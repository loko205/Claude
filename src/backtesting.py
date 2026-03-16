"""Backtesting engine — runs momentum strategy on real or synthetic OHLCV data.

Usage:
    # With CoinGecko (default, needs internet):
    uv run python -m src.backtesting 30 90

    # With CSV file:
    uv run python -m src.backtesting --csv data/sol_ohlc.csv 90

    # Fallback synthetic data (offline):
    uv run python -m src.backtesting --synthetic 90
"""

import asyncio
import csv
import logging
import math
import random
import sys
from dataclasses import dataclass, field

import httpx

from src.execution.risk import RiskManager
from src.strategies.momentum import Candle, MomentumStrategy

log = logging.getLogger(__name__)

COINGECKO_OHLC_URL = "https://api.coingecko.com/api/v3/coins/{coin_id}/ohlc"


@dataclass
class BacktestTrade:
    timestamp: float
    action: str  # "buy" or "sell"
    price: float
    size_usdc: float
    reason: str


@dataclass
class BacktestResult:
    trades: list[BacktestTrade] = field(default_factory=list)
    start_balance: float = 0.0
    final_balance: float = 0.0
    max_drawdown_pct: float = 0.0
    total_candles: int = 0

    @property
    def pnl(self) -> float:
        return self.final_balance - self.start_balance

    @property
    def pnl_pct(self) -> float:
        return (self.pnl / self.start_balance * 100) if self.start_balance else 0

    @property
    def win_count(self) -> int:
        return sum(1 for i in range(1, len(self.trades), 2)
                   if i < len(self.trades)
                   and self.trades[i].price > self.trades[i - 1].price)

    @property
    def loss_count(self) -> int:
        pairs = len(self.trades) // 2
        return pairs - self.win_count

    @property
    def win_rate(self) -> float:
        pairs = len(self.trades) // 2
        return (self.win_count / pairs * 100) if pairs else 0

    def report(self) -> str:
        lines = [
            "=" * 50,
            "  BACKTEST ERGEBNIS — Momentum (EMA/RSI)",
            "=" * 50,
            f"  Candles:          {self.total_candles}",
            f"  Trades:           {len(self.trades)} ({len(self.trades) // 2} Round-Trips)",
            f"  Win/Loss:         {self.win_count}W / {self.loss_count}L",
            f"  Win Rate:         {self.win_rate:.1f}%",
            f"  Start:            ${self.start_balance:.2f}",
            f"  End:              ${self.final_balance:.2f}",
            f"  P&L:              ${self.pnl:+.2f} ({self.pnl_pct:+.1f}%)",
            f"  Max Drawdown:     {self.max_drawdown_pct:.1f}%",
            "=" * 50,
        ]
        if self.trades:
            lines.append("  Letzte Trades:")
            for t in self.trades[-10:]:
                lines.append(
                    f"    {t.action.upper():4s} @ ${t.price:.2f} "
                    f"(${t.size_usdc:.2f}) — {t.reason}"
                )
            lines.append("=" * 50)
        return "\n".join(lines)


async def fetch_ohlc(coin_id: str = "solana", days: int = 30) -> list[Candle]:
    """Fetch OHLCV candles from CoinGecko (free, no API key)."""
    async with httpx.AsyncClient(timeout=20) as client:
        url = COINGECKO_OHLC_URL.format(coin_id=coin_id)
        resp = await client.get(url, params={"vs_currency": "usd", "days": days})
        resp.raise_for_status()
        data = resp.json()

    # CoinGecko OHLC format: [[timestamp, open, high, low, close], ...]
    candles = [
        Candle(
            timestamp=row[0] / 1000,  # ms -> s
            open=row[1],
            high=row[2],
            low=row[3],
            close=row[4],
            volume=0,  # OHLC endpoint has no volume
        )
        for row in data
    ]
    log.info(f"Fetched {len(candles)} candles from CoinGecko ({coin_id}, {days}d)")
    return candles


