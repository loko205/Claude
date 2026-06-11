-- HUD: cash/bag/depth/prestige panel, surface + sell buttons, shop & museum
-- frames, notifications with SFX.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")

local World = require(ReplicatedStorage.Shared.World)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local SUFFIXES = { "K", "M", "B", "T" }
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

local function makeLabel(parent: Instance, props: { [string]: any }): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextStrokeTransparency = 0.3
	label.TextColor3 = Color3.new(1, 1, 1)
	for key, value in props do
		(label :: any)[key] = value
	end
	label.Parent = parent
	return label
end

-- Stats panel ------------------------------------------------------------
local statsPanel = Instance.new("Frame")
statsPanel.Position = UDim2.new(0, 14, 0, 14)
statsPanel.Size = UDim2.new(0, 260, 0, 132)
statsPanel.Parent = gui
styleFrame(statsPanel)

local cashLabel = makeLabel(statsPanel, {
	Position = UDim2.new(0, 16, 0, 8),
	Size = UDim2.new(1, -32, 0, 38),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(120, 255, 120),
	Text = "$0",
})
local bagLabel = makeLabel(statsPanel, {
	Position = UDim2.new(0, 16, 0, 48),
	Size = UDim2.new(1, -32, 0, 26),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Bag 0/20",
})
local depthLabel = makeLabel(statsPanel, {
	Position = UDim2.new(0, 16, 0, 76),
	Size = UDim2.new(1, -32, 0, 26),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(90, 220, 255),
	Text = "Surface",
})
local prestigeLabel = makeLabel(statsPanel, {
	Position = UDim2.new(0, 16, 0, 102),
	Size = UDim2.new(1, -32, 0, 24),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(255, 205, 80),
	Text = "",
})

-- Notifications ------------------------------------------------------------
local feed = Instance.new("Frame")
feed.BackgroundTransparency = 1
feed.AnchorPoint = Vector2.new(1, 0)
feed.Position = UDim2.new(1, -20, 0, 20)
feed.Size = UDim2.new(0, 330, 0, 320)
feed.Parent = gui
local feedLayout = Instance.new("UIListLayout")
feedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
feedLayout.Padding = UDim.new(0, 4)
feedLayout.Parent = feed

remotes.Notify.OnClientEvent:Connect(function(text: string, color: Color3?)
	if color and color.R > color.G then
		badSound:Play()
	else
		goodSound:Play()
	end
	local note = Instance.new("TextLabel")
	note.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	note.BackgroundTransparency = 0.3
	note.Size = UDim2.new(1, 0, 0, 30)
	note.Font = Enum.Font.FredokaOne
	note.TextScaled = true
	note.TextColor3 = color or Color3.new(1, 1, 1)
	note.Text = text
	note.Parent = feed
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = note
	task.delay(4, function()
		TweenService:Create(note, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.wait(0.5)
		note:Destroy()
	end)
end)

-- Panels (shop / museum) ----------------------------------------------------
local function makePanel(titleText: string): (Frame, ScrollingFrame, TextLabel)
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.Size = UDim2.new(0, 380, 0, 460)
	panel.Visible = false
	panel.Parent = gui
	styleFrame(panel)

	local title = makeLabel(panel, {
		Position = UDim2.new(0, 14, 0, 8),
		Size = UDim2.new(1, -70, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = titleText,
	})

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 8)
	close.Size = UDim2.new(0, 32, 0, 30)
	close.Font = Enum.Font.FredokaOne
	close.Text = "X"
	close.TextScaled = true
	close.TextColor3 = Color3.new(1, 1, 1)
	close.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	close.Parent = panel
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = close
	close.Activated:Connect(function()
		panel.Visible = false
	end)

	local content = Instance.new("ScrollingFrame")
	content.BackgroundTransparency = 1
	content.Position = UDim2.new(0, 12, 0, 46)
	content.Size = UDim2.new(1, -24, 1, -58)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.ScrollBarThickness = 6
	content.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = content

	return panel, content, title
end

local shopPanel, shopContent = makePanel("SHOVEL SHOP")
local museumPanel, museumContent = makePanel("MUSEUM — YOUR RELICS")

local function rowButton(parent: Instance, height: number): TextButton
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -8, 0, height)
	button.Font = Enum.Font.FredokaOne
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = Color3.fromRGB(50, 54, 70)
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

