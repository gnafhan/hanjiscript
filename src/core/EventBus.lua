local require = ...

local Signal = require("utils.Signal")

local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
	return setmetatable({ _signals = {} }, EventBus)
end

function EventBus:_signal(eventType)
	local signal = self._signals[eventType]

	if not signal then
		signal = Signal.new()
		self._signals[eventType] = signal
	end

	return signal
end

function EventBus:on(eventType, handler)
	return self:_signal(eventType):Connect(handler)
end

function EventBus:once(eventType, handler)
	return self:_signal(eventType):Once(handler)
end

function EventBus:emit(eventType, payload)
	return self:_signal(eventType):Fire(payload)
end

function EventBus:destroy()
	for _, signal in pairs(self._signals) do
		signal:Destroy()
	end

	self._signals = {}
end

return EventBus
