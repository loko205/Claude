-- Builds character models from definitions (procedural voxel look, no assets needed).
local Factory = {}

local function block(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

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
	return textLabel
end

-- Returns a fully assembled, anchored model. `showPrice` adds the price line
-- (used on the conveyor; placed characters only show name + income).
function Factory.build(def, showPrice: boolean): Model
	local rarity = def.rarityInfo
	local scale = 1 + (rarity.tier - 1) * 0.2

	local model = Instance.new("Model")
	model.Name = def.id

	local body = block({
		Name = "Body",
		Size = Vector3.new(2, 2.4, 1.4) * scale,
		Color = def.color,
		Material = rarity.tier >= 6 and Enum.Material.Neon or Enum.Material.SmoothPlastic,
	})
	body.Parent = model
	model.PrimaryPart = body

	local head = block({
		Name = "Head",
		Size = Vector3.new(1.5, 1.5, 1.5) * scale,
		Color = def.color,
		Material = body.Material,
	})
	head.CFrame = body.CFrame * CFrame.new(0, (body.Size.Y + head.Size.Y) / 2, 0)
	head.Parent = model

	for _, side in { -1, 1 } do
		local eye = block({
			Name = "Eye",
			Size = Vector3.new(0.3, 0.3, 0.1) * scale,
			Color = Color3.new(0, 0, 0),
		})
		eye.CFrame = head.CFrame * CFrame.new(side * 0.35 * scale, 0.2 * scale, -head.Size.Z / 2)
		eye.Parent = model
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 160, 0, 70)
	billboard.StudsOffset = Vector3.new(0, head.Size.Y + 1.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 70
	billboard.Parent = body

	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = billboard

	label(billboard, def.name, rarity.color, 22)
	label(billboard, ("$%d/s"):format(def.income), Color3.fromRGB(255, 255, 255), 18)
	if showPrice then
		label(billboard, ("Buy: $%d"):format(def.price), Color3.fromRGB(120, 255, 120), 18)
	end

	return model
end

return Factory
