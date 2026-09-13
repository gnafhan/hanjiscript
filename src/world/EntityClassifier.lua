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
	return tags
end
return EntityClassifier
