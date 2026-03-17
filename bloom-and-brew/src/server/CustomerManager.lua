--[[
    CustomerManager.lua — NPC Customer Spawning, Orders, Rewards
    Generates orders based on player rep and level.
    NPCs want plants AND potions (with purity requirements).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlantData = require(ReplicatedStorage.Shared.PlantData)
local PotionData = require(ReplicatedStorage.Shared.PotionData)
local CustomerData = require(ReplicatedStorage.Shared.CustomerData)
local DataManager = require(script.Parent.DataManager)

local CustomerManager = {}

-- RemoteEvents
local remotes = {}

local function createRemotes()
    local folder = Instance.new("Folder")
    folder.Name = "CustomerRemotes"
    folder.Parent = ReplicatedStorage

    local events = { "FulfillOrder", "DismissOrder", "GetDialogue" }
    for _, name in ipairs(events) do
        local remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = folder
        remotes[name] = remote
    end

    -- RemoteFunction for getting order data
    local getOrdersFunc = Instance.new("RemoteFunction")
    getOrdersFunc.Name = "GetOrders"
    getOrdersFunc.Parent = folder
    remotes.GetOrders = getOrdersFunc
end

-- ============================================================
-- ORDER GENERATION
-- ============================================================

-- Generate a specific order with concrete item requirements
local function generateConcreteOrder(customerTypeId, playerLevel, playerRep)
    local order = CustomerData.GenerateOrder(customerTypeId, playerLevel, playerRep)
    if not order then return nil end

    -- Fill in specific items based on order type
    if order.Type == "Plant" then
        -- Pick a random plant of the required rarity
        local plants = PlantData.GetPlantsByRarity(order.Rarity)
        local plantIds = {}
        for id in pairs(plants) do
            table.insert(plantIds, id)
        end
        if #plantIds == 0 then return nil end

        order.ItemId = plantIds[math.random(1, #plantIds)]
        local plant = PlantData.GetPlant(order.ItemId)
        order.ItemName = plant.Name
        order.RewardCoins = plant.BaseValue * order.Amount * order.RewardMult

    elseif order.Type == "Potion" then
        -- Pick a random potion of the required tier
        local potions = PotionData.GetPotionsByTier(order.Tier)
        local potionIds = {}
        for id in pairs(potions) do
            table.insert(potionIds, id)
        end
        if #potionIds == 0 then return nil end

        order.ItemId = potionIds[math.random(1, #potionIds)]
        local potion = PotionData.GetPotion(order.ItemId)
        order.ItemName = potion.Name
        order.RewardCoins = potion.BaseValue * order.Amount * order.RewardMult
    end

    -- Add unique order ID and timestamp
    order.OrderId = tostring(os.time()) .. "_" .. math.random(1000, 9999)
    order.CreatedAt = os.time()
    order.ExpiresAt = os.time() + order.Timer

    -- Generate greeting dialogue
    order.Greeting = CustomerData.GetDialogue(customerTypeId, "Greeting")

    return order
end

-- ============================================================
-- ORDER SPAWNING (Timer-based)
-- ============================================================

local playerSpawnTimers = {}

local function spawnOrderForPlayer(player)
    local data = DataManager.GetData(player)
    if not data then return end

    -- Max orders check
    if #data.Customers.ActiveOrders >= Config.Customers.MaxActiveOrders then return end

    -- Get available customer types for player's reputation
    local availableTypes = CustomerData.GetAvailableTypes(data.Reputation)
    if #availableTypes == 0 then return end

    -- Weighted random: higher rep customers spawn less often
    local weights = {}
    for i, typeId in ipairs(availableTypes) do
        -- Later types have lower weight
        weights[i] = math.max(1, #availableTypes - i + 1)
    end

    local totalWeight = 0
    for _, w in ipairs(weights) do totalWeight = totalWeight + w end

    local roll = math.random() * totalWeight
    local cumulative = 0
    local selectedType = availableTypes[1]

    for i, w in ipairs(weights) do
        cumulative = cumulative + w
        if roll <= cumulative then
            selectedType = availableTypes[i]
            break
        end
    end

    -- Generate order
    local order = generateConcreteOrder(selectedType, data.Level, data.Reputation)
    if not order then return end

    table.insert(data.Customers.ActiveOrders, order)
    -- TODO: Notify client about new order
end

local function customerSpawnLoop()
    while true do
        local interval = math.random(Config.Customers.SpawnInterval.Min, Config.Customers.SpawnInterval.Max)
        task.wait(interval)

        for _, player in ipairs(Players:GetPlayers()) do
            spawnOrderForPlayer(player)
        end
    end
end

-- ============================================================
-- TIMER EXPIRY
-- ============================================================

local function checkExpiredOrders()
    for _, player in ipairs(Players:GetPlayers()) do
        local data = DataManager.GetData(player)
        if not data then continue end

        local now = os.time()
        local expired = {}

        for i, order in ipairs(data.Customers.ActiveOrders) do
            if now >= order.ExpiresAt then
                table.insert(expired, i)
            end
        end

        -- Remove expired orders (reverse order to avoid index shift)
        for i = #expired, 1, -1 do
            local order = data.Customers.ActiveOrders[expired[i]]
            table.remove(data.Customers.ActiveOrders, expired[i])
            -- TODO: Notify client with timeout dialogue
            local timeoutMsg = CustomerData.GetDialogue(order.CustomerType, "Timeout")
        end
    end
end

-- ============================================================
-- ORDER FULFILLMENT
-- ============================================================

function CustomerManager.FulfillOrder(player, orderIndex, itemIndices)
    local data = DataManager.GetData(player)
    if not data then return false, "No data" end

    local order = data.Customers.ActiveOrders[orderIndex]
    if not order then return false, "Order does not exist" end

    -- Check timer
    if os.time() >= order.ExpiresAt then
        table.remove(data.Customers.ActiveOrders, orderIndex)
        return false, "Order expired!"
    end

    if type(itemIndices) ~= "table" or #itemIndices < order.Amount then
        return false, "Not enough items"
    end

    -- Validate items
    if order.Type == "Plant" then
        for _, idx in ipairs(itemIndices) do
            local plant = data.Inventory.Plants[idx]
            if not plant then return false, "Plant not in inventory" end
            if plant.PlantId ~= order.ItemId then return false, "Wrong plant" end
            if plant.Quality < (order.MinQuality or 1) then
                return false, "Quality too low (min. " .. order.MinQuality .. "★)"
            end
        end

        -- Remove plants (reverse order)
        table.sort(itemIndices, function(a, b) return a > b end)
        for _, idx in ipairs(itemIndices) do
            table.remove(data.Inventory.Plants, idx)
        end

    elseif order.Type == "Potion" then
        for _, idx in ipairs(itemIndices) do
            local potion = data.Inventory.Potions[idx]
            if not potion then return false, "Potion not in inventory" end
            if potion.PotionId ~= order.ItemId then return false, "Wrong potion" end
            if potion.Purity < (order.MinPurity or 0) then
                return false, "Purity too low (min. " .. order.MinPurity .. "%)"
            end
        end

        -- Remove potions (reverse order)
        table.sort(itemIndices, function(a, b) return a > b end)
        for _, idx in ipairs(itemIndices) do
            table.remove(data.Inventory.Potions, idx)
        end
    end

    -- Grant rewards
    local rewardCoins = math.floor(order.RewardCoins)

    -- VIP bonus
    if data.Gamepasses and data.Gamepasses.VIPAlchemist then
        rewardCoins = math.floor(rewardCoins * Config.Economy.Gamepasses.VIPAlchemist.CoinMult)
    end

    DataManager.AddCoins(player, rewardCoins)

    -- Bonus rewards
    local customerType = CustomerData.Types[order.CustomerType]
    local bonusMsg = ""
    if customerType and customerType.BonusRewards then
        for _, bonus in ipairs(customerType.BonusRewards) do
            if math.random() < bonus.Chance then
                if bonus.Type == "RecipeHint" then
                    bonusMsg = bonusMsg .. " + Recipe hint!"
                elseif bonus.Type == "RareSeed" then
                    -- Give a random rare seed
                    local rarePlants = PlantData.GetPlantsByRarity("Rare")
                    for id in pairs(rarePlants) do
                        data.Inventory.Seeds[id] = (data.Inventory.Seeds[id] or 0) + 1
                        bonusMsg = bonusMsg .. " + Rare seed: " .. rarePlants[id].Name
                        break
                    end
                elseif bonus.Type == "Catalyst" then
                    local catalysts = { "Moonstone", "Suncrystal", "WormCompost" }
                    local catalystId = catalysts[math.random(1, #catalysts)]
                    data.Inventory.Catalysts[catalystId] = (data.Inventory.Catalysts[catalystId] or 0) + 1
                    bonusMsg = bonusMsg .. " + Catalyst: " .. catalystId
                elseif bonus.Type == "MythicSeed" then
                    local mythicPlants = PlantData.GetPlantsByRarity("Mythic")
                    for id in pairs(mythicPlants) do
                        data.Inventory.Seeds[id] = (data.Inventory.Seeds[id] or 0) + 1
                        bonusMsg = bonusMsg .. " + MYTHIC seed: " .. mythicPlants[id].Name .. "!!!"
                        break
                    end
                end
            end
        end
    end

    -- Stats + XP + Reputation
    data.Customers.CompletedOrders = data.Customers.CompletedOrders + 1
    data.Stats.NPCOrdersFulfilled = data.Stats.NPCOrdersFulfilled + 1
    DataManager.AddXP(player, Config.Economy.XP.NPCOrder)

    -- Reputation gain based on customer type
    local repGain = { Villager = 5, Healer = 15, Noble = 30, Warlock = 75, TheShadow = 200 }
    data.Reputation = data.Reputation + (repGain[order.CustomerType] or 5)

    -- Remove order
    local acceptDialogue = CustomerData.GetDialogue(order.CustomerType, "Accept")
    table.remove(data.Customers.ActiveOrders, orderIndex)

    return true, acceptDialogue .. " (" .. rewardCoins .. " Coins" .. bonusMsg .. ")"
end

-- Dismiss an order (no penalty, just remove)
function CustomerManager.DismissOrder(player, orderIndex)
    local data = DataManager.GetData(player)
    if not data then return false end

    local order = data.Customers.ActiveOrders[orderIndex]
    if not order then return false end

    local declineDialogue = CustomerData.GetDialogue(order.CustomerType, "Decline")
    table.remove(data.Customers.ActiveOrders, orderIndex)

    return true, declineDialogue
end

-- ============================================================
-- REMOTE HANDLERS
-- ============================================================

local function setupRemoteHandlers()
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

    remotes.FulfillOrder.OnServerEvent:Connect(function(player, orderIndex, itemIndices)
        if not rateCheck(player) then return end
        if type(orderIndex) ~= "number" then return end
        if type(itemIndices) ~= "table" then return end
        CustomerManager.FulfillOrder(player, orderIndex, itemIndices)
    end)

    remotes.DismissOrder.OnServerEvent:Connect(function(player, orderIndex)
        if not rateCheck(player) then return end
        if type(orderIndex) ~= "number" then return end
        CustomerManager.DismissOrder(player, orderIndex)
    end)

    remotes.GetOrders.OnServerInvoke = function(player)
        local data = DataManager.GetData(player)
        if not data then return {} end
        return data.Customers.ActiveOrders
    end
end

-- ============================================================
-- START
-- ============================================================

createRemotes()
setupRemoteHandlers()

-- Spawn loop
task.spawn(customerSpawnLoop)

-- Expiry check every 10 seconds
task.spawn(function()
    while true do
        checkExpiredOrders()
        task.wait(10)
    end
end)

return CustomerManager
