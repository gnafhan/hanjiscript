local AssetResolver = {}

local function add(refs, kind, value)
	if value == nil or value == "" then
		return
	end

	local text = tostring(value)
	if text == "" then
		return
	end

	table.insert(refs, { kind = kind, id = text })
end

function AssetResolver.resolve(instance)
	local refs = {}
	local values = {}

	if instance:IsA("MeshPart") then
		values.mesh = instance.MeshId
		values.texture = instance.TextureID
		add(refs, "mesh", instance.MeshId)
		add(refs, "texture", instance.TextureID)
	elseif instance:IsA("SpecialMesh") then
		values.mesh = instance.MeshId
		values.texture = instance.TextureId
		add(refs, "mesh", instance.MeshId)
		add(refs, "texture", instance.TextureId)
	elseif instance:IsA("Decal") or instance:IsA("Texture") then
		values.texture = instance.Texture
		add(refs, "texture", instance.Texture)
	elseif instance:IsA("Sound") then
		values.sound = instance.SoundId
		add(refs, "sound", instance.SoundId)
	elseif instance:IsA("Animation") then
		values.animation = instance.AnimationId
		add(refs, "animation", instance.AnimationId)
	elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		values.image = instance.Image
		add(refs, "image", instance.Image)
	end

	return values, refs
end

return AssetResolver
