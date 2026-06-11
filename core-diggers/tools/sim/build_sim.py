#!/usr/bin/env python3
"""Builds and runs a headless integration test for the Core Diggers server.

Wraps the real game modules (textually) into a single Luau file together with
a minimal Roblox API stub (instances, signals, virtual clock scheduler) and a
scripted player session. Run:  python3 tools/sim/build_sim.py [path-to-luau]
"""
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
LUAU = sys.argv[1] if len(sys.argv) > 1 else "/tmp/luau"

SHARED = ["World", "RelicDesigns", "CampBlueprint"]
SERVER = ["Economy", "Data", "Buffs", "Monetize", "Contracts", "Inventory",
          "Tools", "Terrain", "Museum", "Leaderboard", "Camp"]

PRELUDE = r"""
-- ===== Roblox API stub with a virtual clock scheduler =====
local VCLOCK = 0.0
local realos = os
os = {
	clock = function() return VCLOCK end,
	time = function() return 1750000000 + math.floor(VCLOCK) end,
	date = realos.date,
}

local waiting = {}
local function task_wait(t)
	table.insert(waiting, { co = coroutine.running(), wake = VCLOCK + (t or 0.03) })
	return coroutine.yield()
end
local function task_spawn(fn, ...)
	local co = coroutine.create(fn)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		error("task.spawn: " .. tostring(err), 0)
	end
	return co
end
task = {
	wait = task_wait,
	spawn = task_spawn,
	defer = task_spawn,
	delay = function(t, fn) task_spawn(function() task_wait(t) fn() end) end,
}
local function RUN(seconds)
	local target = VCLOCK + seconds
	while VCLOCK < target do
		VCLOCK += 0.05
		local i = 1
		while i <= #waiting do
			if waiting[i].wake <= VCLOCK then
				local entry = table.remove(waiting, i)
				local ok, err = coroutine.resume(entry.co)
				if not ok then
					error("scheduler: " .. tostring(err), 0)
				end
			else
				i += 1
			end
		end
	end
end

local function Signal()
	local s = { _handlers = {} }
	function s.Connect(self, fn)
		table.insert(self._handlers, fn)
		return { Disconnect = function() end }
	end
	function s.Fire(self, ...)
		for _, fn in self._handlers do
			task_spawn(fn, ...)
		end
	end
	return s
end

-- datatypes ---------------------------------------------------------------
local V3 = {}
V3.__index = function(self, k)
	if k == "X" then return rawget(self, "x") end
	if k == "Y" then return rawget(self, "y") end
	if k == "Z" then return rawget(self, "z") end
	if k == "Magnitude" then
		local x, y, z = rawget(self, "x"), rawget(self, "y"), rawget(self, "z")
		return math.sqrt(x * x + y * y + z * z)
	end
	return nil
end
V3.__add = function(a, b) return Vector3.new(a.x + b.x, a.y + b.y, a.z + b.z) end
V3.__sub = function(a, b) return Vector3.new(a.x - b.x, a.y - b.y, a.z - b.z) end
V3.__mul = function(a, b)
	if type(b) == "number" then return Vector3.new(a.x * b, a.y * b, a.z * b) end
	if type(a) == "number" then return Vector3.new(b.x * a, b.y * a, b.z * a) end
	return Vector3.new(a.x * b.x, a.y * b.y, a.z * b.z)
end
Vector3 = {
	new = function(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, V3) end,
}
Vector3.one = Vector3.new(1, 1, 1)

local CF = {}
CF.__index = function(self, k)
	if k == "Position" then return rawget(self, "p") end
	if k == "X" then return rawget(self, "p").x end
	if k == "Y" then return rawget(self, "p").y end
	if k == "Z" then return rawget(self, "p").z end
	return nil
end
CFrame = {
	new = function(a, b, c)
		if type(a) == "table" then return setmetatable({ p = a }, CF) end
		return setmetatable({ p = Vector3.new(a, b, c) }, CF)
	end,
	Angles = function() return setmetatable({ p = Vector3.new() }, CF) end,
}

Color3 = {
	fromRGB = function(r, g, b) return { R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255 } end,
	new = function(r, g, b) return { R = r or 0, G = g or 0, B = b or 0 } end,
}
UDim2 = { new = function() return {} end, fromScale = function() return {} end, fromOffset = function() return {} end }
UDim = { new = function() return {} end }
Vector2 = { new = function() return {} end }
NumberRange = { new = function() return {} end }
NumberSequence = { new = function() return {} end }
ColorSequence = { new = function() return {} end }
TweenInfo = { new = function() return {} end }
Random = {
	new = function()
		return {
			NextNumber = function(_, a, b)
				if a then return a + math.random() * (b - a) end
				return math.random()
			end,
			NextInteger = function(_, a, b) return math.random(a, b) end,
		}
	end,
}
Enum = setmetatable({}, {
	__index = function(t, k)
		local e = setmetatable({}, { __index = function(t2, k2)
			local v = { Name = k2, EnumType = k }
			rawset(t2, k2, v)
			return v
		end })
		rawset(t, k, e)
		return e
	end,
})

-- instances -----------------------------------------------------------------
INSTANCES = {}
NOTIFIES = {}
local EVENTS = {
	Triggered = true, MouseClick = true, Touched = true, Died = true, Changed = true,
	OnServerEvent = true, OnClientEvent = true, Activated = true,
	PlayerAdded = true, PlayerRemoving = true, CharacterAdded = true, CharacterRemoving = true,
}
local METHODS
local InstMT = {
	__index = function(self, key)
		local m = METHODS[key]
		if m then return m end
		local props = rawget(self, "_props")
		if props[key] ~= nil then return props[key] end
		if EVENTS[key] then
			local events = rawget(self, "_events")
			if not events[key] then events[key] = Signal() end
			return events[key]
		end
		for _, c in rawget(self, "_children") do
			if c.Name == key then return c end
		end
		return nil
	end,
	__newindex = function(self, key, value)
		if key == "Parent" then
			local props = rawget(self, "_props")
			local old = props.Parent
			if old then
				local siblings = rawget(old, "_children")
				for i, c in siblings do
					if c == self then table.remove(siblings, i) break end
				end
			end
			props.Parent = value
			if value then table.insert(rawget(value, "_children"), self) end
			return
		end
		rawget(self, "_props")[key] = value
	end,
}
local function newInst(className)
	local inst = setmetatable({
		ClassName = className,
		_props = { Name = className },
		_children = {},
		_attrs = {},
		_events = {},
		_attrSignals = {},
	}, InstMT)
	rawget(inst, "_props").Name = className
	table.insert(INSTANCES, inst)
	return inst
end
METHODS = {
	SetAttribute = function(self, k, v)
		rawget(self, "_attrs")[k] = v
		local sig = rawget(self, "_attrSignals")[k]
		if sig then sig:Fire() end
	end,
	GetAttribute = function(self, k) return rawget(self, "_attrs")[k] end,
	GetAttributeChangedSignal = function(self, k)
		local sigs = rawget(self, "_attrSignals")
		if not sigs[k] then sigs[k] = Signal() end
		return sigs[k]
	end,
	FindFirstChild = function(self, name)
		for _, c in rawget(self, "_children") do
			if c.Name == name then return c end
		end
		return nil
	end,
	FindFirstChildOfClass = function(self, cls)
		for _, c in rawget(self, "_children") do
			if c.ClassName == cls then return c end
		end
		return nil
	end,
	WaitForChild = function(self, name) return METHODS.FindFirstChild(self, name) end,
	GetChildren = function(self) return table.clone(rawget(self, "_children")) end,
	Destroy = function(self)
		self.Parent = nil
		rawget(self, "_props").Destroyed = true
	end,
	IsA = function(self, cls)
		return self.ClassName == cls or cls == "BasePart" or cls == "Instance"
	end,
	GetPivot = function(self)
		local pv = rawget(self, "_props").PivotCF
		if pv then return pv end
		local root = METHODS.FindFirstChild(self, "HumanoidRootPart")
		local pos = (root and rawget(root, "_props").Position) or rawget(self, "_props").Position or Vector3.new()
		return CFrame.new(pos)
	end,
	PivotTo = function(self, cf)
		rawget(self, "_props").PivotCF = cf
		local root = METHODS.FindFirstChild(self, "HumanoidRootPart")
		if root then rawget(root, "_props").Position = cf.Position end
	end,
	TakeDamage = function(self, d)
		rawget(self, "_props").Health = (rawget(self, "_props").Health or 100) - d
	end,
	Emit = function() end,
	Play = function() end,
	FireClient = function(self, player, text, color)
		table.insert(NOTIFIES, { remote = self.Name, player = player, text = tostring(text) })
	end,
	FireAllClients = function(self, text, color)
		table.insert(NOTIFIES, { remote = self.Name, player = nil, text = tostring(text) })
	end,
}
Instance = { new = newInst }

-- services -------------------------------------------------------------------
PLAYERS = {}
local Services = {}
Services.ReplicatedStorage = newInst("ReplicatedStorage")
Services.Players = newInst("Players")
Services.Players.GetPlayers = function() return table.clone(PLAYERS) end
Services.Players.GetPlayerByUserId = function(_, id)
	for _, p in PLAYERS do
		if p.UserId == id then return p end
	end
	return nil
end
Services.Players.GetNameFromUserIdAsync = function(_, id) return "User" .. id end
Services.Lighting = newInst("Lighting")
Services.RunService = newInst("RunService")
local fakeStore = {
	GetAsync = function() return nil end,
	SetAsync = function() end,
	GetSortedAsync = function() return { GetCurrentPage = function() return {} end } end,
}
Services.DataStoreService = {
	GetDataStore = function() return fakeStore end,
	GetOrderedDataStore = function() return fakeStore end,
}
Services.MarketplaceService = { UserOwnsGamePassAsync = function() return false end }
Services.CollectionService = { AddTag = function() end, GetTagged = function() return {} end }
workspace = newInst("Workspace")
game = {
	GetService = function(_, name)
		return Services[name] or error("no service stub: " .. name)
	end,
	BindToClose = function() end,
}

-- expect helper ----------------------------------------------------------------
local FAILS = 0
local CHECKS = 0
function expect(cond, msg)
	CHECKS += 1
	if not cond then
		FAILS += 1
		print("FAIL: " .. msg)
	end
end
function summary()
	print(("%d checks, %d failures"):format(CHECKS, FAILS))
	if FAILS > 0 then
		error("simulation failed", 0)
	end
end
function lastNotify(player)
	for i = #NOTIFIES, 1, -1 do
		if NOTIFIES[i].player == player and NOTIFIES[i].remote == "Notify" then
			return NOTIFIES[i].text
		end
	end
	return ""
end
"""

