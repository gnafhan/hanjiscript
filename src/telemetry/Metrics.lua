local Metrics = {}
Metrics.__index = Metrics

function Metrics.new()
	return setmetatable({
		_counters = {},
		_gauges = {},
		_startedAt = os.clock(),
	}, Metrics)
end

function Metrics:increment(name, amount)
	self._counters[name] = (self._counters[name] or 0) + (amount or 1)
end

function Metrics:set(name, value)
	self._gauges[name] = value
end

function Metrics:get(name)
	if self._gauges[name] ~= nil then
		return self._gauges[name]
	end

	return self._counters[name] or 0
end

function Metrics:reset()
	self._counters = {}
	self._gauges = {}
	self._startedAt = os.clock()
end

function Metrics:snapshot()
	local out = {}

	for name, value in pairs(self._counters) do
		out[name] = value
	end

	for name, value in pairs(self._gauges) do
		out[name] = value
	end

	out.uptime = os.clock() - self._startedAt
	return out
end

return Metrics
