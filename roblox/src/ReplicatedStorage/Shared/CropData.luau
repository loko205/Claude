--!strict
-- CropData: definitions for every crop in the game.
-- All economic/growth tuning lives here so balancing is a single-file change.

export type Crop = {
	id: string,
	name: string,
	tier: number, -- 1 = starter, 5 = endgame
	unlockLevel: number,
	seedCost: number, -- coins to buy one seed
	baseValue: number, -- coins per harvested unit at market baseline
	growthTime: number, -- seconds from planting to fully grown
	yieldRange: { min: number, max: number },
	seasonBonus: { [string]: number }, -- season -> yield/value multiplier
	fertilizerMultiplier: number, -- extra yield multiplier when fertilized soil
	color: Color3, -- visual tint for the crop part
	rarity: string, -- Common / Uncommon / Rare / Epic / Legendary
	legendary: boolean?, -- only obtainable through genetics
	geneParents: { string }?, -- required parent ids for legendary breeding
}

local C = Color3.fromRGB

local CropData = {}

-- The growth-stage thresholds are fractions of growthTime. Five visual stages.
CropData.GROWTH_STAGES = { 0.0, 0.2, 0.45, 0.7, 1.0 }
CropData.SEASONS = { "Spring", "Summer", "Autumn", "Winter" }

