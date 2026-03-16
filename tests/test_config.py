"""Tests for config module."""

import os

from src.config import Config


def test_default_config():
    cfg = Config()
    assert cfg.paper_trading is True
    assert cfg.max_trade_size_usdc == 10.0
    assert cfg.min_profit_bps == 10
    assert cfg.usdc_mint == "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"


def test_config_from_env(monkeypatch):
    monkeypatch.setenv("PAPER_TRADING", "false")
    monkeypatch.setenv("MAX_TRADE_SIZE_USDC", "25")
    monkeypatch.setenv("MIN_PROFIT_BPS", "20")

    cfg = Config.from_env()
    assert cfg.paper_trading is False
    assert cfg.max_trade_size_usdc == 25.0
    assert cfg.min_profit_bps == 20
