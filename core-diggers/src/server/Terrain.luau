-- The diggable voxel island. Blocks exist only where exposed: the top layer
-- and the island's side shell spawn upfront, everything else is revealed as
-- neighbors get mined. All mining is server-validated.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage.Shared.World)
local Inventory = require(script.Parent.Inventory)
local Tools = require(script.Parent.Tools)
local Contracts = require(script.Parent.Contracts)
local Buffs = require(script.Parent.Buffs)

local Terrain = {}

-- Wired by init.server (needs Economy/notify/profile access).
Terrain.onCoreBroken = nil :: ((player: Player) -> ())?

local SIZE_X = World.Island.sizeX
local SIZE_Z = World.Island.sizeZ
local DEPTH = World.Island.depth
local BS = World.BlockSize

local cells: { [string]: any } = {} -- key -> cell table | "mined"
local folder: Folder
local lastSwing: { [Player]: number } = {}
local lastFullWarn: { [Player]: number } = {}
local rng = Random.new()

local coreHp = World.Core.hp
local corePart: Part? = nil
local coreDown = false

local function notify(player: Player, text: string, color: Color3?)
	ReplicatedStorage.Remotes.Notify:FireClient(player, text, color)
end

local function key(i: number, j: number, k: number): string
	return i .. "," .. j .. "," .. k
end

local function positionOf(i: number, j: number, k: number): Vector3
	return Vector3.new((i - (SIZE_X + 1) / 2) * BS, -(k - 0.5) * BS, (j - (SIZE_Z + 1) / 2) * BS)
end

local function isCoreSlot(i: number, j: number, k: number): boolean
	local mid = SIZE_X / 2
	return k == DEPTH and (i == mid or i == mid + 1) and (j == mid or j == mid + 1)
end

local function spawnCore()
	if corePart then
		return
	end
	local part = Instance.new("Part")
	part.Name = "TheCore"
	part.Anchored = true
	part.Size = Vector3.new(BS * 2, BS * 2, BS * 2)
	part.Position = Vector3.new(0, -(DEPTH - 0.5) * BS, 0)
	part.Color = Color3.fromRGB(255, 120, 40)
	part.Material = Enum.Material.Neon
	part.Parent = folder
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 18
	click.Parent = part
	click.MouseClick:Connect(function(player)
		Terrain.hitCore(player)
	end)
	corePart = part
	coreHp = World.Core.hp
	coreDown = false
end

local DECOR_FLOWERS = {
	Color3.fromRGB(235, 90, 90),
	Color3.fromRGB(245, 205, 80),
	Color3.fromRGB(190, 120, 235),
	Color3.fromRGB(245, 245, 240),
}

