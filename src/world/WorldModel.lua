local require = ...

local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")
local EntityClassifier = require("world.EntityClassifier")
local AssetResolver = require("world.AssetResolver")
local SpatialIndex = require("world.SpatialIndex")

local WorldModel = {}
WorldModel.__index = WorldModel

local function isSystemInstance(instance)
	local current = instance
	while current do
		local ok, value = pcall(current.GetAttribute, current, "HanjiScriptSystem")
		if ok and value then
			return true
		end
		current = current.Parent
	end
	return false
end

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
	if isSystemInstance(instance) then
		return nil
	end
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

function WorldModel:refresh(instance)
	if isSystemInstance(instance) then
		self:remove(instance)
		return nil
	end
	local workspaceService = game:GetService("Workspace")
	local ok, isLive = pcall(function()
		return instance and instance:IsDescendantOf(workspaceService)
	end)
	if not ok or not isLive then
		self:remove(instance)
		return nil
	end
	local previous = self.entities[instance]
	if not previous then
		return self:add(instance)
	end

	local value = entity(instance)
	self.entities[instance] = value
	self.spatial:refresh(value)
	self.context.eventBus:emit(EventTypes.WorldEntityUpdated, {
		entity = value,
		previous = previous,
	})
	return value
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
		if isSystemInstance(instance) then
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

	-- CollectionService tags can be applied after spawn. Listen only to the
	-- semantic tags used by the universal classifier so recon stays current
	-- without attaching one AttributeChanged connection per instance.
	local ok, collectionService = pcall(game.GetService, game, "CollectionService")
	if ok and collectionService then
		for _, tag in ipairs({ "Collectible", "Seller", "Vendor", "Merchant", "Shop", "Pickup", "Item" }) do
			local addedOk, addedSignal = pcall(collectionService.GetInstanceAddedSignal, collectionService, tag)
			if addedOk and addedSignal then
				self.maid:Add(addedSignal:Connect(function(instance) self:refresh(instance) end))
			end
			local removedOk, removedSignal = pcall(collectionService.GetInstanceRemovedSignal, collectionService, tag)
			if removedOk and removedSignal then
				self.maid:Add(removedSignal:Connect(function(instance) self:refresh(instance) end))
			end
		end
	end
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
