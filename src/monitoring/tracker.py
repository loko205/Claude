"""P&L tracker and trade history."""

import json
import logging
import time
from dataclasses import asdict
from pathlib import Path

from rich.console import Console
from rich.table import Table

from src.execution.risk import RiskManager, TradeRecord

log = logging.getLogger(__name__)
console = Console()

TRADE_LOG = Path("trades.json")


class Tracker:
    def __init__(self, risk: RiskManager, initial_balance: float = 90.0):
        self.risk = risk
        self.initial_balance = initial_balance
        self.start_time = time.time()

    def save_trades(self):
        """Save trade history to JSON."""
        trades = [asdict(t) for t in self.risk.trades]
        TRADE_LOG.write_text(json.dumps(trades, indent=2))

    def print_status(self, current_balance: float):
        """Print a nice status overview to console."""
        elapsed = time.time() - self.start_time
        hours = elapsed / 3600
        total_pnl = current_balance - self.initial_balance
        pnl_pct = (total_pnl / self.initial_balance) * 100

        table = Table(title="Trading Bot Status")
        table.add_column("Metric", style="cyan")
        table.add_column("Value", style="green")

        table.add_row("Initial Balance", f"${self.initial_balance:.2f}")
        table.add_row("Current Balance", f"${current_balance:.2f}")
        table.add_row("Total P&L", f"${total_pnl:+.4f} ({pnl_pct:+.2f}%)")
        table.add_row("Daily P&L", f"${self.risk.daily_pnl:+.4f}")
        table.add_row("Total Trades", str(len(self.risk.trades)))
        table.add_row("Running Time", f"{hours:.1f}h")
        table.add_row("Consecutive Losses", str(self.risk.consecutive_losses))
        table.add_row("Status", "PAUSED" if self.risk.is_paused else "ACTIVE")

        console.print(table)

    def print_recent_trades(self, n: int = 10):
        """Print last N trades."""
        trades = self.risk.trades[-n:]
        if not trades:
            console.print("[yellow]No trades yet[/yellow]")
            return

        table = Table(title=f"Last {n} Trades")
        table.add_column("Time", style="dim")
        table.add_column("Token")
        table.add_column("Side")
        table.add_column("Amount")
        table.add_column("P&L", style="green")
        table.add_column("Strategy")

        for t in trades:
            pnl_style = "green" if t.profit_usdc >= 0 else "red"
            table.add_row(
                time.strftime("%H:%M:%S", time.localtime(t.timestamp)),
                t.token,
                t.side,
                f"${t.amount_usdc:.2f}",
                f"[{pnl_style}]${t.profit_usdc:+.4f}[/{pnl_style}]",
                t.strategy,
            )

        console.print(table)
