--[[
    Balancing.lua — Documentation of all balancing target values
    Not intended as a runtime module, but as a design reference.
    All actual values are in Config.lua!
]]

local Balancing = {}

-- ============================================================
-- INCOME PER HOUR (Target Values)
-- ============================================================

Balancing.IncomePerHour = {
    -- Level 1-5: Onboarding, learning core mechanics
    -- Main income: Selling plants + first NPC orders
    -- Target: ~100-200 Coins/hour
    Early = {
        PlantSales = 80,      -- 8 harvests x 10 Coins avg
        NPCOrders = 75,       -- 3 orders x 25 Coins avg
        DailyLogin = 50,      -- If logging in once per day
        Total = "~200 Coins/h",
        Note = "Enough for 1-2 seed purchases per hour",
    },

    -- Level 5-15: Brew Lab + first potions + mutation
    -- Target: ~500-1000 Coins/hour
    Mid = {
        PlantSales = 150,
        PotionSales = 300,    -- Starter potions to NPCs
        NPCOrders = 200,      -- Healer orders
        PlayerTrade = 100,    -- First player sales
        Total = "~750 Coins/h",
        Note = "Machines pay for themselves in 1-3h of playtime",
    },

    -- Level 15-30: Advanced potions + Auction House
    -- Target: ~2000-5000 Coins/hour
    Late = {
        PotionSales = 1500,   -- Advanced/Rare potions
        NPCOrders = 800,      -- Noble/Warlock orders
        PlayerTrade = 500,    -- Active trading
        AuctionIncome = 200,
        Total = "~3000 Coins/h",
        Note = "Cauldron upgrades and rare seeds become accessible",
    },

    -- Level 30+: Endgame
    -- Target: ~10000+ Coins/hour
    Endgame = {
        PotionSales = 5000,   -- Legendary potions with high purity
        PlayerTrade = 3000,   -- Potion stand empire
        NPCOrders = 2000,     -- The Shadow!
        Total = "~10000+ Coins/h",
        Note = "Grandmaster rank, guild activities",
    },
}

-- ============================================================
-- EXPENSES / COIN SINKS
-- ============================================================

Balancing.CoinSinks = {
    -- Target: ~60-70% of income is spent again
    -- This keeps the economy stable

    SeedCosts = "Recurring, 5-20 Coins per seed (Common)",
    PlotUpgrades = "500 → 1500 → 5000 → 15000 → 50000 (major investments)",
    Machines = "50-5000 Coins (tiered by level requirement)",
    MachineUpgrades = "3x and 8x base cost (Improved/Master)",
    CauldronUpgrades = "2000 → 8000 → 25000 → 75000",
    SoilUpgrades = "500 → 1500 → 3000",
    TradeTax = "5-10% on all player transactions",
    Catalysts = "100-2000 Coins",

    -- Amortization times (target)
    Amortization = {
        DryingRack = "1-2 processing cycles (50 Coins → quick return)",
        StoneMortar = "~5 processing cycles (200 Coins)",
        PlantPress = "~8 processing cycles (500 Coins)",
        Distillery = "~15 processing cycles (1500 Coins)",
        AetherExtractor = "~10 processing cycles (5000 Coins, but endgame potions are expensive)",
        CopperCauldron = "~10-15 brewing cycles",
        SilverCauldron = "~15-20 brewing cycles",
    },
}

-- ============================================================
-- PURITY DISTRIBUTION
-- ============================================================

