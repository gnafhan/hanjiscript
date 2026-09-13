local require = ...

local TargetSelector = {}
TargetSelector.__index = TargetSelector

local KIND_TAGS = {
	collectible = { "collectible-candidate", "collectible" },
	seller = { "seller-candidate", "seller", "vendor" },
}

local function hasTag(entity, expected)
	for _, tag in ipairs(entity.tags or {}) do
		if tag == expected then
			return true
		end
	end
	return false
end

local function lower(value)
	return tostring(value or ""):lower()
end

local function matchesName(entity, kind)
	local name = lower(entity.name)
	local path = lower(entity.path)

	if kind == "collectible" then
		return name:find("item", 1, true) ~= nil
			or name:find("drop", 1, true) ~= nil
			or name:find("collect", 1, true) ~= nil
			or path:find("items", 1, true) ~= nil
	end

	if kind == "seller" then
		return name:find("sell", 1, true) ~= nil
			or name:find("shop", 1, true) ~= nil
			or name:find("merchant", 1, true) ~= nil
			or name:find("vendor", 1, true) ~= nil
			or path:find("seller", 1, true) ~= nil
	end

	return false
end

local function distance(entity, origin)
	if not origin or not entity.position then
		return math.huge
	end

	local ok, value = pcall(function()
		return (entity.position - origin).Magnitude
	end)

	return ok and value or math.huge
end

function TargetSelector.new(context)
	return setmetatable({ context = context }, TargetSelector)
end

function TargetSelector:find(kind, origin, options)
	options = options or {}
	local world = self.context and self.context.world
	if not world or type(world.list) ~= "function" then
		return {}
	end

	local tags = KIND_TAGS[kind] or { kind }
	local candidates = {}

	for _, entity in ipairs(world:list(options.query)) do
		local valid = false
		for _, tag in ipairs(tags) do
			if hasTag(entity, tag) then
				valid = true
				break
			end
		end

		if not valid then
			valid = matchesName(entity, kind)
		end

		-- A model or part is actionable; prompts, attachments and folders are
		-- useful for inspection but are not sensible movement targets.
		if valid and (entity.className == "Model" or entity.className == "Part"
			or entity.className == "MeshPart" or entity.className == "UnionOperation") then
			local item = {
				entity = entity,
				distance = distance(entity, origin),
			}
			item.score = item.distance == math.huge and 0 or 1 / math.max(item.distance, 1)
			table.insert(candidates, item)
		end
	end

	table.sort(candidates, function(a, b)
		if a.score == b.score then
			return (a.entity.path or "") < (b.entity.path or "")
		end
		return a.score > b.score
	end)

	local limit = options.limit or 20
	while #candidates > limit do
		table.remove(candidates)
	end

	return candidates
end

function TargetSelector:nearest(kind, origin, options)
	local results = self:find(kind, origin, options)
	return results[1] and results[1].entity or nil, results[1]
end

return TargetSelector
