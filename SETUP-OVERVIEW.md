# Claude Code Best Practices — Setup Übersicht

## 📁 Dateistruktur

```
Claude/
├── CLAUDE.md                          ← Projekt-Config (wird automatisch gelesen)
├── SETUP-OVERVIEW.md                  ← Diese Datei
├── .learnings/
│   └── LEARNINGS.md                   ← Fehler-Log (wächst automatisch)
└── .claude/
    ├── settings.json                  ← Hooks + Permissions
    ├── commands/                      ← Slash Commands
    │   ├── commit-push-pr.md          ← /commit-push-pr
    │   ├── simplify.md                ← /simplify
    │   ├── review.md                  ← /review
    │   └── plan.md                    ← /plan <task>
    └── skills/
        └── self-improvement/
            └── SKILL.md               ← Self-Improvement Zyklus
```

## 🔄 Workflow (Boris Chernys Methode)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        DEIN TASK                                    │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │   1. PLAN MODE         │  Shift+Tab (2x)
              │   Claude erstellt Plan │  oder /plan <task>
              │   Du prüfst & bestätigst│
              └───────────┬────────────┘
                          │ ✅ Plan bestätigt
                          ▼
              ┌────────────────────────┐
              │   2. AUTO-ACCEPT       │  Shift+Tab (1x)
              │   Claude setzt um      │  Claude arbeitet autonom
              │   Code wird geschrieben│
              └───────────┬────────────┘
                          │ Code fertig
                          ▼
              ┌────────────────────────┐
              │   3. AUTO-SIMPLIFY     │  ← passiert automatisch!
              │   Unnötige Komplexität │
              │   Ungenutzte Imports   │
              │   Code-Wiederverwendung│
              └───────────┬────────────┘
                          │
                          ▼
              ┌────────────────────────┐
              │   4. AUTO-REVIEW       │  ← passiert automatisch!
              │   Logik-Fehler         │
              │   Edge Cases           │
              │   Security + Performance│
              └───────────┬────────────┘
                          │
                          ▼
              ┌────────────────────────┐
              │   5. TESTS             │  ← passiert automatisch!
              │   Bestehende Tests     │
              │   laufen lassen        │
              └───────────┬────────────┘
                          │ ✅ Alles ok
                          ▼
              ┌────────────────────────┐
              │   6. COMMIT & PR       │  /commit-push-pr
              │   Commit → Push → PR   │  (manuell auslösen)
              └────────────────────────┘
```

## 🧠 Self-Improvement Zyklus

```
    Claude macht einen Fehler
              │
              ▼
    Du sagst: "Reflect on this mistake.
    Abstract and generalize the learning.
    Write it to CLAUDE.md."
              │
              ▼
    ┌─────────────────────────────┐
    │  1. ANALYSE                 │
    │  Was ging schief?           │
    │  Warum?                     │
    └────────────┬────────────────┘
                 │
                 ▼
    ┌─────────────────────────────┐
    │  2. LOGGEN                  │
    │  → .learnings/LEARNINGS.md  │
    │  Timestamp + Kontext +      │
    │  Fehler + Lösung            │
    └────────────┬────────────────┘
                 │
                 ▼
    ┌─────────────────────────────┐
    │  3. ABSTRAHIEREN            │
    │  Muster erkennen            │
    │  Allgemeine Regel ableiten  │
    └────────────┬────────────────┘
                 │
                 ▼
    ┌─────────────────────────────┐
    │  4. CLAUDE.md UPDATEN       │
    │  → GELERNTE REGELN          │
    │  IMMER/NIEMALS Format       │
    │  → SUMMARY aktualisieren    │
    └─────────────────────────────┘
                 │
                 ▼
       Nächste Session ist besser
```

## ⚡ Was ist automatisch vs. manuell?

```
AUTOMATISCH (ohne dein Zutun)          MANUELL (du löst aus)
─────────────────────────────          ─────────────────────
✅ CLAUDE.md lesen                     🔘 /plan <task>
✅ Regeln befolgen                     🔘 /commit-push-pr
✅ Simplify nach Code-Änderung         🔘 /simplify (extra)
✅ Review nach Code-Änderung           🔘 /review (extra)
✅ Tests nach Code-Änderung            🔘 Magic Prompt
✅ PostToolUse Hook                    🔘 Plan Mode (Shift+Tab 2x)
✅ Permission Allowlist                🔘 Auto-Accept (Shift+Tab 1x)
                                       🔘 /compact (bei ~50% Context)
                                       🔘 /clear (bei Task-Wechsel)
```

## 🌳 Git Workflow

```
main ─────────────────────────────────────● merge
        \                                /
         \  feature/mein-task           /
          ●────●────●────●────●────●───
          │    │    │    │    │    │
         plan code  simplify  test  PR
                    review
```

## 🔑 Wichtigste Tastenkürzel

```
┌──────────────────┬────────────────────────────────────┐
│  Shift+Tab (2x)  │  Plan Mode — erst planen, dann     │
│                  │  bestätigen                         │
├──────────────────┼────────────────────────────────────┤
│  Shift+Tab (1x)  │  Auto-Accept — Claude arbeitet     │
│                  │  autonom durch                      │
├──────────────────┼────────────────────────────────────┤
│  /compact        │  Context komprimieren (~50%)        │
├──────────────────┼────────────────────────────────────┤
│  /clear          │  Context reset (Task-Wechsel)       │
├──────────────────┼────────────────────────────────────┤
│  /model          │  Modell wechseln (immer Opus!)      │
├──────────────────┼────────────────────────────────────┤
│  /diff           │  Alle Änderungen anzeigen           │
├──────────────────┼────────────────────────────────────┤
│  /rewind         │  Letzte Änderungen rückgängig        │
└──────────────────┴────────────────────────────────────┘
```
