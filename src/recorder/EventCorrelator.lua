local require = ...
local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")

local EventCorrelator = {}
EventCorrelator.__index = EventCorrelator

function EventCorrelator.new(context)
	return setmetatable({ context = context, maid = Maid.new(), lastInteraction = nil }, EventCorrelator)
end

function EventCorrelator:start()
	self.maid:Add(self.context.eventBus:on(EventTypes.InteractionCompleted, function(data)
		self.lastInteraction = { at = os.clock(), data = data }
		self.context.eventBus:emit(EventTypes.SemanticAction, { kind = "interaction-completed", target = data.target })
	end))
	self.maid:Add(self.context.eventBus:on(EventTypes.WorldEntityRemoved, function(entity)
		local pending = self.lastInteraction
		if pending and os.clock() - pending.at <= 2.5 then
			self.context.eventBus:emit(EventTypes.SemanticAction, {
				kind = "pickup-candidate", target = entity.path, interaction = pending.data.target,
			})
			self.lastInteraction = nil
		end
	end))
	self.maid:Add(self.context.eventBus:on(EventTypes.InventoryChanged, function(data)
		if data.delta and data.delta > 0 then
			self.context.eventBus:emit(EventTypes.SemanticAction, { kind = "inventory-gained", delta = data.delta })
		elseif data.delta and data.delta < 0 then
			self.context.eventBus:emit(EventTypes.SemanticAction, { kind = "inventory-spent", delta = data.delta })
		end
	end))
end

function EventCorrelator:stop() self.maid:Clean() end
return EventCorrelator
