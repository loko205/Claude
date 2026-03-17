--[[
    Config.lua — Zentrale Konfiguration für Bloom & Brew
    Alle Zahlen und Parameter an EINER Stelle.
    NIEMALS Magic Numbers in anderen Modulen verwenden!
]]

local Config = {}

-- ============================================================
-- GARTEN
-- ============================================================

Config.Garden = {
    MaxPlots = 6,
    StartPlots = 1,
    FieldsPerPlot = 9, -- 3x3

    PlotTypes = {
        Standard    = { SpeedMult = 1.0, MutationMult = 1.0, ValueMult = 1.0 },
        Gewaechshaus = { SpeedMult = 1.5, MutationMult = 1.0, ValueMult = 1.0 },
        Mutation    = { SpeedMult = 1.0, MutationMult = 1.5, ValueMult = 1.0 },
        Premium     = { SpeedMult = 1.0, MutationMult = 1.0, ValueMult = 1.3 },
    },

    SoilTypes = {
        Normal    = { GrowthMult = 1.0, MutationMult = 1.0, ValueMult = 1.0 },
        Naehrboden = { GrowthMult = 1.2, MutationMult = 1.0, ValueMult = 1.0 },
        Mystisch  = { GrowthMult = 1.0, MutationMult = 1.15, ValueMult = 1.0 },
        Golden    = { GrowthMult = 1.0, MutationMult = 1.0, ValueMult = 1.3 },
    },

    PlotUpgradeCosts = { 500, 1500, 5000, 15000, 50000 },

    -- Wachstums-Tick Intervall (Sekunden)
    TickInterval = 1,

    -- Gieß-Cooldown (Sekunden)
    WaterCooldown = 30,
    WaterSpeedMult = 1.5,

    -- Überreif ab Progress > 1.0, Qualität sinkt ab 1.2
    OverripeThreshold = 1.0,
    OverripeQualityLoss = 1.2,
}

-- ============================================================
-- PFLANZEN
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
        { Name = "Maessig",     Stars = 1, Mult = 1.0 },
        { Name = "Normal",      Stars = 2, Mult = 1.2 },
        { Name = "Gut",         Stars = 3, Mult = 1.5 },
        { Name = "Premium",     Stars = 4, Mult = 2.0 },
        { Name = "Meisterwerk", Stars = 5, Mult = 3.0 },
    },

    GrowthPhases = { "Samen", "Sproessling", "Wachstum", "Bluete", "Ernte", "Ueberreif" },

    -- Qualitäts-Wahrscheinlichkeiten (Base, ohne Modifikatoren)
    QualityWeights = { 40, 30, 20, 8, 2 }, -- ★1 bis ★5

    Traits = {
        Leuchtend       = { Mult = 1.2, Desc = "Glows softly" },
        Gigantisch      = { Mult = 1.0, YieldMult = 2.0, Desc = "Double extract yield" },
        Schnellwachsend = { SpeedMult = 1.5, Desc = "Grows 50% faster" },
        Selbstgiessend  = { AutoWater = true, Desc = "Never needs watering" },
        Potent          = { PurityBonus = 15, Desc = "+15% potion purity" },
        Goldig          = { ValueMult = 3.0, Desc = "3x sale value" },
        Unsterblich     = { NoOverripe = true, Desc = "Never goes overripe" },
        Duftend         = { Mult = 1.5, Desc = "Attracts better customers" },
    },

    TraitChance = 0.15, -- 15% Chance auf Trait bei Mutation
}

-- ============================================================
-- VERARBEITUNG (NEU — Extrakt-System)
-- ============================================================

