-- Builds the whole map procedurally: baseplate, spawn, conveyor belt, plot origins.
local Map = {}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

function Map.build()
	local folder = Instance.new("Folder")
	folder.Name = "Map"

	part({
		Name = "Baseplate",
		Size = Vector3.new(400, 4, 400),
		Position = Vector3.new(0, -2, 0),
		Color = Color3.fromRGB(90, 140, 90),
		Material = Enum.Material.Grass,
		Parent = folder,
	})

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Size = Vector3.new(14, 1, 14)
	spawnLocation.Position = Vector3.new(0, 0.5, -26)
	spawnLocation.Color = Color3.fromRGB(230, 230, 230)
	spawnLocation.Anchored = true
	spawnLocation.Duration = 0
	spawnLocation.Parent = folder

	-- Belt runs along the X axis through the map center.
	local beltLength = 130
	part({
		Name = "Belt",
		Size = Vector3.new(beltLength, 1, 6),
		Position = Vector3.new(0, 0.5, 0),
		Color = Color3.fromRGB(50, 50, 55),
		Material = Enum.Material.DiamondPlate,
		Parent = folder,
	})

	local plotOrigins = {}
	for _, z in { -60, 60 } do
		for _, x in { -105, -35, 35, 105 } do
			table.insert(plotOrigins, Vector3.new(x, 0, z))
		end
	end

	folder.Parent = workspace

	return {
		folder = folder,
		beltStartX = -beltLength / 2,
		beltEndX = beltLength / 2,
		beltTopY = 1,
		plotOrigins = plotOrigins,
	}
end

return Map
