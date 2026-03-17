# Bloom & Brew 🌿⚗️

A Roblox game combining gardening, alchemy, and player trading.

## Elevator Pitch

You are an alchemist-gardener: Grow magical plants, process their active ingredients with various machines, brew potions with wild effects, and sell them through a growing network of NPCs AND real players.

## Core Loop

```
Seeds → Plant & Tend → Harvest
    → Process (Drying/Grinding/Pressing/Distilling/Aether Extraction)
    → Obtain Extracts → Brew Potions → Determine Purity
    → Sell to NPCs OR Trade with Players
    → Coins, Seeds, Reputation, Rare Recipes
```

## Project Structure

```
bloom-and-brew/
├── docs/                    # Game Design Document
├── src/
│   ├── shared/              # ReplicatedStorage — Data & Config
│   ├── server/              # ServerScriptService — Game Logic
│   ├── client/              # StarterPlayerScripts — UI Stubs
│   └── data/                # Balancing Documentation
├── default.project.json     # Rojo Config
└── README.md
```

## Setup

1. Install [Rojo](https://rojo.space/) (VS Code Extension + Roblox Plugin)
2. Run `rojo serve` in the project directory
3. In Roblox Studio: Rojo Plugin → Connect

## Tech Stack

- **Language:** Luau (Roblox Lua)
- **Sync:** Rojo
- **Architecture:** Strict server-client separation — all game logic runs server-side

## Features

- **Garden System:** 6 plots, 4 soil types, 20+ plants with rarities & traits
- **Processing System:** 5 methods (Drying → Aether Extraction), each plant requires the right machine
- **Brewing System:** 14+ potions, purity system (0-100%), optional brewing minigame
- **Mutation System:** Cross-breed plants for rare variants
- **NPC Customers:** 5 types with unique personalities and requirements
- **Player Trading:** Direct trade, Bulletin Board, Auction House, Potion Stand
- **Guilds:** Shared garden, group brewing, guild quests
- **Potion Duel:** Fun PvP with potion effects

## License

MIT
