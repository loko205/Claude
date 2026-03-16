"""Hyperliquid SDK wrapper for perpetual trading."""

import logging
import time

import eth_account
from hyperliquid.exchange import Exchange
from hyperliquid.info import Info
from hyperliquid.utils import constants

from src.config import config
from src.strategies.momentum import Candle

log = logging.getLogger(__name__)


class HyperliquidClient:
    """Wrapper around the Hyperliquid Python SDK."""

    def __init__(
        self,
        private_key: str | None = None,
        account_address: str | None = None,
        testnet: bool | None = None,
    ):
        pk = private_key or config.hl_private_key
        self.account_address = account_address or config.hl_account_address or None
        use_testnet = testnet if testnet is not None else config.hl_testnet
        self.base_url = constants.TESTNET_API_URL if use_testnet else constants.MAINNET_API_URL

        # Info client (read-only, always available)
        self.info = Info(self.base_url, skip_ws=True)

        # Exchange client (requires private key for trading)
        if pk:
            self.wallet = eth_account.Account.from_key(pk)
            self.exchange = Exchange(
                self.wallet,
                self.base_url,
                account_address=self.account_address or None,
            )
            log.info(f"Hyperliquid connected: {self.wallet.address} ({'testnet' if use_testnet else 'MAINNET'})")
        else:
            self.wallet = None
            self.exchange = None
            log.warning("No HL private key — read-only mode")

        self._leverage_cache: dict[str, tuple[int, bool]] = {}

    @property
    def address(self) -> str | None:
        """Resolve the account address (main wallet or API wallet)."""
        return self.account_address or (self.wallet.address if self.wallet else None)

    def _require_exchange(self) -> bool:
        if not self.exchange:
            log.error("No exchange client")
            return False
        return True

    # === Leverage ===

    def set_leverage(self, coin: str, leverage: int, is_cross: bool = True):
        """Set leverage for a coin. Skips if already set to same value."""
        if not self._require_exchange():
            return
        cached = self._leverage_cache.get(coin)
        if cached == (leverage, is_cross):
            return
        self.exchange.update_leverage(leverage, coin, is_cross=is_cross)
        self._leverage_cache[coin] = (leverage, is_cross)
        log.info(f"Leverage set: {coin} {leverage}x {'cross' if is_cross else 'isolated'}")

    # === Orders ===

    def market_open(self, coin: str, is_buy: bool, sz: float, slippage: float = 0.05) -> dict:
        """Open a position with a market order."""
        if not self._require_exchange():
            return {"status": "error", "msg": "no exchange client"}
        result = self.exchange.market_open(coin, is_buy, sz, slippage)
        status = result.get("status", "unknown")
        log.info(f"Market {'BUY' if is_buy else 'SELL'} {sz} {coin}: {status}")
        return result

    def market_close(self, coin: str, slippage: float = 0.05, sz: float | None = None) -> dict:
        """Close a position (full or partial)."""
        if not self._require_exchange():
            return {"status": "error", "msg": "no exchange client"}
        if sz is not None:
            result = self.exchange.market_close(coin, sz=sz, slippage=slippage)
        else:
            result = self.exchange.market_close(coin, slippage=slippage)
        log.info(f"Market CLOSE {coin} (sz={sz}): {result.get('status', 'unknown')}")
        return result

    def limit_order(
        self, coin: str, is_buy: bool, sz: float, price: float, tif: str = "Gtc"
    ) -> dict:
        """Place a limit order."""
        if not self._require_exchange():
            return {"status": "error", "msg": "no exchange client"}
        result = self.exchange.order(
            coin, is_buy, sz, price, {"limit": {"tif": tif}}
        )
        log.info(f"Limit {'BUY' if is_buy else 'SELL'} {sz} {coin} @ {price}: {result.get('status', 'unknown')}")
        return result

    def cancel_order(self, coin: str, oid: int) -> dict:
        """Cancel an order by ID."""
        if not self._require_exchange():
            return {"status": "error", "msg": "no exchange client"}
        return self.exchange.cancel(coin, oid)

    def place_with_tp_sl(
        self,
        coin: str,
        is_buy: bool,
        sz: float,
        slippage: float,
        tp_price: float | None = None,
        sl_price: float | None = None,
        mid_price: float | None = None,
    ) -> dict:
        """Atomically place entry + TP + SL orders."""
        if not self._require_exchange():
            return {"status": "error", "msg": "no exchange client"}

        mid = mid_price or self.get_mid_price(coin)
        if not mid:
            return {"status": "error", "msg": f"no mid price for {coin}"}

        # Entry order (market-like via IOC with slippage)
        slip_mult = (1 + slippage) if is_buy else (1 - slippage)
        entry_px = round(mid * slip_mult, 6)
        entry_order = {
            "coin": coin, "is_buy": is_buy, "sz": sz,
            "limit_px": entry_px,
            "order_type": {"limit": {"tif": "Ioc"}},
            "reduce_only": False,
        }

        orders = [entry_order]

        # TP order (opposite side, reduce_only)
        if tp_price is not None:
            orders.append({
                "coin": coin, "is_buy": not is_buy, "sz": sz,
                "limit_px": tp_price,
                "order_type": {"trigger": {"triggerPx": str(tp_price), "isMarket": True, "tpsl": "tp"}},
                "reduce_only": True,
            })

        # SL order (opposite side, reduce_only)
        if sl_price is not None:
            orders.append({
                "coin": coin, "is_buy": not is_buy, "sz": sz,
                "limit_px": sl_price,
                "order_type": {"trigger": {"triggerPx": str(sl_price), "isMarket": True, "tpsl": "sl"}},
                "reduce_only": True,
            })

        if len(orders) > 1:
            result = self.exchange.bulk_orders(orders, grouping="normalTpsl")
        else:
            result = self.exchange.bulk_orders(orders)

        log.info(f"Entry+TP/SL {coin}: {result.get('status', 'unknown')}")
        return result

    # === Market Data ===

    def get_candles(
        self, coin: str, interval: str = "15m",
        start_time: int | None = None, end_time: int | None = None,
    ) -> list[Candle]:
        """Fetch OHLCV candles. Max 5000 per request."""
        now_ms = int(time.time() * 1000)
        if end_time is None:
            end_time = now_ms
        if start_time is None:
            start_time = end_time - 86400 * 1000  # 24h default

        raw = self.info.candles_snapshot(coin, interval, start_time, end_time)
        candles = []
        for c in raw:
            candles.append(Candle(
                timestamp=c["t"] / 1000,
                open=float(c["o"]),
                high=float(c["h"]),
                low=float(c["l"]),
                close=float(c["c"]),
                volume=float(c["v"]),
            ))
        return candles

    # === Account Info ===

    def get_position(self, coin: str) -> dict | None:
        """Get position for a specific coin."""
        if not self.address:
            return None
        state = self.info.user_state(self.address)
        for pos in state.get("assetPositions", []):
            p = pos.get("position", {})
            if p.get("coin") == coin:
                return {
                    "coin": coin,
                    "size": float(p.get("szi", 0)),
                    "entry_price": float(p.get("entryPx", 0)),
                    "unrealized_pnl": float(p.get("unrealizedPnl", 0)),
                    "liquidation_price": float(p.get("liquidationPx", 0)) if p.get("liquidationPx") else None,
                    "leverage": float(p.get("leverage", {}).get("value", 0)) if isinstance(p.get("leverage"), dict) else 0,
                }
        return None

    def get_all_positions(self) -> list[dict]:
        """Get all open positions."""
        if not self.address:
            return []
        state = self.info.user_state(self.address)
        positions = []
        for pos in state.get("assetPositions", []):
            p = pos.get("position", {})
            sz = float(p.get("szi", 0))
            if sz != 0:
                positions.append({
                    "coin": p.get("coin"),
                    "size": sz,
                    "entry_price": float(p.get("entryPx", 0)),
                    "unrealized_pnl": float(p.get("unrealizedPnl", 0)),
                })
        return positions

    def get_balance(self) -> float:
        """Get withdrawable USDC balance."""
        if not self.address:
            return 0.0
        state = self.info.user_state(self.address)
        return float(state.get("withdrawable", 0))

    def get_mid_price(self, coin: str) -> float | None:
        """Get current mid price for a coin."""
        mids = self.info.all_mids()
        val = mids.get(coin)
        return float(val) if val else None
