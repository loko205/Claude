--[[
    PlotController.lua — Client-side Garden Controller (STUB)
    Handles garden rendering, planting interactions, and processing UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local PlantData = require(ReplicatedStorage.Shared.PlantData)
local ProcessingData = require(ReplicatedStorage.Shared.ProcessingData)

local PlotController = {}
local player = Players.LocalPlayer

-- ============================================================
-- TODO: GARDEN RENDERING
-- ============================================================
-- [ ] Display plot grid (3x3) visually with ground tiles
-- [ ] Plant per tile as 3D model (5 growth stages)
-- [ ] Growth progress bar above each plant
-- [ ] Display quality stars (★-★★★★★)
-- [ ] Trait icons next to the plant (Glowing = glow effect, etc.)
-- [ ] Overripe warning (red flashing when progress > 1.0)
-- [ ] Soil type visually distinguishable (color/texture)
-- [ ] Plot type badge (Standard/Greenhouse/Mutation/Premium)

-- ============================================================
-- TODO: PLANTING INTERACTIONS
-- ============================================================
-- [ ] Seed picker UI: Select seeds from inventory
-- [ ] Click on empty tile → Plant seed (Fire PlantRemotes.PlantSeed)
-- [ ] Click on plant → Action menu (Water/Fertilize/Prune/Harvest)
-- [ ] Watering animation (watering can, water particles)
-- [ ] Fertilize animation (sparkle effect)
-- [ ] Harvest animation (plant disappears, item popup)
-- [ ] Watering cooldown display (30s timer per plant)

-- ============================================================
-- TODO: PROCESSING UI (NEW)
-- ============================================================
-- [ ] Processing station as interactive object next to the garden
-- [ ] Machine selection (only show unlocked ones)
-- [ ] Machine purchase dialog with costs and level requirement
-- [ ] Plant-to-machine drag & drop
-- [ ] Warning for wrong method ("WARNING: Plant will be destroyed!")
-- [ ] Show recommendation for correct method
-- [ ] Progress bar for active processing tasks
-- [ ] Extract collection animation (vial fills up)
-- [ ] Machine upgrade UI (Basic → Improved → Master)
-- [ ] Extract inventory display (what do I have, how much, what potency?)

-- ============================================================
-- TODO: PLOT MANAGEMENT
-- ============================================================
-- [ ] Plot purchase button (if < MaxPlots)
-- [ ] Plot upgrade button with cost display
-- [ ] Soil change UI
-- [ ] Plot type selection on purchase
-- [ ] Overview of all plots (minimap?)

-- ============================================================
-- TODO: GARDEN VISITS (other players)
-- ============================================================
-- [ ] "Visit" button for other players
-- [ ] Visit mode: View only + watering help
-- [ ] "Like" button
-- [ ] Guestbook UI
-- [ ] Plant info popup on hover

-- Placeholder initialization
function PlotController.Init()
    print("[PlotController] Initialized (STUB)")
end

PlotController.Init()

return PlotController
