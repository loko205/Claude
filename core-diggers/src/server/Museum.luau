-- Relic museum: pedestals show donated relics (first donor per server gets the
-- nameplate); donating gives the player a permanent sell bonus.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage.Shared.World)
local RelicDesigns = require(ReplicatedStorage.Shared.RelicDesigns)
local Inventory = require(script.Parent.Inventory)
local Economy = require(script.Parent.Economy)

local Museum = {}

local pedestals: { [string]: { part: Part, label: TextLabel, filled: boolean } } = {}

local function notify(player: Player, text: string, color: Color3?)
	ReplicatedStorage.Remotes.Notify:FireClient(player, text, color)
end

local function makeLabel(part: Part, text: string): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 150, 0, 54)
	gui.StudsOffset = Vector3.new(0, 3.6, 0)
	gui.MaxDistance = 60
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = Color3.fromRGB(200, 200, 210)
	label.TextScaled = true
	label.TextStrokeTransparency = 0.4
	label.Parent = gui
	return label
end

local function buildRelicModel(relicId: string, position: Vector3)
	local model = Instance.new("Model")
	model.Name = relicId
	for _, spec in RelicDesigns[relicId] do
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Size = Vector3.new(spec.s[1], spec.s[2], spec.s[3])
		part.CFrame = CFrame.new(position + Vector3.new(spec.p[1], spec.p[2], spec.p[3]))
		part.Color = Color3.fromRGB(spec.c[1], spec.c[2], spec.c[3])
		part.Material = if spec.m then (Enum.Material :: any)[spec.m] else Enum.Material.SmoothPlastic
		part.Transparency = spec.t or 0
		part.Parent = model
	end
	model.Parent = workspace
end

function Museum.init(keyed: { [string]: Part })
	for index, relic in World.Relics do
		local part = keyed["ped_" .. index]
		pedestals[relic.id] = {
			part = part,
			label = makeLabel(part, "???"),
			filled = false,
		}
	end
end

function Museum.donate(player: Player, relicId: string)
	local relic = World.relic(relicId)
	if not relic or not Inventory.takeRelic(player, relicId) then
		return
	end
	local alreadyDonated = player:GetAttribute("don_" .. relicId) == true
	Inventory.markDonated(player, relicId)

	local pedestal = pedestals[relicId]
	if pedestal and not pedestal.filled then
		pedestal.filled = true
		local top = pedestal.part.Position + Vector3.new(0, pedestal.part.Size.Y / 2, 0)
		buildRelicModel(relicId, top)
		pedestal.label.Text = ("%s\nFound by %s"):format(relic.name, player.DisplayName)
		pedestal.label.TextColor3 = Color3.fromRGB(255, 205, 80)
		ReplicatedStorage.Remotes.Notify:FireAllClients(
			("%s donated %s to the museum!"):format(player.DisplayName, relic.name),
			Color3.fromRGB(255, 205, 80)
		)
	end

	if alreadyDonated then
		notify(player, ("Donated another %s (bonus already active)."):format(relic.name), Color3.fromRGB(200, 200, 210))
	else
		notify(
			player,
			("Museum bonus unlocked: permanent +%d%% sell value!"):format(World.MuseumBonusPerRelic * 100),
			Color3.fromRGB(120, 255, 120)
		)
	end
end

function Museum.sellRelic(player: Player, relicId: string)
	local relic = World.relic(relicId)
	if not relic or not Inventory.takeRelic(player, relicId) then
		return
	end
	local payout = math.floor(relic.value * Inventory.sellMultiplier(player))
	Economy.addCash(player, payout)
	notify(player, ("Sold %s for $%d."):format(relic.name, payout), Color3.fromRGB(120, 255, 120))
end

return Museum
