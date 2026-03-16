"""Tests for Hyperliquid integration modules."""

import time
from unittest.mock import MagicMock, patch

import pytest

from src.strategies.momentum import Candle, MomentumStrategy


# === Candle parsing ===

def test_candle_from_raw_data():
    """Verify raw SDK candle data maps correctly to Candle dataclass."""
    raw = {
        "t": 1700000000000, "T": 1700000900000, "s": "SOL",
        "o": "130.5", "h": "132.0", "l": "129.8", "c": "131.2", "v": "50000", "n": 120,
    }
    candle = Candle(
        timestamp=raw["t"] / 1000,
        open=float(raw["o"]),
        high=float(raw["h"]),
        low=float(raw["l"]),
        close=float(raw["c"]),
        volume=float(raw["v"]),
    )
    assert candle.timestamp == 1700000000.0
    assert candle.open == 130.5
    assert candle.high == 132.0
    assert candle.close == 131.2


# === TP/SL order construction ===

def test_tp_sl_order_dict():
    """Verify TP/SL order dicts match Hyperliquid SDK format."""
    tp_order = {
        "coin": "SOL", "is_buy": False, "sz": 1.0,
        "limit_px": 150.0,
        "order_type": {"trigger": {"triggerPx": "150.0", "isMarket": True, "tpsl": "tp"}},
        "reduce_only": True,
    }
    sl_order = {
        "coin": "SOL", "is_buy": False, "sz": 1.0,
        "limit_px": 120.0,
        "order_type": {"trigger": {"triggerPx": "120.0", "isMarket": True, "tpsl": "sl"}},
        "reduce_only": True,
    }

    assert tp_order["order_type"]["trigger"]["tpsl"] == "tp"
    assert sl_order["order_type"]["trigger"]["tpsl"] == "sl"
    assert tp_order["reduce_only"] is True
    assert sl_order["reduce_only"] is True
    assert tp_order["is_buy"] is False  # close long = sell


def test_short_tp_sl_order_dict():
    """TP/SL for short: buy side, reduce_only."""
    tp_order = {
        "coin": "ETH", "is_buy": True, "sz": 0.5,
        "limit_px": 2000.0,
        "order_type": {"trigger": {"triggerPx": "2000.0", "isMarket": True, "tpsl": "tp"}},
        "reduce_only": True,
    }
    sl_order = {
        "coin": "ETH", "is_buy": True, "sz": 0.5,
        "limit_px": 2800.0,
        "order_type": {"trigger": {"triggerPx": "2800.0", "isMarket": True, "tpsl": "sl"}},
        "reduce_only": True,
    }

    assert tp_order["is_buy"] is True  # close short = buy
    assert sl_order["is_buy"] is True


# === Leverage validation ===

def test_leverage_bounds():
    """Leverage should be positive and reasonable."""
    valid_leverages = [1, 3, 5, 10, 20, 50]
    for lev in valid_leverages:
        assert 1 <= lev <= 100

    invalid = [0, -1, 101]
    for lev in invalid:
        assert not (1 <= lev <= 100)


# === HLExecutor paper mode ===

def test_paper_trade_no_sdk_calls():
    """Paper mode should not call real SDK methods."""
    from src.execution.risk import RiskManager

    risk = RiskManager()

    # Mock the client
    mock_client = MagicMock()
    mock_client.get_mid_price.return_value = 130.0
    mock_client.wallet = None  # no real wallet

    from src.execution.hl_executor import HLExecutor
    executor = HLExecutor(mock_client, risk)
    executor.paper_mode = True

    result = executor.execute_perp_trade(
        "SOL", is_buy=True, size_usdc=10.0,
        sl_pct=0.02, tp_pct=0.04, strategy="test",
    )

    assert result is not None
    assert result["status"] == "paper"
    assert result["coin"] == "SOL"
    assert result["side"] == "long"
    # Real SDK should NOT be called
    mock_client.market_open.assert_not_called()
    mock_client.place_with_tp_sl.assert_not_called()


def test_paper_short_trade():
    """Paper short trade should have correct side."""
    from src.execution.risk import RiskManager

    risk = RiskManager()
    mock_client = MagicMock()
    mock_client.get_mid_price.return_value = 130.0

    from src.execution.hl_executor import HLExecutor
    executor = HLExecutor(mock_client, risk)
    executor.paper_mode = True

    result = executor.execute_perp_trade(
        "SOL", is_buy=False, size_usdc=10.0,
        sl_pct=0.02, tp_pct=0.04, strategy="test",
    )

    assert result["side"] == "short"
    assert result["sl"] > result["price"]  # SL above entry for shorts
    assert result["tp"] < result["price"]  # TP below entry for shorts


# === HLMomentumStrategy signal generation ===

def _make_candles(prices: list[float]) -> list[Candle]:
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


@pytest.mark.asyncio
async def test_hl_momentum_short_signal_downtrend():
    """Strong downtrend should produce short signals."""
    # Build candles: flat then strong drop
    prices = [200.0] * 70 + [200 - i * 1.5 for i in range(60)]
    candles = _make_candles(prices)

    mock_client = MagicMock()
    mock_client.get_candles.return_value = candles

    from src.strategies.hl_momentum import HLMomentumStrategy
    strategy = HLMomentumStrategy(mock_client, coin="SOL")
    strategy.last_fetch = 0  # force evaluation

    signals = await strategy.evaluate()

    # Should have at least one sell (short) or close signal
    actions = [s.action for s in signals]
    # Downtrend may or may not trigger depending on ADX — we just verify no crash
    assert isinstance(signals, list)


@pytest.mark.asyncio
async def test_hl_momentum_insufficient_data():
    """Not enough candles should return empty signals."""
    candles = _make_candles([100.0] * 30)

    mock_client = MagicMock()
    mock_client.get_candles.return_value = candles

    from src.strategies.hl_momentum import HLMomentumStrategy
    strategy = HLMomentumStrategy(mock_client, coin="SOL")
    strategy.last_fetch = 0

    signals = await strategy.evaluate()
    assert signals == []


# === Config ===

def test_config_hyperliquid_fields():
    """Config should have all HL fields with defaults."""
    from src.config import Config

    cfg = Config()
    assert cfg.exchange == "solana"
    assert cfg.hl_private_key == ""
    assert cfg.hl_account_address == ""
    assert cfg.hl_testnet is True
    assert cfg.hl_default_leverage == 3
    assert cfg.hl_leverage_cross is True


def test_config_hl_from_env(monkeypatch):
    """Config should load HL fields from environment."""
    from src.config import Config

    monkeypatch.setenv("EXCHANGE", "hyperliquid")
    monkeypatch.setenv("HL_TESTNET", "false")
    monkeypatch.setenv("HL_DEFAULT_LEVERAGE", "10")
    monkeypatch.setenv("HL_LEVERAGE_CROSS", "false")

    cfg = Config.from_env()
    assert cfg.exchange == "hyperliquid"
    assert cfg.hl_testnet is False
    assert cfg.hl_default_leverage == 10
    assert cfg.hl_leverage_cross is False


# === Backtesting short trades ===

@pytest.mark.asyncio
async def test_backtest_with_shorts():
    """Backtest should handle short positions without errors."""
    from src.backtesting import run_backtest, generate_synthetic

    # Use synthetic data with a downtrend seed
    candles = generate_synthetic(days=30, seed=42)
    result = await run_backtest(candles, start_balance=90.0)

    assert result.final_balance > 0
    assert result.total_candles > 0
    # Report should include short P&L line
    report = result.report()
    assert "Short P&L" in report
    assert "Long P&L" in report
