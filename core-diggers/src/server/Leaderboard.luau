-- Global "deepest diggers" list on an OrderedDataStore, shown on the camp board.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage.Shared.World)

local Leaderboard = {}

local store = DataStoreService:GetOrderedDataStore("CoreDepth_v1")
local nameCache: { [number]: string } = {}

local function nameFor(userId: number): string
	if not nameCache[userId] then
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
		nameCache[userId] = ok and name or "???"
	end
	return nameCache[userId]
end

function Leaderboard.submit(userId: number, depthBest: number)
	if depthBest <= 0 then
		return
	end
	task.spawn(function()
		pcall(store.SetAsync, store, tostring(userId), depthBest)
	end)
end

function Leaderboard.init(board: Part)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 300, 0, 340)
	gui.StudsOffset = Vector3.new(0, 1, 0)
	gui.MaxDistance = 90
	gui.Parent = board

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Font = Enum.Font.FredokaOne
	title.Text = "DEEPEST DIGGERS"
	title.TextColor3 = Color3.fromRGB(90, 220, 255)
	title.TextScaled = true
	title.TextStrokeTransparency = 0.2
	title.Parent = gui

	local listLabel = Instance.new("TextLabel")
	listLabel.BackgroundTransparency = 1
	listLabel.Position = UDim2.new(0, 0, 0, 44)
	listLabel.Size = UDim2.new(1, 0, 1, -44)
	listLabel.Font = Enum.Font.FredokaOne
	listLabel.Text = "..."
	listLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	listLabel.TextSize = 22
	listLabel.TextYAlignment = Enum.TextYAlignment.Top
	listLabel.TextStrokeTransparency = 0.3
	listLabel.Parent = gui

	task.spawn(function()
		while true do
			local ok, pages = pcall(store.GetSortedAsync, store, false, 10)
			if ok then
				local lines = {}
				for rank, entry in pages:GetCurrentPage() do
					table.insert(lines, ("%d. %s — Layer %d"):format(rank, nameFor(tonumber(entry.key) :: number), entry.value))
				end
				listLabel.Text = #lines > 0 and table.concat(lines, "\n") or "Be the first!"
			end
			task.wait(World.LeaderboardRefresh)
		end
	end)
end

return Leaderboard
