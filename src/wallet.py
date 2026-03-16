"""Solana wallet integration — balance checks and transaction signing."""

import base64
import logging
from dataclasses import dataclass

import httpx
from solders.keypair import Keypair
from solders.pubkey import Pubkey

from src.config import config

log = logging.getLogger(__name__)

# USDC has 6 decimals on Solana
USDC_DECIMALS = 6


@dataclass
class WalletBalance:
    sol: float
    usdc: float


class Wallet:
    def __init__(self, private_key: str | None = None, rpc_url: str | None = None):
        self.rpc_url = rpc_url or config.solana_rpc_url
        self._client = httpx.AsyncClient(timeout=30)

        if private_key:
            self.keypair = Keypair.from_base58_string(private_key)
        elif config.solana_private_key:
            self.keypair = Keypair.from_base58_string(config.solana_private_key)
        else:
            self.keypair = None
            log.warning("No private key configured — read-only mode")

    @property
    def pubkey(self) -> Pubkey | None:
        return self.keypair.pubkey() if self.keypair else None

    async def _rpc(self, method: str, params: list) -> dict:
        """Send a JSON-RPC request to Solana."""
        payload = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
        resp = await self._client.post(self.rpc_url, json=payload)
        resp.raise_for_status()
        data = resp.json()
        if "error" in data:
            raise RuntimeError(f"RPC error: {data['error']}")
        return data["result"]

    async def get_sol_balance(self) -> float:
        """Get SOL balance in SOL (not lamports)."""
        if not self.pubkey:
            return 0.0
        result = await self._rpc("getBalance", [str(self.pubkey)])
        return result["value"] / 1e9

    async def get_usdc_balance(self) -> float:
        """Get USDC balance."""
        if not self.pubkey:
            return 0.0

        result = await self._rpc(
            "getTokenAccountsByOwner",
            [
                str(self.pubkey),
                {"mint": config.usdc_mint},
                {"encoding": "jsonParsed"},
            ],
        )

        accounts = result.get("value", [])
        if not accounts:
            return 0.0

        token_amount = accounts[0]["account"]["data"]["parsed"]["info"]["tokenAmount"]
        return float(token_amount["uiAmount"])

    async def get_balance(self) -> WalletBalance:
        """Get full wallet balance."""
        sol = await self.get_sol_balance()
        usdc = await self.get_usdc_balance()
        return WalletBalance(sol=sol, usdc=usdc)

    async def close(self):
        await self._client.aclose()
