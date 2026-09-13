local require = ...

local Signal = require("utils.Signal")

local UIState = {}
UIState.__index = UIState

function UIState.new(initial)
	return setmetatable({
		_data = initial or {},
		Changed = Signal.new(),
		ChangedKey = Signal.new(),
	}, UIState)
end

function UIState:get(key, default)
	local value = self._data[key]

	if value == nil then
		return default
	end

	return value
end

function UIState:set(key, value)
	if self._data[key] == value then
		return value
	end

	self._data[key] = value
	self.Changed:Fire(key, value)
	self.ChangedKey:Fire(key, value)
	return value
end

function UIState:update(patch)
	for key, value in pairs(patch) do
		self:set(key, value)
	end
end

function UIState:snapshot()
	local out = {}

	for key, value in pairs(self._data) do
		out[key] = value
	end

	return out
end

function UIState:destroy()
	self.Changed:Destroy()
	self.ChangedKey:Destroy()
end

return UIState
