"""Backtesting engine for regime-adaptive strategy.

Tests breakout (trending) + mean reversion (ranging) on historical data.

Usage:
    uv run python -m src.backtesting 30 90          # CoinGecko
    uv run python -m src.backtesting --synthetic 90  # Offline
    uv run python -m src.backtesting --csv file.csv 90
"""

import asyncio
import csv
import logging
import math
import random
import sys
from dataclasses import dataclass, field
from enum import Enum

import httpx

from src.strategies.momentum import Candle, MomentumStrategy

log = logging.getLogger(__name__)

COINGECKO_OHLC_URL = "https://api.coingecko.com/api/v3/coins/{coin_id}/ohlc"


class Regime(Enum):
    TRENDING = "trending"
    RANGING = "ranging"
    TRANSITION = "transition"


@dataclass
class BacktestTrade:
    timestamp: float
    action: str
    price: float
    size_usdc: float
    reason: str
    pnl: float = 0.0
    regime: str = ""


@dataclass
class BacktestResult:
    trades: list[BacktestTrade] = field(default_factory=list)
    start_balance: float = 0.0
    final_balance: float = 0.0
    max_drawdown_pct: float = 0.0
    total_candles: int = 0
    regime_counts: dict[str, int] = field(default_factory=dict)

    @property
    def pnl(self) -> float:
        return self.final_balance - self.start_balance

    @property
    def pnl_pct(self) -> float:
        return (self.pnl / self.start_balance * 100) if self.start_balance else 0

    @property
    def sells(self) -> list[BacktestTrade]:
        return [t for t in self.trades if t.action == "sell"]

    @property
    def win_count(self) -> int:
        return sum(1 for t in self.sells if t.pnl > 0)

    @property
    def loss_count(self) -> int:
        return sum(1 for t in self.sells if t.pnl <= 0)

    @property
    def win_rate(self) -> float:
        n = len(self.sells)
        return (self.win_count / n * 100) if n else 0

    @property
    def avg_win(self) -> float:
        wins = [t.pnl for t in self.sells if t.pnl > 0]
        return sum(wins) / len(wins) if wins else 0

    @property
    def avg_loss(self) -> float:
        losses = [t.pnl for t in self.sells if t.pnl <= 0]
        return sum(losses) / len(losses) if losses else 0

    @property
    def profit_factor(self) -> float:
        gross_win = sum(t.pnl for t in self.sells if t.pnl > 0)
        gross_loss = abs(sum(t.pnl for t in self.sells if t.pnl < 0))
        return gross_win / gross_loss if gross_loss > 0 else float('inf')

    @property
    def expectancy(self) -> float:
        n = len(self.sells)
        return sum(t.pnl for t in self.sells) / n if n else 0

    @property
    def weekly_pnl(self) -> float:
        """Extrapolate to weekly based on candle count (assumes 15min candles)."""
        if self.total_candles == 0:
            return 0
        days = self.total_candles / (24 * 4)  # 15min candles
        return self.pnl / days * 7 if days > 0 else 0

    def report(self) -> str:
        breakout_sells = [t for t in self.sells if "BREAKOUT" in t.regime or "TREND" in t.regime]
        mr_sells = [t for t in self.sells if "MEAN" in t.regime or "RANGE" in t.regime]
        bo_pnl = sum(t.pnl for t in breakout_sells)
        mr_pnl = sum(t.pnl for t in mr_sells)

        lines = [
            "=" * 60,
            "  BACKTEST — Regime-Adaptive (Breakout + Mean Reversion)",
            "=" * 60,
            f"  Candles:          {self.total_candles}",
            f"  Trades:           {len(self.sells)} round-trips",
            f"  Win/Loss:         {self.win_count}W / {self.loss_count}L",
            f"  Win Rate:         {self.win_rate:.1f}%",
            f"  Avg Win:          ${self.avg_win:+.2f}",
            f"  Avg Loss:         ${self.avg_loss:+.2f}",
            f"  Profit Factor:    {self.profit_factor:.2f}",
            f"  Expectancy:       ${self.expectancy:+.2f} / trade",
            "",
            f"  Breakout P&L:     ${bo_pnl:+.2f} ({len(breakout_sells)} trades)",
            f"  MeanRev P&L:      ${mr_pnl:+.2f} ({len(mr_sells)} trades)",
            "",
            f"  Start:            ${self.start_balance:.2f}",
            f"  End:              ${self.final_balance:.2f}",
            f"  P&L:              ${self.pnl:+.2f} ({self.pnl_pct:+.1f}%)",
            f"  Woche (hochger.): ${self.weekly_pnl:+.2f}",
            f"  Max Drawdown:     {self.max_drawdown_pct:.1f}%",
            "=" * 60,
        ]
        if self.trades:
            lines.append("  Trades:")
            for t in self.trades[-20:]:
                pnl_s = f" PnL=${t.pnl:+.2f}" if t.action == "sell" else ""
                lines.append(
                    f"    {t.action.upper():4s} @ ${t.price:>8.2f} "
                    f"(${t.size_usdc:>6.2f}){pnl_s} [{t.regime}] {t.reason}"
                )
            lines.append("=" * 60)
        return "\n".join(lines)


