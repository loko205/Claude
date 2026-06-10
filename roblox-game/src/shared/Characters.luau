-- Collectible character definitions. All characters are original creations
-- (absurd food/animal hybrids) to stay clear of third-party IP.
local Characters = {}

Characters.Rarities = {
	{ name = "Common", weight = 50, color = Color3.fromRGB(170, 170, 170), price = 25, income = 1 },
	{ name = "Uncommon", weight = 25, color = Color3.fromRGB(85, 200, 85), price = 150, income = 5 },
	{ name = "Rare", weight = 12, color = Color3.fromRGB(60, 130, 230), price = 800, income = 20 },
	{ name = "Epic", weight = 7, color = Color3.fromRGB(150, 70, 220), price = 4000, income = 75 },
	{ name = "Legendary", weight = 4, color = Color3.fromRGB(255, 176, 0), price = 20000, income = 300 },
	{ name = "Mythic", weight = 1.5, color = Color3.fromRGB(255, 60, 60), price = 100000, income = 1200 },
	{ name = "Secret", weight = 0.5, color = Color3.fromRGB(25, 25, 25), price = 750000, income = 7500 },
}

-- mult scales price and income within a rarity tier.
local list = {
	{ id = "schnitzel_cat", name = "Schnitzel Cat", rarity = "Common", mult = 1, color = Color3.fromRGB(222, 184, 135) },
	{ id = "toast_goblin", name = "Toast Goblin", rarity = "Common", mult = 1.2, color = Color3.fromRGB(210, 160, 90) },
	{ id = "pickle_pigeon", name = "Pickle Pigeon", rarity = "Common", mult = 1.5, color = Color3.fromRGB(120, 160, 80) },
	{ id = "bratwurst_dog", name = "Bratwurst Dog", rarity = "Uncommon", mult = 1, color = Color3.fromRGB(180, 100, 70) },
	{ id = "disco_pickle", name = "Disco Pickle", rarity = "Uncommon", mult = 1.2, color = Color3.fromRGB(90, 200, 120) },
	{ id = "waffle_wolf", name = "Waffle Wolf", rarity = "Uncommon", mult = 1.5, color = Color3.fromRGB(230, 190, 110) },
	{ id = "banana_shark", name = "Banana Shark", rarity = "Rare", mult = 1, color = Color3.fromRGB(250, 220, 80) },
	{ id = "sushi_raccoon", name = "Sushi Raccoon", rarity = "Rare", mult = 1.2, color = Color3.fromRGB(200, 200, 210) },
	{ id = "pretzel_snake", name = "Pretzel Snake", rarity = "Rare", mult = 1.5, color = Color3.fromRGB(160, 110, 60) },
	{ id = "kebab_capybara", name = "Kebab Capybara", rarity = "Epic", mult = 1, color = Color3.fromRGB(170, 120, 80) },
	{ id = "lasagna_llama", name = "Lasagna Llama", rarity = "Epic", mult = 1.2, color = Color3.fromRGB(220, 140, 90) },
	{ id = "toaster_duck", name = "Toaster Duck", rarity = "Epic", mult = 1.5, color = Color3.fromRGB(240, 230, 140) },
	{ id = "donut_dragon", name = "Donut Dragon", rarity = "Legendary", mult = 1, color = Color3.fromRGB(255, 150, 180) },
	{ id = "espresso_gorilla", name = "Espresso Gorilla", rarity = "Legendary", mult = 1.2, color = Color3.fromRGB(90, 60, 40) },
	{ id = "nuclear_currywurst", name = "Nuclear Currywurst", rarity = "Legendary", mult = 1.5, color = Color3.fromRGB(255, 120, 30) },
	{ id = "quantum_pretzel", name = "Quantum Pretzel", rarity = "Mythic", mult = 1, color = Color3.fromRGB(120, 220, 255) },
	{ id = "galactic_doener", name = "Galactic Döner", rarity = "Mythic", mult = 1.3, color = Color3.fromRGB(150, 80, 255) },
	{ id = "sigma_strudel", name = "Sigma Strudel", rarity = "Mythic", mult = 1.6, color = Color3.fromRGB(255, 215, 120) },
	{ id = "void_schnitzel", name = "Void Schnitzel", rarity = "Secret", mult = 1, color = Color3.fromRGB(30, 30, 40) },
	{ id = "omega_meatball", name = "Omega Meatball", rarity = "Secret", mult = 1.5, color = Color3.fromRGB(80, 20, 20) },
	{ id = "the_final_bratwurst", name = "THE FINAL BRATWURST", rarity = "Secret", mult = 2.5, color = Color3.fromRGB(255, 0, 100) },
}

local rarityByName = {}
for tier, rarity in Characters.Rarities do
	rarity.tier = tier
	rarityByName[rarity.name] = rarity
end

local byId = {}
local byRarity = {}
for _, def in list do
	local rarity = rarityByName[def.rarity]
	def.income = math.floor(rarity.income * def.mult)
	def.price = math.floor(rarity.price * def.mult)
	def.rarityInfo = rarity
	byId[def.id] = def
	byRarity[def.rarity] = byRarity[def.rarity] or {}
	table.insert(byRarity[def.rarity], def)
end

Characters.List = list

local rng = Random.new()
local totalWeight = 0
for _, rarity in Characters.Rarities do
	totalWeight += rarity.weight
end

function Characters.byId(id: string)
	return byId[id]
end

-- Weighted random pick: rarity by weight, then uniform within the rarity.
function Characters.pick()
	local roll = rng:NextNumber() * totalWeight
	for _, rarity in Characters.Rarities do
		roll -= rarity.weight
		if roll <= 0 then
			local pool = byRarity[rarity.name]
			return pool[rng:NextInteger(1, #pool)]
		end
	end
	return list[1] -- unreachable fallback
end

return Characters
