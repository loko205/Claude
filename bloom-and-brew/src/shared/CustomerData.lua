--[[
    CustomerData.lua — NPC customer types, order logic & dialogues
    5 customer types with unique personalities, requirements, and rewards.
    NPCs want both plants and potions (with purity requirements).
]]

local Config = require(script.Parent.Config)

local CustomerData = {}

-- ============================================================
-- CUSTOMER TYPES
-- ============================================================

CustomerData.Types = {

    Villager = {
        Id = "Villager",
        Name = "Villager",
        Desc = "Simple folk with simple wishes. But hey, everyone starts somewhere!",
        MinRep = Config.Customers.Types.Villager.MinRep,
        RewardMult = Config.Customers.Types.Villager.RewardMult,
        Timer = Config.Customers.Types.Villager.Timer,
        Color = Color3.fromRGB(139, 195, 74),

        -- What they can request
        OrderTemplates = {
            { Type = "Plant", Rarity = "Common", MinAmount = 1, MaxAmount = 3, MinQuality = 1 },
            { Type = "Potion", Tier = "Starter", MinAmount = 1, MaxAmount = 1, MinPurity = 0 },
        },

        -- Bonus rewards (in addition to coins)
        BonusRewards = {},

        -- Personality
        Personality = "Friendly, simple, grateful",
    },

    Healer = {
        Id = "Healer",
        Name = "Healer",
        Desc = "Needs potions for his patients. Quality matters — lives are at stake!",
        MinRep = Config.Customers.Types.Healer.MinRep,
        RewardMult = Config.Customers.Types.Healer.RewardMult,
        Timer = Config.Customers.Types.Healer.Timer,
        Color = Color3.fromRGB(76, 175, 80),

        OrderTemplates = {
            { Type = "Potion", Tier = "Starter", MinAmount = 1, MaxAmount = 2, MinPurity = 50 },
            { Type = "Potion", Tier = "Advanced", MinAmount = 1, MaxAmount = 1, MinPurity = 50 },
        },

        BonusRewards = {
            { Type = "RecipeHint", Chance = 0.15 },
        },

        Personality = "Warmhearted, caring, knowledgeable",
    },

    Noble = {
        Id = "Noble",
        Name = "Noble",
        Desc = "Only the finest for this distinguished gentleman! Purity is everything, commoner.",
        MinRep = Config.Customers.Types.Noble.MinRep,
        RewardMult = Config.Customers.Types.Noble.RewardMult,
        Timer = Config.Customers.Types.Noble.Timer,
        Color = Color3.fromRGB(255, 215, 0),

        OrderTemplates = {
            { Type = "Potion", Tier = "Advanced", MinAmount = 1, MaxAmount = 2, MinPurity = 70 },
            { Type = "Potion", Tier = "Rare", MinAmount = 1, MaxAmount = 1, MinPurity = 70 },
        },

        BonusRewards = {
            { Type = "RareSeed", Chance = 0.20 },
        },

        Personality = "Condescending, demanding, generous when pleased",
    },

    Warlock = {
        Id = "Warlock",
        Name = "Warlock",
        Desc = "Whispers more than he speaks. Wants things you'd best not question.",
        MinRep = Config.Customers.Types.Warlock.MinRep,
        RewardMult = Config.Customers.Types.Warlock.RewardMult,
        Timer = Config.Customers.Types.Warlock.Timer,
        Color = Color3.fromRGB(156, 39, 176),

        OrderTemplates = {
            { Type = "Potion", Tier = "Rare", MinAmount = 1, MaxAmount = 1, MinPurity = 85, RequireTrait = true },
            { Type = "Potion", Tier = "Advanced", MinAmount = 2, MaxAmount = 2, MinPurity = 85 },
        },

        BonusRewards = {
            { Type = "Catalyst", Chance = 0.30 },
        },

        Personality = "Mysterious, quiet, knowing",
    },

    TheShadow = {
        Id = "TheShadow",
        Name = "The Shadow",
        Desc = "???",
        MinRep = Config.Customers.Types.TheShadow.MinRep,
        RewardMult = Config.Customers.Types.TheShadow.RewardMult,
        Timer = Config.Customers.Types.TheShadow.Timer,
        Color = Color3.fromRGB(33, 33, 33),

        OrderTemplates = {
            { Type = "Potion", Tier = "Legendary", MinAmount = 1, MaxAmount = 1, MinPurity = 95 },
        },

        BonusRewards = {
            { Type = "MythicSeed", Chance = 0.50 },
        },

        Personality = "Enigmatic, short sentences, threatening but fair",
    },
}

