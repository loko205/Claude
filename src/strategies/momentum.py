"""Momentum/trend-following strategy using EMA crossover and RSI."""

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
    name = "momentum"

    def __init__(self, fast_period: int = 9, slow_period: int = 21, rsi_period: int = 14):
        self.fast_period = fast_period
        self.slow_period = slow_period
        self.rsi_period = rsi_period
        self._client = httpx.AsyncClient(timeout=15)
        self.candles: deque[Candle] = deque(maxlen=100)
        self.last_fetch = 0.0
        self.position: str = "none"  # "none", "long"

    async def fetch_candles(self, mint: str = config.sol_mint, interval: str = "15m") -> list[Candle]:
        """Fetch OHLCV candles from Jupiter price API or Birdeye."""
        # Use Jupiter price history as simple proxy
        # For production, use Birdeye API with API key
        try:
            now = int(time.time())
            params = {
                "address": mint,
                "type": interval,
                "time_from": now - 86400,  # last 24h
                "time_to": now,
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

    def calc_ema(self, prices: list[float], period: int) -> list[float]:
        """Calculate Exponential Moving Average."""
        if len(prices) < period:
            return []

        multiplier = 2 / (period + 1)
        ema = [sum(prices[:period]) / period]  # SMA for first value

        for price in prices[period:]:
            ema.append((price - ema[-1]) * multiplier + ema[-1])

        return ema

    def calc_rsi(self, prices: list[float], period: int = 14) -> float | None:
        """Calculate Relative Strength Index."""
        if len(prices) < period + 1:
            return None

        deltas = [prices[i] - prices[i - 1] for i in range(1, len(prices))]
        recent = deltas[-period:]

        gains = [d for d in recent if d > 0]
        losses = [-d for d in recent if d < 0]

        avg_gain = sum(gains) / period if gains else 0
        avg_loss = sum(losses) / period if losses else 0.001

        rs = avg_gain / avg_loss
        return 100 - (100 / (1 + rs))

    async def evaluate(self) -> list[Signal]:
        """Generate trading signals based on EMA crossover + RSI filter."""
        now = time.time()
        if now - self.last_fetch < 60:  # Check every minute
            return []
        self.last_fetch = now

        await self.fetch_candles()

        if len(self.candles) < self.slow_period + 5:
            log.info(f"Not enough candles ({len(self.candles)}/{self.slow_period + 5})")
            return []

        closes = [c.close for c in self.candles]

        ema_fast = self.calc_ema(closes, self.fast_period)
        ema_slow = self.calc_ema(closes, self.slow_period)
        rsi = self.calc_rsi(closes, self.rsi_period)

        if not ema_fast or not ema_slow or rsi is None:
            return []

        # Align EMAs (slow EMA starts later)
        offset = self.slow_period - self.fast_period
        fast_current = ema_fast[-1]
        slow_current = ema_slow[-1]
        fast_prev = ema_fast[-2] if len(ema_fast) > 1 else fast_current
        slow_prev = ema_slow[-2] if len(ema_slow) > 1 else slow_current

        signals = []

        # Bullish crossover: fast crosses above slow + RSI not overbought
        if fast_prev <= slow_prev and fast_current > slow_current and rsi < 70:
            if self.position != "long":
                confidence = min(1.0, (fast_current - slow_current) / slow_current * 100)
                signals.append(Signal(
                    action="buy",
                    token="SOL",
                    confidence=max(0.3, confidence),
                    reason=f"EMA crossover bullish (RSI: {rsi:.1f})",
                ))
                self.position = "long"
                log.info(f"MOMENTUM BUY SIGNAL — EMA cross up, RSI={rsi:.1f}")

        # Bearish crossover: fast crosses below slow OR RSI overbought
        elif (fast_prev >= slow_prev and fast_current < slow_current) or rsi > 80:
            if self.position == "long":
                signals.append(Signal(
                    action="sell",
                    token="SOL",
                    confidence=0.7,
                    reason=f"EMA crossover bearish (RSI: {rsi:.1f})",
                ))
                self.position = "none"
                log.info(f"MOMENTUM SELL SIGNAL — EMA cross down, RSI={rsi:.1f}")

        return signals

    async def close(self):
        await self._client.aclose()
