-- The viral core: steal characters from other bases and carry them home.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Characters = require(ReplicatedStorage.Shared.Characters)
local Plots = require(script.Parent.Plots)
local Factory = require(script.Parent.Factory)
local Dex = require(script.Parent.Dex)

local Steal = {}

local carrying = {} -- thief Player -> { model, unit, ownerName, diedConn }
local cooldownUntil: { [Player]: number } = {}

local function notify(player: Player, text: string, color: Color3?)
	ReplicatedStorage.Remotes.Notify:FireClient(player, text, color)
end

local function setWalkSpeed(player: Player, speed: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = speed
	end
end

-- Ends a carry. If `deliver` is false the character goes back to its owner
-- (when online and with a free slot), otherwise it is lost.
local function endCarry(thief: Player, deliver: boolean)
	local carry = carrying[thief]
	if not carry then
		return
	end
	carrying[thief] = nil
	if carry.diedConn then
		carry.diedConn:Disconnect()
	end
	carry.model:Destroy()
	thief:SetAttribute("Carrying", nil)
	setWalkSpeed(thief, 16)

	if deliver then
		if Plots.place(thief, carry.unit) then
			notify(thief, ("Stolen! %s is yours now!"):format(Characters.unitName(carry.unit)), Color3.fromRGB(120, 255, 120))
			Dex.mark(thief, carry.unit.def)
		else
			notify(thief, "Your base is full! The character escaped.", Color3.fromRGB(255, 80, 80))
		end
		return
	end

	-- Return to the original owner if possible.
	local owner = Players:FindFirstChild(carry.ownerName)
	if owner and owner:IsA("Player") and Plots.place(owner, carry.unit) then
		notify(owner, ("%s made it back home!"):format(Characters.unitName(carry.unit)), Color3.fromRGB(120, 255, 120))
	end
end

function Steal.trySteal(thief: Player, plot, slotIndex: number)
	local owner = plot.owner
	if not owner or owner == thief then
		return
	end
	if Plots.isLocked(plot) then
		notify(thief, "This base is locked!", Color3.fromRGB(255, 80, 80))
		return
	end
	if carrying[thief] then
		notify(thief, "You are already carrying something!", Color3.fromRGB(255, 80, 80))
		return
	end
	if os.clock() < (cooldownUntil[thief] or 0) then
		notify(thief, "Steal cooldown active!", Color3.fromRGB(255, 80, 80))
		return
	end
	local character = thief.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local unit = Plots.removeSlot(plot, slotIndex)
	if not unit then
		return
	end
	cooldownUntil[thief] = os.clock() + Config.StealCooldown

	-- Carried copy floats above the thief's head (moved every Heartbeat).
	local model = Factory.build(unit, false)
	model.Parent = workspace

	local carry = { model = model, unit = unit, ownerName = owner.Name, diedConn = nil }
	carrying[thief] = carry
	thief:SetAttribute("Carrying", Characters.unitName(unit))
	setWalkSpeed(thief, Config.StealWalkSpeed)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		carry.diedConn = humanoid.Died:Connect(function()
			notify(thief, "You dropped the loot!", Color3.fromRGB(255, 80, 80))
			endCarry(thief, false)
		end)
	end

	notify(owner, ("%s is stealing your %s!"):format(thief.DisplayName, Characters.unitName(unit)), Color3.fromRGB(255, 80, 80))
	notify(thief, ("Run home with %s!"):format(Characters.unitName(unit)), Color3.fromRGB(255, 220, 120))
end

function Steal.onPlayerRemoving(player: Player)
	endCarry(player, false)
	cooldownUntil[player] = nil
end

function Steal.init()
	RunService.Heartbeat:Connect(function()
		for thief, carry in carrying do
			local character = thief.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root then
				continue
			end
			local lift = carry.model:GetAttribute("GroundLift") or 0
			carry.model:PivotTo(root.CFrame * CFrame.new(0, 2 + lift, 0))

			local plot = Plots.get(thief)
			if plot then
				local toHome = (root.Position - plot.origin) * Vector3.new(1, 0, 1)
				if toHome.Magnitude < Config.DeliveryRadius then
					endCarry(thief, true)
				end
			end
		end
	end)
end

return Steal
