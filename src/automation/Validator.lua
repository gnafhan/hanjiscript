local Validator = {}
Validator.__index = Validator

function Validator.new(context)
	return setmetatable({ context = context }, Validator)
end

local function hasTarget(target)
	return type(target) == "table" and (target.id or target.path or target.instance) ~= nil
end

function Validator:check(machine, signal, data, plan)
	if not machine or not machine.running then
		return false, "workflow is not running"
	end

	if type(signal) ~= "string" or signal == "" then
		return false, "workflow signal must be a non-empty string"
	end

	local node = machine.definition.states[machine.state]
	if not node or not node.on or not node.on[signal] then
		return false, ("signal %s is not valid from %s"):format(signal, machine.state)
	end

	if signal == "target_found" or signal == "arrived" then
		local target = data and data.target or plan and plan.target
		if not hasTarget(target) then
			return false, "a classified target is required before this transition"
		end
	end

	if signal == "inventory_full" or signal == "inventory_available" then
		local inventory = data and data.inventory or plan and plan.inventory
		if not inventory or type(inventory.count) ~= "number" or type(inventory.capacity) ~= "number" then
			return false, "inventory snapshot is required before branching"
		end
		if signal == "inventory_full" and inventory.count < inventory.capacity then
			return false, "inventory is not full"
		end
		if signal == "inventory_available" and inventory.count >= inventory.capacity then
			return false, "inventory is full"
		end
	end

	return true
end

return Validator
