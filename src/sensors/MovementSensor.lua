local require = ...

local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")

local MovementSensor = {}
MovementSensor.__index = MovementSensor

function MovementSensor.new(context)
	return setmetatable({
		context = context,
		maid = Maid.new(),
		running = false,
		root = nil,
	}, MovementSensor)
end

function MovementSensor:start()
	if self.running then
		return false
	end
	self.running = true

	local player = game:GetService("Players").LocalPlayer
	local function resolveRoot(character)
		self.root = character and character:FindFirstChild("HumanoidRootPart") or nil
	end
	resolveRoot(player and player.Character)

	if player then
		self.maid:Add(player.CharacterAdded:Connect(resolveRoot))
	end

	local interval = 1 / math.max(1, self.context.config:get("recorder.movementSampleRate", 5))
	local last = 0
	self.maid:Add(game:GetService("RunService").Heartbeat:Connect(function()
		if not self.running or not self.root or os.clock() - last < interval then
			return
		end
		last = os.clock()

		self.context.eventBus:emit(EventTypes.MovementSample, {
			position = self.root.Position,
			velocity = self.root.AssemblyLinearVelocity,
		})
	end))

	return true
end

function MovementSensor:stop()
	if not self.running then
		return false
	end
	self.running = false
	self.root = nil
	self.maid:Clean()
	return true
end

return MovementSensor
