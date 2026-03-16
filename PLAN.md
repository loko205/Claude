# Plan: Hyperliquid Perps Integration

## Ziel
Regime-adaptive Strategie (Breakout + Mean Reversion) auf Hyperliquid Perpetuals anwenden.
Long + Short, 3-5x Hebel, ATR-Stops, Bracket-Orders.

Bisherige Backtest-Ergebnisse (Spot, 1x): +$23/Monat auf $90 (25.6% monatlich).
Mit 3x Hebel + Shorts: Ziel ~$50-70/Monat.

## Warum Hyperliquid?
- Perps mit bis zu 50x Hebel (wir nutzen 3-5x)
- Long UND Short möglich → Profit in Downtrends
- 0.045% Taker / **-0.015% Maker Rebate** (Geld verdienen mit Limit-Orders!)
- Bracket-Orders (Entry + SL + TP atomar)
- Python SDK: `hyperliquid-python-sdk`
- User hat schon Wallet + API-Zugang

## Dateien & Änderungen

### 1. NEU: `src/exchanges/__init__.py`
Package init.

### 2. NEU: `src/exchanges/hyperliquid.py` — HL Client
Klasse `HyperliquidClient`:
- `__init__(private_key, testnet=True)` — SDK Setup
- `get_candles(coin, interval, limit)` → list[Candle]
- `get_balance()` → float (USDC)
- `get_position(coin)` → dict (size, entry, pnl, leverage)
- `set_leverage(coin, leverage)`
- `market_open(coin, is_buy, size_usd, sl_price=None, tp_price=None)` — Bracket-Order
- `market_close(coin)` — Position schließen
- `cancel_all(coin)` — Orders canceln

### 3. ÄNDERN: `src/config.py`
Neue Felder:
- `hyperliquid_private_key: str`
- `hyperliquid_testnet: bool = True`
- `hyperliquid_leverage: int = 3`
- `use_hyperliquid: bool = False`

### 4. ÄNDERN: `src/strategies/momentum.py` — Short-Signals
- TRENDING down (ADX > 25, price < EMA50): Donchian breakdown → action="short"
- RANGING: BB upper + RSI > 65 → action="short"
- Exit-Signale: action="cover" (statt nur "sell")

### 5. ÄNDERN: `src/backtesting.py` — Short + Leverage + Fees
- Short-Trades (Donchian breakdown, BB upper touch)
- `leverage` Parameter (multipliziert PnL und Drawdown)
- HL Fees: 0.045% pro Open + Close
- Funding Rate Simulation (~0.01% pro 8h)

### 6. ÄNDERN: `src/execution/executor.py` — Dual-Exchange
- `if config.use_hyperliquid:` → HyperliquidClient nutzen
- Bracket-Orders (Entry + SL + TP in einem Call)
- Position-Tracking via HL API

### 7. ÄNDERN: `src/main.py` — HL in Loop
- Candles von HL statt Birdeye
- Execute über HL Client
- Position-State von API

### 8. NEU: `tests/test_hyperliquid.py`
- Client init, order building, position parsing

## Reihenfolge
1. `uv add hyperliquid-python-sdk`
2. Config erweitern
3. `src/exchanges/hyperliquid.py` bauen
4. Strategie um Short-Signals erweitern
5. Backtester für Short + Leverage + Fees
6. Backtest laufen lassen (Long+Short+3x Leverage)
7. Executor dual-exchange
8. Main Loop
9. Tests
10. Push

## Risiko-Mitigierung
- **Testnet FIRST** — kein echtes Geld
- Paper-Trading bleibt Default
- Max Leverage: 5x
- Liquidation-Check vor Trade
- Bestehende Risk-Manager Limits gelten
