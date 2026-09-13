local require = ...
local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")
local SessionRecorder={}; SessionRecorder.__index=SessionRecorder
local TYPES={EventTypes.MovementSample,EventTypes.InteractionCompleted,EventTypes.WorldEntityAdded,EventTypes.WorldEntityRemoved,EventTypes.InventoryChanged,EventTypes.SemanticAction}
local function serializable(value, seen)
	local kind=typeof(value)
	if kind=="Vector3" then return {x=value.X,y=value.Y,z=value.Z} end
	if kind=="Instance" then return value:GetFullName() end
	if type(value)~="table" then return value end
	seen=seen or {}; if seen[value] then return nil end; seen[value]=true
	local out={}; for key,item in pairs(value) do out[tostring(key)]=serializable(item,seen) end; return out
end
function SessionRecorder.new(context) return setmetatable({context=context,maid=Maid.new(),status="idle",events={}},SessionRecorder) end
function SessionRecorder:start()
	if self.status=="running" then return end; self.status="running"; self.events={}; self.startedAt=os.clock()
	for _,kind in ipairs(TYPES) do self.maid:Add(self.context.eventBus:on(kind,function(data)
		if self.status=="running" then table.insert(self.events,{type=kind,timestamp=os.clock()-self.startedAt,data=data}) end
	end)) end
end
function SessionRecorder:stop()
	if self.status~="running" and self.status~="paused" then return end; self.status="stopped"; self.maid:Clean()
	if self.context.capabilities.persistence and type(writefile)=="function" then
		local ok,json=pcall(function() return game:GetService("HttpService"):JSONEncode(serializable({startedAt=self.startedAt,events=self.events})) end)
		if ok then
			if type(makefolder)=="function" then pcall(makefolder,"HanjiScript") end
			pcall(writefile,"HanjiScript/session-"..os.time()..".json",json)
		end
	end
end
function SessionRecorder:pause() self.status="paused" end
function SessionRecorder:resume() self.status="running" end
return SessionRecorder
