-- Gamepasses and developer products. All ids live in Config.Monetization;
-- an id of 0 means "not created yet" and disables the item safely.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(script.Parent.Economy)

local Monetize = {}

local M = Config.Monetization
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

function Monetize.incomeMult(player: Player): number
	local mult = 1
	if Monetize.ownsPass(player, M.GamepassDoubleCash) then
		mult *= 2
	end
	if Monetize.ownsPass(player, M.GamepassVIP) then
		mult *= 1 + Config.VIPIncomeBonus
	end
	return mult
end

local productAmounts = {
	[M.ProductCashSmall] = Config.CashProductAmounts.Small,
	[M.ProductCashMedium] = Config.CashProductAmounts.Medium,
	[M.ProductCashLarge] = Config.CashProductAmounts.Large,
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