async def run_backtest(
    candles: list[Candle],
    start_balance: float = 90.0,
    # Regime thresholds
    adx_trend: float = 25.0,
    adx_range: float = 20.0,
    # Breakout params
    donchian_period: int = 20,
    donchian_exit: int = 10,
    # Mean reversion params
    bb_period: int = 20,
    bb_std: float = 2.0,
    rsi_buy: float = 35.0,
    rsi_sell: float = 65.0,
    # Risk
    atr_stop_mult: float = 2.0,
    atr_trail_mult: float = 1.5,
    breakout_size_pct: float = 75.0,
    mr_size_pct: float = 50.0,
) -> BacktestResult:
    """Run regime-adaptive backtest."""
    strategy = MomentumStrategy()
    result = BacktestResult(start_balance=start_balance)
    result.total_candles = len(candles)

    balance = start_balance
    position_tokens = 0.0
    entry_price = 0.0
    entry_size = 0.0
    stop_loss = 0.0
    trailing_stop = 0.0
    peak_price = 0.0
    peak_balance = balance
    current_regime = ""
    take_profit = 0.0

    min_candles = max(donchian_period, bb_period, 50) + 15

    for i in range(min_candles, len(candles)):
        window = candles[:i + 1]
        closes = [c.close for c in window]
        price = closes[-1]

        adx = strategy.calc_adx(window)
        atr = strategy.calc_atr(window)
        rsi = strategy.calc_rsi(closes)

        if adx is None or atr is None or rsi is None:
            continue

        # Determine regime
        if adx > adx_trend:
            regime = Regime.TRENDING
        elif adx < adx_range:
            regime = Regime.RANGING
        else:
            regime = Regime.TRANSITION

        result.regime_counts[regime.value] = result.regime_counts.get(regime.value, 0) + 1

        # === POSITION MANAGEMENT ===
        if position_tokens > 0:
            # Update trailing stop (only moves up)
            if price > peak_price:
                peak_price = price
                new_trail = price - atr_trail_mult * atr
                trailing_stop = max(trailing_stop, new_trail)

            hit_stop = price <= stop_loss
            hit_trail = price <= trailing_stop and trailing_stop > stop_loss
            hit_tp = take_profit > 0 and price >= take_profit

            # Regime-change exit: was trending, now ranging (or vice versa)
            regime_exit = False
            if current_regime == "BREAKOUT" and regime == Regime.RANGING:
                regime_exit = True
            if current_regime == "MEAN_REV" and regime == Regime.TRENDING:
                regime_exit = True

            # Breakout exit: price drops below donchian_exit low
            breakout_exit = False
            if current_regime == "BREAKOUT" and len(window) >= donchian_exit:
                exit_low = min(c.low for c in window[-donchian_exit:])
                if price <= exit_low:
                    breakout_exit = True

            # Mean rev exit: price reaches middle band or RSI normalizes
            mr_exit = False
            if current_regime == "MEAN_REV":
                bb = strategy.calc_bollinger(closes, bb_period, bb_std)
                if bb:
                    _, middle, _ = bb
                    if price >= middle or rsi > rsi_sell:
                        mr_exit = True

            if hit_stop or hit_trail or hit_tp or regime_exit or breakout_exit or mr_exit:
                sell_value = position_tokens * price
                pnl = sell_value - entry_size
                balance += sell_value
                reason_parts = []
                if hit_stop:
                    reason_parts.append("STOP-LOSS")
                elif hit_trail:
                    reason_parts.append(f"TRAIL(peak=${peak_price:.2f})")
                elif hit_tp:
                    reason_parts.append("TAKE-PROFIT")
                elif breakout_exit:
                    reason_parts.append(f"DONCHIAN-EXIT({donchian_exit})")
                elif mr_exit:
                    reason_parts.append("BB-MID/RSI-NORM")
                elif regime_exit:
                    reason_parts.append("REGIME-CHANGE")

                result.trades.append(BacktestTrade(
                    timestamp=candles[i].timestamp, action="sell",
                    price=price, size_usdc=sell_value, pnl=pnl,
                    regime=current_regime,
                    reason=" ".join(reason_parts),
                ))
                position_tokens = 0
                continue

        # === ENTRIES ===
        if position_tokens == 0 and balance > 1:

            # TRENDING: Donchian breakout
            if regime == Regime.TRENDING:
                donchian = strategy.calc_donchian(window, donchian_period)
                if donchian:
                    upper, lower = donchian
                    # Price breaks above channel high AND RSI not overbought
                    if price >= upper and rsi < 75:
                        size = balance * breakout_size_pct / 100
                        # Strong trend bonus
                        if adx > 35:
                            size = min(balance * (breakout_size_pct + 15) / 100, balance * 0.75)
                        tokens = size / price
                        position_tokens = tokens
                        balance -= size
                        entry_price = price
                        entry_size = size
                        peak_price = price
                        stop_loss = price - atr_stop_mult * atr
                        trailing_stop = price - atr_trail_mult * atr
                        take_profit = 0  # let winners run
                        current_regime = "BREAKOUT"

                        result.trades.append(BacktestTrade(
                            timestamp=candles[i].timestamp, action="buy",
                            price=price, size_usdc=size, regime="BREAKOUT",
                            reason=f"DONCHIAN({donchian_period}) break, ADX={adx:.0f}, "
                                   f"RSI={rsi:.0f}, SL=${stop_loss:.2f}",
                        ))

            # RANGING: Bollinger Band mean reversion
            elif regime == Regime.RANGING:
                bb = strategy.calc_bollinger(closes, bb_period, bb_std)
                if bb:
                    upper, middle, lower = bb
                    # Price touches lower band + RSI oversold
                    if price <= lower and rsi < rsi_buy:
                        size = balance * mr_size_pct / 100
                        tokens = size / price
                        position_tokens = tokens
                        balance -= size
                        entry_price = price
                        entry_size = size
                        peak_price = price
                        stop_loss = price - atr_stop_mult * atr
                        trailing_stop = 0  # use BB-mid as exit instead
                        take_profit = middle  # target = middle band
                        current_regime = "MEAN_REV"

                        result.trades.append(BacktestTrade(
                            timestamp=candles[i].timestamp, action="buy",
                            price=price, size_usdc=size, regime="MEAN_REV",
                            reason=f"BB lower touch, ADX={adx:.0f}, "
                                   f"RSI={rsi:.0f}, TP=${middle:.2f}",
                        ))

        # Track drawdown
        total_value = balance + position_tokens * price
        peak_balance = max(peak_balance, total_value)
        dd = (peak_balance - total_value) / peak_balance * 100 if peak_balance > 0 else 0
        result.max_drawdown_pct = max(result.max_drawdown_pct, dd)

    # Force-close
    if position_tokens > 0 and candles:
        last = candles[-1].close
        sell_value = position_tokens * last
        pnl = sell_value - entry_size
        balance += sell_value
        result.trades.append(BacktestTrade(
            timestamp=candles[-1].timestamp, action="sell",
            price=last, size_usdc=sell_value, pnl=pnl,
            regime=current_regime, reason="END — forced close",
        ))

    result.final_balance = balance
    return result


