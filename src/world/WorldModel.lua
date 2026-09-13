local require = ...

local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")
local EntityClassifier = require("world.EntityClassifier")
local AssetResolver = require("world.AssetResolver")
local SpatialIndex = require("world.SpatialIndex")

local WorldModel = {}
WorldModel.__index = WorldModel

local function entity(instance)
	local position
	if instance:IsA("BasePart") then
		position = instance.Position
	elseif instance:IsA("Model") then
		local ok, pivot = pcall(instance.GetPivot, instance)
		position = ok and pivot.Position or nil
	end

	local assets, assetRefs = AssetResolver.resolve(instance)
	return {
		id = instance:GetDebugId(),
		instance = instance,
		name = instance.Name,
		className = instance.ClassName,
		path = instance:GetFullName(),
		position = position,
		attributes = instance:GetAttributes(),
		assets = assets,
		assetRefs = assetRefs,
		tags = EntityClassifier.classify(instance, assets),
	}
end

function WorldModel.new(context)
	return setmetatable({
		context = context,
		entities = {},
		spatial = SpatialIndex.new(),
		maid = Maid.new(),
		running = false,
	}, WorldModel)
end

function WorldModel:add(instance)
	if self.entities[instance] then
		return self.entities[instance]
	end

	local value = entity(instance)
	self.entities[instance] = value
	self.spatial:add(value)
	self.context.eventBus:emit(EventTypes.WorldEntityAdded, value)
	return value
end

function WorldModel:remove(instance)
	local value = self.entities[instance]
	if not value then
		return
	end

	self.entities[instance] = nil
	self.spatial:remove(value)
	self.context.eventBus:emit(EventTypes.WorldEntityRemoved, value)
end

function WorldModel:list(query)
	local result = {}
	query = (query or ""):lower()

	for _, value in pairs(self.entities) do
		if query == "" or value.name:lower():find(query, 1, true)
			or value.className:lower():find(query, 1, true)
			or value.path:lower():find(query, 1, true) then
			table.insert(result, value)
		end
	end

	table.sort(result, function(a, b)
		return a.path < b.path
	end)
	return result
end

function WorldModel:tree(limit)
	local result, count = {}, 0
	local maxEntries = limit or 500

	local function visit(instance, depth)
		if count >= maxEntries then
			return
		end

		local value = self.entities[instance] or entity(instance)
		local node = {}
		for key, item in pairs(value) do
			node[key] = item
		end
		node.depth = depth
		node.hasChildren = #instance:GetChildren() > 0
		table.insert(result, node)
		count += 1

		for _, child in ipairs(instance:GetChildren()) do
			visit(child, depth + 1)
			if count >= maxEntries then
				break
			end
		end
	end

	for _, root in ipairs(game:GetService("Workspace"):GetChildren()) do
		visit(root, 0)
		if count >= maxEntries then
			break
		end
	end

	return result
end

function WorldModel:nearest(position, options)
	return self.spatial:nearest(position, options)
end

function WorldModel:withinRadius(position, radius, options)
	return self.spatial:withinRadius(position, radius, options)
end

function WorldModel:count()
	local count = 0
	for _ in pairs(self.entities) do
		count += 1
	end
	return count
end

function WorldModel:start()
	if self.running then
		return false
	end
	self.running = true

	local workspaceService = game:GetService("Workspace")
	for _, instance in ipairs(workspaceService:GetDescendants()) do
		self:add(instance)
	end

	self.maid:Add(workspaceService.DescendantAdded:Connect(function(instance)
		self:add(instance)
	end))
	self.maid:Add(workspaceService.DescendantRemoving:Connect(function(instance)
		self:remove(instance)
	end))
	return true
end

function WorldModel:stop()
	if not self.running then
		return false
	end
	self.running = false
	self.maid:Clean()
	return true
end

function WorldModel:destroy()
	self:stop()
	self.entities = {}
	self.spatial:clear()
end

return WorldModel
