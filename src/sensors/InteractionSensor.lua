local require = ...

local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")

local InteractionSensor = {}
InteractionSensor.__index = InteractionSensor

local function fullName(instance)
	local ok, value = pcall(instance.GetFullName, instance)
	return ok and value or instance.Name
end

function InteractionSensor.new(context)
	return setmetatable({
		context = context,
		maid = Maid.new(),
		running = false,
	}, InteractionSensor)
end

function InteractionSensor:_emit(eventType, kind, instance)
	self.context.eventBus:emit(eventType, {
		kind = kind,
		target = fullName(instance.Parent or instance),
		instance = instance,
	})
end

function InteractionSensor:start()
	if self.running then
		return false
	end
	self.running = true

	local localPlayer = game:GetService("Players").LocalPlayer
	local function watch(instance)
		if instance:IsA("ProximityPrompt") then
			self.maid:Add(instance.PromptButtonHoldBegan:Connect(function()
				self:_emit(EventTypes.InteractionStarted, "proximity_prompt", instance)
			end))
			self.maid:Add(instance.Triggered:Connect(function(player)
				if player == localPlayer then
					self:_emit(EventTypes.InteractionCompleted, "proximity_prompt", instance)
				end
			end))
		elseif instance:IsA("ClickDetector") then
			self.maid:Add(instance.MouseClick:Connect(function(player)
				if player == localPlayer then
					self:_emit(EventTypes.InteractionCompleted, "click_detector", instance)
				end
			end))
		elseif instance:IsA("Tool") then
			self.maid:Add(instance.Activated:Connect(function()
				self:_emit(EventTypes.InteractionCompleted, "tool_activated", instance)
			end))
		end
	end

	local sources = {
		game:GetService("Workspace"),
		localPlayer and localPlayer:FindFirstChildOfClass("Backpack"),
	}
	for _, source in ipairs(sources) do
		if source then
			for _, instance in ipairs(source:GetDescendants()) do
				watch(instance)
			end
			self.maid:Add(source.DescendantAdded:Connect(watch))
		end
	end

	return true
end

function InteractionSensor:stop()
	if not self.running then
		return false
	end
	self.running = false
	self.maid:Clean()
	return true
end

return InteractionSensor
