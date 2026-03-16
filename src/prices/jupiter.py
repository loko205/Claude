"""Jupiter API integration for quotes and swaps on Solana."""

import logging
from dataclasses import dataclass

import httpx

log = logging.getLogger(__name__)

JUPITER_QUOTE_URL = "https://quote-api.jup.ag/v6/quote"
JUPITER_SWAP_URL = "https://quote-api.jup.ag/v6/swap"
JUPITER_PRICE_URL = "https://price.jup.ag/v6/price"


@dataclass
class Quote:
    input_mint: str
    output_mint: str
    in_amount: int
    out_amount: int
    price_impact_pct: float
    route_plan: list
    raw: dict  # full API response for swap execution


class JupiterClient:
    def __init__(self):
        self._client = httpx.AsyncClient(timeout=15)

    async def get_quote(
        self,
        input_mint: str,
        output_mint: str,
        amount: int,
        slippage_bps: int = 50,
    ) -> Quote | None:
        """Get a swap quote from Jupiter.

        Args:
            input_mint: Input token mint address
            output_mint: Output token mint address
            amount: Amount in smallest unit (e.g. lamports for SOL, 1e6 for USDC)
            slippage_bps: Max slippage in basis points (default 0.5%)
        """
        params = {
            "inputMint": input_mint,
            "outputMint": output_mint,
            "amount": str(amount),
            "slippageBps": slippage_bps,
        }

        try:
            resp = await self._client.get(JUPITER_QUOTE_URL, params=params)
            resp.raise_for_status()
            data = resp.json()

            return Quote(
                input_mint=data["inputMint"],
                output_mint=data["outputMint"],
                in_amount=int(data["inAmount"]),
                out_amount=int(data["outAmount"]),
                price_impact_pct=float(data.get("priceImpactPct", 0)),
                route_plan=data.get("routePlan", []),
                raw=data,
            )
        except Exception as e:
            log.error(f"Jupiter quote failed: {e}")
            return None

    async def get_price(self, token_mint: str, vs_mint: str = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v") -> float | None:
        """Get token price in USDC (or other vs token)."""
        params = {"ids": token_mint, "vsToken": vs_mint}

        try:
            resp = await self._client.get(JUPITER_PRICE_URL, params=params)
            resp.raise_for_status()
            data = resp.json()
            price_data = data.get("data", {}).get(token_mint)
            if price_data:
                return float(price_data["price"])
            return None
        except Exception as e:
            log.error(f"Jupiter price fetch failed: {e}")
            return None

    async def get_swap_transaction(self, quote: Quote, user_pubkey: str) -> str | None:
        """Get a serialized swap transaction from Jupiter.

        Returns base64-encoded transaction ready to sign and send.
        """
        payload = {
            "quoteResponse": quote.raw,
            "userPublicKey": user_pubkey,
            "wrapAndUnwrapSol": True,
        }

        try:
            resp = await self._client.post(JUPITER_SWAP_URL, json=payload)
            resp.raise_for_status()
            data = resp.json()
            return data.get("swapTransaction")
        except Exception as e:
            log.error(f"Jupiter swap TX failed: {e}")
            return None

    async def close(self):
        await self._client.aclose()
