local EnvironmentDetector = {}

local function getExecutorName()
	if type(typeof) == "function" and typeof(identifyexecutor) == "function" then
		local ok, name = pcall(identifyexecutor)
		if ok and name then
			return name
		end
	end

	if type(getexecutorname) == "function" then
		local ok, name = pcall(getexecutorname)
		if ok and name then
			return name
		end
	end

	return nil
end

function EnvironmentDetector.detect()
	local runtime = {
		platform = "unknown",
		environment = "unknown",
		executor = nil,
	}

	local userInput = game and game:GetService("UserInputService")

	if userInput then
		if userInput.TouchEnabled and not userInput.KeyboardEnabled then
			runtime.platform = "mobile"
		elseif userInput.GamepadEnabled and not userInput.KeyboardEnabled then
			runtime.platform = "console"
		else
			runtime.platform = "desktop"
		end
	end

	local runService = game and game:GetService("RunService")

	if runService then
		runtime.environment = runService:IsStudio() and "studio" or "client"
	end

	runtime.executor = getExecutorName()

	if runtime.executor then
		runtime.environment = "executor"
	end

	return runtime
end

return EnvironmentDetector