-- Order (for UI + Spawning)
CustomerData.TypeOrder = { "Villager", "Healer", "Noble", "Warlock", "TheShadow" }

-- ============================================================
-- NPC DIALOGUES (English, with personality)
-- ============================================================

CustomerData.Dialogues = {

    Villager = {
        Greeting = {
            "Hello! Do you have some herbs for me, by any chance?",
            "Oh, an alchemist! My grandma swears by moonwort tea!",
            "Excuse me... I could use something for my garden...",
            "Hey! Got anything for slugs? They're eating everything I have!",
            "I heard you grow the best plants in the whole village!",
        },
        Accept = {
            "Great, thank you! You're a lifesaver!",
            "Perfect! That's exactly what I was looking for!",
            "Wow, looks really good! Thanks!",
            "My grandma is going to be so happy! Thank you!",
        },
        Decline = {
            "Oh... well, maybe next time.",
            "Too bad. I'll ask the other alchemist...",
            "No worries, I'll come back later!",
        },
        Timeout = {
            "I have to go... maybe next time!",
            "Well, guess it wasn't meant to be. Bye!",
        },
    },

    Healer = {
        Greeting = {
            "Good day! I urgently need potions for my patients.",
            "Ah, finally a capable alchemist! My supplies are nearly empty.",
            "Do you have something for headaches? Well... magical headaches.",
            "The purity must be right — my patients deserve only the best!",
            "Can you help me? A child in the village turned himself into a frog...",
        },
        Accept = {
            "Excellent! The purity is perfect. My patients thank you!",
            "Wonderful! This will help so many people. Here, take this as thanks.",
            "This saves lives! Thank you, truly!",
            "Outstanding work! Perhaps I'll show you one of my recipes sometime...",
        },
        Decline = {
            "The purity isn't good enough, I'm afraid... my patients need better.",
            "Hm, that's not pure enough for me. Sorry.",
            "I need at least 50% purity. Give it another try!",
        },
        Timeout = {
            "I must get back to my patients... they can't wait any longer!",
            "Time is running out! I'll have to look elsewhere.",
        },
    },

    Noble = {
        Greeting = {
            "LISTEN here, commoner. I require something... Exquisite.",
            "My last alchemist disappointed me GREATLY. Do not disappoint me.",
            "I pay handsomely — but only for handsome quality!",
            "*snaps fingers* You there! Do you have rare potions?",
            "A noble like myself drinks only crystal-pure potions. At the very least!",
        },
        Accept = {
            "Hm. Acceptable. Here is your gold. Keep it up.",
            "*nods approvingly* Not bad for a commoner!",
            "Finally someone who understands quality! Take this rare seed.",
            "NOW that is what I call a potion! You are rising in my favor.",
        },
        Decline = {
            "*wrinkles nose* You call THIS quality? Laughable!",
            "I am deeply disappointed. Return when you can do better.",
            "My horses drink purer potions than THIS.",
        },
        Timeout = {
            "*turns and leaves* My time is worth more than your entire shop.",
            "Incompetent AND slow. Impressively dreadful.",
        },
    },

    Warlock = {
        Greeting = {
            "*whispers* ...I need something. Something special.",
            "The stars are aligned. Do you have... what I seek?",
            "Don't ask what for. Just deliver.",
            "I sense power in your laboratory... let me taste it.",
            "*appears from nowhere* ...I have a task for you.",
        },
        Accept = {
            "*nods slowly* The potency is right. You have talent... use it wisely.",
            "Yesss... exactly that. Here, take this catalyst. You will need it.",
            "*grins* Better than expected. I shall return.",
            "The purity... *closes eyes* ...exquisite.",
        },
        Decline = {
            "*shakes head* Not potent enough. I need MORE.",
            "That is... disappointing. I expected more from you.",
            "Without the right trait, this potion is worthless to me.",
        },
        Timeout = {
            "*dissolves into shadows* ...the opportunity has passed.",
            "*vanishes* ...you kept me waiting. I will not forget that.",
        },
    },

    TheShadow = {
        Greeting = {
            "...",
            "You know what I want.",
            "Perfection. Nothing less.",
            "Time is running. Quickly.",
            "Show me your finest potion. Now.",
        },
        Accept = {
            "Good. Very good. *places a shimmering seed down* Earned.",
            "...*nods once*...",
            "You have potential. Rare potential.",
            "Perfect. *the seed glows mythically* Use it wisely.",
        },
        Decline = {
            "No.",
            "Not pure enough. *vanishes*",
            "Disappointing.",
        },
        Timeout = {
            "*is suddenly gone*",
            "Too slow. *shadows swallow the figure*",
        },
    },
}

-- ============================================================
-- ORDER GENERATION
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
