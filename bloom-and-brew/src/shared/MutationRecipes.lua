--[[
    MutationRecipes.lua — Pflanzen-Mutations-Rezepte & Katalysatoren
    Mutations-Labor ab Level 5: 2 Pflanzen + optionaler Katalysator → Ergebnis
]]

local Config = require(script.Parent.Config)

local MutationRecipes = {}

-- ============================================================
-- MUTATIONS-REZEPTE
-- Format: { Input1, Input2 } → Result (mit Erfolgsrate)
-- ============================================================

MutationRecipes.Recipes = {

    -- ======== COMMON → RARE ========
    {
        Inputs = { "mondkraut", "flammenblatt" },
        Result = "irrlichtwurzel",
        BaseChance = 0.30,
        Desc = "Mondlicht + Feuer = ein irres Leuchten das niemals erlischt",
    },
    {
        Inputs = { "nebelranke", "sternmoos" },
        Result = "frostbluete",
        BaseChance = 0.25,
        Desc = "Nebel + Sternenkälte = ewiges Eis in Blütenform",
    },
    {
        Inputs = { "flammenblatt", "sternmoos" },
        Result = "donnerknospe",
        BaseChance = 0.30,
        Desc = "Feuer + Sternenenergie = purer Blitz in einer Knospe",
    },
    {
        Inputs = { "mondkraut", "nebelranke" },
        Result = "frostbluete",
        BaseChance = 0.28,
        Desc = "Mondkälte + Nebel = kristallklares Eis",
    },
    {
        Inputs = { "schattenlilie", "mondkraut" },
        Result = "irrlichtwurzel",
        BaseChance = 0.35,
        Desc = "Schatten + Mond = ein Licht das in die Irre führt",
    },

    -- ======== COMMON → UNCOMMON ========
    {
        Inputs = { "mondkraut", "sternmoos" },
        Result = "kristallgras",
        BaseChance = 0.40,
        Desc = "Mondlicht kristallisiert die Sternsporen",
    },
    {
        Inputs = { "flammenblatt", "schattenlilie" },
        Result = "sonnentau",
        BaseChance = 0.38,
        Desc = "Feuer + Schatten = goldener Sonnentropfen",
    },
    {
        Inputs = { "nebelranke", "flammenblatt" },
        Result = "windblume",
        BaseChance = 0.35,
        Desc = "Nebel + Hitze = ein ewiger Wind in Blütenform",
    },

    -- ======== RARE → EPIC ========
    {
        Inputs = { "irrlichtwurzel", "frostbluete" },
        Result = "voidfarn",
        BaseChance = 0.22,
        Desc = "Irrlicht + Frost = ein Riss in der Realität",
    },
    {
        Inputs = { "donnerknospe", "irrlichtwurzel" },
        Result = "sturmranke",
        BaseChance = 0.20,
        Desc = "Donner + Irrlicht = ein elektrischer Sturm",
    },
    {
        Inputs = { "frostbluete", "donnerknospe" },
        Result = "phoenixkelch",
        BaseChance = 0.22,
        Desc = "Eis + Blitz = aus der Zerstörung wächst Neues",
    },

    -- ======== EPIC → LEGENDARY ========
    {
        Inputs = { "voidfarn", "phoenixkelch" },
        Result = "galaxienblume",
        BaseChance = 0.14,
        Desc = "Void + Phönix = ein neuer Stern wird geboren",
    },
    {
        Inputs = { "sturmranke", "voidfarn" },
        Result = "zeitlotus",
        BaseChance = 0.12,
        Desc = "Sturm + Void = die Zeit selbst verbiegt sich",
    },
    {
        Inputs = { "phoenixkelch", "sturmranke" },
        Result = "galaxienblume",
        BaseChance = 0.13,
        Desc = "Phönix + Sturm = kosmische Wiedergeburt",
    },

    -- ======== LEGENDARY → MYTHIC (braucht Regenbogen-Essenz als Katalysator!) ========
    {
        Inputs = { "galaxienblume", "zeitlotus" },
        Result = "weltbaumsetzling",
        BaseChance = 0.04,
        RequiresCatalyst = "RegenbogenEssenz",
        Desc = "Galaxie + Zeit = der Samen des Universums",
    },
    {
        Inputs = { "zeitlotus", "galaxienblume" },
        Result = "ewige_essenz",
        BaseChance = 0.03,
        RequiresCatalyst = "RegenbogenEssenz",
        Desc = "Zeit + Sterne = etwas das schon immer da war",
    },
}

-- ============================================================
-- KATALYSATOREN
-- ============================================================

MutationRecipes.Catalysts = {
    Mondstein = {
        Id = "Mondstein",
        Name = "Mondstein",
        Desc = "Ein silbriger Stein der das Mondlicht speichert. Erhöht die Chance auf seltenere Ergebnisse.",
        Effect = "RarityBoost",
        Value = 0.10, -- +10% Erfolgsrate
        Cost = 200,
        Rarity = "Uncommon",
    },
    Sonnenkristall = {
        Id = "Sonnenkristall",
        Name = "Sonnenkristall",
        Desc = "Goldener Kristall voller Sonnenenergie. Das Ergebnis wird mindestens ★★★.",
        Effect = "QualityBoost",
        Value = 1, -- +1 Qualitätsstufe
        Cost = 350,
        Rarity = "Rare",
    },
    RegenbogenEssenz = {
        Id = "RegenbogenEssenz",
        Name = "Regenbogen-Essenz",
        Desc = "Schillert in allen Farben. Einziger Weg zu Mythic-Pflanzen. Extrem selten!",
        Effect = "MythicUnlock",
        Value = true,
        Cost = 2000,
        Rarity = "Legendary",
    },
    Wurmkompost = {
        Id = "Wurmkompost",
        Name = "Wurmkompost",
        Desc = "Von den fleißigsten Würmern der Welt. Garantiert mindestens ★★★ Qualität.",
        Effect = "MinQuality",
        Value = 3, -- Min ★★★
        Cost = 150,
        Rarity = "Common",
    },
    ExperimentellesSerum = {
        Id = "ExperimentellesSerum",
        Name = "Experimentelles Serum",
        Desc = "Niemand weiß was drin ist. Das Ergebnis? Völlig zufällig. Viel Glück!",
        Effect = "Random",
        Value = true,
        Cost = 100,
        Rarity = "Uncommon",
    },
}

-- ============================================================
-- FALLBACK-TABELLE
-- Bei fehlgeschlagener Mutation bekommt man eine dieser Pflanzen zurück
-- ============================================================

MutationRecipes.Fallbacks = {
    Common = { "mondkraut", "sternmoos" },
    Uncommon = { "kristallgras", "windblume" },
    Rare = { "mondkraut", "flammenblatt", "sternmoos" }, -- Degraded result
    Epic = { "irrlichtwurzel", "donnerknospe" },         -- Degraded result
    Legendary = { "voidfarn", "phoenixkelch" },           -- Degraded result
}

-- ============================================================
-- HILFSFUNKTIONEN
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
