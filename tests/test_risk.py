"""Tests for risk management."""

import time

from src.execution.risk import RiskManager, TradeRecord


def test_can_trade_within_limits():
    risk = RiskManager()
    ok, reason = risk.can_trade(5.0)
    assert ok is True
    assert reason == "ok"


def test_blocks_oversized_trade():
    risk = RiskManager()
    ok, reason = risk.can_trade(999.0)
    assert ok is False
    assert "exceeds max" in reason


def test_daily_loss_limit():
    risk = RiskManager()
    # Simulate losses
    for i in range(10):
        risk.record_trade(TradeRecord(
            timestamp=time.time(),
            token="SOL",
            side="swap",
            amount_usdc=5.0,
            profit_usdc=-3.0,
            strategy="test",
        ))

    ok, reason = risk.can_trade(5.0)
    assert ok is False
    assert "loss limit" in reason.lower() or "paused" in reason.lower()


def test_consecutive_loss_cooldown():
    risk = RiskManager()
    for i in range(5):
        risk.record_trade(TradeRecord(
            timestamp=time.time(),
            token="SOL",
            side="swap",
            amount_usdc=1.0,
            profit_usdc=-0.1,
            strategy="test",
        ))

    ok, reason = risk.can_trade(1.0)
    assert ok is False
    assert "consecutive" in reason.lower() or "loss limit" in reason.lower()


def test_position_sizing():
    risk = RiskManager()
    size = risk.get_position_size(100.0, confidence=1.0)
    assert size == 10.0  # 10% of 100, capped at max_trade_size

    size_low = risk.get_position_size(100.0, confidence=0.3)
    assert size_low < size


def test_winning_trades_reset_consecutive_losses():
    risk = RiskManager()
    for i in range(3):
        risk.record_trade(TradeRecord(
            timestamp=time.time(), token="SOL", side="swap",
            amount_usdc=1.0, profit_usdc=-0.1, strategy="test",
        ))
    assert risk.consecutive_losses == 3

    risk.record_trade(TradeRecord(
        timestamp=time.time(), token="SOL", side="swap",
        amount_usdc=1.0, profit_usdc=0.5, strategy="test",
    ))
    assert risk.consecutive_losses == 0
