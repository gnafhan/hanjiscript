local BASE_URL = "https://raw.githubusercontent.com/gnafhan/hanjiscript/893eeb2"

local function getFetch()
	if type(http_request) == "function" then
		return function(url)
			local response = http_request({ Url = url, Method = "GET" })
			return response and response.Body
		end
	end

	if type(request) == "function" then
		return function(url)
			local response = request({ Url = url, Method = "GET" })
			return response and response.Body
		end
	end

	if syn and syn.request then
		return function(url)
			local response = syn.request({ Url = url, Method = "GET" })
			return response and response.Body
		end
	end

	if type(game) == "table" and game.HttpGet then
		return function(url)
			return game:HttpGet(url)
		end
	end

	return nil
end

local function getCompiler()
	if type(loadstring) == "function" then
		return function(source, chunkName)
			return loadstring(source, chunkName)
		end
	end

	if type(load) == "function" then
		return function(source, chunkName)
			return load(source, chunkName)
		end
	end

	return nil
end

local function notify(title, text, duration)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration or 4,
		})
	end)
end

local fetch = getFetch()
local compile = getCompiler()

if not fetch or not compile then
	notify("HanjiScript", "Unsupported environment: need HTTP + loadstring.", 6)
	return
end

local ok, err = pcall(function()
	local loaderSource = fetch(BASE_URL .. "/src/loader/RemoteLoader.lua")
	local factory = compile(loaderSource, "@RemoteLoader")

	local jsonDecode = function(body)
		return game:GetService("HttpService"):JSONDecode(body)
	end

	local RemoteLoader = factory(fetch, jsonDecode, compile)
	local loader = RemoteLoader.new({ baseUrl = BASE_URL })

	local manifest = loader:loadManifest("manifest.json")
	local main = loader:require(manifest.entry or "main")
	main(loader)
end)

if not ok then
	notify("HanjiScript", "Bootstrap failed: " .. tostring(err), 8)
end
