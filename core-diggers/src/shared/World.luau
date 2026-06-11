-- All world/economy data in one place. Pure data (no Roblox types) so the
-- standalone Luau CLI can load it for preview rendering.
local World = {}

World.BlockSize = 4
World.Island = { sizeX = 26, sizeZ = 26, depth = 36 }

-- hp = clicks-with-damage to break, matId = guaranteed drop, ores roll once per block.
World.Layers = {
	{ name = "Topsoil", from = 1, to = 4, hp = 2, color = { 110, 160, 90 }, material = "Grass",
		matId = "topsoil", ores = { { id = "coal", chance = 0.10 }, { id = "copper", chance = 0.05 } } },
	{ name = "Stone", from = 5, to = 10, hp = 5, color = { 132, 134, 140 }, material = "Slate",
		matId = "stone", ores = { { id = "coal", chance = 0.12 }, { id = "iron", chance = 0.07 }, { id = "silver", chance = 0.03 } } },
	{ name = "Deep Rock", from = 11, to = 16, hp = 10, color = { 92, 94, 102 }, material = "Basalt",
		matId = "deeprock", ores = { { id = "iron", chance = 0.10 }, { id = "gold", chance = 0.05 }, { id = "amethyst", chance = 0.025 } } },
	{ name = "Ice Crust", from = 17, to = 22, hp = 16, color = { 165, 205, 225 }, material = "Ice",
		matId = "permafrost", ores = { { id = "sapphire", chance = 0.06 }, { id = "frost_crystal", chance = 0.025 }, { id = "gold", chance = 0.04 } } },
	{ name = "Magma Rock", from = 23, to = 28, hp = 26, color = { 105, 58, 46 }, material = "Basalt",
		matId = "magmarock", ores = { { id = "ruby", chance = 0.06 }, { id = "obsidian", chance = 0.035 } } },
	{ name = "Crystal Cavern", from = 29, to = 33, hp = 38, color = { 150, 110, 200 }, material = "Slate",
		matId = "crystalrock", ores = { { id = "diamond", chance = 0.05 }, { id = "prism_shard", chance = 0.025 } } },
	{ name = "Void Basalt", from = 34, to = 36, hp = 55, color = { 42, 40, 54 }, material = "Basalt",
		matId = "voidrock", ores = { { id = "starmetal", chance = 0.05 }, { id = "void_pearl", chance = 0.02 } } },
}

-- Meteor event blocks (land on the surface, guaranteed-rich).
World.Meteor = { hp = 12, color = { 90, 220, 255 }, material = "Neon", matId = "stardust",
	ores = { { id = "sapphire", chance = 0.5 }, { id = "diamond", chance = 0.3 }, { id = "gold", chance = 0.8 } } }

-- Sell values. Shiny ore variants are worth ShinyMult times more.
World.Items = {
	topsoil = { name = "Topsoil", value = 1, color = { 130, 100, 70 } },
	stone = { name = "Stone", value = 3, color = { 140, 140, 145 } },
	deeprock = { name = "Deep Rock", value = 8, color = { 95, 95, 105 } },
	permafrost = { name = "Permafrost", value = 18, color = { 170, 210, 230 } },
	magmarock = { name = "Magma Rock", value = 40, color = { 120, 65, 50 } },
	crystalrock = { name = "Crystal Rock", value = 90, color = { 160, 120, 210 } },
	voidrock = { name = "Void Rock", value = 200, color = { 55, 50, 70 } },
	stardust = { name = "Stardust", value = 120, color = { 120, 225, 255 } },
	coal = { name = "Coal", value = 6, color = { 40, 40, 42 } },
	copper = { name = "Copper", value = 14, color = { 200, 120, 70 } },
	iron = { name = "Iron", value = 30, color = { 190, 190, 200 } },
	silver = { name = "Silver", value = 70, color = { 220, 224, 235 } },
	gold = { name = "Gold", value = 160, color = { 250, 200, 70 } },
	amethyst = { name = "Amethyst", value = 320, color = { 175, 110, 230 } },
	sapphire = { name = "Sapphire", value = 550, color = { 70, 120, 240 } },
	frost_crystal = { name = "Frost Crystal", value = 900, color = { 175, 235, 255 } },
	ruby = { name = "Ruby", value = 1400, color = { 235, 60, 70 } },
	obsidian = { name = "Obsidian", value = 2200, color = { 30, 28, 36 } },
	diamond = { name = "Diamond", value = 4500, color = { 190, 245, 255 } },
	prism_shard = { name = "Prism Shard", value = 7500, color = { 255, 150, 220 } },
	starmetal = { name = "Starmetal", value = 15000, color = { 140, 160, 255 } },
	void_pearl = { name = "Void Pearl", value = 30000, color = { 120, 60, 200 } },
}

World.ShinyChance = 0.02
World.ShinyMult = 5

