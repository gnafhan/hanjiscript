local require = ...

local Id = require("utils.Id")

local EventSchema = {}
EventSchema.version = 1

function EventSchema.session(context)
	local experience = context.experience or {}
	local adapter = context.adapter
	local config = context.config

	return {
		id = Id.next("session"),
		schemaVersion = EventSchema.version,
		frameworkVersion = config and config:get("frameworkVersion", "0.1.0") or "0.1.0",
		experienceId = experience.gameId,
		placeId = experience.placeId,
		adapterId = adapter and adapter.id or "none",
		startedAt = os.time(),
	}
end

function EventSchema.event(eventType, source, sessionId, timestamp, data)
	return {
		id = Id.next("evt"),
		timestamp = timestamp,
		type = eventType,
		source = source or "EventBus",
		sessionId = sessionId,
		data = data,
	}
end

return EventSchema
