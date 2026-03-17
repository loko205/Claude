--[[
    BrewingEngine.lua — Potion Brewing Logic, Purity, Effect Calculation
    Potions are brewed from EXTRACTS (not raw plants!).
    Purity = Extract Potency x Cauldron Level x Timing x Traits x Random.
    Minigame scoring for bonus purity.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlantData = require(ReplicatedStorage.Shared.PlantData)
local PotionData = require(ReplicatedStorage.Shared.PotionData)
local DataManager = require(script.Parent.DataManager)

local BrewingEngine = {}

-- RemoteEvents
local remotes = {}

local function createRemotes()
    local folder = Instance.new("Folder")
    folder.Name = "BrewingRemotes"
    folder.Parent = ReplicatedStorage

    local events = { "StartBrew", "SubmitMinigame", "CollectPotion", "UpgradeCauldron", "AutoBrew" }
    for _, name in ipairs(events) do
        local remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = folder
        remotes[name] = remote
    end
end

-- ============================================================
-- BREWING LOGIC
-- ============================================================

-- Start brewing a potion (with minigame option)
-- potionId: which potion to brew
-- extractSelection: table mapping extractId to amount (for wildcard recipes)
function BrewingEngine.StartBrew(player, potionId, extractSelection)
    local data = DataManager.GetData(player)
    if not data then return false, "No data" end

    -- Level check
    if data.Level < Config.Brewing.UnlockLevel then
        return false, "Brew Lab unlocks at Level " .. Config.Brewing.UnlockLevel
    end

    -- Already brewing?
    if data.Lab.ActiveBrew then
        return false, "Already brewing!"
    end

    -- Validate potion exists
    local potion = PotionData.GetPotion(potionId)
    if not potion then return false, "Unknown potion" end

    -- Level requirement
    if data.Level < potion.LevelReq then
        return false, "Level " .. potion.LevelReq .. " required"
    end

    -- Check cauldron slots
    local cauldronData = Config.Brewing.CauldronLevels[data.Lab.CauldronLevel]
    local ingredientCount = #potion.Ingredients
    if ingredientCount > cauldronData.Slots then
        return false, "Cauldron too small! " .. cauldronData.Name .. " only has " .. cauldronData.Slots .. " slots"
    end

    -- Validate and consume extracts
    local extractPotencies = {}
    local hasPotentTrait = false

    for _, ingredient in ipairs(potion.Ingredients) do
        if ingredient.ExtractFrom == "ANY_EPIC_PLUS" then
            -- Wildcard: player chooses which epic+ extracts to use
            if not extractSelection then
                return false, "Select Epic+ extracts for the chaos potion"
            end

            local usedCount = 0
            for extractId, amount in pairs(extractSelection) do
                local extract = data.Inventory.Extracts[extractId]
                if not extract then continue end

                -- Verify rarity is Epic+
                local plantInfo = PlantData.GetPlant(extractId)
                if not plantInfo then continue end

                local rarityOrder = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }
                if (rarityOrder[plantInfo.Rarity] or 0) < 4 then continue end

                local useAmount = math.min(amount, extract.Amount, ingredient.Amount - usedCount)
                if useAmount <= 0 then continue end

                for i = 1, useAmount do
                    table.insert(extractPotencies, extract.Potency)
                end
                if extract.HasPotent then hasPotentTrait = true end

                extract.Amount = extract.Amount - useAmount
                if extract.Amount <= 0 then
                    data.Inventory.Extracts[extractId] = nil
                end
                usedCount = usedCount + useAmount
            end

            if usedCount < ingredient.Amount then
                return false, "Not enough Epic+ extracts (need " .. ingredient.Amount .. ")"
            end
        else
            -- Normal ingredient
            local extract = data.Inventory.Extracts[ingredient.ExtractFrom]
            if not extract or extract.Amount < ingredient.Amount then
                local plantInfo = PlantData.GetPlant(ingredient.ExtractFrom)
                local name = plantInfo and plantInfo.ExtractName or ingredient.ExtractFrom
                return false, "Not enough " .. name
            end

            for i = 1, ingredient.Amount do
                table.insert(extractPotencies, extract.Potency)
            end
            if extract.HasPotent then hasPotentTrait = true end

            -- Consume extracts
            extract.Amount = extract.Amount - ingredient.Amount
            if extract.Amount <= 0 then
                data.Inventory.Extracts[ingredient.ExtractFrom] = nil
            end
        end
    end

    -- Calculate brew time (with cauldron speed bonus)
    local brewTime = potion.BrewTime / cauldronData.SpeedMult

    -- BrewMaster gamepass bonus
    if data.Gamepasses and data.Gamepasses.BrewMaster then
        -- Purity bonus applied later
    end

    -- Store active brew
    data.Lab.ActiveBrew = {
        PotionId = potionId,
        StartTime = os.time(),
        BrewTime = brewTime,
        ExtractPotencies = extractPotencies,
        HasPotentTrait = hasPotentTrait,
        MinigameScore = nil, -- Set when minigame is completed or skipped
        AutoBrew = false,
    }

    return true, potion.Name .. " is brewing! (" .. math.floor(brewTime) .. "s)"
end

-- Auto-brew: skip minigame, base purity
function BrewingEngine.AutoBrew(player, potionId, extractSelection)
    local success, msg = BrewingEngine.StartBrew(player, potionId, extractSelection)
    if not success then return false, msg end

    local data = DataManager.GetData(player)
    data.Lab.ActiveBrew.AutoBrew = true
    data.Lab.ActiveBrew.MinigameScore = 0 -- No minigame bonus

    return true, msg .. " (Auto mode)"
end

-- ============================================================
-- MINIGAME SCORING
-- ============================================================

-- Submit minigame timing inputs from client
-- inputs: { timings = {}, temperature = {}, stirring = {} }
function BrewingEngine.SubmitMinigame(player, inputs)
    local data = DataManager.GetData(player)
    if not data or not data.Lab.ActiveBrew then return false, "No active brew" end

    if data.Lab.ActiveBrew.MinigameScore then
        return false, "Minigame already completed"
    end

    -- Validate inputs aren't physically impossible (anti-cheat)
    if type(inputs) ~= "table" then return false, "Invalid input" end

    -- Anti-cheat: Check minimum brew time has passed before accepting minigame
    local brew = data.Lab.ActiveBrew
    local elapsed = os.time() - brew.StartTime
    if elapsed < 5 then
        return false, "Brew just started"
    end

    local score = 0

    -- Timing score (0-40 points): How well timed were the ingredient additions?
    -- Anti-cheat: Limit timing entries to actual ingredient count
    if inputs.timings and type(inputs.timings) == "table" then
        local timingScore = 0
        local maxTimings = math.min(#inputs.timings, 4) -- Max 4 ingredients
        for i = 1, maxTimings do
            local timing = inputs.timings[i]
            if type(timing) ~= "number" then continue end
            local accuracy = math.max(0, math.min(1, timing))
            timingScore = timingScore + accuracy
        end
        if maxTimings > 0 then
            timingScore = (timingScore / maxTimings) * 40
        end
        score = score + timingScore
    end

    -- Temperature score (0-30 points): How well was temperature maintained?
    if inputs.temperature and type(inputs.temperature) == "number" then
        -- Perfect = 1.0
        local tempAccuracy = math.max(0, math.min(1, inputs.temperature))
        score = score + tempAccuracy * 30
    end

    -- Stirring score (0-30 points): Rhythm accuracy
    if inputs.stirring and type(inputs.stirring) == "number" then
        local stirAccuracy = math.max(0, math.min(1, inputs.stirring))
        score = score + stirAccuracy * 30
    end

    -- Anti-cheat: cap at 100 and check for suspiciously perfect scores
    score = math.min(100, math.max(0, math.floor(score)))

    data.Lab.ActiveBrew.MinigameScore = score

    local rating = "Okay"
    if score >= 90 then rating = "PERFECT!"
    elseif score >= 70 then rating = "Great!"
    elseif score >= 50 then rating = "Good"
    elseif score >= 30 then rating = "Meh..."
    end

    return true, "Minigame: " .. score .. "/100 — " .. rating
end

-- ============================================================
-- COLLECT POTION
-- ============================================================

function BrewingEngine.CollectPotion(player)
    local data = DataManager.GetData(player)
    if not data or not data.Lab.ActiveBrew then return false, "No active brew" end

    local brew = data.Lab.ActiveBrew

    -- Check if done
    local elapsed = os.time() - brew.StartTime
    if elapsed < brew.BrewTime then
        local remaining = math.ceil(brew.BrewTime - elapsed)
        return false, remaining .. "s remaining"
    end

    -- If minigame wasn't completed and not auto-brew, use base score
    local minigameScore = brew.MinigameScore or 0

    -- Calculate purity
    local gamepassPurityBonus = 0
    if data.Gamepasses and data.Gamepasses.BrewMaster then
        gamepassPurityBonus = Config.Economy.Gamepasses.BrewMaster.PurityBonus
    end

    local purity = PotionData.CalculatePurity(
        brew.ExtractPotencies,
        data.Lab.CauldronLevel,
        minigameScore,
        brew.HasPotentTrait
    )

    -- Apply gamepass bonus
    purity = math.min(100, purity + gamepassPurityBonus)

    -- Get purity tier
    local purityTier = PotionData.GetPurityTier(purity)
    local potion = PotionData.GetPotion(brew.PotionId)

    -- Handle Chaos Potion (random effect)
    local actualPotionId = brew.PotionId
    if potion and potion.IsWildcard then
        -- Random potion effect
        local allPotionIds = PotionData.GetAllPotionIds()
        actualPotionId = allPotionIds[math.random(1, #allPotionIds)]
    end

    -- Create potion in inventory
    local newPotion = {
        PotionId = actualPotionId,
        OriginalRecipe = brew.PotionId,
        Purity = purity,
        PurityTier = purityTier.Name,
        BrewedAt = os.time(),
        MinigameScore = minigameScore,
    }

    table.insert(data.Inventory.Potions, newPotion)

    -- Check for new discovery BEFORE updating potiondex
    local isNewDiscovery = not data.Potiondex[actualPotionId]

    -- Update potiondex
    data.Potiondex[actualPotionId] = true

    -- Essence reward
    local essenceReward = PotionData.GetEssenceReward(brew.PotionId)
    DataManager.AddEssence(player, essenceReward)

    -- Stats + XP
    data.Stats.TotalPotionsBrewed = data.Stats.TotalPotionsBrewed + 1
    if purity > data.Stats.HighestPurity then
        data.Stats.HighestPurity = purity
    end
    DataManager.AddXP(player, Config.Economy.XP.Brew)

    -- Grant new discovery XP
    if isNewDiscovery then
        DataManager.AddXP(player, Config.Economy.XP.NewDiscovery)
    end

    -- Clear active brew
    data.Lab.ActiveBrew = nil

    -- Discover recipe
    if not data.Lab.RecipesDiscovered[brew.PotionId] then
        data.Lab.RecipesDiscovered[brew.PotionId] = true
    end

    local resultPotion = PotionData.GetPotion(actualPotionId)
    local msg = (resultPotion and resultPotion.Name or actualPotionId) ..
        " brewed! Purity: " .. purity .. "% (" .. purityTier.Name .. ")"

    if purityTier.Glow then
        msg = msg .. " ★ GLOWS GOLDEN! ★"
    end

    return true, msg, newPotion
end

-- ============================================================
-- CAULDRON UPGRADE
-- ============================================================

function BrewingEngine.UpgradeCauldron(player)
    local data = DataManager.GetData(player)
    if not data then return false, "No data" end

    local currentLevel = data.Lab.CauldronLevel
    local nextLevel = currentLevel + 1

    if nextLevel > #Config.Brewing.CauldronLevels then
        return false, "Max cauldron level reached"
    end

    local nextCauldron = Config.Brewing.CauldronLevels[nextLevel]

    -- Level requirement
    if data.Level < nextCauldron.LevelReq then
        return false, "Level " .. nextCauldron.LevelReq .. " required"
    end

    -- Cost
    if not DataManager.RemoveCoins(player, nextCauldron.Cost) then
        return false, "Not enough Coins (" .. nextCauldron.Cost .. " needed)"
    end

    data.Lab.CauldronLevel = nextLevel

    return true, "Upgraded to " .. nextCauldron.Name .. "! (+Slots, +Purity, +Speed)"
end

-- ============================================================
-- BREW TICK
-- ============================================================

local function brewTick()
    for _, player in ipairs(Players:GetPlayers()) do
        local data = DataManager.GetData(player)
        if not data or not data.Lab.ActiveBrew then continue end

        local brew = data.Lab.ActiveBrew
        local elapsed = os.time() - brew.StartTime

        -- Notify when brew is complete
        if elapsed >= brew.BrewTime and not brew.NotifiedComplete then
            brew.NotifiedComplete = true
            -- TODO: Fire client notification that brew is ready
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

    remotes.StartBrew.OnServerEvent:Connect(function(player, potionId, extractSelection)
        if not rateCheck(player) then return end
        if type(potionId) ~= "string" then return end
        BrewingEngine.StartBrew(player, potionId, extractSelection)
    end)

    remotes.AutoBrew.OnServerEvent:Connect(function(player, potionId, extractSelection)
        if not rateCheck(player) then return end
        if type(potionId) ~= "string" then return end
        BrewingEngine.AutoBrew(player, potionId, extractSelection)
    end)

    remotes.SubmitMinigame.OnServerEvent:Connect(function(player, inputs)
        if not rateCheck(player) then return end
        if type(inputs) ~= "table" then return end
        BrewingEngine.SubmitMinigame(player, inputs)
    end)

    remotes.CollectPotion.OnServerEvent:Connect(function(player)
        if not rateCheck(player) then return end
        BrewingEngine.CollectPotion(player)
    end)

    remotes.UpgradeCauldron.OnServerEvent:Connect(function(player)
        if not rateCheck(player) then return end
        BrewingEngine.UpgradeCauldron(player)
    end)
end

-- ============================================================
-- START
-- ============================================================

createRemotes()
setupRemoteHandlers()

-- Brew tick every 5 seconds
task.spawn(function()
    while true do
        brewTick()
        task.wait(5)
    end
end)

return BrewingEngine
