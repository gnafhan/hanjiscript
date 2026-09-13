local require = ...

local EventTypes = require("core.EventTypes")
local Signal = require("utils.Signal")

local NavigationTask = {}
NavigationTask.__index = NavigationTask

function NavigationTask.new(target)
	return setmetatable({
		target = target,
		status = "pending",
		result = nil,
		progress = Signal.new(),
		completed = Signal.new(),
	}, NavigationTask)
end

function NavigationTask:onProgress(callback)
	return self.progress:Connect(callback)
end

function NavigationTask:onComplete(callback)
	if self.result then
		callback(self.result)
		return nil
	end
	return self.completed:Connect(callback)
end

function NavigationTask:_finish(result)
	if self.result then
		return
	end
	self.result = result
	self.status = result.success and "completed" or (result.reason == "cancelled" and "cancelled" or "failed")
	self.completed:Fire(result)
	end

function NavigationTask:cancel()
	if self.result then
		return false
	end
	self:_finish({ success = false, reason = "cancelled", target = self.target })
	return true
end

function NavigationTask:getSnapshot()
	return {
		status = self.status,
		target = self.target,
		result = self.result,
	}
end

function NavigationTask:destroy()
	self.progress:Destroy()
	self.completed:Destroy()
	end

local Navigator = {}
Navigator.__index = Navigator

local function positionOf(entity)
	if not entity then
		return nil
	end
	if entity.position then
		return entity.position
	end
	local instance = entity.instance or entity
	local ok, position = pcall(function()
		if instance:IsA("BasePart") then
			return instance.Position
		elseif instance:IsA("Model") then
			return instance:GetPivot().Position
		end
		return nil
	end)
	return ok and position or nil
end

local function localRoot()
	local ok, root = pcall(function()
		local player = game:GetService("Players").LocalPlayer
		local character = player and player.Character
		return character and character:FindFirstChild("HumanoidRootPart")
	end)
	return ok and root or nil
end

function Navigator.new(context)
	return setmetatable({
		context = context,
		activeTask = nil,
		lastPath = nil,
	}, Navigator)
end

function Navigator:_resolveTarget(target)
	if not target then
		return nil
	end
	if target.instance or target.position then
		return target
	end

	local world = self.context and self.context.world
	if world and type(world.list) == "function" then
		for _, candidate in ipairs(world:list()) do
			if (target.id and candidate.id == target.id) or (target.path and candidate.path == target.path) then
				return candidate
			end
		end
	end
	return nil
end

function Navigator:estimate(target)
	local resolved = self:_resolveTarget(target)
	local root = localRoot()
	local targetPosition = positionOf(resolved or target)
	if not root or not targetPosition then
		return { available = false, reason = "player or target position unavailable" }
	end

	local ok, distance = pcall(function()
		return (root.Position - targetPosition).Magnitude
	end)
	if not ok then
		return { available = false, reason = "unable to calculate target distance" }
	end
	return { available = true, distance = distance, targetPosition = targetPosition }
end

function Navigator:goTo(target, options)
	options = options or {}
	if self.activeTask and not self.activeTask.result then
		self:cancel()
	end

	local resolved = self:_resolveTarget(target)
	local taskObject = NavigationTask.new(target)
	self.activeTask = taskObject
	self.context.eventBus:emit(EventTypes.NavigationStarted, { target = target, mode = "preview" })

	local estimate = self:estimate(resolved or target)
	if not estimate.available then
		taskObject:_finish({ success = false, reason = estimate.reason, target = target })
		self.context.eventBus:emit(EventTypes.NavigationCompleted, taskObject:getSnapshot().result)
		return taskObject
	end

	-- Universal mode computes and exposes a path but never teleports or fakes
	-- input. A game adapter can opt into execution later via an authoritative
	-- Navigator implementation.
	if options.execute == true then
		taskObject:_finish({
			success = false,
			reason = "execution requires an adapter navigator",
			target = target,
			distance = estimate.distance,
		})
		self.context.eventBus:emit(EventTypes.NavigationCompleted, taskObject:getSnapshot().result)
		return taskObject
	end

	local pathResult = {
		success = true,
		preview = true,
		target = target,
		distance = estimate.distance,
		pathLength = estimate.distance,
		waypoints = {},
	}

	local pathOk, path = pcall(function()
		local service = game:GetService("PathfindingService")
		local computed = service:CreatePath(options.agentParameters or {})
		computed:ComputeAsync(localRoot().Position, estimate.targetPosition)
		return computed
	end)

	if pathOk and path and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		pathResult.waypoints = waypoints
		local length = 0
		for index = 2, #waypoints do
			local segmentOk, segment = pcall(function()
				return (waypoints[index].Position - waypoints[index - 1].Position).Magnitude
			end)
			if segmentOk then length += segment end
		end
		pathResult.pathLength = length
	else
		pathResult.pathStatus = path and tostring(path.Status) or "error"
		pathResult.success = false
		pathResult.reason = "unreachable"
	end

	self.lastPath = pathResult
	self.context.eventBus:emit(EventTypes.NavigationPathComputed, {
		target = target,
		distance = pathResult.distance,
		pathLength = pathResult.pathLength,
		waypoints = #pathResult.waypoints,
		status = pathResult.pathStatus or "success",
	})
	taskObject:_finish(pathResult)
	self.context.eventBus:emit(EventTypes.NavigationCompleted, pathResult)
	return taskObject
end

function Navigator:cancel()
	if self.activeTask then
		local cancelled = self.activeTask:cancel()
		if cancelled then
			self.context.eventBus:emit(EventTypes.NavigationCompleted, self.activeTask.result)
		end
		return cancelled
	end
	return false
end

function Navigator:destroy()
	self:cancel()
	if self.activeTask then
		self.activeTask:destroy()
		self.activeTask = nil
	end
	self.lastPath = nil
end

Navigator.NavigationTask = NavigationTask
return Navigator
