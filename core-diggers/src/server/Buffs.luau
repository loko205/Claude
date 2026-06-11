-- Timed potion buffs. Expiry attributes use os.time() so the client can
-- render countdowns.
local Buffs = {}

local active: { [Player]: { [string]: number } } = {}

function Buffs.grant(player: Player, id: string, duration: number)
	local buffs = active[player]
	if not buffs then
		buffs = {}
		active[player] = buffs
	end
	buffs[id] = math.max(buffs[id] or 0, os.clock()) + duration
	player:SetAttribute("buff_" .. id, os.time() + math.floor(buffs[id] - os.clock()))
end

function Buffs.has(player: Player, id: string): boolean
	local buffs = active[player]
	return buffs ~= nil and (buffs[id] or 0) > os.clock()
end

function Buffs.onPlayerRemoving(player: Player)
	active[player] = nil
end

return Buffs
