--[[
    ProcessingData.lua — Verarbeitungssystem für Bloom & Brew
    5 Methoden um Pflanzen zu Extrakten zu verarbeiten:
    Trocknen → Mörsern → Pressen → Destillieren → Äther-Extraktion

    Jede Pflanze braucht die richtige Methode für optimale Ausbeute.
    Falsche Methode = Pflanze zerstört!
]]

local Config = require(script.Parent.Config)

local ProcessingData = {}

-- ============================================================
-- VERARBEITUNGSMETHODEN
-- ============================================================

ProcessingData.Methods = {
    Trocknen = {
        Id = "Trocknen",
        Name = "Trocknen",
        MachineName = "Trockengestell",
        Desc = "Hänge die Pflanze kopfüber auf und lass die Luft ihre Arbeit machen. Wie Wäsche, nur magischer.",
        LongDesc = "Die älteste und einfachste Methode der Wirkstoffgewinnung. Die Pflanze wird an einem luftigen Ort aufgehängt, bis die Feuchtigkeit entwichen ist und die Wirkstoffe konzentriert zurückbleiben. Perfekt für Blätter und Kräuter.",
        Icon = "rbxassetid://0", -- Placeholder
        Cost = Config.Processing.Methods.Trocknen.Cost,
        LevelReq = Config.Processing.Methods.Trocknen.LevelReq,
        BaseDuration = Config.Processing.Methods.Trocknen.BaseDuration,
        Category = "Einfach",
        OutputType = "Getrocknete Blätter/Kräuter",
    },

    Moersern = {
        Id = "Moersern",
        Name = "Mörsern",
        MachineName = "Steinmörser",
        Desc = "Stampf die Pflanze zu feinem Pulver. Armtraining inklusive!",
        LongDesc = "Mit dem schweren Steinmörser werden Pflanzenteile zerrieben und zerstoßen. So werden Sporen freigesetzt, kristalline Strukturen gebrochen und verborgene Wirkstoffe zugänglich gemacht. Ideal für harte, feste Pflanzenteile.",
        Icon = "rbxassetid://0",
        Cost = Config.Processing.Methods.Moersern.Cost,
        LevelReq = Config.Processing.Methods.Moersern.LevelReq,
        BaseDuration = Config.Processing.Methods.Moersern.BaseDuration,
        Category = "Einfach",
        OutputType = "Pulver/Sporen",
    },

    Pressen = {
        Id = "Pressen",
        Name = "Pressen",
        MachineName = "Pflanzenpresse",
        Desc = "Quetsche jeden Tropfen Saft raus. Die Pflanze wird's überleben — naja, eigentlich nicht.",
        LongDesc = "Die mechanische Presse extrahiert Säfte, Öle und Nektare aus saftigen Pflanzenteilen. Durch kontrollierten Druck werden flüssige Wirkstoffe gewonnen, ohne sie durch Hitze zu zerstören. Perfekt für Blüten und fleischige Pflanzen.",
        Icon = "rbxassetid://0",
        Cost = Config.Processing.Methods.Pressen.Cost,
        LevelReq = Config.Processing.Methods.Pressen.LevelReq,
        BaseDuration = Config.Processing.Methods.Pressen.BaseDuration,
        Category = "Fortgeschritten",
        OutputType = "Öl/Saft/Nektar",
    },

    Destillieren = {
        Id = "Destillieren",
        Name = "Destillieren",
        MachineName = "Destille",
        Desc = "Dampf rein, Magie raus. Wie Kochen, aber mit mehr Wissenschaft und weniger Essen.",
        LongDesc = "Durch erhitzen und kontrolliertes Auffangen des Dampfes werden flüchtige ätherische Substanzen extrahiert. Die Destille trennt Wirkstoffe präzise nach Siedepunkt — das reinste Verfahren für empfindliche, gasförmige oder hitzelösliche Substanzen.",
        Icon = "rbxassetid://0",
        Cost = Config.Processing.Methods.Destillieren.Cost,
        LevelReq = Config.Processing.Methods.Destillieren.LevelReq,
        BaseDuration = Config.Processing.Methods.Destillieren.BaseDuration,
        Category = "Fortgeschritten",
        OutputType = "Destillat/Ätherisches Öl",
    },

    AetherExtraktion = {
        Id = "AetherExtraktion",
        Name = "Äther-Extraktion",
        MachineName = "Äther-Extraktor",
        Desc = "Zieht die magische Essenz direkt aus der Pflanze. Sieht SO cool aus.",
        LongDesc = "Der Äther-Extraktor nutzt konzentrierte magische Energie um nicht-physische Wirkstoffe aus Pflanzen zu lösen. Nur diese Methode kann Void-Energie, Sternenlicht oder Zeitessenz extrahieren. Die teuerste, aber auch mächtigste Methode.",
        Icon = "rbxassetid://0",
        Cost = Config.Processing.Methods.AetherExtraktion.Cost,
        LevelReq = Config.Processing.Methods.AetherExtraktion.LevelReq,
        BaseDuration = Config.Processing.Methods.AetherExtraktion.BaseDuration,
        Category = "Meister",
        OutputType = "Magische Essenz",
    },
}