local function refreshShop()
	for _, child in shopContent:GetChildren() do
		if child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local equippedShovel = player:GetAttribute("Shovel") or "rusty"
	local equippedPack = player:GetAttribute("Pack") or 1

	makeLabel(shopContent, { Size = UDim2.new(1, 0, 0, 26), Text = "SHOVELS", TextColor3 = Color3.fromRGB(120, 190, 255) })
	for _, shovel in World.Shovels do
		local button = rowButton(shopContent, 38)
		if shovel.id == equippedShovel then
			button.Text = ("%s — EQUIPPED"):format(shovel.name)
			button.BackgroundColor3 = Color3.fromRGB(60, 130, 90)
		else
			button.Text = ("%s — dmg %d%s — $%s"):format(
				shovel.name, shovel.dmg,
				shovel.luck > 0 and (" +%d%% luck"):format(shovel.luck * 100) or "",
				fmt(shovel.price)
			)
			button.Activated:Connect(function()
				remotes.Buy:FireServer("shovel", shovel.id)
				task.wait(0.2)
				refreshShop()
			end)
		end
	end

	makeLabel(shopContent, { Size = UDim2.new(1, 0, 0, 26), Text = "BACKPACKS", TextColor3 = Color3.fromRGB(120, 190, 255) })
	for _, pack in World.Backpacks do
		local button = rowButton(shopContent, 38)
		if pack.id == equippedPack then
			button.Text = ("%s (%d) — EQUIPPED"):format(pack.name, pack.cap)
			button.BackgroundColor3 = Color3.fromRGB(60, 130, 90)
		else
			button.Text = ("%s — %d slots — $%s"):format(pack.name, pack.cap, fmt(pack.price))
			button.Activated:Connect(function()
				remotes.Buy:FireServer("pack", pack.id)
				task.wait(0.2)
				refreshShop()
			end)
		end
	end

	-- Robux section (entries appear once ids are configured in World.luau)
	local M = World.Monetization
	local robux = {
		{ label = "2x Cash — Gamepass", kind = "pass", id = M.GamepassDoubleCash },
		{ label = "VIP (+10% luck, +50 bag) — Gamepass", kind = "pass", id = M.GamepassVIP },
		{ label = "Portable Seller — Gamepass", kind = "pass", id = M.GamepassPortableSeller },
		{ label = ("$%s Cash"):format(fmt(World.CashProductAmounts.Small)), kind = "product", id = M.ProductCashSmall },
		{ label = ("$%s Cash"):format(fmt(World.CashProductAmounts.Medium)), kind = "product", id = M.ProductCashMedium },
		{ label = ("$%s Cash"):format(fmt(World.CashProductAmounts.Large)), kind = "product", id = M.ProductCashLarge },
	}
	local anyConfigured = false
	for _, entry in robux do
		if entry.id ~= 0 then
			anyConfigured = true
		end
	end
	if anyConfigured then
		makeLabel(shopContent, { Size = UDim2.new(1, 0, 0, 26), Text = "ROBUX", TextColor3 = Color3.fromRGB(120, 255, 120) })
		for _, entry in robux do
			if entry.id ~= 0 then
				local button = rowButton(shopContent, 38)
				button.BackgroundColor3 = Color3.fromRGB(60, 130, 90)
				button.Text = entry.label
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
end

