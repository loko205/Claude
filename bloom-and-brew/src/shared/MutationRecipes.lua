--[[
    MutationRecipes.lua — Plant mutation recipes & catalysts
    Mutation Lab unlocked at Level 5: 2 plants + optional catalyst → result
]]

local Config = require(script.Parent.Config)

local MutationRecipes = {}

-- ============================================================
-- MUTATION RECIPES
-- Format: { Input1, Input2 } → Result (with success rate)
-- ============================================================

MutationRecipes.Recipes = {

    -- ======== COMMON → RARE ========
    {
        Inputs = { "mondkraut", "flammenblatt" },
        Result = "irrlichtwurzel",
        BaseChance = 0.30,
        Desc = "Moonlight + Fire = a wild glow that never fades",
    },
    {
        Inputs = { "nebelranke", "sternmoos" },
        Result = "frostbluete",
        BaseChance = 0.25,
        Desc = "Mist + stellar cold = eternal ice in blossom form",
    },
    {
        Inputs = { "flammenblatt", "sternmoos" },
        Result = "donnerknospe",
        BaseChance = 0.30,
        Desc = "Fire + star energy = pure lightning in a bud",
    },
    {
        Inputs = { "mondkraut", "nebelranke" },
        Result = "frostbluete",
        BaseChance = 0.28,
        Desc = "Moon chill + mist = crystal-clear ice",
    },
    {
        Inputs = { "schattenlilie", "mondkraut" },
        Result = "irrlichtwurzel",
        BaseChance = 0.35,
        Desc = "Shadow + moon = a light that leads you astray",
    },

    -- ======== COMMON → UNCOMMON ========
    {
        Inputs = { "mondkraut", "sternmoos" },
        Result = "kristallgras",
        BaseChance = 0.40,
        Desc = "Moonlight crystallizes the star spores",
    },
    {
        Inputs = { "flammenblatt", "schattenlilie" },
        Result = "sonnentau",
        BaseChance = 0.38,
        Desc = "Fire + shadow = golden sundrop",
    },
    {
        Inputs = { "nebelranke", "flammenblatt" },
        Result = "windblume",
        BaseChance = 0.35,
        Desc = "Mist + heat = an eternal breeze in blossom form",
    },

    -- ======== RARE → EPIC ========
    {
        Inputs = { "irrlichtwurzel", "frostbluete" },
        Result = "voidfarn",
        BaseChance = 0.22,
        Desc = "Wisp + frost = a crack in reality",
    },
    {
        Inputs = { "donnerknospe", "irrlichtwurzel" },
        Result = "sturmranke",
        BaseChance = 0.20,
        Desc = "Thunder + wisp = an electric storm",
    },
    {
        Inputs = { "frostbluete", "donnerknospe" },
        Result = "phoenixkelch",
        BaseChance = 0.22,
        Desc = "Ice + lightning = from destruction, new life grows",
    },

    -- ======== EPIC → LEGENDARY ========
    {
        Inputs = { "voidfarn", "phoenixkelch" },
        Result = "galaxienblume",
        BaseChance = 0.14,
        Desc = "Void + phoenix = a new star is born",
    },
    {
        Inputs = { "sturmranke", "voidfarn" },
        Result = "zeitlotus",
        BaseChance = 0.12,
        Desc = "Storm + void = time itself bends",
    },
    {
        Inputs = { "phoenixkelch", "sturmranke" },
        Result = "galaxienblume",
        BaseChance = 0.13,
        Desc = "Phoenix + storm = cosmic rebirth",
    },

    -- ======== LEGENDARY → MYTHIC (requires Rainbow Essence as catalyst!) ========
    {
        Inputs = { "galaxienblume", "zeitlotus" },
        Result = "weltbaumsetzling",
        BaseChance = 0.04,
        RequiresCatalyst = "RainbowEssence",
        Desc = "Galaxy + time = the seed of the universe",
    },
    {
        Inputs = { "zeitlotus", "galaxienblume" },
        Result = "ewige_essenz",
        BaseChance = 0.03,
        RequiresCatalyst = "RainbowEssence",
        Desc = "Time + stars = something that always was",
    },
}

