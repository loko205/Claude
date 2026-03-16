"""Tests for momentum strategy calculations."""

from src.strategies.momentum import MomentumStrategy


def test_ema_calculation():
    strategy = MomentumStrategy(fast_period=3, slow_period=5)
    prices = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]

    ema = strategy.calc_ema(prices, period=3)
    assert len(ema) > 0
    # EMA should be close to recent prices and trending up
    assert ema[-1] > ema[0]


def test_ema_insufficient_data():
    strategy = MomentumStrategy()
    ema = strategy.calc_ema([1, 2], period=10)
    assert ema == []


def test_rsi_calculation():
    strategy = MomentumStrategy()
    # Steadily rising prices should give RSI > 50
    prices = list(range(1, 20))
    rsi = strategy.calc_rsi(prices, period=14)
    assert rsi is not None
    assert rsi > 50

    # Steadily falling prices should give RSI < 50
    falling = list(range(20, 1, -1))
    rsi_fall = strategy.calc_rsi(falling, period=14)
    assert rsi_fall is not None
    assert rsi_fall < 50


def test_rsi_insufficient_data():
    strategy = MomentumStrategy()
    rsi = strategy.calc_rsi([1, 2, 3], period=14)
    assert rsi is None
