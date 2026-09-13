local defaultFetch, defaultJsonDecode, defaultCompile = ...

local RemoteLoader = {}
RemoteLoader.__index = RemoteLoader

function RemoteLoader.new(options)
	options = options or {}

	local self = setmetatable({}, RemoteLoader)
	self.baseUrl = options.baseUrl or ""
	self.fetch = options.fetch or defaultFetch
	self.jsonDecode = options.jsonDecode or defaultJsonDecode
	self.compile = options.compile or defaultCompile
	self.manifest = options.manifest or nil
	self._cache = {}
	self._loading = {}
	self.requireFn = function(name)
		return self:require(name)
	end

	return self
end

function RemoteLoader:resolve(path)
	if type(path) ~= "string" then
		error("module path must be a string", 2)
	end

	if path:match("^https?://") then
		return path
	end

	return string.format("%s/%s", self.baseUrl, path)
end

function RemoteLoader:_get(path)
	local url = self:resolve(path)
	local body = self.fetch(url)

	if body == nil or body == "" then
		error(("failed to fetch %s"):format(url), 2)
	end

	return body
end

function RemoteLoader:_decodeJson(body)
	if self.jsonDecode then
		return self.jsonDecode(body)
	end

	return self.compile("return " .. body, "@manifest")()
end

function RemoteLoader:loadManifest(path)
	local body = self:_get(path or "manifest.json")
	local manifest = self:_decodeJson(body)
	self.manifest = manifest
	return manifest
end

function RemoteLoader:checkVersion(localVersion)
	local manifest = self.manifest or self:loadManifest()
	local remoteVersion = manifest.frameworkVersion

	if localVersion and remoteVersion and localVersion ~= remoteVersion then
		return false, remoteVersion
	end

	return true, remoteVersion
end

function RemoteLoader:_compile(source, name)
	local chunk = self.compile(source, name)

	if type(chunk) ~= "function" then
		error(("failed to compile module %s"):format(name), 2)
	end

	return chunk
end

function RemoteLoader:require(name)
	if self._cache[name] ~= nil then
		return self._cache[name]
	end

	if self._loading[name] then
		error(("circular dependency detected: %s"):format(name), 2)
	end

	local manifest = self.manifest or self:loadManifest()
	local modules = manifest.modules or {}
	local path = modules[name]

	if not path then
		error(("unknown module: %s"):format(name), 2)
	end

	self._loading[name] = true

	local ok, result = pcall(function()
		local source = self:_get(path)
		local chunk = self:_compile(source, "@" .. name)
		return chunk(self.requireFn)
	end)

	self._loading[name] = nil

	if not ok then
		error(("failed to load module %s: %s"):format(name, tostring(result)), 0)
	end

	self._cache[name] = result
	return result
end

function RemoteLoader:has(name)
	return self._cache[name] ~= nil
end

function RemoteLoader:evict(name)
	self._cache[name] = nil
end

function RemoteLoader:clear()
	self._cache = {}
end

return RemoteLoader
