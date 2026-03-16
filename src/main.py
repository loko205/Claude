"""Main entry point — orchestrates strategies and the trading loop."""

import asyncio
import logging
import signal
import sys

from rich.console import Console
from rich.logging import RichHandler

from src.config import config
from src.execution.risk import RiskManager
from src.monitoring.tracker import Tracker

console = Console()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[RichHandler(console=console, rich_tracebacks=True)],
)
log = logging.getLogger(__name__)

LOOP_INTERVAL = 3  # seconds between strategy evaluation cycles


async def run_solana(risk: RiskManager):
    """Run the Solana/Jupiter trading loop."""
    from src.execution.executor import Executor
    from src.strategies.arbitrage import ArbitrageStrategy
    from src.strategies.momentum import MomentumStrategy
    from src.wallet import Wallet

    wallet = Wallet()

    if wallet.pubkey:
        balance = await wallet.get_balance()
        console.print(f"Wallet: {wallet.pubkey}")
        console.print(f"Balance: {balance.sol:.4f} SOL, {balance.usdc:.2f} USDC")
        balance_usdc = balance.usdc
    else:
        console.print("[yellow]No wallet configured — monitoring mode[/yellow]")
        balance_usdc = 90.0

    tracker = Tracker(risk, initial_balance=balance_usdc)
    arb_strategy = ArbitrageStrategy(wallet, risk)
    momentum_strategy = MomentumStrategy()

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
            arb_signals = await arb_strategy.evaluate()
            momentum_signals = await momentum_strategy.evaluate()

            for sig in arb_signals:
                if sig.action == "buy" and sig.amount_usdc:
                    profit = await arb_strategy.execute_arb(sig.token, sig.amount_usdc)
                    if profit != 0:
                        console.print(
                            f"  ARB {sig.token}: ${profit:+.4f} "
                            f"({'[green]WIN' if profit > 0 else '[red]LOSS'}[/])"
                        )

            for sig in momentum_signals:
                executor = Executor(wallet, risk)
                if sig.action == "buy":
                    size = risk.get_position_size(balance_usdc, sig.confidence)
                    amount_raw = int(size * 1e6)
                    await executor.execute_swap(
                        config.usdc_mint, config.sol_mint, amount_raw,
                        strategy="momentum",
                    )
                elif sig.action == "sell":
                    if wallet.pubkey:
                        sol_balance = await wallet.get_sol_balance()
                        sell_amount = int((sol_balance - 0.01) * 1e9)
                        if sell_amount > 0:
                            await executor.execute_swap(
                                config.sol_mint, config.usdc_mint, sell_amount,
                                strategy="momentum",
                            )
                await executor.close()

            if cycle % 20 == 0:
                tracker.print_status(balance_usdc)
                tracker.save_trades()

            await asyncio.sleep(LOOP_INTERVAL)

    finally:
        console.print("\n[cyan]Final status:[/cyan]")
        tracker.print_status(balance_usdc)
        tracker.print_recent_trades()
        tracker.save_trades()
        await arb_strategy.close()
        await momentum_strategy.close()
        await wallet.close()


async def run_hyperliquid(risk: RiskManager):
    """Run the Hyperliquid perpetuals trading loop."""
    from src.exchanges.hyperliquid import HyperliquidClient
    from src.execution.hl_executor import HLExecutor
    from src.strategies.hl_momentum import HLMomentumStrategy

    client = HyperliquidClient()
    executor = HLExecutor(client, risk)
    balance_usdc = client.get_balance() if client.wallet else 90.0

    console.print(f"Balance: ${balance_usdc:.2f} USDC")
    positions = client.get_all_positions()
    if positions:
        for p in positions:
            console.print(f"  Position: {p['coin']} {p['size']:+.4f} PnL=${p['unrealized_pnl']:+.2f}")
    console.print()

    tracker = Tracker(risk, initial_balance=balance_usdc)
    strategy = HLMomentumStrategy(client, coin="SOL")

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
            signals = await strategy.evaluate()

            for sig in signals:
                if sig.action == "buy":
                    size = risk.get_position_size(balance_usdc, sig.confidence)
                    executor.execute_perp_trade(
                        sig.token, is_buy=True, size_usdc=size,
                        sl_pct=0.02, tp_pct=0.04, strategy="hl_momentum",
                    )
                elif sig.action == "sell":
                    size = risk.get_position_size(balance_usdc, sig.confidence)
                    executor.execute_perp_trade(
                        sig.token, is_buy=False, size_usdc=size,
                        sl_pct=0.02, tp_pct=0.04, strategy="hl_momentum",
                    )
                elif sig.action in ("close_long", "close_short"):
                    executor.close_position(sig.token, strategy="hl_momentum")

            if cycle % 20 == 0:
                balance_usdc = client.get_balance() if client.wallet else balance_usdc
                tracker.print_status(balance_usdc)
                tracker.save_trades()

            await asyncio.sleep(LOOP_INTERVAL)

    finally:
        console.print("\n[cyan]Final status:[/cyan]")
        balance_usdc = client.get_balance() if client.wallet else balance_usdc
        tracker.print_status(balance_usdc)
        tracker.print_recent_trades()
        tracker.save_trades()
        await strategy.close()


async def main():
    exchange = config.exchange
    console.print(f"[bold cyan]Trading Bot — {exchange.upper()}[/bold cyan]")
    console.print(f"Mode: {'[yellow]PAPER TRADING[/yellow]' if config.paper_trading else '[red]LIVE TRADING[/red]'}")
    console.print(f"Max trade size: ${config.max_trade_size_usdc}")
    console.print(f"Daily loss limit: ${config.daily_loss_limit_usdc}")
    console.print()

    risk = RiskManager()

    if exchange == "hyperliquid":
        console.print(f"Leverage: {config.hl_default_leverage}x {'cross' if config.hl_leverage_cross else 'isolated'}")
        console.print(f"Network: {'testnet' if config.hl_testnet else '[red]MAINNET[/red]'}")
        await run_hyperliquid(risk)
    else:
        console.print(f"Min profit: {config.min_profit_bps} bps")
        await run_solana(risk)

    console.print("[green]Bot stopped cleanly.[/green]")


if __name__ == "__main__":
    asyncio.run(main())
