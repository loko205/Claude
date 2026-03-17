--[[
    PlantManager.lua — Plants, Growth, Watering, Harvesting
    Server tick every 1s for growth progress.
    All actions server-side validated.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local PlantData = require(ReplicatedStorage.Shared.PlantData)
local DataManager = require(script.Parent.DataManager)

local PlantManager = {}

-- RemoteEvents (created at runtime)
local remotes = {}

-- ============================================================
-- INITIALIZATION
-- ============================================================

local function createRemotes()
    local folder = Instance.new("Folder")
    folder.Name = "PlantRemotes"
    folder.Parent = ReplicatedStorage

    local events = { "PlantSeed", "WaterPlant", "FertilizePlant", "PrunePlant", "HarvestPlant", "UpgradePlot" }
    for _, name in ipairs(events) do
        local remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = folder
        remotes[name] = remote
    end
end

-- ============================================================
-- GROWTH TICK
-- ============================================================

local function growthTick()
    for _, player in ipairs(Players:GetPlayers()) do
        local data = DataManager.GetData(player)
        if not data then continue end

        for plotIndex, plot in pairs(data.Plots) do
            local plotConfig = Config.Garden.PlotTypes[plot.Type] or Config.Garden.PlotTypes.Standard
            local soilConfig = Config.Garden.SoilTypes[plot.SoilType] or Config.Garden.SoilTypes.Normal

            for fieldIndex, field in pairs(plot.Fields) do
                if not field or not field.PlantId then continue end

                local plantInfo = PlantData.GetPlant(field.PlantId)
                if not plantInfo then continue end

                -- Calculate growth speed
                local speedMult = 1.0
                speedMult = speedMult * plotConfig.SpeedMult
                speedMult = speedMult * soilConfig.GrowthMult

                -- Watered bonus
                if field.Watered and (os.time() - (field.LastWatered or 0)) < Config.Garden.WaterCooldown then
                    speedMult = speedMult * Config.Garden.WaterSpeedMult
                end

                -- Trait: FastGrowing
                if field.Traits and table.find(field.Traits, "FastGrowing") then
                    speedMult = speedMult * Config.Plants.Traits.FastGrowing.SpeedMult
                end

                -- Trait: SelfWatering (auto-water)
                if field.Traits and table.find(field.Traits, "SelfWatering") then
                    speedMult = speedMult * Config.Garden.WaterSpeedMult
                end

                -- Progress increment per tick
                local growthPerTick = (1.0 / plantInfo.GrowthTime) * speedMult * Config.Garden.TickInterval
                field.GrowthProgress = (field.GrowthProgress or 0) + growthPerTick

                -- Overripe quality loss
                if field.GrowthProgress > Config.Garden.OverripeQualityLoss then
                    -- Trait: Immortal prevents overripe
                    if not (field.Traits and table.find(field.Traits, "Immortal")) then
                        -- Degrade quality over time
                        local overripeAmount = field.GrowthProgress - Config.Garden.OverripeQualityLoss
                        field.QualityLoss = math.min(overripeAmount * 0.5, 0.8) -- Max 80% quality loss
                    end
                end
            end
        end
    end
end

-- ============================================================
-- GROWTH PHASE HELPER
-- ============================================================

function PlantManager.GetGrowthPhase(progress)
    if progress < 0.2 then return "Seed"
    elseif progress < 0.4 then return "Sprout"
    elseif progress < 0.6 then return "Growing"
    elseif progress < 0.8 then return "Bloom"
    elseif progress <= 1.0 then return "Harvest"
    else return "Overripe"
    end
end

-- ============================================================
-- ACTIONS (all server-validated)
-- ============================================================

-- Plant a seed
function PlantManager.PlantSeed(player, plotIndex, fieldIndex, plantId)
    local data = DataManager.GetData(player)
    if not data then return false, "No data" end

    -- Validate plot exists
    local plot = data.Plots[plotIndex]
    if not plot then return false, "Plot does not exist" end

    -- Validate field is empty
    if plot.Fields[fieldIndex] then return false, "Field is occupied" end

    -- Validate field index
    if fieldIndex < 1 or fieldIndex > Config.Garden.FieldsPerPlot then
        return false, "Invalid field"
    end

    -- Validate seed exists in inventory
    local seeds = data.Inventory.Seeds[plantId]
    if not seeds or seeds <= 0 then return false, "No seeds" end

    -- Validate plant exists
    local plantInfo = PlantData.GetPlant(plantId)
    if not plantInfo then return false, "Unknown plant" end

    -- Plant!
    data.Inventory.Seeds[plantId] = seeds - 1
    if data.Inventory.Seeds[plantId] <= 0 then
        data.Inventory.Seeds[plantId] = nil
    end

    plot.Fields[fieldIndex] = {
        PlantId = plantId,
        GrowthProgress = 0,
        Quality = PlantData.RollQuality(),
        Traits = {},
        Watered = false,
        LastWatered = 0,
        PlantedAt = os.time(),
        QualityLoss = 0,
    }

    return true, "Planted!"
end

-- Water a plant
function PlantManager.WaterPlant(player, plotIndex, fieldIndex)
    local data = DataManager.GetData(player)
    if not data then return false, "No data" end

    local plot = data.Plots[plotIndex]
    if not plot then return false, "Plot does not exist" end

    local field = plot.Fields[fieldIndex]
    if not field then return false, "No plant here" end

    -- Cooldown check
    local now = os.time()
    if (now - (field.LastWatered or 0)) < Config.Garden.WaterCooldown then
        return false, "Still wet!"
    end

    field.Watered = true
    field.LastWatered = now

    return true, "Watered!"
end

-- Water help from another player (garden visit)
function PlantManager.WaterHelpFromVisitor(visitor, owner, plotIndex, fieldIndex)
    local success, msg = PlantManager.WaterPlant(owner, plotIndex, fieldIndex)
    if success then
        -- Both get XP bonus
        DataManager.AddXP(visitor, 5)
        DataManager.AddXP(owner, 5)
    end
    return success, msg
end

-- Fertilize a plant (+Quality)
function PlantManager.FertilizePlant(player, plotIndex, fieldIndex)
    local data = DataManager.GetData(player)
    if not data then return false end

    local plot = data.Plots[plotIndex]
    if not plot then return false end

    local field = plot.Fields[fieldIndex]
    if not field then return false end

    -- Increase quality by 1 star (max 5)
    if field.Quality < 5 then
        field.Quality = field.Quality + 1
        -- Cost: 50 Coins per fertilize
        if not DataManager.RemoveCoins(player, 50) then
            field.Quality = field.Quality - 1 -- Rollback
            return false, "Not enough Coins"
        end
        return true, "Fertilized! Quality: " .. field.Quality .. " stars"
    end

    return false, "Already at max quality"
end

-- Prune a plant (+Mutation chance, for later use in MutationEngine)
function PlantManager.PrunePlant(player, plotIndex, fieldIndex)
    local data = DataManager.GetData(player)
    if not data then return false end

    local plot = data.Plots[plotIndex]
    if not plot then return false end

    local field = plot.Fields[fieldIndex]
    if not field then return false end

    field.Pruned = true
    return true, "Pruned! Mutation chance increased."
end

-- Harvest a plant
function PlantManager.HarvestPlant(player, plotIndex, fieldIndex)
    local data = DataManager.GetData(player)
    if not data then return false, "No data" end

    local plot = data.Plots[plotIndex]
    if not plot then return false, "Plot does not exist" end

    local field = plot.Fields[fieldIndex]
    if not field then return false, "No plant here" end

    -- Must be at harvest phase (progress >= 0.8)
    if field.GrowthProgress < 0.8 then
        return false, "Not ripe yet! (" .. PlantManager.GetGrowthPhase(field.GrowthProgress) .. ")"
    end

    local plantInfo = PlantData.GetPlant(field.PlantId)
    if not plantInfo then return false, "Unknown plant" end

    -- Calculate final quality (apply overripe loss)
    local finalQuality = field.Quality
    if field.QualityLoss and field.QualityLoss > 0 then
        local qualityReduction = math.floor(field.QualityLoss * field.Quality)
        finalQuality = math.max(1, field.Quality - qualityReduction)
    end

    -- Yield multiplier (Gamepass: DoubleHarvest)
    local yieldMult = 1
    if data.Gamepasses and data.Gamepasses.DoubleHarvest then
        yieldMult = Config.Economy.Gamepasses.DoubleHarvest.YieldMult
    end

    -- Add plant to inventory
    local harvestedPlant = {
        PlantId = field.PlantId,
        Quality = finalQuality,
        Traits = field.Traits or {},
        HarvestedAt = os.time(),
    }

    for i = 1, yieldMult do
        table.insert(data.Inventory.Plants, harvestedPlant)
    end

    -- Update Plantdex
    data.Plantdex[field.PlantId] = true

    -- Stats + XP
    data.Stats.TotalHarvests = data.Stats.TotalHarvests + 1
    DataManager.AddXP(player, Config.Economy.XP.Harvest)

    -- Clear field
    plot.Fields[fieldIndex] = nil

    return true, "Harvested: " .. plantInfo.Name .. " (" .. finalQuality .. "★)"
end

-- Upgrade a plot
function PlantManager.UpgradePlot(player, plotIndex)
    local data = DataManager.GetData(player)
    if not data then return false end

    local plot = data.Plots[plotIndex]
    if not plot then return false, "Plot does not exist" end

    if plot.Level >= #Config.Garden.PlotUpgradeCosts then
        return false, "Max level reached"
    end

    local cost = Config.Garden.PlotUpgradeCosts[plot.Level]
    if not DataManager.RemoveCoins(player, cost) then
        return false, "Not enough Coins (" .. cost .. " needed)"
    end

    plot.Level = plot.Level + 1
    return true, "Plot upgraded to level " .. plot.Level
end

-- Buy a new plot
function PlantManager.BuyPlot(player, plotType)
    local data = DataManager.GetData(player)
    if not data then return false end

    local currentPlots = 0
    for _ in pairs(data.Plots) do currentPlots = currentPlots + 1 end

    local maxPlots = Config.Garden.MaxPlots
    if data.Gamepasses and data.Gamepasses.ExtraPlots then
        maxPlots = maxPlots + Config.Economy.Gamepasses.ExtraPlots.BonusPlots
    end

    if currentPlots >= maxPlots then
        return false, "Max number of plots reached"
    end

    -- Cost based on how many plots the player already has
    local cost = Config.Garden.PlotUpgradeCosts[currentPlots] or 50000

    if not DataManager.RemoveCoins(player, cost) then
        return false, "Not enough Coins"
    end

    local newIndex = currentPlots + 1
    data.Plots[newIndex] = {
        Level = 1,
        Type = plotType or "Standard",
        SoilType = "Normal",
        Fields = {},
    }

    return true, "New plot purchased!"
end

-- ============================================================
-- REMOTE EVENT HANDLERS
-- ============================================================

local function setupRemoteHandlers()
    -- Rate limiting
    local lastAction = {}

    local function rateCheck(player)
        local now = os.clock()
        local key = tostring(player.UserId)
        if lastAction[key] and (now - lastAction[key]) < (1 / Config.Technical.MaxRequestsPerSecond) then
            return false
        end
        lastAction[key] = now
        return true
    end

    remotes.PlantSeed.OnServerEvent:Connect(function(player, plotIndex, fieldIndex, plantId)
        if not rateCheck(player) then return end
        local success, msg = PlantManager.PlantSeed(player, plotIndex, fieldIndex, plantId)
        -- TODO: Fire client feedback
    end)

    remotes.WaterPlant.OnServerEvent:Connect(function(player, plotIndex, fieldIndex)
        if not rateCheck(player) then return end
        PlantManager.WaterPlant(player, plotIndex, fieldIndex)
    end)

    remotes.FertilizePlant.OnServerEvent:Connect(function(player, plotIndex, fieldIndex)
        if not rateCheck(player) then return end
        PlantManager.FertilizePlant(player, plotIndex, fieldIndex)
    end)

    remotes.PrunePlant.OnServerEvent:Connect(function(player, plotIndex, fieldIndex)
        if not rateCheck(player) then return end
        PlantManager.PrunePlant(player, plotIndex, fieldIndex)
    end)

    remotes.HarvestPlant.OnServerEvent:Connect(function(player, plotIndex, fieldIndex)
        if not rateCheck(player) then return end
        PlantManager.HarvestPlant(player, plotIndex, fieldIndex)
    end)

    remotes.UpgradePlot.OnServerEvent:Connect(function(player, plotIndex)
        if not rateCheck(player) then return end
        PlantManager.UpgradePlot(player, plotIndex)
    end)
end

-- ============================================================
-- START
-- ============================================================

createRemotes()
setupRemoteHandlers()

-- Growth tick loop
task.spawn(function()
    while true do
        growthTick()
        task.wait(Config.Garden.TickInterval)
    end
end)

return PlantManager
