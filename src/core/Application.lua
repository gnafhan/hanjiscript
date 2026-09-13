local require = ...

local Context = require("core.Context")
local EventBus = require("core.EventBus")
local CommandBus = require("core.CommandBus")
local Lifecycle = require("core.Lifecycle")
local EventTypes = require("core.EventTypes")

local Config = require("config.Config")
local Logger = require("telemetry.Logger")
local Metrics = require("telemetry.Metrics")

local AdapterRegistry = require("registry.AdapterRegistry")
local UniversalAdapter = require("adapters.UniversalAdapter")
local FeatureManager = require("features.FeatureManager")

local EnvironmentDetector = require("runtime.EnvironmentDetector")
local ExperienceDetector = require("runtime.ExperienceDetector")
local CapabilityDetector = require("runtime.CapabilityDetector")

local AppUI = require("ui.AppUI")
local WorldModel = require("world.WorldModel")
local MovementSensor = require("sensors.MovementSensor")
local InteractionSensor = require("sensors.InteractionSensor")
local SessionRecorder = require("recorder.SessionRecorder")

local Application = {}
Application.__index = Application

function Application.new(options)
	return setmetatable({
		_options = options or {},
		_startedAt = nil,
		_destroyed = false,
	}, Application)
end

function Application:_registerCommands()
	local context = self.context
	local commandBus = context.commandBus
	local uiState = context.uiState
	local logger = context.logger

	local function setRecorderStatus(status)
		uiState:set("recorderStatus", status)
		context.eventBus:emit(EventTypes.RecorderStateChanged, { status = status })
		logger:info("Recorder", "state changed", { status = status })
	end

	commandBus:register("ui.toggle", function()
		uiState:set("visible", not uiState:get("visible", true))
	end)

	commandBus:register("ui.show", function()
		uiState:set("visible", true)
	end)

	commandBus:register("ui.hide", function()
		uiState:set("visible", false)
	end)

	commandBus:register("recorder.start", function()
		context.recorder:start()
		context.movementSensor:start()
		setRecorderStatus("running")
	end)

	commandBus:register("recorder.pause", function()
		context.recorder:pause()
		setRecorderStatus("paused")
	end)

	commandBus:register("recorder.resume", function()
		context.recorder:resume()
		setRecorderStatus("running")
	end)

	commandBus:register("recorder.stop", function()
		context.movementSensor:stop()
		context.recorder:stop()
		setRecorderStatus("stopped")
	end)

	commandBus:register("automation.start", function()
		uiState:set("automationStatus", "running")
		context.eventBus:emit(EventTypes.AutomationStateChanged, { status = "running" })
		logger:info("Automation", "started")
	end)

	commandBus:register("automation.stop", function()
		uiState:set("automationStatus", "idle")
		context.eventBus:emit(EventTypes.AutomationStateChanged, { status = "idle" })
		logger:info("Automation", "stopped")
	end)

	commandBus:register("app.shutdown", function()
		self:destroy()
	end)
end

function Application:init()
	local config = Config.load(self._options.config)

	local logger = Logger.new({ minLevel = config:get("telemetry.logLevel", "info") })
	local eventBus = EventBus.new()
	local commandBus = CommandBus.new()
	local metrics = Metrics.new()

	local context = Context.new({
		config = config,
		logger = logger,
		eventBus = eventBus,
		commandBus = commandBus,
		metrics = metrics,
	})

	context.runtime = EnvironmentDetector.detect()
	context.experience = ExperienceDetector.detect()
	context.capabilities = CapabilityDetector.detect()

	logger:info("Application", "runtime detected", context.runtime)
	eventBus:emit(EventTypes.RuntimeDetected, context.runtime)

	logger:info("Application", "experience detected", context.experience)
	eventBus:emit(EventTypes.ExperienceDetected, context.experience)

	local registry = AdapterRegistry.new()
	registry:register(UniversalAdapter)
	registry:setFallback(UniversalAdapter)
	context.adapterRegistry = registry

	local adapter = registry:resolve(context)
	context.adapter = adapter

	if adapter and type(adapter.init) == "function" then
		adapter:init(context)
	end

	logger:info("Application", "adapter resolved", { adapter = adapter and adapter.id or "none" })
	eventBus:emit(EventTypes.AdapterResolved, { adapter = adapter and adapter.id or "none" })

	context.features = FeatureManager.new(context)
	context.world = WorldModel.new(context)
	context.world:start()
	context.movementSensor = MovementSensor.new(context)
	context.interactionSensor = InteractionSensor.new(context)
	context.interactionSensor:start()
	context.recorder = SessionRecorder.new(context)

	local ui = AppUI.new(context)
	context.ui = ui
	context.uiState = ui:getState()

	self.context = context
	self.lifecycle = Lifecycle.new("Application", eventBus)

	self:_registerCommands()

	return self
end

function Application:start()
	if not self.context then
		self:init()
	end

	self.lifecycle:set(Lifecycle.States.Starting)
	self._startedAt = os.clock()

	local context = self.context

	if context.adapter and type(context.adapter.start) == "function" then
		context.adapter:start()
	end

	if context.ui and type(context.ui.mount) == "function" then
		context.ui:mount()
	end

	context.metrics:set("startedAt", self._startedAt)
	self.lifecycle:set(Lifecycle.States.Running)
	context.eventBus:emit(EventTypes.ApplicationStarted, { at = self._startedAt })
	context.logger:info("Application", "started", { version = context.config:get("frameworkVersion") })

	return self
end

function Application:stop()
	if not self.context then
		return self
	end

	self.lifecycle:set(Lifecycle.States.Stopping)

	local context = self.context

	if context.ui and type(context.ui.unmount) == "function" then
		context.ui:unmount()
	end

	if context.adapter and type(context.adapter.stop) == "function" then
		context.adapter:stop()
	end
	if context.movementSensor then context.movementSensor:stop() end
	if context.interactionSensor then context.interactionSensor:stop() end
	if context.recorder then context.recorder:stop() end
	if context.world then context.world:destroy() end

	self.lifecycle:set(Lifecycle.States.Completed)
	context.eventBus:emit(EventTypes.ApplicationStopped, { at = os.clock() })
	context.logger:info("Application", "stopped")

	return self
end

function Application:getState()
	return self.context and self.lifecycle and self.lifecycle.state or "idle"
end

function Application:destroy()
	if self._destroyed then
		return
	end

	self._destroyed = true
	self:stop()

	local context = self.context

	if context then
		if context.logger then
			context.logger:destroy()
		end

		if context.eventBus then
			context.eventBus:destroy()
		end
	end
end

return Application
