--[[
    PlayerInteraction.lua — Spieler-Interaktionen (STUB)
    Gartenbesuche, Gießhilfe, Trank-Duell, Gilden-UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerInteraction = {}
local player = Players.LocalPlayer

-- ============================================================
-- TODO: GARTENBESUCHE
-- ============================================================
-- [ ] Spielerliste: Online-Spieler mit "Garten besuchen" Button
-- [ ] Teleport zum Garten des anderen Spielers
-- [ ] Besuchs-Modus: Kamera zeigt den fremden Garten
-- [ ] "Gefällt mir" Button (+Coins für Besitzer)
-- [ ] Pflanzen-Hovern: Info-Popup (Name, Qualität, Traits)
-- [ ] "Gießhilfe" Button bei nicht-gegossenen Pflanzen
-- [ ] Gießen-Animation + XP-Bonus für beide Spieler
-- [ ] Gästebuch: Nachrichten hinterlassen (moderiert!)
-- [ ] "Zurück zu meinem Garten" Button
-- [ ] Top-Gärten der Woche: Showcase-Leaderboard

-- ============================================================
-- TODO: TRANK-DUELL
-- ============================================================
-- [ ] Duell-Challenge senden: Spieler auswählen + Trank wählen
-- [ ] Duell-Anfrage-Popup beim Gegner
-- [ ] Duell-Arena: Kleiner Parcours/Plattform
-- [ ] Countdown (3... 2... 1... LOS!)
-- [ ] Effekt-spezifische Mini-Challenges:
--     - Sprungtrank → Wer erreicht die höchste Plattform?
--     - Speedtrank → Wer ist schneller im Parcours?
--     - Riesenwuchs → Wer ist am größten? (Purity bestimmt Größe)
--     - Flugessenz → Wer sammelt mehr Sterne in der Luft?
--     - Unsichtbarkeitstrank → Versteckspiel (wer findet den anderen?)
-- [ ] Ergebnis-Screen: Gewinner + Coins + Rep
-- [ ] Duell-Statistik (Siege/Niederlagen)

-- ============================================================
-- TODO: GILDEN / ALCHEMISTEN-ZIRKEL
-- ============================================================
-- [ ] Gilden-Erstellung: Name + Icon wählen (ab Level 12)
-- [ ] Gilden-Beitritt: Liste offener Gilden + Einladungen
-- [ ] Gilden-Übersicht: Mitglieder, Rang, Beiträge
-- [ ] Gemeinsamer Garten: Extra-Plot mit Gilden-Mitgliedern
-- [ ] Gilden-Labor: Gruppen-Brauen UI (mehrere Spieler gleichzeitig)
-- [ ] Gilden-Aufträge: Große NPC-Aufträge die alle bearbeiten
-- [ ] Gilden-Chat
-- [ ] Gilden-Wettbewerbe: Gilde vs. Gilde Scoreboard
-- [ ] Rollen: Anführer, Offizier, Mitglied

-- ============================================================
-- TODO: TÄGLICHE HERAUSFORDERUNGEN
-- ============================================================
-- [ ] Community-Challenge Banner oben im Screen
-- [ ] Fortschrittsbalken (server-weiter Fortschritt)
-- [ ] Eigener Beitrag anzeigen
-- [ ] Belohnungs-Vorschau
-- [ ] Challenge-Typen:
--     - "Community braut 1000 Tränke"
--     - "Finde die Geheim-Mutation des Tages"
--     - "1000 Pflanzen ernten"
--     - "Höchste Reinheit des Tages"
-- [ ] Rangliste: Top-Beiträger

-- ============================================================
-- TODO: TRANK-KONSUM
-- ============================================================
-- [ ] "Trinken" Button im Inventar / Quick-Bar
-- [ ] Trink-Animation (Fläschchen an den Mund)
-- [ ] Effekt-Overlay: Buff-Icon + Timer in der HUD-Ecke
-- [ ] Visuelle Effekte pro Trank:
--     - Sprungtrank: Grüne Partikel an den Füßen
--     - Glühtrank: Spieler leuchtet
--     - Speedtrank: Geschwindigkeitslinien
--     - Unsichtbarkeitstrank: Transparenz-Übergang
--     - Flugessenz: Flügel-Partikel
--     - Riesenwuchs: Größen-Skalierung
-- [ ] Buff-Ende-Warnung (5s vorher: "Effekt läuft gleich ab!")

-- Placeholder initialization
function PlayerInteraction.Init()
    print("[PlayerInteraction] Initialized (STUB)")
end

PlayerInteraction.Init()

return PlayerInteraction
