--[[
    ProcessingData.lua — Processing system for Bloom & Brew
    5 methods to process plants into extracts:
    Drying → Grinding → Pressing → Distilling → Aether Extraction

    Each plant needs the right method for optimal yield.
    Wrong method = plant destroyed!
]]

local Config = require(script.Parent.Config)

local ProcessingData = {}

-- ============================================================
-- PROCESSING METHODS
-- ============================================================

ProcessingData.Methods = {
    Drying = {
        Id = "Drying",
        Name = "Drying",
        MachineName = "Drying Rack",
        Desc = "Hang the plant upside down and let the air do its thing. Like laundry, but more magical.",
        LongDesc = "The oldest and simplest method of extracting active ingredients. The plant is hung in a well-ventilated area until the moisture has evaporated and the compounds remain concentrated. Perfect for leaves and herbs.",
        Icon = "rbxassetid://0", -- Placeholder
        Cost = Config.Processing.Methods.Drying.Cost,
        LevelReq = Config.Processing.Methods.Drying.LevelReq,
        BaseDuration = Config.Processing.Methods.Drying.BaseDuration,
        Category = "Basic",
        OutputType = "Dried Leaves/Herbs",
    },

    Grinding = {
        Id = "Grinding",
        Name = "Grinding",
        MachineName = "Stone Mortar",
        Desc = "Crush the plant into fine powder. Free arm workout included!",
        LongDesc = "The heavy stone mortar grinds and crushes plant parts. This releases spores, breaks crystalline structures, and unlocks hidden active ingredients. Ideal for hard, solid plant parts.",
        Icon = "rbxassetid://0",
        Cost = Config.Processing.Methods.Grinding.Cost,
        LevelReq = Config.Processing.Methods.Grinding.LevelReq,
        BaseDuration = Config.Processing.Methods.Grinding.BaseDuration,
        Category = "Basic",
        OutputType = "Powder/Spores",
    },

    Pressing = {
        Id = "Pressing",
        Name = "Pressing",
        MachineName = "Plant Press",
        Desc = "Squeeze every last drop of juice out. The plant will survive — well, actually no.",
        LongDesc = "The mechanical press extracts juices, oils, and nectars from succulent plant parts. Controlled pressure yields liquid compounds without destroying them through heat. Perfect for blossoms and fleshy plants.",
        Icon = "rbxassetid://0",
        Cost = Config.Processing.Methods.Pressing.Cost,
        LevelReq = Config.Processing.Methods.Pressing.LevelReq,
        BaseDuration = Config.Processing.Methods.Pressing.BaseDuration,
        Category = "Advanced",
        OutputType = "Oil/Juice/Nectar",
    },

    Distilling = {
        Id = "Distilling",
        Name = "Distilling",
        MachineName = "Distillery",
        Desc = "Steam in, magic out. Like cooking, but with more science and less food.",
        LongDesc = "By heating and carefully capturing the vapor, volatile essential substances are extracted. The distillery separates compounds precisely by boiling point — the purest method for delicate, gaseous, or heat-soluble substances.",
        Icon = "rbxassetid://0",
        Cost = Config.Processing.Methods.Distilling.Cost,
        LevelReq = Config.Processing.Methods.Distilling.LevelReq,
        BaseDuration = Config.Processing.Methods.Distilling.BaseDuration,
        Category = "Advanced",
        OutputType = "Distillate/Essential Oil",
    },

    AetherExtraction = {
        Id = "AetherExtraction",
        Name = "Aether Extraction",
        MachineName = "Aether Extractor",
        Desc = "Pulls the magical essence straight out of the plant. Looks SO cool.",
        LongDesc = "The Aether Extractor uses concentrated magical energy to dissolve non-physical compounds from plants. Only this method can extract void energy, starlight, or time essence. The most expensive, but also the most powerful method.",
        Icon = "rbxassetid://0",
        Cost = Config.Processing.Methods.AetherExtraction.Cost,
        LevelReq = Config.Processing.Methods.AetherExtraction.LevelReq,
        BaseDuration = Config.Processing.Methods.AetherExtraction.BaseDuration,
        Category = "Master",
        OutputType = "Magical Essence",
    },
}

-- Method order (for UI sorting)
ProcessingData.MethodOrder = { "Drying", "Grinding", "Pressing", "Distilling", "AetherExtraction" }

-- ============================================================
-- MACHINE UPGRADES
-- ============================================================

ProcessingData.Upgrades = {}
for i, level in ipairs(Config.Processing.UpgradeLevels) do
    ProcessingData.Upgrades[i] = {
        Level = i,
        Name = level.Name,
        PotencyMult = level.PotencyMult,
        DurationMult = level.DurationMult,
        YieldBonus = level.YieldBonus,
        CostMult = level.CostMult,
    }
end

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Get processing method data by ID
function ProcessingData.GetMethod(methodId)
    return ProcessingData.Methods[methodId]
end

-- Calculate processing duration with machine upgrades
function ProcessingData.GetDuration(methodId, machineLevel)
    local method = ProcessingData.Methods[methodId]
    if not method then return 0 end

    local upgrade = Config.Processing.UpgradeLevels[machineLevel or 1]
    return method.BaseDuration * (upgrade and upgrade.DurationMult or 1.0)
end

-- Calculate extract potency from plant quality and processing method
-- plantQuality: 1-5 (stars)
-- methodEfficiency: 0.0-1.0 (1.0 = primary method, <1.0 = alternative)
-- machineLevel: 1-3
function ProcessingData.CalculatePotency(plantQuality, methodEfficiency, machineLevel)
    local qualityMult = ({ 1.0, 1.2, 1.5, 2.0, 3.0 })[plantQuality] or 1.0
    local upgrade = Config.Processing.UpgradeLevels[machineLevel or 1]
    local machineMult = upgrade and upgrade.PotencyMult or 1.0

    -- Potency = plant quality x method efficiency x machine bonus
    local potency = qualityMult * methodEfficiency * machineMult

    -- Clamp 0-1 (normalized to max = 5-star + primary + master machine)
    local maxPotency = 3.0 * 1.0 * 1.3 -- 5-star x 100% x Master
    return math.min(potency / maxPotency, 1.0)
end

-- Calculate extract yield (how many extract units from one plant)
function ProcessingData.GetYield(plantData, machineLevel, hasTrait)
    local baseYield = 1
    local upgrade = Config.Processing.UpgradeLevels[machineLevel or 1]
    local bonusYield = upgrade and upgrade.YieldBonus or 0

    -- Trait "Gigantic" = 2x yield
    if hasTrait then
        baseYield = baseYield * 2
    end

    return baseYield + bonusYield
end

-- Get the upgrade cost for a specific machine method and target level
function ProcessingData.GetUpgradeCost(methodId, targetLevel)
    local method = ProcessingData.Methods[methodId]
    if not method then return 0 end

    local upgrade = Config.Processing.UpgradeLevels[targetLevel]
    if not upgrade then return 0 end

    return method.Cost * upgrade.CostMult
end

-- Check if player can use a specific processing method (level check)
function ProcessingData.CanPlayerUse(methodId, playerLevel)
    local method = ProcessingData.Methods[methodId]
    if not method then return false end
    return playerLevel >= method.LevelReq
end

-- Get all methods available at a given player level
function ProcessingData.GetAvailableMethods(playerLevel)
    local available = {}
    for _, methodId in ipairs(ProcessingData.MethodOrder) do
        if ProcessingData.CanPlayerUse(methodId, playerLevel) then
            table.insert(available, methodId)
        end
    end
    return available
end

return ProcessingData
