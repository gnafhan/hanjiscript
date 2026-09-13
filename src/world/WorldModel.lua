local require = ...
local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")

local WorldModel = {}
WorldModel.__index = WorldModel

local function entity(instance)
	local position
	if instance:IsA("BasePart") then position = instance.Position
	elseif instance:IsA("Model") then position = instance:GetPivot().Position end
	return { id = instance:GetDebugId(), instance = instance, name = instance.Name, className = instance.ClassName,
		path = instance:GetFullName(), position = position, attributes = instance:GetAttributes() }
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
function WorldModel:start()
	local workspaceService=game:GetService("Workspace")
	for _, instance in ipairs(workspaceService:GetDescendants()) do self:add(instance) end
	self.maid:Add(workspaceService.DescendantAdded:Connect(function(instance) self:add(instance) end))
	self.maid:Add(workspaceService.DescendantRemoving:Connect(function(instance) self:remove(instance) end))
end
function WorldModel:stop() self.maid:Clean() end
function WorldModel:destroy() self:stop(); self.entities={} end
return WorldModel
