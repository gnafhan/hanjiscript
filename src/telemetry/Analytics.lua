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
		navigationStartedAt = nil,
		cycleStartedAt = nil,
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
		navigationStarted = 0,
		navigationCompleted = 0,
		navigationFailures = 0,
		navigationDistance = 0,
		navigationPathLength = 0,
		navigationPathSamples = 0,
		workflowCycles = 0,
		cycleDuration = 0,
		cycleSamples = 0,
	}
	self.navigationStartedAt = nil
	self.cycleStartedAt = nil

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
	self.maid:Add(bus:on(EventTypes.NavigationStarted, function()
		self:_increment("navigationStarted")
		self.navigationStartedAt = os.clock()
	end))
	self.maid:Add(bus:on(EventTypes.NavigationPathComputed, function(event)
		if not event then return end
		local distance = tonumber(event.distance)
		local pathLength = tonumber(event.pathLength)
		if distance then self.values.navigationDistance += math.max(0, distance) end
		if pathLength then
			self.values.navigationPathLength += math.max(0, pathLength)
			self.values.navigationPathSamples += 1
		end
	end))
	self.maid:Add(bus:on(EventTypes.NavigationCompleted, function(event)
		self:_increment("navigationCompleted")
		if event and event.success == false then
			self:_increment("navigationFailures")
		end
		self.navigationStartedAt = nil
	end))
	self.maid:Add(bus:on(EventTypes.WorkflowStateChanged, function(event)
		if event and event.signal ~= "start" and event.signal ~= "stop" then
			self:_increment("workflowTransitions")
		end
		if not event then return end
		if event.signal == "start" then
			self.cycleStartedAt = os.clock()
		elseif event.previousState == "sell" and event.state == "find_item" then
			self:_increment("workflowCycles")
			if self.cycleStartedAt then
				self.values.cycleDuration += math.max(0, os.clock() - self.cycleStartedAt)
				self:_increment("cycleSamples")
			end
			self.cycleStartedAt = os.clock()
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
	self.navigationStartedAt = nil
	self.cycleStartedAt = nil
	return true
end

function Analytics:snapshot()
	local out = {}
	for key, value in pairs(self.values) do
		out[key] = value
	end
	out.uptime = self.startedAt and math.max(0, os.clock() - self.startedAt) or 0
	out.averagePathLength = out.navigationPathSamples > 0
		and out.navigationPathLength / out.navigationPathSamples
		or 0
	out.averageCycleTime = out.cycleSamples > 0
		and out.cycleDuration / out.cycleSamples
		or 0
	out.navigationSuccessRate = out.navigationCompleted > 0
		and (out.navigationCompleted - out.navigationFailures) / out.navigationCompleted
		or 0
	out.routeEfficiency = out.navigationPathLength > 0
		and out.navigationDistance / out.navigationPathLength
		or 0
	out.itemsPerMinute = out.uptime > 0
		and (out.inventoryGained / (out.uptime / 60))
		or 0
	return out
end

return Analytics
