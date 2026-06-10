-- Cash handling via leaderstats (server-authoritative).
local Economy = {}

function Economy.setup(player: Player, startCash: number)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("NumberValue")
	cash.Name = "Cash"
	cash.Value = startCash
	cash.Parent = leaderstats
	leaderstats.Parent = player
end

local function cashValue(player: Player): NumberValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Cash") :: NumberValue
end

function Economy.getCash(player: Player): number
	local cash = cashValue(player)
	return cash and cash.Value or 0
end

function Economy.addCash(player: Player, amount: number)
	local cash = cashValue(player)
	if cash then
		cash.Value += amount
	end
end

function Economy.trySpend(player: Player, amount: number): boolean
	local cash = cashValue(player)
	if cash and cash.Value >= amount then
		cash.Value -= amount
		return true
	end
	return false
end

return Economy
