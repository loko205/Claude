"""Trade executor — handles swap execution via Jupiter on Solana."""

import base64
import logging
import time

from solders.keypair import Keypair
from solders.transaction import VersionedTransaction

from src.config import config
from src.execution.risk import RiskManager, TradeRecord
from src.prices.jupiter import JupiterClient, Quote
from src.wallet import Wallet

log = logging.getLogger(__name__)


class Executor:
    def __init__(self, wallet: Wallet, risk: RiskManager):
        self.wallet = wallet
        self.risk = risk
        self.jupiter = JupiterClient()
        self.paper_mode = config.paper_trading

    async def execute_swap(
        self,
        input_mint: str,
        output_mint: str,
        amount: int,
        slippage_bps: int = 50,
        strategy: str = "unknown",
    ) -> dict | None:
        """Execute a token swap.

        In paper mode, simulates the trade using Jupiter quotes.
        In live mode, signs and submits the transaction.
        """
        # Get quote
        quote = await self.jupiter.get_quote(
            input_mint, output_mint, amount, slippage_bps
        )
        if not quote:
            log.error("No quote available")
            return None

        # Check amount in USDC terms
        if input_mint == config.usdc_mint:
            amount_usdc = amount / 1e6
        else:
            amount_usdc = config.max_trade_size_usdc  # conservative estimate

        ok, reason = self.risk.can_trade(amount_usdc)
        if not ok:
            log.warning(f"Trade blocked by risk manager: {reason}")
            return None

        if self.paper_mode:
            return await self._paper_trade(quote, amount_usdc, strategy)
        else:
            return await self._live_trade(quote, amount_usdc, strategy)

    async def _paper_trade(
        self, quote: Quote, amount_usdc: float, strategy: str
    ) -> dict:
        """Simulate a trade using the quote."""
        log.info(
            f"[PAPER] Swap {quote.in_amount} {quote.input_mint[:8]}... "
            f"-> {quote.out_amount} {quote.output_mint[:8]}... "
            f"(impact: {quote.price_impact_pct:.4f}%)"
        )

        # For round-trip arb, profit is calculated by the strategy
        self.risk.record_trade(TradeRecord(
            timestamp=time.time(),
            token=quote.output_mint[:8],
            side="swap",
            amount_usdc=amount_usdc,
            profit_usdc=0,  # Strategy calculates this
            strategy=strategy,
        ))

        return {
            "status": "paper",
            "in_amount": quote.in_amount,
            "out_amount": quote.out_amount,
            "price_impact": quote.price_impact_pct,
        }

    async def _live_trade(
        self, quote: Quote, amount_usdc: float, strategy: str
    ) -> dict | None:
        """Execute a real on-chain swap."""
        if not self.wallet.keypair:
            log.error("No keypair — cannot execute live trade")
            return None

        pubkey = str(self.wallet.pubkey)
        swap_tx = await self.jupiter.get_swap_transaction(quote, pubkey)
        if not swap_tx:
            log.error("Failed to get swap transaction")
            return None

        try:
            # Deserialize, sign, and send
            tx_bytes = base64.b64decode(swap_tx)
            tx = VersionedTransaction.from_bytes(tx_bytes)
            signed_tx = VersionedTransaction(tx.message, [self.wallet.keypair])
            signed_bytes = bytes(signed_tx)

            # Send via RPC
            result = await self.wallet._rpc(
                "sendTransaction",
                [base64.b64encode(signed_bytes).decode(), {"encoding": "base64"}],
            )

            tx_sig = result
            log.info(f"[LIVE] TX sent: {tx_sig}")

            self.risk.record_trade(TradeRecord(
                timestamp=time.time(),
                token=quote.output_mint[:8],
                side="swap",
                amount_usdc=amount_usdc,
                profit_usdc=0,
                strategy=strategy,
            ))

            return {"status": "live", "signature": tx_sig}

        except Exception as e:
            log.error(f"Transaction execution failed: {e}")
            return None

    async def close(self):
        await self.jupiter.close()
