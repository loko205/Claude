"""Trade executor for Hyperliquid perpetuals."""

import logging
import time

from src.config import config
from src.exchanges.hyperliquid import HyperliquidClient
from src.execution.risk import RiskManager, TradeRecord

log = logging.getLogger(__name__)


class HLExecutor:
    """Executes perp trades on Hyperliquid with risk management."""

    def __init__(self, client: HyperliquidClient, risk: RiskManager):
        self.client = client
        self.risk = risk
        self.paper_mode = config.paper_trading

    @staticmethod
    def _calc_tp_sl(
        mid: float, is_buy: bool, tp_pct: float | None, sl_pct: float | None,
    ) -> tuple[float | None, float | None]:
        """Calculate TP/SL prices from percentage distances."""
        tp = None
        sl = None
        if tp_pct:
            tp = round(mid * (1 + tp_pct) if is_buy else mid * (1 - tp_pct), 2)
        if sl_pct:
            sl = round(mid * (1 - sl_pct) if is_buy else mid * (1 + sl_pct), 2)
        return tp, sl

    def execute_perp_trade(
        self,
        coin: str,
        is_buy: bool,
        size_usdc: float,
        sl_pct: float | None = None,
        tp_pct: float | None = None,
        strategy: str = "unknown",
    ) -> dict | None:
        """Execute a perpetual trade with optional TP/SL.

        Args:
            coin: e.g. "ETH", "SOL", "BTC"
            is_buy: True=long, False=short
            size_usdc: position size in USDC
            sl_pct: stop-loss distance as fraction (e.g. 0.02 = 2%)
            tp_pct: take-profit distance as fraction (e.g. 0.04 = 4%)
            strategy: strategy name for tracking
        """
        ok, reason = self.risk.can_trade(size_usdc)
        if not ok:
            log.warning(f"Trade blocked: {reason}")
            return None

        if self.paper_mode:
            return self._paper_trade(coin, is_buy, size_usdc, sl_pct, tp_pct, strategy)
        return self._live_trade(coin, is_buy, size_usdc, sl_pct, tp_pct, strategy)

    def _paper_trade(
        self, coin: str, is_buy: bool, size_usdc: float,
        sl_pct: float | None, tp_pct: float | None, strategy: str,
    ) -> dict:
        """Simulate a trade using current market price."""
        mid = self.client.get_mid_price(coin)
        if mid is None:
            log.error(f"No price for {coin} — paper trade skipped")
            return {"status": "error", "msg": "no price"}

        sz_coins = size_usdc / mid
        side = "long" if is_buy else "short"
        tp_px, sl_px = self._calc_tp_sl(mid, is_buy, tp_pct, sl_pct)

        log.info(
            f"[PAPER] {side.upper()} {sz_coins:.4f} {coin} @ ${mid:.2f} "
            f"(${size_usdc:.2f}) TP={tp_px} SL={sl_px}"
        )

        self.risk.record_trade(TradeRecord(
            timestamp=time.time(), token=coin, side=side,
            amount_usdc=size_usdc, profit_usdc=0, strategy=strategy,
        ))

        return {
            "status": "paper", "coin": coin, "side": side,
            "size": sz_coins, "price": mid,
            "tp": tp_px, "sl": sl_px,
        }

    def _live_trade(
        self, coin: str, is_buy: bool, size_usdc: float,
        sl_pct: float | None, tp_pct: float | None, strategy: str,
    ) -> dict | None:
        """Execute a real trade on Hyperliquid."""
        mid = self.client.get_mid_price(coin)
        if mid is None:
            log.error(f"No price for {coin}")
            return None

        # Set leverage
        self.client.set_leverage(
            coin, config.hl_default_leverage, config.hl_leverage_cross
        )

        sz_coins = round(size_usdc / mid, 4)
        tp_price, sl_price = self._calc_tp_sl(mid, is_buy, tp_pct, sl_pct)

        # Place order with TP/SL
        if tp_price or sl_price:
            result = self.client.place_with_tp_sl(
                coin, is_buy, sz_coins, slippage=0.05,
                tp_price=tp_price, sl_price=sl_price,
                mid_price=mid,
            )
        else:
            result = self.client.market_open(coin, is_buy, sz_coins)

        status = result.get("status", "unknown")
        if status == "error":
            log.error(f"Trade failed: {result}")
            return None

        side = "long" if is_buy else "short"
        self.risk.record_trade(TradeRecord(
            timestamp=time.time(), token=coin, side=side,
            amount_usdc=size_usdc, profit_usdc=0, strategy=strategy,
        ))

        log.info(f"[LIVE] {side.upper()} {sz_coins} {coin} @ ~${mid:.2f} TP={tp_price} SL={sl_price}")
        return {"status": "live", "coin": coin, "side": side, "size": sz_coins, **result}

    def close_position(self, coin: str, strategy: str = "unknown") -> dict | None:
        """Close an existing position."""
        if self.paper_mode:
            log.info(f"[PAPER] Close {coin}")
            return {"status": "paper", "action": "close", "coin": coin}

        pos = self.client.get_position(coin)
        if not pos or pos["size"] == 0:
            log.info(f"No open position for {coin}")
            return None

        result = self.client.market_close(coin)
        pnl = pos["unrealized_pnl"]

        self.risk.record_trade(TradeRecord(
            timestamp=time.time(), token=coin,
            side="close", amount_usdc=abs(pos["size"] * pos["entry_price"]),
            profit_usdc=pnl, strategy=strategy,
        ))

        log.info(f"[LIVE] Closed {coin}: PnL=${pnl:+.4f}")
        return {"status": "closed", "coin": coin, "pnl": pnl, **result}
