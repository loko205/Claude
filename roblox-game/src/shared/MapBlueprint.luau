-- Build plan for the whole static map. Pure data output (no Roblox types) so the
-- standalone Luau CLI can load it for preview rendering (tools/export_map.luau).
--
-- Part spec fields: s/p/c/m/t like Designs, plus
--   k  = key for parts the server logic needs to find (pads, signs, locks, shields)
--   nc = true -> CanCollide off (shields, portal planes)
-- Layout: belt runs along X at z=0, spawn plaza at -Z, 4 plots on each side (z = +/-60).

local MapBlueprint = {}

local STONE = { 150, 148, 140 }
local DARKMETAL = { 60, 60, 70 }
local PATH = { 185, 178, 168 }

function MapBlueprint.build()
	local parts = {}
	local function add(s, p, props)
		local spec = { s = s, p = p }
		if props then
			for key, value in props do
				spec[key] = value
			end
		end
		table.insert(parts, spec)
	end

	-- Ground
	add({ 400, 4, 400 }, { 0, -2, 0 }, { c = { 106, 158, 98 }, m = "Grass" })

	-- Spawn plaza (checker tiles), spawn pad itself is added by Map.luau
	for col = 0, 5 do
		for row = 0, 3 do
			local light = (col + row) % 2 == 0
			add({ 5, 0.24, 5 }, { -12.5 + col * 5, 0.12, -33.5 + row * 5 }, {
				c = light and { 205, 205, 200 } or { 168, 170, 176 },
			})
		end
	end

	-- Conveyor: platform, belt, rails, hazard ends
	add({ 140, 0.5, 10 }, { 0, 0.25, 0 }, { c = { 70, 72, 78 }, m = "Slate" })
	add({ 130, 0.7, 6 }, { 0, 0.85, 0 }, { c = { 45, 45, 52 }, m = "DiamondPlate" })
	add({ 130, 0.4, 0.4 }, { 0, 1.35, -3.1 }, { c = { 95, 95, 105 }, m = "Metal" })
	add({ 130, 0.4, 0.4 }, { 0, 1.35, 3.1 }, { c = { 95, 95, 105 }, m = "Metal" })
	add({ 1.5, 0.55, 10 }, { -66.2, 0.77, 0 }, { c = { 240, 200, 60 } })
	add({ 1.5, 0.55, 10 }, { 66.2, 0.77, 0 }, { c = { 240, 200, 60 } })

	-- Portal arches at both belt ends (characters emerge/vanish here)
	for _, x in { -68, 68 } do
		add({ 1.4, 7, 1.4 }, { x, 4.0, -4.2 }, { c = DARKMETAL, m = "Metal" })
		add({ 1.4, 7, 1.4 }, { x, 4.0, 4.2 }, { c = DARKMETAL, m = "Metal" })
		add({ 1.4, 1.4, 9.8 }, { x, 7.9, 0 }, { c = DARKMETAL, m = "Metal" })
		add({ 1.46, 0.3, 9.86 }, { x, 8.8, 0 }, { c = { 90, 220, 255 }, m = "Neon" })
		add({ 0.25, 6, 7.4 }, { x, 4.4, 0 }, { c = { 150, 90, 255 }, m = "Neon", t = 0.45, nc = true })
	end

	-- Stone paths from the belt to every plot
	for _, z in { -1, 1 } do
		for _, x in { -105, -35, 35, 105 } do
			add({ 6, 0.3, 40 }, { x, 0.15, z * 26 }, { c = PATH, m = "Concrete" })
		end
	end

	-- Golden schnitzel statue (landmark behind spawn)
	add({ 11, 1.2, 11 }, { 0, 0.6, -47 }, { c = STONE })
	add({ 8.5, 3.2, 8.5 }, { 0, 2.8, -47 }, { c = STONE })
	add({ 8.0, 6.6, 1.8 }, { 0, 8.0, -47 }, { c = { 235, 190, 90 }, m = "Metal" })
	add({ 2.3, 4.5, 1.7 }, { -4.6, 7.4, -47 }, { c = { 235, 190, 90 }, m = "Metal" })
	add({ 2.0, 3.9, 1.7 }, { 4.5, 8.5, -47 }, { c = { 235, 190, 90 }, m = "Metal" })
	add({ 5.2, 1.5, 1.7 }, { 0.5, 4.6, -47 }, { c = { 235, 190, 90 }, m = "Metal" })
	for _, sp in { { -1.8, 8.4 }, { 1.4, 9.5 }, { 2.4, 7.0 }, { -0.6, 6.0 }, { 0.4, 10.4 } } do
		add({ 0.55, 0.55, 0.3 }, { sp[1], sp[2], -47.95 }, { c = { 190, 145, 60 }, m = "Metal" })
	end
	add({ 4.0, 1.8, 0.3 }, { 0, 2.4, -41.4 }, { c = { 90, 70, 40 }, m = "Metal", k = "plaque" })

	-- Trees (voxel canopies)
	local treeSpots = {
		{ -140, -140 }, { 140, -140 }, { -140, 140 }, { 140, 140 },
		{ -155, 0 }, { 155, 0 }, { 0, 155 }, { 0, -155 },
		{ -100, -115 }, { 100, -115 }, { -100, 115 }, { 100, 115 },
	}
	for _, spot in treeSpots do
		local x, z = spot[1], spot[2]
		add({ 2.0, 8.5, 2.0 }, { x, 4.25, z }, { c = { 110, 80, 55 } })
		add({ 7.5, 4.6, 7.5 }, { x, 10.2, z }, { c = { 88, 150, 82 } })
		add({ 5.2, 3.4, 5.2 }, { x + 2.5, 9.0, z + 1.3 }, { c = { 104, 170, 92 } })
		add({ 4.6, 3.2, 4.6 }, { x - 2.3, 9.3, z - 1.2 }, { c = { 96, 160, 86 } })
		add({ 3.8, 2.6, 3.8 }, { x, 13.2, z }, { c = { 104, 170, 92 } })
	end

	-- Plots
	local plotOrigins = {}
	local plotIndex = 0
	for _, z in { -60, 60 } do
		for _, x in { -105, -35, 35, 105 } do
			plotIndex += 1
			local i = plotIndex
			table.insert(plotOrigins, { x, 0, z })
			local back = z + (z > 0 and 13 or -13)
			local front = z + (z > 0 and -12.5 or 12.5)

			add({ 28, 1, 28 }, { x, 0.5, z }, { c = { 92, 94, 104 }, m = "Slate" })
			add({ 24.5, 0.24, 24.5 }, { x, 1.12, z }, { c = { 138, 141, 152 } })

			for j = 1, 12 do
				local col = (j - 1) % 6
				local row = j <= 6 and -4.5 or 4.5
				local px = x - 10 + col * 4
				add({ 3, 0.34, 3 }, { px, 1.42, z + row }, { c = { 70, 72, 80 } })
				add({ 2.35, 0.16, 2.35 }, { px, 1.67, z + row }, {
					c = { 185, 188, 196 },
					k = ("p%d_pad%d"):format(i, j),
				})
			end

			for _, cx in { -12.5, 12.5 } do
				for _, cz in { -12.5, 12.5 } do
					add({ 1.2, 5, 1.2 }, { x + cx, 3, z + cz }, { c = { 105, 106, 118 } })
					add({ 0.8, 0.8, 0.8 }, { x + cx, 5.9, z + cz }, { c = { 255, 235, 170 }, m = "Neon" })
				end
			end

			add({ 0.5, 6.5, 0.5 }, { x, 4.25, back }, { c = { 80, 70, 60 } })
			add({ 6.5, 2.6, 0.5 }, { x, 6.2, back }, { c = { 50, 52, 60 }, k = ("p%d_sign"):format(i) })

			add({ 1.4, 1.1, 1.4 }, { x, 1.79, front }, { c = { 70, 72, 80 }, m = "Metal" })
			add({ 0.95, 0.35, 0.95 }, { x, 2.52, front }, {
				c = { 60, 160, 255 },
				m = "Neon",
				k = ("p%d_lock"):format(i),
			})

			add({ 28, 16, 28 }, { x, 8, z }, {
				c = { 100, 200, 255 },
				m = "ForceField",
				t = 1,
				nc = true,
				k = ("p%d_shield"):format(i),
			})
		end
	end

	return {
		parts = parts,
		plotOrigins = plotOrigins,
		belt = { startX = -65, endX = 65, topY = 1.2 },
	}
end

return MapBlueprint