SCENARIO = r"""
-- ===== scripted player session =====
math.randomseed(42)
boot() -- runs init.server

local RS = game:GetService("ReplicatedStorage")
local remotes = RS.Remotes
local PlayersService = game:GetService("Players")

local player = Instance.new("Player")
player.Name = "Tester"
player.DisplayName = "Tester"
player.UserId = 1
table.insert(PLAYERS, player)
PlayersService.PlayerAdded:Fire(player)
RUN(0.5)

local Economy = MOD("Economy")
local Inventory = MOD("Inventory")
local World = MOD("World")
local Terrain = MOD("Terrain")

expect(Economy.getCash(player) == 25 + World.DailyBase, "join cash = start + daily, got " .. Economy.getCash(player))
expect(player:GetAttribute("contract_1") ~= nil and player:GetAttribute("contract_1") ~= "", "daily contracts assigned")
expect(player:GetAttribute("Shovel") == "rusty", "starts with rusty shovel")

-- character
local char = Instance.new("Model")
char.Name = "Tester"
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Position = Vector3.new(0, 2, 0)
root.Parent = char
local humanoid = Instance.new("Humanoid")
humanoid.Name = "Humanoid"
humanoid.Parent = char
player.Character = char
player.CharacterAdded:Fire(char)
RUN(0.5)

-- dig surface blocks near the island center until the bag has loot
local detectors = {}
for _, inst in INSTANCES do
	if inst.ClassName == "ClickDetector" and inst.Parent and inst.Parent.Position
		and inst.Parent.Position.Y >= -8 and inst.Parent.Position.Y <= 8
		and math.abs(inst.Parent.Position.X) < 30 and math.abs(inst.Parent.Position.Z) < 30 then
		table.insert(detectors, inst)
	end
end
expect(#detectors > 20, "surface click detectors exist, got " .. #detectors)
local swings = 0
for _, det in detectors do
	if (player:GetAttribute("Bag") or 0) >= 6 then
		break
	end
	root.Position = det.Parent.Position + Vector3.new(0, 5, 0)
	for _ = 1, 8 do
		RUN(0.35)
		det.MouseClick:Fire(player)
		swings += 1
	end
end
local bag = player:GetAttribute("Bag") or 0
expect(bag >= 6, "digging fills the bag, got " .. bag .. " after " .. swings .. " swings")
expect((player:GetAttribute("Depth") or 0) >= 1, "depth tracked")

-- sell at the stand
local sellPrompt
for _, inst in INSTANCES do
	if inst.ClassName == "ProximityPrompt" and inst.ActionText == "Sell Loot" then
		sellPrompt = inst
	end
end
expect(sellPrompt ~= nil, "sell prompt exists")
local before = Economy.getCash(player)
root.Position = Vector3.new(-18, 2, -63)
sellPrompt.Triggered:Fire(player)
RUN(0.2)
expect(Economy.getCash(player) > before, "selling pays out")
expect((player:GetAttribute("Bag") or 0) == 0, "bag empty after selling")

-- shovel ore gating: golden needs 2 gold
Economy.addCash(player, 50000)
remotes.Buy.OnServerEvent:Fire(player, "shovel", "golden")
RUN(0.2)
expect(player:GetAttribute("Shovel") == "rusty", "golden shovel blocked without gold ore")
Inventory.awardBulk(player, "gold", 3) -- bulk award: no shiny rolls, deterministic
remotes.Buy.OnServerEvent:Fire(player, "shovel", "golden")
RUN(0.2)
expect(player:GetAttribute("Shovel") == "golden", "golden shovel bought with ore + cash")
expect(Inventory.countOf(player, "gold") == 1, "ore cost consumed, left " .. Inventory.countOf(player, "gold"))

-- crafting: torch needs 3 coal + 5 stone
remotes.Buy.OnServerEvent:Fire(player, "craft", "torch")
RUN(0.2)
expect((player:GetAttribute("gear_torch") or 0) == 0, "craft blocked without materials")
Inventory.awardBulk(player, "coal", 3)
Inventory.awardBulk(player, "stone", 5)
remotes.Buy.OnServerEvent:Fire(player, "craft", "torch")
RUN(0.2)
expect((player:GetAttribute("gear_torch") or 0) == 1, "torch crafted")
remotes.PlaceTorch.OnServerEvent:Fire(player)
RUN(0.2)
expect((player:GetAttribute("gear_torch") or 0) == 0, "torch placed and consumed")

-- teleport gating: deep teleport needs a flare
char:PivotTo(CFrame.new(0, -60, 0))
remotes.Teleport.OnServerEvent:Fire(player)
RUN(0.2)
expect(char:GetPivot().Y < -50, "deep teleport blocked without flare")
Inventory.awardBulk(player, "copper", 2)
Inventory.awardBulk(player, "coal", 2)
remotes.Buy.OnServerEvent:Fire(player, "craft", "flare")
RUN(0.2)
remotes.Teleport.OnServerEvent:Fire(player)
RUN(0.2)
expect(char:GetPivot().Y > 0, "flare teleport works, y = " .. char:GetPivot().Y)
expect((player:GetAttribute("gear_flare") or 0) == 0, "flare consumed")

-- death penalty: dying deep loses half the bag
Inventory.awardBulk(player, "stone", 10)
local bagBeforeDeath = player:GetAttribute("Bag") or 0
char:PivotTo(CFrame.new(0, -60, 0))
humanoid.Died:Fire()
RUN(0.3)
local afterDeath = player:GetAttribute("Bag") or 0
-- per-stack floor rounding: lose floor(n/2) of every stack
expect(afterDeath < bagBeforeDeath and afterDeath <= math.ceil(bagBeforeDeath * 0.6),
	("death penalty halves the bag (%d -> %d)"):format(bagBeforeDeath, afterDeath))

-- mining bomb: blasts blocks, materials only
Inventory.awardBulk(player, "iron", 4)
Inventory.awardBulk(player, "coal", 6)
remotes.Buy.OnServerEvent:Fire(player, "craft", "bomb")
RUN(0.2)
expect((player:GetAttribute("gear_bomb") or 0) == 1, "bomb crafted")
char:PivotTo(CFrame.new(2, 4, 2))
local bagBeforeBomb = player:GetAttribute("Bag") or 0
remotes.UseBomb.OnServerEvent:Fire(player)
RUN(4)
expect((player:GetAttribute("Bag") or 0) > bagBeforeBomb, "bomb yields materials")

-- perks
remotes.Buy.OnServerEvent:Fire(player, "perk", "miner")
RUN(0.2)
expect((player:GetAttribute("perk_miner") or 0) == 0, "perk blocked without points")
player:SetAttribute("PerkPoints", 2)
remotes.Buy.OnServerEvent:Fire(player, "perk", "miner")
RUN(0.2)
expect((player:GetAttribute("perk_miner") or 0) == 1, "perk bought")
expect((player:GetAttribute("PerkPoints") or 0) == 1, "perk point spent")

-- potions
Economy.addCash(player, 5000)
remotes.Buy.OnServerEvent:Fire(player, "potion", "luck")
RUN(0.2)
expect(player:GetAttribute("buff_luck") ~= nil, "luck potion active")

-- meteor event runs without error
Terrain.meteor()
RUN(0.5)

-- leave: save path runs without error
PlayersService.PlayerRemoving:Fire(player)
RUN(0.5)

summary()
print("SIMULATION OK")
"""


