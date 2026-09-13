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

function Validator:validateEvidence(action, evidence)
	evidence = evidence or {}
	if action == "pickup" then
		if evidence.entityRemoved ~= true then
			return false, "pickup has no confirmed world entity removal"
		end
		if type(evidence.inventoryDelta) ~= "number" or evidence.inventoryDelta <= 0 then
			return false, "pickup has no positive inventory delta"
		end
	elseif action == "sell" then
		if type(evidence.inventoryDelta) ~= "number" or evidence.inventoryDelta >= 0 then
			return false, "sale has no negative inventory delta"
		end
		if type(evidence.currencyDelta) ~= "number" or evidence.currencyDelta <= 0 then
			return false, "sale has no positive currency delta"
		end
	else
		return false, "unknown evidence action"
	end

	return true, evidence
end

return Validator
