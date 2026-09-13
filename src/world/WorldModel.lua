local require = ...
local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")
local EntityClassifier = require("world.EntityClassifier")

local WorldModel = {}
WorldModel.__index = WorldModel

local function entity(instance)
	local position
	if instance:IsA("BasePart") then position = instance.Position
	elseif instance:IsA("Model") then position = instance:GetPivot().Position end
	local assets={}
	if instance:IsA("MeshPart") then assets.mesh=instance.MeshId; assets.texture=instance.TextureID
	elseif instance:IsA("Decal") or instance:IsA("Texture") then assets.texture=instance.Texture
	elseif instance:IsA("Sound") then assets.sound=instance.SoundId
	elseif instance:IsA("Animation") then assets.animation=instance.AnimationId end
	return { id = instance:GetDebugId(), instance = instance, name = instance.Name, className = instance.ClassName,
		path = instance:GetFullName(), position = position, attributes = instance:GetAttributes(), assets = assets, tags = EntityClassifier.classify(instance, assets) }
end

function WorldModel.new(context)
	return setmetatable({ context=context, entities={}, maid=Maid.new() }, WorldModel)
end
function WorldModel:add(instance)
	if self.entities[instance] then return end
	local value = entity(instance); self.entities[instance] = value
	self.context.eventBus:emit(EventTypes.WorldEntityAdded, value)
end
function WorldModel:remove(instance)
	local value=self.entities[instance]; if not value then return end
	self.entities[instance]=nil; self.context.eventBus:emit(EventTypes.WorldEntityRemoved, value)
end
function WorldModel:list(query)
	local result={}; query=(query or ""):lower()
	for _, value in pairs(self.entities) do
		if query=="" or value.name:lower():find(query,1,true) or value.className:lower():find(query,1,true) then table.insert(result,value) end
	end
	table.sort(result,function(a,b) return a.path<b.path end); return result
end
function WorldModel:tree(limit)
	local result, count = {}, 0
	local function visit(instance, depth)
		if count >= (limit or 500) then return end
		local value=self.entities[instance] or entity(instance); value.depth=depth; value.hasChildren=#instance:GetChildren()>0
		table.insert(result,value); count+=1
		for _,child in ipairs(instance:GetChildren()) do visit(child,depth+1); if count >= (limit or 500) then break end end
	end
	for _,root in ipairs(game:GetService("Workspace"):GetChildren()) do visit(root,0); if count >= (limit or 500) then break end end
	return result
end
function WorldModel:start()
	local workspaceService=game:GetService("Workspace")
	for _, instance in ipairs(workspaceService:GetDescendants()) do self:add(instance) end
	self.maid:Add(workspaceService.DescendantAdded:Connect(function(instance) self:add(instance) end))
	self.maid:Add(workspaceService.DescendantRemoving:Connect(function(instance) self:remove(instance) end))
end
function WorldModel:stop() self.maid:Clean() end
function WorldModel:destroy() self:stop(); self.entities={} end
return WorldModel
