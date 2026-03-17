--[[
    Balancing.lua — Dokumentation aller Balancing-Zielwerte
    Nicht als Laufzeit-Modul gedacht, sondern als Design-Referenz.
    Alle tatsächlichen Werte stehen in Config.lua!
]]

local Balancing = {}

-- ============================================================
-- EINNAHMEN PRO STUNDE (Zielwerte)
-- ============================================================

Balancing.IncomePerHour = {
    -- Level 1-5: Einstieg, lernt die Grundmechaniken
    -- Haupteinnahme: Pflanzen verkaufen + erste NPC-Aufträge
    -- Ziel: ~100-200 Coins/Stunde
    Early = {
        PlantSales = 80,      -- 8 Ernten × 10 Coins avg
        NPCOrders = 75,       -- 3 Aufträge × 25 Coins avg
        DailyLogin = 50,      -- Wenn einmal am Tag
        Total = "~200 Coins/h",
        Note = "Genug für 1-2 Samenkäufe pro Stunde",
    },

    -- Level 5-15: Brau-Labor + erste Tränke + Mutation
    -- Ziel: ~500-1000 Coins/Stunde
    Mid = {
        PlantSales = 150,
        PotionSales = 300,    -- Starter-Tränke an NPCs
        NPCOrders = 200,      -- Heiler-Aufträge
        PlayerTrade = 100,    -- Erste Spieler-Verkäufe
        Total = "~750 Coins/h",
        Note = "Maschinen amortisieren sich in 1-3h Spielzeit",
    },

    -- Level 15-30: Fortgeschrittene Tränke + Auktionshaus
    -- Ziel: ~2000-5000 Coins/Stunde
    Late = {
        PotionSales = 1500,   -- Fortgeschrittene/Seltene Tränke
        NPCOrders = 800,      -- Adelige/Hexenmeister
        PlayerTrade = 500,    -- Aktiver Handel
        AuctionIncome = 200,
        Total = "~3000 Coins/h",
        Note = "Kessel-Upgrades und seltene Samen werden zugänglich",
    },

    -- Level 30+: Endgame
    -- Ziel: ~10000+ Coins/Stunde
    Endgame = {
        PotionSales = 5000,   -- Legendäre Tränke mit hoher Reinheit
        PlayerTrade = 3000,   -- Trankstand-Imperium
        NPCOrders = 2000,     -- Der Schatten!
        Total = "~10000+ Coins/h",
        Note = "Großmeister-Rang, Gilden-Aktivitäten",
    },
}

-- ============================================================
-- AUSGABEN / COIN-SINKS
-- ============================================================

Balancing.CoinSinks = {
    -- Ziel: ~60-70% der Einnahmen werden wieder ausgegeben
    -- Das hält die Wirtschaft stabil

    SeedCosts = "Laufend, 5-20 Coins pro Samen (Common)",
    PlotUpgrades = "500 → 1500 → 5000 → 15000 → 50000 (große Investitionen)",
    Machines = "50-5000 Coins (gestaffelt nach Level-Req)",
    MachineUpgrades = "3x und 8x Basiskosten (Verbessert/Meister)",
    CauldronUpgrades = "2000 → 8000 → 25000 → 75000",
    SoilUpgrades = "500 → 1500 → 3000",
    TradeTax = "5-10% auf alle Spieler-Transaktionen",
    Catalysts = "100-2000 Coins",

    -- Amortisationszeiten (Ziel)
    Amortization = {
        Trockengestell = "1-2 Verarbeitungen (50 Coins → schnell zurück)",
        Steinmoerser = "~5 Verarbeitungen (200 Coins)",
        Pflanzenpresse = "~8 Verarbeitungen (500 Coins)",
        Destille = "~15 Verarbeitungen (1500 Coins)",
        AetherExtraktor = "~10 Verarbeitungen (5000 Coins, aber Endgame-Tränke sind teuer)",
        Kupferkessel = "~10-15 Brau-Vorgänge",
        Silberkessel = "~15-20 Brau-Vorgänge",
    },
}

-- ============================================================
-- REINHEITS-VERTEILUNG
-- ============================================================

Balancing.PurityDistribution = {
    -- Ziel-Verteilung bei Level 10 mit Basis-Setup:
    -- Verdünnt (0-30%):   ~5%  der Tränke (nur bei schlechten Pflanzen + kein Minigame)
    -- Unrein (31-50%):    ~15% der Tränke
    -- Standard (51-70%):  ~40% der Tränke (häufigster Bereich)
    -- Rein (71-85%):      ~25% der Tränke (mit gutem Minigame)
    -- Kristallrein (86-95%): ~12% der Tränke (★★★★+ Pflanzen + Minigame + Potent)
    -- Perfekt (96-100%):  ~3%  der Tränke (★★★★★ + Meister-Kessel + perfektes Minigame)

    Note = "Perfekte Tränke sollen SELTEN und WERTVOLL sein. Der 5x Wert-Multiplikator motiviert dazu, in bessere Maschinen und Minigame-Skill zu investieren.",

    -- Reinheits-Formel: (avgPotency * 60) + cauldronBonus + minigameBonus + potentBonus ± 5
    -- Max theoretisch: 60 + 20 + 20 + 15 + 5 = 120 (gecapped auf 100)
    -- Realistisch mit ★★★ + Basis-Kessel + 50/100 Minigame: ~55%
    -- Mit ★★★★★ + Obsidian + Perfektes Minigame + Potent: ~95-100%
}

