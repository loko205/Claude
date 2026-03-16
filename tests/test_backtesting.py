"""Tests for backtesting engine."""

import pytest

from src.backtesting import BacktestResult, BacktestTrade, run_backtest
from src.strategies.momentum import Candle


def _make_candles(prices: list[float]) -> list[Candle]:
    """Create candles from a list of close prices."""
    return [
        Candle(timestamp=i * 900, open=p, high=p * 1.01, low=p * 0.99, close=p, volume=0)
        for i, p in enumerate(prices)
    ]


@pytest.mark.asyncio
async def test_backtest_uptrend():
    """Uptrend should generate buy signals and profit."""
    # 50 candles: sideways then strong uptrend
    prices = [100.0] * 25 + [100 + i * 2 for i in range(25)]
    candles = _make_candles(prices)
    result = await run_backtest(candles, start_balance=90.0, fast_period=5, slow_period=10)

    assert result.total_candles == 50
    assert result.start_balance == 90.0
    assert result.final_balance > 0


@pytest.mark.asyncio
async def test_backtest_downtrend():
    """Downtrend should limit losses via risk management."""
    prices = [150 - i * 1.5 for i in range(50)]
    candles = _make_candles(prices)
    result = await run_backtest(candles, start_balance=90.0, fast_period=5, slow_period=10)

    assert result.total_candles == 50
    # Should not lose everything
    assert result.final_balance > 0


@pytest.mark.asyncio
async def test_backtest_insufficient_candles():
    """Too few candles should return no trades."""
    candles = _make_candles([100.0] * 10)
    result = await run_backtest(candles, start_balance=90.0)

    assert len(result.trades) == 0
    assert result.final_balance == 90.0


def test_backtest_result_report():
    """BacktestResult.report() should produce a string."""
    result = BacktestResult(start_balance=90.0, final_balance=95.0, total_candles=100)
    result.trades = [
        BacktestTrade(0, "buy", 130.0, 9.0, "test buy"),
        BacktestTrade(1, "sell", 140.0, 9.7, "test sell"),
    ]
    report = result.report()
    assert "P&L" in report
    assert "+5.00" in report


def test_backtest_result_win_rate():
    """Win rate calculation."""
    result = BacktestResult(start_balance=90.0, final_balance=90.0)
    # 1 winning pair, 1 losing pair
    result.trades = [
        BacktestTrade(0, "buy", 100.0, 10.0, ""),
        BacktestTrade(1, "sell", 110.0, 11.0, ""),  # win
        BacktestTrade(2, "buy", 110.0, 11.0, ""),
        BacktestTrade(3, "sell", 105.0, 10.5, ""),  # loss
    ]
    assert result.win_count == 1
    assert result.loss_count == 1
    assert result.win_rate == 50.0
