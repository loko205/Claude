# Bloom & Brew — Game Design Document

## Elevator Pitch

You are an alchemist-gardener: Grow magical plants, process their active ingredients with various machines (Drying, Grinding, Pressing, Distilling, Aether Extraction), brew potions with wild effects, and sell them through a growing network of NPCs AND real players.

## Core Loop

```
Seeds → Plant & Tend → Harvest
    → PROCESS (choose the right method!)
    → Obtain Extracts
    → Brew Potions (Purity 0-100%)
    → Sell / Use Yourself
    → Coins, Rep, Rare Recipes, New Seeds
```

## Inspirations

| Game | Adopted Element |
|------|-----------------|
| Grow a Garden | Plot system, plant care, growth phases |
| Schedule 1 | Purity system, "dealing" mechanic (as fantasy alchemy) |
| Hay Day | NPC customer orders, delivery system |

---

## 1. Garden System

### Plots
- Start: 1 Plot (3x3 = 9 fields), max 6 Plots
- 4 Types: Standard, Greenhouse (+50% Speed), Mutation Plot (+50% Mutation), Premium (+30% Value)
- 4 Soils: Normal, Nutrient Soil (+20% Growth), Mystic (+15% Mutation), Golden (+30% Value)

### Plants (20+)
- 6 Rarities: Common (60%) → Uncommon (25%) → Rare (10%) → Epic (4%) → Legendary (0.9%) → Mythic (0.1%)
- 6 Growth Phases: Seed → Sprout → Growing → Bloom → Harvest → Overripe
- 5 Quality Tiers: ★ Mediocre (1x) → ★★★★★ Masterwork (3x)
- 8 Traits: Glowing, Gigantic, Fast-Growing, Self-Watering, Potent, Golden, Immortal, Fragrant

### Care
- Watering: +50% growth speed (30s cooldown)
- Fertilizing: +1 quality tier (costs Coins)
- Pruning: +mutation chance

---

## 2. Processing System (NEW)

Harvested plants must first be PROCESSED before they can serve as potion ingredients.

### 5 Methods

| Method | Machine | Cost | From Level | Duration | Output |
|--------|---------|------|------------|----------|--------|
| Drying | Drying Rack | 50 | 1 | 60s | Dried Herbs |
| Grinding | Stone Mortar | 200 | 3 | 45s | Powder/Spores |
| Pressing | Plant Press | 500 | 8 | 30s | Oil/Juice/Nectar |
| Distilling | Distillery | 1500 | 15 | 90s | Distillate/Aeth. Oil |
| Aether Extraction | Aether Extractor | 5000 | 25 | 120s | Magical Essence |

### Plant → Method Assignment

Each plant has a **primary method** (100% yield) and optionally an **alternative** (reduced yield). Wrong method = plant destroyed!

- Moonherb → Drying (dry the leaves)
- Flameleaf → Pressing (fire oil in the leaf)
- Mistvine → Distilling (volatile essence)
- Starmoss → Grinding (release spores)
- Galaxyflower → Aether Extraction (starlight is not physical)

### Machine Upgrades (3 Tiers)
- Basic: Base
- Improved: +15% Potency, -20% Duration (3x Cost)
- Master: +30% Potency, -40% Duration, +1 Extract (8x Cost)

### Result: Extracts
From a plant you get an extract with **Potency** (based on plant quality × method efficiency × machine level).

---

## 3. Brewing System

### Lab
- From Level 3 (early! Core feature)
- 5 Cauldron Tiers: Wood → Copper → Silver → Gold → Obsidian
- Higher cauldron = more ingredient slots, better purity, faster

### Potions
14+ recipes in 4 tiers:
- **Starter (Lv 3):** Jump Potion, Glow Potion, Mist Potion, Speed Potion
- **Advanced (Lv 8):** Invisibility Potion, Flight Essence, Giant Growth, Magnetic Potion
- **Rare (Lv 15):** Teleportation Elixir, Time Potion, Phoenix Tear, Chaos Potion
- **Legendary (Lv 25):** Midas Elixir, Omniscient Potion

### Purity (0-100%)
THE core element (inspired by Schedule 1):
- Extract Potency (50%) + Cauldron Level (20%) + Minigame Score (20%) + Potent Trait (10%) ± 5% Random
- 6 Tiers: Diluted (0.3x) → Impure (0.6x) → Standard (1x) → Pure (1.5x) → Crystal Clear (2.5x) → Perfect (5x, golden glowing!)

### Brewing Minigame (optional)
- Timing: Add extracts at the right moment
- Temperature: Keep slider in the green zone
- Stirring: Stir in rhythm
- Perfect minigame = up to +20% purity
- Auto-brew possible (without bonus)

---

## 4. NPC Customers

5 types with unique personalities:

| Customer | From Rep | Wants | Timer |
|----------|----------|-------|-------|
| Villager | 0 | Common plants/Starter potions | 10min |
| Healer | 100 | Specific potions, 50%+ purity | 8min |
| Noble | 500 | Rare potions, 70%+ purity | 12min |
| Warlock | 2000 | Epic+ potions, 85%+ purity, with trait | 15min |
| The Shadow | 10000 | Legendary potion, 95%+ purity | 5min! |

---

## 5. Player Interactions

### Direct Trade (Lv 5)
- Trade window, anti-scam (10s countdown), trust system

### Bulletin Board (Lv 8)
- Marketplace with offers, secret offers from Rep 1000

### Potion Stand (Lv 10)
- Personal stand in front of the garden, regular customer system, dealer reputation

### Auction House (Lv 15)
- For Epic+ items, 1h/6h/24h auctions, buy-it-now

### Guilds (Lv 12)
- Shared garden, group brewing (+10% purity), guild quests

### Potion Duel (Lv 10)
- Fun PvP: Who has the better potion? Effect-based mini-challenges

### Garden Visits (Lv 1)
- Watering help (XP for both), likes, guestbook

---

## 6. Economy

### Currencies
- **Coins:** Main currency (sales, orders, trade)
- **Gems:** Premium (daily, achievements, Robux)
- **Essence:** Only from brewing (cauldron upgrades, secret recipes)

### Dealer Reputation (separate system!)
5 Ranks: Apprentice → Alchemist → Master Brewer → Legendary Alchemist → Grandmaster
Rises through player sales, high purity, satisfied buyers.

### Monetization (Fair, no P2W)
6 Gamepasses (149-599 Robux): Quality-of-life and time savings.
All content earnable. Premium accelerates by 40-60%.

---

## 7. Technical Architecture

- **Strict server-client separation:** All logic runs server-side
- **Anti-exploit:** Server validates every action, rate limit (10 req/s)
- **DataStore:** Complete player profile with auto-save (60s)
- **Rojo:** External code synchronization with Roblox Studio
- **Ticks:** Plants (1s), Brewing (5s), Processing (5s), Customers (10s), Auctions (30s)
