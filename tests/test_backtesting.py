"""Tests for regime-adaptive backtesting engine."""

import pytest

from src.backtesting import BacktestResult, BacktestTrade, run_backtest, generate_synthetic
from src.strategies.momentum import Candle


def _make_candles(prices: list[float]) -> list[Candle]:
    """Create candles from close prices with realistic OHLC."""
    candles = []
    for i, p in enumerate(prices):
        prev = prices[i - 1] if i > 0 else p
        candles.append(Candle(
            timestamp=i * 900,
            open=prev,
            high=max(p, prev) * 1.002,
            low=min(p, prev) * 0.998,
            close=p,
            volume=1e6,
        ))
    return candles


@pytest.mark.asyncio
async def test_backtest_strong_uptrend():
    """Strong uptrend should trigger breakout trades and profit."""
    # Flat then strong breakout
    prices = [100.0] * 70 + [100 + i * 1.5 for i in range(100)]
    candles = _make_candles(prices)
    result = await run_backtest(candles, start_balance=90.0)

    assert result.total_candles == 170
    assert result.final_balance >= 90.0  # should not lose in a strong uptrend


@pytest.mark.asyncio
async def test_backtest_ranging_market():
    """Ranging market should trigger mean reversion trades."""
    # Oscillating around 100
    import math
    prices = [100 + 5 * math.sin(i * 0.15) for i in range(200)]
    candles = _make_candles(prices)
    result = await run_backtest(candles, start_balance=90.0)

    assert result.total_candles == 200


@pytest.mark.asyncio
async def test_backtest_insufficient_data():
    """Too few candles should return no trades."""
    candles = _make_candles([100.0] * 30)
    result = await run_backtest(candles, start_balance=90.0)

    assert len(result.trades) == 0
    assert result.final_balance == 90.0


@pytest.mark.asyncio
async def test_synthetic_data_consistency():
    """Same seed should produce same results."""
    c1 = generate_synthetic(days=7, seed=99)
    c2 = generate_synthetic(days=7, seed=99)
    assert len(c1) == len(c2)
    assert c1[0].close == c2[0].close
    assert c1[-1].close == c2[-1].close


@pytest.mark.asyncio
async def test_multi_seed_no_ruin():
    """Strategy should never lose more than 50% across diverse scenarios."""
    for seed in range(1, 6):
        candles = generate_synthetic(days=30, seed=seed)
        result = await run_backtest(candles, start_balance=90.0)
        assert result.final_balance > 45.0, f"Seed {seed}: balance dropped to ${result.final_balance:.2f}"


def test_result_report():
    """Report should contain key metrics."""
    result = BacktestResult(start_balance=90.0, final_balance=100.0, total_candles=100)
    result.trades = [
        BacktestTrade(0, "buy", 130.0, 45.0, "test", regime="BREAKOUT"),
        BacktestTrade(1, "sell", 140.0, 48.5, "test", pnl=3.5, regime="BREAKOUT"),
    ]
    report = result.report()
    assert "Breakout P&L" in report
    assert "MeanRev P&L" in report
    assert "+10.00" in report  # $10 P&L


def test_result_win_rate():
    """Win rate across mixed results."""
    result = BacktestResult(start_balance=90.0, final_balance=90.0)
    result.trades = [
        BacktestTrade(0, "buy", 100, 10, "", regime="B"),
        BacktestTrade(1, "sell", 110, 11, "", pnl=1.0, regime="B"),  # win
        BacktestTrade(2, "buy", 110, 11, "", regime="M"),
        BacktestTrade(3, "sell", 105, 10.5, "", pnl=-0.5, regime="M"),  # loss
        BacktestTrade(4, "buy", 100, 10, "", regime="B"),
        BacktestTrade(5, "sell", 108, 10.8, "", pnl=0.8, regime="B"),  # win
    ]
    assert result.win_count == 2
    assert result.loss_count == 1
    assert abs(result.win_rate - 66.7) < 0.1
    assert result.profit_factor == 1.8 / 0.5