-- Relics: rare finds. Donating one to the museum gives a permanent sell bonus
-- and puts your name on the pedestal; selling gives quick cash instead.
World.RelicChance = 0.006
World.MuseumBonusPerRelic = 0.03
World.Relics = {
	{ id = "old_boot", name = "Old Boot", layer = 1, value = 350 },
	{ id = "cracked_compass", name = "Cracked Compass", layer = 2, value = 1200 },
	{ id = "miners_lantern", name = "Miner's Lantern", layer = 3, value = 4000 },
	{ id = "frozen_fish", name = "Frozen Fish", layer = 4, value = 12000 },
	{ id = "magma_geode", name = "Magma Geode", layer = 5, value = 35000 },
	{ id = "crystal_crown", name = "Crystal Crown", layer = 6, value = 100000 },
	{ id = "void_idol", name = "Void Idol", layer = 7, value = 300000 },
	-- Mythic relics can appear in any layer (tenth of the normal relic odds).
	{ id = "golden_gnome", name = "Golden Gnome", layer = 0, value = 150000 },
	{ id = "ancient_drill", name = "Ancient Drill", layer = 0, value = 400000 },
	{ id = "first_pickaxe", name = "THE FIRST PICKAXE", layer = 0, value = 1000000 },
}
World.MythicRelicFactor = 0.1

World.Shovels = {
	{ id = "rusty", name = "Rusty Shovel", dmg = 1, luck = 0, price = 0, color = { 140, 110, 80 } },
	{ id = "copper", name = "Copper Shovel", dmg = 2, luck = 0, price = 250, color = { 200, 120, 70 } },
	{ id = "iron", name = "Iron Shovel", dmg = 4, luck = 0, price = 1200, color = { 190, 190, 200 } },
	{ id = "golden", name = "Golden Shovel", dmg = 7, luck = 0.05, price = 6000, color = { 250, 200, 70 } },
	{ id = "crystal", name = "Crystal Shovel", dmg = 12, luck = 0.10, price = 25000, color = { 150, 220, 255 } },
	{ id = "magma", name = "Magma Shovel", dmg = 20, luck = 0.15, price = 90000, color = { 240, 110, 50 } },
	{ id = "void", name = "Void Shovel", dmg = 32, luck = 0.25, price = 350000, color = { 110, 60, 190 } },
	{ id = "omega", name = "OMEGA DRILL", dmg = 50, luck = 0.40, price = 1500000, color = { 255, 0, 110 } },
}

World.Backpacks = {
	{ id = 1, name = "Pockets", cap = 20, price = 0 },
	{ id = 2, name = "Satchel", cap = 45, price = 400 },
	{ id = 3, name = "Backpack", cap = 90, price = 2000 },
	{ id = 4, name = "Big Pack", cap = 180, price = 10000 },
	{ id = 5, name = "Cargo Rig", cap = 350, price = 60000 },
	{ id = 6, name = "Black Hole Bag", cap = 700, price = 300000 },
}

-- THE CORE: a shared glowing block under the island center. Breaking it grants
-- prestige (+50% sell value each) and respawns for the next digger.
World.Core = { hp = 150, respawn = 60, prestigeBonus = 0.5 }

World.SwingCooldown = 0.25
World.MeteorInterval = 12 * 60
World.MeteorLifetime = 150
World.DailyBase = 200
World.DailyStreakCap = 7
World.TeleportCooldown = 20
World.LeaderboardRefresh = 90
World.AutosaveInterval = 120

-- Paste your ids here after creating passes/products (0 = hidden in shop).
World.Monetization = {
	GamepassDoubleCash = 0,
	GamepassVIP = 0, -- +10% luck, +50 backpack capacity
	GamepassPortableSeller = 0, -- sell anywhere
	ProductCashSmall = 0,
	ProductCashMedium = 0,
	ProductCashLarge = 0,
}
World.CashProductAmounts = { Small = 5000, Medium = 40000, Large = 250000 }
World.VIPLuck = 0.10
World.VIPCapacity = 50

-- Lookup helpers (work in both Roblox and the CLI).
local layerByIndex = {}
for _, layer in World.Layers do
	for k = layer.from, layer.to do
		layerByIndex[k] = layer
	end
end
function World.layerAt(k: number)
	return layerByIndex[k]
end

local shovelById = {}
for _, s in World.Shovels do
	shovelById[s.id] = s
end
function World.shovel(id: string)
	return shovelById[id] or World.Shovels[1]
end

local packById = {}
for _, p in World.Backpacks do
	packById[p.id] = p
end
function World.backpack(id: number)
	return packById[id] or World.Backpacks[1]
end

local relicById = {}
for _, r in World.Relics do
	relicById[r.id] = r
end
function World.relic(id: string)
	return relicById[id]
end

return World
