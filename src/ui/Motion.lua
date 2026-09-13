local require = ...

local Theme = require("ui.Theme")

local tweenService = game:GetService("TweenService")

local Motion = {}

local function ensureScale(instance)
	local scale = instance:FindFirstChild("__MotionScale")

	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "__MotionScale"
		scale.Scale = 1
		scale.Parent = instance
	end

	return scale
end

function Motion.tween(instance, info, props)
	local tween = tweenService:Create(instance, info or Theme.Motion.easeOut, props)
	tween:Play()
	return tween
end

function Motion.hover(instance, enterProps, leaveProps, info)
	local tweenInfo = info or Theme.Motion.easeOut

	instance.MouseEnter:Connect(function()
		Motion.tween(instance, tweenInfo, enterProps)
	end)

	instance.MouseLeave:Connect(function()
		Motion.tween(instance, tweenInfo, leaveProps)
	end)
end

function Motion.press(instance)
	local scale = ensureScale(instance)
	local pressInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	instance.MouseButton1Down:Connect(function()
		scale.Scale = 0.97
	end)

	instance.MouseButton1Up:Connect(function()
		scale.Scale = 1
	end)

	instance.MouseLeave:Connect(function()
		scale.Scale = 1
	end)

	return scale
end

function Motion.ripple(button, color)
	button.ClipsDescendants = true

	local rippleColor = color or Color3.fromRGB(255, 255, 255)
	local rippleInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	button.MouseButton1Down:Connect(function(x, y)
		local circle = Instance.new("Frame")
		circle.Name = "MotionRipple"
		circle.AnchorPoint = Vector2.new(0.5, 0.5)
		circle.BackgroundColor3 = rippleColor
		circle.BackgroundTransparency = 0.72
		circle.BorderSizePixel = 0
		circle.ZIndex = 30
		circle.Size = UDim2.fromOffset(0, 0)
		circle.Position = UDim2.fromOffset(
			x - button.AbsolutePosition.X,
			y - button.AbsolutePosition.Y
		)
		circle.Parent = button

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = circle

		local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.2
		local tween = tweenService:Create(circle, rippleInfo, {
			Size = UDim2.fromOffset(maxSize, maxSize),
			BackgroundTransparency = 1,
		})

		tween.Completed:Connect(function()
			circle:Destroy()
		end)

		tween:Play()
	end)
end

function Motion.reveal(instance, options)
	options = options or {}

	local info = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local offset = options.offset or 10

	if instance:IsA("CanvasGroup") then
		instance.GroupTransparency = 1
		instance.Position = instance.Position + UDim2.fromOffset(0, offset)
		Motion.tween(instance, info, {
			GroupTransparency = 0,
			Position = instance.Position - UDim2.fromOffset(0, offset),
		})
		return
	end

	local original = instance.BackgroundTransparency
	instance.BackgroundTransparency = 1
	Motion.tween(instance, info, { BackgroundTransparency = original })
end

return Motion