-- Surface decoration is parented to its block, so it vanishes when the block
-- is dug out (nothing ever floats). CanQuery=false lets clicks pass through.
local function addDecor(blockPart: Part)
	local roll = rng:NextNumber()
	if roll >= 0.2 then
		return
	end
	local base = blockPart.Position + Vector3.new(rng:NextNumber(-1.2, 1.2), BS / 2, rng:NextNumber(-1.2, 1.2))
	local function deco(size: Vector3, offset: Vector3, color: Color3, material: Enum.Material?)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Size = size
		p.Position = base + offset
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Parent = blockPart
	end
	if roll < 0.10 then -- grass tuft
		deco(Vector3.new(0.9, 0.7, 0.9), Vector3.new(0, 0.35, 0), Color3.fromRGB(95, 165, 80), Enum.Material.Grass)
	elseif roll < 0.14 then -- flower
		deco(Vector3.new(0.18, 0.9, 0.18), Vector3.new(0, 0.45, 0), Color3.fromRGB(90, 140, 70))
		deco(Vector3.new(0.5, 0.4, 0.5), Vector3.new(0, 1.1, 0), DECOR_FLOWERS[rng:NextInteger(1, #DECOR_FLOWERS)])
	elseif roll < 0.18 then -- boulder
		deco(Vector3.new(1.5, 0.9, 1.2), Vector3.new(0, 0.45, 0), Color3.fromRGB(135, 135, 140), Enum.Material.Rock)
	else -- sapling
		deco(Vector3.new(0.7, 2.8, 0.7), Vector3.new(0, 1.4, 0), Color3.fromRGB(110, 80, 55), Enum.Material.Wood)
		deco(Vector3.new(3, 2.2, 3), Vector3.new(0, 3.6, 0), Color3.fromRGB(88, 150, 82), Enum.Material.Grass)
		deco(Vector3.new(2, 1.4, 2), Vector3.new(0, 4.9, 0), Color3.fromRGB(104, 170, 92), Enum.Material.Grass)
	end
end

local spawnCell -- forward declaration

local function reveal(i: number, j: number, k: number)
	if k < 1 or k > DEPTH or i < 1 or i > SIZE_X or j < 1 or j > SIZE_Z then
		return
	end
	if isCoreSlot(i, j, k) then
		spawnCore()
		return
	end
	spawnCell(i, j, k)
end

spawnCell = function(i: number, j: number, k: number, skipDecor: boolean?)
	local cellKey = key(i, j, k)
	if cells[cellKey] then
		return
	end
	if isCoreSlot(i, j, k) then
		return
	end
	-- k = 0 holds the surface mounds; they count as topsoil
	local layer = World.layerAt(math.max(k, 1))
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = Vector3.new(BS, BS, BS)
	part.Position = positionOf(i, j, k)
	local jitter = rng:NextInteger(-7, 7)
	part.Color = Color3.fromRGB(
		math.clamp(layer.color[1] + jitter, 0, 255),
		math.clamp(layer.color[2] + jitter, 0, 255),
		math.clamp(layer.color[3] + jitter, 0, 255)
	)
	part.Material = (Enum.Material :: any)[layer.material]
	part.Parent = folder

	local cell = { part = part, hp = layer.hp, maxHp = layer.hp, layer = layer, layerIndex = k, i = i, j = j, k = k }

	-- Block specials: lava (hazard layers), golden treasure, visible ore veins.
	if layer.hazard and rng:NextNumber() < World.LavaChance then
		cell.lava = true
		cell.hp, cell.maxHp = 6, 6
		part.Color = Color3.fromRGB(255, 95, 30)
		part.Material = Enum.Material.Neon
		part.Touched:Connect(function(hitPart)
			local humanoid = hitPart.Parent and hitPart.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid and os.clock() - (humanoid:GetAttribute("LavaT") or 0) > 1 then
				humanoid:SetAttribute("LavaT", os.clock())
				humanoid:TakeDamage(World.LavaDamage)
			end
		end)
	elseif rng:NextNumber() < World.TreasureChance then
		cell.treasure = true
		part.Color = Color3.fromRGB(235, 185, 80)
		part.Material = Enum.Material.Metal
	elseif #layer.ores > 0 and rng:NextNumber() < World.VeinChance then
		-- pick an ore weighted by its layer chance, tint the block toward it
		local total = 0
		for _, ore in layer.ores do
			total += ore.chance
		end
		local roll = rng:NextNumber() * total
		for _, ore in layer.ores do
			roll -= ore.chance
			if roll <= 0 then
				cell.vein = ore.id
				break
			end
		end
		local oc = World.Items[cell.vein].color
		local lc = layer.color
		part.Color = Color3.fromRGB(
			lc[1] * 0.35 + oc[1] * 0.65,
			lc[2] * 0.35 + oc[2] * 0.65,
			lc[3] * 0.35 + oc[3] * 0.65
		)
	end

	cells[cellKey] = cell

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 16
	click.Parent = part
	click.MouseClick:Connect(function(player)
		Terrain.hit(player, cell, cellKey)
	end)

	if k <= 1 and not skipDecor then
		addDecor(part)
	end
end

-- Break burst: short particle puff in the block's color.
local function breakFx(position: Vector3, color: Color3)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.Position = position
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Lifetime = NumberRange.new(0.25, 0.5)
	emitter.Speed = NumberRange.new(6, 11)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.4)
	emitter.Rate = 0
	emitter.Parent = holder
	holder.Parent = folder
	emitter:Emit(14)
	task.delay(1, function()
		holder:Destroy()
	end)
end

-- Small rising text ("+24.5kg Gold", "CRIT!") at a block position.
local function floatText(position: Vector3, text: string, color: Color3)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.Position = position
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 140, 0, 32)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 60
	gui.Parent = holder
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	holder.Parent = folder
	task.spawn(function()
		for step = 1, 10 do
			holder.Position += Vector3.new(0, 0.3, 0)
			label.TextTransparency = step / 12
			task.wait(0.06)
		end
		holder:Destroy()
	end)
end

local function swingAllowed(player: Player): boolean
	local now = os.clock()
	local cooldown = World.SwingCooldown * (Buffs.has(player, "speed") and 0.5 or 1)
	if now - (lastSwing[player] or 0) < cooldown then
		return false
	end
	lastSwing[player] = now
	return true
end

local function inReach(player: Player, position: Vector3): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - position).Magnitude <= 22
end

