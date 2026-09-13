local require = ...
local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")
local SessionRecorder={}; SessionRecorder.__index=SessionRecorder
local TYPES={EventTypes.MovementSample,EventTypes.InteractionCompleted,EventTypes.WorldEntityAdded,EventTypes.WorldEntityRemoved}
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
		local ok,json=pcall(function() return game:GetService("HttpService"):JSONEncode({startedAt=self.startedAt,events=self.events}) end)
		if ok then pcall(writefile,"HanjiScript/session-"..os.time()..".json",json) end
	end
end
function SessionRecorder:pause() self.status="paused" end
function SessionRecorder:resume() self.status="running" end
return SessionRecorder
