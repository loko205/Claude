--[[
    CustomerDisplay.lua — NPC Customer Display (STUB)
    Order board, NPC dialog window, timer display.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local CustomerData = require(ReplicatedStorage.Shared.CustomerData)

local CustomerDisplay = {}
local player = Players.LocalPlayer

-- ============================================================
-- TODO: ORDER BOARD
-- ============================================================
-- [ ] Order board as 2D UI (on wooden sign background)
-- [ ] Max 8 orders side by side as "notes"
-- [ ] Each note: Customer type icon, item icon, quantity, reward
-- [ ] Timer countdown per order (red when < 60s)
-- [ ] Purity requirement as bar (e.g. "min 70%")
-- [ ] "Fulfill" button when requirements are met
-- [ ] "Decline" button (gray, small)
-- [ ] Order difficulty color-coded (green → orange → red)

-- ============================================================
-- TODO: NPC DIALOG WINDOW
-- ============================================================
-- [ ] Dialog box at the bottom of the screen (visual novel style)
-- [ ] NPC portrait on the left (different image per customer type)
-- [ ] Name + rank above the portrait
-- [ ] Type-specific color scheme:
--     - Villager: Green, friendly
--     - Healer: Light green, warm
--     - Noble: Gold, pompous
--     - Warlock: Purple, mysterious
--     - The Shadow: Black, minimal
-- [ ] Text typewriter effect (letter by letter)
-- [ ] Response options: "Accept" / "Decline"
-- [ ] Different dialogs: Greeting, acceptance, rejection, timeout

-- ============================================================
-- TODO: NPC MODELS (3D)
-- ============================================================
-- [ ] Villager: Farmer with straw hat, smiling
-- [ ] Healer: Robe in green tones, staff with crystal
-- [ ] Noble: Royal clothing, crown/monocle, raised nose
-- [ ] Warlock: Dark hooded robe, glowing eyes
-- [ ] The Shadow: Barely visible figure, only eyes glow
-- [ ] NPCs spawn at the order board and wait there

-- ============================================================
-- TODO: ORDER FULFILLMENT
-- ============================================================
-- [ ] Item picker: Which items from inventory to hand over?
-- [ ] Auto-select for matching items
-- [ ] Quality/purity check visual (green = fits, red = not good enough)
-- [ ] Handover animation (items fly to the NPC)
-- [ ] Reward animation (coins rain, XP popup, bonus items)

-- Placeholder initialization
function CustomerDisplay.Init()
    print("[CustomerDisplay] Initialized (STUB)")
end

CustomerDisplay.Init()

return CustomerDisplay
