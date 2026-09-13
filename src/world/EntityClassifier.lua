local EntityClassifier = {}
function EntityClassifier.classify(instance, assets)
	local tags={}
	if instance:IsA("Model") then table.insert(tags,"model") end
	if instance:IsA("BasePart") then table.insert(tags,"geometry") end
	if instance:IsA("ProximityPrompt") or instance:IsA("ClickDetector") then table.insert(tags,"interactive") end
	if next(assets) then table.insert(tags,"asset-bearing") end
	local name=instance.Name:lower()
	if name:find("item") or name:find("drop") or name:find("collect") then table.insert(tags,"collectible-candidate") end
	if name:find("sell") or name:find("shop") or name:find("merchant") or name:find("vendor") then table.insert(tags,"seller-candidate") end
	local ok, collectionService = pcall(game.GetService, game, "CollectionService")
	if ok and collectionService then
		local tagOk, instanceTags = pcall(collectionService.GetTags, collectionService, instance)
		if tagOk then
			for _, tag in ipairs(instanceTags) do
				local normalized = tostring(tag):lower()
				local duplicate = false
				for _, existing in ipairs(tags) do if existing == normalized then duplicate = true break end end
				if not duplicate then table.insert(tags, normalized) end
			end
		end
	end
	-- Keep adapter-agnostic semantic aliases available to selectors and the
	-- overlay even when a place uses the shorter CollectionService tag names.
	local function addAlias(alias)
		for _, existing in ipairs(tags) do
			if existing == alias then return end
		end
		table.insert(tags, alias)
	end
	local function has(expected)
		for _, existing in ipairs(tags) do
			if existing == expected then return true end
		end
		return false
	end
	if has("collectible") or has("pickup") or has("item") then addAlias("collectible-candidate") end
	if has("seller") or has("vendor") or has("merchant") or has("shop") then addAlias("seller-candidate") end
	return tags
end
return EntityClassifier
