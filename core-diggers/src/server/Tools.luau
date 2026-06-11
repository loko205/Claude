-- Shovel stats and the (cosmetic) tool model players hold.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage.Shared.World)
local Monetize = require(script.Parent.Monetize)

local Tools = {}

function Tools.stats(player: Player)
	local shovel = World.shovel(player:GetAttribute("Shovel") or "rusty")
	return shovel.dmg, shovel.luck + Monetize.luckBonus(player)
end

local function buildTool(shovel): Tool
	local tool = Instance.new("Tool")
	tool.Name = shovel.name
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 3.2, 0.4)
	handle.Color = Color3.fromRGB(120, 85, 55)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Parent = tool

	local blade = Instance.new("Part")
	blade.Size = Vector3.new(1.1, 1.2, 0.25)
	blade.Color = Color3.fromRGB(shovel.color[1], shovel.color[2], shovel.color[3])
	blade.Material = shovel.id == "omega" and Enum.Material.Neon or Enum.Material.Metal
	blade.CanCollide = false
	blade.CFrame = handle.CFrame * CFrame.new(0, -1.9, 0)
	blade.Parent = tool

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = blade
	weld.Parent = handle

	return tool
end

-- Replaces the player's shovel tool (called on spawn and after buying).
function Tools.give(player: Player)
	local shovel = World.shovel(player:GetAttribute("Shovel") or "rusty")
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	for _, container in { backpack, character } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") then
					child:Destroy()
				end
			end
		end
	end
	if backpack then
		buildTool(shovel).Parent = backpack
	end
end

return Tools
