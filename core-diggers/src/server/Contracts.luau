-- Daily contracts: three random goals per day, auto-claimed on completion.
-- Progress lives on the profile; attributes mirror state for the client UI.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage.Shared.World)
local Economy = require(script.Parent.Economy)

local Contracts = {}

local profiles: { [Player]: any } = {}
local rng = Random.new()

local function notify(player: Player, text: string, color: Color3?)
	ReplicatedStorage.Remotes.Notify:FireClient(player, text, color)
end

local function describe(contract): string
	if contract.type == "blocks" then
		return ("Break %d blocks"):format(contract.need)
	elseif contract.type == "ore" then
		return ("Collect %d %s"):format(contract.need, World.Items[contract.id].name)
	elseif contract.type == "sell" then
		return ("Earn $%d from selling"):format(contract.need)
	end
	return ("Reach layer %d"):format(contract.need)
end

local function sync(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	for i = 1, World.DailyContracts do
		local contract = profile.contracts[i]
		player:SetAttribute(
			"contract_" .. i,
			contract and ("%s|%d|%d|%d|%s"):format(
				describe(contract),
				math.min(contract.have, contract.need),
				contract.need,
				contract.reward,
				contract.done and "1" or "0"
			) or ""
		)
	end
end

function Contracts.register(player: Player, profile)
	profiles[player] = profile

	local today = math.floor(os.time() / 86400)
	if profile.contractsDay ~= today then
		profile.contractsDay = today
		profile.contracts = {}
		local pool = table.clone(World.ContractPool)
		for _ = 1, World.DailyContracts do
			local pick = table.remove(pool, rng:NextInteger(1, #pool))
			table.insert(profile.contracts, {
				type = pick.type,
				id = pick.id,
				need = pick.need,
				reward = pick.reward,
				have = 0,
				done = false,
			})
		end
		notify(player, "3 new daily contracts! Check the CONTRACTS button.", Color3.fromRGB(120, 220, 255))
	end
	sync(player)
end

function Contracts.unregister(player: Player)
	profiles[player] = nil
end

local function progress(player: Player, kind: string, amount: number, id: string?, absolute: boolean?)
	local profile = profiles[player]
	if not profile then
		return
	end
	local changed = false
	for _, contract in profile.contracts do
		if not contract.done and contract.type == kind and (kind ~= "ore" or contract.id == id) then
			contract.have = absolute and math.max(contract.have, amount) or contract.have + amount
			changed = true
			if contract.have >= contract.need then
				contract.done = true
				Economy.addCash(player, contract.reward)
				notify(
					player,
					("CONTRACT DONE: %s — +$%d!"):format(describe(contract), contract.reward),
					Color3.fromRGB(120, 255, 120)
				)
			end
		end
	end
	if changed then
		sync(player)
	end
end

function Contracts.onBlock(player: Player)
	progress(player, "blocks", 1)
end

function Contracts.onOre(player: Player, id: string, count: number)
	progress(player, "ore", count, (id:gsub("^shiny_", "")))
end

function Contracts.onSell(player: Player, total: number)
	progress(player, "sell", total)
end

function Contracts.onDepth(player: Player, layerIndex: number)
	progress(player, "depth", layerIndex, nil, true)
end

return Contracts
