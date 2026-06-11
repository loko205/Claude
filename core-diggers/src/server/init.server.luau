-- Bootstrap: builds camp + island, wires remotes/prompts, handles join/leave,
-- selling, shop, museum, daily streak, meteor events, core prestige and saving.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local World = require(ReplicatedStorage.Shared.World)

-- Remotes must exist before modules that reference them run handlers.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
for _, name in { "Notify", "OpenUI", "Buy", "SellAll", "Donate", "SellRelic", "Teleport", "PlaceTorch", "UseBomb" } do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end
remotes.Parent = ReplicatedStorage
local notifyRemote = remotes.Notify

local Camp = require(script.Camp)
local Terrain = require(script.Terrain)
local Economy = require(script.Economy)
local Data = require(script.Data)
local Inventory = require(script.Inventory)
local Tools = require(script.Tools)
local Museum = require(script.Museum)
local Monetize = require(script.Monetize)
local Leaderboard = require(script.Leaderboard)
local Contracts = require(script.Contracts)
local Buffs = require(script.Buffs)

local keyed = Camp.build()
Terrain.init()
Museum.init(keyed)
Leaderboard.init(keyed.leaderboard)
MarketplaceService.ProcessReceipt = Monetize.processReceipt

local profiles: { [Player]: any } = {}
local teleportReady: { [Player]: number } = {}

local function notify(player: Player, text: string, color: Color3?)
	notifyRemote:FireClient(player, text, color)
end

-- Station prompts open the matching client UI.
for _, station in { { key = "sell", action = "Sell Loot", ui = "sell" }, { key = "shop", action = "Open Shop", ui = "shop" }, { key = "museum_sign", action = "Open Museum", ui = "museum" }, { key = "forge", action = "Open Forge", ui = "craft" } } do
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = station.action
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent = keyed[station.key]
	prompt.Triggered:Connect(function(player)
		if station.ui == "sell" then
			local total = Inventory.sellAll(player)
			notify(
				player,
				total > 0 and ("Sold everything for $%d!"):format(total) or "Nothing to sell yet — go dig!",
				total > 0 and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(200, 200, 210)
			)
		else
			remotes.OpenUI:FireClient(player, station.ui)
		end
	end)
end

Terrain.onCoreBroken = function(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.prestige += 1
	player:SetAttribute("Prestige", profile.prestige)
	notifyRemote:FireAllClients(
		("%s CRACKED THE CORE! (Prestige %d)"):format(player.DisplayName, profile.prestige),
		Color3.fromRGB(255, 120, 40)
	)
	player:SetAttribute("PerkPoints", (player:GetAttribute("PerkPoints") or 0) + 1)
	notify(
		player,
		("PRESTIGE %d! +%d%% sell value and +1 PERK POINT!"):format(profile.prestige, profile.prestige * World.Core.prestigeBonus * 100),
		Color3.fromRGB(255, 205, 80)
	)
end

local function grantDaily(player: Player, profile)
	local now = os.time()
	local today = math.floor(now / 86400)
	local lastDay = math.floor((profile.lastDaily or 0) / 86400)
	if today <= lastDay then
		return
	end
	profile.streak = (today - lastDay == 1) and (profile.streak or 0) + 1 or 1
	profile.lastDaily = now
	local reward = World.DailyBase * math.min(profile.streak, World.DailyStreakCap)
	Economy.addCash(player, reward)
	notify(player, ("Daily streak day %d: +$%d!"):format(profile.streak, reward), Color3.fromRGB(120, 220, 255))
end

local function onPlayerAdded(player: Player)
	local profile = Data.load(player)
	profiles[player] = profile

	player:SetAttribute("Shovel", profile.shovel)
	player:SetAttribute("Pack", profile.pack)
	player:SetAttribute("Prestige", profile.prestige)
	player:SetAttribute("DepthBest", profile.depthBest)
	for _, perk in World.Perks do
		player:SetAttribute("perk_" .. perk.id, (profile.perks or {})[perk.id] or 0)
	end
	local spent = 0
	for _, perk in World.Perks do
		spent += (profile.perks or {})[perk.id] or 0
	end
	player:SetAttribute("PerkPoints", profile.prestige - spent)
	Economy.setup(player, profile.cash)
	Inventory.register(player, profile)
	Contracts.register(player, profile)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		Tools.give(player)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.Died:Connect(function()
				-- dying underground costs part of the unbanked bag
				if character:GetPivot().Y < -World.BlockSize * 2 then
					Inventory.applyDeathPenalty(player)
				end
			end)
		end
	end)
	if player.Character then
		Tools.give(player)
	end

	if profile.lastSeen == 0 then
		notify(player, "Welcome to CORE DIGGERS! Grab your shovel and DIG DOWN!", Color3.fromRGB(90, 220, 255))
	end
	grantDaily(player, profile)
