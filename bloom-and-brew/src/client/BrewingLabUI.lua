--[[
    BrewingLabUI.lua — Client-side Brewing Lab Interface (STUB)
    Cauldron UI, recipe book, minigame, purity display.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local PotionData = require(ReplicatedStorage.Shared.PotionData)
local ProcessingData = require(ReplicatedStorage.Shared.ProcessingData)

local BrewingLabUI = {}
local player = Players.LocalPlayer

-- ============================================================
-- TODO: LAB VIEW
-- ============================================================
-- [ ] 3D lab room with cauldron in the center
-- [ ] Cauldron model based on level (Wood → Copper → Silver → Gold → Obsidian)
-- [ ] Shelves with extract vials (inventory visualization)
-- [ ] Steam VFX from cauldron during brewing
-- [ ] Glow effects at high purity
-- [ ] Upgrade sign on the cauldron

-- ============================================================
-- TODO: RECIPE BOOK
-- ============================================================
-- [ ] Recipe book UI as an openable book
-- [ ] Show discovered recipes in full
-- [ ] Undiscovered recipes as "???" (silhouette)
-- [ ] Filter: Tier (Starter/Advanced/Rare/Legendary)
-- [ ] Ingredient checklist (green = available, red = missing)
-- [ ] Show extract type (not raw plant!)
-- [ ] "Brew" button when all extracts are available
-- [ ] Mode selection: Minigame vs. auto-brew

-- ============================================================
-- TODO: BREWING MINIGAME
-- ============================================================
-- [ ] Fullscreen minigame overlay when brewing starts
-- [ ] Phase 1: Ingredient timing (throw extracts into cauldron at the right moment)
--     - Ingredients fall from above, perfect timing = green zone
--     - Feedback: "Perfect!", "Good", "Meh..."
-- [ ] Phase 2: Temperature control (slider)
--     - Temperature fluctuates, player must keep it in the green zone
--     - Too hot = red, too cold = blue
-- [ ] Phase 3: Stirring to the rhythm
--     - Tap circles on the cauldron in time
--     - Visual stirring animation
-- [ ] Score display at the end (0-100)
-- [ ] Send score to server (Fire BrewingRemotes.SubmitMinigame)
-- [ ] Auto-brew option: Skip minigame

-- ============================================================
-- TODO: BREWING PROGRESS
-- ============================================================
-- [ ] Progress bar above the cauldron
-- [ ] Timer display (remaining seconds)
-- [ ] Steam intensity increases with progress
-- [ ] "Done!" notification (particle explosion)
-- [ ] Collection animation (potion vial)

-- ============================================================
-- TODO: POTION RESULT
-- ============================================================
-- [ ] Result popup: Potion name, purity, value
-- [ ] Purity bar with color (Diluted=Gray → Perfect=Gold)
-- [ ] At "Perfect" (96-100%): Golden glow effect + confetti
-- [ ] Potiondex update on new discovery
-- [ ] "Drink yourself" vs "Store" selection

-- ============================================================
-- TODO: EXTRACT INVENTORY
-- ============================================================
-- [ ] List of all extracts with quantity and average potency
-- [ ] Potency display as colored bar (low=red → high=green)
-- [ ] Extract info: Which method, from which plant
-- [ ] Quick info: "Usable for which potions?"

-- Placeholder initialization
function BrewingLabUI.Init()
    print("[BrewingLabUI] Initialized (STUB)")
end

BrewingLabUI.Init()

return BrewingLabUI
