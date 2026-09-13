local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")
local Motion = require("ui.Motion")

local palette = Theme.Dark

local KIND_COLORS = {
	info = palette.info,
	success = palette.success,
	warn = palette.warn,
	error = palette.danger,
	accent = palette.accent,
}

local Notifications = {}
Notifications.__index = Notifications

function Notifications.new(parent, options)
	options = options or {}

	local container = Components.create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 20),
		Size = UDim2.fromOffset(options.width or 304, 1),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 100,
		parent = parent,
	})

	Components.list(container, {
		gap = 10,
		horizontal = Enum.HorizontalAlignment.Right,
	})

	return setmetatable({
		container = container,
		width = options.width or 304,
		max = options.max or 4,
		items = {},
	}, Notifications)
end

function Notifications:_remove(record)
	for index, item in ipairs(self.items) do
		if item == record then
			table.remove(self.items, index)
			break
		end
	end
end

function Notifications:push(options)
	options = options or {}

	local kind = options.kind or "info"
	local accent = KIND_COLORS[kind] or palette.accent
	local duration = options.duration or 4

	local toast = Components.create("CanvasGroup", {
		Name = "Toast",
		BackgroundColor3 = palette.surface,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		GroupTransparency = 1,
		ZIndex = 100,
		parent = self.container,
	})

	Components.corner(toast, Theme.Radius.lg)
	Components.stroke(toast, palette.border)

	local scale = Instance.new("UIScale")
	scale.Scale = 0.94
	scale.Parent = toast

	local bar = Components.create("Frame", {
		Name = "Accent",
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 3, 1, -16),
		parent = toast,
	})

	Components.corner(bar, Theme.Radius.pill)

	local body = Components.create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(0, 0),
		parent = toast,
	})

	Components.padding(body, { top = 12, bottom = 12, left = 16, right = 30 })
	Components.list(body, { gap = 4 })

	local header = Components.create("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 0,
		parent = body,
	})

	Components.label(header, {
		text = options.title or "HanjiScript",
		font = Theme.Font.medium,
		textSize = Theme.Text.label,
		color = palette.text,
		size = UDim2.new(1, 0, 1, 0),
	})

	Components.label(body, {
		text = options.text or options.message or "",
		font = Theme.Font.body,
		textSize = Theme.Text.caption,
		color = palette.textSecondary,
		wrapped = true,
		size = UDim2.new(1, 0, 0, 0),
		automaticSize = Enum.AutomaticSize.Y,
		layoutOrder = 1,
	})

	local closeButton = Components.iconButton(toast, {
		name = "Close",
		icon = "close",
		iconSize = 10,
		size = 22,
		variant = "ghost",
		anchorPoint = Vector2.new(1, 0),
		position = UDim2.new(1, -8, 0, 8),
	})

	local record = {
		kind = kind,
		close = function()
			if toast.Parent == nil then
				return
			end

			Motion.tween(toast, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				GroupTransparency = 1,
			})
			local outScale = Motion.tween(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Scale = 0.94,
			})

			outScale.Completed:Connect(function()
				toast:Destroy()
			end)

			self:_remove(record)
		end,
	}

	table.insert(self.items, record)

	if #self.items > self.max then
		local oldest = self.items[1]
		if oldest then
			oldest.close()
		end
	end

	closeButton.MouseButton1Click:Connect(function()
		record.close()
	end)

	Motion.tween(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		GroupTransparency = 0,
	})

	Motion.tween(scale, TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	})

	if duration > 0 then
		task.delay(duration, function()
			record.close()
		end)
	end

	return record
end

function Notifications:info(text, title)
	return self:push({ kind = "info", text = text, title = title })
end

function Notifications:success(text, title)
	return self:push({ kind = "success", text = text, title = title })
end

function Notifications:warn(text, title)
	return self:push({ kind = "warn", text = text, title = title })
end

function Notifications:error(text, title)
	return self:push({ kind = "error", text = text, title = title })
end

return Notifications
