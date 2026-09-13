local require = ...

local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")

local Analytics = {}
Analytics.__index = Analytics

function Analytics.new(context)
	return setmetatable({
		context = context,
		maid = Maid.new(),
		values = {},
		running = false,
		startedAt = nil,
	}, Analytics)
end

function Analytics:_increment(key, amount)
	self.values[key] = (self.values[key] or 0) + (amount or 1)
end

function Analytics:start()
	if self.running then
		return false
	end
	self.running = true
	self.startedAt = os.clock()
	self.values = {
		entitiesIndexed = self.context.world and self.context.world:count() or 0,
		entitiesAdded = 0,
		entitiesRemoved = 0,
		movementSamples = 0,
		interactionsCompleted = 0,
		inventoryGained = 0,
		inventorySpent = 0,
		workflowTransitions = 0,
		pickupCandidates = 0,
		sellCandidates = 0,
	}

	local bus = self.context.eventBus
	self.maid:Add(bus:on(EventTypes.WorldEntityAdded, function()
		self:_increment("entitiesAdded")
	end))
	self.maid:Add(bus:on(EventTypes.WorldEntityRemoved, function()
		self:_increment("entitiesRemoved")
	end))
	self.maid:Add(bus:on(EventTypes.MovementSample, function()
		self:_increment("movementSamples")
	end))
	self.maid:Add(bus:on(EventTypes.InteractionCompleted, function()
		self:_increment("interactionsCompleted")
	end))
	self.maid:Add(bus:on(EventTypes.WorkflowStateChanged, function(event)
		if event and event.signal ~= "start" and event.signal ~= "stop" then
			self:_increment("workflowTransitions")
		end
	end))
	self.maid:Add(bus:on(EventTypes.SemanticAction, function(event)
		if not event then return end
		if event.kind == "inventory-gained" then
			self:_increment("inventoryGained", math.max(1, event.delta or 1))
		elseif event.kind == "inventory-spent" then
			self:_increment("inventorySpent", math.abs(event.delta or 1))
		elseif event.kind == "pickup-candidate" then
			self:_increment("pickupCandidates")
		elseif event.kind == "sell-candidate" then
			self:_increment("sellCandidates")
		end
	end))

	return true
end

function Analytics:stop()
	if not self.running then
		return false
	end
	self.running = false
	self.maid:Clean()
	return true
end

function Analytics:snapshot()
	local out = {}
	for key, value in pairs(self.values) do
		out[key] = value
	end
	out.uptime = self.startedAt and os.clock() - self.startedAt or 0
	return out
end

return Analytics
