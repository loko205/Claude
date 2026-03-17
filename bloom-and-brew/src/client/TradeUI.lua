--[[
    TradeUI.lua — Handel-Interface (STUB)
    Direkthandel, Schwarzes Brett, Auktionshaus, Trankstand.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerTradeData = require(ReplicatedStorage.Shared.PlayerTradeData)

local TradeUI = {}
local player = Players.LocalPlayer

-- ============================================================
-- TODO: DIREKTHANDEL (P2P Trade Window)
-- ============================================================
-- [ ] Trade-Request-Popup ("Spieler X möchte handeln!")
-- [ ] Geteiltes Trade-Window: Links = Meine Items, Rechts = Andere Items
-- [ ] Drag & Drop: Items aus Inventar ins Trade-Fenster ziehen
-- [ ] Coins-Feld: Manuell Coins-Betrag eingeben
-- [ ] Bestätigungs-Buttons: "Bestätigen" (grün) / "Abbrechen" (rot)
-- [ ] 10s Anti-Scam-Countdown nach Bestätigung (großer Timer)
-- [ ] Änderungen nach Confirm resetten den Timer (Warnung!)
-- [ ] Vertrauens-Anzeige: Trust-Level zum anderen Spieler

-- ============================================================
-- TODO: TRANKSTAND
-- ============================================================
-- [ ] Stand als 3D-Objekt vor dem Garten des Spielers
-- [ ] Stand-Design basierend auf Dealer-Rang (Einfach → Luxus)
-- [ ] Angebots-Slots mit Trank-Icons + Preis
-- [ ] "Einstellen"-Dialog: Trank auswählen, Preis festlegen
-- [ ] Besucher-Ansicht: Angebote des anderen Spielers sehen + "Kaufen"
-- [ ] Dealer-Rang-Badge über dem Stand
-- [ ] Stammkunden-Badge bei Lieblings-Verkäufern

-- ============================================================
-- TODO: SCHWARZES BRETT (Marktplatz)
-- ============================================================
-- [ ] Brett-UI als scrollbare Liste
-- [ ] Filter: Typ (Pflanze/Trank), Reinheit, Preis, Rarität
-- [ ] Sortierung: Neueste, Preis (auf/ab), Reinheit, Rarität
-- [ ] Geheime Angebote: Sichtbar ab Rep 1000, goldener Rahmen
-- [ ] "Kaufen"-Button + Bestätigungs-Dialog
-- [ ] "Eigene Angebote verwalten" Tab
-- [ ] "Angebot einstellen" Dialog
-- [ ] Stammkunden-Rabatt automatisch anzeigen ("-10%")

-- ============================================================
-- TODO: AUKTIONSHAUS
-- ============================================================
-- [ ] Premium-UI mit goldener Umrandung
-- [ ] Aktive Auktionen als Karten (Item-Bild, aktuelles Gebot, Timer)
-- [ ] "Gebot abgeben" Dialog (mit Min-Gebot-Anzeige)
-- [ ] "Sofortkauf" Button (wenn Buyout-Preis gesetzt)
-- [ ] Eigene Auktionen verwalten
-- [ ] "Neue Auktion" Dialog: Item wählen, Mindestgebot, Dauer, Buyout
-- [ ] Gebotshistorie pro Auktion

-- ============================================================
-- TODO: DEALER-RANG-ANZEIGE
-- ============================================================
-- [ ] Rang über dem Kopf des Spielers (Billboard GUI)
-- [ ] Rang-Farbe: Lehrling=Grau, Alchemist=Grün, Meisterbrauer=Blau, etc.
-- [ ] Aura-Effekt ab "Meisterbrauer"
-- [ ] Leuchtender Name ab "Großmeister"

-- Placeholder initialization
function TradeUI.Init()
    print("[TradeUI] Initialized (STUB)")
end

TradeUI.Init()

return TradeUI
