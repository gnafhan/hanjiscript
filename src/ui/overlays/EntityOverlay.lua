local require = ...

local Maid = require("utils.Maid")
local Theme = require("ui.Theme")
local Components = require("ui.Components")
local EventTypes = require("core.EventTypes")

local EntityOverlay = {}
EntityOverlay.__index = EntityOverlay

local function getParent()
	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and coreGui then return coreGui end
	local players = game:GetService("Players")
	return players.LocalPlayer and players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		or players.LocalPlayer and players.LocalPlayer:WaitForChild("PlayerGui")
end

local function hasTag(entity, expected)
	for _, tag in ipairs(entity.tags or {}) do
		if tag == expected then return true end
	end
	return false
end

local function isInteresting(entity)
	return hasTag(entity, "collectible-candidate")
		or hasTag(entity, "seller-candidate")
		or hasTag(entity, "interactive")
		or hasTag(entity, "asset-bearing")
end

local function markerKind(entity)
	if hasTag(entity, "seller-candidate") then return "SELLER", Theme.Dark.warn end
	if hasTag(entity, "collectible-candidate") then return "COLLECTIBLE", Theme.Dark.success end
	if hasTag(entity, "interactive") then return "INTERACTIVE", Theme.Dark.info end
	return "ASSET", Theme.Dark.accent
end

local function adorneeFor(entity)
	local instance = entity and entity.instance
	if not instance then return nil end
	if instance:IsA("BasePart") then return instance end
	if instance:IsA("Model") then
		if instance.PrimaryPart then return instance.PrimaryPart end
		return instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return instance:FindFirstAncestorWhichIsA("BasePart")
end

local function playerPosition()
	local ok, position = pcall(function()
		local player = game:GetService("Players").LocalPlayer
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return root and root.Position or nil
	end)
	return ok and position or nil
end

function EntityOverlay.new(context)
	return setmetatable({
		context = context,
		maid = Maid.new(),
		markerMaid = Maid.new(),
		folder = nil,
		running = false,
		enabled = false,
		dirty = true,
		elapsed = 0,
		markers = {},
		lastPosition = nil,
		maxMarkers = 60,
		radius = 140,
	}, EntityOverlay)
end

function EntityOverlay:_clearMarkers()
	self.markerMaid:Clean()
	self.markers = {}
	if self.folder then
		for _, child in ipairs(self.folder:GetChildren()) do child:Destroy() end
	end
end

function EntityOverlay:_createMarker(entity, distance)
	local adornee = adorneeFor(entity)
	if not adornee then return false end
	local kind, color = markerKind(entity)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Entity_" .. tostring(entity.id):gsub("[^%w_]", "_")
	billboard.Adornee = adornee
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = self.radius + 30
	billboard.Size = UDim2.fromOffset(176, 42)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	billboard.Parent = self.folder
	self.markers[entity.id] = billboard

	local panel = Components.create("Frame", {
		Name = "Panel",
		BackgroundColor3 = Theme.Dark.backgroundTop,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		parent = billboard,
	})
	Components.corner(panel, Theme.Radius.sm)
	Components.stroke(panel, color, 1, 0.18)
	Components.label(panel, {
		text = ("%s  %s"):format(kind, tostring(entity.name or "Entity")),
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = Theme.Dark.text,
		position = UDim2.fromOffset(8, 4),
		size = UDim2.new(1, -16, 0, 16),
		truncate = Enum.TextTruncate.AtEnd,
	})
	Components.label(panel, {
		text = ("%s  ·  %.0f studs"):format(entity.className or "Instance", distance or 0),
		font = Theme.Font.mono,
		textSize = Theme.Text.micro,
		color = Theme.Dark.textMuted,
		position = UDim2.fromOffset(8, 21),
		size = UDim2.new(1, -16, 0, 14),
		truncate = Enum.TextTruncate.AtEnd,
	})
	return true
end

function EntityOverlay:refresh()
	if not self.running or not self.enabled or not self.folder then
		self:_clearMarkers()
		return 0
	end
	local position = playerPosition()
	if not position then
		self:_clearMarkers()
		return 0
	end
	self:_clearMarkers()
	local nearby = self.context.world and self.context.world:withinRadius(position, self.radius) or {}
	local count = 0
	for _, item in ipairs(nearby) do
		if count >= self.maxMarkers then break end
		if isInteresting(item.entity) and self:_createMarker(item.entity, item.distance) then count += 1 end
	end
	self.lastPosition = position
	self.dirty = false
	return count
end

function EntityOverlay:setEnabled(enabled)
	self.enabled = enabled == true
	self.dirty = true
	if self.running then self:refresh() end
	return self.enabled
end

function EntityOverlay:start()
	if self.running then return false end
	self.running = true
	self.enabled = self.context.config:get("ui.overlayEnabled", true) == true
	self.maxMarkers = math.max(10, tonumber(self.context.config:get("ui.overlayMaxMarkers", 60)) or 60)
	self.radius = math.max(30, tonumber(self.context.config:get("ui.overlayRadius", 140)) or 140)
	local parent = getParent()
	if not parent then
		self.running = false
		return false, "unable to resolve overlay parent"
	end
	local existing = parent:FindFirstChild("HanjiScriptEntityOverlay")
	if existing then existing:Destroy() end
	self.folder = Instance.new("Folder")
	self.folder.Name = "HanjiScriptEntityOverlay"
	self.folder.Parent = parent
	self.maid:Add(self.context.eventBus:on(EventTypes.WorldEntityAdded, function() self.dirty = true end))
	self.maid:Add(self.context.eventBus:on(EventTypes.WorldEntityRemoved, function() self.dirty = true end))
	self.maid:Add(game:GetService("RunService").Heartbeat:Connect(function(delta)
		self.elapsed += delta
		if self.dirty then
			self.elapsed = 0
			self:refresh()
		elseif self.elapsed >= 0.75 then
			self.elapsed = 0
			local position = playerPosition()
			local moved = not self.lastPosition or not position
			if position and self.lastPosition then
				local ok, distance = pcall(function() return (position - self.lastPosition).Magnitude end)
				moved = ok and distance >= 8
			end
			if moved then self:refresh(position) end
		end
	end))
	self:refresh()
	return true
end

function EntityOverlay:stop()
	if not self.running then return false end
	self.running = false
	self.maid:Clean()
	self:_clearMarkers()
	if self.folder then self.folder:Destroy(); self.folder = nil end
	return true
end

function EntityOverlay:getSnapshot()
	local count = 0
	for _ in pairs(self.markers) do count += 1 end
	return { running = self.running, enabled = self.enabled, markerCount = count, maxMarkers = self.maxMarkers, radius = self.radius }
end

function EntityOverlay:destroy()
	self:stop()
	self.markerMaid:Destroy()
	self.maid:Destroy()
end

return EntityOverlay
