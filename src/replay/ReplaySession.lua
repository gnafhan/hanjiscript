local require = ...

local EventTypes = require("core.EventTypes")
local ReplayClock = require("replay.ReplayClock")

local ReplaySession = {}
ReplaySession.__index = ReplaySession

local function eventTime(event)
	return tonumber(event and event.timestamp) or 0
end

local function copy(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return nil
	end
	seen[value] = true
	local result = {}
	for key, item in pairs(value) do
		result[key] = copy(item, seen)
	end
	return result
end

function ReplaySession.new(context)
	local self = setmetatable({
		context = context,
		clock = ReplayClock.new(),
		session = nil,
		events = {},
		cursor = 1,
		state = {},
	}, ReplaySession)

	self.clock:onTick(function(time)
		self:advanceTo(time)
	end)
	return self
end

function ReplaySession:_resetState()
	self.state = {
		position = nil,
		inventoryCount = 0,
		entities = {},
		workflowState = nil,
		lastSemantic = nil,
	}
	self.cursor = 1
end

function ReplaySession:load(session)
	if type(session) ~= "table" or type(session.events) ~= "table" then
		return false, "session must contain an events array"
	end

	self.session = session
	self.events = {}
	for _, event in ipairs(session.events) do
		table.insert(self.events, event)
	end
	table.sort(self.events, function(a, b)
		return eventTime(a) < eventTime(b)
	end)
	self:_resetState()
	self.clock:seek(0)
	return true
end

function ReplaySession:_apply(event)
	local eventType = event.type
	local data = event.data or {}
	if eventType == EventTypes.MovementSample then
		self.state.position = data.position
	elseif eventType == EventTypes.InventoryChanged then
		self.state.inventoryCount = data.after or self.state.inventoryCount
	elseif eventType == EventTypes.WorldEntityAdded then
		local id = data.id or data.path or data.name
		if id then self.state.entities[id] = data end
	elseif eventType == EventTypes.WorldEntityRemoved then
		local id = data.id or data.path or data.name
		if id then self.state.entities[id] = nil end
	elseif eventType == EventTypes.WorkflowStateChanged then
		self.state.workflowState = data.state
	elseif eventType == EventTypes.SemanticAction then
		self.state.lastSemantic = data
	end

	if self.context and self.context.eventBus then
		self.context.eventBus:emit(EventTypes.ReplayEventApplied, {
			timestamp = eventTime(event),
			type = eventType,
		})
	end
end

function ReplaySession:advanceTo(time)
	local targetTime = math.max(0, tonumber(time) or 0)
	self.clock.time = targetTime
	while self.cursor <= #self.events and eventTime(self.events[self.cursor]) <= targetTime do
		self:_apply(self.events[self.cursor])
		self.cursor += 1
	end

	if self.context and self.context.eventBus then
		self.context.eventBus:emit(EventTypes.ReplayStateChanged, self:getSnapshot())
	end
	return self:getSnapshot()
end

function ReplaySession:seek(time)
	local targetTime = math.max(0, tonumber(time) or 0)
	self:_resetState()
	self.clock.time = 0
	return self:advanceTo(targetTime)
end

function ReplaySession:play()
	return self.clock:play()
end

function ReplaySession:pause()
	return self.clock:pause()
end

function ReplaySession:step(delta)
	local amount = math.max(0, tonumber(delta) or 0)
	self.clock.time += amount
	return self:advanceTo(self.clock.time)
end

function ReplaySession:getSnapshot()
	local entityCount = 0
	for _ in pairs(self.state.entities or {}) do
		entityCount += 1
	end
	return {
		sessionId = self.session and self.session.id,
		currentTime = self.clock.time,
		duration = self.session and self.session.duration or (#self.events > 0 and eventTime(self.events[#self.events]) or 0),
		cursor = self.cursor,
		eventCount = #self.events,
		playing = self.clock.playing,
		state = {
			position = copy(self.state.position),
			inventoryCount = self.state.inventoryCount,
			entityCount = entityCount,
			workflowState = self.state.workflowState,
			lastSemantic = copy(self.state.lastSemantic),
		},
	}
end

function ReplaySession:destroy()
	self:pause()
	self.clock:destroy()
	self.events = {}
	self.session = nil
	self:_resetState()
end

return ReplaySession
