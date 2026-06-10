-- HUD: cash, income, rebirth button, carry banner, notifications.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyRemote = remotes:WaitForChild("Notify")
local rebirthRemote = remotes:WaitForChild("Rebirth")

local SUFFIXES = { "K", "M", "B", "T", "Qa" }

local function fmt(n: number): string
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local index = 0
	while n >= 1000 and index < #SUFFIXES do
		n /= 1000
		index += 1
	end
	return ("%.1f%s"):format(n, SUFFIXES[index])
end

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(props: { [string]: any }): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextStrokeTransparency = 0.3
	label.TextColor3 = Color3.new(1, 1, 1)
	for key, value in props do
		(label :: any)[key] = value
	end
	label.Parent = gui
	return label
end

local cashLabel = makeLabel({
	Position = UDim2.new(0, 20, 0, 20),
	Size = UDim2.new(0, 220, 0, 40),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(120, 255, 120),
	Text = "$0",
})

local incomeLabel = makeLabel({
	Position = UDim2.new(0, 20, 0, 62),
	Size = UDim2.new(0, 220, 0, 26),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "$0/s",
})

local carryBanner = makeLabel({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 16),
	Size = UDim2.new(0, 480, 0, 34),
	TextColor3 = Color3.fromRGB(255, 220, 120),
	Text = "",
	Visible = false,
})

local rebirthButton = Instance.new("TextButton")
rebirthButton.AnchorPoint = Vector2.new(0.5, 1)
rebirthButton.Position = UDim2.new(0.5, 0, 1, -20)
rebirthButton.Size = UDim2.new(0, 260, 0, 44)
rebirthButton.BackgroundColor3 = Color3.fromRGB(150, 70, 220)
rebirthButton.Font = Enum.Font.FredokaOne
rebirthButton.TextScaled = true
rebirthButton.TextColor3 = Color3.new(1, 1, 1)
rebirthButton.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = rebirthButton

rebirthButton.Activated:Connect(function()
	rebirthRemote:FireServer()
end)

local function updateRebirthButton()
	local rebirths = player:GetAttribute("Rebirths") or 0
	local cost = Config.RebirthBaseCost * Config.RebirthCostFactor ^ rebirths
	rebirthButton.Text = ("REBIRTH (+%d%% income)  $%s"):format(Config.RebirthIncomeBonus * 100, fmt(cost))
end

-- Notification feed (top right).
local feed = Instance.new("Frame")
feed.BackgroundTransparency = 1
feed.AnchorPoint = Vector2.new(1, 0)
feed.Position = UDim2.new(1, -20, 0, 20)
feed.Size = UDim2.new(0, 320, 0, 300)
feed.Parent = gui
local feedLayout = Instance.new("UIListLayout")
feedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
feedLayout.Padding = UDim.new(0, 4)
feedLayout.Parent = feed

notifyRemote.OnClientEvent:Connect(function(text: string, color: Color3?)
	local note = Instance.new("TextLabel")
	note.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	note.BackgroundTransparency = 0.3
	note.Size = UDim2.new(1, 0, 0, 32)
	note.Font = Enum.Font.FredokaOne
	note.TextScaled = true
	note.TextColor3 = color or Color3.new(1, 1, 1)
	note.Text = text
	note.Parent = feed
	local noteCorner = Instance.new("UICorner")
	noteCorner.CornerRadius = UDim.new(0, 8)
	noteCorner.Parent = note
	task.delay(4, function()
		TweenService:Create(note, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.wait(0.5)
		note:Destroy()
	end)
end)

-- Live stat bindings.
local function watchCash()
	local leaderstats = player:WaitForChild("leaderstats")
	local cash = leaderstats:WaitForChild("Cash") :: NumberValue
	local function update()
		cashLabel.Text = "$" .. fmt(cash.Value)
	end
	cash.Changed:Connect(update)
	update()
end

player:GetAttributeChangedSignal("Income"):Connect(function()
	incomeLabel.Text = ("$%s/s"):format(fmt(player:GetAttribute("Income") or 0))
end)

player:GetAttributeChangedSignal("Rebirths"):Connect(updateRebirthButton)

player:GetAttributeChangedSignal("Carrying"):Connect(function()
	local carrying = player:GetAttribute("Carrying")
	carryBanner.Visible = carrying ~= nil
	if carrying then
		carryBanner.Text = ("You grabbed %s — RUN TO YOUR BASE!"):format(carrying)
	end
end)

updateRebirthButton()
task.spawn(watchCash)
