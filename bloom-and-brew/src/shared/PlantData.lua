--[[
    PlantData.lua — Alle Pflanzendefinitionen für Bloom & Brew
    Jede Pflanze hat: Id, Name, Beschreibung, Rarität, Wachstumszeit,
    Basiswert, mögliche Traits, und Verarbeitungsmethode(n).
]]

local PlantData = {}

-- ============================================================
-- PFLANZENDEFINITIONEN
-- ============================================================

PlantData.Plants = {

    -- ======== COMMON (60%) ========

    mondkraut = {
        Id = "mondkraut",
        Name = "Mondkraut",
        Desc = "Leuchtet bei Vollmond so hell, dass Motten Schlange stehen. Riecht nach Mitternachtssnack.",
        Rarity = "Common",
        GrowthTime = 30,
        BaseValue = 10,
        SeedCost = 5,
        TraitPool = { "Leuchtend", "Schnellwachsend", "Potent", "Duftend" },
        -- Verarbeitung: Blätter trocknen lassen, Wirkung entfaltet sich an der Luft
        Processing = {
            Primary = "Trocknen",
            Alternative = nil,
        },
        ExtractName = "Getrocknetes Mondkraut",
        ExtractDesc = "Silbrig schimmernde Blättchen, knistert leise im Mondlicht",
    },

    flammenblatt = {
        Id = "flammenblatt",
        Name = "Flammenblatt",
        Desc = "Fasst sich warm an und würzt jede Suppe. Nicht empfohlen als Taschentuch.",
        Rarity = "Common",
        GrowthTime = 60,
        BaseValue = 15,
        SeedCost = 8,
        TraitPool = { "Leuchtend", "Gigantisch", "Potent", "Goldig" },
        -- Verarbeitung: Feueröl sitzt im Blattinneren — pressen!
        Processing = {
            Primary = "Pressen",
            Alternative = { Method = "Moersern", Efficiency = 0.6 },
        },
        ExtractName = "Flammenöl",
        ExtractDesc = "Orangerotes Öl das leicht flackert — Finger weg von offenen Flammen!",
    },

    nebelranke = {
        Id = "nebelranke",
        Name = "Nebelranke",
        Desc = "Wächst am liebsten im Nebel und verschwindet manchmal einfach. Wie meine Socken.",
        Rarity = "Common",
        GrowthTime = 90,
        BaseValue = 20,
        SeedCost = 12,
        TraitPool = { "Schnellwachsend", "Selbstgiessend", "Potent", "Unsterblich" },
        -- Verarbeitung: Flüchtige Nebelessenz muss durch Destillation aufgefangen werden
        Processing = {
            Primary = "Destillieren",
            Alternative = { Method = "Trocknen", Efficiency = 0.5 },
        },
        ExtractName = "Nebelessenz",
        ExtractDesc = "Durchsichtiger Tropfen der im Glas zu schweben scheint",
    },

    sternmoos = {
        Id = "sternmoos",
        Name = "Sternmoos",
        Desc = "Funkelt nachts wie ein Mini-Sternenhimmel. Schnecken lieben es — leider.",
        Rarity = "Common",
        GrowthTime = 120,
        BaseValue = 25,
        SeedCost = 15,
        TraitPool = { "Leuchtend", "Gigantisch", "Schnellwachsend", "Duftend" },
        -- Verarbeitung: Sporen im Moos müssen durch Mörsern freigesetzt werden
        Processing = {
            Primary = "Moersern",
            Alternative = { Method = "Trocknen", Efficiency = 0.7 },
        },
        ExtractName = "Sternstaub-Pulver",
        ExtractDesc = "Glitzerndes Pulver das an allem kleben bleibt. An. Allem.",
    },

    schattenlilie = {
        Id = "schattenlilie",
        Name = "Schattenlilie",
        Desc = "Blüht nur im Schatten und sieht dabei unfassbar dramatisch aus. Die Goth-Pflanze.",
        Rarity = "Common",
        GrowthTime = 180,
        BaseValue = 30,
        SeedCost = 20,
        TraitPool = { "Duftend", "Potent", "Goldig", "Unsterblich" },
        -- Verarbeitung: Dunkler Nektar in den Blütenblättern — pressen
        Processing = {
            Primary = "Pressen",
            Alternative = { Method = "Destillieren", Efficiency = 0.8 },
        },
        ExtractName = "Schattennektar",
        ExtractDesc = "Tintenschwarzer Sirup der das Licht um sich herum zu verschlucken scheint",
    },

    -- ======== UNCOMMON (25%) ========

    kristallgras = {
        Id = "kristallgras",
        Name = "Kristallgras",
        Desc = "Knirscht beim Laufen wie Chips. Sieht aus wie gefrorener Rasen, ist aber warm.",
        Rarity = "Uncommon",
        GrowthTime = 150,
        BaseValue = 45,
        SeedCost = 30,
        TraitPool = { "Leuchtend", "Gigantisch", "Goldig", "Potent" },
        Processing = {
            Primary = "Moersern",
            Alternative = nil,
        },
        ExtractName = "Kristallsplitter",
        ExtractDesc = "Winzige Kristalle die im Licht regenbogenfarben leuchten",
    },

    sonnentau = {
        Id = "sonnentau",
        Name = "Sonnentau",
        Desc = "Klebriger als Honig, süßer als Komplimente. Insekten finden ihn unwiderstehlich.",
        Rarity = "Uncommon",
        GrowthTime = 200,
        BaseValue = 50,
        SeedCost = 35,
        TraitPool = { "Selbstgiessend", "Duftend", "Schnellwachsend", "Potent" },
        Processing = {
            Primary = "Pressen",
            Alternative = { Method = "Trocknen", Efficiency = 0.6 },
        },
        ExtractName = "Goldtau-Sirup",
        ExtractDesc = "Zähflüssiger Sirup der im Sonnenlicht golden leuchtet",
    },

    windblume = {
        Id = "windblume",
        Name = "Windblume",
        Desc = "Weht auch ohne Wind. Ständig am Tanzen. Hat mehr Moves als du.",
        Rarity = "Uncommon",
        GrowthTime = 160,
        BaseValue = 40,
        SeedCost = 28,
        TraitPool = { "Schnellwachsend", "Leuchtend", "Duftend", "Unsterblich" },
        Processing = {
            Primary = "Destillieren",
            Alternative = { Method = "Pressen", Efficiency = 0.65 },
        },
        ExtractName = "Windessenz",
        ExtractDesc = "Eine Flasche die ständig vibriert — darin tobt ein Mini-Sturm",
    },

    -- ======== RARE (10%) ========

    irrlichtwurzel = {
        Id = "irrlichtwurzel",
        Name = "Irrlichtwurzel",
        Desc = "Leuchtet grünlich und führt einen im Kreis. GPS-Signal: Fehlanzeige.",
        Rarity = "Rare",
        GrowthTime = 240,
        BaseValue = 80,
        SeedCost = 60,
        TraitPool = { "Leuchtend", "Potent", "Gigantisch", "Goldig" },
        -- Verarbeitung: Ätherische Substanz nur durch Hitze lösbar
        Processing = {
            Primary = "Destillieren",
            Alternative = nil,
        },
        ExtractName = "Irrlicht-Destillat",
        ExtractDesc = "Grünlich leuchtende Flüssigkeit die im Dunkeln den Weg weist... oder auch nicht",
    },

    donnerknospe = {
        Id = "donnerknospe",
        Name = "Donnerknospe",
        Desc = "Knallt beim Aufblühen wie ein Mini-Gewitter. Nachbarn hassen diesen Trick!",
        Rarity = "Rare",
        GrowthTime = 300,
        BaseValue = 100,
        SeedCost = 75,
        TraitPool = { "Gigantisch", "Potent", "Leuchtend", "Schnellwachsend" },
        -- Verarbeitung: Kristalline Struktur muss zerbrochen werden
        Processing = {
            Primary = "Moersern",
            Alternative = { Method = "Pressen", Efficiency = 0.6 },
        },
        ExtractName = "Blitzpulver",
        ExtractDesc = "Knistert und knackt in der Dose. Nicht schütteln. NICHT. SCHÜTTELN.",
    },

    frostbluete = {
        Id = "frostbluete",
        Name = "Frostblüte",
        Desc = "Eiskalt und wunderschön. Wie mein Ex. Aber nützlicher.",
        Rarity = "Rare",
        GrowthTime = 280,
        BaseValue = 90,
        SeedCost = 70,
        TraitPool = { "Unsterblich", "Potent", "Duftend", "Goldig" },
        -- Verarbeitung: Eisessenz schmilzt — schnell pressen!
        Processing = {
            Primary = "Pressen",
            Alternative = nil,
        },
        ExtractName = "Frostessenz",
        ExtractDesc = "Eisblaues Öl das nie gefriert aber alles um sich herum abkühlt",
    },

    -- ======== EPIC (4%) ========

    voidfarn = {
        Id = "voidfarn",
        Name = "Voidfarn",
        Desc = "Sieht aus wie ein Loch in der Realität. Fass nicht rein. Ernst gemeint.",
        Rarity = "Epic",
        GrowthTime = 420,
        BaseValue = 200,
        SeedCost = 150,
        TraitPool = { "Potent", "Leuchtend", "Gigantisch", "Unsterblich" },
        -- Verarbeitung: Void-Energie nur magisch extrahierbar
        Processing = {
            Primary = "AetherExtraktion",
            Alternative = { Method = "Destillieren", Efficiency = 0.4 },
        },
        ExtractName = "Void-Extrakt",
        ExtractDesc = "Ein Tropfen absoluter Schwärze. Verschluckt Licht und Neugier gleichermaßen",
    },

    phoenixkelch = {
        Id = "phoenixkelch",
        Name = "Phoenixkelch",
        Desc = "Stirbt ab und wächst sofort neu. Hat mehr Comebacks als ein 90er-Boyband-Star.",
        Rarity = "Epic",
        GrowthTime = 480,
        BaseValue = 250,
        SeedCost = 180,
        TraitPool = { "Unsterblich", "Potent", "Leuchtend", "Goldig" },
        -- Verarbeitung: Phönixtränen verdampfen bei Berührung
        Processing = {
            Primary = "Destillieren",
            Alternative = { Method = "AetherExtraktion", Efficiency = 0.7 },
        },
        ExtractName = "Phönixträne",
        ExtractDesc = "Ein einzelner goldener Tropfen. Fühlt sich warm an wie eine Umarmung",
    },

    sturmranke = {
        Id = "sturmranke",
        Name = "Sturmranke",
        Desc = "Peitscht wild herum und macht Krawall. Der Punk unter den Pflanzen.",
        Rarity = "Epic",
        GrowthTime = 450,
        BaseValue = 220,
        SeedCost = 160,
        TraitPool = { "Schnellwachsend", "Gigantisch", "Potent", "Duftend" },
        -- Verarbeitung: Blitz-Saft in den Ranken
        Processing = {
            Primary = "Pressen",
            Alternative = { Method = "Moersern", Efficiency = 0.5 },
        },
        ExtractName = "Sturmsaft",
        ExtractDesc = "Elektrisch geladener Saft. Kribbelt auf der Zunge. Überall.",
    },

    -- ======== LEGENDARY (0.9%) ========

    galaxienblume = {
        Id = "galaxienblume",
        Name = "Galaxienblume",
        Desc = "In ihren Blütenblättern sieht man winzige Sterne. Bester Screensaver der Natur.",
        Rarity = "Legendary",
        GrowthTime = 600,
        BaseValue = 500,
        SeedCost = 400,
        TraitPool = { "Leuchtend", "Potent", "Goldig", "Unsterblich" },
        -- Verarbeitung: Sternenlicht-Essenz ist nicht physisch
        Processing = {
            Primary = "AetherExtraktion",
            Alternative = nil,
        },
        ExtractName = "Sternenstaub-Essenz",
        ExtractDesc = "Flüssiges Sternenlicht. Beleuchtet einen ganzen Raum wenn man das Fläschchen öffnet",
    },

    zeitlotus = {
        Id = "zeitlotus",
        Name = "Zeitlotus",
        Desc = "Blüht gleichzeitig in Vergangenheit und Zukunft. Ganz normal. Alles fein.",
        Rarity = "Legendary",
        GrowthTime = 720,
        BaseValue = 600,
        SeedCost = 500,
        TraitPool = { "Potent", "Unsterblich", "Leuchtend", "Goldig" },
        -- Verarbeitung: Zeitenergie braucht magischen Zugang
        Processing = {
            Primary = "AetherExtraktion",
            Alternative = { Method = "Destillieren", Efficiency = 0.3 },
        },
        ExtractName = "Zeitsand-Tinktur",
        ExtractDesc = "Fließt rückwärts im Glas. Oder vorwärts? Kommt drauf an wann du hinschaust",
    },

    -- ======== MYTHIC (0.1%) ========

    weltbaumsetzling = {
        Id = "weltbaumsetzling",
        Name = "Weltbaumsetzling",
        Desc = "Ein Baby-Weltbaum! Wird mal das Universum tragen. Jetzt erstmal Topfpflanze.",
        Rarity = "Mythic",
        GrowthTime = 900,
        BaseValue = 1000,
        SeedCost = 800,
        TraitPool = { "Gigantisch", "Unsterblich", "Potent", "Goldig", "Leuchtend" },
        -- Verarbeitung: Urkraft nur mit höchster Technik extrahierbar
        Processing = {
            Primary = "AetherExtraktion",
            Alternative = nil,
        },
        ExtractName = "Weltenmark",
        ExtractDesc = "Goldene Flüssigkeit die nach allem und nichts gleichzeitig riecht",
    },

    ewige_essenz = {
        Id = "ewige_essenz",
        Name = "Ewige Essenz",
        Desc = "Existiert schon seit vor dem Urknall. Hat die beste Work-Life-Balance aller Pflanzen.",
        Rarity = "Mythic",
        GrowthTime = 1200,
        BaseValue = 1500,
        SeedCost = 1200,
        TraitPool = { "Potent", "Unsterblich", "Leuchtend", "Goldig", "Gigantisch", "Duftend" },
        -- Verarbeitung: Reinste magische Substanz
        Processing = {
            Primary = "AetherExtraktion",
            Alternative = nil,
        },
        ExtractName = "Ewigkeits-Tropfen",
        ExtractDesc = "Ein Tropfen der nie verdunstet, nie gefriert, nie altert. Einfach... ewig",
    },
}

