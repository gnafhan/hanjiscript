local require = ...

local Maid = require("utils.Maid")
local Theme = require("ui.Theme")
local EventTypes = require("core.EventTypes")

local PathOverlay = {}
PathOverlay.__index = PathOverlay

local function resolveParent()
	local ok, workspaceService = pcall(function()
		return game:GetService("Workspace")
	end)
	return ok and workspaceService or nil
end

local function waypointPosition(waypoint)
	if not waypoint then
		return nil
	end
	local ok, position = pcall(function()
		return waypoint.Position
	end)
	return ok and position or nil
end

local function pointPart(name, position, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.42, 0.42, 0.42)
	part.Position = position
	part.Color = color
	part.Transparency = 0.08
	part.Parent = parent
	return part
end

local function segmentBeam(index, fromPart, toPart, parent, color)
	local from = Instance.new("Attachment")
	from.Name = "Start"
	from.Parent = fromPart

	local to = Instance.new("Attachment")
	to.Name = "End"
	to.Parent = toPart

	local beam = Instance.new("Beam")
	beam.Name = "Segment_" .. tostring(index)
	beam.Attachment0 = from
	beam.Attachment1 = to
	beam.FaceCamera = true
	beam.LightInfluence = 0
	beam.LightEmission = 1
	beam.Width0 = 0.16
	beam.Width1 = 0.16
	beam.Color = ColorSequence.new(color)
	beam.Transparency = NumberSequence.new(0.12)
	beam.Segments = 3
	beam.Parent = parent
	return beam
end

function PathOverlay.new(context)
	return setmetatable({
		context = context,
		maid = Maid.new(),
		pathMaid = Maid.new(),
		folder = nil,
		running = false,
		enabled = false,
		lastPath = nil,
		pointCount = 0,
		maxWaypoints = 128,
	}, PathOverlay)
end

function PathOverlay:_clear()
	self.pathMaid:Clean()
	self.lastPath = nil
	self.pointCount = 0
end

function PathOverlay:render(pathResult)
	self:_clear()
	if not self.running or not self.enabled or not self.folder then
		return 0
	end
	if not pathResult or pathResult.success ~= true then
		return 0
	end

	local points = {}
	for _, waypoint in ipairs(pathResult.waypoints or {}) do
		local position = waypointPosition(waypoint)
		if position then
			table.insert(points, position)
			if #points >= self.maxWaypoints then break end
		end
	end
	if #points == 0 then
		return 0
	end

	local pointParts = {}
	for index, position in ipairs(points) do
		local color = index == #points and Theme.Dark.success or Theme.Dark.accent
		local part = pointPart("Waypoint_" .. tostring(index), position, color, self.folder)
		table.insert(pointParts, part)
		self.pathMaid:Add(part)
	end
	for index = 2, #pointParts do
		local beam = segmentBeam(index - 1, pointParts[index - 1], pointParts[index], self.folder, Theme.Dark.accent)
		self.pathMaid:Add(beam)
	end

	self.lastPath = pathResult
	self.pointCount = #pointParts
	return self.pointCount
end

function PathOverlay:setEnabled(enabled)
	self.enabled = enabled == true
	if not self.enabled then
		self:_clear()
	elseif self.running and self.context.navigator then
		self:render(self.context.navigator.lastPath)
	end
	return self.enabled
end

function PathOverlay:start()
	if self.running then return false end
	self.running = true
	self.enabled = self.context.config:get("ui.pathOverlayEnabled", true) == true
	self.maxWaypoints = math.max(8, tonumber(self.context.config:get("ui.pathOverlayMaxWaypoints", 128)) or 128)

	local parent = resolveParent()
	if not parent then
		self.running = false
		return false, "unable to resolve path overlay parent"
	end
	local existing = parent:FindFirstChild("HanjiScriptPathOverlay")
	if existing then existing:Destroy() end
	self.folder = Instance.new("Folder")
	self.folder.Name = "HanjiScriptPathOverlay"
	self.folder.Parent = parent

	self.maid:Add(self.context.eventBus:on(EventTypes.NavigationPathComputed, function(event)
		if event and event.status == "success" and self.context.navigator then
			self:render(self.context.navigator.lastPath)
		else
			self:_clear()
		end
	end))
	self.maid:Add(self.context.eventBus:on(EventTypes.NavigationCompleted, function(event)
		if event and event.success == false then self:_clear() end
	end))

	if self.enabled and self.context.navigator then
		self:render(self.context.navigator.lastPath)
	end
	return true
end

function PathOverlay:stop()
	if not self.running then return false end
	self.running = false
	self.maid:Clean()
	self:_clear()
	if self.folder then self.folder:Destroy(); self.folder = nil end
	return true
end

function PathOverlay:getSnapshot()
	return {
		running = self.running,
		enabled = self.enabled,
		pointCount = self.pointCount,
		maxWaypoints = self.maxWaypoints,
		target = self.lastPath and self.lastPath.target or nil,
		pathLength = self.lastPath and self.lastPath.pathLength or nil,
	}
end

function PathOverlay:destroy()
	self:stop()
	self.pathMaid:Destroy()
	self.maid:Destroy()
end

return PathOverlay
