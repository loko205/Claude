-- Global rich list on an OrderedDataStore, shown on the physical board
-- next to the plaza (MapBlueprint key "leaderboard").
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Leaderboard = {}

local store = DataStoreService:GetOrderedDataStore("GlobalCash_v1")
local nameCache: { [number]: string } = {}

local function nameFor(userId: number): string
	if not nameCache[userId] then
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
		nameCache[userId] = ok and name or "???"
	end
	return nameCache[userId]
end

function Leaderboard.submit(userId: number, cash: number)
	task.spawn(function()
		pcall(store.SetAsync, store, tostring(userId), math.floor(cash))
	end)
end

function Leaderboard.init(board: Part)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 340, 0, 380)
	gui.StudsOffset = Vector3.new(0, 1, 0)
	gui.MaxDistance = 140
	gui.Parent = board

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 44)
	title.Font = Enum.Font.FredokaOne
	title.Text = "RICHEST PLAYERS"
	title.TextColor3 = Color3.fromRGB(255, 205, 80)
	title.TextScaled = true
	title.TextStrokeTransparency = 0.2
	title.Parent = gui

	local listLabel = Instance.new("TextLabel")
	listLabel.BackgroundTransparency = 1
	listLabel.Position = UDim2.new(0, 0, 0, 48)
	listLabel.Size = UDim2.new(1, 0, 1, -48)
	listLabel.Font = Enum.Font.FredokaOne
	listLabel.Text = "..."
	listLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	listLabel.TextSize = 24
	listLabel.TextYAlignment = Enum.TextYAlignment.Top
	listLabel.TextStrokeTransparency = 0.3
	listLabel.Parent = gui

	task.spawn(function()
		while true do
			local ok, pages = pcall(store.GetSortedAsync, store, false, 10)
			if ok then
				local lines = {}
				for rank, entry in pages:GetCurrentPage() do
					table.insert(lines, ("%d. %s — $%d"):format(rank, nameFor(tonumber(entry.key) :: number), entry.value))
				end
				listLabel.Text = #lines > 0 and table.concat(lines, "\n") or "Be the first!"
			end
			task.wait(Config.LeaderboardRefresh)
		end
	end)
end

return Leaderboard
