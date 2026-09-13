local WorkflowInference = {}
local require = ...
local EventTypes = require("core.EventTypes")

local TRACKED = {
	["pickup-candidate"] = "pickup",
	["inventory-gained"] = "inventory-gained",
	["sell-candidate"] = "sell",
	["inventory-spent"] = "inventory-spent",
}

local function append(sequence, value)
	if sequence[#sequence] ~= value then table.insert(sequence, value) end
end

function WorkflowInference.infer(session)
	if type(session) ~= "table" or type(session.events) ~= "table" then
		return { id = "unknown", version = 1, confidence = 0, sequence = {}, counts = {} }
	end

	local sequence, counts, evidence = {}, {}, {}
	for _, event in ipairs(session.events) do
		if event.type == EventTypes.SemanticAction then
			local data = event.data or {}
			local normalized = TRACKED[data.kind]
			if normalized then
				append(sequence, normalized)
				counts[normalized] = (counts[normalized] or 0) + 1
				table.insert(evidence, {
					timestamp = event.timestamp,
					kind = data.kind,
					target = data.target,
				})
			end
		end
	end

	local hasPickup = (counts.pickup or 0) > 0
	local hasSell = (counts.sell or 0) > 0
	local inferredId = hasPickup and hasSell and "collect-and-sell" or "observed-session"
	local confidence = 0
	if hasPickup then confidence += 0.45 end
	if hasSell then confidence += 0.45 end
	if (counts["inventory-gained"] or 0) > 0 then confidence += 0.05 end
	if (counts["inventory-spent"] or 0) > 0 then confidence += 0.05 end

	return {
		id = inferredId,
		version = 1,
		confidence = math.min(1, confidence),
		sequence = sequence,
		counts = counts,
		evidence = evidence,
	}
end

return WorkflowInference
