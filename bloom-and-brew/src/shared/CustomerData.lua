--[[
    CustomerData.lua — NPC-Kundentypen, Auftragslogik & Dialoge
    5 Kundentypen mit eigener Persönlichkeit, Anforderungen und Belohnungen.
    NPCs wollen sowohl Pflanzen als auch Tränke (mit Reinheits-Anforderungen).
]]

local Config = require(script.Parent.Config)

local CustomerData = {}

-- ============================================================
-- KUNDENTYPEN
-- ============================================================

CustomerData.Types = {

    Dorfbewohner = {
        Id = "Dorfbewohner",
        Name = "Dorfbewohner",
        Desc = "Einfache Leute mit einfachen Wünschen. Aber hey, jeder fängt mal klein an!",
        MinRep = Config.Customers.Types.Dorfbewohner.MinRep,
        RewardMult = Config.Customers.Types.Dorfbewohner.RewardMult,
        Timer = Config.Customers.Types.Dorfbewohner.Timer,
        Color = Color3.fromRGB(139, 195, 74),

        -- Was sie wollen können
        OrderTemplates = {
            { Type = "Plant", Rarity = "Common", MinAmount = 1, MaxAmount = 3, MinQuality = 1 },
            { Type = "Potion", Tier = "Starter", MinAmount = 1, MaxAmount = 1, MinPurity = 0 },
        },

        -- Belohnungs-Extras (zusätzlich zu Coins)
        BonusRewards = {},

        -- Persönlichkeit
        Personality = "Freundlich, einfach, dankbar",
    },

    Heiler = {
        Id = "Heiler",
        Name = "Heiler",
        Desc = "Braucht Tränke für seine Patienten. Qualität zählt — Menschenleben und so!",
        MinRep = Config.Customers.Types.Heiler.MinRep,
        RewardMult = Config.Customers.Types.Heiler.RewardMult,
        Timer = Config.Customers.Types.Heiler.Timer,
        Color = Color3.fromRGB(76, 175, 80),

        OrderTemplates = {
            { Type = "Potion", Tier = "Starter", MinAmount = 1, MaxAmount = 2, MinPurity = 50 },
            { Type = "Potion", Tier = "Fortgeschritten", MinAmount = 1, MaxAmount = 1, MinPurity = 50 },
        },

        BonusRewards = {
            { Type = "RecipeHint", Chance = 0.15 },
        },

        Personality = "Warmherzig, besorgt, wissend",
    },

    Adeliger = {
        Id = "Adeliger",
        Name = "Adeliger",
        Desc = "Nur das Beste für den feinen Herrn! Reinheit ist alles, Bürgerchen.",
        MinRep = Config.Customers.Types.Adeliger.MinRep,
        RewardMult = Config.Customers.Types.Adeliger.RewardMult,
        Timer = Config.Customers.Types.Adeliger.Timer,
        Color = Color3.fromRGB(255, 215, 0),

        OrderTemplates = {
            { Type = "Potion", Tier = "Fortgeschritten", MinAmount = 1, MaxAmount = 2, MinPurity = 70 },
            { Type = "Potion", Tier = "Selten", MinAmount = 1, MaxAmount = 1, MinPurity = 70 },
        },

        BonusRewards = {
            { Type = "RareSeed", Chance = 0.20 },
        },

        Personality = "Herablassend, anspruchsvoll, großzügig wenn zufrieden",
    },

    Hexenmeister = {
        Id = "Hexenmeister",
        Name = "Hexenmeister",
        Desc = "Flüstert mehr als er spricht. Will Dinge die man besser nicht hinterfragt.",
        MinRep = Config.Customers.Types.Hexenmeister.MinRep,
        RewardMult = Config.Customers.Types.Hexenmeister.RewardMult,
        Timer = Config.Customers.Types.Hexenmeister.Timer,
        Color = Color3.fromRGB(156, 39, 176),

        OrderTemplates = {
            { Type = "Potion", Tier = "Selten", MinAmount = 1, MaxAmount = 1, MinPurity = 85, RequireTrait = true },
            { Type = "Potion", Tier = "Fortgeschritten", MinAmount = 2, MaxAmount = 2, MinPurity = 85 },
        },

        BonusRewards = {
            { Type = "Catalyst", Chance = 0.30 },
        },

        Personality = "Geheimnisvoll, leise, wissend",
    },

    DerSchatten = {
        Id = "DerSchatten",
        Name = "Der Schatten",
        Desc = "???",
        MinRep = Config.Customers.Types.DerSchatten.MinRep,
        RewardMult = Config.Customers.Types.DerSchatten.RewardMult,
        Timer = Config.Customers.Types.DerSchatten.Timer,
        Color = Color3.fromRGB(33, 33, 33),

        OrderTemplates = {
            { Type = "Potion", Tier = "Legendaer", MinAmount = 1, MaxAmount = 1, MinPurity = 95 },
        },

        BonusRewards = {
            { Type = "MythicSeed", Chance = 0.50 },
        },

        Personality = "Rätselhaft, kurze Sätze, bedrohlich aber fair",
    },
}

