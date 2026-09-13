local AdapterRegistry = {}
AdapterRegistry.__index = AdapterRegistry

function AdapterRegistry.new()
	return setmetatable({
		_adapters = {},
		_fallback = nil,
	}, AdapterRegistry)
end

function AdapterRegistry:register(adapter)
	if type(adapter) ~= "table" or not adapter.id then
		error("AdapterRegistry:register expects an adapter with an id", 2)
	end

	self._adapters[adapter.id] = adapter
	return adapter
end

function AdapterRegistry:setFallback(adapter)
	self._fallback = adapter
	return adapter
end

function AdapterRegistry:get(id)
	return self._adapters[id]
end

function AdapterRegistry:all()
	local out = {}

	for _, adapter in pairs(self._adapters) do
		table.insert(out, adapter)
	end

	table.sort(out, function(a, b)
		return a.id < b.id
	end)

	return out
end

function AdapterRegistry:resolve(context)
	local matches = {}

	for _, adapter in pairs(self._adapters) do
		if type(adapter.supports) == "function" then
			local ok, supported = pcall(adapter.supports, adapter, context)

			if ok and supported then
				table.insert(matches, adapter)
			end
		end
	end

	if #matches > 0 then
		return matches[1], matches
	end

	return self._fallback, matches
end

return AdapterRegistry
