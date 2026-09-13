local require = ...
local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")
local MovementSensor = {}; MovementSensor.__index=MovementSensor
function MovementSensor.new(context) return setmetatable({context=context,maid=Maid.new(),running=false},MovementSensor) end
function MovementSensor:start()
	if self.running then return end; self.running=true
	local player=game:GetService("Players").LocalPlayer; local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local interval=1/math.max(1,self.context.config:get("recorder.movementSampleRate",5)); local last=0
	self.maid:Add(game:GetService("RunService").Heartbeat:Connect(function()
		if not self.running or not root or os.clock()-last<interval then return end; last=os.clock()
		self.context.eventBus:emit(EventTypes.MovementSample,{position=root.Position,velocity=root.AssemblyLinearVelocity})
	end))
end
function MovementSensor:stop() self.running=false; self.maid:Clean() end
return MovementSensor
