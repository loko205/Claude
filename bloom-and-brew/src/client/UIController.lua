--[[
    UIController.lua — Haupt-UI Controller (STUB)
    HUD, Inventar, Level-Anzeige, Benachrichtigungen.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)

local UIController = {}
local player = Players.LocalPlayer

-- ============================================================
-- TODO: HUD (Head-Up Display)
-- ============================================================
-- [ ] Oben links: Spieler-Name, Level, XP-Balken
-- [ ] Oben rechts: Coins (gold), Gems (blau), Essenz (lila)
-- [ ] Unter Coins: NPC-Rep Anzeige (kleiner Text)
-- [ ] Dealer-Rang Badge (wenn freigeschaltet)
-- [ ] Minimap/Kompass (optional)

-- ============================================================
-- TODO: INVENTAR-UI
-- ============================================================
-- [ ] Tab-basiertes Inventar: Samen | Pflanzen | Extrakte | Tränke | Katalysatoren
-- [ ] Jedes Item: Icon + Name + Menge/Qualität
-- [ ] Pflanzen: Qualitäts-Sterne + Traits als Badges
-- [ ] Tränke: Reinheits-Anzeige + Effekt-Beschreibung
-- [ ] Extrakte: Potenz-Balken + Menge
-- [ ] Rechtsklick/Langes Drücken → Kontextmenü (Verkaufen, Verarbeiten, etc.)
-- [ ] Such-/Filter-Funktion
-- [ ] Sortierung: Name, Rarität, Wert, Menge

-- ============================================================
-- TODO: BENACHRICHTIGUNGEN
-- ============================================================
-- [ ] Toast-Notifications (unten rechts, stackend)
-- [ ] Typen: Ernte fertig, Verarbeitung fertig, Trank fertig, Auftrag erhalten
-- [ ] Level-Up-Animation (Vollbild-Flash + Fanfare)
-- [ ] Neue Entdeckung: Goldener Rahmen + "NEU" Badge
-- [ ] Handelsanfrage-Popup
-- [ ] Täglicher Login-Reward Screen

-- ============================================================
-- TODO: SAMMELALBUM (Plantdex & Potiondex)
-- ============================================================
-- [ ] Buch-artige UI mit allen Pflanzen/Tränken
-- [ ] Entdeckte Items: Vollständig mit Bild + Beschreibung
-- [ ] Unentdeckte: Silhouette + "???"
-- [ ] Fortschritts-Anzeige (X/Y entdeckt)
-- [ ] Achievements für Vollständigkeit

-- ============================================================
-- TODO: EINSTELLUNGEN
-- ============================================================
-- [ ] Musik-Lautstärke
-- [ ] SFX-Lautstärke
-- [ ] Grafik-Qualität
-- [ ] Benachrichtigungs-Einstellungen
-- [ ] Hilfe / Tutorial wiederholen

-- Placeholder initialization
function UIController.Init()
    print("[UIController] Initialized (STUB)")
end

UIController.Init()

return UIController