end

local function snapshot(player: Player, profile)
	profile.cash = Economy.getCash(player)
	profile.depthBest = math.max(profile.depthBest or 0, player:GetAttribute("DepthBest") or 0)
	profile.lastSeen = os.time()
end

local function onPlayerRemoving(player: Player)
	Terrain.onPlayerRemoving(player)
	Monetize.onPlayerRemoving(player)
	Buffs.onPlayerRemoving(player)
	teleportReady[player] = nil
	local profile = profiles[player]
	if profile then
		snapshot(player, profile)
		Data.save(player, profile)
		Leaderboard.submit(player.UserId, profile.depthBest)
		profiles[player] = nil
	end
	Inventory.unregister(player)
	Contracts.unregister(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- Remote handlers --------------------------------------------------------

remotes.Buy.OnServerEvent:Connect(function(player, kind, id)
	local profile = profiles[player]
	if not profile then
		return
	end
	if kind == "shovel" then
		local shovel = World.shovel(id)
		if shovel.id ~= id or shovel.id == profile.shovel then
			return
		end
		if shovel.costOres then
			for oreId, need in shovel.costOres do
				if Inventory.countOf(player, oreId) < need then
					notify(
						player,
						("You also need %d %s for this shovel!"):format(need, World.Items[oreId].name),
						Color3.fromRGB(255, 80, 80)
					)
					return
				end
			end
		end
		if not Economy.trySpend(player, shovel.price) then
			notify(player, "Not enough cash!", Color3.fromRGB(255, 80, 80))
			return
		end
		if shovel.costOres then
			Inventory.consumeOres(player, shovel.costOres)
		end
		profile.shovel = shovel.id
		player:SetAttribute("Shovel", shovel.id)
		Tools.give(player)
		notify(player, ("Equipped %s!"):format(shovel.name), Color3.fromRGB(120, 255, 120))
	elseif kind == "pack" then
		local packId = tonumber(id) or 0
		local pack = World.backpack(packId)
		if pack.id ~= packId or pack.id == profile.pack then
			return
		end
		if not Economy.trySpend(player, pack.price) then
			notify(player, "Not enough cash!", Color3.fromRGB(255, 80, 80))
			return
		end
		profile.pack = pack.id
		player:SetAttribute("Pack", pack.id)
		Inventory.register(player, profile) -- refresh capacity attributes
		notify(player, ("Equipped %s (%d slots)!"):format(pack.name, pack.cap), Color3.fromRGB(120, 255, 120))
	elseif kind == "craft" then
		for _, recipe in World.Recipes do
			if recipe.id == id then
				if not Inventory.consumeOres(player, recipe.cost) then
					notify(player, "Missing materials! Check the recipe.", Color3.fromRGB(255, 80, 80))
					return
				end
				Inventory.addGear(player, recipe.id, 1)
				notify(player, ("Crafted %s!"):format(recipe.name), Color3.fromRGB(120, 220, 255))
				return
			end
		end
	elseif kind == "perk" then
		local points = player:GetAttribute("PerkPoints") or 0
		if points < 1 then
			notify(player, "No perk points - crack the core for prestige!", Color3.fromRGB(255, 80, 80))
			return
		end
		for _, perk in World.Perks do
			if perk.id == id then
				profile.perks = profile.perks or {}
				local level = profile.perks[perk.id] or 0
				if level >= perk.max then
					notify(player, ("%s is already maxed."):format(perk.name), Color3.fromRGB(200, 200, 210))
					return
				end
				profile.perks[perk.id] = level + 1
				player:SetAttribute("perk_" .. perk.id, level + 1)
				player:SetAttribute("PerkPoints", points - 1)
				Inventory.register(player, profile) -- refresh capacity for Hauler
				notify(player, ("%s level %d unlocked!"):format(perk.name, level + 1), Color3.fromRGB(255, 205, 80))
				return
			end
		end
	elseif kind == "potion" then
		for _, potion in World.Potions do
			if potion.id == id then
				if not Economy.trySpend(player, potion.price) then
					notify(player, "Not enough cash!", Color3.fromRGB(255, 80, 80))
					return
				end
				Buffs.grant(player, potion.id, potion.duration)
				notify(player, ("%s active: %s!"):format(potion.name, potion.desc), Color3.fromRGB(190, 120, 235))
				return
			end
		end
	end
end)

remotes.SellAll.OnServerEvent:Connect(function(player)
	-- The sell button works from anywhere with the Portable Seller pass,
	-- otherwise only near the stand.
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local nearStand = root and (root.Position - keyed.sell.Position).Magnitude <= 14
	if not nearStand and not Monetize.canSellAnywhere(player) then
		notify(player, "Go to the sell stand (or get the Portable Seller pass)!", Color3.fromRGB(255, 80, 80))
		return
	end
	local total = Inventory.sellAll(player)
	if total > 0 then
		notify(player, ("Sold everything for $%d!"):format(total), Color3.fromRGB(120, 255, 120))
	end
end)

remotes.Donate.OnServerEvent:Connect(function(player, relicId)
	if type(relicId) == "string" then
		Museum.donate(player, relicId)
	end
end)

remotes.SellRelic.OnServerEvent:Connect(function(player, relicId)
	if type(relicId) == "string" then
		Museum.sellRelic(player, relicId)
	end
end)

remotes.Teleport.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if now < (teleportReady[player] or 0) then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	-- Deep teleports consume a Recall Flare (craftable at the forge).
	if character:GetPivot().Y < -World.FreeTeleportMaxLayer * World.BlockSize then
		if not Inventory.useGear(player, "flare") then
			notify(player, "Too deep! Craft a Recall Flare at the forge (or climb).", Color3.fromRGB(255, 80, 80))
			return
		end
	end
	teleportReady[player] = now + World.TeleportCooldown
	character:PivotTo(CFrame.new(0, 4, -68))
end)

remotes.PlaceTorch.OnServerEvent:Connect(function(player)
	if (player:GetAttribute("gear_torch") or 0) > 0 and Terrain.placeTorch(player) then
		Inventory.useGear(player, "torch")
	end
end)

remotes.UseBomb.OnServerEvent:Connect(function(player)
	if Inventory.useGear(player, "bomb") then
		Terrain.blast(player)
	end
end)

-- Loops -------------------------------------------------------------------

task.spawn(function()
	while true do
		task.wait(World.MeteorInterval)
		Terrain.meteor()
		notifyRemote:FireAllClients("METEOR IMPACT on the surface! Rich ore inside!", Color3.fromRGB(90, 220, 255))
	end
end)

task.spawn(function()
	while true do
		task.wait(World.AutosaveInterval)
		for _, player in Players:GetPlayers() do
			local profile = profiles[player]
			if profile then
				snapshot(player, profile)
				Data.save(player, profile)
				Leaderboard.submit(player.UserId, profile.depthBest)
			end
		end
	end
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		onPlayerRemoving(player)
	end
end)
