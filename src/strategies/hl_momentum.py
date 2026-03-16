"""Regime-adaptive momentum strategy for Hyperliquid perpetuals.

Extends the base momentum logic with short-selling capability:
- TRENDING up (ADX > 25): Donchian breakout long
- TRENDING down (ADX > 25): Donchian breakdown short
- RANGING (ADX < 20): Bollinger mean reversion (long at lower, short at upper)
- TRANSITION (ADX 20-25): Exit only
"""

import logging
import time

from src.exchanges.hyperliquid import HyperliquidClient
from src.strategies.base import Signal, Strategy
from src.strategies.momentum import MomentumStrategy

log = logging.getLogger(__name__)


class HLMomentumStrategy(Strategy):
    """Regime-adaptive strategy for Hyperliquid perps with long+short."""

    name = "hl_momentum"

    def __init__(self, client: HyperliquidClient, coin: str = "SOL", interval: str = "15m"):
        self.client = client
        self.coin = coin
        self.interval = interval
        self.last_fetch = 0.0
        self.position: str = "none"  # "none", "long", "short"
        # Reuse indicator calculations (static methods, no HTTP client needed)
        self._ind = MomentumStrategy.__new__(MomentumStrategy)

    async def evaluate(self) -> list[Signal]:
        """Generate trading signals from Hyperliquid candle data."""
        now = time.time()
        if now - self.last_fetch < 60:
            return []
        self.last_fetch = now

        # Fetch 24h of candles
        candles = self.client.get_candles(self.coin, self.interval)
        if len(candles) < 60:
            log.debug(f"Not enough candles ({len(candles)}), need 60+")
            return []

        closes = [c.close for c in candles]
        price = closes[-1]

        adx = self._ind.calc_adx(candles)
        atr = self._ind.calc_atr(candles)
        rsi = self._ind.calc_rsi(closes)

        if adx is None or atr is None or rsi is None:
            return []

        signals = []

        if adx > 25:
            signals = self._trending_signals(candles, closes, price, adx, atr, rsi)
        elif adx < 20:
            signals = self._ranging_signals(closes, price, adx, rsi)
        else:
            signals = self._transition_signals(closes, adx)

        return signals

    def _trending_signals(self, candles, closes, price, adx, atr, rsi) -> list[Signal]:
        """Donchian breakout/breakdown in trending markets."""
        signals = []
        donchian = self._ind.calc_donchian(candles, 20)
        if not donchian:
            return []

        upper, lower = donchian
        ema_fast = self._ind.calc_ema(closes, 9)
        ema_slow = self._ind.calc_ema(closes, 21)
        trend_up = ema_fast and ema_slow and ema_fast[-1] > ema_slow[-1]

        # Long breakout
        if self.position != "long" and price >= upper and rsi < 75 and trend_up:
            confidence = min(1.0, 0.5 + (adx - 25) / 50)
            signals.append(Signal(
                action="buy", token=self.coin, confidence=confidence,
                reason=f"BREAKOUT: {price:.1f} >= donchian {upper:.1f}, ADX={adx:.0f}",
            ))
            if self.position == "short":
                signals.insert(0, Signal(
                    action="close_short", token=self.coin, confidence=0.9,
                    reason="Flip: short -> long",
                ))
            self.position = "long"

        # Short breakdown
        elif self.position != "short" and price <= lower and rsi > 25 and not trend_up:
            confidence = min(1.0, 0.5 + (adx - 25) / 50)
            signals.append(Signal(
                action="sell", token=self.coin, confidence=confidence,
                reason=f"BREAKDOWN: {price:.1f} <= donchian {lower:.1f}, ADX={adx:.0f}",
            ))
            if self.position == "long":
                signals.insert(0, Signal(
                    action="close_long", token=self.coin, confidence=0.9,
                    reason="Flip: long -> short",
                ))
            self.position = "short"

        # Exit long
        elif self.position == "long":
            ten_low = min(c.low for c in candles[-10:])
            if price <= ten_low or rsi > 80:
                signals.append(Signal(
                    action="close_long", token=self.coin, confidence=0.8,
                    reason=f"TREND EXIT long: 10-bar low or RSI={rsi:.0f}",
                ))
                self.position = "none"

        # Exit short
        elif self.position == "short":
            ten_high = max(c.high for c in candles[-10:])
            if price >= ten_high or rsi < 20:
                signals.append(Signal(
                    action="close_short", token=self.coin, confidence=0.8,
                    reason=f"TREND EXIT short: 10-bar high or RSI={rsi:.0f}",
                ))
                self.position = "none"

        return signals

    def _ranging_signals(self, closes, price, adx, rsi) -> list[Signal]:
        """Bollinger Band mean reversion in ranging markets."""
        signals = []
        bb = self._ind.calc_bollinger(closes)
        if not bb:
            return []

        upper, middle, lower = bb

        # Long at lower band
        if price <= lower and rsi < 35 and self.position != "long":
            if self.position == "short":
                signals.append(Signal(
                    action="close_short", token=self.coin, confidence=0.7,
                    reason="Mean rev: close short before long",
                ))
            signals.append(Signal(
                action="buy", token=self.coin, confidence=0.6,
                reason=f"MEAN REV long: {price:.1f} <= BB_low={lower:.1f}, RSI={rsi:.0f}",
            ))
            self.position = "long"

        # Short at upper band
        elif price >= upper and rsi > 65 and self.position != "short":
            if self.position == "long":
                signals.append(Signal(
                    action="close_long", token=self.coin, confidence=0.7,
                    reason="Mean rev: close long before short",
                ))
            signals.append(Signal(
                action="sell", token=self.coin, confidence=0.6,
                reason=f"MEAN REV short: {price:.1f} >= BB_up={upper:.1f}, RSI={rsi:.0f}",
            ))
            self.position = "short"

        # Exit long at middle
        elif self.position == "long" and (price >= middle or rsi > 65):
            signals.append(Signal(
                action="close_long", token=self.coin, confidence=0.7,
                reason=f"MEAN REV EXIT long: mid={middle:.1f}, RSI={rsi:.0f}",
            ))
            self.position = "none"

        # Exit short at middle
        elif self.position == "short" and (price <= middle or rsi < 35):
            signals.append(Signal(
                action="close_short", token=self.coin, confidence=0.7,
                reason=f"MEAN REV EXIT short: mid={middle:.1f}, RSI={rsi:.0f}",
            ))
            self.position = "none"

        return signals

    def _transition_signals(self, closes, adx) -> list[Signal]:
        """Only exit in transition zone (ADX 20-25)."""
        signals = []
        if self.position == "none":
            return []

        ema_fast = self._ind.calc_ema(closes, 9)
        ema_slow = self._ind.calc_ema(closes, 21)
        if not ema_fast or not ema_slow:
            return []

        if self.position == "long" and ema_fast[-1] < ema_slow[-1]:
            signals.append(Signal(
                action="close_long", token=self.coin, confidence=0.6,
                reason=f"TRANSITION EXIT long: EMA cross down, ADX={adx:.0f}",
            ))
            self.position = "none"
        elif self.position == "short" and ema_fast[-1] > ema_slow[-1]:
            signals.append(Signal(
                action="close_short", token=self.coin, confidence=0.6,
                reason=f"TRANSITION EXIT short: EMA cross up, ADX={adx:.0f}",
            ))
            self.position = "none"

        return signals

    async def close(self):
        pass  # No async resources to clean up
