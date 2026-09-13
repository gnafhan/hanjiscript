local require = ...

local Application = require("core.Application")

return function(bootstrap)
	local options = {}

	if bootstrap and bootstrap.options then
		options = bootstrap.options
	end

	local application = Application.new(options)
	application:init()
	application:start()

	local handle = {
		version = "0.1.0",
		application = application,
		context = application.context,
		loader = bootstrap,

		stop = function()
			application:stop()
		end,

		destroy = function()
			application:destroy()
		end,
	}

	if type(getgenv) == "function" then
		getgenv().HanjiScript = handle
	end

	return handle
end
