-- Gamepasses and developer products. Ids live in World.Monetization;
-- an id of 0 means "not created yet" and disables the item safely.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage.Shared.World)
local Economy = require(script.Parent.Economy)

local Monetize = {}

local M = World.Monetization
local passCache: { [Player]: { [number]: boolean } } = {}

function Monetize.ownsPass(player: Player, passId: number): boolean
	if passId == 0 then
		return false
	end
	local cache = passCache[player]
	if not cache then
		cache = {}
		passCache[player] = cache
	end
	if cache[passId] == nil then
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
		cache[passId] = ok and owns or false
	end
	return cache[passId]
end

function Monetize.sellMult(player: Player): number
	return Monetize.ownsPass(player, M.GamepassDoubleCash) and 2 or 1
end

function Monetize.luckBonus(player: Player): number
	return Monetize.ownsPass(player, M.GamepassVIP) and World.VIPLuck or 0
end

function Monetize.capBonus(player: Player): number
	return Monetize.ownsPass(player, M.GamepassVIP) and World.VIPCapacity or 0
end

function Monetize.canSellAnywhere(player: Player): boolean
	return Monetize.ownsPass(player, M.GamepassPortableSeller)
end

local productAmounts = {
	[M.ProductCashSmall] = World.CashProductAmounts.Small,
	[M.ProductCashMedium] = World.CashProductAmounts.Medium,
	[M.ProductCashLarge] = World.CashProductAmounts.Large,
}
productAmounts[0] = nil -- unconfigured ids must never match

function Monetize.processReceipt(receiptInfo): Enum.ProductPurchaseDecision
	local amount = productAmounts[receiptInfo.ProductId]
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not amount or not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Economy.addCash(player, amount)
	ReplicatedStorage.Remotes.Notify:FireClient(
		player,
		("+$%d — thanks for the support!"):format(amount),
		Color3.fromRGB(120, 255, 120)
	)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Monetize.onPlayerRemoving(player: Player)
	passCache[player] = nil
end

return Monetize
