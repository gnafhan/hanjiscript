local require = ...

local EventTypes = require("core.EventTypes")

local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(definition, context)
	assert(type(definition) == "table", "StateMachine requires a workflow definition")
	assert(type(definition.initial) == "string", "workflow definition is missing initial state")
	assert(type(definition.states) == "table", "workflow definition is missing states")

	return setmetatable({
		definition = definition,
		context = context,
		state = definition.initial,
		running = false,
		transitionCount = 0,
	}, StateMachine)
end

function StateMachine:_emit(previous, signal, data)
	if not self.context or not self.context.eventBus then
		return
	end

	self.context.eventBus:emit(EventTypes.WorkflowStateChanged, {
		workflowId = self.definition.id,
		state = self.state,
		previousState = previous,
		signal = signal,
		transitionCount = self.transitionCount,
		data = data,
	})
end

function StateMachine:start(reset)
	if self.running then
		return false
	end

	if reset ~= false then
		self.state = self.definition.initial
		self.transitionCount = 0
	end

	self.running = true
	self:_emit(nil, "start")
	return true
end

function StateMachine:send(signal, data)
	if not self.running then
		return false, "workflow is not running"
	end

	if type(signal) ~= "string" or signal == "" then
		return false, "workflow signal must be a non-empty string"
	end

	local node = self.definition.states[self.state]
	local nextState = node and node.on and node.on[signal]

	if not nextState then
		return false, ("no transition from %s on %s"):format(self.state, signal)
	end

	local previous = self.state
	self.state = nextState
	self.transitionCount += 1
	self:_emit(previous, signal, data)

	return true, nextState
end

function StateMachine:stop()
	if not self.running then
		return false
	end

	self.running = false
	self:_emit(self.state, "stop")
	return true
end

function StateMachine:current()
	return self.state
end

return StateMachine
