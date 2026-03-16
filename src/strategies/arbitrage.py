"""DEX arbitrage strategy — finds and exploits round-trip price differences."""

import logging
import time

from src.config import config
from src.execution.executor import Executor
from src.execution.risk import RiskManager
from src.prices.aggregator import PriceAggregator, ArbitrageOpportunity
from src.strategies.base import Signal, Strategy
from src.wallet import Wallet

log = logging.getLogger(__name__)


class ArbitrageStrategy(Strategy):
    name = "arbitrage"

    def __init__(self, wallet: Wallet, risk: RiskManager):
        self.aggregator = PriceAggregator()
        self.executor = Executor(wallet, risk)
        self.risk = risk
        self.wallet = wallet
        self.last_scan = 0.0
        self.scan_interval = 5.0  # seconds between scans

    async def evaluate(self) -> list[Signal]:
        """Scan for round-trip arbitrage opportunities."""
        now = time.time()
        if now - self.last_scan < self.scan_interval:
            return []
        self.last_scan = now

        balance = await self.wallet.get_usdc_balance()
        trade_size = self.risk.get_position_size(balance, confidence=0.8)

        opportunities = await self.aggregator.find_round_trip_arb(trade_size)

        signals = []
        for opp in opportunities:
            if opp.spread_bps >= config.min_profit_bps:
                signals.append(Signal(
                    action="buy",
                    token=opp.token,
                    confidence=min(1.0, opp.spread_bps / 50),  # Higher spread = more confident
                    reason=f"Round-trip arb: {opp.spread_bps:.1f} bps spread",
                    amount_usdc=trade_size,
                ))
                log.info(
                    f"ARB SIGNAL: {opp.token} — {opp.spread_bps:.1f} bps "
                    f"(${trade_size:.2f})"
                )

        return signals

    async def execute_arb(self, opp_token: str, amount_usdc: float) -> float:
        """Execute a round-trip arbitrage trade.

        Returns profit in USDC (negative if loss).
        """
        from src.prices.aggregator import WATCHED_TOKENS

        mint = WATCHED_TOKENS.get(opp_token)
        if not mint:
            return 0.0

        amount_raw = int(amount_usdc * 1e6)

        # Step 1: USDC -> Token
        buy_result = await self.executor.execute_swap(
            config.usdc_mint, mint, amount_raw,
            slippage_bps=30, strategy="arbitrage",
        )
        if not buy_result:
            return 0.0

        token_amount = buy_result["out_amount"]

        # Step 2: Token -> USDC
        sell_result = await self.executor.execute_swap(
            mint, config.usdc_mint, token_amount,
            slippage_bps=30, strategy="arbitrage",
        )
        if not sell_result:
            log.error(f"Sell leg failed — holding {token_amount} of {opp_token}")
            return 0.0

        out_usdc = sell_result["out_amount"] / 1e6
        profit = out_usdc - amount_usdc

        log.info(f"ARB COMPLETE: {opp_token} — in: ${amount_usdc:.4f}, out: ${out_usdc:.4f}, profit: ${profit:.4f}")
        return profit

    async def close(self):
        await self.aggregator.close()
        await self.executor.close()
