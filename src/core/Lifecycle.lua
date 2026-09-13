local Lifecycle = {}
Lifecycle.__index = Lifecycle

Lifecycle.States = {
	Idle = "idle",
	Starting = "starting",
	Running = "running",
	Paused = "paused",
	Stopping = "stopping",
	Failed = "failed",
	Completed = "completed",
}

function Lifecycle.new(owner, eventBus)
	return setmetatable({
		owner = owner or "anonymous",
		eventBus = eventBus or nil,
		state = Lifecycle.States.Idle,
	}, Lifecycle)
end

function Lifecycle:is(state)
	return self.state == state
end

function Lifecycle:set(newState)
	if self.state == newState then
		return
	end

	local previous = self.state
	self.state = newState

	if self.eventBus then
		self.eventBus:emit("lifecycle.state_changed", {
			owner = self.owner,
			from = previous,
			to = newState,
		})
	end
end

return Lifecycle