# === Data sources ===

async def fetch_ohlc(coin_id: str = "solana", days: int = 30) -> list[Candle]:
    """Fetch from CoinGecko (free)."""
    async with httpx.AsyncClient(timeout=20) as client:
        url = COINGECKO_OHLC_URL.format(coin_id=coin_id)
        resp = await client.get(url, params={"vs_currency": "usd", "days": days})
        resp.raise_for_status()
        data = resp.json()
    return [
        Candle(timestamp=r[0] / 1000, open=r[1], high=r[2], low=r[3], close=r[4], volume=0)
        for r in data
    ]


def load_csv(path: str) -> list[Candle]:
    """Load from CSV (columns: timestamp,open,high,low,close[,volume])."""
    candles = []
    with open(path) as f:
        for row in csv.DictReader(f):
            candles.append(Candle(
                timestamp=float(row["timestamp"]),
                open=float(row["open"]), high=float(row["high"]),
                low=float(row["low"]), close=float(row["close"]),
                volume=float(row.get("volume", 0)),
            ))
    return candles


def generate_synthetic(
    days: int = 30, interval_minutes: int = 15,
    start_price: float = 130.0, volatility: float = 0.03,
    seed: int | None = None,
) -> list[Candle]:
    """Generate synthetic SOL candles with realistic trend regimes."""
    if seed is not None:
        random.seed(seed)

    candles_per_day = 24 * 60 // interval_minutes
    total = days * candles_per_day
    step_vol = volatility / math.sqrt(candles_per_day)

    price = start_price
    candles = []
    regime_drift = 0.0
    regime_counter = 0

    for i in range(total):
        ts = i * interval_minutes * 60
        if regime_counter <= 0:
            regime_counter = random.randint(candles_per_day * 2, candles_per_day * 5)
            roll = random.random()
            if roll < 0.4:
                regime_drift = random.uniform(0.0003, 0.001)
            elif roll < 0.7:
                regime_drift = random.uniform(-0.001, -0.0003)
            else:
                regime_drift = 0.0
        regime_counter -= 1

        shock = random.gauss(0, step_vol)
        price *= (1 + regime_drift + shock)
        price = max(price, 10.0)

        iv = abs(random.gauss(0, step_vol * 0.7))
        high = price * (1 + iv)
        low = price * (1 - iv)
        op = price * (1 + random.gauss(0, step_vol * 0.3))

        candles.append(Candle(
            timestamp=ts, open=op,
            high=max(high, op, price), low=min(low, op, price),
            close=price, volume=random.uniform(1e6, 5e6),
        ))

    return candles


