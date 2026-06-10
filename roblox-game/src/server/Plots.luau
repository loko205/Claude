-- Owns player bases: assignment, slots, placing/removing characters, locking, income.
-- The plot geometry itself comes from MapBlueprint (via Map.build's keyed parts).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Factory = require(script.Parent.Factory)

local Plots = {}

-- Wired by init.server to Steal.trySteal to avoid a circular require.
Plots.onSteal = nil :: ((thief: Player, plot: any, slotIndex: number) -> ())?

local plots = {} -- array of plot state tables
local plotByOwner: { [Player]: any } = {}

local function makeSignLabel(board: Part): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 260, 0, 56)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 160
	gui.Parent = board

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = "Free Base"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	return label
end

function Plots.init(map)
	for i, origin in map.plotOrigins do
		local pads = {}
		for j = 1, Config.PlotSlots do
			pads[j] = map.keyed[("p%d_pad%d"):format(i, j)]
		end
		local lockButton = map.keyed[("p%d_lock"):format(i)]

		local lockPrompt = Instance.new("ProximityPrompt")
		lockPrompt.ActionText = ("Lock Base (%ds)"):format(Config.LockDuration)
		lockPrompt.ObjectText = "Base Shield"
		lockPrompt.RequiresLineOfSight = false
		lockPrompt.Parent = lockButton

		local plot = {
			index = i,
			origin = origin,
			owner = nil :: Player?,
			slots = {} :: { [number]: { def: any, model: Model } },
			pads = pads,
			signLabel = makeSignLabel(map.keyed[("p%d_sign"):format(i)]),
			shield = map.keyed[("p%d_shield"):format(i)],
			lockPrompt = lockPrompt,
			lockedUntil = 0,
			lockReadyAt = 0,
		}

		lockPrompt.Triggered:Connect(function(player)
			Plots.tryLock(player, plot)
		end)

		plots[i] = plot
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
	plot.shield.Transparency = 0.5
	plot.lockPrompt.Enabled = false
	task.delay(Config.LockDuration, function()
		if not Plots.isLocked(plot) then
			plot.shield.Transparency = 1
		end
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
