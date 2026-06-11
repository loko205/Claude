-- Bootstrap: builds the map, wires modules, handles join/leave, income,
-- rebirth, daily streak, Gold Rush events, monetization and saving.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage.Shared.Config)
local Characters = require(ReplicatedStorage.Shared.Characters)

-- Remotes must exist before modules that reference them run handlers.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local notifyRemote = Instance.new("RemoteEvent")
notifyRemote.Name = "Notify"
notifyRemote.Parent = remotes
local rebirthRemote = Instance.new("RemoteEvent")
rebirthRemote.Name = "Rebirth"
rebirthRemote.Parent = remotes
remotes.Parent = ReplicatedStorage

local Map = require(script.Map)
local Plots = require(script.Plots)
local Economy = require(script.Economy)
local Conveyor = require(script.Conveyor)
local Steal = require(script.Steal)
local Data = require(script.Data)
local Dex = require(script.Dex)
local Monetize = require(script.Monetize)
local Leaderboard = require(script.Leaderboard)

local belt = Map.build()
Plots.init(belt)
Conveyor.init(belt)
Steal.init()
Plots.onSteal = Steal.trySteal
Leaderboard.init(belt.keyed.leaderboard)
MarketplaceService.ProcessReceipt = Monetize.processReceipt

local profiles: { [Player]: any } = {}

local function notify(player: Player, text: string, color: Color3?)
	notifyRemote:FireClient(player, text, color)
end

local function notifyAll(text: string, color: Color3?)
	notifyRemote:FireAllClients(text, color)
end

-- Saved slot entries are { id, mut? }; very old saves stored plain id strings.
local function entryToUnit(entry)
	local id = if type(entry) == "table" then entry.id else entry
	local def = Characters.byId(id)
	if not def then
		return nil
	end
	return { def = def, mut = type(entry) == "table" and Characters.getMutation(entry.mut) or nil }
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
	local reward = Config.DailyBase * math.min(profile.streak, Config.DailyStreakCap)
	Economy.addCash(player, reward)
	notify(player, ("Daily streak day %d: +$%d!"):format(profile.streak, reward), Color3.fromRGB(120, 220, 255))
end

local function onPlayerAdded(player: Player)
	local profile = Data.load(player)
	profiles[player] = profile

	player:SetAttribute("Rebirths", profile.rebirths)
	Dex.restore(player, profile.discovered or {})
	Economy.setup(player, profile.cash)
	Plots.assign(player)

	for _, entry in profile.slots do
		local unit = entryToUnit(entry)
		if unit then
			Plots.place(player, unit)
		end
	end

	if profile.lastSeen == 0 then
		-- First session: free starter character for instant progression.
		local def = Characters.byId("bratwurst_dog")
		if Plots.place(player, { def = def }) then
			notify(player, "Welcome! Here is a free Bratwurst Dog to get you started!", Color3.fromRGB(120, 255, 120))
			Dex.mark(player, def)
		end
	elseif profile.lastSeen > 0 and profile.incomeRate > 0 then
		local elapsed = math.min(os.time() - profile.lastSeen, Config.OfflineCap)
		local earned = math.floor(elapsed * profile.incomeRate * Config.OfflineRate)
		if earned > 0 then
			Economy.addCash(player, earned)
			notify(player, ("Welcome back! You earned $%d while away."):format(earned), Color3.fromRGB(120, 255, 120))
		end
	end

	grantDaily(player, profile)
end

local function snapshot(player: Player, profile)
	profile.cash = Economy.getCash(player)
	profile.rebirths = player:GetAttribute("Rebirths") or 0
	profile.incomeRate = Plots.getIncome(player)
	profile.lastSeen = os.time()
	local discovered = {}
	for _, def in Characters.List do
		if player:GetAttribute("dex_" .. def.id) then
			discovered[def.id] = true
		end
	end
	profile.discovered = discovered
end

local function onPlayerRemoving(player: Player)
	Steal.onPlayerRemoving(player)
	Monetize.onPlayerRemoving(player)
	local profile = profiles[player]
	if profile then
		snapshot(player, profile)
		profile.slots = Plots.release(player)
		Data.save(player, profile)
		Leaderboard.submit(player.UserId, profile.cash)
		profiles[player] = nil
	else
		Plots.release(player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player) -- players that joined before the connection
end

rebirthRemote.OnServerEvent:Connect(function(player)
	local rebirths = player:GetAttribute("Rebirths") or 0
	local cost = Config.RebirthBaseCost * Config.RebirthCostFactor ^ rebirths
	if not Economy.trySpend(player, cost) then
		notify(player, "Not enough cash to rebirth!", Color3.fromRGB(255, 80, 80))
		return
	end
	Plots.clear(player)
	player:SetAttribute("Rebirths", rebirths + 1)
	notify(
		player,
		("REBIRTH %d! Permanent +%d%% income!"):format(rebirths + 1, (rebirths + 1) * Config.RebirthIncomeBonus * 100),
		Color3.fromRGB(255, 120, 255)
	)
end)

-- Income tick (gamepass multipliers applied here).
task.spawn(function()
	while true do
		task.wait(Config.IncomeTick)
		for _, player in Players:GetPlayers() do
			local income = math.floor(Plots.getIncome(player) * Monetize.incomeMult(player))
			player:SetAttribute("Income", income)
			if income > 0 then
				Economy.addCash(player, income)
			end
		end
	end
end)

-- Gold Rush: server-wide luck boost on a fixed cycle, shared hype moment.
task.spawn(function()
	while true do
		task.wait(Config.GoldRushInterval)
		Conveyor.setLuck(Config.GoldRushLuck)
		notifyAll(
			("GOLD RUSH! %dx luck for %d seconds!"):format(Config.GoldRushLuck, Config.GoldRushDuration),
			Color3.fromRGB(255, 200, 60)
		)
		task.wait(Config.GoldRushDuration)
		Conveyor.setLuck(1)
		notifyAll("Gold Rush is over.", Color3.fromRGB(200, 200, 210))
	end
end)

-- Autosave.
task.spawn(function()
	while true do
		task.wait(Config.AutosaveInterval)
		for _, player in Players:GetPlayers() do
			local profile = profiles[player]
			if profile then
				local plot = Plots.get(player)
				if plot then
					local entries = {}
					for _, slot in plot.slots do
						table.insert(entries, { id = slot.unit.def.id, mut = slot.unit.mut and slot.unit.mut.name })
					end
					profile.slots = entries
				end
				snapshot(player, profile)
				Data.save(player, profile)
				Leaderboard.submit(player.UserId, profile.cash)
			end
		end
	end
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		onPlayerRemoving(player)
	end
end)
