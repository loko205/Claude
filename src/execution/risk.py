"""Risk management — position sizing, loss limits, trade guards."""

import logging
import time
from dataclasses import dataclass, field

from src.config import config

log = logging.getLogger(__name__)


@dataclass
class TradeRecord:
    timestamp: float
    token: str
    side: str  # "buy" or "sell"
    amount_usdc: float
    profit_usdc: float
    strategy: str


class RiskManager:
    def __init__(self):
        self.trades: list[TradeRecord] = []
        self.daily_pnl: float = 0.0
        self.last_reset: float = time.time()
        self.consecutive_losses: int = 0
        self.is_paused: bool = False

    def can_trade(self, amount_usdc: float) -> tuple[bool, str]:
        """Check if a trade is allowed under current risk constraints."""
        self._maybe_reset_daily()

        if self.is_paused:
            return False, "Trading paused — manual resume required"

        if amount_usdc > config.max_trade_size_usdc:
            return False, f"Trade size ${amount_usdc:.2f} exceeds max ${config.max_trade_size_usdc:.2f}"

        if abs(self.daily_pnl) >= config.daily_loss_limit_usdc and self.daily_pnl < 0:
            self.is_paused = True
            return False, f"Daily loss limit hit: ${self.daily_pnl:.2f}"

        if self.consecutive_losses >= 5:
            return False, f"5 consecutive losses — cooling down"

        return True, "ok"

    def record_trade(self, trade: TradeRecord):
        """Record a completed trade and update risk metrics."""
        self.trades.append(trade)
        self.daily_pnl += trade.profit_usdc

        if trade.profit_usdc < 0:
            self.consecutive_losses += 1
        else:
            self.consecutive_losses = 0

        log.info(
            f"Trade recorded: {trade.side} {trade.token} "
            f"${trade.amount_usdc:.2f} P&L: ${trade.profit_usdc:.4f} "
            f"Daily P&L: ${self.daily_pnl:.4f}"
        )

    def get_position_size(self, balance_usdc: float, confidence: float = 1.0) -> float:
        """Calculate position size based on balance and confidence.

        Uses a conservative Kelly-inspired sizing:
        - Base: 10% of balance
        - Scaled by confidence (0-1)
        - Capped at max_trade_size
        """
        base_size = balance_usdc * 0.10
        sized = base_size * max(0.1, min(1.0, confidence))
        return min(sized, config.max_trade_size_usdc)

    def _maybe_reset_daily(self):
        """Reset daily P&L every 24 hours."""
        now = time.time()
        if now - self.last_reset > 86400:
            log.info(f"Daily reset — final P&L: ${self.daily_pnl:.4f}")
            self.daily_pnl = 0.0
            self.last_reset = now
            self.consecutive_losses = 0
            self.is_paused = False

    def summary(self) -> dict:
        """Return current risk status."""
        return {
            "daily_pnl": self.daily_pnl,
            "total_trades": len(self.trades),
            "consecutive_losses": self.consecutive_losses,
            "is_paused": self.is_paused,
        }
