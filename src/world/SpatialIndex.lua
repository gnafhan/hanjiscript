local SpatialIndex = {}
SpatialIndex.__index = SpatialIndex

local function distance(position, entity)
	if not position or not entity or not entity.position then
		return math.huge
	end

	local ok, value = pcall(function()
		return (entity.position - position).Magnitude
	end)
	return ok and value or math.huge
end

local function hasTag(entity, expected)
	for _, tag in ipairs(entity.tags or {}) do
		if tag == expected then
			return true
		end
	end
	return false
end

function SpatialIndex.new()
	return setmetatable({ entries = {} }, SpatialIndex)
end

function SpatialIndex:add(entity)
	if entity and entity.id then
		self.entries[entity.id] = entity
	end
end

function SpatialIndex:remove(entity)
	local id = type(entity) == "table" and entity.id or entity
	if id then
		self.entries[id] = nil
	end
end

function SpatialIndex:refresh(entity)
	self:remove(entity)
	self:add(entity)
end

function SpatialIndex:withinRadius(position, radius, options)
	options = options or {}
	local result = {}
	local maxDistance = radius or math.huge

	for _, entity in pairs(self.entries) do
		local matches = true
		if options.tag and not hasTag(entity, options.tag) then
			matches = false
		end
		if options.className and entity.className ~= options.className then
			matches = false
		end

		local entityDistance = distance(position, entity)
		if matches and entityDistance <= maxDistance then
			table.insert(result, { entity = entity, distance = entityDistance })
		end
	end

	table.sort(result, function(a, b)
		if a.distance == b.distance then
			return (a.entity.path or "") < (b.entity.path or "")
		end
		return a.distance < b.distance
	end)

	return result
end

function SpatialIndex:nearest(position, options)
	local result = self:withinRadius(position, math.huge, options)
	return result[1] and result[1].entity or nil, result[1] and result[1].distance or math.huge
end

function SpatialIndex:count()
	local count = 0
	for _ in pairs(self.entries) do
		count += 1
	end
	return count
end

function SpatialIndex:clear()
	self.entries = {}
end

return SpatialIndex
