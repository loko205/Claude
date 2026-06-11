-- Schnitzel-Dex: tracks which characters a player has discovered.
-- Discovery state lives in player attributes ("dex_<id>") so the client can
-- render the collection book without extra remotes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(script.Parent.Economy)

local Dex = {}

-- Marks a character as discovered and pays the discovery reward once.
function Dex.mark(player: Player, def)
	local key = "dex_" .. def.id
	if player:GetAttribute(key) then
		return
	end
	player:SetAttribute(key, true)
	local reward = math.floor(def.price * Config.DiscoveryRewardFactor)
	if reward > 0 then
		Economy.addCash(player, reward)
	end
	ReplicatedStorage.Remotes.Notify:FireClient(
		player,
		("NEW! %s added to your Schnitzel-Dex (+$%d)"):format(def.name, reward),
		def.rarityInfo.color
	)
end

-- Restores discovery attributes from a saved profile (no rewards).
function Dex.restore(player: Player, discovered: { [string]: boolean })
	for id in discovered do
		player:SetAttribute("dex_" .. id, true)
	end
end

return Dex
