"""Configuration loaded from environment variables."""

import os
from dataclasses import dataclass, field
from pathlib import Path

from dotenv import load_dotenv

# Load .env from project root or config/
for env_path in [Path(".env"), Path("config/.env")]:
    if env_path.exists():
        load_dotenv(env_path)
        break


@dataclass
class Config:
    # Solana
    solana_private_key: str = ""
    solana_rpc_url: str = "https://api.mainnet-beta.solana.com"

    # CEX (optional)
    binance_api_key: str = ""
    binance_api_secret: str = ""

    # Trading
    paper_trading: bool = True
    max_trade_size_usdc: float = 10.0
    daily_loss_limit_usdc: float = 20.0
    min_profit_bps: int = 10  # basis points (0.1%)

    # Token addresses on Solana
    usdc_mint: str = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
    sol_mint: str = "So11111111111111111111111111111111111111112"

    @classmethod
    def from_env(cls) -> "Config":
        return cls(
            solana_private_key=os.getenv("SOLANA_PRIVATE_KEY", ""),
            solana_rpc_url=os.getenv("SOLANA_RPC_URL", cls.solana_rpc_url),
            binance_api_key=os.getenv("BINANCE_API_KEY", ""),
            binance_api_secret=os.getenv("BINANCE_API_SECRET", ""),
            paper_trading=os.getenv("PAPER_TRADING", "true").lower() == "true",
            max_trade_size_usdc=float(os.getenv("MAX_TRADE_SIZE_USDC", "10")),
            daily_loss_limit_usdc=float(os.getenv("DAILY_LOSS_LIMIT_USDC", "20")),
            min_profit_bps=int(os.getenv("MIN_PROFIT_BPS", "10")),
        )


# Global config instance
config = Config.from_env()
