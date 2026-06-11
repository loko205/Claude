-- Exports World + CampBlueprint + RelicDesigns as JSON for preview rendering.
-- Run:  luau tools/export_world.luau > /tmp/cd_world.json
local World = require("../src/shared/World")
local CampBlueprint = require("../src/shared/CampBlueprint")
local RelicDesigns = require("../src/shared/RelicDesigns")

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
			if type(v) ~= "function" then
				table.insert(parts, string.format("%q", k) .. ":" .. encode(v))
			end
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	error("unsupported type: " .. t)
end

print(encode({
	layers = World.Layers,
	island = World.Island,
	blockSize = World.BlockSize,
	items = World.Items,
	relics = World.Relics,
	shovels = World.Shovels,
	camp = CampBlueprint.build().parts,
	relicDesigns = RelicDesigns,
}))
