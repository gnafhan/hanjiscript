local CapabilityDetector = {}

local function has(name)
	return type(_G[name]) == "function" or type(rawget(_G, name)) == "function"
end

function CapabilityDetector.detect()
	return {
		pathfinding = game ~= nil and game:FindService("PathfindingService") ~= nil,
		recording = true,
		persistence = has("writefile") or has("appendfile"),
		http = type(http_request) == "function" or type(request) == "function" or (syn ~= nil),
		loadstring = type(loadstring) == "function" or type(load) == "function",
		clipboard = has("setclipboard"),
		notifications = game ~= nil,
	}
end

return CapabilityDetector