-- Reihenfolge (für UI + Spawning)
CustomerData.TypeOrder = { "Dorfbewohner", "Heiler", "Adeliger", "Hexenmeister", "DerSchatten" }

-- ============================================================
-- NPC-DIALOGE (Deutsch, mit Persönlichkeit)
-- ============================================================

CustomerData.Dialogues = {

    Dorfbewohner = {
        Greeting = {
            "Hallo! Hast du vielleicht ein paar Kräuter für mich?",
            "Oh, ein Alchemist! Meine Oma schwört auf Mondkraut-Tee!",
            "Entschuldigung... ich bräuchte da was für meinen Garten...",
            "Hey! Hast du was gegen Schnecken? Die fressen mir alles weg!",
            "Ich hab gehört du hast die besten Pflanzen im ganzen Dorf!",
        },
        Accept = {
            "Super, danke dir! Du bist ein Lebensretter!",
            "Perfekt! Genau das hab ich gesucht!",
            "Wow, sieht richtig gut aus! Danke!",
            "Meine Oma wird sich so freuen! Danke!",
        },
        Decline = {
            "Oh... naja, vielleicht nächstes Mal.",
            "Schade. Ich frag mal den anderen Alchemisten...",
            "Kein Problem, ich komm später wieder!",
        },
        Timeout = {
            "Ich muss leider los... vielleicht beim nächsten Mal!",
            "Naja, war wohl nichts. Tschüss!",
        },
    },

    Heiler = {
        Greeting = {
            "Guten Tag! Ich brauche dringend Tränke für meine Patienten.",
            "Ah, endlich ein fähiger Alchemist! Meine Vorräte sind fast leer.",
            "Hast du etwas gegen Kopfschmerzen? Also... magische Kopfschmerzen.",
            "Die Reinheit muss stimmen — meine Patienten verdienen nur das Beste!",
            "Kannst du mir helfen? Ein Kind im Dorf hat sich in einen Frosch verwandelt...",
        },
        Accept = {
            "Ausgezeichnet! Die Reinheit ist perfekt. Meine Patienten danken dir!",
            "Wunderbar! Damit kann ich vielen helfen. Hier, nimm das als Dank.",
            "Das rettet Leben! Danke, wirklich!",
            "Hervorragende Arbeit! Vielleicht zeig ich dir mal eins meiner Rezepte...",
        },
        Decline = {
            "Die Reinheit reicht leider nicht... meine Patienten brauchen Besseres.",
            "Hm, das ist mir nicht rein genug. Tut mir leid.",
            "Ich brauche mindestens 50% Reinheit. Versuch's nochmal!",
        },
        Timeout = {
            "Ich muss zu meinen Patienten... die können nicht länger warten!",
            "Die Zeit drängt! Ich muss woanders suchen.",
        },
    },

    Adeliger = {
        Greeting = {
            "HÖR mal her, Bürgerchen. Ich brauche etwas... Exquisites.",
            "Mein letzter Alchemist hat mich SEHR enttäuscht. Enttäusch mich nicht.",
            "Ich zahle fürstlich — aber nur für fürstliche Qualität!",
            "*schnippt mit den Fingern* Du da! Hast du seltene Tränke?",
            "Ein Adeliger wie ich trinkt nur kristallreine Tränke. Mindestens!",
        },
        Accept = {
            "Hm. Akzeptabel. Hier ist dein Gold. Mach so weiter.",
            "*nickt anerkennend* Nicht schlecht für einen Bürgerlichen!",
            "Endlich jemand der Qualität versteht! Nimm diesen seltenen Samen.",
            "DAS nenne ich einen Trank! Du steigst in meiner Gunst.",
        },
        Decline = {
            "*rümpft die Nase* Das soll Qualität sein? Lächerlich!",
            "Ich bin tief enttäuscht. Komm wieder wenn du es besser kannst.",
            "Meine Pferde trinken reinere Tränke als DAS hier.",
        },
        Timeout = {
            "*dreht sich um und geht* Meine Zeit ist kostbarer als dein ganzer Laden.",
            "Unfähig UND langsam. Beeindruckend negativ.",
        },
    },

    Hexenmeister = {
        Greeting = {
            "*flüstert* ...ich brauche etwas. Etwas Besonderes.",
            "Die Sterne stehen günstig. Hast du... was ich suche?",
            "Frag nicht wozu. Liefere einfach.",
            "Ich spüre Macht in deinem Labor... lass sie mich schmecken.",
            "*erscheint aus dem Nichts* ...ich habe einen Auftrag für dich.",
        },
        Accept = {
            "*nickt langsam* Die Potenz stimmt. Du hast Talent... nutze es weise.",
            "Yesss... genau das. Hier, nimm diesen Katalysator. Du wirst ihn brauchen.",
            "*grinst* Besser als erwartet. Ich komme wieder.",
            "Die Reinheit... *schließt die Augen* ...exquisit.",
        },
        Decline = {
            "*schüttelt den Kopf* Nicht potent genug. Ich brauche MEHR.",
            "Das ist... enttäuschend. Ich hatte mehr von dir erwartet.",
            "Ohne den richtigen Trait ist dieser Trank wertlos für mich.",
        },
        Timeout = {
            "*löst sich in Schatten auf* ...die Gelegenheit ist verstrichen.",
            "*verschwindet* ...du hast mich warten lassen. Das vergesse ich nicht.",
        },
    },

    DerSchatten = {
        Greeting = {
            "...",
            "Du weißt was ich will.",
            "Perfektion. Nichts weniger.",
            "Die Zeit läuft. Schnell.",
            "Zeig mir deinen besten Trank. Jetzt.",
        },
        Accept = {
            "Gut. Sehr gut. *legt einen schimmernden Samen hin* Verdient.",
            "...*nickt einmal*...",
            "Du hast Potenzial. Seltenes Potenzial.",
            "Perfekt. *der Samen leuchtet mythisch* Nutze ihn weise.",
        },
        Decline = {
            "Nein.",
            "Nicht rein genug. *verschwindet*",
            "Enttäuschend.",
        },
        Timeout = {
            "*ist plötzlich weg*",
            "Zu langsam. *Schatten verschlucken die Gestalt*",
        },
    },
}

