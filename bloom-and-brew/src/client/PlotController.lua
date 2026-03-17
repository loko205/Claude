--[[
    PlotController.lua — Client-seitiger Garten-Controller (STUB)
    Steuert Garten-Rendering, Pflanz-Interaktionen und Verarbeitungs-UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local PlantData = require(ReplicatedStorage.Shared.PlantData)
local ProcessingData = require(ReplicatedStorage.Shared.ProcessingData)

local PlotController = {}
local player = Players.LocalPlayer

-- ============================================================
-- TODO: GARTEN-RENDERING
-- ============================================================
-- [ ] Plot-Grid (3x3) visuell darstellen mit Bodenplatten
-- [ ] Pflanze pro Feld als 3D-Modell (5 Wachstumsphasen)
-- [ ] Wachstumsfortschritt-Balken über jeder Pflanze
-- [ ] Qualitäts-Sterne anzeigen (★-★★★★★)
-- [ ] Trait-Icons neben der Pflanze (Leuchtend = Glow-Effekt, etc.)
-- [ ] Überreif-Warnung (rotes Blinken ab Progress > 1.0)
-- [ ] Boden-Typ visuell unterscheidbar (Farbe/Textur)
-- [ ] Plot-Typ Badge (Standard/Gewächshaus/Mutation/Premium)

-- ============================================================
-- TODO: PFLANZ-INTERAKTIONEN
-- ============================================================
-- [ ] Seed-Picker UI: Samen aus Inventar auswählen
-- [ ] Klick auf leeres Feld → Samen pflanzen (Fire PlantRemotes.PlantSeed)
-- [ ] Klick auf Pflanze → Aktionsmenü (Gießen/Düngen/Beschneiden/Ernten)
-- [ ] Gießen-Animation (Gießkanne, Wasserpartikel)
-- [ ] Dünge-Animation (Sparkle-Effekt)
-- [ ] Ernte-Animation (Pflanze verschwindet, Item-Popup)
-- [ ] Gieß-Cooldown-Anzeige (30s Timer pro Pflanze)

-- ============================================================
-- TODO: VERARBEITUNGS-UI (NEU)
-- ============================================================
-- [ ] Verarbeitungsstation als interaktives Objekt neben dem Garten
-- [ ] Maschinen-Auswahl (nur freigeschaltete anzeigen)
-- [ ] Maschinen-Kauf-Dialog mit Kosten und Level-Req
-- [ ] Pflanze-zu-Maschine Drag & Drop
-- [ ] Warnung bei falscher Methode ("ACHTUNG: Pflanze wird zerstört!")
-- [ ] Empfehlung für richtige Methode anzeigen
-- [ ] Fortschrittsbalken für aktive Verarbeitungen
-- [ ] Extrakt-Einsammel-Animation (Fläschchen füllt sich)
-- [ ] Maschinen-Upgrade UI (Einfach → Verbessert → Meister)
-- [ ] Extrakt-Inventar-Anzeige (was hab ich, wie viel, welche Potenz?)

-- ============================================================
-- TODO: PLOT-MANAGEMENT
-- ============================================================
-- [ ] Plot-Kauf-Button (wenn < MaxPlots)
-- [ ] Plot-Upgrade-Button mit Kosten-Anzeige
-- [ ] Boden-Wechsel UI
-- [ ] Plot-Typ-Auswahl beim Kauf
-- [ ] Übersicht aller Plots (Minimap?)

-- ============================================================
-- TODO: GARTENBESUCH (andere Spieler)
-- ============================================================
-- [ ] "Besuchen"-Button bei anderen Spielern
-- [ ] Besuchs-Modus: Nur Anschauen + Gießhilfe
-- [ ] "Gefällt mir"-Button
-- [ ] Gästebuch-UI
-- [ ] Pflanzen-Info-Popup beim Hovern

-- Placeholder initialization
function PlotController.Init()
    print("[PlotController] Initialized (STUB)")
end

PlotController.Init()

return PlotController
