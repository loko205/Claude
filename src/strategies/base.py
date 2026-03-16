"""Base strategy interface."""

from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass
class Signal:
    action: str  # "buy", "sell", "hold"
    token: str
    confidence: float  # 0.0 to 1.0
    reason: str
    amount_usdc: float | None = None


class Strategy(ABC):
    name: str = "base"

    @abstractmethod
    async def evaluate(self) -> list[Signal]:
        """Evaluate market conditions and return trading signals."""
        ...

    @abstractmethod
    async def close(self):
        ...