CropData.Crops = {
	wheat = {
		id = "wheat",
		name = "Wheat",
		tier = 1,
		unlockLevel = 1,
		seedCost = 5,
		baseValue = 12,
		growthTime = 30,
		yieldRange = { min = 2, max = 4 },
		seasonBonus = { Spring = 1.1, Summer = 1.0, Autumn = 1.2, Winter = 0.7 },
		fertilizerMultiplier = 1.25,
		color = C(222, 184, 90),
		rarity = "Common",
	},
	carrot = {
		id = "carrot",
		name = "Carrot",
		tier = 1,
		unlockLevel = 2,
		seedCost = 8,
		baseValue = 18,
		growthTime = 50,
		yieldRange = { min = 2, max = 5 },
		seasonBonus = { Spring = 1.2, Summer = 1.0, Autumn = 1.1, Winter = 0.8 },
		fertilizerMultiplier = 1.25,
		color = C(237, 145, 33),
		rarity = "Common",
	},
	strawberry = {
		id = "strawberry",
		name = "Strawberry",
		tier = 2,
		unlockLevel = 4,
		seedCost = 20,
		baseValue = 35,
		growthTime = 90,
		yieldRange = { min = 3, max = 6 },
		seasonBonus = { Spring = 1.3, Summer = 1.2, Autumn = 0.9, Winter = 0.6 },
		fertilizerMultiplier = 1.3,
		color = C(220, 60, 80),
		rarity = "Uncommon",
	},
	corn = {
		id = "corn",
		name = "Corn",
		tier = 2,
		unlockLevel = 6,
		seedCost = 30,
		baseValue = 48,
		growthTime = 120,
		yieldRange = { min = 3, max = 7 },
		seasonBonus = { Spring = 1.0, Summer = 1.4, Autumn = 1.2, Winter = 0.5 },
		fertilizerMultiplier = 1.3,
		color = C(245, 215, 70),
		rarity = "Uncommon",
	},
	tomato = {
		id = "tomato",
		name = "Tomato",
		tier = 2,
		unlockLevel = 8,
		seedCost = 35,
		baseValue = 55,
		growthTime = 140,
		yieldRange = { min = 4, max = 8 },
		seasonBonus = { Spring = 1.1, Summer = 1.5, Autumn = 1.0, Winter = 0.5 },
		fertilizerMultiplier = 1.35,
		color = C(200, 40, 40),
		rarity = "Uncommon",
	},
	pumpkin = {
		id = "pumpkin",
		name = "Pumpkin",
		tier = 3,
		unlockLevel = 12,
		seedCost = 70,
		baseValue = 110,
		growthTime = 240,
		yieldRange = { min = 2, max = 4 },
		seasonBonus = { Spring = 0.9, Summer = 1.0, Autumn = 1.6, Winter = 0.7 },
		fertilizerMultiplier = 1.4,
		color = C(230, 126, 34),
		rarity = "Rare",
	},
	grapes = {
		id = "grapes",
		name = "Grapes",
		tier = 3,
		unlockLevel = 15,
		seedCost = 90,
		baseValue = 140,
		growthTime = 300,
		yieldRange = { min = 4, max = 9 },
		seasonBonus = { Spring = 1.1, Summer = 1.3, Autumn = 1.4, Winter = 0.6 },
		fertilizerMultiplier = 1.4,
		color = C(128, 80, 200),
		rarity = "Rare",
	},
	chili = {
		id = "chili",
		name = "Chili Pepper",
		tier = 3,
		unlockLevel = 18,
		seedCost = 110,
		baseValue = 175,
		growthTime = 330,
		yieldRange = { min = 3, max = 6 },
		seasonBonus = { Spring = 1.0, Summer = 1.6, Autumn = 1.1, Winter = 0.4 },
		fertilizerMultiplier = 1.45,
		color = C(190, 30, 30),
		rarity = "Rare",
	},
	bluemelon = {
		id = "bluemelon",
		name = "Blue Melon",
		tier = 4,
		unlockLevel = 24,
		seedCost = 220,
		baseValue = 320,
		growthTime = 480,
		yieldRange = { min = 2, max = 5 },
		seasonBonus = { Spring = 1.2, Summer = 1.5, Autumn = 1.0, Winter = 0.5 },
		fertilizerMultiplier = 1.5,
		color = C(60, 140, 220),
		rarity = "Epic",
	},
	dragonfruit = {
		id = "dragonfruit",
		name = "Dragon Fruit",
		tier = 4,
		unlockLevel = 30,
		seedCost = 350,
		baseValue = 520,
		growthTime = 600,
		yieldRange = { min = 2, max = 4 },
		seasonBonus = { Spring = 1.1, Summer = 1.4, Autumn = 1.3, Winter = 0.6 },
		fertilizerMultiplier = 1.5,
		color = C(225, 60, 130),
		rarity = "Epic",
	},
	truffle = {
		id = "truffle",
		name = "Truffle",
		tier = 5,
		unlockLevel = 40,
		seedCost = 800,
		baseValue = 1300,
		growthTime = 1200,
		yieldRange = { min = 1, max = 3 },
		seasonBonus = { Spring = 1.0, Summer = 0.9, Autumn = 1.7, Winter = 1.2 },
		fertilizerMultiplier = 1.6,
		color = C(70, 50, 40),
		rarity = "Legendary",
	},
	-- Legendary, breeding-only crops (not purchasable as seeds).
	golden_pumpkin = {
		id = "golden_pumpkin",
		name = "Golden Pumpkin",
		tier = 5,
		unlockLevel = 12,
		seedCost = 0,
		baseValue = 2400,
		growthTime = 360,
		yieldRange = { min = 1, max = 2 },
		seasonBonus = { Spring = 1.0, Summer = 1.0, Autumn = 2.0, Winter = 1.0 },
		fertilizerMultiplier = 1.8,
		color = C(255, 215, 0),
		rarity = "Legendary",
		legendary = true,
		geneParents = { "pumpkin", "pumpkin" },
	},
	rainbow_grapes = {
		id = "rainbow_grapes",
		name = "Rainbow Grapes",
		tier = 5,
		unlockLevel = 15,
		seedCost = 0,
		baseValue = 2800,
		growthTime = 420,
		yieldRange = { min = 2, max = 4 },
		seasonBonus = { Spring = 1.5, Summer = 1.5, Autumn = 1.5, Winter = 1.5 },
		fertilizerMultiplier = 1.8,
		color = C(180, 120, 255),
		rarity = "Legendary",
		legendary = true,
		geneParents = { "grapes", "bluemelon" },
	},
} :: { [string]: Crop }

function CropData.get(id: string): Crop?
	return CropData.Crops[id]
end

-- Crops a player can buy as seeds at the given level (excludes legendary).
function CropData.purchasable(level: number): { Crop }
	local out = {}
	for _, crop in CropData.Crops do
		if not crop.legendary and crop.unlockLevel <= level then
			table.insert(out, crop)
		end
	end
	table.sort(out, function(a, b)
		return a.unlockLevel < b.unlockLevel
	end)
	return out
end

return CropData
