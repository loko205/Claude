--[[
    Config.lua — Central configuration for Bloom & Brew
    All numbers and parameters in ONE place.
    NEVER use magic numbers in other modules!
]]

local Config = {}

-- ============================================================
-- GARDEN
-- ============================================================

Config.Garden = {
    MaxPlots = 6,
    StartPlots = 1,
    FieldsPerPlot = 9, -- 3x3

    PlotTypes = {
        Standard    = { SpeedMult = 1.0, MutationMult = 1.0, ValueMult = 1.0 },
        Greenhouse  = { SpeedMult = 1.5, MutationMult = 1.0, ValueMult = 1.0 },
        Mutation    = { SpeedMult = 1.0, MutationMult = 1.5, ValueMult = 1.0 },
        Premium     = { SpeedMult = 1.0, MutationMult = 1.0, ValueMult = 1.3 },
    },

    SoilTypes = {
        Normal    = { GrowthMult = 1.0, MutationMult = 1.0, ValueMult = 1.0 },
        Fertile   = { GrowthMult = 1.2, MutationMult = 1.0, ValueMult = 1.0 },
        Mystical  = { GrowthMult = 1.0, MutationMult = 1.15, ValueMult = 1.0 },
        Golden    = { GrowthMult = 1.0, MutationMult = 1.0, ValueMult = 1.3 },
    },

    PlotUpgradeCosts = { 500, 1500, 5000, 15000, 50000 },

    -- Growth tick interval (seconds)
    TickInterval = 1,

    -- Watering cooldown (seconds)
    WaterCooldown = 30,
    WaterSpeedMult = 1.5,

    -- Overripe at Progress > 1.0, quality degrades at 1.2
    OverripeThreshold = 1.0,
    OverripeQualityLoss = 1.2,
}

-- ============================================================
-- PLANTS
-- ============================================================

Config.Plants = {
    Rarities = {
        Common    = { Weight = 60, Color = "White" },
        Uncommon  = { Weight = 25, Color = "Green" },
        Rare      = { Weight = 10, Color = "Blue" },
        Epic      = { Weight = 4,  Color = "Purple" },
        Legendary = { Weight = 0.9, Color = "Orange" },
        Mythic    = { Weight = 0.1, Color = "Red" },
    },

    QualityStars = {
        { Name = "Mediocre",   Stars = 1, Mult = 1.0 },
        { Name = "Normal",     Stars = 2, Mult = 1.2 },
        { Name = "Good",       Stars = 3, Mult = 1.5 },
        { Name = "Premium",    Stars = 4, Mult = 2.0 },
        { Name = "Masterwork", Stars = 5, Mult = 3.0 },
    },

    GrowthPhases = { "Seed", "Sprout", "Growing", "Bloom", "Harvest", "Overripe" },

    -- Quality probability weights (base, no modifiers)
    QualityWeights = { 40, 30, 20, 8, 2 }, -- 1-star to 5-star

    Traits = {
        Luminous     = { Mult = 1.2, Desc = "Glows softly" },
        Giant        = { Mult = 1.0, YieldMult = 2.0, Desc = "Double extract yield" },
        FastGrowing  = { SpeedMult = 1.5, Desc = "Grows 50% faster" },
        SelfWatering = { AutoWater = true, Desc = "Never needs watering" },
        Potent       = { PurityBonus = 15, Desc = "+15% potion purity" },
        Golden       = { ValueMult = 3.0, Desc = "3x sale value" },
        Immortal     = { NoOverripe = true, Desc = "Never goes overripe" },
        Fragrant     = { Mult = 1.5, Desc = "Attracts better customers" },
    },

    TraitChance = 0.15, -- 15% chance for trait on mutation
}

-- ============================================================
-- PROCESSING (Extract System)
-- ============================================================

