--[[
    PlantData.lua — All plant definitions for Bloom & Brew
    Each plant has: Id, Name, Description, Rarity, GrowthTime,
    BaseValue, possible Traits, and Processing method(s).
]]

local PlantData = {}

-- ============================================================
-- PLANT DEFINITIONS
-- ============================================================

PlantData.Plants = {

    -- ======== COMMON (60%) ========

    mondkraut = {
        Id = "mondkraut",
        Name = "Moonwort",
        Desc = "Glows so bright during a full moon that moths line up for it. Smells like a midnight snack.",
        Rarity = "Common",
        GrowthTime = 30,
        BaseValue = 10,
        SeedCost = 5,
        TraitPool = { "Luminous", "FastGrowing", "Potent", "Fragrant" },
        -- Processing: Let leaves dry, the effect unfolds in open air
        Processing = {
            Primary = "Drying",
            Alternative = nil,
        },
        ExtractName = "Dried Moonwort",
        ExtractDesc = "Silvery shimmering leaves that crackle softly in the moonlight",
    },

    flammenblatt = {
        Id = "flammenblatt",
        Name = "Flameleaf",
        Desc = "Warm to the touch and spices up any soup. Not recommended as a handkerchief.",
        Rarity = "Common",
        GrowthTime = 60,
        BaseValue = 15,
        SeedCost = 8,
        TraitPool = { "Luminous", "Giant", "Potent", "Golden" },
        -- Processing: Fire oil sits inside the leaf — press it!
        Processing = {
            Primary = "Pressing",
            Alternative = { Method = "Grinding", Efficiency = 0.6 },
        },
        ExtractName = "Flame Oil",
        ExtractDesc = "Orange-red oil that flickers slightly — keep away from open flames!",
    },

    nebelranke = {
        Id = "nebelranke",
        Name = "Mistcreeper",
        Desc = "Loves growing in fog and sometimes just vanishes. Like my socks.",
        Rarity = "Common",
        GrowthTime = 90,
        BaseValue = 20,
        SeedCost = 12,
        TraitPool = { "FastGrowing", "SelfWatering", "Potent", "Immortal" },
        -- Processing: Volatile mist essence must be captured through distillation
        Processing = {
            Primary = "Distilling",
            Alternative = { Method = "Drying", Efficiency = 0.5 },
        },
        ExtractName = "Mist Essence",
        ExtractDesc = "A translucent drop that seems to hover inside its vial",
    },

    sternmoos = {
        Id = "sternmoos",
        Name = "Starmoss",
        Desc = "Sparkles at night like a tiny starry sky. Slugs love it — unfortunately.",
        Rarity = "Common",
        GrowthTime = 120,
        BaseValue = 25,
        SeedCost = 15,
        TraitPool = { "Luminous", "Giant", "FastGrowing", "Fragrant" },
        -- Processing: Spores in the moss must be released by grinding
        Processing = {
            Primary = "Grinding",
            Alternative = { Method = "Drying", Efficiency = 0.7 },
        },
        ExtractName = "Stardust Powder",
        ExtractDesc = "Glittering powder that sticks to everything. Every. Thing.",
    },

    schattenlilie = {
        Id = "schattenlilie",
        Name = "Shadowlily",
        Desc = "Only blooms in shadow and looks incredibly dramatic doing it. The goth plant.",
        Rarity = "Common",
        GrowthTime = 180,
        BaseValue = 30,
        SeedCost = 20,
        TraitPool = { "Fragrant", "Potent", "Golden", "Immortal" },
        -- Processing: Dark nectar sits in the petals — press them
        Processing = {
            Primary = "Pressing",
            Alternative = { Method = "Distilling", Efficiency = 0.8 },
        },
        ExtractName = "Shadow Nectar",
        ExtractDesc = "Ink-black syrup that seems to swallow the light around it",
    },

    -- ======== UNCOMMON (25%) ========

    kristallgras = {
        Id = "kristallgras",
        Name = "Crystalgrass",
        Desc = "Crunches underfoot like chips. Looks like frozen lawn but it's warm.",
        Rarity = "Uncommon",
        GrowthTime = 150,
        BaseValue = 45,
        SeedCost = 30,
        TraitPool = { "Luminous", "Giant", "Golden", "Potent" },
        Processing = {
            Primary = "Grinding",
            Alternative = nil,
        },
        ExtractName = "Crystal Shards",
        ExtractDesc = "Tiny crystals that glow in rainbow colors when hit by light",
    },

    sonnentau = {
        Id = "sonnentau",
        Name = "Sundew",
        Desc = "Stickier than honey, sweeter than compliments. Bugs find it irresistible.",
        Rarity = "Uncommon",
        GrowthTime = 200,
        BaseValue = 50,
        SeedCost = 35,
        TraitPool = { "SelfWatering", "Fragrant", "FastGrowing", "Potent" },
        Processing = {
            Primary = "Pressing",
            Alternative = { Method = "Drying", Efficiency = 0.6 },
        },
        ExtractName = "Goldew Syrup",
        ExtractDesc = "Viscous syrup that glows golden in the sunlight",
    },

    windblume = {
        Id = "windblume",
        Name = "Windbloom",
        Desc = "Sways even without wind. Always dancing. Has more moves than you.",
        Rarity = "Uncommon",
        GrowthTime = 160,
        BaseValue = 40,
        SeedCost = 28,
        TraitPool = { "FastGrowing", "Luminous", "Fragrant", "Immortal" },
        Processing = {
            Primary = "Distilling",
            Alternative = { Method = "Pressing", Efficiency = 0.65 },
        },
        ExtractName = "Wind Essence",
        ExtractDesc = "A bottle that constantly vibrates — a tiny storm rages inside",
    },

    -- ======== RARE (10%) ========

    irrlichtwurzel = {
        Id = "irrlichtwurzel",
        Name = "Willowroot",
        Desc = "Glows greenish and leads you in circles. GPS signal: not found.",
        Rarity = "Rare",
        GrowthTime = 240,
        BaseValue = 80,
        SeedCost = 60,
        TraitPool = { "Luminous", "Potent", "Giant", "Golden" },
        -- Processing: Ethereal substance only extractable through heat
        Processing = {
            Primary = "Distilling",
            Alternative = nil,
        },
        ExtractName = "Willowlight Distillate",
        ExtractDesc = "Greenish glowing liquid that guides your way in the dark... or maybe not",
    },

    donnerknospe = {
        Id = "donnerknospe",
        Name = "Thunderbud",
        Desc = "Pops like a mini thunderstorm when it blooms. Neighbors hate this one trick!",
        Rarity = "Rare",
        GrowthTime = 300,
        BaseValue = 100,
        SeedCost = 75,
        TraitPool = { "Giant", "Potent", "Luminous", "FastGrowing" },
        -- Processing: Crystalline structure must be shattered
        Processing = {
            Primary = "Grinding",
            Alternative = { Method = "Pressing", Efficiency = 0.6 },
        },
        ExtractName = "Lightning Powder",
        ExtractDesc = "Crackles and pops in the jar. Don't shake it. DO. NOT. SHAKE.",
    },

    frostbluete = {
        Id = "frostbluete",
        Name = "Frostbloom",
        Desc = "Ice cold and gorgeous. Like my ex. But more useful.",
        Rarity = "Rare",
        GrowthTime = 280,
        BaseValue = 90,
        SeedCost = 70,
        TraitPool = { "Immortal", "Potent", "Fragrant", "Golden" },
        -- Processing: Ice essence melts fast — press quickly!
        Processing = {
            Primary = "Pressing",
            Alternative = nil,
        },
        ExtractName = "Frost Essence",
        ExtractDesc = "Ice-blue oil that never freezes but chills everything around it",
    },

    -- ======== EPIC (4%) ========

    voidfarn = {
        Id = "voidfarn",
        Name = "Voidfern",
        Desc = "Looks like a hole in reality. Don't reach in. Seriously.",
        Rarity = "Epic",
        GrowthTime = 420,
        BaseValue = 200,
        SeedCost = 150,
        TraitPool = { "Potent", "Luminous", "Giant", "Immortal" },
        -- Processing: Void energy only extractable through magic
        Processing = {
            Primary = "AetherExtraction",
            Alternative = { Method = "Distilling", Efficiency = 0.4 },
        },
        ExtractName = "Void Extract",
        ExtractDesc = "A drop of absolute darkness. Devours light and curiosity alike",
    },

    phoenixkelch = {
        Id = "phoenixkelch",
        Name = "Phoenixcup",
        Desc = "Dies and regrows instantly. Has more comebacks than a 90s boyband star.",
        Rarity = "Epic",
        GrowthTime = 480,
        BaseValue = 250,
        SeedCost = 180,
        TraitPool = { "Immortal", "Potent", "Luminous", "Golden" },
        -- Processing: Phoenix tears evaporate on contact
        Processing = {
            Primary = "Distilling",
            Alternative = { Method = "AetherExtraction", Efficiency = 0.7 },
        },
        ExtractName = "Phoenix Tear",
        ExtractDesc = "A single golden drop. Feels as warm as a hug",
    },

    sturmranke = {
        Id = "sturmranke",
        Name = "Stormvine",
        Desc = "Whips around wildly and causes a ruckus. The punk of the plant world.",
        Rarity = "Epic",
        GrowthTime = 450,
        BaseValue = 220,
        SeedCost = 160,
        TraitPool = { "FastGrowing", "Giant", "Potent", "Fragrant" },
        -- Processing: Lightning juice sits in the vines
        Processing = {
            Primary = "Pressing",
            Alternative = { Method = "Grinding", Efficiency = 0.5 },
        },
        ExtractName = "Storm Juice",
        ExtractDesc = "Electrically charged juice. Tingles on your tongue. Everywhere.",
    },

    -- ======== LEGENDARY (0.9%) ========

    galaxienblume = {
        Id = "galaxienblume",
        Name = "Galaxybloom",
        Desc = "You can see tiny stars inside its petals. Nature's best screensaver.",
        Rarity = "Legendary",
        GrowthTime = 600,
        BaseValue = 500,
        SeedCost = 400,
        TraitPool = { "Luminous", "Potent", "Golden", "Immortal" },
        -- Processing: Starlight essence is not physical
        Processing = {
            Primary = "AetherExtraction",
            Alternative = nil,
        },
        ExtractName = "Stardust Essence",
        ExtractDesc = "Liquid starlight. Illuminates an entire room when you uncork the bottle",
    },

    zeitlotus = {
        Id = "zeitlotus",
        Name = "Timelotus",
        Desc = "Blooms simultaneously in the past and the future. Totally normal. Everything's fine.",
        Rarity = "Legendary",
        GrowthTime = 720,
        BaseValue = 600,
        SeedCost = 500,
        TraitPool = { "Potent", "Immortal", "Luminous", "Golden" },
        -- Processing: Time energy requires magical access
        Processing = {
            Primary = "AetherExtraction",
            Alternative = { Method = "Distilling", Efficiency = 0.3 },
        },
        ExtractName = "Timesand Tincture",
        ExtractDesc = "Flows backwards in the glass. Or forwards? Depends on when you look",
    },

    -- ======== MYTHIC (0.1%) ========

    weltbaumsetzling = {
        Id = "weltbaumsetzling",
        Name = "Worldtree Seedling",
        Desc = "A baby world tree! Will carry the universe one day. For now, it's a houseplant.",
        Rarity = "Mythic",
        GrowthTime = 900,
        BaseValue = 1000,
        SeedCost = 800,
        TraitPool = { "Giant", "Immortal", "Potent", "Golden", "Luminous" },
        -- Processing: Primal energy only extractable with the highest technique
        Processing = {
            Primary = "AetherExtraction",
            Alternative = nil,
        },
        ExtractName = "Worldmarrow",
        ExtractDesc = "Golden liquid that smells like everything and nothing at the same time",
    },

    ewige_essenz = {
        Id = "ewige_essenz",
        Name = "Eternal Essence",
        Desc = "Has existed since before the Big Bang. Best work-life balance of any plant.",
        Rarity = "Mythic",
        GrowthTime = 1200,
        BaseValue = 1500,
        SeedCost = 1200,
        TraitPool = { "Potent", "Immortal", "Luminous", "Golden", "Giant", "Fragrant" },
        -- Processing: Purest magical substance
        Processing = {
            Primary = "AetherExtraction",
            Alternative = nil,
        },
        ExtractName = "Eternity Drop",
        ExtractDesc = "A drop that never evaporates, never freezes, never ages. Just... eternal",
    },
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Returns plant data by ID
function PlantData.GetPlant(plantId)
    return PlantData.Plants[plantId]
end

-- Returns all plants of a specific rarity
function PlantData.GetPlantsByRarity(rarity)
    local result = {}
    for id, plant in pairs(PlantData.Plants) do
        if plant.Rarity == rarity then
            result[id] = plant
        end
    end
    return result
end

-- Returns a list of all plant IDs
function PlantData.GetAllPlantIds()
    local ids = {}
    for id in pairs(PlantData.Plants) do
        table.insert(ids, id)
    end
    return ids
end

-- Returns true if the plant can be processed with the given method
function PlantData.CanProcess(plantId, method)
    local plant = PlantData.Plants[plantId]
    if not plant then return false end

    if plant.Processing.Primary == method then
        return true, 1.0
    end

    if plant.Processing.Alternative and plant.Processing.Alternative.Method == method then
        return true, plant.Processing.Alternative.Efficiency
    end

    return false, 0
end

-- Returns the optimal processing method for a plant
function PlantData.GetPrimaryMethod(plantId)
    local plant = PlantData.Plants[plantId]
    if not plant then return nil end
    return plant.Processing.Primary
end

-- Pick a random trait from the plant's trait pool
function PlantData.GetRandomTrait(plantId)
    local plant = PlantData.Plants[plantId]
    if not plant or #plant.TraitPool == 0 then return nil end
    return plant.TraitPool[math.random(1, #plant.TraitPool)]
end

-- Calculate base quality (1-5 stars) with weighted random
function PlantData.RollQuality(qualityWeights)
    local weights = qualityWeights or { 40, 30, 20, 8, 2 }
    local total = 0
    for _, w in ipairs(weights) do
        total = total + w
    end

    local roll = math.random() * total
    local cumulative = 0
    for i, w in ipairs(weights) do
        cumulative = cumulative + w
        if roll <= cumulative then
            return i
        end
    end
    return 1
end

return PlantData
