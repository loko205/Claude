-- Exports Shared/MapBlueprint as JSON for the map preview renderer.
-- Run with the standalone Luau CLI:  luau tools/export_map.luau > /tmp/map.json
local MapBlueprint = require("../src/shared/MapBlueprint")

local function encode(value): string
	local t = type(value)
	if t == "number" then
		return string.format("%.6g", value)
	elseif t == "boolean" then
		return tostring(value)
	elseif t == "string" then
		return string.format("%q", value)
	elseif t == "table" then
		if #value > 0 then
			local parts = {}
			for _, v in value do
				table.insert(parts, encode(v))
			end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local parts = {}
		for k, v in value do
			table.insert(parts, string.format("%q", k) .. ":" .. encode(v))
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	error("unsupported type: " .. t)
end

print(encode(MapBlueprint.build()))
