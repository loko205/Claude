--[[
    CustomerDisplay.lua — NPC-Kunden Anzeige (STUB)
    Auftrags-Board, NPC-Dialog-Fenster, Timer-Anzeige.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local CustomerData = require(ReplicatedStorage.Shared.CustomerData)

local CustomerDisplay = {}
local player = Players.LocalPlayer

-- ============================================================
-- TODO: AUFTRAGS-BOARD
-- ============================================================
-- [ ] Auftrags-Board als 2D-UI (auf Holztafel-Hintergrund)
-- [ ] Max 8 Aufträge nebeneinander als "Zettel"
-- [ ] Jeder Zettel: Kundentyp-Icon, Item-Icon, Menge, Belohnung
-- [ ] Timer-Countdown pro Auftrag (rot wenn < 60s)
-- [ ] Reinheits-Anforderung als Balken (z.B. "min 70%")
-- [ ] "Erfüllen"-Button wenn Requirements erfüllt
-- [ ] "Ablehnen"-Button (grau, klein)
-- [ ] Auftrags-Schwierigkeit farbcodiert (grün → orange → rot)

-- ============================================================
-- TODO: NPC-DIALOG-FENSTER
-- ============================================================
-- [ ] Dialog-Box unten im Screen (visueller Roman-Stil)
-- [ ] NPC-Portrait links (je Kundentyp anderes Bild)
-- [ ] Name + Rang über dem Portrait
-- [ ] Typen-spezifische Farbgebung:
--     - Dorfbewohner: Grün, freundlich
--     - Heiler: Hellgrün, warm
--     - Adeliger: Gold, pompös
--     - Hexenmeister: Lila, mysteriös
--     - Der Schatten: Schwarz, minimal
-- [ ] Text-Typewriter-Effekt (Buchstabe für Buchstabe)
-- [ ] Antwort-Optionen: "Annehmen" / "Ablehnen"
-- [ ] Verschiedene Dialoge: Begrüßung, Annahme, Ablehnung, Timeout

-- ============================================================
-- TODO: NPC-MODELLE (3D)
-- ============================================================
-- [ ] Dorfbewohner: Bauer mit Strohhut, lächelnd
-- [ ] Heiler: Robe in Grüntönen, Stab mit Kristall
-- [ ] Adeliger: Königliche Kleidung, Krone/Monokel, erhobene Nase
-- [ ] Hexenmeister: Dunkle Kapuzenrobe, leuchtende Augen
-- [ ] Der Schatten: Kaum sichtbare Gestalt, nur Augen leuchten
-- [ ] NPCs spawnen am Auftrags-Board und warten dort

-- ============================================================
-- TODO: AUFTRAGS-ERFÜLLUNG
-- ============================================================
-- [ ] Item-Picker: Welche Items aus dem Inventar übergeben?
-- [ ] Auto-Select für passende Items
-- [ ] Qualitäts/Reinheits-Check visuell (grün = passt, rot = nicht gut genug)
-- [ ] Übergabe-Animation (Items fliegen zum NPC)
-- [ ] Belohnungs-Animation (Coins regnen, XP-Popup, Bonus-Items)

-- Placeholder initialization
function CustomerDisplay.Init()
    print("[CustomerDisplay] Initialized (STUB)")
end

CustomerDisplay.Init()

return CustomerDisplay
