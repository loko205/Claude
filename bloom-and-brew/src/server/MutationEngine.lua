--[[
    MutationEngine.lua — Server-side mutation calculation
    Mutation Lab at Level 5: 2 plants + optional catalyst → result
    Trait inheritance, success probability, fallback on failure.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlantData = require(ReplicatedStorage.Shared.PlantData)
local MutationRecipes = require(ReplicatedStorage.Shared.MutationRecipes)
local DataManager = require(script.Parent.DataManager)

local MutationEngine = {}

-- RemoteEvents
local remotes = {}

local function createRemotes()
    local folder = Instance.new("Folder")
    folder.Name = "MutationRemotes"
    folder.Parent = ReplicatedStorage

    local events = { "AttemptMutation" }
    for _, name in ipairs(events) do
        local remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = folder
        remotes[name] = remote
    end
end

-- ============================================================
-- MUTATION LOGIC
-- ============================================================

-- Attempt a mutation with two plants and optional catalyst
-- plantIndex1, plantIndex2: Indices in data.Inventory.Plants
-- catalystId: optional catalyst from inventory
function MutationEngine.AttemptMutation(player, plantIndex1, plantIndex2, catalystId)
    local data = DataManager.GetData(player)
    if not data then return false, "No data" end

    -- Level check
    if data.Level < Config.Mutation.UnlockLevel then
        return false, "Mutation Lab unlocks at Level " .. Config.Mutation.UnlockLevel
    end

    -- Validate plants exist
    local plant1 = data.Inventory.Plants[plantIndex1]
    local plant2 = data.Inventory.Plants[plantIndex2]
    if not plant1 or not plant2 then return false, "Plants not in inventory" end
    if plantIndex1 == plantIndex2 then return false, "Two different plants required" end

    -- Validate catalyst if provided
    if catalystId then
        local catalystAmount = data.Inventory.Catalysts[catalystId]
        if not catalystAmount or catalystAmount <= 0 then
            return false, "Catalyst not available"
        end
        if not MutationRecipes.Catalysts[catalystId] then
            return false, "Unknown catalyst"
        end
    end

    -- Find matching recipe
    local recipe = MutationRecipes.FindRecipe(plant1.PlantId, plant2.PlantId)

    -- Check if recipe requires specific catalyst
    if recipe and recipe.RequiresCatalyst then
        if catalystId ~= recipe.RequiresCatalyst then
            return false, "This mutation requires " ..
                MutationRecipes.Catalysts[recipe.RequiresCatalyst].Name .. " as catalyst!"
        end
    end

    -- Experimental Serum: random result regardless of recipe
    local useRandom = false
    if catalystId == "ExperimentalSerum" then
        useRandom = true
    end

    -- Get plot modifiers (if mutating on a Mutations-Plot)
    -- For simplicity, use base values; in full game, check which plot player is using
    local plotMutationMult = 1.0
    local soilMutationMult = 1.0

    -- Check for Mutation plot bonus
    for _, plot in pairs(data.Plots) do
        if plot.Type == "Mutation" then
            plotMutationMult = Config.Garden.PlotTypes.Mutation.MutationMult
            soilMutationMult = Config.Garden.SoilTypes[plot.SoilType]
                and Config.Garden.SoilTypes[plot.SoilType].MutationMult or 1.0
            break
        end
    end

    -- Pruned bonus
    local pruneBonus = 0
    if plant1.Pruned then pruneBonus = pruneBonus + 0.05 end
    if plant2.Pruned then pruneBonus = pruneBonus + 0.05 end

    -- Consume plants and catalyst
    -- Remove higher index first to avoid shifting
    local highIndex = math.max(plantIndex1, plantIndex2)
    local lowIndex = math.min(plantIndex1, plantIndex2)
    table.remove(data.Inventory.Plants, highIndex)
    table.remove(data.Inventory.Plants, lowIndex)

    if catalystId then
        data.Inventory.Catalysts[catalystId] = data.Inventory.Catalysts[catalystId] - 1
        if data.Inventory.Catalysts[catalystId] <= 0 then
            data.Inventory.Catalysts[catalystId] = nil
        end
    end

    -- Random result (Experimental Serum)
    if useRandom then
        local allPlantIds = PlantData.GetAllPlantIds()
        local randomPlantId = allPlantIds[math.random(1, #allPlantIds)]
        local randomPlant = PlantData.GetPlant(randomPlantId)

        local resultQuality = PlantData.RollQuality()
        local resultTraits = {}

        -- Small trait chance
        if math.random() < Config.Plants.TraitChance * 2 then -- Double chance with serum
            local trait = PlantData.GetRandomTrait(randomPlantId)
            if trait then table.insert(resultTraits, trait) end
        end

        table.insert(data.Inventory.Plants, {
            PlantId = randomPlantId,
            Quality = resultQuality,
            Traits = resultTraits,
            MutatedFrom = { plant1.PlantId, plant2.PlantId },
            MutatedAt = os.time(),
        })

        data.Plantdex[randomPlantId] = true
        data.Stats.MutationsDiscovered = data.Stats.MutationsDiscovered + 1
        DataManager.AddXP(player, Config.Economy.XP.Mutation)

        return true, "Experimental mutation! Result: " .. randomPlant.Name .. " (Random!)"
    end

    -- No recipe found
    if not recipe then
        local fallbackId = MutationRecipes.GetFallback("Common")
        local fallbackPlant = PlantData.GetPlant(fallbackId)

        table.insert(data.Inventory.Plants, {
            PlantId = fallbackId,
            Quality = 1,
            Traits = {},
            MutatedAt = os.time(),
        })

        return false, "No known combination! Fallback: " .. (fallbackPlant and fallbackPlant.Name or fallbackId)
    end

    -- Calculate success chance
    local chance = MutationRecipes.CalculateChance(recipe, catalystId, plotMutationMult, soilMutationMult)
    chance = chance + pruneBonus

    -- Roll!
    local roll = math.random()
    local success = roll <= chance

    if success then
        -- Successful mutation!
        local resultPlant = PlantData.GetPlant(recipe.Result)

        -- Quality: average of inputs, with catalyst bonus
        local resultQuality = math.floor((plant1.Quality + plant2.Quality) / 2)

        -- Catalyst: Suncrystal boosts quality
        if catalystId == "Suncrystal" then
            resultQuality = math.min(5, resultQuality + MutationRecipes.Catalysts.Suncrystal.Value)
        end
        -- Catalyst: WormCompost min quality
        if catalystId == "WormCompost" then
            resultQuality = math.max(resultQuality, MutationRecipes.Catalysts.WormCompost.Value)
        end

        -- Trait inheritance + new trait chance
        local resultTraits = {}

        -- Inherit one random trait from parents
        local parentTraits = {}
        for _, t in ipairs(plant1.Traits or {}) do table.insert(parentTraits, t) end
        for _, t in ipairs(plant2.Traits or {}) do table.insert(parentTraits, t) end

        if #parentTraits > 0 then
            local inheritedTrait = parentTraits[math.random(1, #parentTraits)]
            table.insert(resultTraits, inheritedTrait)
        end

        -- Chance for new random trait
        if math.random() < Config.Plants.TraitChance then
            local newTrait = PlantData.GetRandomTrait(recipe.Result)
            if newTrait and not table.find(resultTraits, newTrait) then
                table.insert(resultTraits, newTrait)
            end
        end

        -- Add result to inventory
        table.insert(data.Inventory.Plants, {
            PlantId = recipe.Result,
            Quality = resultQuality,
            Traits = resultTraits,
            MutatedFrom = { plant1.PlantId, plant2.PlantId },
            MutatedAt = os.time(),
        })

        -- Update discovery
        local isNewDiscovery = not data.Plantdex[recipe.Result]
        data.Plantdex[recipe.Result] = true
        data.Stats.MutationsDiscovered = data.Stats.MutationsDiscovered + 1

        local xpAmount = Config.Economy.XP.Mutation
        if isNewDiscovery then
            xpAmount = xpAmount + Config.Economy.XP.NewDiscovery
        end
        DataManager.AddXP(player, xpAmount)

        local msg = "Mutation successful! " .. resultPlant.Name
        if #resultTraits > 0 then
            msg = msg .. " [Traits: " .. table.concat(resultTraits, ", ") .. "]"
        end
        if isNewDiscovery then
            msg = msg .. " ★ NEW DISCOVERY! ★"
        end

        return true, msg

    else
        -- Failed mutation: fallback plant
        local inputRarity = PlantData.GetPlant(plant1.PlantId).Rarity
        local fallbackId = MutationRecipes.GetFallback(inputRarity)
        local fallbackPlant = PlantData.GetPlant(fallbackId)

        table.insert(data.Inventory.Plants, {
            PlantId = fallbackId,
            Quality = math.max(1, math.floor((plant1.Quality + plant2.Quality) / 2) - 1),
            Traits = {},
            MutatedAt = os.time(),
        })

        local chancePercent = math.floor(chance * 100)
        return false, "Mutation failed (" .. chancePercent .. "% chance). Fallback: " ..
            (fallbackPlant and fallbackPlant.Name or fallbackId)
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

    remotes.AttemptMutation.OnServerEvent:Connect(function(player, plantIndex1, plantIndex2, catalystId)
        if not rateCheck(player) then return end
        if type(plantIndex1) ~= "number" or type(plantIndex2) ~= "number" then return end
        if catalystId ~= nil and type(catalystId) ~= "string" then return end
        MutationEngine.AttemptMutation(player, plantIndex1, plantIndex2, catalystId)
    end)
end

-- ============================================================
-- START
-- ============================================================

createRemotes()
setupRemoteHandlers()

return MutationEngine