-- ============================================================
-- AUFTRAGS-GENERIERUNG
-- ============================================================

-- Generate a random order for a customer type
-- Returns: { CustomerType, Items = { {Type, ItemId, Amount, MinPurity, MinQuality} }, Reward, Timer }
function CustomerData.GenerateOrder(customerTypeId, playerLevel, playerRep)
    local customerType = CustomerData.Types[customerTypeId]
    if not customerType then return nil end

    -- Pick random order template
    local template = customerType.OrderTemplates[math.random(1, #customerType.OrderTemplates)]

    local amount = math.random(template.MinAmount, template.MaxAmount)

    local order = {
        CustomerType = customerTypeId,
        Type = template.Type,
        Amount = amount,
        MinPurity = template.MinPurity or 0,
        MinQuality = template.MinQuality or 1,
        RequireTrait = template.RequireTrait or false,
        Timer = customerType.Timer,
        RewardMult = customerType.RewardMult,
        -- Specific item will be filled by CustomerManager based on available data
        Tier = template.Tier,
        Rarity = template.Rarity,
    }

    return order
end

-- Get available customer types for a player's reputation level
function CustomerData.GetAvailableTypes(playerRep)
    local available = {}
    for _, typeId in ipairs(CustomerData.TypeOrder) do
        local ct = CustomerData.Types[typeId]
        if playerRep >= ct.MinRep then
            table.insert(available, typeId)
        end
    end
    return available
end

-- Get a random dialogue line for a customer action
function CustomerData.GetDialogue(customerTypeId, action)
    local dialogues = CustomerData.Dialogues[customerTypeId]
    if not dialogues then return "..." end

    local lines = dialogues[action]
    if not lines or #lines == 0 then return "..." end

    return lines[math.random(1, #lines)]
end

return CustomerData
