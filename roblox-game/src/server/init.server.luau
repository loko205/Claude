-- Bootstrap: builds the map, wires modules, handles join/leave, income, rebirth, saving.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local belt = Map.build()
Plots.init(belt.plotOrigins, belt.folder)
Conveyor.init(belt)
Steal.init()
Plots.onSteal = Steal.trySteal

local profiles: { [Player]: any } = {}

local function notify(player: Player, text: string, color: Color3?)
	notifyRemote:FireClient(player, text, color)
end

local function onPlayerAdded(player: Player)
	local profile = Data.load(player)
	profiles[player] = profile

	player:SetAttribute("Rebirths", profile.rebirths)
	Economy.setup(player, profile.cash)
	Plots.assign(player)

	for _, id in profile.slots do
		local def = Characters.byId(id)
		if def then
			Plots.place(player, def)
		end
	end

	if profile.lastSeen > 0 and profile.incomeRate > 0 then
		local elapsed = math.min(os.time() - profile.lastSeen, Config.OfflineCap)
		local earned = math.floor(elapsed * profile.incomeRate * Config.OfflineRate)
		if earned > 0 then
			Economy.addCash(player, earned)
			notify(player, ("Welcome back! You earned $%d while away."):format(earned), Color3.fromRGB(120, 255, 120))
		end
	end
end

local function saveProfile(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.cash = Economy.getCash(player)
	profile.rebirths = player:GetAttribute("Rebirths") or 0
	profile.incomeRate = Plots.getIncome(player)
	profile.lastSeen = os.time()
	Data.save(player, profile)
end

local function onPlayerRemoving(player: Player)
	Steal.onPlayerRemoving(player)
	local profile = profiles[player]
	if profile then
		profile.cash = Economy.getCash(player)
		profile.rebirths = player:GetAttribute("Rebirths") or 0
		profile.incomeRate = Plots.getIncome(player)
		profile.slots = Plots.release(player)
		profile.lastSeen = os.time()
		Data.save(player, profile)
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

-- Income tick.
task.spawn(function()
	while true do
		task.wait(Config.IncomeTick)
		for _, player in Players:GetPlayers() do
			local income = Plots.getIncome(player)
			player:SetAttribute("Income", income)
			if income > 0 then
				Economy.addCash(player, income)
			end
		end
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
					local ids = {}
					for _, slot in plot.slots do
						table.insert(ids, slot.def.id)
					end
					profile.slots = ids
				end
				saveProfile(player)
			end
		end
	end
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		onPlayerRemoving(player)
	end
end)
