local ExperienceDetector = {}

local function safe(fn, default)
	local ok, value = pcall(fn)

	if ok and value ~= nil then
		return value
	end

	return default
end

function ExperienceDetector.detect()
	local experience = {
		gameId = safe(function()
			return game.GameId
		end, 0),
		placeId = safe(function()
			return game.PlaceId
		end, 0),
		jobId = safe(function()
			return game.JobId
		end, ""),
		name = safe(function()
			return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
		end, "Unknown Experience"),
	}

	if experience.placeId == 0 then
		experience.placeType = "test"
	elseif experience.gameId == 0 then
		experience.placeType = "place"
	else
		experience.placeType = "game"
	end

	return experience
end

return ExperienceDetector
