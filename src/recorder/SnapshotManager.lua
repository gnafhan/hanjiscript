local require = ...

local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")

local SnapshotManager = {}
SnapshotManager.__index = SnapshotManager

local function playerPosition()
	local ok, position = pcall(function()
		local player = game:GetService("Players").LocalPlayer
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return root and root.Position or nil
	end)
	return ok and position or nil
end

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end

function SnapshotManager.new(context)
	return setmetatable({
		context = context,
		maid = Maid.new(),
		running = false,
		startedAt = nil,
		lastAt = 0,
		interval = 5,
		snapshots = {},
	}, SnapshotManager)
end

function SnapshotManager:capture()
	local now = os.clock()
	local inventorySensor = self.context.inventorySensor
	local workflowRunner = self.context.workflowRunner
	local snapshot = {
		timestamp = self.startedAt and now - self.startedAt or 0,
		player = { position = playerPosition() },
		world = {
			entityCount = self.context.world and self.context.world:count() or 0,
			spatialCount = self.context.world and self.context.world.spatial:count() or 0,
		},
		inventory = {
			count = inventorySensor and inventorySensor:getCount() or 0,
			items = inventorySensor and inventorySensor:getSnapshot() or {},
		},
		workflow = workflowRunner and workflowRunner:getSnapshot() or nil,
	}
	table.insert(self.snapshots, snapshot)
	self.context.eventBus:emit(EventTypes.SnapshotCaptured, copy(snapshot))
	return snapshot
end

function SnapshotManager:start()
	if self.running then return false end
	self.running = true
	self.startedAt = os.clock()
	self.lastAt = 0
	self.interval = math.max(1, self.context.config:get("recorder.snapshotInterval", 5))
	self.snapshots = {}
	self:capture()
	self.maid:Add(game:GetService("RunService").Heartbeat:Connect(function()
		if not self.running or os.clock() - self.lastAt < self.interval then return end
		self.lastAt = os.clock()
		self:capture()
	end))
	return true
end

function SnapshotManager:stop()
	if not self.running then return false end
	self:capture()
	self.running = false
	self.maid:Clean()
	return true
end

function SnapshotManager:getSnapshots()
	return copy(self.snapshots)
end

return SnapshotManager
