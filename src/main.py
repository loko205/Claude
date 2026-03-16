"""Main entry point — orchestrates strategies and the trading loop."""

import asyncio
import logging
import signal
import sys

from rich.console import Console
from rich.logging import RichHandler

from src.config import config
from src.execution.executor import Executor
from src.execution.risk import RiskManager
from src.monitoring.tracker import Tracker
from src.strategies.arbitrage import ArbitrageStrategy
from src.strategies.momentum import MomentumStrategy
from src.wallet import Wallet

console = Console()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[RichHandler(console=console, rich_tracebacks=True)],
)
log = logging.getLogger(__name__)

LOOP_INTERVAL = 3  # seconds between strategy evaluation cycles


async def main():
    console.print("[bold cyan]Solana Trading Bot[/bold cyan]")
    console.print(f"Mode: {'[yellow]PAPER TRADING[/yellow]' if config.paper_trading else '[red]LIVE TRADING[/red]'}")
    console.print(f"Max trade size: ${config.max_trade_size_usdc}")
    console.print(f"Daily loss limit: ${config.daily_loss_limit_usdc}")
    console.print(f"Min profit: {config.min_profit_bps} bps")
    console.print()

    # Initialize components
    wallet = Wallet()
    risk = RiskManager()

    if wallet.pubkey:
        balance = await wallet.get_balance()
        console.print(f"Wallet: {wallet.pubkey}")
        console.print(f"Balance: {balance.sol:.4f} SOL, {balance.usdc:.2f} USDC")
    else:
        console.print("[yellow]No wallet configured — running in monitoring mode[/yellow]")
        balance_usdc = 90.0  # simulated

    tracker = Tracker(risk, initial_balance=balance.usdc if wallet.pubkey else 90.0)

    # Initialize strategies
    arb_strategy = ArbitrageStrategy(wallet, risk)
    momentum_strategy = MomentumStrategy()

    # Graceful shutdown
    running = True

    def shutdown(sig, frame):
        nonlocal running
        console.print("\n[yellow]Shutting down...[/yellow]")
        running = False

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    console.print("[green]Bot started — press Ctrl+C to stop[/green]\n")

    cycle = 0
    try:
        while running:
            cycle += 1

            # Evaluate strategies
            arb_signals = await arb_strategy.evaluate()
            momentum_signals = await momentum_strategy.evaluate()

            # Execute arbitrage signals
            for sig in arb_signals:
                if sig.action == "buy" and sig.amount_usdc:
                    profit = await arb_strategy.execute_arb(
                        sig.token, sig.amount_usdc
                    )
                    if profit != 0:
                        console.print(
                            f"  ARB {sig.token}: ${profit:+.4f} "
                            f"({'[green]WIN' if profit > 0 else '[red]LOSS'}[/])"
                        )

            # Execute momentum signals
            for sig in momentum_signals:
                executor = Executor(wallet, risk)
                if sig.action == "buy":
                    size = risk.get_position_size(
                        balance.usdc if wallet.pubkey else 90.0,
                        sig.confidence,
                    )
                    amount_raw = int(size * 1e6)
                    await executor.execute_swap(
                        config.usdc_mint, config.sol_mint, amount_raw,
                        strategy="momentum",
                    )
                elif sig.action == "sell":
                    # Sell all SOL back to USDC
                    if wallet.pubkey:
                        sol_balance = await wallet.get_sol_balance()
                        # Keep 0.01 SOL for fees
                        sell_amount = int((sol_balance - 0.01) * 1e9)
                        if sell_amount > 0:
                            await executor.execute_swap(
                                config.sol_mint, config.usdc_mint, sell_amount,
                                strategy="momentum",
                            )
                await executor.close()

            # Periodic status update
            if cycle % 20 == 0:
                current_balance = balance.usdc if wallet.pubkey else 90.0
                tracker.print_status(current_balance)
                tracker.save_trades()

            await asyncio.sleep(LOOP_INTERVAL)

    finally:
        console.print("\n[cyan]Final status:[/cyan]")
        tracker.print_status(balance.usdc if wallet.pubkey else 90.0)
        tracker.print_recent_trades()
        tracker.save_trades()

        await arb_strategy.close()
        await momentum_strategy.close()
        await wallet.close()

        console.print("[green]Bot stopped cleanly.[/green]")


if __name__ == "__main__":
    asyncio.run(main())
