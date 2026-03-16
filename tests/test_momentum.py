"""Tests for regime-adaptive momentum strategy indicators."""

from src.strategies.momentum import Candle, MomentumStrategy


def _candles_from_prices(prices: list[float]) -> list[Candle]:
    candles = []
    for i, p in enumerate(prices):
        prev = prices[i - 1] if i > 0 else p
        candles.append(Candle(
            timestamp=i * 900,
            open=prev,
            high=max(p, prev) * 1.005,
            low=min(p, prev) * 0.995,
            close=p,
            volume=1e6,
        ))
    return candles


def test_ema_calculation():
    strategy = MomentumStrategy(fast_period=3, slow_period=5)
    prices = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    ema = strategy.calc_ema(prices, period=3)
    assert len(ema) > 0
    assert ema[-1] > ema[0]


def test_ema_insufficient_data():
    strategy = MomentumStrategy()
    ema = strategy.calc_ema([1, 2], period=10)
    assert ema == []


def test_rsi_calculation():
    strategy = MomentumStrategy()
    # Rising prices → RSI > 50
    prices = list(range(1, 20))
    rsi = strategy.calc_rsi(prices, period=14)
    assert rsi is not None
    assert rsi > 50

    # Falling prices → RSI < 50
    falling = list(range(20, 1, -1))
    rsi_fall = strategy.calc_rsi(falling, period=14)
    assert rsi_fall is not None
    assert rsi_fall < 50


def test_rsi_insufficient_data():
    strategy = MomentumStrategy()
    rsi = strategy.calc_rsi([1, 2, 3], period=14)
    assert rsi is None


def test_atr_calculation():
    strategy = MomentumStrategy()
    candles = _candles_from_prices([100 + i for i in range(20)])
    atr = strategy.calc_atr(candles, period=14)
    assert atr is not None
    assert atr > 0


def test_atr_insufficient_data():
    strategy = MomentumStrategy()
    candles = _candles_from_prices([100, 101, 102])
    atr = strategy.calc_atr(candles, period=14)
    assert atr is None


def test_adx_trending():
    strategy = MomentumStrategy()
    # Strong uptrend should give higher ADX
    prices = [100 + i * 2 for i in range(60)]
    candles = _candles_from_prices(prices)
    adx = strategy.calc_adx(candles, period=14)
    assert adx is not None
    assert adx > 0


def test_donchian_channel():
    strategy = MomentumStrategy()
    prices = list(range(90, 130))  # steadily rising
    candles = _candles_from_prices(prices)
    result = strategy.calc_donchian(candles, period=20)
    assert result is not None
    upper, lower = result
    assert upper > lower
    # Should exclude current candle
    assert upper < candles[-1].high  # current candle not included


def test_bollinger_bands():
    strategy = MomentumStrategy()
    prices = [100 + (i % 5 - 2) * 2 for i in range(30)]  # oscillating
    result = strategy.calc_bollinger(prices, period=20, num_std=2.0)
    assert result is not None
    upper, middle, lower = result
    assert upper > middle > lower


def test_bollinger_insufficient_data():
    strategy = MomentumStrategy()
    result = strategy.calc_bollinger([100, 101], period=20)
    assert result is None
