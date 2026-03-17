--[[
    PlayerTradeManager.lua — P2P Trading, Potion Stand, Market Board, Auction House
    Regular Customers, Dealer Rep, Trust System.
    All server-validated, rate-limited, anti-exploit.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerTradeData = require(ReplicatedStorage.Shared.PlayerTradeData)
local PotionData = require(ReplicatedStorage.Shared.PotionData)
local DataManager = require(script.Parent.DataManager)

local PlayerTradeManager = {}

-- Active trades (server-side state, not persisted)
local activeTrades = {} -- { [tradeId] = { Player1, Player2, Items1, Items2, Coins1, Coins2, Confirmed1, Confirmed2, ConfirmTime } }
local tradeIdCounter = 0

-- RemoteEvents
local remotes = {}

local function createRemotes()
    local folder = Instance.new("Folder")
    folder.Name = "TradeRemotes"
    folder.Parent = ReplicatedStorage

    local events = {
        "SendTradeRequest", "AcceptTradeRequest", "DeclineTradeRequest",
        "AddTradeItem", "RemoveTradeItem", "SetTradeCoins",
        "ConfirmTrade", "CancelTrade",
        "ListOnStand", "RemoveFromStand", "BuyFromStand",
        "PostMarketOffer", "RemoveMarketOffer", "BuyMarketOffer",
        "CreateAuction", "BidOnAuction", "BuyoutAuction",
    }
    for _, name in ipairs(events) do
        local remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = folder
        remotes[name] = remote
    end
end

-- Rate limiter
local lastActions = {}
local function rateCheck(player)
    local now = os.clock()
    local key = tostring(player.UserId)
    if lastActions[key] and (now - lastActions[key]) < (1 / Config.Technical.MaxRequestsPerSecond) then
        return false
    end
    lastActions[key] = now
    return true
end

-- ============================================================
-- 1. DIRECT TRADE (P2P Trade)
-- ============================================================

function PlayerTradeManager.SendTradeRequest(sender, targetPlayer)
    local senderData = DataManager.GetData(sender)
    if not senderData then return false, "No data" end

    if senderData.Level < Config.Trade.DirectTradeLevel then
        return false, "Level " .. Config.Trade.DirectTradeLevel .. " required"
    end

    -- Check target is valid player
    if not targetPlayer or not targetPlayer:IsA("Player") then
        return false, "Invalid player"
    end

    -- Create trade session
    tradeIdCounter = tradeIdCounter + 1
    local tradeId = tradeIdCounter

    activeTrades[tradeId] = {
        Player1 = sender,
        Player2 = targetPlayer,
        Items1 = {},
        Items2 = {},
        Coins1 = 0,
        Coins2 = 0,
        Confirmed1 = false,
        Confirmed2 = false,
        ConfirmTime = nil,
        CreatedAt = os.time(),
    }

    -- TODO: Notify target player
    return true, "Trade request sent!", tradeId
end

function PlayerTradeManager.ConfirmTrade(player, tradeId)
    local trade = activeTrades[tradeId]
    if not trade then return false, "Trade not found" end

    local isPlayer1 = trade.Player1 == player
    local isPlayer2 = trade.Player2 == player
    if not isPlayer1 and not isPlayer2 then return false, "Not your trade" end

    if isPlayer1 then trade.Confirmed1 = true end
    if isPlayer2 then trade.Confirmed2 = true end

    -- Both confirmed?
    if trade.Confirmed1 and trade.Confirmed2 then
        if not trade.ConfirmTime then
            -- Start anti-scam countdown
            trade.ConfirmTime = os.time()
            -- TODO: Notify both players about countdown
            return true, "Both confirmed! " .. Config.Trade.AntiScamCountdown .. "s Countdown..."
        end

        -- Check countdown
        local elapsed = os.time() - trade.ConfirmTime
        if elapsed < Config.Trade.AntiScamCountdown then
            return false, "Countdown still running (" .. (Config.Trade.AntiScamCountdown - elapsed) .. "s)"
        end

        -- Execute trade!
        return PlayerTradeManager.ExecuteTrade(tradeId)
    end

    return true, "Confirmed! Waiting for the other player..."
end

function PlayerTradeManager.ExecuteTrade(tradeId)
    local trade = activeTrades[tradeId]
    if not trade then return false, "Trade not found" end

    local data1 = DataManager.GetData(trade.Player1)
    local data2 = DataManager.GetData(trade.Player2)
    if not data1 or not data2 then return false, "Player data unavailable" end

    -- Calculate tax
    local tax1 = math.floor(trade.Coins1 * Config.Trade.TradeTax)
    local tax2 = math.floor(trade.Coins2 * Config.Trade.TradeTax)

    -- Validate coins
    if data1.Coins < trade.Coins1 then return false, "Player 1 doesn't have enough Coins" end
    if data2.Coins < trade.Coins2 then return false, "Player 2 doesn't have enough Coins" end

    -- Transfer coins (after tax)
    DataManager.RemoveCoins(trade.Player1, trade.Coins1)
    DataManager.AddCoins(trade.Player2, trade.Coins1 - tax1)

    DataManager.RemoveCoins(trade.Player2, trade.Coins2)
    DataManager.AddCoins(trade.Player1, trade.Coins2 - tax2)

    -- Transfer items (simplified — in full game, transfer specific inventory items)
    -- Items would be indices into Inventory.Plants/Potions/Seeds
    -- For now, the trade.Items contain the actual item data

    -- Update trust scores
    local p1Id = tostring(trade.Player1.UserId)
    local p2Id = tostring(trade.Player2.UserId)
    data1.Trade.TrustScores[p2Id] = (data1.Trade.TrustScores[p2Id] or 0) + PlayerTradeData.Trust.SuccessfulTrade
    data2.Trade.TrustScores[p1Id] = (data2.Trade.TrustScores[p1Id] or 0) + PlayerTradeData.Trust.SuccessfulTrade

    -- Stats
    data1.Stats.PlayerSales = data1.Stats.PlayerSales + 1
    data2.Stats.PlayerSales = data2.Stats.PlayerSales + 1

    -- Clean up
    activeTrades[tradeId] = nil

    return true, "Trade completed!"
end

function PlayerTradeManager.CancelTrade(player, tradeId)
    local trade = activeTrades[tradeId]
    if not trade then return false end
    if trade.Player1 ~= player and trade.Player2 ~= player then return false end

    activeTrades[tradeId] = nil
    return true, "Trade cancelled"
end

-- ============================================================
-- 2. POTION STAND
-- ============================================================

function PlayerTradeManager.ListOnStand(player, potionIndex, price)
    local data = DataManager.GetData(player)
    if not data then return false, "No data" end

    if data.Level < Config.Trade.StandLevel then
        return false, "Potion Stand unlocks at Level " .. Config.Trade.StandLevel
    end

    -- Check slots
    local maxSlots = PlayerTradeData.GetStandSlots(data.Trade.DealerRep, data.Gamepasses and data.Gamepasses.ExpandedStand)
    if #data.Trade.StandOffers >= maxSlots then
        return false, "All stand slots occupied (" .. maxSlots .. " max)"
    end

    -- Validate potion
    local potion = data.Inventory.Potions[potionIndex]
    if not potion then return false, "Potion not in inventory" end

    -- Validate price (anti-exploit: must be positive, reasonable)
    if type(price) ~= "number" or price <= 0 or price > 999999 then
        return false, "Invalid price"
    end

    -- Move potion to stand
    local standOffer = {
        Potion = potion,
        Price = price,
        ListedAt = os.time(),
    }

    table.remove(data.Inventory.Potions, potionIndex)
    table.insert(data.Trade.StandOffers, standOffer)

    local potionInfo = PotionData.GetPotion(potion.PotionId)
    return true, (potionInfo and potionInfo.Name or potion.PotionId) .. " listed for " .. price .. " Coins on stand!"
end

function PlayerTradeManager.BuyFromStand(buyer, sellerId, offerIndex)
    local seller = Players:GetPlayerByUserId(sellerId)
    if not seller then return false, "Seller not online" end

    local buyerData = DataManager.GetData(buyer)
    local sellerData = DataManager.GetData(seller)
    if not buyerData or not sellerData then return false, "Data unavailable" end

    local offer = sellerData.Trade.StandOffers[offerIndex]
    if not offer then return false, "Offer does not exist" end

    -- Can afford?
    if buyerData.Coins < offer.Price then
        return false, "Not enough Coins (" .. offer.Price .. " required)"
    end

    -- Execute purchase
    local tax = math.floor(offer.Price * Config.Trade.TradeTax)
    DataManager.RemoveCoins(buyer, offer.Price)
    DataManager.AddCoins(seller, offer.Price - tax)

    -- Transfer potion
    table.insert(buyerData.Inventory.Potions, offer.Potion)
    table.remove(sellerData.Trade.StandOffers, offerIndex)

    -- Update dealer rep
    sellerData.Trade.DealerRep = sellerData.Trade.DealerRep + PlayerTradeData.RepGains.SuccessfulSale
    if offer.Potion.Purity and offer.Potion.Purity >= 85 then
        sellerData.Trade.DealerRep = sellerData.Trade.DealerRep + PlayerTradeData.RepGains.HighPurityBonus
    end
    if offer.Potion.Purity and offer.Potion.Purity >= 96 then
        sellerData.Trade.DealerRep = sellerData.Trade.DealerRep + PlayerTradeData.RepGains.PerfectPurityBonus
    end

    sellerData.Trade.TotalSales = sellerData.Trade.TotalSales + 1
    sellerData.Trade.DealerRank = PlayerTradeData.GetDealerRank(sellerData.Trade.DealerRep).Name

    -- Regular customer tracking (loyalty)
    local buyerIdStr = tostring(buyer.UserId)
    sellerData.Trade.FavoriteSuppliers = sellerData.Trade.FavoriteSuppliers or {}
    -- Track purchases from this buyer
    buyerData.Trade.FavoriteSuppliers = buyerData.Trade.FavoriteSuppliers or {}
    local sellerIdStr = tostring(seller.UserId)
    buyerData.Trade.FavoriteSuppliers[sellerIdStr] = (buyerData.Trade.FavoriteSuppliers[sellerIdStr] or 0) + 1

    -- Stats
    sellerData.Stats.PlayerSales = sellerData.Stats.PlayerSales + 1
    DataManager.AddXP(seller, Config.Economy.XP.PlayerSale)

    return true, "Purchased for " .. offer.Price .. " Coins!"
end

-- ============================================================
-- 3. MARKET BOARD (Marketplace)
-- ============================================================

function PlayerTradeManager.PostMarketOffer(player, itemType, itemIndex, price, isSecret)
    local data = DataManager.GetData(player)
    if not data then return false, "No data" end

    if data.Level < Config.Trade.MarketLevel then
        return false, "Market Board unlocks at Level " .. Config.Trade.MarketLevel
    end

    if #data.Trade.MarketOffers >= Config.Trade.MaxMarketOffers then
        return false, "Maximum offers reached (" .. Config.Trade.MaxMarketOffers .. ")"
    end

    -- Secret offers require rep
    if isSecret and data.Trade.DealerRep < Config.Trade.SecretOfferMinRep then
        return false, "Secret offers require " .. Config.Trade.SecretOfferMinRep .. " Dealer Rep"
    end

    if type(price) ~= "number" or price <= 0 or price > 999999 then
        return false, "Invalid price"
    end

    local itemData
    if itemType == "Potion" then
        itemData = data.Inventory.Potions[itemIndex]
        if not itemData then return false, "Potion not in inventory" end
        table.remove(data.Inventory.Potions, itemIndex)
    elseif itemType == "Plant" then
        itemData = data.Inventory.Plants[itemIndex]
        if not itemData then return false, "Plant not in inventory" end
        table.remove(data.Inventory.Plants, itemIndex)
    else
        return false, "Invalid item type"
    end

    table.insert(data.Trade.MarketOffers, {
        ItemType = itemType,
        ItemData = itemData,
        Price = price,
        Secret = isSecret or false,
        ListedAt = os.time(),
        SellerId = player.UserId,
        SellerName = player.Name,
    })

    return true, "Listed on Market Board!"
end

function PlayerTradeManager.BuyMarketOffer(buyer, sellerId, offerIndex)
    local seller = Players:GetPlayerByUserId(sellerId)
    if not seller then return false, "Seller not online" end

    local buyerData = DataManager.GetData(buyer)
    local sellerData = DataManager.GetData(seller)
    if not buyerData or not sellerData then return false, "Data unavailable" end

    local offer = sellerData.Trade.MarketOffers[offerIndex]
    if not offer then return false, "Offer does not exist" end

    -- Secret offer visibility check
    if offer.Secret and not PlayerTradeData.CanSeeSecretOffers(buyerData.Trade.DealerRep) then
        return false, "This offer is only visible to insiders"
    end

    -- Regular customer discount
    local discount = 0
    local sellerIdStr = tostring(sellerId)
    local purchases = buyerData.Trade.FavoriteSuppliers and buyerData.Trade.FavoriteSuppliers[sellerIdStr] or 0
    if purchases >= PlayerTradeData.FavoriteSupplier.PurchasesRequired then
        discount = PlayerTradeData.FavoriteSupplier.Discount
    end

    local finalPrice = math.floor(offer.Price * (1 - discount))

    if buyerData.Coins < finalPrice then
        return false, "Not enough Coins (" .. finalPrice .. " required)"
    end

    -- Execute
    local tax = math.floor(finalPrice * Config.Trade.MarketTax)
    DataManager.RemoveCoins(buyer, finalPrice)
    DataManager.AddCoins(seller, finalPrice - tax)

    -- Transfer item
    if offer.ItemType == "Potion" then
        table.insert(buyerData.Inventory.Potions, offer.ItemData)
    elseif offer.ItemType == "Plant" then
        table.insert(buyerData.Inventory.Plants, offer.ItemData)
    end

    table.remove(sellerData.Trade.MarketOffers, offerIndex)

    -- Rep + Stats
    sellerData.Trade.DealerRep = sellerData.Trade.DealerRep + PlayerTradeData.RepGains.SuccessfulSale
    sellerData.Trade.TotalSales = sellerData.Trade.TotalSales + 1
    sellerData.Trade.DealerRank = PlayerTradeData.GetDealerRank(sellerData.Trade.DealerRep).Name
    DataManager.AddXP(seller, Config.Economy.XP.PlayerSale)

    local discountMsg = discount > 0 and " (Regular discount: -" .. math.floor(discount * 100) .. "%)" or ""
    return true, "Purchased for " .. finalPrice .. " Coins!" .. discountMsg
end

-- ============================================================
-- 4. AUCTION HOUSE
-- ============================================================

function PlayerTradeManager.CreateAuction(player, itemType, itemIndex, minBid, durationIndex, buyoutPrice)
    local data = DataManager.GetData(player)
    if not data then return false, "No data" end

    if data.Level < Config.Trade.AuctionLevel then
        return false, "Auction House unlocks at Level " .. Config.Trade.AuctionLevel
    end

    if type(minBid) ~= "number" or minBid <= 0 then
        return false, "Invalid minimum bid"
    end

    local duration = Config.Trade.AuctionDurations[durationIndex or 1]
    if not duration then return false, "Invalid duration" end

    local itemData
    if itemType == "Potion" then
        itemData = data.Inventory.Potions[itemIndex]
        if not itemData then return false end
        table.remove(data.Inventory.Potions, itemIndex)
    elseif itemType == "Plant" then
        itemData = data.Inventory.Plants[itemIndex]
        if not itemData then return false end
        table.remove(data.Inventory.Plants, itemIndex)
    else
        return false, "Invalid item type"
    end

    table.insert(data.Trade.Auctions, {
        ItemType = itemType,
        ItemData = itemData,
        MinBid = minBid,
        CurrentBid = 0,
        BidderId = nil,
        BidderName = nil,
        BuyoutPrice = buyoutPrice,
        EndTime = os.time() + duration,
        SellerId = player.UserId,
        SellerName = player.Name,
    })

    return true, "Auction created!"
end

function PlayerTradeManager.BidOnAuction(bidder, sellerId, auctionIndex, bidAmount)
    local seller = Players:GetPlayerByUserId(sellerId)
    if not seller then return false, "Seller not online" end

    local bidderData = DataManager.GetData(bidder)
    local sellerData = DataManager.GetData(seller)
    if not bidderData or not sellerData then return false end

    local auction = sellerData.Trade.Auctions[auctionIndex]
    if not auction then return false, "Auction does not exist" end

    -- Check not expired
    if os.time() >= auction.EndTime then
        return false, "Auction expired"
    end

    -- Validate bid
    local minRequired = math.max(auction.MinBid, math.floor(auction.CurrentBid * (1 + PlayerTradeData.Rules.Auction.MinBidIncrement)))
    if bidAmount < minRequired then
        return false, "Minimum bid: " .. minRequired .. " Coins"
    end

    if bidderData.Coins < bidAmount then
        return false, "Not enough Coins"
    end

    -- Refund previous bidder
    if auction.BidderId then
        local prevBidder = Players:GetPlayerByUserId(auction.BidderId)
        if prevBidder then
            DataManager.AddCoins(prevBidder, auction.CurrentBid)
        end
    end

    -- Place bid
    DataManager.RemoveCoins(bidder, bidAmount)
    auction.CurrentBid = bidAmount
    auction.BidderId = bidder.UserId
    auction.BidderName = bidder.Name

    return true, "Bid: " .. bidAmount .. " Coins!"
end

function PlayerTradeManager.BuyoutAuction(buyer, sellerId, auctionIndex)
    local seller = Players:GetPlayerByUserId(sellerId)
    if not seller then return false, "Seller not online" end

    local sellerData = DataManager.GetData(seller)
    if not sellerData then return false end

    local auction = sellerData.Trade.Auctions[auctionIndex]
    if not auction or not auction.BuyoutPrice then return false, "No buyout available" end

    local buyerData = DataManager.GetData(buyer)
    if buyerData.Coins < auction.BuyoutPrice then
        return false, "Not enough Coins"
    end

    -- Refund previous bidder
    if auction.BidderId then
        local prevBidder = Players:GetPlayerByUserId(auction.BidderId)
        if prevBidder then
            DataManager.AddCoins(prevBidder, auction.CurrentBid)
        end
    end

    -- Execute buyout
    local tax = math.floor(auction.BuyoutPrice * Config.Trade.AuctionTax)
    DataManager.RemoveCoins(buyer, auction.BuyoutPrice)
    DataManager.AddCoins(seller, auction.BuyoutPrice - tax)

    -- Transfer item
    if auction.ItemType == "Potion" then
        table.insert(buyerData.Inventory.Potions, auction.ItemData)
    elseif auction.ItemType == "Plant" then
        table.insert(buyerData.Inventory.Plants, auction.ItemData)
    end

    table.remove(sellerData.Trade.Auctions, auctionIndex)

    -- Rep
    sellerData.Trade.DealerRep = sellerData.Trade.DealerRep + PlayerTradeData.RepGains.SuccessfulSale
    sellerData.Trade.TotalSales = sellerData.Trade.TotalSales + 1

    return true, "Buyout for " .. auction.BuyoutPrice .. " Coins!"
end

-- ============================================================
-- AUCTION EXPIRY TICK
-- ============================================================

local function auctionExpiryTick()
    for _, player in ipairs(Players:GetPlayers()) do
        local data = DataManager.GetData(player)
        if not data then continue end

        local now = os.time()
        local expired = {}

        for i, auction in ipairs(data.Trade.Auctions) do
            if now >= auction.EndTime then
                table.insert(expired, i)
            end
        end

        for j = #expired, 1, -1 do
            local i = expired[j]
            local auction = data.Trade.Auctions[i]

            if auction.BidderId and auction.CurrentBid > 0 then
                -- Auction won: transfer item to winner, coins to seller
                local winner = Players:GetPlayerByUserId(auction.BidderId)
                if winner then
                    local winnerData = DataManager.GetData(winner)
                    if winnerData then
                        if auction.ItemType == "Potion" then
                            table.insert(winnerData.Inventory.Potions, auction.ItemData)
                        elseif auction.ItemType == "Plant" then
                            table.insert(winnerData.Inventory.Plants, auction.ItemData)
                        end
                    end
                end

                local tax = math.floor(auction.CurrentBid * Config.Trade.AuctionTax)
                DataManager.AddCoins(player, auction.CurrentBid - tax)
                data.Trade.DealerRep = data.Trade.DealerRep + PlayerTradeData.RepGains.SuccessfulSale
            else
                -- No bids: return item to seller
                if auction.ItemType == "Potion" then
                    table.insert(data.Inventory.Potions, auction.ItemData)
                elseif auction.ItemType == "Plant" then
                    table.insert(data.Inventory.Plants, auction.ItemData)
                end
            end

            table.remove(data.Trade.Auctions, i)
        end
    end
end

-- ============================================================
-- REMOTE HANDLERS
-- ============================================================

local function setupRemoteHandlers()
    remotes.SendTradeRequest.OnServerEvent:Connect(function(player, targetPlayer)
        if not rateCheck(player) then return end
        PlayerTradeManager.SendTradeRequest(player, targetPlayer)
    end)

    remotes.ConfirmTrade.OnServerEvent:Connect(function(player, tradeId)
        if not rateCheck(player) then return end
        if type(tradeId) ~= "number" then return end
        PlayerTradeManager.ConfirmTrade(player, tradeId)
    end)

    remotes.CancelTrade.OnServerEvent:Connect(function(player, tradeId)
        if not rateCheck(player) then return end
        if type(tradeId) ~= "number" then return end
        PlayerTradeManager.CancelTrade(player, tradeId)
    end)

    remotes.ListOnStand.OnServerEvent:Connect(function(player, potionIndex, price)
        if not rateCheck(player) then return end
        if type(potionIndex) ~= "number" or type(price) ~= "number" then return end
        PlayerTradeManager.ListOnStand(player, potionIndex, price)
    end)

    remotes.BuyFromStand.OnServerEvent:Connect(function(player, sellerId, offerIndex)
        if not rateCheck(player) then return end
        if type(sellerId) ~= "number" or type(offerIndex) ~= "number" then return end
        PlayerTradeManager.BuyFromStand(player, sellerId, offerIndex)
    end)

    remotes.PostMarketOffer.OnServerEvent:Connect(function(player, itemType, itemIndex, price, isSecret)
        if not rateCheck(player) then return end
        if type(itemType) ~= "string" or type(itemIndex) ~= "number" or type(price) ~= "number" then return end
        PlayerTradeManager.PostMarketOffer(player, itemType, itemIndex, price, isSecret)
    end)

    remotes.BuyMarketOffer.OnServerEvent:Connect(function(player, sellerId, offerIndex)
        if not rateCheck(player) then return end
        if type(sellerId) ~= "number" or type(offerIndex) ~= "number" then return end
        PlayerTradeManager.BuyMarketOffer(player, sellerId, offerIndex)
    end)

    remotes.CreateAuction.OnServerEvent:Connect(function(player, itemType, itemIndex, minBid, durationIndex, buyoutPrice)
        if not rateCheck(player) then return end
        PlayerTradeManager.CreateAuction(player, itemType, itemIndex, minBid, durationIndex, buyoutPrice)
    end)

    remotes.BidOnAuction.OnServerEvent:Connect(function(player, sellerId, auctionIndex, bidAmount)
        if not rateCheck(player) then return end
        PlayerTradeManager.BidOnAuction(player, sellerId, auctionIndex, bidAmount)
    end)

    remotes.BuyoutAuction.OnServerEvent:Connect(function(player, sellerId, auctionIndex)
        if not rateCheck(player) then return end
        PlayerTradeManager.BuyoutAuction(player, sellerId, auctionIndex)
    end)
end

-- ============================================================
-- START
-- ============================================================

createRemotes()
setupRemoteHandlers()

-- Auction expiry check every 30 seconds
task.spawn(function()
    while true do
        auctionExpiryTick()
        task.wait(30)
    end
end)

return PlayerTradeManager
