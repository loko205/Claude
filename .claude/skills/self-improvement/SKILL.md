# Self-Improvement Skill

## Zweck
Automatisches Lernen aus Fehlern und Korrekturen, um die Qualität über Sessions hinweg zu verbessern.

## Trigger
Wird aktiviert durch den Magic Prompt:
> "Reflect on this mistake. Abstract and generalize the learning. Write it to CLAUDE.md."

## Ablauf

### 1. Fehler loggen
Bei jedem Fehler oder jeder Korrektur:
- Logge den Vorfall in `.learnings/LEARNINGS.md`
- Format:
  ```
  ## [TIMESTAMP] — [PRIORITÄT: HIGH/MEDIUM/LOW]
  **Kontext:** Was wurde versucht?
  **Fehler:** Was ging schief?
  **Lösung:** Was war der richtige Weg?
  **Abstraktion:** Welches allgemeine Muster steckt dahinter?
  ```

### 2. Muster erkennen
Bei wiederkehrenden Mustern (gleicher Fehlertyp >= 2x):
- Promote die Erkenntnis zu einer Regel in `CLAUDE.md` unter `GELERNTE REGELN`
- Folge den Meta-Regeln für neue Regeln (IMMER/NIEMALS Format)
- Aktualisiere die SUMMARY in CLAUDE.md

### 3. Qualitätssicherung
- Prüfe ob die neue Regel nicht redundant ist
- Halte CLAUDE.md unter 200 Zeilen
- Bei Überschreitung: Lagere Details in separate Dateien aus

## Beispiel

**Lerning:**
```
## 2026-03-16 — HIGH
**Kontext:** API-Endpunkt implementiert
**Fehler:** Vergessen, Error-Handling für 429 Rate-Limit hinzuzufügen
**Lösung:** Retry mit exponential backoff eingebaut
**Abstraktion:** Bei API-Calls immer Rate-Limiting berücksichtigen
```

**Daraus generierte Regel in CLAUDE.md:**
```
- IMMER Rate-Limiting bei externen API-Calls berücksichtigen
  - APIs haben Limits, unbehandelte 429er führen zu stillen Fehlern
  - `retry with exponential backoff` als Standard-Pattern verwenden
```
