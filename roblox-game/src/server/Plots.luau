-- Owns player bases: assignment, slots, placing/removing characters, locking, income.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Factory = require(script.Parent.Factory)

local Plots = {}

-- Wired by init.server to Steal.trySteal to avoid a circular require.
Plots.onSteal = nil :: ((thief: Player, plot: any, slotIndex: number) -> ())?

local plots = {} -- array of plot state tables
local plotByOwner: { [Player]: any } = {}

local function buildPart(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

local function buildPlot(origin: Vector3, index: number, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index

	buildPart({
		Name = "Floor",
		Size = Vector3.new(28, 1, 28),
		Position = origin + Vector3.new(0, 0.5, 0),
		Color = Color3.fromRGB(120, 120, 130),
		Material = Enum.Material.SmoothPlastic,
		Parent = model,
	})

	-- 12 slot pads in two rows of six.
	local pads = {}
	for i = 1, Config.PlotSlots do
		local row = math.floor((i - 1) / 6)
		local col = (i - 1) % 6
		local pad = buildPart({
			Name = "Pad" .. i,
			Size = Vector3.new(3, 0.4, 3),
			Position = origin + Vector3.new(-10 + col * 4, 1.2, -6 + row * 9),
			Color = Color3.fromRGB(80, 80, 90),
			Parent = model,
		})
		pads[i] = pad
	end

	-- Sign with the owner's name at the back of the plot.
	local towardCenter = origin.Z > 0 and -1 or 1
	local sign = buildPart({
		Name = "Sign",
		Size = Vector3.new(1, 8, 1),
		Position = origin + Vector3.new(0, 4, -towardCenter * 13),
		Color = Color3.fromRGB(60, 60, 70),
		Parent = model,
	})
	local signGui = Instance.new("BillboardGui")
	signGui.Size = UDim2.new(0, 240, 0, 50)
	signGui.StudsOffset = Vector3.new(0, 5, 0)
	signGui.AlwaysOnTop = true
	signGui.Parent = sign
	local signLabel = Instance.new("TextLabel")
	signLabel.BackgroundTransparency = 1
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.Font = Enum.Font.FredokaOne
	signLabel.Text = "Free Base"
	signLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	signLabel.TextScaled = true
	signLabel.TextStrokeTransparency = 0.3
	signLabel.Parent = signGui

	-- Lock button at the front edge.
	local lockButton = buildPart({
		Name = "LockButton",
		Size = Vector3.new(3, 1, 3),
		Position = origin + Vector3.new(0, 1.5, towardCenter * 13),
		Color = Color3.fromRGB(60, 160, 255),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	local lockPrompt = Instance.new("ProximityPrompt")
	lockPrompt.ActionText = ("Lock Base (%ds)"):format(Config.LockDuration)
	lockPrompt.ObjectText = "Base Shield"
	lockPrompt.RequiresLineOfSight = false
	lockPrompt.Parent = lockButton

	local shield = buildPart({
		Name = "Shield",
		Size = Vector3.new(28, 16, 28),
		Position = origin + Vector3.new(0, 8, 0),
		Color = Color3.fromRGB(100, 200, 255),
		Material = Enum.Material.ForceField,
		Transparency = 1,
		CanCollide = false,
		Parent = model,
	})

	model.Parent = parent

	local plot = {
		index = index,
		origin = origin,
		owner = nil :: Player?,
		slots = {} :: { [number]: { def: any, model: Model } },
		pads = pads,
		signLabel = signLabel,
		shield = shield,
		lockPrompt = lockPrompt,
		lockedUntil = 0,
		lockReadyAt = 0,
	}

	lockPrompt.Triggered:Connect(function(player)
		Plots.tryLock(player, plot)
	end)

	return plot
end

function Plots.init(plotOrigins: { Vector3 }, parent: Instance)
	for i, origin in plotOrigins do
		plots[i] = buildPlot(origin, i, parent)
	end
end

function Plots.get(player: Player)
	return plotByOwner[player]
end

function Plots.assign(player: Player)
	for _, plot in plots do
		if plot.owner == nil then
			plot.owner = player
			plot.signLabel.Text = player.DisplayName .. "'s Base"
			plotByOwner[player] = plot
			return plot
		end
	end
	return nil -- more players than plots; should not happen with matching server size
end

function Plots.isLocked(plot): boolean
	return os.clock() < plot.lockedUntil
end

function Plots.tryLock(player: Player, plot)
	if plot.owner ~= player then
		return
	end
	local now = os.clock()
	if now < plot.lockReadyAt then
		return
	end
	plot.lockedUntil = now + Config.LockDuration
	plot.lockReadyAt = now + Config.LockDuration + Config.LockCooldown
	plot.shield.Transparency = 0
	plot.lockPrompt.Enabled = false
	task.delay(Config.LockDuration, function()
		plot.shield.Transparency = 1
	end)
	task.delay(Config.LockDuration + Config.LockCooldown, function()
		plot.lockPrompt.Enabled = true
	end)
end

-- Places a character into the first free slot. Returns true on success.
function Plots.place(player: Player, def): boolean
	local plot = plotByOwner[player]
	if not plot then
		return false
	end
	local slotIndex
	for i = 1, Config.PlotSlots do
		if plot.slots[i] == nil then
			slotIndex = i
			break
		end
	end
	if not slotIndex then
		return false
	end

	local model = Factory.build(def, false)
	local pad = plot.pads[slotIndex]
	-- Characters on plots face the map center (the belt).
	local yaw = plot.origin.Z < 0 and math.pi or 0
	Factory.standOn(model, pad.Position + Vector3.new(0, pad.Size.Y / 2, 0), yaw)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Steal!"
	prompt.ObjectText = def.name
	prompt.HoldDuration = 1
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(thief)
		if thief ~= plot.owner and Plots.onSteal then
			Plots.onSteal(thief, plot, slotIndex)
		end
	end)

	model.Parent = workspace
	plot.slots[slotIndex] = { def = def, model = model }
	return true
end

-- Removes a slot and returns its definition (model is destroyed).
function Plots.removeSlot(plot, slotIndex: number)
	local slot = plot.slots[slotIndex]
	if not slot then
		return nil
	end
	plot.slots[slotIndex] = nil
	slot.model:Destroy()
	return slot.def
end

function Plots.getIncome(player: Player): number
	local plot = plotByOwner[player]
	if not plot then
		return 0
	end
	local income = 0
	for _, slot in plot.slots do
		income += slot.def.income
	end
	local rebirths = player:GetAttribute("Rebirths") or 0
	return math.floor(income * (1 + rebirths * Config.RebirthIncomeBonus))
end

function Plots.clear(player: Player)
	local plot = plotByOwner[player]
	if not plot then
		return
	end
	for i in plot.slots do
		local slot = plot.slots[i]
		plot.slots[i] = nil
		slot.model:Destroy()
	end
end

-- Frees the plot and returns the list of character ids for saving.
function Plots.release(player: Player): { string }
	local plot = plotByOwner[player]
	if not plot then
		return {}
	end
	local ids = {}
	for _, slot in plot.slots do
		table.insert(ids, slot.def.id)
	end
	Plots.clear(player)
	plot.owner = nil
	plot.signLabel.Text = "Free Base"
	plot.lockedUntil = 0
	plot.lockReadyAt = 0
	plot.shield.Transparency = 1
	plot.lockPrompt.Enabled = true
	plotByOwner[player] = nil
	return ids
end

return Plots
