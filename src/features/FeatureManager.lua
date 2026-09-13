local FeatureManager = {}
FeatureManager.__index = FeatureManager

function FeatureManager.new(context)
	return setmetatable({
		_context = context,
		_features = {},
		_enabled = {},
	}, FeatureManager)
end

function FeatureManager:register(feature)
	if type(feature) ~= "table" or not feature.id then
		error("FeatureManager:register expects a feature with an id", 2)
	end

	self._features[feature.id] = feature
	return feature
end

function FeatureManager:get(id)
	return self._features[id]
end

function FeatureManager:isEnabled(id)
	return self._enabled[id] == true
end

function FeatureManager:setEnabled(id, enabled)
	local feature = self._features[id]

	if not feature then
		return false, ("unknown feature: %s"):format(tostring(id))
	end

	if self._enabled[id] == enabled then
		return true
	end

	if enabled then
		if type(feature.init) == "function" and not feature._initialized then
			feature:init(self._context)
			feature._initialized = true
		end

		if type(feature.enable) == "function" then
			feature:enable()
		end
	else
		if type(feature.disable) == "function" then
			feature:disable()
		end
	end

	self._enabled[id] = enabled
	return true
end

function FeatureManager:list()
	local out = {}

	for id, feature in pairs(self._features) do
		table.insert(out, {
			id = id,
			feature = feature,
			enabled = self:isEnabled(id),
		})
	end

	table.sort(out, function(a, b)
		return a.id < b.id
	end)

	return out
end

return FeatureManager