-- ============================================================
-- CATALYSTS
-- ============================================================

MutationRecipes.Catalysts = {
    Moonstone = {
        Id = "Moonstone",
        Name = "Moonstone",
        Desc = "A silvery stone that stores moonlight. Increases the chance of rarer results.",
        Effect = "RarityBoost",
        Value = 0.10, -- +10% success rate
        Cost = 200,
        Rarity = "Uncommon",
    },
    Suncrystal = {
        Id = "Suncrystal",
        Name = "Sun Crystal",
        Desc = "A golden crystal brimming with solar energy. The result will be at least 3-star.",
        Effect = "QualityBoost",
        Value = 1, -- +1 quality tier
        Cost = 350,
        Rarity = "Rare",
    },
    RainbowEssence = {
        Id = "RainbowEssence",
        Name = "Rainbow Essence",
        Desc = "Shimmers in every color. The only way to get Mythic plants. Extremely rare!",
        Effect = "MythicUnlock",
        Value = true,
        Cost = 2000,
        Rarity = "Legendary",
    },
    WormCompost = {
        Id = "WormCompost",
        Name = "Worm Compost",
        Desc = "Made by the world's most diligent worms. Guarantees at least 3-star quality.",
        Effect = "MinQuality",
        Value = 3, -- Min 3-star
        Cost = 150,
        Rarity = "Common",
    },
    ExperimentalSerum = {
        Id = "ExperimentalSerum",
        Name = "Experimental Serum",
        Desc = "Nobody knows what's in it. The result? Completely random. Good luck!",
        Effect = "Random",
        Value = true,
        Cost = 100,
        Rarity = "Uncommon",
    },
}

-- ============================================================
-- FALLBACK TABLE
-- On failed mutation, the player receives one of these plants back
-- ============================================================

MutationRecipes.Fallbacks = {
    Common = { "mondkraut", "sternmoos" },
    Uncommon = { "kristallgras", "windblume" },
    Rare = { "mondkraut", "flammenblatt", "sternmoos" }, -- Degraded result
    Epic = { "irrlichtwurzel", "donnerknospe" },         -- Degraded result
    Legendary = { "voidfarn", "phoenixkelch" },           -- Degraded result
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Find a recipe that matches two plant inputs (order-independent)
function MutationRecipes.FindRecipe(plantId1, plantId2)
    for _, recipe in ipairs(MutationRecipes.Recipes) do
        local a, b = recipe.Inputs[1], recipe.Inputs[2]
        if (a == plantId1 and b == plantId2) or (a == plantId2 and b == plantId1) then
            return recipe
        end
    end
    return nil
end

-- Calculate final mutation chance with catalyst and plot modifiers
function MutationRecipes.CalculateChance(recipe, catalystId, plotMutationMult, soilMutationMult)
    local chance = recipe.BaseChance

    -- Catalyst bonus
    if catalystId then
        local catalyst = MutationRecipes.Catalysts[catalystId]
        if catalyst and catalyst.Effect == "RarityBoost" then
            chance = chance + catalyst.Value
        end
    end

    -- Plot and soil multipliers
    chance = chance * (plotMutationMult or 1.0) * (soilMutationMult or 1.0)

    return math.min(chance, 0.95) -- Cap at 95%
end

-- Get a random fallback plant for failed mutation based on input rarity
function MutationRecipes.GetFallback(inputRarity)
    local pool = MutationRecipes.Fallbacks[inputRarity] or MutationRecipes.Fallbacks.Common
    return pool[math.random(1, #pool)]
end

-- Check if a recipe requires a specific catalyst
function MutationRecipes.RequiresCatalyst(recipe, catalystId)
    if not recipe.RequiresCatalyst then
        return true -- No catalyst required
    end
    return recipe.RequiresCatalyst == catalystId
end

return MutationRecipes
