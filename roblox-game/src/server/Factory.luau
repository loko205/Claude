-- Assembles character models from the build plans in Shared/Designs.
-- A "unit" is { def = characterDef, mut = mutation? }; mutations re-tint the
-- base-colored parts and multiply income/price.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Designs = require(ReplicatedStorage.Shared.Designs)
local Characters = require(ReplicatedStorage.Shared.Characters)

local Factory = {}

local function label(parent: Instance, text: string, color: Color3, size: number)
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.new(1, 0, 0, size)
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.Text = text
	textLabel.TextColor3 = color
	textLabel.TextScaled = true
	textLabel.TextStrokeTransparency = 0.3
	textLabel.Parent = parent
end

-- Returns a fully assembled, anchored model. `showPrice` adds the price line
-- (used on the conveyor; placed characters only show name + income).
function Factory.build(unit, showPrice: boolean): Model
	local def, mut = unit.def, unit.mut
	local rarity = def.rarityInfo
	local scale = 1 + (rarity.tier - 1) * 0.12
	local design = Designs[def.id]

	local model = Instance.new("Model")
	model.Name = def.id

	for i, spec in design do
		local part = Instance.new("Part")
		part.Name = i == 1 and "Body" or "P" .. i
		part.Anchored = true
		part.CanCollide = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		if spec.b then
			part.Shape = Enum.PartType.Ball
		end
		part.Size = Vector3.new(spec.s[1], spec.s[2], spec.s[3]) * scale
		part.CFrame = CFrame.new(spec.p[1] * scale, spec.p[2] * scale, spec.p[3] * scale)
		part.Transparency = spec.t or 0

		-- Base-colored parts carry the mutation look; accent parts keep theirs.
		local isBasePart = spec.c == nil
		if isBasePart and mut then
			part.Color = mut.color
			part.Material = spec.m and (Enum.Material :: any)[spec.m] or mut.material
			if mut.name == "Rainbow" then
				CollectionService:AddTag(part, "RainbowPart")
			end
		else
			part.Color = if spec.c then Color3.fromRGB(spec.c[1], spec.c[2], spec.c[3]) else def.color
			part.Material = if spec.m then (Enum.Material :: any)[spec.m] else Enum.Material.SmoothPlastic
		end

		part.Parent = model
		if i == 1 then
			model.PrimaryPart = part
		end
	end

	-- Root pivot sits at design origin (y = 0); remember the lift to the model
	-- bottom so callers can rest it on any surface.
	local bboxCF, bboxSize = model:GetBoundingBox()
	model:SetAttribute("GroundLift", -(bboxCF.Y - bboxSize.Y / 2))
	if mut then
		model:SetAttribute("Mutation", mut.name)
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 170, 0, 76)
	billboard.StudsOffset = Vector3.new(0, bboxCF.Y + bboxSize.Y / 2 + 1.3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 70
	billboard.Parent = model.PrimaryPart

	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = billboard

	label(billboard, Characters.unitName(unit), mut and mut.color or rarity.color, 22)
	label(billboard, ("$%d/s"):format(Characters.unitIncome(unit)), Color3.fromRGB(255, 255, 255), 18)
	if showPrice then
		label(billboard, ("Buy: $%d"):format(Characters.unitPrice(unit)), Color3.fromRGB(120, 255, 120), 18)
	end

	return model
end

-- Rests the model's lowest point on `position`, optionally rotated around Y.
function Factory.standOn(model: Model, position: Vector3, yaw: number?)
	local lift = model:GetAttribute("GroundLift") or 0
	model:PivotTo(CFrame.new(position + Vector3.new(0, lift, 0)) * CFrame.Angles(0, yaw or 0, 0))
end

return Factory