-- ============================================================
-- HILFSFUNKTIONEN
-- ============================================================

-- Returns plant data by ID
function PlantData.GetPlant(plantId)
    return PlantData.Plants[plantId]
end

-- Returns all plants of a specific rarity
function PlantData.GetPlantsByRarity(rarity)
    local result = {}
    for id, plant in pairs(PlantData.Plants) do
        if plant.Rarity == rarity then
            result[id] = plant
        end
    end
    return result
end

-- Returns a list of all plant IDs
function PlantData.GetAllPlantIds()
    local ids = {}
    for id in pairs(PlantData.Plants) do
        table.insert(ids, id)
    end
    return ids
end

-- Returns true if the plant can be processed with the given method
function PlantData.CanProcess(plantId, method)
    local plant = PlantData.Plants[plantId]
    if not plant then return false end

    if plant.Processing.Primary == method then
        return true, 1.0
    end

    if plant.Processing.Alternative and plant.Processing.Alternative.Method == method then
        return true, plant.Processing.Alternative.Efficiency
    end

    return false, 0
end

-- Returns the optimal processing method for a plant
function PlantData.GetPrimaryMethod(plantId)
    local plant = PlantData.Plants[plantId]
    if not plant then return nil end
    return plant.Processing.Primary
end

-- Pick a random trait from the plant's trait pool
function PlantData.GetRandomTrait(plantId)
    local plant = PlantData.Plants[plantId]
    if not plant or #plant.TraitPool == 0 then return nil end
    return plant.TraitPool[math.random(1, #plant.TraitPool)]
end

-- Calculate base quality (1-5 stars) with weighted random
function PlantData.RollQuality(qualityWeights)
    local weights = qualityWeights or { 40, 30, 20, 8, 2 }
    local total = 0
    for _, w in ipairs(weights) do
        total = total + w
    end

    local roll = math.random() * total
    local cumulative = 0
    for i, w in ipairs(weights) do
        cumulative = cumulative + w
        if roll <= cumulative then
            return i
        end
    end
    return 1
end

return PlantData
