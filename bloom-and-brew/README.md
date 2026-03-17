# Bloom & Brew 🌿⚗️

Ein Roblox-Spiel das Gärtnern, Alchemie und Spieler-Handel kombiniert.

## Elevator Pitch

Du bist ein Alchemist-Gärtner: Züchte magische Pflanzen, verarbeite ihre Wirkstoffe mit verschiedenen Maschinen, braue daraus Zaubertränke mit verrückten Effekten, und verkaufe sie über ein wachsendes Netzwerk aus NPCs UND echten Spielern.

## Core Loop

```
Samen → Pflanzen & Pflegen → Ernten
    → Verarbeiten (Trocknen/Mörsern/Pressen/Destillieren/Äther-Extraktion)
    → Extrakte gewinnen → Tränke brauen → Reinheit bestimmen
    → Verkaufen an NPCs ODER Handeln mit Spielern
    → Geld, Samen, Reputation, seltene Rezepte
```

## Projektstruktur

```
bloom-and-brew/
├── docs/                    # Game Design Document
├── src/
│   ├── shared/              # ReplicatedStorage — Daten & Config
│   ├── server/              # ServerScriptService — Spiellogik
│   ├── client/              # StarterPlayerScripts — UI-Stubs
│   └── data/                # Balancing-Dokumentation
├── default.project.json     # Rojo-Config
└── README.md
```

## Setup

1. [Rojo](https://rojo.space/) installieren (VS Code Extension + Roblox Plugin)
2. `rojo serve` im Projektverzeichnis starten
3. In Roblox Studio: Rojo Plugin → Connect

## Tech Stack

- **Sprache:** Luau (Roblox Lua)
- **Sync:** Rojo
- **Architektur:** Strikte Server-Client-Trennung — alle Spiellogik serverseitig

## Features

- **Garten-System:** 6 Plots, 4 Boden-Typen, 20+ Pflanzen mit Raritäten & Traits
- **Verarbeitungs-System:** 5 Methoden (Trocknen → Äther-Extraktion), jede Pflanze braucht die richtige Maschine
- **Brau-System:** 14+ Tränke, Reinheitssystem (0-100%), optionales Brau-Minigame
- **Mutations-System:** Pflanzen kreuzen für seltene Varianten
- **NPC-Kunden:** 5 Typen mit eigener Persönlichkeit und Anforderungen
- **Spieler-Handel:** Direkthandel, Schwarzes Brett, Auktionshaus, Trankstand
- **Gilden:** Gemeinsamer Garten, Gruppen-Brauen, Gilden-Aufträge
- **Trank-Duell:** Fun-PvP mit Trank-Effekten

## Lizenz

MIT
