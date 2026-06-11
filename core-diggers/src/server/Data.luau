-- DataStore persistence with retries. Profile shape:
-- { cash, prestige, shovel, pack, inv = {id=n}, relics = {id=n},
--   donated = {id=true}, depthBest, streak, lastDaily, lastSeen }
local DataStoreService = game:GetService("DataStoreService")

local Data = {}

local store = DataStoreService:GetDataStore("CoreDiggers_v1")

local function defaultProfile()
	return {
		cash = 25,
		prestige = 0,
		shovel = "rusty",
		pack = 1,
		inv = {},
		gear = {},
		perks = {},
		relics = {},
		donated = {},
		depthBest = 0,
		contracts = {},
		contractsDay = 0,
		streak = 0,
		lastDaily = 0,
		lastSeen = 0,
	}
end

local function withRetries(fn)
	for attempt = 1, 3 do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		if attempt < 3 then
			task.wait(2 ^ attempt)
		else
			warn("DataStore call failed:", result)
		end
	end
	return false, nil
end

function Data.load(player: Player)
	local ok, profile = withRetries(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	if not ok then
		-- Mark so we never overwrite real data with a fresh profile.
		player:SetAttribute("DataLoadFailed", true)
	end
	return profile or defaultProfile()
end

function Data.save(player: Player, profile)
	if player:GetAttribute("DataLoadFailed") then
		return
	end
	withRetries(function()
		store:SetAsync(tostring(player.UserId), profile)
		return nil
	end)
end

return Data