def wrap(name: str, source: str, is_script: bool) -> str:
    body = source.replace("\r\n", "\n")
    kind = "script" if is_script else "module"
    return (f"MODULES[{name!r}] = function(script, require)\n"
            f"-- <<{kind} {name}>>\n{body}\nend\n")


def main() -> None:
    parts = [PRELUDE, "MODULES = {}\n"]
    for name in SHARED:
        src = (ROOT / "src/shared" / f"{name}.luau").read_text()
        parts.append(wrap(name, src, False))
    for name in SERVER:
        src = (ROOT / "src/server" / f"{name}.luau").read_text()
        parts.append(wrap(name, src, False))
    init_src = (ROOT / "src/server/init.server.luau").read_text()
    parts.append(wrap("__init", init_src, True))

    parts.append(r"""
-- module marker instances + custom require ------------------------------------
local RS = game:GetService("ReplicatedStorage")
local sharedFolder = Instance.new("Folder")
sharedFolder.Name = "Shared"
sharedFolder.Parent = RS
local serverFolder = Instance.new("Folder")
serverFolder.Name = "Server"
local MARKERS = {}
local LOADED = {}
local function makeMarker(name, parent)
	local m = Instance.new("ModuleScript")
	m.Name = name
	m._module = name
	m.Parent = parent
	MARKERS[name] = m
end
""")
    for name in SHARED:
        parts.append(f'makeMarker("{name}", sharedFolder)\n')
    for name in SERVER:
        parts.append(f'makeMarker("{name}", serverFolder)\n')
    parts.append(r"""
local function REQ(marker)
	local name = marker._module
	if LOADED[name] == nil then
		LOADED[name] = MODULES[name](marker, REQ)
	end
	return LOADED[name]
end
function MOD(name)
	if LOADED[name] == nil then
		LOADED[name] = MODULES[name](MARKERS[name], REQ)
	end
	return LOADED[name]
end
function boot()
	MODULES["__init"](serverFolder, REQ)
end
""")
    parts.append(SCENARIO)
    out = pathlib.Path("/tmp/sim.luau")
    out.write_text("\n".join(parts))
    result = subprocess.run([LUAU, str(out)], capture_output=True, text=True)
    print(result.stdout)
    if result.returncode != 0:
        print(result.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
