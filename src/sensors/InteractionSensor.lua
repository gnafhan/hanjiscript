local require = ...
local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")
local InteractionSensor = {}; InteractionSensor.__index=InteractionSensor
function InteractionSensor.new(context) return setmetatable({context=context,maid=Maid.new()},InteractionSensor) end
function InteractionSensor:start()
	local function watch(instance)
		if instance:IsA("ProximityPrompt") then self.maid:Add(instance.Triggered:Connect(function(player)
			if player==game:GetService("Players").LocalPlayer then self.context.eventBus:emit(EventTypes.InteractionCompleted,{kind="proximity_prompt",target=instance.Parent and instance.Parent:GetFullName()}) end
		end)) end
	end
	for _,v in ipairs(game:GetService("Workspace"):GetDescendants()) do watch(v) end
	self.maid:Add(game:GetService("Workspace").DescendantAdded:Connect(watch))
end
function InteractionSensor:stop() self.maid:Clean() end
return InteractionSensor
