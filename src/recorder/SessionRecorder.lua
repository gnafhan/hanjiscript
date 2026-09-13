local require = ...

local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")
local EventSchema = require("recorder.EventSchema")

local SessionRecorder = {}
SessionRecorder.__index = SessionRecorder

local TYPES = {
	EventTypes.MovementSample,
	EventTypes.InteractionStarted,
	EventTypes.InteractionCompleted,
	EventTypes.WorldEntityAdded,
	EventTypes.WorldEntityRemoved,
	EventTypes.InventoryChanged,
	EventTypes.NavigationStarted,
	EventTypes.NavigationCompleted,
	EventTypes.WorkflowStateChanged,
	EventTypes.WorkflowPlanUpdated,
	EventTypes.SemanticAction,
}

local SOURCES = {
	[EventTypes.MovementSample] = "MovementSensor",
	[EventTypes.InteractionStarted] = "InteractionSensor",
	[EventTypes.InteractionCompleted] = "InteractionSensor",
	[EventTypes.WorldEntityAdded] = "WorldModel",
	[EventTypes.WorldEntityRemoved] = "WorldModel",
	[EventTypes.InventoryChanged] = "InventorySensor",
	[EventTypes.NavigationStarted] = "Navigator",
	[EventTypes.NavigationCompleted] = "Navigator",
	[EventTypes.WorkflowStateChanged] = "StateMachine",
	[EventTypes.WorkflowPlanUpdated] = "Planner",
	[EventTypes.SemanticAction] = "EventCorrelator",
}

local function serializable(value, seen)
	local kind = typeof(value)
	if kind == "Vector3" then
		return { x = value.X, y = value.Y, z = value.Z }
	end
	if kind == "CFrame" then
		local position = value.Position
		return { x = position.X, y = position.Y, z = position.Z }
	end
	if kind == "Instance" then
		return value:GetFullName()
	end
	if type(value) ~= "table" then
		return value
	end

	seen = seen or {}
	if seen[value] then
		return nil
	end
	seen[value] = true

	local out = {}
	for key, item in pairs(value) do
		out[tostring(key)] = serializable(item, seen)
	end
	return out
end

function SessionRecorder.new(context)
	return setmetatable({
		context = context,
		maid = Maid.new(),
		status = "idle",
		events = {},
		session = nil,
		startedAt = nil,
		lastExportPath = nil,
	}, SessionRecorder)
end

function SessionRecorder:start()
	if self.status == "running" then
		return false
	end

	self.status = "running"
	self.events = {}
	self.session = EventSchema.session(self.context)
	self.startedAt = os.clock()
	self.lastExportPath = nil

	for _, eventType in ipairs(TYPES) do
		self.maid:Add(self.context.eventBus:on(eventType, function(data)
			if self.status ~= "running" then
				return
			end

			table.insert(self.events, EventSchema.event(
				eventType,
				SOURCES[eventType],
				self.session.id,
				os.clock() - self.startedAt,
				data
			))
		end))
	end

	return true
end

function SessionRecorder:stop()
	if self.status ~= "running" and self.status ~= "paused" then
		return false
	end

	self.status = "stopped"
	self.maid:Clean()

	if self.session then
		self.session.duration = os.clock() - (self.startedAt or os.clock())
		self.session.eventCount = #self.events
		self.session.events = self.events
	end

	local capabilities = self.context.capabilities or {}
	if capabilities.persistence and type(writefile) == "function" and self.session then
		local ok, json = pcall(function()
			return game:GetService("HttpService"):JSONEncode(serializable(self.session))
		end)
		if ok then
			if type(makefolder) == "function" then
				pcall(makefolder, "HanjiScript")
			end
			self.lastExportPath = "HanjiScript/session-" .. os.time() .. ".json"
			pcall(writefile, self.lastExportPath, json)
		end
	end

	return true
end

function SessionRecorder:pause()
	if self.status ~= "running" then
		return false
	end
	self.status = "paused"
	return true
end

function SessionRecorder:resume()
	if self.status ~= "paused" then
		return false
	end
	self.status = "running"
	return true
end

function SessionRecorder:getSession()
	return self.session
end

function SessionRecorder:getEventCount()
	return #self.events
end

return SessionRecorder