local function refreshMuseum()
	for _, child in museumContent:GetChildren() do
		if child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("Frame") then
			child:Destroy()
		end
	end
	for _, relic in World.Relics do
		local count = player:GetAttribute("relic_" .. relic.id) or 0
		local donated = player:GetAttribute("don_" .. relic.id) == true
		local row = makeLabel(museumContent, {
			Size = UDim2.new(1, 0, 0, 26),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = ("%s %s%s"):format(donated and "★" or "☆", relic.name, count > 0 and ("  ×%d"):format(count) or ""),
			TextColor3 = donated and Color3.fromRGB(255, 205, 80)
				or (count > 0 and Color3.new(1, 1, 1) or Color3.fromRGB(110, 110, 120)),
		})
		if count > 0 then
			row.Size = UDim2.new(0.5, 0, 0, 26)
			local donate = rowButton(museumContent, 30)
			donate.Size = UDim2.new(1, -8, 0, 30)
			donate.BackgroundColor3 = Color3.fromRGB(60, 130, 90)
			donate.Text = ("Donate %s (+%d%% forever)"):format(relic.name, World.MuseumBonusPerRelic * 100)
			donate.Activated:Connect(function()
				remotes.Donate:FireServer(relic.id)
				task.wait(0.2)
				refreshMuseum()
			end)
			local sell = rowButton(museumContent, 30)
			sell.Text = ("Sell %s ($%s)"):format(relic.name, fmt(relic.value))
			sell.Activated:Connect(function()
				remotes.SellRelic:FireServer(relic.id)
				task.wait(0.2)
				refreshMuseum()
			end)
		end
	end
end

remotes.OpenUI.OnClientEvent:Connect(function(which: string)
	if which == "shop" then
		refreshShop()
		shopPanel.Visible = true
		museumPanel.Visible = false
	elseif which == "museum" then
		refreshMuseum()
		museumPanel.Visible = true
		shopPanel.Visible = false
	end
end)

-- Bottom buttons ------------------------------------------------------------
local function bottomButton(text: string, offsetX: number, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0, 1)
	button.Position = UDim2.new(0, 14 + offsetX, 1, -20)
	button.Size = UDim2.new(0, 120, 0, 42)
	button.Font = Enum.Font.FredokaOne
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = color
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

bottomButton("SURFACE", 0, Color3.fromRGB(40, 44, 58)).Activated:Connect(function()
	remotes.Teleport:FireServer()
end)
bottomButton("SELL", 130, Color3.fromRGB(60, 130, 90)).Activated:Connect(function()
	remotes.SellAll:FireServer()
end)
bottomButton("SHOP", 260, Color3.fromRGB(40, 44, 58)).Activated:Connect(function()
	refreshShop()
	shopPanel.Visible = not shopPanel.Visible
	museumPanel.Visible = false
end)
bottomButton("MUSEUM", 390, Color3.fromRGB(40, 44, 58)).Activated:Connect(function()
	refreshMuseum()
	museumPanel.Visible = not museumPanel.Visible
	shopPanel.Visible = false
end)

-- Live bindings --------------------------------------------------------------
task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats")
	local cash = leaderstats:WaitForChild("Cash") :: NumberValue
	local function update()
		cashLabel.Text = "$" .. fmt(cash.Value)
	end
	cash.Changed:Connect(update)
	update()
end)

local function updateBag()
	bagLabel.Text = ("Bag %d/%d"):format(player:GetAttribute("Bag") or 0, player:GetAttribute("BagCap") or 20)
end
local function updateDepth()
	local depth = player:GetAttribute("Depth") or 0
	if depth < 1 then
		depthLabel.Text = "Surface"
	else
		local layer = World.layerAt(depth)
		depthLabel.Text = ("Layer %d — %s"):format(depth, layer and layer.name or "?")
	end
end
local function updatePrestige()
	local prestige = player:GetAttribute("Prestige") or 0
	prestigeLabel.Text = prestige > 0
			and ("Prestige %d (+%d%% value)"):format(prestige, prestige * World.Core.prestigeBonus * 100)
		or "Crack the core for prestige!"
end

player:GetAttributeChangedSignal("Bag"):Connect(updateBag)
player:GetAttributeChangedSignal("BagCap"):Connect(updateBag)
player:GetAttributeChangedSignal("Depth"):Connect(updateDepth)
player:GetAttributeChangedSignal("Prestige"):Connect(updatePrestige)
updateBag()
updateDepth()
updatePrestige()
