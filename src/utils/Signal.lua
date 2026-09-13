local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

function Connection:Disconnect()
	if self._disconnected then
		return
	end

	self._disconnected = true
	local handlers = self._signal._handlers

	for i = #handlers, 1, -1 do
		if handlers[i] == self then
			table.remove(handlers, i)
		end
	end
end

function Connection:connected()
	return not self._disconnected
end

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(handler)
	if type(handler) ~= "function" then
		error("Signal:Connect expects a function", 2)
	end

	local connection = setmetatable({
		_fn = handler,
		_signal = self,
		_disconnected = false,
	}, Connection)

	table.insert(self._handlers, connection)
	return connection
end

function Signal:Once(handler)
	local connection

	connection = self:Connect(function(...)
		if connection then
			connection:Disconnect()
		end
		handler(...)
	end)

	return connection
end

function Signal:Fire(...)
	local snapshot = {}
	for i, connection in ipairs(self._handlers) do
		snapshot[i] = connection
	end

	for _, connection in ipairs(snapshot) do
		if not connection._disconnected then
			connection._fn(...)
		end
	end
end

function Signal:Destroy()
	for _, connection in ipairs(self._handlers) do
		connection._disconnected = true
	end

	self._handlers = {}
end

return Signal