Config.Processing = {
    Methods = {
        Drying = {
            MachineName = "Drying Rack",
            Cost = 50,
            LevelReq = 1,
            BaseDuration = 60,
            Desc = "Air drying — the simplest method",
        },
        Grinding = {
            MachineName = "Stone Mortar",
            Cost = 200,
            LevelReq = 3,
            BaseDuration = 45,
            Desc = "Crushing in a mortar — releases powders and spores",
        },
        Pressing = {
            MachineName = "Plant Press",
            Cost = 500,
            LevelReq = 8,
            BaseDuration = 30,
            Desc = "Mechanical pressing — extracts juices and oils",
        },
        Distilling = {
            MachineName = "Distillery",
            Cost = 1500,
            LevelReq = 15,
            BaseDuration = 90,
            Desc = "Steam distillation — purest essential extracts",
        },
        AetherExtraction = {
            MachineName = "Aether Extractor",
            Cost = 5000,
            LevelReq = 25,
            BaseDuration = 120,
            Desc = "Magical extraction — for the most powerful compounds",
        },
    },

    -- Machine upgrade tiers
    UpgradeLevels = {
        { Name = "Basic",    PotencyMult = 1.0, DurationMult = 1.0, YieldBonus = 0, CostMult = 1 },
        { Name = "Improved", PotencyMult = 1.15, DurationMult = 0.8, YieldBonus = 0, CostMult = 3 },
        { Name = "Master",   PotencyMult = 1.30, DurationMult = 0.6, YieldBonus = 1, CostMult = 8 },
    },

    -- Alternative method: efficiency penalty (defined in PlantData)
    -- Wrong method: plant destroyed
    WrongMethodDestroysPlant = true,
}

-- ============================================================
-- BREWING
-- ============================================================

Config.Brewing = {
    UnlockLevel = 3,

    CauldronLevels = {
        { Name = "Wooden Cauldron",   Slots = 2, PurityBonus = 0,  SpeedMult = 1.0, Cost = 0,     LevelReq = 3 },
        { Name = "Copper Cauldron",   Slots = 3, PurityBonus = 5,  SpeedMult = 1.2, Cost = 2000,  LevelReq = 15 },
        { Name = "Silver Cauldron",   Slots = 3, PurityBonus = 10, SpeedMult = 1.4, Cost = 8000,  LevelReq = 25 },
        { Name = "Gold Cauldron",     Slots = 4, PurityBonus = 15, SpeedMult = 1.6, Cost = 25000, LevelReq = 40 },
        { Name = "Obsidian Cauldron", Slots = 4, PurityBonus = 20, SpeedMult = 2.0, Cost = 75000, LevelReq = 50 },
    },

    -- Purity tiers
    PurityTiers = {
        { Name = "Diluted",      Min = 0,  Max = 30,  EffectMult = 0.5, DurationMult = 0.5, ValueMult = 0.3 },
        { Name = "Impure",       Min = 31, Max = 50,  EffectMult = 1.0, DurationMult = 1.0, ValueMult = 0.6 },
        { Name = "Standard",     Min = 51, Max = 70,  EffectMult = 1.0, DurationMult = 1.0, ValueMult = 1.0 },
        { Name = "Pure",         Min = 71, Max = 85,  EffectMult = 1.25, DurationMult = 1.25, ValueMult = 1.5 },
        { Name = "Crystal Pure", Min = 86, Max = 95,  EffectMult = 1.25, DurationMult = 1.5, ValueMult = 2.5 },
        { Name = "Perfect",      Min = 96, Max = 100, EffectMult = 1.5, DurationMult = 2.0, ValueMult = 5.0, Glow = true },
    },

    -- Purity calculation: factor weights
    PurityWeights = {
        ExtractPotency = 0.50, -- Biggest factor: extract quality
        CauldronBonus  = 0.20, -- Cauldron level
        MinigameScore  = 0.20, -- Timing/Skill
        PotentTrait    = 0.10, -- Potent trait of ingredient plants
    },

    RandomPurityRange = 5, -- +/-5% random factor
    MinigameMaxBonus = 20, -- Perfect minigame = +20% purity

    -- Essence per brewed potion
    EssencePerBrew = {
        Common = 1,
        Uncommon = 2,
        Rare = 5,
        Epic = 10,
        Legendary = 25,
    },
}

-- ============================================================
-- MUTATION
-- ============================================================

Config.Mutation = {
    UnlockLevel = 5,

    -- Base success rates by target rarity
    SuccessRates = {
        Rare      = { Min = 0.25, Max = 0.40 },
        Epic      = { Min = 0.20, Max = 0.25 },
        Legendary = { Min = 0.12, Max = 0.15 },
        Mythic    = { Min = 0.03, Max = 0.05 },
    },

    Catalysts = {
        Moonstone          = { RarityBoost = 0.10, Desc = "Increases result rarity" },
        Suncrystal         = { QualityBoost = 1,   Desc = "Guarantees min. 3-star quality" },
        RainbowEssence     = { MythicUnlock = true, Desc = "Enables Mythic mutations" },
        WormCompost        = { MinQuality = 3,     Desc = "Result min. 3-star" },
        ExperimentalSerum  = { Random = true,      Desc = "Completely random result" },
    },
}

