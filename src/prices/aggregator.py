"""Multi-source price aggregator — finds arbitrage opportunities across DEXs."""

import asyncio
import logging
import time
from dataclasses import dataclass

from src.config import config
from src.prices.jupiter import JupiterClient

log = logging.getLogger(__name__)

# Popular Solana tokens to monitor for arbitrage
WATCHED_TOKENS = {
    "SOL": config.sol_mint,
    "USDC": config.usdc_mint,
    "BONK": "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",
    "JUP": "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN",
    "RAY": "4k3Dyjzvzp8eMZWUXbBCjEvwSkkk59S5iCNLY3QrkX6R",
    "ORCA": "orcaEKTdK7LKz57vaAYr9QeNsVEPfiu6QeMU1kektZE",
}


@dataclass
class PriceEntry:
    token: str
    mint: str
    price_usdc: float
    timestamp: float
    source: str


@dataclass
class ArbitrageOpportunity:
    token: str
    buy_source: str
    sell_source: str
    buy_price: float
    sell_price: float
    spread_bps: float  # profit in basis points
    timestamp: float


class PriceAggregator:
    def __init__(self):
        self.jupiter = JupiterClient()
        self.prices: dict[str, list[PriceEntry]] = {}

    async def fetch_jupiter_prices(self) -> list[PriceEntry]:
        """Fetch prices for all watched tokens from Jupiter."""
        entries = []
        now = time.time()

        tasks = []
        for name, mint in WATCHED_TOKENS.items():
            if name == "USDC":
                continue
            tasks.append((name, mint, self.jupiter.get_price(mint)))

        results = await asyncio.gather(
            *[t[2] for t in tasks], return_exceptions=True
        )

        for (name, mint, _), result in zip(tasks, results):
            if isinstance(result, Exception):
                log.warning(f"Failed to fetch {name} price: {result}")
                continue
            if result is not None:
                entries.append(PriceEntry(
                    token=name, mint=mint, price_usdc=result,
                    timestamp=now, source="jupiter",
                ))

        return entries

    async def fetch_quote_prices(self, amount_usdc: float = 10.0) -> list[PriceEntry]:
        """Fetch effective prices via actual quotes (more accurate for arb).

        This gets the real executable price including slippage.
        """
        entries = []
        now = time.time()
        amount_raw = int(amount_usdc * 1e6)  # USDC has 6 decimals

        tasks = []
        for name, mint in WATCHED_TOKENS.items():
            if name == "USDC":
                continue
            # Quote: USDC -> Token (buy price)
            tasks.append((
                name, mint, "buy",
                self.jupiter.get_quote(config.usdc_mint, mint, amount_raw),
            ))
            # Quote: Token -> USDC (sell price) — need to estimate token amount
            # We'll use a round-trip approach in arbitrage detection instead

        results = await asyncio.gather(
            *[t[3] for t in tasks], return_exceptions=True
        )

        for (name, mint, side, _), result in zip(tasks, results):
            if isinstance(result, Exception) or result is None:
                continue

            # Effective price = how much token you get per USDC
            effective_price = amount_usdc / (result.out_amount / self._get_decimals(name))
            entries.append(PriceEntry(
                token=name, mint=mint, price_usdc=effective_price,
                timestamp=now, source="jupiter_quote",
            ))

        return entries

    async def find_round_trip_arb(self, amount_usdc: float = 10.0) -> list[ArbitrageOpportunity]:
        """Find round-trip arbitrage: USDC -> Token -> USDC.

        This checks if buying a token and immediately selling it back
        yields more USDC than we started with (after fees).
        """
        opportunities = []
        now = time.time()
        amount_raw = int(amount_usdc * 1e6)

        for name, mint in WATCHED_TOKENS.items():
            if name == "USDC":
                continue

            try:
                # Step 1: Buy token with USDC
                buy_quote = await self.jupiter.get_quote(
                    config.usdc_mint, mint, amount_raw, slippage_bps=30,
                )
                if not buy_quote:
                    continue

                # Step 2: Sell token back to USDC
                sell_quote = await self.jupiter.get_quote(
                    mint, config.usdc_mint, buy_quote.out_amount, slippage_bps=30,
                )
                if not sell_quote:
                    continue

                # Calculate profit
                out_usdc = sell_quote.out_amount / 1e6
                profit_bps = ((out_usdc - amount_usdc) / amount_usdc) * 10000

                if profit_bps > -100:  # Log even small losses for monitoring
                    log.info(
                        f"Round-trip {name}: ${amount_usdc:.2f} -> "
                        f"{buy_quote.out_amount} {name} -> ${out_usdc:.2f} "
                        f"({profit_bps:+.1f} bps)"
                    )

                if profit_bps > 0:
                    opportunities.append(ArbitrageOpportunity(
                        token=name,
                        buy_source="jupiter",
                        sell_source="jupiter",
                        buy_price=amount_usdc,
                        sell_price=out_usdc,
                        spread_bps=profit_bps,
                        timestamp=now,
                    ))

            except Exception as e:
                log.warning(f"Round-trip check failed for {name}: {e}")

        return sorted(opportunities, key=lambda x: x.spread_bps, reverse=True)

    def _get_decimals(self, token: str) -> float:
        decimals_map = {
            "SOL": 1e9,
            "BONK": 1e5,
            "JUP": 1e6,
            "RAY": 1e6,
            "ORCA": 1e6,
        }
        return decimals_map.get(token, 1e6)

    async def close(self):
        await self.jupiter.close()
