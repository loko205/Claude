# Contributing to Bloom & Brew

## Setup

1. Install [Rojo](https://rojo.space/) (VS Code Extension + Roblox Studio Plugin)
2. Clone the repository
3. Run `rojo serve` in the `bloom-and-brew/` directory
4. In Roblox Studio: Connect via Rojo Plugin

## Project Structure

- `src/shared/` → ReplicatedStorage (data modules, shared by client and server)
- `src/server/` → ServerScriptService (game logic, NEVER trust client data)
- `src/client/` → StarterPlayerScripts (UI only, sends actions to server)
- `src/data/` → Balancing documentation

## Code Style

- **Language:** Luau (Roblox Lua)
- **Comments:** Technical comments in English, player-facing text in German
- **All game logic is server-side** — the client only renders and sends user inputs
- **All parameters in `Config.lua`** — no magic numbers in other files
- **Anti-Exploit:** Validate EVERY client input on the server

## Architecture Rules

1. Client sends actions → Server validates → Server executes → Server notifies client
2. Never trust client data (positions, amounts, inventories)
3. Rate-limit all RemoteEvents (max 10/s per player)
4. Type-check all RemoteEvent parameters on the server

## Git Workflow

- Feature branches: `feature/your-feature`
- No direct pushes to `main`
- Descriptive commit messages in German or English
- Test in Roblox Studio before pushing

## Adding New Content

### New Plant
1. Add definition to `PlantData.lua` (with Processing method!)
2. Add extract info (ExtractName, ExtractDesc)
3. Add mutation recipe to `MutationRecipes.lua` (if applicable)
4. Update `Balancing.lua`

### New Potion
1. Add recipe to `PotionData.lua` (uses Extracts, not raw plants!)
2. Add effect handling in `BrewingEngine.lua`
3. Add client effect in `PlayerInteraction.lua` (stub TODO)
4. Update `Balancing.lua`

### New Processing Method
1. Add to `Config.Processing.Methods`
2. Add to `ProcessingData.Methods`
3. Update relevant plants in `PlantData.lua`
4. Update `ProcessingManager.lua` if special logic needed