function Terrain.hit(player: Player, cell, cellKey: string)
	if cells[cellKey] ~= cell or not cell.part.Parent then
		return
	end
	if not swingAllowed(player) or not inReach(player, cell.part.Position) then
		return
	end
	if not cell.lava and Inventory.isFull(player) then
		if os.clock() - (lastFullWarn[player] or 0) > 2 then
			lastFullWarn[player] = os.clock()
			notify(player, "Backpack full! Sell your loot.", Color3.fromRGB(255, 80, 80))
		end
		return
	end

	local dmg, luck = Tools.stats(player)

	-- Critical digs: hitting a gold-flashing block deals triple damage.
	if cell.critUntil and os.clock() < cell.critUntil then
		dmg *= World.CritMult
		cell.critUntil = nil
		floatText(cell.part.Position + Vector3.new(0, BS / 2, 0), "CRIT!", Color3.fromRGB(255, 220, 90))
	elseif not cell.critUntil and cell.hp - dmg > 0 and rng:NextNumber() < World.CritChance then
		cell.critUntil = os.clock() + World.CritWindow
		local baseColor, baseMaterial = cell.part.Color, cell.part.Material
		cell.part.Color = Color3.fromRGB(255, 220, 90)
		cell.part.Material = Enum.Material.Neon
		task.delay(World.CritWindow, function()
			if cells[cellKey] == cell and cell.part.Parent then
				cell.critUntil = nil
				cell.part.Color = baseColor
				cell.part.Material = baseMaterial
			end
		end)
	end

	cell.hp -= dmg
	if cell.hp > 0 then
		if not cell.critUntil then
			-- darken toward broken (specials keep their look, just dim)
			local f = 0.45 + 0.55 * (cell.hp / cell.maxHp)
			local base = cell.part.Color
			cell.part.Color = Color3.new(base.R * f + base.R * (1 - f) * 0.2, base.G * f, base.B * f)
		end
		return
	end

	local blockPosition = cell.part.Position
	local blockColor = cell.part.Color
	cells[cellKey] = "mined"
	cell.part:Destroy()
	breakFx(blockPosition, blockColor)
	if cell.lava then
		-- lava yields nothing, breaking it just clears the path
	elseif cell.treasure then
		Inventory.awardTreasure(player, cell.layer)
	else
		local find = Inventory.award(player, cell.layer, cell.layerIndex, luck)
		if find then
			floatText(
				blockPosition,
				("+%s %s%s"):format(find.kg, find.shiny and "SHINY " or "", find.name),
				Color3.fromRGB(find.color[1], find.color[2], find.color[3])
			)
		end
		if cell.vein then
			Inventory.awardVein(player, cell.vein, rng:NextInteger(World.VeinYield.min, World.VeinYield.max))
		end
	end
	Contracts.onBlock(player)

	local oldDepth = player:GetAttribute("Depth") or 0
	if cell.k and cell.k > oldDepth then
		player:SetAttribute("Depth", cell.k)
		Contracts.onDepth(player, cell.k)
		if cell.k > (player:GetAttribute("DepthBest") or 0) then
			player:SetAttribute("DepthBest", cell.k)
		end
		-- celebrate entering a new layer
		local newLayer = World.layerAt(cell.k)
		if newLayer ~= World.layerAt(math.max(oldDepth, 1)) then
			notify(player, ("You reached %s! Better loot down here."):format(newLayer.name), Color3.fromRGB(90, 220, 255))
		end
	end

	if cell.k then -- meteor blocks have no grid coords
		reveal(cell.i, cell.j, cell.k + 1)
		reveal(cell.i, cell.j, cell.k - 1)
		reveal(cell.i + 1, cell.j, cell.k)
		reveal(cell.i - 1, cell.j, cell.k)
		reveal(cell.i, cell.j + 1, cell.k)
		reveal(cell.i, cell.j - 1, cell.k)
	end
