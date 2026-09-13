local Table = {}

function Table.count(tbl)
	local total = 0
	for _ in pairs(tbl) do
		total += 1
	end
	return total
end

function Table.shallowCopy(tbl)
	local out = {}
	for key, value in pairs(tbl) do
		out[key] = value
	end
	return out
end

function Table.merge(base, override)
	local out = Table.shallowCopy(base or {})

	for key, value in pairs(override or {}) do
		out[key] = value
	end

	return out
end

function Table.deepMerge(base, override)
	local out = {}

	for key, value in pairs(base or {}) do
		if type(value) == "table" then
			out[key] = Table.deepMerge(value, {})
		else
			out[key] = value
		end
	end

	for key, value in pairs(override or {}) do
		if type(value) == "table" and type(out[key]) == "table" then
			out[key] = Table.deepMerge(out[key], value)
		elseif type(value) == "table" then
			out[key] = Table.deepMerge({}, value)
		else
			out[key] = value
		end
	end

	return out
end

function Table.map(tbl, fn)
	local out = {}
	for key, value in pairs(tbl) do
		out[key] = fn(value, key)
	end
	return out
end

function Table.filter(tbl, predicate)
	local out = {}
	for key, value in pairs(tbl) do
		if predicate(value, key) then
			out[key] = value
		end
	end
	return out
end

function Table.keys(tbl)
	local out = {}
	for key in pairs(tbl) do
		table.insert(out, key)
	end
	return out
end

return Table
