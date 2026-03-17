--[[
    PlayerTradeData.lua — Trade rules, auction house config, black market
    All rules and configuration for player-to-player interactions.
]]

local Config = require(script.Parent.Config)

local PlayerTradeData = {}

-- ============================================================
-- DEALER RANKS
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
-- TRADE RULES
-- ============================================================

PlayerTradeData.Rules = {
    -- Direct trade
    DirectTrade = {
        LevelReq = Config.Trade.DirectTradeLevel,
        TaxRate = Config.Trade.TradeTax,
        ConfirmCountdown = Config.Trade.AntiScamCountdown,
        MaxItemsPerSide = 10,
    },

    -- Bulletin board / marketplace
    Market = {
        LevelReq = Config.Trade.MarketLevel,
        TaxRate = Config.Trade.MarketTax,
        MaxOffers = Config.Trade.MaxMarketOffers,
        OfferDuration = 86400, -- 24h in seconds
        SecretOfferMinRep = Config.Trade.SecretOfferMinRep,
        SortOptions = { "Newest", "Price", "Purity", "Rarity" },
    },

    -- Auction house
    Auction = {
        LevelReq = Config.Trade.AuctionLevel,
        TaxRate = Config.Trade.AuctionTax,
        Durations = Config.Trade.AuctionDurations,
        DurationNames = { "1 Hour", "6 Hours", "24 Hours" },
        MinBidIncrement = 0.05, -- 5% above last bid
        -- Only Epic+ items may be auctioned
        MinRarity = "Epic",
    },

    -- Potion stand
    Stand = {
        LevelReq = Config.Trade.StandLevel,
        BaseSlots = 3,
        MaxFavoriteSuppliers = Config.Trade.MaxFavoriteSuppliers,
        FavoriteDiscount = Config.Trade.FavoriteDiscount,
    },
}

-- ============================================================
-- DEALER REPUTATION
-- ============================================================

PlayerTradeData.RepGains = {
    SuccessfulSale = 5,           -- Per sale
    HighPurityBonus = 10,         -- Sale with 85%+ purity
    PerfectPurityBonus = 25,      -- Sale with 96%+ purity
    RepeatCustomer = 3,           -- Regular customer buys again
    PositiveRating = 8,           -- Positive rating
}

PlayerTradeData.RepLosses = {
    OverpricedVote = -5,          -- Community vote: overpriced
    FailedDelivery = -15,         -- Auction item not delivered
    CancelledTrade = -2,          -- Trade cancelled after confirm
}

-- ============================================================
-- REGULAR CUSTOMER SYSTEM
-- ============================================================

PlayerTradeData.FavoriteSupplier = {
    -- How many purchases are needed to become a regular customer?
    PurchasesRequired = 5,
    -- Bonuses
    Discount = Config.Trade.FavoriteDiscount, -- 10% discount
    NotifyOnNewOffer = true,
    ReservationPriority = true,
    MaxSuppliers = Config.Trade.MaxFavoriteSuppliers,
}

-- ============================================================
-- TRUST SYSTEM
-- ============================================================

PlayerTradeData.Trust = {
    -- Trust level increases with successful trades
    Levels = {
        { Name = "Unknown",   MinScore = 0,   Perks = {} },
        { Name = "Known",     MinScore = 3,   Perks = { "Faster trades" } },
        { Name = "Trusted",   MinScore = 10,  Perks = { "No countdown", "Larger trades" } },
        { Name = "Partner",   MinScore = 25,  Perks = { "Reduced tax (3%)", "Direct delivery" } },
    },

    -- Score changes
    SuccessfulTrade = 1,
    CancelledTrade = -2,
    ScamReport = -10,
}

-- ============================================================
-- HELPER FUNCTIONS
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
        slots = slots + Config.Economy.Gamepasses.ExpandedStand.BonusSlots
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
    if not rules then return false, "Unknown trade type" end

    if playerLevel < rules.LevelReq then
        return false, "Level " .. rules.LevelReq .. " required"
    end

    return true, "OK"
end

return PlayerTradeData
