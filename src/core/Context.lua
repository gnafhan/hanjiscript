local Context = {}
Context.__index = Context

local function defaultFields()
	return {
		runtime = {},
		experience = {},
		capabilities = {},
		services = {},
		config = nil,
		logger = nil,
		eventBus = nil,
		commandBus = nil,
		metrics = nil,
		world = {},
		analytics = nil,
		workflowRunner = nil,
		navigator = nil,
		interactionController = nil,
		replay = nil,
		adapters = nil,
		features = nil,
		ui = nil,
		overlay = nil,
	}
end

function Context.new(fields)
	local self = setmetatable(defaultFields(), Context)

	for key, value in pairs(fields or {}) do
		self[key] = value
	end

	return self
end

function Context:set(serviceName, service)
	self.services[serviceName] = service
	return service
end

function Context:get(serviceName)
	return self.services[serviceName]
end

return Context
