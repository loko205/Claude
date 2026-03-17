--[[
    PotionData.lua — Potion recipes, effects & purity calculation
    Potions are brewed from EXTRACTS (not raw plants!).
    Pipeline: Plant → Processing → Extract → Brew Lab → Potion
]]

local Config = require(script.Parent.Config)

local PotionData = {}

-- ============================================================
-- POTION RECIPES
-- Ingredients are extract IDs (= PlantId, since 1 plant → 1 extract type)
-- ============================================================

PotionData.Potions = {

    -- ======== STARTER POTIONS (Level 3+) ========

    sprungtrank = {
        Id = "sprungtrank",
        Name = "Jump Potion",
        Desc = "Drink this and bounce like a kangaroo on energy drinks!",
        Tier = "Starter",
        LevelReq = 3,
        Ingredients = {
            { ExtractFrom = "mondkraut", Amount = 2 },
        },
        BrewTime = 30,
        BaseValue = 25,
        Effect = {
            Type = "JumpBoost",
            Strength = 3.0,       -- 3x jump height
            BaseDuration = 60,    -- 60 seconds
        },
    },

    gluehtrank = {
        Id = "gluehtrank",
        Name = "Glow Potion",
        Desc = "You glow like a disco ball. Party wherever you go!",
        Tier = "Starter",
        LevelReq = 3,
        Ingredients = {
            { ExtractFrom = "flammenblatt", Amount = 1 },
            { ExtractFrom = "mondkraut", Amount = 1 },
        },
        BrewTime = 45,
        BaseValue = 35,
        Effect = {
            Type = "Glow",
            Strength = 1.0,
            BaseDuration = 120,
        },
    },

    nebeltrank = {
        Id = "nebeltrank",
        Name = "Mist Potion",
        Desc = "Makes you semi-transparent. Perfect for dodging awkward encounters.",
        Tier = "Starter",
        LevelReq = 3,
        Ingredients = {
            { ExtractFrom = "nebelranke", Amount = 2 },
        },
        BrewTime = 60,
        BaseValue = 50,
        Effect = {
            Type = "Transparency",
            Strength = 0.5,        -- 50% transparent
            BaseDuration = 45,
        },
    },

    speedtrank = {
        Id = "speedtrank",
        Name = "Speed Potion",
        Desc = "ZOOOOM! Everything goes blurry. Trees? What trees?",
        Tier = "Starter",
        LevelReq = 3,
        Ingredients = {
            { ExtractFrom = "flammenblatt", Amount = 1 },
            { ExtractFrom = "sternmoos", Amount = 1 },
        },
        BrewTime = 45,
        BaseValue = 40,
        Effect = {
            Type = "SpeedBoost",
            Strength = 1.5,        -- +50% speed
            BaseDuration = 60,
        },
    },

    -- ======== ADVANCED POTIONS (Level 8+) ========

    unsichtbarkeitstrank = {
        Id = "unsichtbarkeitstrank",
        Name = "Invisibility Potion",
        Desc = "Poof! Gone. But please don't drink this during class.",
        Tier = "Advanced",
        LevelReq = 8,
        Ingredients = {
            { ExtractFrom = "nebelranke", Amount = 2 },
            { ExtractFrom = "schattenlilie", Amount = 1 },
        },
        BrewTime = 120,
        BaseValue = 150,
        Effect = {
            Type = "Invisibility",
            Strength = 1.0,
            BaseDuration = 30,
        },
    },

    flugessenz = {
        Id = "flugessenz",
        Name = "Flight Essence",
        Desc = "Fly! Like a bird! Only without feathers and with more 'WAAAH!'",
        Tier = "Advanced",
        LevelReq = 8,
        Ingredients = {
            { ExtractFrom = "sternmoos", Amount = 1 },
            { ExtractFrom = "mondkraut", Amount = 1 },
            { ExtractFrom = "flammenblatt", Amount = 1 },
        },
        BrewTime = 180,
        BaseValue = 200,
        Effect = {
            Type = "Flight",
            Strength = 1.0,
            BaseDuration = 45,
        },
    },

    riesenwuchs = {
        Id = "riesenwuchs",
        Name = "Giant Growth Potion",
        Desc = "FEE-FI-FO-FUM! You're big now. Really big. Doors are your enemy.",
        Tier = "Advanced",
        LevelReq = 8,
        Ingredients = {
            { ExtractFrom = "sternmoos", Amount = 2 },
            { ExtractFrom = "donnerknospe", Amount = 1 },
        },
        BrewTime = 150,
        BaseValue = 180,
        Effect = {
            Type = "SizeBoost",
            Strength = 3.0,        -- 3x size
            BaseDuration = 60,
        },
    },

    magnetischer_trank = {
        Id = "magnetischer_trank",
        Name = "Magnet Potion",
        Desc = "Coins and drops fly toward you like moths to a flame. Cha-ching!",
        Tier = "Advanced",
        LevelReq = 8,
        Ingredients = {
            { ExtractFrom = "irrlichtwurzel", Amount = 1 },
            { ExtractFrom = "nebelranke", Amount = 1 },
        },
        BrewTime = 90,
        BaseValue = 120,
        Effect = {
            Type = "Magnet",
            Strength = 30,          -- Radius in studs
            BaseDuration = 120,
        },
    },

    -- ======== RARE POTIONS (Level 15+) ========

    teleportations_elixier = {
        Id = "teleportations_elixier",
        Name = "Teleportation Elixir",
        Desc = "Be here, be there — quantum physics for beginners!",
        Tier = "Rare",
        LevelReq = 15,
        Ingredients = {
            { ExtractFrom = "voidfarn", Amount = 1 },
            { ExtractFrom = "frostbluete", Amount = 1 },
        },
        BrewTime = 300,
        BaseValue = 500,
        Effect = {
            Type = "Teleport",
            Strength = 1,           -- 1x use
            BaseDuration = 0,       -- Instant
        },
    },

    zeittrank = {
        Id = "zeittrank",
        Name = "Time Potion",
        Desc = "Time flies... and your plants grow twice as fast. Tick-tock!",
        Tier = "Rare",
        LevelReq = 15,
        Ingredients = {
            { ExtractFrom = "zeitlotus", Amount = 1 },
            { ExtractFrom = "sturmranke", Amount = 1 },
        },
        BrewTime = 600,
        BaseValue = 800,
        Effect = {
            Type = "GrowthBoost",
            Strength = 2.0,         -- 2x growth
            BaseDuration = 300,     -- 5 minutes
        },
    },

    phoenixtraene = {
        Id = "phoenixtraene",
        Name = "Phoenix Tear",
        Desc = "A second life! Well, more like a second chance. Still awesome though.",
        Tier = "Rare",
        LevelReq = 15,
        Ingredients = {
            { ExtractFrom = "phoenixkelch", Amount = 1 },
            { ExtractFrom = "galaxienblume", Amount = 1 },
        },
        BrewTime = 900,
        BaseValue = 1500,
        Effect = {
            Type = "Revive",
            Strength = 1,
            BaseDuration = 0,       -- Passive until consumed
        },
    },

    chaostrank = {
        Id = "chaostrank",
        Name = "Chaos Potion",
        Desc = "What happens? NOBODY KNOWS! Could be amazing. Could be... interesting.",
        Tier = "Rare",
        LevelReq = 15,
        Ingredients = {
            -- 3x any Epic+ plants (specially handled in BrewingEngine)
            { ExtractFrom = "ANY_EPIC_PLUS", Amount = 3 },
        },
        BrewTime = 300,
        BaseValue = 600,
        Effect = {
            Type = "Random",
            Strength = 1.0,
            BaseDuration = 60,
        },
        IsWildcard = true, -- Flag for BrewingEngine: accepts any Epic+ extracts
    },

    -- ======== LEGENDARY POTIONS (Level 25+) ========

    midas_elixier = {
        Id = "midas_elixier",
        Name = "Midas Elixir",
        Desc = "Everything turns to gold! Well, almost. Your harvests yield 5x coins. GOOD ENOUGH.",
        Tier = "Legendary",
        LevelReq = 25,
        Ingredients = {
            { ExtractFrom = "weltbaumsetzling", Amount = 1 },
            { ExtractFrom = "galaxienblume", Amount = 2 },
        },
        BrewTime = 1800,
        BaseValue = 5000,
        Effect = {
            Type = "GoldTouch",
            Strength = 5.0,         -- 5x coins
            BaseDuration = 60,
        },
    },

    allwissender_trank = {
        Id = "allwissender_trank",
        Name = "Omniscience Potion",
        Desc = "You see EVERYTHING. All recipes. All secrets. And yes, even what your neighbor is growing.",
        Tier = "Legendary",
        LevelReq = 25,
        Ingredients = {
            { ExtractFrom = "ewige_essenz", Amount = 1 },
            { ExtractFrom = "zeitlotus", Amount = 1 },
        },
        BrewTime = 2400,
        BaseValue = 8000,
        Effect = {
            Type = "Omniscience",
            Strength = 1.0,
            BaseDuration = 600,     -- 10 minutes
        },
    },
}

