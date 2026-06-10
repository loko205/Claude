-- Instantiates the MapBlueprint, plus Roblox-only pieces: spawn, title sign, lighting.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local MapBlueprint = require(ReplicatedStorage.Shared.MapBlueprint)

local Map = {}

local function setupLighting()
	Lighting.ClockTime = 14.3
	Lighting.Brightness = 2.6
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 130)

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(199, 199, 210)
	atmosphere.Haze = 1.5
	atmosphere.Parent = Lighting

	-- Bloom makes the neon characters and lamps pop.
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.9
	bloom.Size = 28
	bloom.Threshold = 1.1
	bloom.Parent = Lighting
end

local function addTitleSign(folder: Folder)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = Vector3.new(0, 12, -46)
	anchor.Parent = folder

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 460, 0, 110)
	billboard.MaxDistance = 250
	billboard.Parent = anchor

	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = billboard

	for _, line in { { "STEAL A SCHNITZEL", 56, Color3.fromRGB(255, 205, 80) }, { "Buy. Earn. STEAL!", 34, Color3.fromRGB(255, 255, 255) } } do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, line[2])
		label.Font = Enum.Font.FredokaOne
		label.Text = line[1]
		label.TextColor3 = line[3]
		label.TextScaled = true
		label.TextStrokeTransparency = 0.2
		label.Parent = billboard
	end
end

function Map.build()
	local blueprint = MapBlueprint.build()
	local folder = Instance.new("Folder")
	folder.Name = "Map"

	local keyed: { [string]: Part } = {}
	for _, spec in blueprint.parts do
		local part = Instance.new("Part")
		part.Anchored = true
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Size = Vector3.new(spec.s[1], spec.s[2], spec.s[3])
		part.Position = Vector3.new(spec.p[1], spec.p[2], spec.p[3])
		if spec.c then
			part.Color = Color3.fromRGB(spec.c[1], spec.c[2], spec.c[3])
		end
		part.Material = if spec.m then (Enum.Material :: any)[spec.m] else Enum.Material.SmoothPlastic
		part.Transparency = spec.t or 0
		part.CanCollide = not spec.nc
		if spec.k then
			part.Name = spec.k
			keyed[spec.k] = part
		end
		part.Parent = folder
	end

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Size = Vector3.new(14, 1, 14)
	spawnLocation.Position = Vector3.new(0, 0.62, -26)
	spawnLocation.Color = Color3.fromRGB(228, 228, 232)
	spawnLocation.Anchored = true
	spawnLocation.Duration = 0
	spawnLocation.Parent = folder

	addTitleSign(folder)
	setupLighting()

	folder.Parent = workspace

	local plotOrigins = {}
	for i, origin in blueprint.plotOrigins do
		plotOrigins[i] = Vector3.new(origin[1], origin[2], origin[3])
	end

	return {
		folder = folder,
		keyed = keyed,
		plotOrigins = plotOrigins,
		beltStartX = blueprint.belt.startX,
		beltEndX = blueprint.belt.endX,
		beltTopY = blueprint.belt.topY,
	}
end

return Map
