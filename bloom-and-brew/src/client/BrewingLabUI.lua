--[[
    BrewingLabUI.lua — Client-seitiges Brau-Labor Interface (STUB)
    Kessel-UI, Rezeptbuch, Minigame, Reinheits-Anzeige.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local PotionData = require(ReplicatedStorage.Shared.PotionData)
local ProcessingData = require(ReplicatedStorage.Shared.ProcessingData)

local BrewingLabUI = {}
local player = Players.LocalPlayer

-- ============================================================
-- TODO: LABOR-ANSICHT
-- ============================================================
-- [ ] 3D-Labor-Raum mit Kessel in der Mitte
-- [ ] Kessel-Modell je nach Level (Holz → Kupfer → Silber → Gold → Obsidian)
-- [ ] Regale mit Extrakt-Fläschchen (Inventar-Visualisierung)
-- [ ] Dampf-VFX vom Kessel während des Brauens
-- [ ] Glow-Effekte bei hoher Reinheit
-- [ ] Upgrade-Schild am Kessel

-- ============================================================
-- TODO: REZEPTBUCH
-- ============================================================
-- [ ] Rezeptbuch-UI als aufklappbares Buch
-- [ ] Entdeckte Rezepte vollständig anzeigen
-- [ ] Unentdeckte Rezepte als "???" (Silhouette)
-- [ ] Filter: Tier (Starter/Fortgeschritten/Selten/Legendär)
-- [ ] Zutaten-Checkliste (grün = vorhanden, rot = fehlt)
-- [ ] Extrakt-Typ anzeigen (nicht rohe Pflanze!)
-- [ ] "Brauen"-Button wenn alle Extrakte vorhanden
-- [ ] Modus-Auswahl: Minigame vs. Auto-Brauen

-- ============================================================
-- TODO: BRAU-MINIGAME
-- ============================================================
-- [ ] Fullscreen-Minigame-Overlay wenn Brauen gestartet
-- [ ] Phase 1: Zutaten-Timing (Extrakte zum richtigen Zeitpunkt in Kessel werfen)
--     - Zutaten fallen von oben, perfekter Zeitpunkt = grüne Zone
--     - Feedback: "Perfekt!", "Gut", "Naja..."
-- [ ] Phase 2: Temperatur-Kontrolle (Slider)
--     - Temperatur schwankt, Spieler muss in grüner Zone halten
--     - Zu heiß = rot, zu kalt = blau
-- [ ] Phase 3: Rühren im Rhythmus
--     - Kreise auf dem Kessel antippen im Takt
--     - Visuelle Rühr-Animation
-- [ ] Score-Anzeige am Ende (0-100)
-- [ ] Score an Server senden (Fire BrewingRemotes.SubmitMinigame)
-- [ ] Auto-Brew-Option: Minigame überspringen

-- ============================================================
-- TODO: BRAU-FORTSCHRITT
-- ============================================================
-- [ ] Fortschrittsbalken über dem Kessel
-- [ ] Timer-Anzeige (verbleibende Sekunden)
-- [ ] Dampf-Intensität steigt mit Fortschritt
-- [ ] "Fertig!"-Notification (Partikel-Explosion)
-- [ ] Einsammel-Animation (Trank-Fläschchen)

-- ============================================================
-- TODO: TRANK-ERGEBNIS
-- ============================================================
-- [ ] Ergebnis-Popup: Trank-Name, Reinheit, Wert
-- [ ] Reinheits-Balken mit Farbe (Verdünnt=Grau → Perfekt=Gold)
-- [ ] Bei "Perfekt" (96-100%): Goldener Glow-Effekt + Konfetti
-- [ ] Potiondex-Update wenn neue Entdeckung
-- [ ] "Selbst trinken" vs "Einlagern" Auswahl

-- ============================================================
-- TODO: EXTRAKT-INVENTAR
-- ============================================================
-- [ ] Liste aller Extrakte mit Menge und durchschnittlicher Potenz
-- [ ] Potenz-Anzeige als farbiger Balken (niedrig=rot → hoch=grün)
-- [ ] Extrakt-Info: Welche Methode, von welcher Pflanze
-- [ ] Quick-Info: "Für welche Tränke brauchbar?"

-- Placeholder initialization
function BrewingLabUI.Init()
    print("[BrewingLabUI] Initialized (STUB)")
end

BrewingLabUI.Init()

return BrewingLabUI
