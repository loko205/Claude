--[[
    PotionData.lua — Trankrezepte, Effekte & Reinheitsberechnung
    Tränke werden aus EXTRAKTEN gebraut (nicht rohe Pflanzen!).
    Pipeline: Pflanze → Verarbeitung → Extrakt → Brau-Labor → Trank
]]

local Config = require(script.Parent.Config)

local PotionData = {}

-- ============================================================
-- TRANKREZEPTE
-- Zutaten sind Extrakt-IDs (= PlantId, da 1 Pflanze → 1 Extrakttyp)
-- ============================================================

PotionData.Potions = {

    -- ======== STARTER-TRÄNKE (Level 3+) ========

    sprungtrank = {
        Id = "sprungtrank",
        Name = "Sprungtrank",
        Desc = "Trink das und spring wie ein Känguru auf Energy-Drink!",
        Tier = "Starter",
        LevelReq = 3,
        Ingredients = {
            { ExtractFrom = "mondkraut", Amount = 2 },
        },
        BrewTime = 30,
        BaseValue = 25,
        Effect = {
            Type = "JumpBoost",
            Strength = 3.0,       -- 3x Sprunghöhe
            BaseDuration = 60,    -- 60 Sekunden
        },
    },

    gluehtrank = {
        Id = "gluehtrank",
        Name = "Glühtrank",
        Desc = "Du leuchtest wie eine Discokugel. Party wherever you go!",
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
        Name = "Nebeltrank",
        Desc = "Macht dich halbtransparent. Perfekt um peinlichen Begegnungen auszuweichen.",
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
        Name = "Speedtrank",
        Desc = "ZOOOOM! Alles wird unscharf. Bäume? Welche Bäume?",
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
            Strength = 1.5,        -- +50% Speed
            BaseDuration = 60,
        },
    },

    -- ======== FORTGESCHRITTENE TRÄNKE (Level 8+) ========

    unsichtbarkeitstrank = {
        Id = "unsichtbarkeitstrank",
        Name = "Unsichtbarkeitstrank",
        Desc = "Poof! Weg bist du. Aber bitte nicht im Unterricht trinken.",
        Tier = "Fortgeschritten",
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
        Name = "Flugessenz",
        Desc = "Fliegen! Wie ein Vogel! Nur ohne Federn und mit mehr 'WAAAH!'",
        Tier = "Fortgeschritten",
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
        Name = "Riesenwuchs-Trank",
        Desc = "FEE-FI-FO-FUM! Du bist jetzt groß. Richtig groß. Türen sind dein Feind.",
        Tier = "Fortgeschritten",
        LevelReq = 8,
        Ingredients = {
            { ExtractFrom = "sternmoos", Amount = 2 },
            { ExtractFrom = "donnerknospe", Amount = 1 },
        },
        BrewTime = 150,
        BaseValue = 180,
        Effect = {
            Type = "SizeBoost",
            Strength = 3.0,        -- 3x Größe
            BaseDuration = 60,
        },
    },

    magnetischer_trank = {
        Id = "magnetischer_trank",
        Name = "Magnetischer Trank",
        Desc = "Coins und Drops fliegen auf dich zu wie Motten zum Licht. Cha-ching!",
        Tier = "Fortgeschritten",
        LevelReq = 8,
        Ingredients = {
            { ExtractFrom = "irrlichtwurzel", Amount = 1 },
            { ExtractFrom = "nebelranke", Amount = 1 },
        },
        BrewTime = 90,
        BaseValue = 120,
        Effect = {
            Type = "Magnet",
            Strength = 30,          -- Radius in Studs
            BaseDuration = 120,
        },
    },

    -- ======== SELTENE TRÄNKE (Level 15+) ========

    teleportations_elixier = {
        Id = "teleportations_elixier",
        Name = "Teleportations-Elixier",
        Desc = "Hier sein, dort sein — Quantenphysik für Anfänger!",
        Tier = "Selten",
        LevelReq = 15,
        Ingredients = {
            { ExtractFrom = "voidfarn", Amount = 1 },
            { ExtractFrom = "frostbluete", Amount = 1 },
        },
        BrewTime = 300,
        BaseValue = 500,
        Effect = {
            Type = "Teleport",
            Strength = 1,           -- 1x Nutzung
            BaseDuration = 0,       -- Instant
        },
    },

    zeittrank = {
        Id = "zeittrank",
        Name = "Zeittrank",
        Desc = "Die Zeit fliegt... und deine Pflanzen wachsen doppelt so schnell. Tic-Toc!",
        Tier = "Selten",
        LevelReq = 15,
        Ingredients = {
            { ExtractFrom = "zeitlotus", Amount = 1 },
            { ExtractFrom = "sturmranke", Amount = 1 },
        },
        BrewTime = 600,
        BaseValue = 800,
        Effect = {
            Type = "GrowthBoost",
            Strength = 2.0,         -- 2x Wachstum
            BaseDuration = 300,     -- 5 Minuten
        },
    },

    phoenixtraene = {
        Id = "phoenixtraene",
        Name = "Phönixträne",
        Desc = "Ein zweites Leben! Naja, eher ein zweiter Versuch. Immer noch krass.",
        Tier = "Selten",
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
            BaseDuration = 0,       -- Passive bis verbraucht
        },
    },

    chaostrank = {
        Id = "chaostrank",
        Name = "Chaostrank",
        Desc = "Was passiert? KEINER WEISS ES! Könnte super werden. Könnte... interessant werden.",
        Tier = "Selten",
        LevelReq = 15,
        Ingredients = {
            -- 3x beliebige Epic+ Pflanzen (speziell behandelt in BrewingEngine)
            { ExtractFrom = "ANY_EPIC_PLUS", Amount = 3 },
        },
        BrewTime = 300,
        BaseValue = 600,
        Effect = {
            Type = "Random",
            Strength = 1.0,
            BaseDuration = 60,
        },
        IsWildcard = true, -- Flag für BrewingEngine: akzeptiert beliebige Epic+ Extrakte
    },

    -- ======== LEGENDÄRE TRÄNKE (Level 25+) ========

    midas_elixier = {
        Id = "midas_elixier",
        Name = "Midas-Elixier",
        Desc = "Alles wird zu Gold! Naja, fast. Deine Ernten geben 5x Coins. DAS REICHT.",
        Tier = "Legendaer",
        LevelReq = 25,
        Ingredients = {
            { ExtractFrom = "weltbaumsetzling", Amount = 1 },
            { ExtractFrom = "galaxienblume", Amount = 2 },
        },
        BrewTime = 1800,
        BaseValue = 5000,
        Effect = {
            Type = "GoldTouch",
            Strength = 5.0,         -- 5x Coins
            BaseDuration = 60,
        },
    },

    allwissender_trank = {
        Id = "allwissender_trank",
        Name = "Allwissender Trank",
        Desc = "Du siehst ALLES. Alle Rezepte. Alle Geheimnisse. Und ja, auch was der Nachbar anbaut.",
        Tier = "Legendaer",
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
            BaseDuration = 600,     -- 10 Minuten
        },
    },
}

