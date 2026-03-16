# CLAUDE.md — Self-Improving Project Config

## SUMMARY
- Sprache: Deutsch bevorzugt, Code-Kommentare auf Englisch
- Paketmanager: uv (NICHT pip)
- Code-Stil: Kurz, pragmatisch, keine übertriebene Abstraktion
- Tests: Immer vor Commit ausführen
- Post-Task: Automatisch simplify + review nach jeder Code-Änderung
- Git: Feature-Branches, keine direkten Pushes auf main
- Modell: Opus mit Thinking für alles (nie auf Sonnet wechseln für Code-Tasks)

## PROJEKT-KONTEXT

### Was ist das Projekt?
[HIER DEIN PROJEKT BESCHREIBEN - z.B. Trading Bot, Web App, etc.]

### Tech Stack
- [HIER DEINEN STACK EINTRAGEN]

### Projektstruktur
Lies die Projektstruktur mit `find . -type f -name "*.py"` (oder passendes Pattern) bevor du Änderungen machst. Verändere NIEMALS Dateien die nicht zum aktuellen Task gehören.

## ABSOLUTE REGELN
1. NIEMALS Code refactoren der nicht zum aktuellen Task gehört
2. NIEMALS Abhängigkeiten hinzufügen ohne zu fragen
3. IMMER `uv` statt `pip` verwenden
4. IMMER bestehende Tests laufen lassen nach Änderungen
5. IMMER Plan Mode nutzen bei Tasks > 50 Zeilen Code
6. IMMER von einem sauberen Git-State starten
7. NIEMALS --dangerously-skip-permissions nutzen, stattdessen /permissions
8. IMMER nach Code-Änderungen automatisch Simplify und Review durchführen bevor du dich als fertig meldest

## GELERNTE REGELN
<!-- Wächst automatisch durch den Self-Improvement Zyklus -->
<!-- Wenn ich sage "Reflect, abstract, generalize, add to CLAUDE.md" -->
<!-- dann analysiere den Fehler, extrahiere das Muster, und schreib eine neue Regel hier rein -->

## WORKFLOW

### Vor jedem Task:
1. Lies diese CLAUDE.md
2. Lies die relevanten Dateien im Projekt
3. Erstelle einen Plan (Plan Mode / Shift+Tab zweimal)
4. Warte auf meine Bestätigung bevor du Code schreibst

### Nach jedem Task (AUTOMATISCH, ohne Aufforderung):
1. Tests ausführen
2. Code vereinfachen (wie `/simplify` — prüfe auf unnötige Komplexität, ungenutzte Imports, Wiederverwendung)
3. Code-Review durchführen (wie `/review` — prüfe auf Logik-Fehler, Edge Cases, Security, Performance)
4. Prüfe ob nur die beabsichtigten Dateien geändert wurden
5. Kurze Zusammenfassung der Änderungen + Ergebnisse aus Simplify & Review

### Verifikation:
IMMER deine eigene Arbeit verifizieren bevor du sie als fertig meldest. Das ist der wichtigste Punkt im gesamten Workflow (Faktor 2-3x Qualität). Nutze Tests, Type-Checks, oder manuelles Überprüfen der Ausgabe.

## META — DIESES DOKUMENT PFLEGEN

### Regeln für neue Regeln
Wenn du eine neue Regel hinzufügst:

**Immer anwenden:**
1. Beginne mit NIEMALS oder IMMER
2. Erkläre zuerst WARUM (1-3 Stichpunkte max)
3. Sei konkret — echte Befehle/Code einbauen
4. Stichpunkte statt Absätze
5. Ein klarer Punkt pro Regel

**Anti-Aufblähung:**
- Keine Warnsignale für offensichtliche Regeln
- Keine schlechten Beispiele für triviale Fehler
- Keine Absätze wo Stichpunkte reichen
- Maximal 200 Zeilen in dieser Datei — wenn mehr nötig, in separate Dateien auslagern

**Wenn du eine neue Regel hinzufügst:**
1. Füge sie unter GELERNTE REGELN ein
2. Aktualisiere die SUMMARY oben
3. Prüfe ob eine bestehende Regel das gleiche abdeckt

## FAILED ATTEMPTS
<!-- Format: Was versucht → Warum gescheitert → Besserer Weg -->
