-- Spawns characters on the belt, moves them, handles buying.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Characters = require(ReplicatedStorage.Shared.Characters)
local Factory = require(script.Parent.Factory)
local Plots = require(script.Parent.Plots)
local Economy = require(script.Parent.Economy)

local Conveyor = {}

local items = {} -- { model: Model, def: any, x: number }

local function notify(player: Player, text: string, color: Color3?)
	ReplicatedStorage.Remotes.Notify:FireClient(player, text, color)
end

local function spawnItem(belt)
	if #items >= Config.MaxItemsOnBelt then
		return
	end
	local def = Characters.pick()
	local model = Factory.build(def, true)
	local item = { model = model, def = def, x = belt.beltStartX }

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = ("Buy  $%d"):format(def.price)
	prompt.ObjectText = def.name
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if model.Parent == nil then
			return
		end
		if not Economy.trySpend(player, def.price) then
			notify(player, "Not enough cash!", Color3.fromRGB(255, 80, 80))
			return
		end
		if not Plots.place(player, def) then
			Economy.addCash(player, def.price) -- refund
			notify(player, "Your base is full!", Color3.fromRGB(255, 80, 80))
			return
		end
		model:Destroy()
		notify(player, ("You bought %s!"):format(def.name), def.rarityInfo.color)
	end)

	model.Parent = workspace
	table.insert(items, item)
end

function Conveyor.init(belt)
	task.spawn(function()
		while true do
			spawnItem(belt)
			task.wait(Config.ConveyorSpawnInterval)
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		for i = #items, 1, -1 do
			local item = items[i]
			if item.model.Parent == nil then
				table.remove(items, i)
				continue
			end
			item.x += Config.ConveyorSpeed * dt
			if item.x > belt.beltEndX then
				item.model:Destroy()
				table.remove(items, i)
				continue
			end
			local lift = item.model:GetAttribute("GroundLift") or 0
			item.model:PivotTo(CFrame.new(item.x, belt.beltTopY + lift, 0))
		end
	end)
end

return Conveyor
