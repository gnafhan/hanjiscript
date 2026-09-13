local require = ...
local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")

local InventorySensor = {}; InventorySensor.__index = InventorySensor
local function snapshot(player)
	local out = {}
	local containers = { player:FindFirstChildOfClass("Backpack"), player.Character }
	for _, container in ipairs(containers) do
		if container then for _, item in ipairs(container:GetChildren()) do out[item.Name] = (out[item.Name] or 0) + 1 end end
	end
	return out
end
local function count(values) local n=0; for _,v in pairs(values) do n+=v end; return n end
function InventorySensor.new(context) return setmetatable({context=context,maid=Maid.new(),running=false,current={}},InventorySensor) end
function InventorySensor:start()
	if self.running then return end; self.running=true
	local player=game:GetService("Players").LocalPlayer; self.current=snapshot(player)
	local last=0
	self.maid:Add(game:GetService("RunService").Heartbeat:Connect(function()
		if not self.running or os.clock()-last<0.5 then return end; last=os.clock()
		local nextValue=snapshot(player); local before=count(self.current); local after=count(nextValue)
		if before~=after then self.context.eventBus:emit(EventTypes.InventoryChanged,{before=before,after=after,delta=after-before,items=nextValue}); self.current=nextValue end
	end))
end
function InventorySensor:stop() self.running=false; self.maid:Clean() end
return InventorySensor