-- Reihenfolge der Methoden (für UI-Sortierung)
ProcessingData.MethodOrder = { "Trocknen", "Moersern", "Pressen", "Destillieren", "AetherExtraktion" }

-- ============================================================
-- MASCHINEN-UPGRADES
-- ============================================================

ProcessingData.Upgrades = {}
for i, level in ipairs(Config.Processing.UpgradeLevels) do
    ProcessingData.Upgrades[i] = {
        Level = i,
        Name = level.Name,
        PotencyMult = level.PotencyMult,
        DurationMult = level.DurationMult,
        YieldBonus = level.YieldBonus,
        CostMult = level.CostMult,
    }
end

-- ============================================================
-- HILFSFUNKTIONEN
-- ============================================================

-- Get processing method data by ID
function ProcessingData.GetMethod(methodId)
    return ProcessingData.Methods[methodId]
end

-- Calculate processing duration with machine upgrades
function ProcessingData.GetDuration(methodId, machineLevel)
    local method = ProcessingData.Methods[methodId]
    if not method then return 0 end

    local upgrade = Config.Processing.UpgradeLevels[machineLevel or 1]
    return method.BaseDuration * (upgrade and upgrade.DurationMult or 1.0)
end

-- Calculate extract potency from plant quality and processing method
-- plantQuality: 1-5 (stars)
-- methodEfficiency: 0.0-1.0 (1.0 = primary method, <1.0 = alternative)
-- machineLevel: 1-3
function ProcessingData.CalculatePotency(plantQuality, methodEfficiency, machineLevel)
    local qualityMult = ({ 1.0, 1.2, 1.5, 2.0, 3.0 })[plantQuality] or 1.0
    local upgrade = Config.Processing.UpgradeLevels[machineLevel or 1]
    local machineMult = upgrade and upgrade.PotencyMult or 1.0

    -- Potenz = Pflanzenqualität × Methoden-Effizienz × Maschinen-Bonus
    local potency = qualityMult * methodEfficiency * machineMult

    -- Clamp 0-1 (normalisiert auf max = ★5 + Primär + Meister-Maschine)
    local maxPotency = 3.0 * 1.0 * 1.3 -- ★5 × 100% × Meister
    return math.min(potency / maxPotency, 1.0)
end

-- Calculate extract yield (how many extract units from one plant)
function ProcessingData.GetYield(plantData, machineLevel, hasTrait)
    local baseYield = 1
    local upgrade = Config.Processing.UpgradeLevels[machineLevel or 1]
    local bonusYield = upgrade and upgrade.YieldBonus or 0

    -- Trait "Gigantisch" = 2x yield
    if hasTrait then
        baseYield = baseYield * 2
    end

    return baseYield + bonusYield
end

-- Get the upgrade cost for a specific machine method and target level
function ProcessingData.GetUpgradeCost(methodId, targetLevel)
    local method = ProcessingData.Methods[methodId]
    if not method then return 0 end

    local upgrade = Config.Processing.UpgradeLevels[targetLevel]
    if not upgrade then return 0 end

    return method.Cost * upgrade.CostMult
end

-- Check if player can use a specific processing method (level check)
function ProcessingData.CanPlayerUse(methodId, playerLevel)
    local method = ProcessingData.Methods[methodId]
    if not method then return false end
    return playerLevel >= method.LevelReq
end

-- Get all methods available at a given player level
function ProcessingData.GetAvailableMethods(playerLevel)
    local available = {}
    for _, methodId in ipairs(ProcessingData.MethodOrder) do
        if ProcessingData.CanPlayerUse(methodId, playerLevel) then
            table.insert(available, methodId)
        end
    end
    return available
end

return ProcessingData