-- ============================================================
-- PURITY CALCULATION
-- ============================================================

-- Calculate purity of a brewed potion
-- extractPotencies: array of potency values (0-1) for each ingredient
-- cauldronLevel: 1-5 (index into Config.Brewing.CauldronLevels)
-- minigameScore: 0-100 (from brew minigame, 0 = auto-brew)
-- hasPotentTrait: bool (any ingredient had "Potent" trait)
function PotionData.CalculatePurity(extractPotencies, cauldronLevel, minigameScore, hasPotentTrait)
    local weights = Config.Brewing.PurityWeights

    -- Average extract potency (0-1)
    local avgPotency = 0
    for _, p in ipairs(extractPotencies) do
        avgPotency = avgPotency + p
    end
    avgPotency = avgPotency / #extractPotencies

    -- Cauldron bonus (0-20 from config)
    local cauldronData = Config.Brewing.CauldronLevels[cauldronLevel or 1]
    local cauldronBonus = cauldronData and cauldronData.PurityBonus or 0

    -- Minigame contribution (0-20 max)
    local minigameBonus = (minigameScore or 0) / 100 * Config.Brewing.MinigameMaxBonus

    -- Potent trait contribution
    local potentBonus = 0
    if hasPotentTrait then
        potentBonus = Config.Plants.Traits.Potent.PurityBonus
    end

    -- Weighted purity: Each factor contributes proportionally
    -- Max potency contribution: 100 * 0.50 = 50
    -- Max cauldron contribution: 20 / 20 * 100 * 0.20 = 20
    -- Max minigame contribution: 20 / 20 * 100 * 0.20 = 20
    -- Max potent contribution: 15 / 15 * 100 * 0.10 = 10
    -- Total max = 100
    local maxCauldronBonus = Config.Brewing.CauldronLevels[#Config.Brewing.CauldronLevels].PurityBonus
    local maxMinigameBonus = Config.Brewing.MinigameMaxBonus
    local maxPotentBonus = Config.Plants.Traits.Potent.PurityBonus

    local purity = (avgPotency * 100 * weights.ExtractPotency)
                  + ((cauldronBonus / math.max(1, maxCauldronBonus)) * 100 * weights.CauldronBonus)
                  + ((minigameBonus / math.max(1, maxMinigameBonus)) * 100 * weights.MinigameScore)
                  + ((potentBonus / math.max(1, maxPotentBonus)) * 100 * weights.PotentTrait)

    -- Random variance
    local variance = (math.random() * 2 - 1) * Config.Brewing.RandomPurityRange
    purity = purity + variance

    -- Clamp 0-100
    return math.max(0, math.min(100, math.floor(purity + 0.5)))
end

-- Get purity tier info for a given purity value
function PotionData.GetPurityTier(purity)
    for _, tier in ipairs(Config.Brewing.PurityTiers) do
        if purity >= tier.Min and purity <= tier.Max then
            return tier
        end
    end
    return Config.Brewing.PurityTiers[1] -- Fallback: Diluted
end

-- Calculate actual potion value based on base value and purity
function PotionData.CalculateValue(potionId, purity, qualityStars)
    local potion = PotionData.Potions[potionId]
    if not potion then return 0 end

    local tier = PotionData.GetPurityTier(purity)
    local qualityMult = Config.Plants.QualityStars[qualityStars or 1]
    qualityMult = qualityMult and qualityMult.Mult or 1.0

    return math.floor(potion.BaseValue * tier.ValueMult * qualityMult)
end

-- Calculate actual effect duration based on purity
function PotionData.GetEffectDuration(potionId, purity)
    local potion = PotionData.Potions[potionId]
    if not potion then return 0 end

    local tier = PotionData.GetPurityTier(purity)
    return math.floor(potion.Effect.BaseDuration * tier.DurationMult)
end

-- Calculate actual effect strength based on purity
function PotionData.GetEffectStrength(potionId, purity)
    local potion = PotionData.Potions[potionId]
    if not potion then return 0 end

    local tier = PotionData.GetPurityTier(purity)
    return potion.Effect.Strength * tier.EffectMult
end

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

function PotionData.GetPotion(potionId)
    return PotionData.Potions[potionId]
end

function PotionData.GetPotionsByTier(tier)
    local result = {}
    for id, potion in pairs(PotionData.Potions) do
        if potion.Tier == tier then
            result[id] = potion
        end
    end
    return result
end

function PotionData.GetAllPotionIds()
    local ids = {}
    for id in pairs(PotionData.Potions) do
        table.insert(ids, id)
    end
    return ids
end

-- Check if player has required extracts for a potion
-- inventory: { [extractId] = amount }
function PotionData.CanBrew(potionId, inventory, playerLevel)
    local potion = PotionData.Potions[potionId]
    if not potion then return false, "Unknown potion" end

    if playerLevel < potion.LevelReq then
        return false, "Level " .. potion.LevelReq .. " required"
    end

    for _, ingredient in ipairs(potion.Ingredients) do
        if ingredient.ExtractFrom == "ANY_EPIC_PLUS" then
            -- Special case: count all Epic+ extracts
            local epicCount = 0
            for extractId, amount in pairs(inventory) do
                -- Would need PlantData to check rarity — handled in BrewingEngine
                epicCount = epicCount + amount
            end
            if epicCount < ingredient.Amount then
                return false, "Not enough Epic+ extracts"
            end
        else
            local have = inventory[ingredient.ExtractFrom] or 0
            if have < ingredient.Amount then
                return false, "Not enough " .. ingredient.ExtractFrom
            end
        end
    end

    return true, "OK"
end

-- Get essence reward for brewing a potion
function PotionData.GetEssenceReward(potionId)
    local potion = PotionData.Potions[potionId]
    if not potion then return 0 end

    -- Map tier to rarity for essence calculation
    local tierToRarity = {
        Starter = "Common",
        Advanced = "Uncommon",
        Rare = "Rare",
        Legendary = "Legendary",
    }

    local rarity = tierToRarity[potion.Tier] or "Common"
    return Config.Brewing.EssencePerBrew[rarity] or 1
end

return PotionData