-- ============================================================
-- VERARBEITUNGSSYSTEM-BALANCE
-- ============================================================

Balancing.Processing = {
    -- Kernidee: Verarbeitung fügt Tiefe hinzu ohne zu nerven
    -- Level 1-3: Nur Trocknen nötig (Mondkraut = die erste Pflanze, braucht nur Trocknen)
    -- So lernt der Spieler das System mit der einfachsten Methode

    DesignPrinciples = {
        "Starter-Pflanzen brauchen IMMER die einfachste verfügbare Methode",
        "Seltenere Pflanzen brauchen fortgeschrittenere Methoden → natürliche Progression",
        "Alternative Methoden sind ein Fallback, nicht der Standard",
        "Falsche Methode = Pflanze weg → motiviert zum Lesen der Pflanzenbeschreibung",
        "Maschinen-Upgrades sind SPÜRBAR aber nicht ZWINGEND",
    },

    Progression = {
        "Level 1: Trockengestell kaufen (50 Coins = billig), Mondkraut trocknen",
        "Level 3: Steinmörser (200), Sternmoos mörsern → erste ★★ Tränke möglich",
        "Level 8: Pflanzenpresse (500), Flammenblatt/Frostblüte pressen → bessere Extrakte",
        "Level 15: Destille (1500), Nebelranke/Irrlichtwurzel destillieren → seltene Tränke",
        "Level 25: Äther-Extraktor (5000), Voidfarn/Galaxienblume → Endgame-Tränke",
    },
}

-- ============================================================
-- XP-KURVE
-- ============================================================

Balancing.XPCurve = {
    -- Formel: BaseXP(100) × Level^1.5
    -- Level 1→2:   100 XP  (~10 Ernten)
    -- Level 5→6:   1118 XP (~45 Ernten oder ~45 Brau-Vorgänge)
    -- Level 10→11: 3162 XP
    -- Level 20→21: 8944 XP
    -- Level 50→51: 35355 XP
    -- Level 100:   ~100000 XP

    Note = "Level 10 soll nach ~3-5h Spielzeit erreichbar sein. Level 25 nach ~20h. Level 50 nach ~100h. Level 100 ist Langzeit-Ziel (300h+).",

    XPSources = {
        "Ernten (+10): Am häufigsten, niedrigster Wert",
        "Verarbeiten (+5): Bonus für die neue Mechanik",
        "Brauen (+15): Belohnt das Kern-Feature",
        "NPC-Aufträge (+25): Belohnt komplette Ketten",
        "Spieler-Verkauf (+20): Belohnt soziale Interaktion",
        "Mutation (+50): Seltener, höherer Wert",
        "Neue Entdeckung (+100): Großer Bonus, motiviert Exploration",
    },
}

-- ============================================================
-- MONETARISIERUNG
-- ============================================================

Balancing.Monetization = {
    -- Ziel: Fair. Kein P2W. Premium = Zeitersparnis.
    -- Alle Items sind erspielbar. Gamepasses beschleunigen um 40-60%.

    VIPAlchemist = "+50% Coins. Bei 3000 Coins/h Endgame = +1500 Coins/h. Signifikant aber nicht gamebreaking.",
    AutoGiesser = "Spart ~30s pro Pflanze pro Gieß-Zyklus. Quality-of-Life.",
    DoppelteErnte = "2x Ertrag = 2x Extrakte = 2x Tränke. Stärkster Gamepass für Farmer.",
    ExtraPlots = "+2 Plots = +18 Felder. Mehr Anbaufläche = mehr Einkommen.",
    Braumeister = "+15% Reinheit-Grundbonus. Verschiebt die Purity-Kurve nach oben. Kein Pflicht-Kauf!",
    ErweiterterStand = "+3 Stand-Slots. Mehr Verkaufsmöglichkeiten für aktive Händler.",

    FairnessCheck = {
        "OHNE Gamepass: Perfekte Tränke sind möglich (★★★★★ + Obsidian + Minigame + Potent)",
        "MIT Gamepass: Perfekte Tränke sind EINFACHER (Braumeister gibt +15% Puffer)",
        "Keine exklusiven Items hinter Paywall",
        "Keine Lootboxen, keine Gacha-Mechaniken",
    },
}

return Balancing
