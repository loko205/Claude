--[[
    EconomyManager.lua — Währungs-Management, Shop, Level-Ups, Daily Rewards
    Anti-Exploit: Alle Transaktionen server-validiert.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage.Shared.Config)
local PlantData = require(ReplicatedStorage.Shared.PlantData)
local DataManager = require(script.Parent.DataManager)

local EconomyManager = {}

-- RemoteEvents
local remotes = {}

local function createRemotes()
    local folder = Instance.new("Folder")
    folder.Name = "EconomyRemotes"
    folder.Parent = ReplicatedStorage

    local events = { "BuySeeds", "SellPlant", "SellPotion", "ClaimDailyLogin", "BuySoilUpgrade" }
    for _, name in ipairs(events) do
        local remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = folder
        remotes[name] = remote
    end

    local getShopFunc = Instance.new("RemoteFunction")
    getShopFunc.Name = "GetShopData"
    getShopFunc.Parent = folder
    remotes.GetShopData = getShopFunc
end

-- Rate limiter
local lastActions = {}
local function rateCheck(player)
    local now = os.clock()
    local key = tostring(player.UserId)
    if lastActions[key] and (now - lastActions[key]) < (1 / Config.Technical.MaxRequestsPerSecond) then
        return false
    end
    lastActions[key] = now
    return true
end

-- ============================================================
-- SHOP — SAMEN KAUFEN
-- ============================================================

function EconomyManager.BuySeeds(player, plantId, amount)
    local data = DataManager.GetData(player)
    if not data then return false, "Keine Daten" end

    if type(amount) ~= "number" or amount <= 0 or amount > 99 then
        return false, "Ungültige Menge"
    end

    local plant = PlantData.GetPlant(plantId)
    if not plant then return false, "Unbekannte Pflanze" end

    -- Only Common and Uncommon seeds in shop
    local shopRarities = { Common = true, Uncommon = true }
    if not shopRarities[plant.Rarity] then
        return false, "Diese Samen sind nicht im Shop erhältlich (nur durch Mutationen/Aufträge)"
    end

    local totalCost = plant.SeedCost * amount
    if not DataManager.RemoveCoins(player, totalCost) then
        return false, "Nicht genug Coins (" .. totalCost .. " benötigt)"
    end

    data.Inventory.Seeds[plantId] = (data.Inventory.Seeds[plantId] or 0) + amount

    return true, amount .. "x " .. plant.Name .. "-Samen gekauft (" .. totalCost .. " Coins)"
end

-- ============================================================
-- VERKAUFEN (an NPCs, Basis-Preis)
-- ============================================================

function EconomyManager.SellPlant(player, plantIndex)
    local data = DataManager.GetData(player)
    if not data then return false, "Keine Daten" end

    local plant = data.Inventory.Plants[plantIndex]
    if not plant then return false, "Pflanze nicht im Inventar" end

    local plantInfo = PlantData.GetPlant(plant.PlantId)
    if not plantInfo then return false, "Unbekannte Pflanze" end

    -- Calculate value
    local qualityMult = Config.Plants.QualityStars[plant.Quality]
    qualityMult = qualityMult and qualityMult.Mult or 1.0

    local value = math.floor(plantInfo.BaseValue * qualityMult)

    -- Trait bonuses
    if plant.Traits then
        for _, trait in ipairs(plant.Traits) do
            local traitInfo = Config.Plants.Traits[trait]
            if traitInfo then
                if traitInfo.ValueMult then
                    value = math.floor(value * traitInfo.ValueMult)
                elseif traitInfo.Mult then
                    value = math.floor(value * traitInfo.Mult)
                end
            end
        end
    end

    -- VIP bonus
    if data.Gamepasses and data.Gamepasses.VIPAlchemist then
        value = math.floor(value * Config.Economy.Gamepasses.VIPAlchemist.CoinMult)
    end

    DataManager.AddCoins(player, value)
    table.remove(data.Inventory.Plants, plantIndex)

    return true, plantInfo.Name .. " verkauft für " .. value .. " Coins"
end

function EconomyManager.SellPotion(player, potionIndex)
    local data = DataManager.GetData(player)
    if not data then return false, "Keine Daten" end

    local potion = data.Inventory.Potions[potionIndex]
    if not potion then return false, "Trank nicht im Inventar" end

    local PotionData = require(ReplicatedStorage.Shared.PotionData)
    local value = PotionData.CalculateValue(potion.PotionId, potion.Purity, 3)

    -- VIP bonus
    if data.Gamepasses and data.Gamepasses.VIPAlchemist then
        value = math.floor(value * Config.Economy.Gamepasses.VIPAlchemist.CoinMult)
    end

    DataManager.AddCoins(player, value)
    table.remove(data.Inventory.Potions, potionIndex)

    local potionInfo = PotionData.GetPotion(potion.PotionId)
    return true, (potionInfo and potionInfo.Name or "Trank") .. " verkauft für " .. value .. " Coins"
end

-- ============================================================
-- DAILY LOGIN REWARDS
-- ============================================================

function EconomyManager.ClaimDailyLogin(player)
    local data = DataManager.GetData(player)
    if not data then return false, "Keine Daten" end

    local now = os.time()
    local lastLogin = data.LoginStreak.LastLogin or 0

    -- Check if already claimed today (same UTC day)
    local lastDay = math.floor(lastLogin / 86400)
    local today = math.floor(now / 86400)

    if lastDay == today then
        return false, "Bereits heute eingeloggt!"
    end

    -- Update streak
    if lastDay == today - 1 then
        -- Consecutive day
        data.LoginStreak.CurrentStreak = math.min(
            data.LoginStreak.CurrentStreak + 1,
            Config.Economy.DailyLogin.MaxStreak
        )
    else
        -- Streak broken
        data.LoginStreak.CurrentStreak = 1
    end

    data.LoginStreak.LastLogin = now

    -- Calculate rewards with streak bonus
    local streakMult = 1 + (data.LoginStreak.CurrentStreak - 1) * Config.Economy.DailyLogin.StreakBonus
    local coins = math.floor(Config.Economy.DailyLogin.Coins * streakMult)
    local gems = math.floor(Config.Economy.DailyLogin.Gems * streakMult)

    DataManager.AddCoins(player, coins)
    DataManager.AddGems(player, gems)

    return true, "Tag " .. data.LoginStreak.CurrentStreak .. "! +" .. coins .. " Coins, +" .. gems .. " Gems"
end

-- ============================================================
-- BODEN-UPGRADE
-- ============================================================

function EconomyManager.BuySoilUpgrade(player, plotIndex, soilType)
    local data = DataManager.GetData(player)
    if not data then return false, "Keine Daten" end

    local plot = data.Plots[plotIndex]
    if not plot then return false, "Plot existiert nicht" end

    if not Config.Garden.SoilTypes[soilType] then
        return false, "Unbekannter Boden-Typ"
    end

    if plot.SoilType == soilType then
        return false, "Bereits dieser Boden-Typ"
    end

    -- Soil costs
    local soilCosts = {
        Normal = 0,
        Naehrboden = 500,
        Mystisch = 1500,
        Golden = 3000,
    }

    local cost = soilCosts[soilType] or 0
    if cost > 0 and not DataManager.RemoveCoins(player, cost) then
        return false, "Nicht genug Coins (" .. cost .. " benötigt)"
    end

    plot.SoilType = soilType

    return true, "Boden auf " .. soilType .. " gewechselt!"
end

-- ============================================================
-- SHOP-DATEN FÜR CLIENT
-- ============================================================

local function getShopData(player)
    local data = DataManager.GetData(player)
    if not data then return {} end

    local shopSeeds = {}
    for id, plant in pairs(PlantData.Plants) do
        if plant.Rarity == "Common" or plant.Rarity == "Uncommon" then
            table.insert(shopSeeds, {
                PlantId = id,
                Name = plant.Name,
                Desc = plant.Desc,
                Cost = plant.SeedCost,
                Rarity = plant.Rarity,
                Owned = data.Inventory.Seeds[id] or 0,
            })
        end
    end

    return {
        Seeds = shopSeeds,
        PlayerCoins = data.Coins,
        PlayerGems = data.Gems,
        PlayerLevel = data.Level,
    }
end

-- ============================================================
-- GAMEPASS HANDLING
-- ============================================================

-- Gamepass IDs would be configured in Roblox (placeholder mapping)
local gamepassMap = {
    -- [gamepassId] = "GamepassName"
}

-- Check and grant gamepasses on join
local function checkGamepasses(player)
    local data = DataManager.GetData(player)
    if not data then return end

    for gamepassId, gamepassName in pairs(gamepassMap) do
        local success, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
        end)
        if success and owns then
            data.Gamepasses[gamepassName] = true
        end
    end
