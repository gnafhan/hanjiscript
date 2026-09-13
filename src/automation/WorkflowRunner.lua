local require = ...

local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")
local StateMachine = require("automation.StateMachine")
local Planner = require("automation.Planner")
local Validator = require("automation.Validator")

local WorkflowRunner = {}
WorkflowRunner.__index = WorkflowRunner

local function copyPlan(plan)
	local out = {}
	for key, value in pairs(plan or {}) do
		if type(value) == "table" then
			local nested = {}
			for nestedKey, nestedValue in pairs(value) do
				nested[nestedKey] = nestedValue
			end
			out[key] = nested
		else
			out[key] = value
		end
	end
	return out
end

function WorkflowRunner.new(context, definition)
	local self = setmetatable({
		context = context,
		definition = definition,
		machine = StateMachine.new(definition, context),
		planner = Planner.new(context),
		validator = Validator.new(context),
		maid = Maid.new(),
		dryRun = true,
		target = nil,
		plan = nil,
		lastObservation = nil,
	}, WorkflowRunner)

	self.maid:Add(context.eventBus:on(EventTypes.WorkflowStateChanged, function()
		if self.machine.running then
			self:refreshPlan()
		end
	end))
	self.maid:Add(context.eventBus:on(EventTypes.SemanticAction, function(data)
		self:observe(EventTypes.SemanticAction, data)
	end))

	return self
end

function WorkflowRunner:refreshPlan()
	local plan = self.planner:propose(self.machine:current(), self.target)

	if plan.target then
		self.target = plan.target
	end

	self.plan = plan
	self.context.eventBus:emit(EventTypes.WorkflowPlanUpdated, copyPlan(plan))
	return plan
end

function WorkflowRunner:start()
	if not self.machine:start(true) then
		return false, "workflow is already running"
	end

	self.target = nil
	self:refreshPlan()
	self.context.logger:info("Workflow", "started (dry-run)", { workflowId = self.definition.id })
	return true
end

function WorkflowRunner:signal(signal, data)
	local plan = self.plan or self:refreshPlan()
	local payload = data or {}

	if payload.target == nil and plan then
		payload.target = plan.target
	end
	if payload.inventory == nil and plan then
		payload.inventory = plan.inventory
	end

	local valid, reason = self.validator:check(self.machine, signal, payload, plan)
	if not valid then
		return false, reason
	end

	local ok, nextState = self.machine:send(signal, payload)
	if not ok then
		return false, nextState
	end

	self.context.logger:info("Workflow", ("transition %s -> %s"):format(signal, nextState), {
		workflowId = self.definition.id,
		dryRun = self.dryRun,
	})
	return true, nextState
end

function WorkflowRunner:advance()
	local plan = self.plan or self:refreshPlan()
	if not plan or not plan.signal then
		return false, plan and plan.reason or "no workflow plan is available"
	end
	return self:signal(plan.signal)
end

function WorkflowRunner:observe(eventType, data)
	self.lastObservation = {
		type = eventType,
		at = os.clock(),
		data = data,
	}
	end

function WorkflowRunner:stop()
	if not self.machine:stop() then
		return false
	end
	self.plan = nil
	self.target = nil
	self.context.logger:info("Workflow", "stopped (dry-run)", { workflowId = self.definition.id })
	return true
end

function WorkflowRunner:getSnapshot()
	return {
		workflowId = self.definition.id,
		version = self.definition.version,
		running = self.machine.running,
		state = self.machine:current(),
		transitionCount = self.machine.transitionCount,
		dryRun = self.dryRun,
		plan = copyPlan(self.plan),
		lastObservation = self.lastObservation,
	}
end

function WorkflowRunner:destroy()
	self:stop()
	self.maid:Destroy()
	self.plan = nil
	self.target = nil
end

return WorkflowRunner