async def run_backtest(
    candles: list[Candle],
    start_balance: float = 90.0,
    fast_period: int = 9,
    slow_period: int = 21,
    rsi_period: int = 14,
) -> BacktestResult:
    """Run momentum strategy over historical candles."""
    strategy = MomentumStrategy(fast_period, slow_period, rsi_period)
    risk = RiskManager()
    result = BacktestResult(start_balance=start_balance)
    result.total_candles = len(candles)

    balance = start_balance
    position_tokens = 0.0
    peak_balance = balance

    min_candles = slow_period + 5

    for i in range(min_candles, len(candles)):
        # Feed candles up to current point
        window = candles[: i + 1]
        closes = [c.close for c in window]
        current_price = closes[-1]

        # Calculate indicators
        ema_fast = strategy.calc_ema(closes, fast_period)
        ema_slow = strategy.calc_ema(closes, slow_period)
        rsi = strategy.calc_rsi(closes, rsi_period)

        if not ema_fast or not ema_slow or rsi is None:
            continue

        fast_cur = ema_fast[-1]
        slow_cur = ema_slow[-1]
        fast_prev = ema_fast[-2] if len(ema_fast) > 1 else fast_cur
        slow_prev = ema_slow[-2] if len(ema_slow) > 1 else slow_cur

        # Bullish crossover + RSI filter
        if fast_prev <= slow_prev and fast_cur > slow_cur and rsi < 70:
            if position_tokens == 0 and balance > 1:
                size = risk.get_position_size(balance, confidence=0.6)
                size = min(size, balance)
                ok, reason = risk.can_trade(size)
                if not ok:
                    continue
                tokens = size / current_price
                position_tokens = tokens
                balance -= size
                result.trades.append(BacktestTrade(
                    timestamp=candles[i].timestamp,
                    action="buy",
                    price=current_price,
                    size_usdc=size,
                    reason=f"EMA cross up, RSI={rsi:.1f}",
                ))

        # Bearish crossover or RSI overbought
        elif (fast_prev >= slow_prev and fast_cur < slow_cur) or rsi > 80:
            if position_tokens > 0:
                sell_value = position_tokens * current_price
                balance += sell_value
                result.trades.append(BacktestTrade(
                    timestamp=candles[i].timestamp,
                    action="sell",
                    price=current_price,
                    size_usdc=sell_value,
                    reason=f"EMA cross down, RSI={rsi:.1f}",
                ))
                position_tokens = 0

        # Track drawdown
        total_value = balance + position_tokens * current_price
        peak_balance = max(peak_balance, total_value)
        dd = (peak_balance - total_value) / peak_balance * 100
        result.max_drawdown_pct = max(result.max_drawdown_pct, dd)

    # Close open position at last price
    if position_tokens > 0 and candles:
        last_price = candles[-1].close
        balance += position_tokens * last_price
        result.trades.append(BacktestTrade(
            timestamp=candles[-1].timestamp,
            action="sell",
            price=last_price,
            size_usdc=position_tokens * last_price,
            reason="Backtest end — forced close",
        ))

    result.final_balance = balance
    return result


def load_csv(path: str) -> list[Candle]:
    """Load OHLCV candles from CSV file.

    Expected columns: timestamp,open,high,low,close[,volume]
    """
    candles = []
    with open(path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            candles.append(Candle(
                timestamp=float(row["timestamp"]),
                open=float(row["open"]),
                high=float(row["high"]),
                low=float(row["low"]),
                close=float(row["close"]),
                volume=float(row.get("volume", 0)),
            ))
    log.info(f"Loaded {len(candles)} candles from {path}")
    return candles


def generate_synthetic(
    days: int = 30,
    interval_minutes: int = 15,
    start_price: float = 130.0,
    volatility: float = 0.03,
    seed: int | None = None,
) -> list[Candle]:
    """Generate realistic synthetic SOL/USD candles.

    Uses geometric Brownian motion with mean-reversion and
    volatility parameters matching real SOL (~3% daily).
    """
    if seed is not None:
        random.seed(seed)

    candles_per_day = 24 * 60 // interval_minutes
    total = days * candles_per_day
    step_vol = volatility / math.sqrt(candles_per_day)

    price = start_price
    mean_price = start_price
    candles = []

    for i in range(total):
        ts = i * interval_minutes * 60
        # Geometric Brownian motion + light mean-reversion
        drift = 0.0002 * (mean_price - price) / price
        shock = random.gauss(0, step_vol)
        ret = drift + shock
        price *= (1 + ret)
        price = max(price, 1.0)  # floor

        high = price * (1 + abs(random.gauss(0, step_vol * 0.5)))
        low = price * (1 - abs(random.gauss(0, step_vol * 0.5)))
        open_p = price * (1 + random.gauss(0, step_vol * 0.3))

        candles.append(Candle(
            timestamp=ts,
            open=open_p,
            high=max(high, open_p, price),
            low=min(low, open_p, price),
            close=price,
            volume=random.uniform(1e6, 5e6),
        ))

    log.info(f"Generated {len(candles)} synthetic candles ({days}d, {interval_minutes}min)")
    return candles


async def main():
    """Fetch real SOL data and run backtest."""
    logging.basicConfig(level=logging.INFO, format="%(message)s")

    args = sys.argv[1:]
    candles = []
    balance = 90.0

    if "--csv" in args:
        idx = args.index("--csv")
        csv_path = args[idx + 1]
        balance = float(args[idx + 2]) if len(args) > idx + 2 else 90.0
        print(f"\nLade Daten aus {csv_path}...")
        candles = load_csv(csv_path)

    elif "--synthetic" in args:
        idx = args.index("--synthetic")
        balance = float(args[idx + 1]) if len(args) > idx + 1 else 90.0
        days = 30
        print(f"\nGeneriere {days} Tage synthetische SOL-Daten...")
        candles = generate_synthetic(days=days, seed=42)

    else:
        days = int(args[0]) if args else 30
        balance = float(args[1]) if len(args) > 1 else 90.0
        print(f"\nFetching {days} Tage SOL/USD von CoinGecko...")
        try:
            candles = await fetch_ohlc("solana", days=days)
        except Exception as e:
            print(f"CoinGecko nicht erreichbar: {e}")
            print("Fallback: generiere synthetische Daten...\n")
            candles = generate_synthetic(days=days, seed=42)

    if len(candles) < 30:
        print(f"Zu wenig Daten: {len(candles)} Candles. Mindestens 30 nötig.")
        return

    print(f"{len(candles)} Candles geladen. Starte Backtest...\n")
    result = await run_backtest(candles, start_balance=balance)
    print(result.report())


if __name__ == "__main__":
    asyncio.run(main())
