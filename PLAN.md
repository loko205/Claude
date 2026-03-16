# Plan: $90 USDC Experiment — Solana

## Ziel
Mit $90 USDC auf Solana innerhalb von 1 Woche Gewinn erzielen.
Realistisches Ziel: ~$200/Monat (Max Abo + API Kosten) = ~$50/Woche.

## Rahmenbedingungen
- **Startkapital:** $90 USDC (Solana)
- **Chain:** Solana (Fees: ~$0.001 pro TX — ideal für kleine Beträge)
- **Zeitraum:** 1 Woche
- **Infrastruktur:** On-Chain + CEX möglich
- **Verlusttoleranz:** 100% (Experiment)

---

## Strategie-Übersicht

### Strategie 1: Solana DEX Arbitrage Bot (Hauptstrategie)
**Was:** Preisunterschiede zwischen Solana DEXs ausnutzen (Jupiter, Raydium, Orca)
**Warum:** Solana Fees sind so niedrig, dass selbst kleine Spreads profitabel sein können
**Erwartung:** Viele kleine Trades, ~0.1-0.5% Gewinn pro Trade
**Risiko:** Slippage, MEV/Frontrunning, kein Spread vorhanden

### Strategie 2: CEX-DEX Arbitrage (Backup)
**Was:** Preisunterschiede zwischen Binance/Coinbase und Jupiter/Raydium
**Warum:** CEX-DEX Spreads sind oft größer als DEX-DEX
**Erwartung:** Weniger Trades, aber höhere Marge pro Trade
**Risiko:** Withdrawal-Zeiten, CEX Fees fressen Marge

### Strategie 3: Momentum/Trend-Following auf SOL/USDC (Ergänzung)
**Was:** Einfacher technischer Trading-Bot (EMA Crossover, RSI) auf SOL/USDC
**Warum:** SOL hat hohe Volatilität = Chancen für Momentum-Strategien
**Erwartung:** Wenige Trades pro Tag, höherer Gewinn pro Trade
**Risiko:** Drawdown bei Seitwärtsbewegung, Verlust bei Trendwechsel

---

## Implementierungsplan

### Phase 1: Setup (Tag 1)
1. **Projekt-Grundstruktur erstellen**
   - `pyproject.toml` mit Dependencies (solana-py, jupiter-py, httpx, etc.)
   - Projekt-Struktur: `src/`, `tests/`, `config/`
   - `.env` Template für Private Keys, API Keys

2. **Wallet-Integration**
   - Solana Wallet Connection (read-only zuerst, dann signing)
   - USDC Balance Check
   - Transaction Builder

3. **Daten-Pipeline**
   - Jupiter Quote API Integration (Preis-Feeds)
   - Raydium Pool-Daten
   - Optional: Binance WebSocket für CEX-Preise

**Dateien:** ~5-6 neue Python-Dateien, ~300 Zeilen
**Dependencies:** solders, solana, httpx, python-dotenv, websockets

### Phase 2: Arbitrage Engine (Tag 2-3)
4. **Price Monitor**
   - Multi-DEX Preisabfrage (Jupiter, Raydium, Orca)
   - Spread-Berechnung in Echtzeit
   - Logging aller gefundenen Opportunities

5. **Arbitrage Executor**
   - Jupiter Swap API Integration
   - Slippage-Protection
   - Profit-Berechnung nach Fees
   - Minimum-Profit-Threshold (nur traden wenn > X% Gewinn)

6. **Risk Management**
   - Max Trade Size (% des Portfolios)
   - Stop-Loss pro Trade
   - Daily Loss Limit
   - Cooldown nach Verlusten

**Dateien:** ~4-5 neue Python-Dateien, ~400 Zeilen

### Phase 3: Momentum Bot (Tag 3-4)
7. **Technische Analyse**
   - OHLCV Daten von Birdeye/Jupiter
   - EMA Crossover Strategie (schnell: 9, langsam: 21)
   - RSI Filter (nur traden wenn RSI < 70 für Long, > 30 für Short)

8. **Trade Execution**
   - SOL/USDC Swaps via Jupiter
   - Position Sizing (max 30% pro Trade)
   - Take-Profit und Stop-Loss

**Dateien:** ~3 neue Python-Dateien, ~250 Zeilen

### Phase 4: Monitoring & Dashboard (Tag 4-5)
9. **Live Monitoring**
   - Echtzeit P&L Tracking
   - Trade History (SQLite oder JSON)
   - Alerts (Console + optional Telegram)

10. **Simulations-Modus**
    - Paper-Trading Modus zum Testen
    - Backtesting mit historischen Daten
    - Performance-Vergleich der Strategien

**Dateien:** ~3 neue Python-Dateien, ~200 Zeilen

### Phase 5: Go Live & Optimierung (Tag 5-7)
11. **Paper-Trading Phase** (min. einige Stunden)
    - Alle Strategien im Simulations-Modus laufen lassen
    - Ergebnisse analysieren
    - Parameter tunen

12. **Live Trading**
    - Mit kleinem Betrag starten ($10)
    - Schrittweise hochfahren wenn profitabel
    - Kontinuierliches Monitoring

---

## Projektstruktur

```
src/
├── __init__.py
├── config.py              # Settings, Environment Variables
├── wallet.py              # Solana Wallet Integration
├── prices/
│   ├── __init__.py
│   ├── jupiter.py         # Jupiter Quote API
│   ├── raydium.py         # Raydium Pool Preise
│   └── aggregator.py      # Multi-Source Preis-Aggregation
├── strategies/
│   ├── __init__.py
│   ├── arbitrage.py       # DEX Arbitrage Logik
│   ├── momentum.py        # EMA/RSI Trend-Following
│   └── base.py            # Strategy Interface
├── execution/
│   ├── __init__.py
│   ├── executor.py        # Trade Execution via Jupiter
│   └── risk.py            # Risk Management
├── monitoring/
│   ├── __init__.py
│   ├── tracker.py         # P&L Tracking
│   └── alerts.py          # Alerts
└── main.py                # Entry Point, Strategy Orchestration

tests/
├── test_prices.py
├── test_arbitrage.py
├── test_risk.py
└── test_momentum.py

config/
└── .env.example
```

## Risiken & Edge Cases

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|------------|
| Totalverlust durch Bug | Mittel | Hoch | Paper-Trading zuerst, schrittweise Erhöhung |
| MEV/Frontrunning | Hoch | Mittel | Priority Fees, Jito Tips, kleine Trades |
| Kein profitabler Spread | Mittel | Mittel | Backup-Strategien, mehr Token-Paare |
| API Rate Limits | Niedrig | Niedrig | Caching, mehrere Endpoints |
| Solana Netzwerk-Ausfall | Niedrig | Hoch | Automatic Pause, CEX Fallback |
| Slippage größer als erwartet | Mittel | Mittel | Strict Slippage Limits, kleine Orders |
| Private Key Leak | Niedrig | Kritisch | .env, .gitignore, separate Wallet |

## Umfang-Schätzung

- **Dateien:** ~20 neue Dateien
- **Code:** ~1200-1500 Zeilen Python
- **Dependencies:** ~8-10 Pakete
- **Zeitaufwand Coding:** ~2-3 Tage intensiv

## Wichtige Sicherheitsregeln

1. **NIEMALS** Private Keys in Code oder Git
2. **IMMER** Paper-Trading vor Live-Trading
3. **IMMER** mit kleinem Betrag starten
4. **IMMER** Stop-Loss und Daily Loss Limit aktiv
5. **NIEMALS** mehr als 50% des Kapitals in einem Trade