Config.Processing = {
    Methods = {
        Trocknen = {
            MachineName = "Trockengestell",
            Cost = 50,
            LevelReq = 1,
            BaseDuration = 60,
            Desc = "Lufttrocknung — die einfachste Methode",
        },
        Moersern = {
            MachineName = "Steinmoerser",
            Cost = 200,
            LevelReq = 3,
            BaseDuration = 45,
            Desc = "Zerstoßen im Mörser — Pulver und Sporen freisetzen",
        },
        Pressen = {
            MachineName = "Pflanzenpresse",
            Cost = 500,
            LevelReq = 8,
            BaseDuration = 30,
            Desc = "Mechanisches Pressen — Säfte und Öle gewinnen",
        },
        Destillieren = {
            MachineName = "Destille",
            Cost = 1500,
            LevelReq = 15,
            BaseDuration = 90,
            Desc = "Dampfdestillation — reinste ätherische Extrakte",
        },
        AetherExtraktion = {
            MachineName = "Aether-Extraktor",
            Cost = 5000,
            LevelReq = 25,
            BaseDuration = 120,
            Desc = "Magische Extraktion — für die mächtigsten Wirkstoffe",
        },
    },

    -- Maschinen-Upgrade-Stufen
    UpgradeLevels = {
        { Name = "Einfach",    PotencyMult = 1.0, DurationMult = 1.0, YieldBonus = 0, CostMult = 1 },
        { Name = "Verbessert", PotencyMult = 1.15, DurationMult = 0.8, YieldBonus = 0, CostMult = 3 },
        { Name = "Meister",    PotencyMult = 1.30, DurationMult = 0.6, YieldBonus = 1, CostMult = 8 },
    },

    -- Wenn alternative Methode genutzt wird: Effizienz-Malus (definiert in PlantData)
    -- Wenn falsche Methode: Pflanze zerstört
    WrongMethodDestroysPlant = true,
}

-- ============================================================
-- BRAUEN
-- ============================================================

Config.Brewing = {
    UnlockLevel = 3,

    CauldronLevels = {
        { Name = "Holzkessel",     Slots = 2, PurityBonus = 0,  SpeedMult = 1.0, Cost = 0,     LevelReq = 3 },
        { Name = "Kupferkessel",   Slots = 3, PurityBonus = 5,  SpeedMult = 1.2, Cost = 2000,  LevelReq = 15 },
        { Name = "Silberkessel",   Slots = 3, PurityBonus = 10, SpeedMult = 1.4, Cost = 8000,  LevelReq = 25 },
        { Name = "Goldkessel",     Slots = 4, PurityBonus = 15, SpeedMult = 1.6, Cost = 25000, LevelReq = 40 },
        { Name = "Obsidiankessel", Slots = 4, PurityBonus = 20, SpeedMult = 2.0, Cost = 75000, LevelReq = 50 },
    },

    -- Reinheitsstufen
    PurityTiers = {
        { Name = "Verduennt",    Min = 0,  Max = 30,  EffectMult = 0.5, DurationMult = 0.5, ValueMult = 0.3 },
        { Name = "Unrein",       Min = 31, Max = 50,  EffectMult = 1.0, DurationMult = 1.0, ValueMult = 0.6 },
        { Name = "Standard",     Min = 51, Max = 70,  EffectMult = 1.0, DurationMult = 1.0, ValueMult = 1.0 },
        { Name = "Rein",         Min = 71, Max = 85,  EffectMult = 1.25, DurationMult = 1.25, ValueMult = 1.5 },
        { Name = "Kristallrein", Min = 86, Max = 95,  EffectMult = 1.25, DurationMult = 1.5, ValueMult = 2.5 },
        { Name = "Perfekt",      Min = 96, Max = 100, EffectMult = 1.5, DurationMult = 2.0, ValueMult = 5.0, Glow = true },
    },

    -- Reinheitsberechnung: Gewichtung der Faktoren
    PurityWeights = {
        ExtractPotency = 0.50, -- Größter Faktor: Qualität der Extrakte
        CauldronBonus  = 0.20, -- Kessel-Level
        MinigameScore  = 0.20, -- Timing/Skill
        PotentTrait    = 0.10, -- Potent-Trait der Zutat-Pflanzen
    },

    RandomPurityRange = 5, -- ±5% Zufallsfaktor
    MinigameMaxBonus = 20, -- Perfektes Minigame = +20% Reinheit

    -- Essenz pro gebrautem Trank
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

    -- Basis-Erfolgsraten nach Ziel-Rarität
    SuccessRates = {
        Rare      = { Min = 0.25, Max = 0.40 },
        Epic      = { Min = 0.20, Max = 0.25 },
        Legendary = { Min = 0.12, Max = 0.15 },
        Mythic    = { Min = 0.03, Max = 0.05 },
    },

    Catalysts = {
        Mondstein          = { RarityBoost = 0.10, Desc = "Erhöht Rarität des Ergebnisses" },
        Sonnenkristall     = { QualityBoost = 1,   Desc = "Garantiert min. ★★★ Qualität" },
        RegenbogenEssenz   = { MythicUnlock = true, Desc = "Ermöglicht Mythic-Mutationen" },
        Wurmkompost        = { MinQuality = 3,     Desc = "Ergebnis min. ★★★" },
        ExperimentellesSerum = { Random = true,     Desc = "Völlig zufälliges Ergebnis" },
    },
}

