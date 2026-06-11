-- Build plan for the whole static map. Pure data output (no Roblox types) so the
-- standalone Luau CLI can load it for preview rendering (tools/export_map.luau).
--
-- Theme: a food-street valley. The 8 bases are colorful restaurant buildings
-- along a cobbled boulevard, the conveyor runs down the middle like a giant
-- sushi belt, the golden schnitzel statue sits on a terraced hill behind spawn,
-- and voxel mountains ring the playfield.
--
-- Part spec fields: s/p/c/m/t like Designs, plus
--   k  = key for parts the server logic needs to find (pads, signs, locks, shields)
--   nc = true -> CanCollide off (shields, portal planes, clouds)
-- Layout: belt runs along X at z=0, spawn plaza at -Z, 4 plots on each side (z = +/-60).

local MapBlueprint = {}

local STONE = { 150, 148, 140 }
local DARKMETAL = { 60, 60, 70 }
local PATH = { 185, 178, 168 }
local GOLD = { 235, 190, 90 }
local SILVER = { 200, 205, 215 }
local LAMPLIGHT = { 255, 220, 150 }

-- One accent color per plot so the street reads like a colorful food town.
local ACCENTS = {
	{ 235, 90, 80 }, { 245, 150, 60 }, { 245, 205, 70 }, { 110, 200, 110 },
	{ 80, 200, 190 }, { 90, 160, 245 }, { 170, 110, 235 }, { 245, 120, 180 },
}
local BUNTING = { { 235, 90, 80 }, { 245, 205, 70 }, { 90, 160, 245 }, { 110, 200, 110 } }

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

	-- ===== Ground & street =====
	add({ 400, 4, 400 }, { 0, -2, 0 }, { c = { 106, 158, 98 }, m = "Grass" })
	add({ 270, 0.36, 36 }, { 0, 0.18, 0 }, { c = { 140, 134, 126 }, m = "Cobblestone" })
	-- subtle grass tone patches against monotony
	for _, patch in { { -70, -90, 40 }, { 80, 100, 50 }, { -120, 80, 36 }, { 130, -70, 30 } } do
		add({ patch[3], 0.12, patch[3] * 0.8 }, { patch[1], 0.06, patch[2] }, { c = { 98, 148, 90 }, m = "Grass" })
	end

	-- Spawn plaza (checker tiles), spawn pad itself is added by Map.luau
	for col = 0, 5 do
		for row = 0, 3 do
			local light = (col + row) % 2 == 0
			add({ 5, 0.24, 5 }, { -12.5 + col * 5, 0.12, -38.5 + row * 5 }, {
				c = light and { 205, 205, 200 } or { 168, 170, 176 },
			})
		end
	end

	-- ===== Conveyor boulevard =====
	add({ 140, 0.5, 10 }, { 0, 0.25, 0 }, { c = { 70, 72, 78 }, m = "Slate" })
	add({ 130, 0.7, 6 }, { 0, 0.85, 0 }, { c = { 45, 45, 52 }, m = "DiamondPlate" })
	add({ 130, 0.4, 0.4 }, { 0, 1.35, -3.1 }, { c = { 95, 95, 105 }, m = "Metal" })
	add({ 130, 0.4, 0.4 }, { 0, 1.35, 3.1 }, { c = { 95, 95, 105 }, m = "Metal" })
	add({ 130, 0.12, 0.12 }, { 0, 1.58, -3.1 }, { c = { 90, 220, 255 }, m = "Neon" })
	add({ 130, 0.12, 0.12 }, { 0, 1.58, 3.1 }, { c = { 90, 220, 255 }, m = "Neon" })
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

	-- Street lamps + bunting strings with little flags
	local lampXs = { -120, -80, -40, 0, 40, 80, 120 }
	for _, z in { -17, 17 } do
		for li, x in lampXs do
			add({ 0.5, 7, 0.5 }, { x, 3.5, z }, { c = { 70, 70, 80 }, m = "Metal" })
			add({ 0.7, 0.7, 0.7 }, { x, 7.2, z }, { c = LAMPLIGHT, m = "Neon" })
			if li < #lampXs then
				add({ 40, 0.08, 0.08 }, { x + 20, 6.6, z }, { c = { 230, 230, 230 } })
				for f = 1, 4 do
					local color = BUNTING[(li + f) % #BUNTING + 1]
					add({ 0.55, 0.7, 0.1 }, { x + f * 8, 6.2, z }, { c = color })
				end
			end
		end
	end

	-- Stone paths from the street to every plot front
	for _, z in { -1, 1 } do
		for _, x in { -105, -35, 35, 105 } do
			add({ 6, 0.3, 26 }, { x, 0.15, z * 33 }, { c = PATH, m = "Concrete" })
		end
	end

	-- ===== Statue hill (terraces + stairs), flanked by giant fork & knife =====
	add({ 36, 6, 28 }, { 0, 3, -73 }, { c = { 96, 150, 88 }, m = "Grass" })
	add({ 26, 6, 20 }, { 0, 9, -75 }, { c = { 104, 158, 96 }, m = "Grass" })
	for i = 1, 4 do
		add({ 10, 1.5, 3.5 }, { 0, -0.75 + i * 1.5, -42.25 - i * 3.5 }, { c = STONE })
	end
	for i = 1, 4 do
		add({ 8, 1.5, 1.6 }, { 0, 5.25 + i * 1.5, -58.7 - i * 1.6 }, { c = STONE })
	end

	add({ 9, 1.2, 9 }, { 0, 12.6, -75 }, { c = STONE })
	add({ 7, 2.6, 7 }, { 0, 14.5, -75 }, { c = STONE })
	add({ 8.0, 6.6, 1.8 }, { 0, 19.5, -75 }, { c = GOLD, m = "Metal" })
	add({ 2.3, 4.5, 1.7 }, { -4.6, 18.9, -75 }, { c = GOLD, m = "Metal" })
	add({ 2.0, 3.9, 1.7 }, { 4.5, 20.0, -75 }, { c = GOLD, m = "Metal" })
	add({ 5.2, 1.5, 1.7 }, { 0.5, 16.1, -75 }, { c = GOLD, m = "Metal" })
	for _, sp in { { -1.8, 19.9 }, { 1.4, 21.0 }, { 2.4, 18.5 }, { -0.6, 17.5 }, { 0.4, 21.9 } } do
		add({ 0.55, 0.55, 0.3 }, { sp[1], sp[2], -75.95 }, { c = { 190, 145, 60 }, m = "Metal" })
	end
	add({ 4.0, 1.8, 0.3 }, { 0, 3.5, -58.8 }, { c = { 90, 70, 40 }, m = "Metal", k = "plaque" })

	-- Giant fork (left) and knife (right) flanking the bottom of the stairs
	add({ 0.8, 7, 0.8 }, { -9, 3.5, -54 }, { c = { 120, 85, 55 } })
	add({ 2.6, 0.8, 0.8 }, { -9, 7.4, -54 }, { c = SILVER, m = "Metal" })
	for _, dx in { -0.9, 0, 0.9 } do
		add({ 0.5, 3.2, 0.6 }, { -9 + dx, 9.4, -54 }, { c = SILVER, m = "Metal" })
	end
	add({ 0.9, 5, 0.9 }, { 9, 2.5, -54 }, { c = { 120, 85, 55 } })
	add({ 1.7, 6.5, 0.5 }, { 9, 8.25, -54 }, { c = SILVER, m = "Metal" })
	add({ 1.1, 1.2, 0.5 }, { 9.3, 11.9, -54 }, { c = SILVER, m = "Metal" })

	-- ===== Ketchup fountain (north side of the street) =====
	add({ 8, 0.4, 8 }, { 0, 0.4, 30 }, { c = STONE })
	for _, w in { { 7, 0, -3.2 }, { 7, 0, 3.2 }, { 1, -3.2, 0 }, { 1, 3.2, 0 } } do
		add({ w[1] == 7 and 7.4 or 1, 1.3, w[1] == 7 and 1 or 7.4 }, { w[2], 1.25, 30 + w[3] }, { c = STONE })
	end
	add({ 6, 0.3, 6 }, { 0, 1.35, 30 }, { c = { 220, 60, 50 }, t = 0.1 })
	add({ 1.6, 2.6, 1.6 }, { 0, 3.0, 30 }, { c = { 215, 50, 45 } })
	add({ 0.7, 0.8, 0.7 }, { 0, 4.7, 30 }, { c = { 245, 245, 240 } })
	add({ 0.35, 2.4, 0.35 }, { 0, 2.9, 30.6 }, { c = { 255, 70, 60 }, m = "Neon", t = 0.2, nc = true })

	-- ===== Market stalls beside the plaza =====
	for si, sx in { -26, 26 } do
		local stripe1 = si == 1 and { 235, 90, 80 } or { 90, 160, 245 }
		add({ 6, 2.2, 2 }, { sx, 1.1, -32 }, { c = { 150, 110, 70 }, m = "WoodPlanks" })
		for _, px in { -2.8, 2.8 } do
			for _, pz in { -1.8, 1.8 } do
				add({ 0.4, 5, 0.4 }, { sx + px, 2.5, -30 + pz }, { c = { 120, 85, 55 } })
			end
		end
		for ci = -1, 1 do
			add({ 2.05, 0.3, 5 }, { sx + ci * 2.05, 5.3, -30 }, {
				c = ci == 0 and { 245, 245, 240 } or stripe1,
			})
		end
		add({ 1.2, 1.2, 1.2 }, { sx - 1.6, 0.6, -28.4 }, { c = { 160, 120, 75 }, m = "WoodPlanks" })
		add({ 1.2, 1.2, 1.2 }, { sx - 0.3, 0.6, -28.2 }, { c = { 140, 100, 60 }, m = "WoodPlanks" })
		add({ 1.0, 1.0, 1.0 }, { sx - 1.0, 1.7, -28.3 }, { c = { 160, 120, 75 }, m = "WoodPlanks" })
	end

	-- ===== Leaderboard board (east of the plaza, facing the street) =====
	add({ 0.6, 7, 0.6 }, { 40.5, 3.5, -30 }, { c = { 80, 70, 60 } })
	add({ 0.6, 7, 0.6 }, { 47.5, 3.5, -30 }, { c = { 80, 70, 60 } })
	add({ 9, 5.2, 0.8 }, { 44, 7.2, -30 }, { c = { 38, 40, 48 }, k = "leaderboard" })
	add({ 9.4, 0.5, 0.9 }, { 44, 10.05, -30 }, { c = { 255, 200, 60 }, m = "Metal" })

	-- ===== Trees =====
	local treeSpots = {
		{ -140, -120 }, { 140, -120 }, { -140, 120 }, { 140, 120 },
		{ -150, 40 }, { 150, 40 }, { -150, -40 }, { 150, -40 },
		{ -100, 115 }, { 100, 115 }, { -60, -110 }, { 60, -110 },
		{ 0, 120 }, { -75, 105 }, { 75, 105 },
	}
	for _, spot in treeSpots do
		local x, z = spot[1], spot[2]
		add({ 2.0, 8.5, 2.0 }, { x, 4.25, z }, { c = { 110, 80, 55 } })
		add({ 7.5, 4.6, 7.5 }, { x, 10.2, z }, { c = { 88, 150, 82 } })
		add({ 5.2, 3.4, 5.2 }, { x + 2.5, 9.0, z + 1.3 }, { c = { 104, 170, 92 } })
		add({ 4.6, 3.2, 4.6 }, { x - 2.3, 9.3, z - 1.2 }, { c = { 96, 160, 86 } })
		add({ 3.8, 2.6, 3.8 }, { x, 13.2, z }, { c = { 104, 170, 92 } })
	end

	-- ===== Mountain ring (valley skyline) =====
	for i = 0, 15 do
		local angle = i * (math.pi * 2 / 16) + 0.13
		local radius = 168 + (i % 3) * 10
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		-- keep the statue hill sightline clear
		if not (math.abs(x) < 30 and z < -100) then
			local width = 26 + (i * 7) % 14
			local height = 15 + (i * 5) % 18
			local tone = i % 2 == 0 and { 108, 118, 106 } or { 122, 130, 118 }
			add({ width, height * 0.6, width * 0.9 }, { x, height * 0.3 - 1, z }, { c = tone, m = "Rock" })
			add({ width * 0.68, height * 0.55, width * 0.6 }, { x + width * 0.08, height * 0.6, z - width * 0.06 }, {
				c = { 132, 138, 128 },
				m = "Rock",
			})
			add({ width * 0.38, height * 0.45, width * 0.34 }, { x + width * 0.04, height * 0.92, z }, {
				c = { 150, 154, 146 },
				m = "Rock",
			})
		end
	end

	-- ===== Clouds =====
	for _, cl in { { -90, 70, -60 }, { 60, 78, 40 }, { 120, 66, -90 }, { -40, 84, 110 }, { 0, 74, -140 } } do
		add({ 14, 3, 8 }, { cl[1], cl[2], cl[3] }, { c = { 250, 250, 252 }, t = 0.25, nc = true })
		add({ 9, 2.6, 6 }, { cl[1] + 6, cl[2] + 1.4, cl[3] + 2 }, { c = { 250, 250, 252 }, t = 0.3, nc = true })
		add({ 7, 2.2, 5 }, { cl[1] - 6, cl[2] + 1, cl[3] - 2 }, { c = { 250, 250, 252 }, t = 0.3, nc = true })
	end

	-- ===== Restaurant-building plots =====
	local plotOrigins = {}
	local plotIndex = 0
	for _, z in { -60, 60 } do
		for _, x in { -105, -35, 35, 105 } do
			plotIndex += 1
			local i = plotIndex
			table.insert(plotOrigins, { x, 0, z })
			local dir = z > 0 and 1 or -1 -- +1: front faces -z (toward street)
			local backZ = z + dir * 13.4
			local frontZ = z - dir * 12.5
			local accent = ACCENTS[i]

			-- floor: stone border + warm wood interior
			add({ 28, 1, 28 }, { x, 0.5, z }, { c = { 92, 94, 104 }, m = "Slate" })
			add({ 24.5, 0.24, 24.5 }, { x, 1.12, z }, { c = { 172, 132, 86 }, m = "WoodPlanks" })

			-- back wall with accent trim, low side walls (thieves must use the front)
			add({ 28, 9, 1.2 }, { x, 5.5, backZ }, { c = { 225, 218, 205 }, m = "Brick" })
			add({ 28.2, 0.6, 1.3 }, { x, 10.2, backZ }, { c = accent })
			for _, sx in { -13.4, 13.4 } do
				add({ 1.2, 4, 26 }, { x + sx, 3, z + dir * 0.6 }, { c = { 225, 218, 205 }, m = "Brick" })
				add({ 1.3, 0.5, 26 }, { x + sx, 5.25, z + dir * 0.6 }, { c = accent })
			end

			-- striped awning over the open front, on two poles with lamps
			for seg = 0, 5 do
				add({ 4.85, 0.35, 6 }, { x - 12.15 + seg * 4.86, 8.3, frontZ - dir * 0.5 }, {
					c = seg % 2 == 0 and accent or { 245, 245, 240 },
				})
			end
			for _, px in { -13.7, 13.7 } do
				add({ 0.6, 8, 0.6 }, { x + px, 4, frontZ - dir * 2 }, { c = { 90, 90, 100 }, m = "Metal" })
				add({ 0.7, 0.7, 0.7 }, { x + px, 8.4, frontZ - dir * 2 }, { c = LAMPLIGHT, m = "Neon" })
			end

			-- 12 slot pads in two rows
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

			-- owner sign mounted on the back wall
			add({ 6.5, 2.6, 0.5 }, { x, 8.0, backZ - dir * 0.9 }, {
				c = { 50, 52, 60 },
				k = ("p%d_sign"):format(i),
			})

			-- lock pedestal at the entrance
			add({ 1.4, 1.1, 1.4 }, { x, 1.79, frontZ }, { c = { 70, 72, 80 }, m = "Metal" })
			add({ 0.95, 0.35, 0.95 }, { x, 2.52, frontZ }, {
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
