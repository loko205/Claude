-- Instantiates the CampBlueprint plus Roblox-only pieces: spawn, signs, lighting.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local CampBlueprint = require(ReplicatedStorage.Shared.CampBlueprint)

local Camp = {}

local function setupLighting()
	Lighting.ClockTime = 10.2
	Lighting.Brightness = 2.4
	Lighting.OutdoorAmbient = Color3.fromRGB(125, 125, 135)

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Offset = 0.6 -- sky island: lots of haze toward the horizon
	atmosphere.Color = Color3.fromRGB(205, 210, 225)
	atmosphere.Haze = 2
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.8
	bloom.Size = 26
	bloom.Threshold = 1.15
	bloom.Parent = Lighting
end

local function addBillboard(part: Part, lines: { { string | number | Color3 } }, offset: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 320, 0, 90)
	billboard.StudsOffset = Vector3.new(0, offset, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120
	billboard.Parent = part
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = billboard
	for _, line in lines do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, line[2])
		label.Font = Enum.Font.FredokaOne
		label.Text = line[1] :: string
		label.TextColor3 = line[3] :: Color3
		label.TextScaled = true
		label.TextStrokeTransparency = 0.25
		label.Parent = billboard
	end
end

function Camp.build()
	local blueprint = CampBlueprint.build()
	local folder = Instance.new("Folder")
	folder.Name = "Camp"

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
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.Position = Vector3.new(0, 0.5, -68)
	spawnLocation.Color = Color3.fromRGB(225, 225, 228)
	spawnLocation.Anchored = true
	spawnLocation.Duration = 0
	spawnLocation.Parent = folder

	addBillboard(keyed.sell, { { "SELL LOOT", 30, Color3.fromRGB(120, 255, 120) } }, 5)
	addBillboard(keyed.shop, { { "SHOVEL SHOP", 30, Color3.fromRGB(120, 190, 255) } }, 5)
	addBillboard(keyed.museum_sign, {
		{ "MUSEUM", 34, Color3.fromRGB(255, 205, 80) },
		{ "Donate relics for permanent sell bonuses", 20, Color3.fromRGB(255, 255, 255) },
	}, 3)
	addBillboard(keyed.dig_sign, {
		{ "DIG DOWN!", 30, Color3.fromRGB(255, 205, 80) },
		{ "Reach THE CORE at layer 36", 20, Color3.fromRGB(255, 255, 255) },
	}, 2.6)

	-- Floating title above the island center
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = Vector3.new(0, 26, 0)
	anchor.Parent = folder
	addBillboard(anchor, {
		{ "CORE DIGGERS", 56, Color3.fromRGB(90, 220, 255) },
		{ "Dig. Get rich. Crack the core.", 30, Color3.fromRGB(255, 255, 255) },
	}, 0)

	setupLighting()
	workspace.FallenPartsDestroyHeight = -260

	folder.Parent = workspace
	return keyed
end

return Camp
