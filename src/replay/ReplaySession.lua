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
		snapshots = {},
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
		entityCountOverride = nil,
		workflowState = nil,
		lastSemantic = nil,
		checkpointTime = nil,
		inference = nil,
	}
	self.cursor = 1
end

function ReplaySession:load(session)
	if type(session) ~= "table" or type(session.events) ~= "table" then
		return false, "session must contain an events array"
	end

	self.session = session
	self.inference = session.inference
	self.events = {}
	for _, event in ipairs(session.events) do
		table.insert(self.events, event)
	end
	table.sort(self.events, function(a, b)
		return eventTime(a) < eventTime(b)
	end)
	self.snapshots = {}
	for _, snapshot in ipairs(session.snapshots or {}) do
		if type(snapshot) == "table" then
			table.insert(self.snapshots, snapshot)
		end
	end
	table.sort(self.snapshots, function(a, b)
		return (tonumber(a.timestamp) or 0) < (tonumber(b.timestamp) or 0)
	end)
	self:_resetState()
	self.clock:seek(0)
	return true
end

function ReplaySession:_restoreSnapshot(snapshot)
	if type(snapshot) ~= "table" then
		return
	end

	local world = snapshot.world or {}
	local inventory = snapshot.inventory or {}
	local workflow = snapshot.workflow or {}
	self.state.position = copy(snapshot.player and snapshot.player.position)
	self.state.inventoryCount = tonumber(inventory.count) or 0
	self.state.workflowState = workflow.state
	self.state.entityCountOverride = tonumber(world.entityCount)
	self.state.checkpointTime = tonumber(snapshot.timestamp) or 0
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
		if id then
			if self.state.entityCountOverride ~= nil and not self.state.entities[id] then
				self.state.entityCountOverride += 1
			end
			self.state.entities[id] = data
		end
	elseif eventType == EventTypes.WorldEntityRemoved then
		local id = data.id or data.path or data.name
		if id then
			if self.state.entityCountOverride ~= nil then
				self.state.entityCountOverride = math.max(0, self.state.entityCountOverride - 1)
			end
			self.state.entities[id] = nil
		end
	elseif eventType == EventTypes.WorldEntityUpdated then
		local entity = data.entity or data
		local id = entity.id or entity.path or entity.name
		if id then
			self.state.entities[id] = entity
		end
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

	-- Restore the nearest checkpoint first, then replay only the tail of the
	-- event stream. This keeps long sessions responsive while preserving the
	-- same deterministic result as a full replay.
	local checkpoint
	for _, snapshot in ipairs(self.snapshots) do
		if (tonumber(snapshot.timestamp) or 0) <= targetTime then
			checkpoint = snapshot
		else
			break
		end
	end
	if checkpoint then
		self:_restoreSnapshot(checkpoint)
		local checkpointTime = tonumber(checkpoint.timestamp) or 0
		while self.cursor <= #self.events and eventTime(self.events[self.cursor]) <= checkpointTime do
			self.cursor += 1
		end
	end
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
	local entityCount = self.state.entityCountOverride
	if entityCount == nil then
		entityCount = 0
		for _ in pairs(self.state.entities or {}) do
			entityCount += 1
		end
	end
	return {
		sessionId = self.session and self.session.id,
		currentTime = self.clock.time,
		duration = self.session and self.session.duration or (#self.events > 0 and eventTime(self.events[#self.events]) or 0),
		cursor = self.cursor,
		eventCount = #self.events,
		snapshotCount = #self.snapshots,
		checkpointTime = self.state.checkpointTime,
		inference = copy(self.inference),
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
