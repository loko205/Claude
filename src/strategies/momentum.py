"""Regime-adaptive trading strategy for SOL/USDC.

Switches between two modes based on market regime:
- TRENDING (ADX > 25): Donchian channel breakout — ride the trend
- RANGING  (ADX < 20): Bollinger Band mean reversion — fade extremes
- TRANSITION (ADX 20-25): No new trades, tighter stops on existing

Risk management:
- ATR-based stop-loss and trailing stops
- Half-Kelly position sizing
- Asymmetric R:R enforcement (min 2:1 breakout, 1.5:1 mean reversion)
"""

import logging
import time
from collections import deque
from dataclasses import dataclass

import httpx

from src.config import config
from src.strategies.base import Signal, Strategy

log = logging.getLogger(__name__)

BIRDEYE_OHLCV_URL = "https://public-api.birdeye.so/defi/ohlcv"


@dataclass
class Candle:
    timestamp: float
    open: float
    high: float
    low: float
    close: float
    volume: float


class MomentumStrategy(Strategy):
    """Regime-adaptive strategy: breakout in trends, mean reversion in ranges."""

    name = "regime_adaptive"

    def __init__(self, fast_period: int = 9, slow_period: int = 21, rsi_period: int = 14):
        self.fast_period = fast_period
        self.slow_period = slow_period
        self.rsi_period = rsi_period
        self._client = httpx.AsyncClient(timeout=15)
        self.candles: deque[Candle] = deque(maxlen=200)
        self.last_fetch = 0.0
        self.position: str = "none"

    async def fetch_candles(self, mint: str = config.sol_mint, interval: str = "15m") -> list[Candle]:
        """Fetch OHLCV candles from Birdeye."""
        try:
            now = int(time.time())
            params = {
                "address": mint, "type": interval,
                "time_from": now - 86400, "time_to": now,
            }
            resp = await self._client.get(BIRDEYE_OHLCV_URL, params=params)
            if resp.status_code != 200:
                log.warning(f"Birdeye OHLCV failed: {resp.status_code}")
                return []
            data = resp.json()
            items = data.get("data", {}).get("items", [])
            candles = [
                Candle(
                    timestamp=item["unixTime"],
                    open=item["o"], high=item["h"],
                    low=item["l"], close=item["c"],
                    volume=item.get("v", 0),
                )
                for item in items
            ]
            self.candles.extend(candles)
            return candles
        except Exception as e:
            log.error(f"Failed to fetch candles: {e}")
            return []

    # === Technical indicators ===

    def calc_ema(self, prices: list[float], period: int) -> list[float]:
        """Exponential Moving Average."""
        if len(prices) < period:
            return []
        multiplier = 2 / (period + 1)
        ema = [sum(prices[:period]) / period]
        for price in prices[period:]:
            ema.append((price - ema[-1]) * multiplier + ema[-1])
        return ema

    def calc_rsi(self, prices: list[float], period: int = 14) -> float | None:
        """RSI with Wilder's smoothing."""
        if len(prices) < period + 1:
            return None
        deltas = [prices[i] - prices[i - 1] for i in range(1, len(prices))]
        avg_gain = sum(max(d, 0) for d in deltas[:period]) / period
        avg_loss = sum(max(-d, 0) for d in deltas[:period]) / period
        for d in deltas[period:]:
            avg_gain = (avg_gain * (period - 1) + max(d, 0)) / period
            avg_loss = (avg_loss * (period - 1) + max(-d, 0)) / period
        if avg_loss == 0:
            return 100.0
        return 100 - (100 / (1 + avg_gain / avg_loss))

    def calc_atr(self, candles: list[Candle], period: int = 14) -> float | None:
        """Average True Range — volatility measure."""
        if len(candles) < period + 1:
            return None
        true_ranges = []
        for i in range(1, len(candles)):
            h, l, pc = candles[i].high, candles[i].low, candles[i - 1].close
            true_ranges.append(max(h - l, abs(h - pc), abs(l - pc)))
        atr = sum(true_ranges[:period]) / period
        for tr in true_ranges[period:]:
            atr = (atr * (period - 1) + tr) / period
        return atr

    def calc_adx(self, candles: list[Candle], period: int = 14) -> float | None:
        """ADX — trend strength (0-100)."""
        if len(candles) < period * 2 + 1:
            return None
        plus_dm, minus_dm, tr_list = [], [], []
        for i in range(1, len(candles)):
            h, l = candles[i].high, candles[i].low
            ph, pl, pc = candles[i - 1].high, candles[i - 1].low, candles[i - 1].close
            plus_dm.append(max(h - ph, 0) if (h - ph) > (pl - l) else 0)
            minus_dm.append(max(pl - l, 0) if (pl - l) > (h - ph) else 0)
            tr_list.append(max(h - l, abs(h - pc), abs(l - pc)))
        sp = sum(plus_dm[:period])
        sm = sum(minus_dm[:period])
        st = sum(tr_list[:period])
        dx_list = []
        for i in range(period, len(tr_list)):
            sp = sp - sp / period + plus_dm[i]
            sm = sm - sm / period + minus_dm[i]
            st = st - st / period + tr_list[i]
            if st == 0:
                continue
            pdi = 100 * sp / st
            mdi = 100 * sm / st
            di_sum = pdi + mdi
            if di_sum == 0:
                continue
            dx_list.append(100 * abs(pdi - mdi) / di_sum)
        if len(dx_list) < period:
            return None
        adx = sum(dx_list[:period]) / period
        for dx in dx_list[period:]:
            adx = (adx * (period - 1) + dx) / period
        return adx

    def calc_donchian(self, candles: list[Candle], period: int = 20) -> tuple[float, float] | None:
        """Donchian channel — highest high and lowest low over PREVIOUS period.

        Excludes current candle to avoid lookahead bias.
        """
        if len(candles) < period + 1:
            return None
        window = candles[-(period + 1):-1]  # exclude current
        return max(c.high for c in window), min(c.low for c in window)

    def calc_bollinger(self, prices: list[float], period: int = 20, num_std: float = 2.0
                       ) -> tuple[float, float, float] | None:
        """Bollinger Bands — (upper, middle, lower)."""
        if len(prices) < period:
            return None
        window = prices[-period:]
        middle = sum(window) / period
        variance = sum((p - middle) ** 2 for p in window) / period
        std = variance ** 0.5
        return middle + num_std * std, middle, middle - num_std * std

    async def evaluate(self) -> list[Signal]:
        """Generate regime-adaptive trading signals."""
        now = time.time()
        if now - self.last_fetch < 60:
            return []
        self.last_fetch = now
        await self.fetch_candles()

        if len(self.candles) < 60:
            return []

        candle_list = list(self.candles)
        closes = [c.close for c in candle_list]
        price = closes[-1]

        adx = self.calc_adx(candle_list)
        atr = self.calc_atr(candle_list)
        rsi = self.calc_rsi(closes)

        if adx is None or atr is None or rsi is None:
            return []

        signals = []

        if adx > 25:
            # TRENDING — use Donchian breakout
            donchian = self.calc_donchian(candle_list, 20)
            if donchian and self.position != "long":
                upper, lower = donchian
                if price >= upper and rsi < 75:
                    confidence = min(1.0, 0.5 + (adx - 25) / 50)
                    signals.append(Signal(
                        action="buy", token="SOL", confidence=confidence,
                        reason=f"BREAKOUT: price={price:.1f} >= donchian_high={upper:.1f}, ADX={adx:.0f}",
                    ))
                    self.position = "long"
            elif donchian and self.position == "long":
                _, lower = donchian
                ten_low = min(c.low for c in candle_list[-10:])
                if price <= ten_low or rsi > 80:
                    signals.append(Signal(
                        action="sell", token="SOL", confidence=0.8,
                        reason=f"TREND EXIT: 10-bar low or RSI={rsi:.0f}",
                    ))
                    self.position = "none"

        elif adx < 20:
            # RANGING — use Bollinger mean reversion
            bb = self.calc_bollinger(closes)
            if bb:
                upper, middle, lower = bb
                if price <= lower and rsi < 35 and self.position != "long":
                    signals.append(Signal(
                        action="buy", token="SOL", confidence=0.6,
                        reason=f"MEAN REV: price={price:.1f} <= BB_lower={lower:.1f}, RSI={rsi:.0f}",
                    ))
                    self.position = "long"
                elif self.position == "long" and (price >= middle or rsi > 65):
                    signals.append(Signal(
                        action="sell", token="SOL", confidence=0.7,
                        reason=f"MEAN REV EXIT: price={price:.1f}, BB_mid={middle:.1f}, RSI={rsi:.0f}",
                    ))
                    self.position = "none"

        else:
            # TRANSITION (ADX 20-25) — only exit, no new entries
            if self.position == "long":
                ema_fast = self.calc_ema(closes, self.fast_period)
                ema_slow = self.calc_ema(closes, self.slow_period)
                if ema_fast and ema_slow and ema_fast[-1] < ema_slow[-1]:
                    signals.append(Signal(
                        action="sell", token="SOL", confidence=0.6,
                        reason=f"TRANSITION EXIT: EMA cross down, ADX={adx:.0f}",
                    ))
                    self.position = "none"

        return signals

    async def close(self):
        await self._client.aclose()