Balancing.PurityDistribution = {
    -- Target distribution at Level 10 with base setup:
    -- Diluted (0-30%):      ~5%  of potions (only with bad plants + no minigame)
    -- Impure (31-50%):      ~15% of potions
    -- Standard (51-70%):    ~40% of potions (most common range)
    -- Pure (71-85%):        ~25% of potions (with good minigame)
    -- Crystal Clear (86-95%): ~12% of potions (4-star+ plants + minigame + Potent)
    -- Perfect (96-100%):    ~3%  of potions (5-star + Master Cauldron + perfect minigame)

    Note = "Perfect potions should be RARE and VALUABLE. The 5x value multiplier motivates investing in better machines and minigame skill.",

    -- Purity formula: (avgPotency * 60) + cauldronBonus + minigameBonus + potentBonus +/- 5
    -- Max theoretical: 60 + 20 + 20 + 15 + 5 = 120 (capped at 100)
    -- Realistic with 3-star + base cauldron + 50/100 minigame: ~55%
    -- With 5-star + Obsidian + perfect minigame + Potent: ~95-100%
}

-- ============================================================
-- PROCESSING SYSTEM BALANCE
-- ============================================================

Balancing.Processing = {
    -- Core idea: Processing adds depth without being annoying
    -- Level 1-3: Only Drying needed (Moonherb = the first plant, only needs Drying)
    -- This way the player learns the system with the simplest method

    DesignPrinciples = {
        "Starter plants ALWAYS require the simplest available method",
        "Rarer plants require more advanced methods → natural progression",
        "Alternative methods are a fallback, not the standard",
        "Wrong method = plant destroyed → motivates reading the plant description",
        "Machine upgrades are NOTICEABLE but not MANDATORY",
    },

    Progression = {
        "Level 1: Buy Drying Rack (50 Coins = cheap), dry Moonherb",
        "Level 3: Stone Mortar (200), grind Starmoss → first 2-star potions possible",
        "Level 8: Plant Press (500), press Flameleaf/Frostbloom → better extracts",
        "Level 15: Distillery (1500), distill Mistvine/Willowisproot → rare potions",
        "Level 25: Aether Extractor (5000), Voidfern/Galaxyflower → endgame potions",
    },
}

-- ============================================================
-- XP CURVE
-- ============================================================

Balancing.XPCurve = {
    -- Formula: BaseXP(100) x Level^1.5
    -- Level 1→2:   100 XP  (~10 harvests)
    -- Level 5→6:   1118 XP (~45 harvests or ~45 brewing cycles)
    -- Level 10→11: 3162 XP
    -- Level 20→21: 8944 XP
    -- Level 50→51: 35355 XP
    -- Level 100:   ~100000 XP

    Note = "Level 10 should be reachable after ~3-5h of playtime. Level 25 after ~20h. Level 50 after ~100h. Level 100 is a long-term goal (300h+).",

    XPSources = {
        "Harvesting (+10): Most frequent, lowest value",
        "Processing (+5): Bonus for the new mechanic",
        "Brewing (+15): Rewards the core feature",
        "NPC Orders (+25): Rewards complete chains",
        "Player Sales (+20): Rewards social interaction",
        "Mutation (+50): Rarer, higher value",
        "New Discovery (+100): Big bonus, motivates exploration",
    },
}

-- ============================================================
-- MONETIZATION
-- ============================================================

Balancing.Monetization = {
    -- Goal: Fair. No P2W. Premium = time savings.
    -- All items are earnable. Gamepasses accelerate by 40-60%.

    VIPAlchemist = "+50% Coins. At 3000 Coins/h endgame = +1500 Coins/h. Significant but not gamebreaking.",
    AutoWaterer = "Saves ~30s per plant per watering cycle. Quality-of-Life.",
    DoubleHarvest = "2x yield = 2x extracts = 2x potions. Strongest gamepass for farmers.",
    ExtraPlots = "+2 Plots = +18 fields. More growing space = more income.",
    BrewMaster = "+15% base purity bonus. Shifts the purity curve upward. Not a must-buy!",
    ExpandedStand = "+3 stand slots. More selling opportunities for active traders.",

    FairnessCheck = {
        "WITHOUT gamepass: Perfect potions are possible (5-star + Obsidian + Minigame + Potent)",
        "WITH gamepass: Perfect potions are EASIER (BrewMaster gives +15% buffer)",
        "No exclusive items behind paywall",
        "No lootboxes, no gacha mechanics",
    },
}

return Balancing
