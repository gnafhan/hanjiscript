local CommandBus = {}
CommandBus.__index = CommandBus

function CommandBus.new(context)
	return setmetatable({
		_context = context,
		_handlers = {},
		_history = {},
	}, CommandBus)
end

function CommandBus:register(name, handler)
	if type(handler) ~= "function" then
		error("CommandBus:register expects a function", 2)
	end

	self._handlers[name] = handler
	return self
end

function CommandBus:execute(name, ...)
	local handler = self._handlers[name]

	if not handler then
		return false, ("unknown command: %s"):format(tostring(name))
	end

	table.insert(self._history, name)

	if #self._history > 128 then
		table.remove(self._history, 1)
	end

	handler(...)
	return true
end

function CommandBus:has(name)
	return self._handlers[name] ~= nil
end

function CommandBus:list()
	local names = {}

	for name in pairs(self._handlers) do
		table.insert(names, name)
	end

	table.sort(names)
	return names
end

function CommandBus:history()
	return self._history
end

return CommandBus