-- ============================================================
-- NPC-KUNDEN
-- ============================================================

Config.Customers = {
    MaxActiveOrders = 8,
    SpawnInterval = { Min = 120, Max = 300 }, -- 2-5 Minuten

    Types = {
        Dorfbewohner  = { MinRep = 0,     RewardMult = 1.0, Timer = 600 },
        Heiler        = { MinRep = 100,   RewardMult = 1.5, Timer = 480 },
        Adeliger      = { MinRep = 500,   RewardMult = 2.5, Timer = 720 },
        Hexenmeister  = { MinRep = 2000,  RewardMult = 3.0, Timer = 900 },
        DerSchatten   = { MinRep = 10000, RewardMult = 10.0, Timer = 300 },
    },
}

-- ============================================================
-- SPIELER-HANDEL
-- ============================================================

Config.Trade = {
    DirectTradeLevel = 5,
    MarketLevel = 8,
    AuctionLevel = 15,
    StandLevel = 10,

    TradeTax = 0.05,         -- 5% auf Coin-Anteil
    MarketTax = 0.05,        -- 5% auf Marktplatz-Verkäufe
    AuctionTax = 0.10,       -- 10% auf Auktions-Endpreis

    MaxMarketOffers = 10,
    MaxStandOffers = 3,      -- Basis, steigt mit Dealer-Rang
    MaxFavoriteSuppliers = 5,
    FavoriteDiscount = 0.10, -- 10% Rabatt bei Stammlieferant

    AntiScamCountdown = 10,  -- Sekunden nach Bestätigung
    RateLimit = 10,          -- Max Requests pro Sekunde

    AuctionDurations = { 3600, 21600, 86400 }, -- 1h, 6h, 24h in Sekunden

    -- Geheime Angebote ab dieser Rep sichtbar
    SecretOfferMinRep = 1000,

    DealerRanks = {
        { Name = "Lehrling",              MinRep = 0,    StandSlots = 3 },
        { Name = "Alchemist",             MinRep = 51,   StandSlots = 5 },
        { Name = "Meisterbrauer",         MinRep = 201,  StandSlots = 8 },
        { Name = "Legendaerer Alchemist", MinRep = 1001, StandSlots = 12 },
        { Name = "Grossmeister",          MinRep = 5001, StandSlots = 15 },
    },
}

-- ============================================================
-- GILDEN
-- ============================================================

Config.Guilds = {
    UnlockLevel = 12,
    MaxMembers = 20,
    GroupBrewPurityBonus = 10, -- +10% Reinheit beim Gruppen-Brauen
}

-- ============================================================
-- WIRTSCHAFT
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
        StreakBonus = 0.10, -- +10% pro Tag
        MaxStreak = 7,
    },

    -- XP-Vergabe
    XP = {
        Harvest = 10,
        Brew = 15,
        NPCOrder = 25,
        PlayerSale = 20,
        Mutation = 50,
        NewDiscovery = 100,
        Processing = 5,
    },

    -- Level-Formel: BaseXP * Level^Exponent
    LevelFormula = {
        BaseXP = 100,
        Exponent = 1.5,
    },

    -- Gamepasses
    Gamepasses = {
        VIPAlchemist   = { Robux = 499, CoinMult = 1.5 },
        AutoGiesser    = { Robux = 299 },
        DoppelteErnte  = { Robux = 399, YieldMult = 2.0 },
        ExtraPlots     = { Robux = 199, BonusPlots = 2 },
        Braumeister    = { Robux = 599, PurityBonus = 15 },
        ErweiterterStand = { Robux = 149, BonusSlots = 3 },
    },
}

-- ============================================================
-- TRANK-DUELL
-- ============================================================

Config.Duels = {
    UnlockLevel = 10,
    WinCoins = 50,
    WinRepBonus = 5,
}

-- ============================================================
-- TECHNISCH
-- ============================================================

Config.Technical = {
    AutoSaveInterval = 60,   -- Sekunden
    MaxRequestsPerSecond = 10,
    DataStoreKey = "BloomAndBrew_v1",
}

return Config