# === CLI ===

async def main():
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    args = sys.argv[1:]
    candles = []
    balance = 90.0

    if "--csv" in args:
        idx = args.index("--csv")
        csv_path = args[idx + 1]
        balance = float(args[idx + 2]) if len(args) > idx + 2 else 90.0
        print(f"\nLade {csv_path}...")
        candles = load_csv(csv_path)

    elif "--synthetic" in args:
        idx = args.index("--synthetic")
        balance = float(args[idx + 1]) if len(args) > idx + 1 else 90.0
        days = 30
        print(f"\n{days} Tage synthetische SOL-Daten (Trend-Regimes)...")
        candles = generate_synthetic(days=days, seed=42)

    else:
        days = int(args[0]) if args else 30
        balance = float(args[1]) if len(args) > 1 else 90.0
        print(f"\nFetching {days}d SOL/USD von CoinGecko...")
        try:
            candles = await fetch_ohlc("solana", days=days)
        except Exception as e:
            print(f"CoinGecko nicht erreichbar: {e}")
            print("Fallback: synthetische Daten...\n")
            candles = generate_synthetic(days=days, seed=42)

    if len(candles) < 70:
        print(f"Zu wenig Daten ({len(candles)}). Min 70 Candles nötig.")
        return

    print(f"{len(candles)} Candles. Starte Backtest...\n")

    # Run with multiple seeds to check robustness
    if "--multi" in args:
        print("Multi-Seed Robustness-Test (seeds 1-10):\n")
        total_pnl = 0
        total_wr = 0
        for seed in range(1, 11):
            c = generate_synthetic(days=30, seed=seed)
            r = await run_backtest(c, start_balance=balance)
            total_pnl += r.pnl
            total_wr += r.win_rate
            emoji = "+" if r.pnl > 0 else "-"
            print(f"  Seed {seed:2d}: P&L=${r.pnl:+6.2f} ({r.pnl_pct:+5.1f}%) "
                  f"WR={r.win_rate:4.0f}% Trades={len(r.sells):2d} "
                  f"DD={r.max_drawdown_pct:4.1f}% [{emoji}]")
        print(f"\n  Avg P&L: ${total_pnl / 10:+.2f}  Avg WR: {total_wr / 10:.0f}%")
    else:
        result = await run_backtest(candles, start_balance=balance)
        print(result.report())


if __name__ == "__main__":
    asyncio.run(main())
