local require = ...

local Defaults = require("config.Defaults")
local Table = require("utils.Table")

local Config = {}
Config.__index = Config

function Config.load(overrides)
	local self = setmetatable({}, Config)
	self._data = Table.deepMerge(Defaults, overrides or {})
	return self
end

function Config:_parts(path)
	local parts = {}

	for part in tostring(path):gmatch("[^%.]+") do
		table.insert(parts, part)
	end

	return parts
end

function Config:get(path, default)
	local node = self._data

	for _, part in ipairs(self:_parts(path)) do
		if type(node) ~= "table" then
			return default
		end

		node = node[part]

		if node == nil then
			return default
		end
	end

	return node
end

function Config:set(path, value)
	local parts = self:_parts(path)

	if #parts == 0 then
		return value
	end

	local node = self._data

	for i = 1, #parts - 1 do
		if type(node[parts[i]]) ~= "table" then
			node[parts[i]] = {}
		end

		node = node[parts[i]]
	end

	node[parts[#parts]] = value
	return value
end

function Config:snapshot()
	return Table.deepMerge(self._data, {})
end

return Config
