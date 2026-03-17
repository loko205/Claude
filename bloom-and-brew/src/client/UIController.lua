--[[
    UIController.lua — Main UI Controller (STUB)
    HUD, inventory, level display, notifications.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)

local UIController = {}
local player = Players.LocalPlayer

-- ============================================================
-- TODO: HUD (Head-Up Display)
-- ============================================================
-- [ ] Top left: Player name, level, XP bar
-- [ ] Top right: Coins (gold), Gems (blue), Essence (purple)
-- [ ] Below coins: NPC rep display (small text)
-- [ ] Dealer rank badge (when unlocked)
-- [ ] Minimap/compass (optional)

-- ============================================================
-- TODO: INVENTORY UI
-- ============================================================
-- [ ] Tab-based inventory: Seeds | Plants | Extracts | Potions | Catalysts
-- [ ] Each item: Icon + name + quantity/quality
-- [ ] Plants: Quality stars + traits as badges
-- [ ] Potions: Purity display + effect description
-- [ ] Extracts: Potency bar + quantity
-- [ ] Right-click/long press → Context menu (Sell, Process, etc.)
-- [ ] Search/filter function
-- [ ] Sorting: Name, rarity, value, quantity

-- ============================================================
-- TODO: NOTIFICATIONS
-- ============================================================
-- [ ] Toast notifications (bottom right, stacking)
-- [ ] Types: Harvest ready, processing done, potion done, order received
-- [ ] Level-up animation (fullscreen flash + fanfare)
-- [ ] New discovery: Golden frame + "NEW" badge
-- [ ] Trade request popup
-- [ ] Daily login reward screen

-- ============================================================
-- TODO: COLLECTION ALBUM (Plantdex & Potiondex)
-- ============================================================
-- [ ] Book-style UI with all plants/potions
-- [ ] Discovered items: Complete with image + description
-- [ ] Undiscovered: Silhouette + "???"
-- [ ] Progress display (X/Y discovered)
-- [ ] Achievements for completion

-- ============================================================
-- TODO: SETTINGS
-- ============================================================
-- [ ] Music volume
-- [ ] SFX volume
-- [ ] Graphics quality
-- [ ] Notification settings
-- [ ] Help / Replay tutorial

-- Placeholder initialization
function UIController.Init()
    print("[UIController] Initialized (STUB)")
end

UIController.Init()

return UIController
