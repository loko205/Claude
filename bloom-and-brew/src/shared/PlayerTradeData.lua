--[[
    PlayerTradeData.lua — Handelsregeln, Auktionshaus-Config, Schwarzmarkt
    Alle Regeln und Konfiguration für Spieler-zu-Spieler-Interaktionen.
]]

local Config = require(script.Parent.Config)

local PlayerTradeData = {}

-- ============================================================
-- DEALER-RÄNGE
-- ============================================================

PlayerTradeData.DealerRanks = {}
for i, rank in ipairs(Config.Trade.DealerRanks) do
    PlayerTradeData.DealerRanks[i] = {
        Name = rank.Name,
        MinRep = rank.MinRep,
        StandSlots = rank.StandSlots,
        -- Visual perks
        HasBadge = i >= 2,
        HasAura = i >= 3,
        HasCustomStand = i >= 4,
        HasGlobalAnnounce = i >= 4,
        HasGlowName = i >= 5,
        HasMentorSystem = i >= 5,
    }
end

-- ============================================================
-- HANDELS-REGELN
-- ============================================================

PlayerTradeData.Rules = {
    -- Direkthandel
    DirectTrade = {
        LevelReq = Config.Trade.DirectTradeLevel,
        TaxRate = Config.Trade.TradeTax,
        ConfirmCountdown = Config.Trade.AntiScamCountdown,
        MaxItemsPerSide = 10,
    },

    -- Schwarzes Brett / Marktplatz
    Market = {
        LevelReq = Config.Trade.MarketLevel,
        TaxRate = Config.Trade.MarketTax,
        MaxOffers = Config.Trade.MaxMarketOffers,
        OfferDuration = 86400, -- 24h in Sekunden
        SecretOfferMinRep = Config.Trade.SecretOfferMinRep,
        SortOptions = { "Neueste", "Preis", "Reinheit", "Raritaet" },
    },

    -- Auktionshaus
    Auction = {
        LevelReq = Config.Trade.AuctionLevel,
        TaxRate = Config.Trade.AuctionTax,
        Durations = Config.Trade.AuctionDurations,
        DurationNames = { "1 Stunde", "6 Stunden", "24 Stunden" },
        MinBidIncrement = 0.05, -- 5% über letztem Gebot
        -- Nur Epic+ Items dürfen versteigert werden
        MinRarity = "Epic",
    },

    -- Trankstand
    Stand = {
        LevelReq = Config.Trade.StandLevel,
        BaseSlots = 3,
        MaxFavoriteSuppliers = Config.Trade.MaxFavoriteSuppliers,
        FavoriteDiscount = Config.Trade.FavoriteDiscount,
    },
}

-- ============================================================
-- DEALER-REPUTATION
-- ============================================================

PlayerTradeData.RepGains = {
    SuccessfulSale = 5,           -- Pro Verkauf
    HighPurityBonus = 10,         -- Verkauf mit 85%+ Reinheit
    PerfectPurityBonus = 25,      -- Verkauf mit 96%+ Reinheit
    RepeatCustomer = 3,           -- Stammkunde kauft erneut
    PositiveRating = 8,           -- Positive Bewertung
}

PlayerTradeData.RepLosses = {
    OverpricedVote = -5,          -- Community-Vote: überteuert
    FailedDelivery = -15,         -- Auktions-Item nicht geliefert
    CancelledTrade = -2,          -- Trade abgebrochen nach Confirm
}

-- ============================================================
-- STAMMKUNDEN-SYSTEM
-- ============================================================

PlayerTradeData.FavoriteSupplier = {
    -- Wie viele Käufe braucht man um Stammkunde zu werden?
    PurchasesRequired = 5,
    -- Boni
    Discount = Config.Trade.FavoriteDiscount, -- 10% Rabatt
    NotifyOnNewOffer = true,
    ReservationPriority = true,
    MaxSuppliers = Config.Trade.MaxFavoriteSuppliers,
}

-- ============================================================
-- VERTRAUENSSYSTEM
-- ============================================================

PlayerTradeData.Trust = {
    -- Trust-Level steigt mit erfolgreichen Trades
    Levels = {
        { Name = "Unbekannt",   MinScore = 0,   Perks = {} },
        { Name = "Bekannt",     MinScore = 3,   Perks = { "Schnellere Trades" } },
        { Name = "Vertraut",    MinScore = 10,  Perks = { "Kein Countdown", "Größere Trades" } },
        { Name = "Partner",     MinScore = 25,  Perks = { "Reduzierte Steuer (3%)", "Direkte Lieferung" } },
    },

    -- Score changes
    SuccessfulTrade = 1,
    CancelledTrade = -2,
    ScamReport = -10,
}

-- ============================================================
-- HILFSFUNKTIONEN
-- ============================================================

-- Get dealer rank for a given reputation
function PlayerTradeData.GetDealerRank(dealerRep)
    local currentRank = PlayerTradeData.DealerRanks[1]
    for _, rank in ipairs(PlayerTradeData.DealerRanks) do
        if dealerRep >= rank.MinRep then
            currentRank = rank
        end
    end
    return currentRank
end

-- Get stand slots for a dealer rank (including gamepass bonus)
function PlayerTradeData.GetStandSlots(dealerRep, hasStandGamepass)
    local rank = PlayerTradeData.GetDealerRank(dealerRep)
    local slots = rank.StandSlots
    if hasStandGamepass then
        slots = slots + Config.Economy.Gamepasses.ErweiterterStand.BonusSlots
    end
    return slots
end

-- Calculate trade tax based on trust level
function PlayerTradeData.GetTradeTax(trustScore)
    if trustScore >= 25 then
        return 0.03 -- Partner: reduced tax
    end
    return Config.Trade.TradeTax
end

-- Check if a player can see secret market offers
function PlayerTradeData.CanSeeSecretOffers(dealerRep)
    return dealerRep >= Config.Trade.SecretOfferMinRep
end

-- Get trust level info for a given trust score
function PlayerTradeData.GetTrustLevel(trustScore)
    local current = PlayerTradeData.Trust.Levels[1]
    for _, level in ipairs(PlayerTradeData.Trust.Levels) do
        if trustScore >= level.MinScore then
            current = level
        end
    end
    return current
end

-- Validate if a trade is allowed (rate limiting, level checks)
function PlayerTradeData.ValidateTrade(playerLevel, tradeType)
    local rules = PlayerTradeData.Rules[tradeType]
    if not rules then return false, "Unbekannter Handelstyp" end

    if playerLevel < rules.LevelReq then
        return false, "Level " .. rules.LevelReq .. " benötigt"
    end

    return true, "OK"
end

return PlayerTradeData
