local Adapter = {}
Adapter.__index = Adapter

Adapter.VERSION = "1.0.0"

function Adapter.new(id)
	local self = setmetatable({}, Adapter)
	self.id = id or "adapter"
	self.version = Adapter.VERSION
	self.context = nil
	return self
end

function Adapter:supports(_context)
	return false
end

function Adapter:init(context)
	self.context = context
end

function Adapter:start() end

function Adapter:stop() end

function Adapter:getEntityRules()
	return {}
end

function Adapter:getWorkflows()
	return {}
end

function Adapter:getFeatures()
	return {}
end

return Adapter
