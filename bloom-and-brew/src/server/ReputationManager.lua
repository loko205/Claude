--[[
    ReputationManager.lua — Two separate reputation systems:
    1. NPC Reputation: Increases through NPC orders, unlocks better customers
    2. Dealer Reputation: Increases through player sales, unlocks ranks

    Both systems are INDEPENDENT of each other.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CustomerData = require(ReplicatedStorage.Shared.CustomerData)
local PlayerTradeData = require(ReplicatedStorage.Shared.PlayerTradeData)
local DataManager = require(script.Parent.DataManager)

local ReputationManager = {}

-- ============================================================
-- 1. NPC-REPUTATION
-- ============================================================

-- Add NPC reputation (called by CustomerManager on order completion)
function ReputationManager.AddNPCRep(player, amount, customerType)
    local data = DataManager.GetData(player)
    if not data then return false end

    data.Reputation = data.Reputation + amount

    -- Check for newly unlocked customer types
    local newUnlocks = {}
    for _, typeId in ipairs(CustomerData.TypeOrder) do
        local ct = CustomerData.Types[typeId]
        if data.Reputation >= ct.MinRep and (data.Reputation - amount) < ct.MinRep then
            table.insert(newUnlocks, typeId)
        end
    end

    return true, newUnlocks
end

-- Get NPC rep info
function ReputationManager.GetNPCRepInfo(player)
    local data = DataManager.GetData(player)
    if not data then return nil end

    local currentType = "Villager"
    local nextType = nil
    local nextTypeRep = 0

    for i, typeId in ipairs(CustomerData.TypeOrder) do
        local ct = CustomerData.Types[typeId]
        if data.Reputation >= ct.MinRep then
            currentType = typeId
            -- Check next type
            if i < #CustomerData.TypeOrder then
                local nextCt = CustomerData.Types[CustomerData.TypeOrder[i + 1]]
                nextType = CustomerData.TypeOrder[i + 1]
                nextTypeRep = nextCt.MinRep
            end
        end
    end

    return {
        Reputation = data.Reputation,
        HighestCustomer = currentType,
        NextCustomer = nextType,
        NextCustomerAt = nextTypeRep,
        Progress = nextTypeRep > 0 and (data.Reputation / nextTypeRep) or 1.0,
    }
end

-- ============================================================
-- 2. DEALER REPUTATION (Player Sales)
-- ============================================================

-- Add dealer rep (called by PlayerTradeManager on sales)
function ReputationManager.AddDealerRep(player, amount)
    local data = DataManager.GetData(player)
    if not data then return false end

    local oldRep = data.Trade.DealerRep
    data.Trade.DealerRep = math.max(0, data.Trade.DealerRep + amount)

    -- Update rank
    local newRank = PlayerTradeData.GetDealerRank(data.Trade.DealerRep)
    local oldRank = PlayerTradeData.GetDealerRank(oldRep)

    data.Trade.DealerRank = newRank.Name

    -- Update stand slots
    data.Trade.StandSlots = newRank.StandSlots

    -- Check for rank-up
    local rankedUp = newRank.Name ~= oldRank.Name and amount > 0

    return true, rankedUp, newRank
end

-- Remove dealer rep (bad behavior)
function ReputationManager.RemoveDealerRep(player, amount, reason)
    return ReputationManager.AddDealerRep(player, -amount)
end

-- Get dealer rep info
function ReputationManager.GetDealerRepInfo(player)
    local data = DataManager.GetData(player)
    if not data then return nil end

    local currentRank = PlayerTradeData.GetDealerRank(data.Trade.DealerRep)

    -- Find next rank
    local nextRank = nil
    for _, rank in ipairs(PlayerTradeData.DealerRanks) do
        if rank.MinRep > data.Trade.DealerRep then
            nextRank = rank
            break
        end
    end

    return {
        DealerRep = data.Trade.DealerRep,
        CurrentRank = currentRank,
        NextRank = nextRank,
        TotalSales = data.Trade.TotalSales,
        StandSlots = PlayerTradeData.GetStandSlots(
            data.Trade.DealerRep,
            data.Gamepasses and data.Gamepasses.ExpandedStand
        ),
        Progress = nextRank and ((data.Trade.DealerRep - currentRank.MinRep) / (nextRank.MinRep - currentRank.MinRep)) or 1.0,
    }
end

-- ============================================================
-- 3. GUILD REPUTATION (aggregated from member rep)
-- ============================================================

-- Calculate total guild reputation from all members
function ReputationManager.CalculateGuildRep(memberUserIds)
    local totalRep = 0

    for _, userId in ipairs(memberUserIds) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            local data = DataManager.GetData(player)
            if data then
                totalRep = totalRep + data.Reputation + data.Trade.DealerRep
            end
        end
    end

    return totalRep
end

-- ============================================================
-- REMOTE (Read-only queries)
-- ============================================================

local function createRemotes()
    local folder = Instance.new("Folder")
    folder.Name = "RepRemotes"
    folder.Parent = ReplicatedStorage

    local getNPCRep = Instance.new("RemoteFunction")
    getNPCRep.Name = "GetNPCRepInfo"
    getNPCRep.Parent = folder
    getNPCRep.OnServerInvoke = function(player)
        return ReputationManager.GetNPCRepInfo(player)
    end

    local getDealerRep = Instance.new("RemoteFunction")
    getDealerRep.Name = "GetDealerRepInfo"
    getDealerRep.Parent = folder
    getDealerRep.OnServerInvoke = function(player)
        return ReputationManager.GetDealerRepInfo(player)
    end
end

createRemotes()

return ReputationManager
