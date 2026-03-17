--[[
    PlayerInteraction.lua — Player Interactions (STUB)
    Garden visits, watering help, potion duel, guild UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerInteraction = {}
local player = Players.LocalPlayer

-- ============================================================
-- TODO: GARDEN VISITS
-- ============================================================
-- [ ] Player list: Online players with "Visit garden" button
-- [ ] Teleport to the other player's garden
-- [ ] Visit mode: Camera shows the other player's garden
-- [ ] "Like" button (+coins for owner)
-- [ ] Plant hover: Info popup (name, quality, traits)
-- [ ] "Watering help" button for unwatered plants
-- [ ] Watering animation + XP bonus for both players
-- [ ] Guestbook: Leave messages (moderated!)
-- [ ] "Back to my garden" button
-- [ ] Top gardens of the week: Showcase leaderboard

-- ============================================================
-- TODO: POTION DUEL
-- ============================================================
-- [ ] Send duel challenge: Select player + choose potion
-- [ ] Duel request popup for the opponent
-- [ ] Duel arena: Small obstacle course/platform
-- [ ] Countdown (3... 2... 1... GO!)
-- [ ] Effect-specific mini-challenges:
--     - Jump potion → Who reaches the highest platform?
--     - Speed potion → Who is faster in the obstacle course?
--     - Giant growth → Who is the tallest? (Purity determines size)
--     - Flight essence → Who collects more stars in the air?
--     - Invisibility potion → Hide and seek (who finds the other?)
-- [ ] Result screen: Winner + coins + rep
-- [ ] Duel statistics (wins/losses)

-- ============================================================
-- TODO: GUILDS / ALCHEMIST CIRCLE
-- ============================================================
-- [ ] Guild creation: Choose name + icon (from level 12)
-- [ ] Guild joining: List of open guilds + invitations
-- [ ] Guild overview: Members, rank, contributions
-- [ ] Shared garden: Extra plot with guild members
-- [ ] Guild lab: Group brewing UI (multiple players simultaneously)
-- [ ] Guild orders: Large NPC orders that everyone works on
-- [ ] Guild chat
-- [ ] Guild competitions: Guild vs. guild scoreboard
-- [ ] Roles: Leader, Officer, Member

-- ============================================================
-- TODO: DAILY CHALLENGES
-- ============================================================
-- [ ] Community challenge banner at the top of the screen
-- [ ] Progress bar (server-wide progress)
-- [ ] Show own contribution
-- [ ] Reward preview
-- [ ] Challenge types:
--     - "Community brews 1000 potions"
--     - "Find the secret mutation of the day"
--     - "Harvest 1000 plants"
--     - "Highest purity of the day"
-- [ ] Leaderboard: Top contributors

-- ============================================================
-- TODO: POTION CONSUMPTION
-- ============================================================
-- [ ] "Drink" button in inventory / quick bar
-- [ ] Drinking animation (vial to the mouth)
-- [ ] Effect overlay: Buff icon + timer in the HUD corner
-- [ ] Visual effects per potion:
--     - Jump potion: Green particles at the feet
--     - Glow potion: Player glows
--     - Speed potion: Speed lines
--     - Invisibility potion: Transparency transition
--     - Flight essence: Wing particles
--     - Giant growth: Size scaling
-- [ ] Buff expiration warning (5s before: "Effect is about to expire!")

-- Placeholder initialization
function PlayerInteraction.Init()
    print("[PlayerInteraction] Initialized (STUB)")
end

PlayerInteraction.Init()

return PlayerInteraction