end

function Terrain.hitCore(player: Player)
	if coreDown or not corePart then
		return
	end
	if not swingAllowed(player) or not inReach(player, corePart.Position) then
		return
	end
	local dmg = Tools.stats(player)
	coreHp -= dmg
	corePart.Color = Color3.fromRGB(255, 120 + 100 * math.max(coreHp, 0) / World.Core.hp, 40)
	if coreHp > 0 then
		return
	end
	coreDown = true
	local part = corePart
	corePart = nil
	part:Destroy()
	if Terrain.onCoreBroken then
		Terrain.onCoreBroken(player)
	end
	task.delay(World.Core.respawn, spawnCore)
end

-- Meteor event: a glowing ore cluster lands on a random surface spot.
function Terrain.meteor()
	local i0 = rng:NextInteger(4, SIZE_X - 5)
	local j0 = rng:NextInteger(4, SIZE_Z - 5)
	local spawned = {}
	for di = 0, 2 do
		for dj = 0, 2 do
			do
				local part = Instance.new("Part")
				part.Anchored = true
				part.Size = Vector3.new(BS, BS, BS)
				part.Position = positionOf(i0 + di, j0 + dj, 0) -- one block above the surface
				part.Color = Color3.fromRGB(World.Meteor.color[1], World.Meteor.color[2], World.Meteor.color[3])
				part.Material = Enum.Material.Neon
				part.Parent = folder
				local cell = { part = part, hp = World.Meteor.hp, maxHp = World.Meteor.hp, layer = World.Meteor, layerIndex = 1 }
				local cellKey = "meteor:" .. tostring(part)
				cells[cellKey] = cell
				local click = Instance.new("ClickDetector")
				click.MaxActivationDistance = 16
				click.Parent = part
				click.MouseClick:Connect(function(player)
					Terrain.hit(player, cell, cellKey)
				end)
				table.insert(spawned, { cell = cell, key = cellKey })
			end
		end
	end
	task.delay(World.MeteorLifetime, function()
		for _, entry in spawned do
			if cells[entry.key] == entry.cell then
				cells[entry.key] = nil
				entry.cell.part:Destroy()
			end
		end
	end)
end

function Terrain.init()
	folder = Instance.new("Folder")
	folder.Name = "Island"
	folder.Parent = workspace

	-- Rolling surface: a smooth height field built from a few hill cones.
	-- Heights are 0-3 extra topsoil blocks (k = 0, -1, -2), contiguous and
	-- terraced like proper voxel hills - and diggable like everything else.
	local heights: { [string]: number } = {}
	for _ = 1, rng:NextInteger(5, 7) do
		local ci = rng:NextInteger(5, SIZE_X - 4)
		local cj = rng:NextInteger(7, SIZE_Z - 4)
		local radius = rng:NextInteger(3, 6)
		local peak = rng:NextInteger(2, 3)
		for di = -radius, radius do
			for dj = -radius, radius do
				local i, j = ci + di, cj + dj
				-- keep the camp entrance row flat and stay off the island rim
				if i >= 2 and i <= SIZE_X - 1 and j >= 3 and j <= SIZE_Z - 1 then
					local dist = math.sqrt(di * di + dj * dj)
					local h = math.floor(peak * (1 - dist / radius) + 0.5)
					if h > 0 then
						local cellKey = i .. "," .. j
						heights[cellKey] = math.max(heights[cellKey] or 0, h)
					end
				end
			end
		end
	end

	for i = 1, SIZE_X do
		for j = 1, SIZE_Z do
			local h = heights[i .. "," .. j] or 0
			spawnCell(i, j, 1, h > 0)
			for level = 1, h do
				-- decor only on the top block of each stack
				spawnCell(i, j, 1 - level, level < h)
			end
		end
	end
	-- Side shell so the floating island looks solid from outside
	for k = 2, DEPTH do
		for i = 1, SIZE_X do
			spawnCell(i, 1, k)
			spawnCell(i, SIZE_Z, k)
		end
		for j = 2, SIZE_Z - 1 do
			spawnCell(1, j, k)
			spawnCell(SIZE_X, j, k)
		end
	end
end

function Terrain.onPlayerRemoving(player: Player)
	lastSwing[player] = nil
	lastFullWarn[player] = nil
end

return Terrain
