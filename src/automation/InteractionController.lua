local require = ...

local InteractionController = {}
InteractionController.__index = InteractionController

local function resolveInstance(context, entity)
	if not entity then
		return nil
	end
	if entity.instance then
		return entity.instance
	end
	if typeof(entity) == "Instance" then
		return entity
	end

	local world = context and context.world
	if world and type(world.list) == "function" then
		for _, candidate in ipairs(world:list()) do
			if (entity.id and candidate.id == entity.id) or (entity.path and candidate.path == entity.path) then
				return candidate.instance
			end
		end
	end
	return nil
end

local function describeInstance(instance)
	local actions = {}
	if not instance then
		return actions
	end

	local function inspect(candidate)
		if candidate:IsA("ProximityPrompt") then
			table.insert(actions, {
				kind = "proximity_prompt",
				name = candidate.ActionText ~= "" and candidate.ActionText or "Trigger",
				object = candidate,
			})
		elseif candidate:IsA("ClickDetector") then
			table.insert(actions, { kind = "click_detector", name = "Click", object = candidate })
		elseif candidate:IsA("Tool") then
			table.insert(actions, { kind = "tool_activated", name = "Activate", object = candidate })
		end
	end

	inspect(instance)
	for _, child in ipairs(instance:GetDescendants()) do
		inspect(child)
	end
	return actions
end

function InteractionController.new(context)
	return setmetatable({ context = context, lastRequest = nil }, InteractionController)
end

function InteractionController:describe(entity)
	local instance = resolveInstance(self.context, entity)
	local actions = describeInstance(instance)
	return {
		available = #actions > 0,
		actions = actions,
		target = entity,
	}
end

function InteractionController:interact(entity, action)
	local adapter = self.context and self.context.adapter
	local instance = resolveInstance(self.context, entity)
	self.lastRequest = { target = entity, action = action, at = os.clock() }

	if not instance then
		return false, { code = "INTERACTION_TARGET_MISSING", reason = "target is no longer in WorldModel" }
	end

	if not adapter or type(adapter.interact) ~= "function" then
		return false, {
			code = "INTERACTION_ADAPTER_REQUIRED",
			reason = "Universal mode only describes interactions; an adapter must provide the authoritative action.",
		}
	end

	local ok, result = pcall(adapter.interact, adapter, instance, action, self.context)
	if not ok then
		return false, { code = "INTERACTION_ADAPTER_ERROR", reason = tostring(result) }
	end
	return result ~= false, result
end

function InteractionController:getSnapshot()
	return { lastRequest = self.lastRequest }
end

return InteractionController
