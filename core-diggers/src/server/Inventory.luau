-- Per-player loot state (lives directly on the profile table, so saving is
-- automatic). Capacity counts materials + ores; relics are weightless.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage.Shared.World)
local Economy = require(script.Parent.Economy)
local Monetize = require(script.Parent.Monetize)
local Contracts = require(script.Parent.Contracts)

local Inventory = {}

local profiles: { [Player]: any } = {}
local rng = Random.new()

local function notify(player: Player, text: string, color: Color3?)
	ReplicatedStorage.Remotes.Notify:FireClient(player, text, color)
end

local function bagCount(profile): number
	local n = 0
	for _, count in profile.inv do
		n += count
	end
	return n
end

-- Light sync for the hot mining path (full relic sync only when relics change).
local function syncBag(player: Player)
	local profile = profiles[player]
	if profile then
		player:SetAttribute("Bag", bagCount(profile))
	end
end

local function syncAttrs(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	player:SetAttribute("Bag", bagCount(profile))
	player:SetAttribute("BagCap", World.backpack(profile.pack).cap + Monetize.capBonus(player))
	for _, relic in World.Relics do
		player:SetAttribute("relic_" .. relic.id, profile.relics[relic.id] or 0)
		player:SetAttribute("don_" .. relic.id, profile.donated[relic.id] == true)
	end
end

function Inventory.register(player: Player, profile)
	profiles[player] = profile
	syncAttrs(player)
end

function Inventory.unregister(player: Player)
	profiles[player] = nil
end

function Inventory.get(player: Player)
	return profiles[player]
end

function Inventory.isFull(player: Player): boolean
	local profile = profiles[player]
	if not profile then
		return true
	end
	return bagCount(profile) >= World.backpack(profile.pack).cap + Monetize.capBonus(player)
end

local function rollRelic(layerIndex: number): string?
	if rng:NextNumber() < World.MythicRelicFactor then
		local mythics = {}
		for _, relic in World.Relics do
			if relic.layer == 0 then
				table.insert(mythics, relic.id)
			end
		end
		return mythics[rng:NextInteger(1, #mythics)]
	end
	for _, relic in World.Relics do
		if relic.layer == layerIndex then
			return relic.id
		end
	end
	return nil
end

-- Awards loot for a broken block. `layerLike` needs matId + ores; layerIndex
-- picks the relic pool (0 for meteor blocks = topsoil pool).
function Inventory.award(player: Player, layerLike, layerIndex: number, luck: number)
	local profile = profiles[player]
	if not profile then
		return
	end

	profile.inv[layerLike.matId] = (profile.inv[layerLike.matId] or 0) + 1

	for _, ore in layerLike.ores do
		if rng:NextNumber() < ore.chance * (1 + luck) then
			local id = ore.id
			local shiny = rng:NextNumber() < World.ShinyChance
			local key = shiny and "shiny_" .. id or id
			profile.inv[key] = (profile.inv[key] or 0) + 1
			Contracts.onOre(player, id, 1)
			local item = World.Items[id]
			if shiny then
				notify(player, ("SHINY %s! (worth %dx)"):format(item.name, World.ShinyMult), Color3.fromRGB(255, 230, 120))
			elseif item.value >= 300 then
				notify(player, ("Found %s!"):format(item.name), Color3.fromRGB(item.color[1], item.color[2], item.color[3]))
			end
			break
		end
	end

	if rng:NextNumber() < World.RelicChance * (1 + luck) then
		local relicId = rollRelic(math.max(layerIndex, 1))
		if relicId then
			profile.relics[relicId] = (profile.relics[relicId] or 0) + 1
			player:SetAttribute("relic_" .. relicId, profile.relics[relicId])
			local relic = World.relic(relicId)
			notify(player, ("RELIC FOUND: %s! Bring it to the museum!"):format(relic.name), Color3.fromRGB(255, 205, 80))
			if relic.layer == 0 then
				ReplicatedStorage.Remotes.Notify:FireAllClients(
					("%s dug up a mythic relic: %s!"):format(player.DisplayName, relic.name),
					Color3.fromRGB(255, 150, 220)
				)
			end
		end
	end

	syncBag(player)
end

-- Visible ore veins pay out a guaranteed bundle.
function Inventory.awardVein(player: Player, oreId: string, count: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	local shinies = 0
	for _ = 1, count do
		local shiny = rng:NextNumber() < World.ShinyChance
		local key = shiny and "shiny_" .. oreId or oreId
		profile.inv[key] = (profile.inv[key] or 0) + 1
		if shiny then
			shinies += 1
		end
	end
	Contracts.onOre(player, oreId, count)
	local item = World.Items[oreId]
	notify(
		player,
		("ORE VEIN: %dx %s%s!"):format(count, item.name, shinies > 0 and (" (%d SHINY!)"):format(shinies) or ""),
		Color3.fromRGB(item.color[1], item.color[2], item.color[3])
	)
	syncBag(player)
end

-- Golden treasure blocks burst into cash scaled by the layer's material value.
function Inventory.awardTreasure(player: Player, layerLike)
	local base = World.Items[layerLike.matId].value
	local payout = math.floor(base * rng:NextInteger(World.TreasureMult.min, World.TreasureMult.max))
	Economy.addCash(player, payout)
	notify(player, ("TREASURE BLOCK! +$%d"):format(payout), Color3.fromRGB(255, 205, 80))
end

function Inventory.itemValue(key: string): number
	local id = key:gsub("^shiny_", "")
	local item = World.Items[id]
	if not item then
		return 0
	end
	return key:find("^shiny_") and item.value * World.ShinyMult or item.value
end

function Inventory.sellMultiplier(player: Player): number
	local profile = profiles[player]
	local donated = 0
	for _, relic in World.Relics do
		if profile and profile.donated[relic.id] then
			donated += 1
		end
	end
	local prestige = profile and profile.prestige or 0
	return (1 + prestige * World.Core.prestigeBonus)
		* (1 + donated * World.MuseumBonusPerRelic)
		* Monetize.sellMult(player)
end

function Inventory.sellAll(player: Player): number
	local profile = profiles[player]
	if not profile then
		return 0
	end
	local total = 0
	for key, count in profile.inv do
		total += Inventory.itemValue(key) * count
	end
	total = math.floor(total * Inventory.sellMultiplier(player))
	if total > 0 then
		profile.inv = {}
		Economy.addCash(player, total)
		Contracts.onSell(player, total)
	end
	syncAttrs(player)
	return total
end

function Inventory.takeRelic(player: Player, relicId: string): boolean
	local profile = profiles[player]
	if not profile or (profile.relics[relicId] or 0) < 1 then
		return false
	end
	profile.relics[relicId] -= 1
	syncAttrs(player)
	return true
end

function Inventory.markDonated(player: Player, relicId: string)
	local profile = profiles[player]
	if profile then
		profile.donated[relicId] = true
	end
	syncAttrs(player)
end

return Inventory