-- ============================================================
-- NPC CUSTOMERS
-- ============================================================

Config.Customers = {
    MaxActiveOrders = 8,
    SpawnInterval = { Min = 120, Max = 300 }, -- 2-5 minutes

    Types = {
        Villager   = { MinRep = 0,     RewardMult = 1.0, Timer = 600 },
        Healer     = { MinRep = 100,   RewardMult = 1.5, Timer = 480 },
        Noble      = { MinRep = 500,   RewardMult = 2.5, Timer = 720 },
        Warlock    = { MinRep = 2000,  RewardMult = 3.0, Timer = 900 },
        TheShadow  = { MinRep = 10000, RewardMult = 10.0, Timer = 300 },
    },
}

-- ============================================================
-- PLAYER TRADING
-- ============================================================

Config.Trade = {
    DirectTradeLevel = 5,
    MarketLevel = 8,
    AuctionLevel = 15,
    StandLevel = 10,

    TradeTax = 0.05,         -- 5% on coin portion
    MarketTax = 0.05,        -- 5% on market sales
    AuctionTax = 0.10,       -- 10% on auction final price

    MaxMarketOffers = 10,
    MaxStandOffers = 3,      -- Base, increases with dealer rank
    MaxFavoriteSuppliers = 5,
    FavoriteDiscount = 0.10, -- 10% discount for regular customers

    AntiScamCountdown = 10,  -- Seconds after confirmation
    RateLimit = 10,          -- Max requests per second

    AuctionDurations = { 3600, 21600, 86400 }, -- 1h, 6h, 24h in seconds

    -- Secret offers visible above this rep
    SecretOfferMinRep = 1000,

    DealerRanks = {
        { Name = "Apprentice",         MinRep = 0,    StandSlots = 3 },
        { Name = "Alchemist",          MinRep = 51,   StandSlots = 5 },
        { Name = "Master Brewer",      MinRep = 201,  StandSlots = 8 },
        { Name = "Legendary Alchemist", MinRep = 1001, StandSlots = 12 },
        { Name = "Grandmaster",        MinRep = 5001, StandSlots = 15 },
    },
}

-- ============================================================
-- GUILDS
-- ============================================================

Config.Guilds = {
    UnlockLevel = 12,
    MaxMembers = 20,
    GroupBrewPurityBonus = 10, -- +10% purity for group brewing
}

-- ============================================================
-- ECONOMY
-- ============================================================

Config.Economy = {
    StartCoins = 100,
    StartGems = 10,
    StartSeeds = {
        { PlantId = "mondkraut", Amount = 5 },
        { PlantId = "flammenblatt", Amount = 3 },
    },

    DailyLogin = {
        Coins = 50,
        Gems = 2,
        StreakBonus = 0.10, -- +10% per day
        MaxStreak = 7,
    },

    -- XP rewards
    XP = {
        Harvest = 10,
        Brew = 15,
        NPCOrder = 25,
        PlayerSale = 20,
        Mutation = 50,
        NewDiscovery = 100,
        Processing = 5,
    },

    -- Level formula: BaseXP * Level^Exponent
    LevelFormula = {
        BaseXP = 100,
        Exponent = 1.5,
    },

    -- Gamepasses
    Gamepasses = {
        VIPAlchemist    = { Robux = 499, CoinMult = 1.5 },
        AutoWaterer     = { Robux = 299 },
        DoubleHarvest   = { Robux = 399, YieldMult = 2.0 },
        ExtraPlots      = { Robux = 199, BonusPlots = 2 },
        BrewMaster      = { Robux = 599, PurityBonus = 15 },
        ExpandedStand   = { Robux = 149, BonusSlots = 3 },
    },
}

-- ============================================================
-- POTION DUELS
-- ============================================================

Config.Duels = {
    UnlockLevel = 10,
    WinCoins = 50,
    WinRepBonus = 5,
}

-- ============================================================
-- TECHNICAL
-- ============================================================

Config.Technical = {
    AutoSaveInterval = 60,   -- Seconds
    MaxRequestsPerSecond = 10,
    DataStoreKey = "BloomAndBrew_v1",
}

return Config
