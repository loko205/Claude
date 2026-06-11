-- Static camp + sky dressing around the diggable island. Pure data for the CLI.
-- The island blocks themselves are spawned by server/Terrain.
-- Spec fields: s/p/c/m/t, k = key for parts the server wires up, nc = no collide.
-- Island top surface is y = 0, island spans x/z -52..52; the camp deck hangs
-- off the north edge (negative z).

local CampBlueprint = {}

local WOOD = { 150, 110, 70 }
local DARKWOOD = { 110, 80, 52 }
local METAL = { 120, 122, 132 }

function CampBlueprint.build()
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

	-- Deck platform attached to the island's north edge
	add({ 56, 2, 28 }, { 0, -1, -66 }, { c = WOOD, m = "WoodPlanks" })
	add({ 56, 1, 2 }, { 0, -0.5, -53 }, { c = DARKWOOD, m = "WoodPlanks" }) -- threshold to the island
	for _, x in { -20, 20 } do -- struts into the island wall
		add({ 2, 2, 16 }, { x, -3.5, -58 }, { c = DARKWOOD, m = "WoodPlanks" })
	end

	-- Fence on the outer deck edges
	for i = 0, 13 do
		add({ 0.5, 2.2, 0.5 }, { -27.5 + i * 4.23, 1.1, -79.5 }, { c = DARKWOOD })
	end
	add({ 56, 0.4, 0.5 }, { 0, 2.0, -79.5 }, { c = WOOD })
	for _, x in { -27.5, 27.5 } do
		for i = 0, 6 do
			add({ 0.5, 2.2, 0.5 }, { x, 1.1, -79.5 + i * 4.3 }, { c = DARKWOOD })
		end
		add({ 0.5, 0.4, 26 }, { x, 2.0, -66.5 }, { c = WOOD })
	end

	-- Sell stand (west)
	add({ 5, 2.4, 2 }, { -18, 1.2, -63 }, { c = DARKWOOD, m = "WoodPlanks", k = "sell" })
	add({ 0.4, 5, 0.4 }, { -20.2, 2.5, -64.6 }, { c = DARKWOOD })
	add({ 0.4, 5, 0.4 }, { -15.8, 2.5, -64.6 }, { c = DARKWOOD })
	add({ 5.6, 0.3, 3 }, { -18, 5.2, -64 }, { c = { 110, 200, 110 } })
	add({ 1.4, 1.0, 1.2 }, { -19.2, 2.9, -63.2 }, { c = { 250, 200, 70 }, m = "Metal" }) -- gold pile
	add({ 0.9, 0.6, 0.8 }, { -18.2, 3.0, -63.0 }, { c = { 250, 210, 90 }, m = "Metal" })

	-- Shop stand (east)
	add({ 5, 2.4, 2 }, { 18, 1.2, -63 }, { c = DARKWOOD, m = "WoodPlanks", k = "shop" })
	add({ 0.4, 5, 0.4 }, { 15.8, 2.5, -64.6 }, { c = DARKWOOD })
	add({ 0.4, 5, 0.4 }, { 20.2, 2.5, -64.6 }, { c = DARKWOOD })
	add({ 5.6, 0.3, 3 }, { 18, 5.2, -64 }, { c = { 90, 160, 245 } })
	add({ 0.3, 2.2, 0.3 }, { 17.2, 3.3, -63.4 }, { c = { 120, 85, 55 } }) -- display shovel
	add({ 1.0, 0.5, 0.4 }, { 17.2, 4.5, -63.4 }, { c = METAL, m = "Metal" })

	-- Museum along the back wall: floor, wall, title board and 10 pedestals
	add({ 44, 0.5, 9 }, { 0, 0.25, -74.5 }, { c = { 180, 175, 165 }, m = "Slate" })
	add({ 44, 7, 1 }, { 0, 3.5, -78.6 }, { c = { 200, 195, 185 }, m = "Brick" })
	add({ 44.4, 0.5, 1.1 }, { 0, 7.2, -78.6 }, { c = { 250, 200, 70 }, m = "Metal" })
	add({ 10, 1.6, 0.4 }, { 0, 5.4, -78.0 }, { c = { 38, 40, 48 }, k = "museum_sign" })
	for i = 1, 10 do
		add({ 2.2, 1.5, 2.2 }, { -19.8 + (i - 1) * 4.4, 0.75 + 0.5, -75.5 }, {
			c = { 160, 158, 150 },
			m = "Slate",
			k = "ped_" .. i,
		})
	end

	-- Leaderboard: deepest diggers
	add({ 0.6, 6.5, 0.6 }, { 24.5, 3.25, -72 }, { c = DARKWOOD })
	add({ 0.6, 6.5, 0.6 }, { 24.5, 3.25, -66 }, { c = DARKWOOD })
	add({ 0.8, 4.8, 7 }, { 24.5, 6.4, -69 }, { c = { 38, 40, 48 }, k = "leaderboard" })
	add({ 0.9, 0.45, 7.3 }, { 24.5, 9.0, -69 }, { c = { 250, 200, 70 }, m = "Metal" })

	-- Campfire
	add({ 1.8, 0.5, 0.6 }, { -0.9, 0.25, -59.6 }, { c = DARKWOOD })
	add({ 0.6, 0.5, 1.8 }, { 0.6, 0.25, -59 }, { c = DARKWOOD })
	add({ 0.8, 1.1, 0.8 }, { 0, 0.9, -59.2 }, { c = { 255, 140, 50 }, m = "Neon", nc = true })
	add({ 0.45, 0.7, 0.45 }, { 0.1, 1.7, -59.2 }, { c = { 255, 200, 90 }, m = "Neon", nc = true })

	-- Flag
	add({ 0.4, 9, 0.4 }, { -24.5, 4.5, -76.5 }, { c = METAL, m = "Metal" })
	add({ 3.2, 2, 0.15 }, { -22.7, 7.6, -76.5 }, { c = { 90, 220, 255 } })

	-- Decorative minecart on a short rail (between the stands and the museum)
	add({ 12, 0.18, 0.35 }, { 9, 0.1, -68.8 }, { c = { 105, 108, 118 }, m = "Metal" })
	add({ 12, 0.18, 0.35 }, { 9, 0.1, -67.2 }, { c = { 105, 108, 118 }, m = "Metal" })
	for _, x in { 4, 7.5, 11, 14 } do
		add({ 0.7, 0.12, 2.6 }, { x, 0.04, -68 }, { c = DARKWOOD })
	end
	add({ 2.4, 1.3, 1.6 }, { 11.5, 0.95, -68 }, { c = { 95, 75, 60 }, m = "Metal" })
	add({ 2.0, 0.4, 1.2 }, { 11.5, 1.7, -68 }, { c = { 132, 134, 140 }, m = "Slate" })
	add({ 0.5, 0.5, 0.5 }, { 11.2, 2.05, -68.1 }, { c = { 250, 200, 70 }, m = "Metal" })
	add({ 0.4, 0.4, 0.4 }, { 11.9, 2.0, -67.9 }, { c = { 190, 245, 255 } })

	-- Warning sign at the dig edge
	add({ 0.35, 2.6, 0.35 }, { 8, 1.3, -54.5 }, { c = DARKWOOD })
	add({ 3.4, 1.5, 0.3 }, { 8, 3.1, -54.5 }, { c = { 240, 200, 60 }, k = "dig_sign" })

	-- Sky dressing: clouds and floating rock islets below/around the island
	local clouds = {
		{ -75, -35, 30 }, { 70, -50, -20 }, { 20, -28, 80 }, { -60, -70, -70 },
		{ 90, -90, 60 }, { -30, -110, 20 }, { 0, -45, -95 },
	}
	for _, cl in clouds do
		add({ 18, 4, 11 }, { cl[1], cl[2], cl[3] }, { c = { 250, 250, 252 }, t = 0.2, nc = true })
		add({ 11, 3.4, 8 }, { cl[1] + 8, cl[2] + 1.8, cl[3] + 2 }, { c = { 250, 250, 252 }, t = 0.25, nc = true })
		add({ 9, 3, 7 }, { cl[1] - 8, cl[2] + 1.4, cl[3] - 2 }, { c = { 250, 250, 252 }, t = 0.25, nc = true })
	end
	local islets = { { -85, -20, -60, 7 }, { 85, -35, 45, 9 }, { -70, -60, 75, 6 }, { 95, -10, -15, 5 } }
	for _, it in islets do
		local r = it[4]
		add({ r * 2, r * 1.2, r * 1.8 }, { it[1], it[2], it[3] }, { c = { 120, 105, 90 }, m = "Rock" })
		add({ r * 2.1, r * 0.25, r * 1.9 }, { it[1], it[2] + r * 0.7, it[3] }, { c = { 110, 160, 90 }, m = "Grass" })
	end

	return { parts = parts }
end

return CampBlueprint
