--[[
    TradeUI.lua — Trade Interface (STUB)
    Direct trade, bulletin board, auction house, potion stand.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerTradeData = require(ReplicatedStorage.Shared.PlayerTradeData)

local TradeUI = {}
local player = Players.LocalPlayer

-- ============================================================
-- TODO: DIRECT TRADE (P2P Trade Window)
-- ============================================================
-- [ ] Trade request popup ("Player X wants to trade!")
-- [ ] Split trade window: Left = My items, Right = Other items
-- [ ] Drag & drop: Drag items from inventory into trade window
-- [ ] Coins field: Manually enter coin amount
-- [ ] Confirmation buttons: "Confirm" (green) / "Cancel" (red)
-- [ ] 10s anti-scam countdown after confirmation (large timer)
-- [ ] Changes after confirm reset the timer (warning!)
-- [ ] Trust display: Trust level with the other player

-- ============================================================
-- TODO: POTION STAND
-- ============================================================
-- [ ] Stand as 3D object in front of the player's garden
-- [ ] Stand design based on dealer rank (Basic → Luxury)
-- [ ] Offer slots with potion icons + price
-- [ ] "List item" dialog: Select potion, set price
-- [ ] Visitor view: See other player's offers + "Buy"
-- [ ] Dealer rank badge above the stand
-- [ ] Regular customer badge for favorite sellers

-- ============================================================
-- TODO: BULLETIN BOARD (Marketplace)
-- ============================================================
-- [ ] Board UI as scrollable list
-- [ ] Filter: Type (Plant/Potion), purity, price, rarity
-- [ ] Sorting: Newest, price (asc/desc), purity, rarity
-- [ ] Secret offers: Visible from rep 1000, golden frame
-- [ ] "Buy" button + confirmation dialog
-- [ ] "Manage own offers" tab
-- [ ] "List offer" dialog
-- [ ] Regular customer discount auto-display ("-10%")

-- ============================================================
-- TODO: AUCTION HOUSE
-- ============================================================
-- [ ] Premium UI with golden border
-- [ ] Active auctions as cards (item image, current bid, timer)
-- [ ] "Place bid" dialog (with minimum bid display)
-- [ ] "Buy now" button (if buyout price is set)
-- [ ] Manage own auctions
-- [ ] "New auction" dialog: Choose item, minimum bid, duration, buyout
-- [ ] Bid history per auction

-- ============================================================
-- TODO: DEALER RANK DISPLAY
-- ============================================================
-- [ ] Rank above the player's head (Billboard GUI)
-- [ ] Rank color: Apprentice=Gray, Alchemist=Green, Master Brewer=Blue, etc.
-- [ ] Aura effect from "Master Brewer" onward
-- [ ] Glowing name from "Grand Master" onward

-- Placeholder initialization
function TradeUI.Init()
    print("[TradeUI] Initialized (STUB)")
end

TradeUI.Init()

return TradeUI
