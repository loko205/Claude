--[[
    ProcessingManager.lua — Verarbeitungs-System (NEU)
    Pflanze → Verarbeitung (Trocknen/Mörsern/Pressen/Destillieren/Äther-Extraktion) → Extrakt
    Server validiert alles: Maschinen-Besitz, Level, richtige Methode.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlantData = require(ReplicatedStorage.Shared.PlantData)
local ProcessingData = require(ReplicatedStorage.Shared.ProcessingData)
local DataManager = require(script.Parent.DataManager)

local ProcessingManager = {}

-- Max concurrent processing slots per player
local MAX_PROCESSING_SLOTS = 3

-- RemoteEvents
local remotes = {}

local function createRemotes()
    local folder = Instance.new("Folder")
    folder.Name = "ProcessingRemotes"
    folder.Parent = ReplicatedStorage

    local events = { "BuyMachine", "UpgradeMachine", "StartProcessing", "CollectExtract" }
    for _, name in ipairs(events) do
        local remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = folder
        remotes[name] = remote
    end
end

-- ============================================================
-- MASCHINEN-VERWALTUNG
-- ============================================================

-- Buy a processing machine
function ProcessingManager.BuyMachine(player, methodId)
    local data = DataManager.GetData(player)
    if not data then return false, "Keine Daten" end

    local methodConfig = Config.Processing.Methods[methodId]
    if not methodConfig then return false, "Unbekannte Methode" end

    -- Level check
    if data.Level < methodConfig.LevelReq then
        return false, "Level " .. methodConfig.LevelReq .. " benötigt"
    end

    -- Already owned?
    if data.Processing.Machines[methodId] and data.Processing.Machines[methodId].Owned then
        return false, "Bereits vorhanden"
    end

    -- Cost check
    if not DataManager.RemoveCoins(player, methodConfig.Cost) then
        return false, "Nicht genug Coins (" .. methodConfig.Cost .. " benötigt)"
    end

    data.Processing.Machines[methodId] = {
        Owned = true,
        Level = 1,
    }

    return true, methodConfig.MachineName .. " gekauft!"
end

-- Upgrade a machine (Level 1→2→3)
function ProcessingManager.UpgradeMachine(player, methodId)
    local data = DataManager.GetData(player)
    if not data then return false, "Keine Daten" end

    local machine = data.Processing.Machines[methodId]
    if not machine or not machine.Owned then
        return false, "Maschine nicht vorhanden"
    end

    if machine.Level >= #Config.Processing.UpgradeLevels then
        return false, "Bereits maximales Level"
    end

    local targetLevel = machine.Level + 1
    local cost = ProcessingData.GetUpgradeCost(methodId, targetLevel)

    if not DataManager.RemoveCoins(player, cost) then
        return false, "Nicht genug Coins (" .. cost .. " benötigt)"
    end

    machine.Level = targetLevel
    local upgradeName = Config.Processing.UpgradeLevels[targetLevel].Name

    return true, "Upgrade auf " .. upgradeName .. "!"
end

-- ============================================================
-- VERARBEITUNG STARTEN
-- ============================================================

-- Start processing a plant into an extract
-- plantInventoryIndex: Index in data.Inventory.Plants
-- methodId: Which processing method to use
function ProcessingManager.StartProcessing(player, plantInventoryIndex, methodId)
    local data = DataManager.GetData(player)
    if not data then return false, "Keine Daten" end

    -- Check active processing slots
    local activeCount = #data.Processing.ActiveProcessing
    if activeCount >= MAX_PROCESSING_SLOTS then
        return false, "Alle Verarbeitungs-Slots belegt (" .. MAX_PROCESSING_SLOTS .. " max)"
    end

    -- Validate plant exists in inventory
    local plant = data.Inventory.Plants[plantInventoryIndex]
    if not plant then return false, "Pflanze nicht im Inventar" end

    local plantInfo = PlantData.GetPlant(plant.PlantId)
    if not plantInfo then return false, "Unbekannte Pflanze" end

    -- Validate machine owned
    local machine = data.Processing.Machines[methodId]
    if not machine or not machine.Owned then
        return false, "Maschine nicht vorhanden — kaufe zuerst ein " ..
            (Config.Processing.Methods[methodId] and Config.Processing.Methods[methodId].MachineName or "Gerät")
    end

    -- Validate player level for method
    if not ProcessingData.CanPlayerUse(methodId, data.Level) then
        return false, "Level zu niedrig für diese Methode"
    end

    -- Validate plant can be processed with this method
    local canProcess, efficiency = PlantData.CanProcess(plant.PlantId, methodId)
    if not canProcess then
        if Config.Processing.WrongMethodDestroysPlant then
            -- Wrong method: plant is destroyed!
            table.remove(data.Inventory.Plants, plantInventoryIndex)
            return false, "FALSCHE METHODE! " .. plantInfo.Name .. " wurde zerstört!"
        end
        return false, "Diese Methode funktioniert nicht für " .. plantInfo.Name
    end

    -- Calculate duration
    local duration = ProcessingData.GetDuration(methodId, machine.Level)

    -- Remove plant from inventory, start processing
    table.remove(data.Inventory.Plants, plantInventoryIndex)

    table.insert(data.Processing.ActiveProcessing, {
        PlantId = plant.PlantId,
        PlantQuality = plant.Quality,
        PlantTraits = plant.Traits,
        Method = methodId,
        Efficiency = efficiency,
        MachineLevel = machine.Level,
        StartTime = os.time(),
        Duration = duration,
    })

    local methodName = ProcessingData.GetMethod(methodId).Name
    return true, plantInfo.Name .. " wird verarbeitet (" .. methodName .. ", " .. math.floor(duration) .. "s)"
end

-- ============================================================
-- EXTRAKT ABHOLEN
-- ============================================================

-- Collect a finished extract
function ProcessingManager.CollectExtract(player, processingIndex)
    local data = DataManager.GetData(player)
    if not data then return false, "Keine Daten" end

    local processing = data.Processing.ActiveProcessing[processingIndex]
    if not processing then return false, "Keine Verarbeitung an diesem Slot" end

    -- Check if done
    local elapsed = os.time() - processing.StartTime
    if elapsed < processing.Duration then
        local remaining = math.ceil(processing.Duration - elapsed)
        return false, "Noch " .. remaining .. "s übrig"
    end

    local plantInfo = PlantData.GetPlant(processing.PlantId)
    if not plantInfo then return false, "Unbekannte Pflanze" end

    -- Calculate potency
    local potency = ProcessingData.CalculatePotency(
        processing.PlantQuality,
        processing.Efficiency,
        processing.MachineLevel
    )

    -- Calculate yield
    local hasGigantisch = false
    if processing.PlantTraits then
        for _, trait in ipairs(processing.PlantTraits) do
            if trait == "Gigantisch" then
                hasGigantisch = true
                break
            end
        end
    end
    local yield = ProcessingData.GetYield(plantInfo, processing.MachineLevel, hasGigantisch)

    -- Add extract to inventory
    local extractKey = processing.PlantId
    if not data.Inventory.Extracts[extractKey] then
        data.Inventory.Extracts[extractKey] = { Amount = 0, Potency = 0 }
    end

    local existing = data.Inventory.Extracts[extractKey]
    -- Average potency when combining extracts
    local totalAmount = existing.Amount + yield
    existing.Potency = (existing.Potency * existing.Amount + potency * yield) / totalAmount
    existing.Amount = totalAmount

    -- Track potent trait for later brewing
    if processing.PlantTraits then
        for _, trait in ipairs(processing.PlantTraits) do
            if trait == "Potent" then
                existing.HasPotent = true
                break
            end
        end
    end

    -- Remove from active processing
    table.remove(data.Processing.ActiveProcessing, processingIndex)

    -- Stats + XP
    data.Stats.TotalExtracts = (data.Stats.TotalExtracts or 0) + yield
    DataManager.AddXP(player, Config.Economy.XP.Processing)

    return true, plantInfo.ExtractName .. " gewonnen! (Potenz: " .. math.floor(potency * 100) .. "%, Menge: " .. yield .. ")"
end

-- ============================================================
-- TICK: Check processing timers (for notifications)
-- ============================================================

local function processingTick()
    for _, player in ipairs(Players:GetPlayers()) do
        local data = DataManager.GetData(player)
        if not data then continue end

        for i, processing in ipairs(data.Processing.ActiveProcessing) do
            local elapsed = os.time() - processing.StartTime
            if elapsed >= processing.Duration and not processing.NotifiedComplete then
                processing.NotifiedComplete = true
                -- TODO: Fire client notification
            end
        end
    end
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

    remotes.BuyMachine.OnServerEvent:Connect(function(player, methodId)
        if not rateCheck(player) then return end
        if type(methodId) ~= "string" then return end
        ProcessingManager.BuyMachine(player, methodId)
    end)

    remotes.UpgradeMachine.OnServerEvent:Connect(function(player, methodId)
        if not rateCheck(player) then return end
        if type(methodId) ~= "string" then return end
        ProcessingManager.UpgradeMachine(player, methodId)
    end)

    remotes.StartProcessing.OnServerEvent:Connect(function(player, plantIndex, methodId)
        if not rateCheck(player) then return end
        if type(plantIndex) ~= "number" or type(methodId) ~= "string" then return end
        ProcessingManager.StartProcessing(player, plantIndex, methodId)
    end)

    remotes.CollectExtract.OnServerEvent:Connect(function(player, processingIndex)
        if not rateCheck(player) then return end
        if type(processingIndex) ~= "number" then return end
        ProcessingManager.CollectExtract(player, processingIndex)
    end)
end

-- ============================================================
-- START
-- ============================================================

createRemotes()
setupRemoteHandlers()

-- Processing tick (every 5 seconds is enough for notifications)
task.spawn(function()
    while true do
        processingTick()
        task.wait(5)
    end
end)

return ProcessingManager