end

-- ============================================================
-- REMOTE HANDLERS
-- ============================================================

local function setupRemoteHandlers()
    remotes.BuySeeds.OnServerEvent:Connect(function(player, plantId, amount)
        if not rateCheck(player) then return end
        if type(plantId) ~= "string" or type(amount) ~= "number" then return end
        EconomyManager.BuySeeds(player, plantId, amount)
    end)

    remotes.SellPlant.OnServerEvent:Connect(function(player, plantIndex)
        if not rateCheck(player) then return end
        if type(plantIndex) ~= "number" then return end
        EconomyManager.SellPlant(player, plantIndex)
    end)

    remotes.SellPotion.OnServerEvent:Connect(function(player, potionIndex)
        if not rateCheck(player) then return end
        if type(potionIndex) ~= "number" then return end
        EconomyManager.SellPotion(player, potionIndex)
    end)

    remotes.ClaimDailyLogin.OnServerEvent:Connect(function(player)
        if not rateCheck(player) then return end
        EconomyManager.ClaimDailyLogin(player)
    end)

    remotes.BuySoilUpgrade.OnServerEvent:Connect(function(player, plotIndex, soilType)
        if not rateCheck(player) then return end
        if type(plotIndex) ~= "number" or type(soilType) ~= "string" then return end
        EconomyManager.BuySoilUpgrade(player, plotIndex, soilType)
    end)

    remotes.GetShopData.OnServerInvoke = function(player)
        return getShopData(player)
    end
end

-- ============================================================
-- START
-- ============================================================

createRemotes()
setupRemoteHandlers()

-- Check gamepasses on join
Players.PlayerAdded:Connect(function(player)
    task.wait(2) -- Wait for DataManager to load
    checkGamepasses(player)

    -- Auto-claim daily login
    EconomyManager.ClaimDailyLogin(player)
end)

return EconomyManager