-- ============================================================
-- REINHEITSBERECHNUNG
-- ============================================================

-- Calculate purity of a brewed potion
-- extractPotencies: array of potency values (0-1) for each ingredient
-- cauldronLevel: 1-5 (index into Config.Brewing.CauldronLevels)
-- minigameScore: 0-100 (from brau-minigame, 0 = auto-brew)
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

    -- Weighted sum
    local purity = (avgPotency * 100 * weights.ExtractPotency)
                  + (cauldronBonus * weights.CauldronBonus / 0.20 * 100 * weights.CauldronBonus)
                  + (minigameBonus * weights.MinigameScore / 0.20)
                  + (potentBonus * weights.PotentTrait / 0.10)

    -- Simpler calculation: Base from potency + bonuses
    purity = (avgPotency * 60) -- Max 60 from ingredients
           + cauldronBonus      -- Max 20 from cauldron
           + (minigameBonus)    -- Max 20 from minigame
           + (hasPotentTrait and potentBonus or 0) -- Bonus from trait

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
    return Config.Brewing.PurityTiers[1] -- Fallback: Verdünnt
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
-- HILFSFUNKTIONEN
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
    if not potion then return false, "Unbekannter Trank" end

    if playerLevel < potion.LevelReq then
        return false, "Level " .. potion.LevelReq .. " benötigt"
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
                return false, "Nicht genug Epic+ Extrakte"
            end
        else
            local have = inventory[ingredient.ExtractFrom] or 0
            if have < ingredient.Amount then
                return false, "Nicht genug " .. ingredient.ExtractFrom
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
        Fortgeschritten = "Uncommon",
        Selten = "Rare",
        Legendaer = "Legendary",
    }

    local rarity = tierToRarity[potion.Tier] or "Common"
    return Config.Brewing.EssencePerBrew[rarity] or 1
end

return PotionData
