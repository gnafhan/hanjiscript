local Id = {}
local counter = 0

function Id.next(prefix)
	counter += 1
	return string.format("%s_%d", prefix or "id", counter)
end

function Id.reset()
	counter = 0
end

return Id
