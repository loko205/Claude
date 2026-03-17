--[[
    DataManager.lua — DataStore Persistenz, Auto-Save, Session-Lock
    Verwaltet alle Spielerdaten serverseitig.
    KEINE Spiellogik hier — nur Laden, Speichern, Schema-Defaults.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.Shared.Config)

local DataManager = {}

-- Active player data cache
local playerDataCache = {}
local sessionLocks = {}
local dataStore = DataStoreService:GetDataStore(Config.Technical.DataStoreKey)

-- ============================================================
-- DEFAULT PLAYER DATA SCHEMA
-- ============================================================

local function getDefaultData()
    return {
        -- Profil
        Level = 1,
        XP = 0,
        Coins = Config.Economy.StartCoins,
        Gems = Config.Economy.StartGems,
        Essence = 0,
        Reputation = 0,
        DealerReputation = 0,

        -- Garten
        Plots = {
            [1] = {
                Level = 1,
                Type = "Standard",
                SoilType = "Normal",
                Fields = {}, -- { [fieldIndex] = { PlantId, GrowthProgress, Quality, Traits, Watered, PlantedAt } }
            },
        },

        -- Labor
        Lab = {
            CauldronLevel = 1,
            ActiveBrew = nil, -- { PotionId, StartTime, Extracts, MinigameInputs }
            RecipesDiscovered = {},
        },

        -- Verarbeitung (NEU)
        Processing = {
            Machines = {}, -- { [methodId] = { Owned = bool, Level = 1-3 } }
            ActiveProcessing = {}, -- { PlantId, Method, StartTime, SlotIndex }
        },

        -- Inventar
        Inventory = {
            Seeds = {},      -- { [plantId] = amount }
            Plants = {},     -- { [index] = { PlantId, Quality, Traits } }
            Catalysts = {},  -- { [catalystId] = amount }
            Extracts = {},   -- { [plantId] = { Amount, Potency } } (NEU)
            Potions = {},    -- { [index] = { PotionId, Purity, Quality, Traits, BrewedAt } }
            Tools = {},
        },

        -- Sammelalbum
        Plantdex = {},   -- { [plantId] = true }
        Potiondex = {},  -- { [potionId] = true }

        -- NPC-Kunden
        Customers = {
            ActiveOrders = {},    -- { [index] = order }
            CompletedOrders = 0,  -- Counter only (DataStore size!)
        },

        -- Spieler-Handel
        Trade = {
            DealerRep = 0,
            DealerRank = "Lehrling",
            TotalSales = 0,
            StandSlots = 3,
            StandOffers = {},      -- { [index] = { PotionIndex, Price, ListedAt } }
            MarketOffers = {},     -- { [index] = { ItemType, ItemData, Price, ListedAt, Secret } }
            Auctions = {},         -- { [index] = { ItemData, MinBid, CurrentBid, BidderId, EndTime } }
            FavoriteSuppliers = {},-- { [userId] = purchaseCount }
            TrustScores = {},      -- { [userId] = trustScore }
        },

        -- Gilde
        Guild = {
            GuildId = nil,
            Role = nil,
            Contributions = 0,
        },

        -- Stats
        Stats = {
            TotalHarvests = 0,
            TotalPotionsBrewed = 0,
            TotalExtracts = 0,
            MutationsDiscovered = 0,
            NPCOrdersFulfilled = 0,
            PlayerSales = 0,
            DuelsWon = 0,
            DuelsLost = 0,
            HighestPurity = 0,
            TotalCoinsEarned = 0,
            PlayTime = 0,
        },

        LoginStreak = {
            LastLogin = 0,
            CurrentStreak = 0,
        },

        Gamepasses = {},
        Settings = {},

        -- Meta
        DataVersion = 1,
        FirstJoin = os.time(),
        LastSave = 0,
    }
end

-- ============================================================
-- DEEP MERGE (fills in missing fields from defaults)
-- ============================================================

local function deepMerge(target, defaults)
    for key, defaultValue in pairs(defaults) do
        if target[key] == nil then
            if type(defaultValue) == "table" then
                target[key] = deepMerge({}, defaultValue)
            else
                target[key] = defaultValue
            end
        elseif type(target[key]) == "table" and type(defaultValue) == "table" then
            deepMerge(target[key], defaultValue)
        end
    end
    return target
end

-- ============================================================
-- LOAD / SAVE
-- ============================================================

function DataManager.LoadData(player)
    local userId = tostring(player.UserId)

    -- Session lock check
    if sessionLocks[userId] then
        warn("[DataManager] Session already locked for " .. player.Name)
        return nil
    end

    local success, data = pcall(function()
        return dataStore:GetAsync("Player_" .. userId)
    end)

    if not success then
        warn("[DataManager] Failed to load data for " .. player.Name .. ": " .. tostring(data))
        -- Give default data if load fails (safe fallback)
        data = nil
    end

    -- New player or failed load: use defaults
    if data == nil then
        data = getDefaultData()
        -- Give starting seeds
        for _, seedInfo in ipairs(Config.Economy.StartSeeds) do
            data.Inventory.Seeds[seedInfo.PlantId] = seedInfo.Amount
        end
    else
        -- Fill in any missing fields from schema updates
        data = deepMerge(data, getDefaultData())
    end

    -- Set session lock
    sessionLocks[userId] = true
    playerDataCache[userId] = data

    print("[DataManager] Loaded data for " .. player.Name)
    return data
end

function DataManager.SaveData(player)
    local userId = tostring(player.UserId)
    local data = playerDataCache[userId]

    if not data then
        warn("[DataManager] No data to save for " .. player.Name)
        return false
    end

    data.LastSave = os.time()

    local success, err = pcall(function()
        dataStore:SetAsync("Player_" .. userId, data)
    end)

    if not success then
        warn("[DataManager] Failed to save data for " .. player.Name .. ": " .. tostring(err))
        return false
    end

    return true
end

function DataManager.GetData(player)
    local userId = tostring(player.UserId)
    return playerDataCache[userId]
end

-- ============================================================
-- SAFE GETTERS / SETTERS
-- ============================================================

function DataManager.AddCoins(player, amount)
    local data = DataManager.GetData(player)
    if not data then return false end
    if amount < 0 then return false end -- Use RemoveCoins for negative
    data.Coins = data.Coins + amount
    data.Stats.TotalCoinsEarned = data.Stats.TotalCoinsEarned + amount
    return true
end

function DataManager.RemoveCoins(player, amount)
    local data = DataManager.GetData(player)
    if not data then return false end
    if data.Coins < amount then return false end
    data.Coins = data.Coins - amount
    return true
end

function DataManager.AddGems(player, amount)
    local data = DataManager.GetData(player)
    if not data then return false end
    data.Gems = data.Gems + amount
    return true
end

function DataManager.AddEssence(player, amount)
    local data = DataManager.GetData(player)
    if not data then return false end
    data.Essence = data.Essence + amount
    return true
end

function DataManager.AddXP(player, amount)
    local data = DataManager.GetData(player)
    if not data then return false end

    data.XP = data.XP + amount

    -- Level-up check
    local formula = Config.Economy.LevelFormula
    local xpNeeded = formula.BaseXP * (data.Level ^ formula.Exponent)

    while data.XP >= xpNeeded do
        data.XP = data.XP - xpNeeded
        data.Level = data.Level + 1
        xpNeeded = formula.BaseXP * (data.Level ^ formula.Exponent)
        print("[DataManager] " .. player.Name .. " leveled up to " .. data.Level .. "!")
    end

    return true
end

-- ============================================================
-- AUTO-SAVE LOOP
-- ============================================================

local function autoSaveLoop()
    while true do
        task.wait(Config.Technical.AutoSaveInterval)
        for userId, data in pairs(playerDataCache) do
            local player = Players:GetPlayerByUserId(tonumber(userId))
            if player then
                DataManager.SaveData(player)
            end
        end
    end
end

-- ============================================================
-- PLAYER LIFECYCLE
-- ============================================================

Players.PlayerAdded:Connect(function(player)
    DataManager.LoadData(player)
end)

Players.PlayerRemoving:Connect(function(player)
    local userId = tostring(player.UserId)
    DataManager.SaveData(player)
    playerDataCache[userId] = nil
    sessionLocks[userId] = nil
end)

-- Save all on server shutdown
game:BindToClose(function()
    for userId, data in pairs(playerDataCache) do
        local player = Players:GetPlayerByUserId(tonumber(userId))
        if player then
            DataManager.SaveData(player)
        end
    end
end)

-- Start auto-save
task.spawn(autoSaveLoop)

return DataManager
