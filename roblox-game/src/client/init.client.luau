-- HUD: cash, income, rebirth button, carry banner, notifications.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage.Shared.Config)
local Characters = require(ReplicatedStorage.Shared.Characters)

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

-- Built-in SFX (no uploaded assets needed)
local goodSound = Instance.new("Sound")
goodSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
goodSound.Volume = 0.6
goodSound.Parent = SoundService
local badSound = Instance.new("Sound")
badSound.SoundId = "rbxasset://sounds/snap.mp3"
badSound.Volume = 0.5
badSound.Parent = SoundService

local function styleFrame(frame: GuiObject, strokeColor: Color3?)
	frame.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
	frame.BackgroundTransparency = 0.25
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor or Color3.fromRGB(80, 84, 100)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = frame
end

-- Stats panel (top left)
local statsPanel = Instance.new("Frame")
statsPanel.Position = UDim2.new(0, 14, 0, 14)
statsPanel.Size = UDim2.new(0, 250, 0, 92)
statsPanel.Parent = gui
styleFrame(statsPanel)

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
	Position = UDim2.new(0, 16, 0, 10),
	Size = UDim2.new(1, -32, 0, 42),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(120, 255, 120),
	Text = "$0",
})
cashLabel.Parent = statsPanel

local incomeLabel = makeLabel({
	Position = UDim2.new(0, 16, 0, 54),
	Size = UDim2.new(1, -32, 0, 26),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "$0/s",
})
incomeLabel.Parent = statsPanel

local carryBanner = makeLabel({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.new(0, 520, 0, 44),
	TextColor3 = Color3.fromRGB(255, 220, 120),
	Text = "",
	Visible = false,
})
styleFrame(carryBanner, Color3.fromRGB(255, 170, 60))

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
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(Color3.fromRGB(150, 70, 220), Color3.fromRGB(255, 80, 180))
gradient.Rotation = 90
gradient.Parent = rebirthButton
local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = Color3.fromRGB(255, 255, 255)
buttonStroke.Thickness = 2
buttonStroke.Transparency = 0.5
buttonStroke.Parent = rebirthButton

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
	-- Reddish notifications are warnings/failures, everything else is positive.
	if color and color.R > color.G then
		badSound:Play()
	else
		goodSound:Play()
	end
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

-- ===== Rainbow mutation effect (parts are tagged by the server Factory) =====
task.spawn(function()
	while true do
		local hue = (os.clock() * 0.4) % 1
		for _, part in CollectionService:GetTagged("RainbowPart") do
			(part :: BasePart).Color = Color3.fromHSV(hue, 0.85, 1)
		end
		task.wait(0.08)
	end
end)

-- ===== Toggleable side panels: Schnitzel-Dex and Shop =====
local function makePanel(titleText: string): (Frame, Frame)
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.Position = UDim2.new(0, 14, 1, -130)
	panel.Size = UDim2.new(0, 320, 0, 420)
	panel.Visible = false
	panel.Parent = gui
	styleFrame(panel)

	local title = makeLabel({
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -24, 0, 30),
		Text = titleText,
	})
	title.Parent = panel

	local content = Instance.new("ScrollingFrame")
	content.BackgroundTransparency = 1
	content.Position = UDim2.new(0, 12, 0, 44)
	content.Size = UDim2.new(1, -24, 1, -56)
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.ScrollBarThickness = 6
	content.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = content

	return panel, content
end

local dexPanel, dexContent = makePanel("SCHNITZEL-DEX")
local shopPanel, shopContent = makePanel("SHOP")

local function refreshDex()
	for _, child in dexContent:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local found = 0
	for _, def in Characters.List do
		local discovered = player:GetAttribute("dex_" .. def.id) == true
		if discovered then
			found += 1
		end
		local row = Instance.new("TextLabel")
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 24)
		row.Font = Enum.Font.FredokaOne
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextStrokeTransparency = 0.4
		row.Text = discovered and ("%s  ·  %s"):format(def.name, def.rarity) or "???"
		row.TextColor3 = discovered and def.rarityInfo.color or Color3.fromRGB(110, 110, 120)
		row.Parent = dexContent
	end
	local title = dexPanel:FindFirstChildOfClass("TextLabel")
	if title then
		title.Text = ("SCHNITZEL-DEX  %d/%d"):format(found, #Characters.List)
	end
end

-- Shop entries prompt native Roblox purchases; ids come from Config.
local function buildShop()
	local M = Config.Monetization
	local entries = {
		{ label = "2x Cash — Gamepass", kind = "pass", id = M.GamepassDoubleCash },
		{ label = ("VIP (+%d%% income) — Gamepass"):format(Config.VIPIncomeBonus * 100), kind = "pass", id = M.GamepassVIP },
		{ label = ("$%d Cash"):format(Config.CashProductAmounts.Small), kind = "product", id = M.ProductCashSmall },
		{ label = ("$%d Cash"):format(Config.CashProductAmounts.Medium), kind = "product", id = M.ProductCashMedium },
		{ label = ("$%d Cash"):format(Config.CashProductAmounts.Large), kind = "product", id = M.ProductCashLarge },
	}
	for _, entry in entries do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 42)
		button.Font = Enum.Font.FredokaOne
		button.TextScaled = true
		button.TextColor3 = Color3.new(1, 1, 1)
		button.BackgroundColor3 = entry.id ~= 0 and Color3.fromRGB(60, 130, 90) or Color3.fromRGB(60, 62, 72)
		button.Text = entry.id ~= 0 and entry.label or entry.label .. "  (soon)"
		button.Parent = shopContent
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button
		if entry.id ~= 0 then
			button.Activated:Connect(function()
				if entry.kind == "pass" then
					MarketplaceService:PromptGamePassPurchase(player, entry.id)
				else
					MarketplaceService:PromptProductPurchase(player, entry.id)
				end
			end)
		end
	end
end
buildShop()

local function makeToggle(text: string, offsetX: number, panel: Frame, onOpen: (() -> ())?)
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0, 1)
	button.Position = UDim2.new(0, 14 + offsetX, 1, -20)
	button.Size = UDim2.new(0, 110, 0, 40)
	button.Font = Enum.Font.FredokaOne
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = Color3.fromRGB(40, 44, 58)
	button.Text = text
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	button.Activated:Connect(function()
		local open = not panel.Visible
		dexPanel.Visible = false
		shopPanel.Visible = false
		panel.Visible = open
		if open and onOpen then
			onOpen()
		end
	end)
end

makeToggle("DEX", 0, dexPanel, refreshDex)
makeToggle("SHOP", 120, shopPanel)
