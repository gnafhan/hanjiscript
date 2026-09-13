local require = ...

local Signal = require("utils.Signal")

local Logger = {}
Logger.__index = Logger

Logger.Levels = {
	debug = 10,
	info = 20,
	warn = 30,
	error = 40,
}

function Logger.levelFromName(name)
	if type(name) == "number" then
		return name
	end

	return Logger.Levels[string.lower(tostring(name))] or Logger.Levels.info
end

function Logger.new(options)
	options = options or {}

	return setmetatable({
		_minLevel = Logger.levelFromName(options.minLevel or "info"),
		_history = {},
		_maxHistory = options.maxHistory or 500,
		Emitted = Signal.new(),
	}, Logger)
end

function Logger:setLevel(level)
	self._minLevel = Logger.levelFromName(level)
end

function Logger:_write(level, tag, message, fields)
	if level < self._minLevel then
		return
	end

	local entry = {
		level = level,
		tag = tag or "App",
		message = tostring(message),
		fields = fields,
		timestamp = os.clock(),
	}

	table.insert(self._history, entry)

	if #self._history > self._maxHistory then
		table.remove(self._history, 1)
	end

	self.Emitted:Fire(entry)
end

function Logger:debug(tag, message, fields)
	self:_write(Logger.Levels.debug, tag, message, fields)
end

function Logger:info(tag, message, fields)
	self:_write(Logger.Levels.info, tag, message, fields)
end

function Logger:warn(tag, message, fields)
	self:_write(Logger.Levels.warn, tag, message, fields)
end

function Logger:error(tag, message, fields)
	self:_write(Logger.Levels.error, tag, message, fields)
end

function Logger:history()
	return self._history
end

function Logger:destroy()
	self.Emitted:Destroy()
	self._history = {}
end

return Logger
