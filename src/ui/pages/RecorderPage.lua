local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")
local Maid = require("utils.Maid")

local palette = Theme.Dark

local RecorderPage = {
	id = "recorder",
	title = "Recorder",
	order = 3,
}

local STATUS_COLORS = {
	idle = palette.textMuted,
	starting = palette.warn,
	running = palette.success,
	paused = palette.warn,
	stopping = palette.warn,
	stopped = palette.textMuted,
	failed = palette.danger,
}

function RecorderPage.create(context, parent)
	local frame = Components.create("Frame", {
		Name = "RecorderPage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		parent = parent,
	})

	Components.padding(frame, Theme.Spacing.md)
	Components.list(frame, { gap = Theme.Spacing.sm })

	local header = Components.create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		parent = frame,
	})

	Components.label(header, {
		Text = "Session Recorder",
		Font = Theme.Font.bold,
		TextSize = Theme.TextSize.lg,
		Size = UDim2.new(1, -80, 1, 0),
		parent = header,
	})

	local status = Components.badge(header, {
		Text = "idle",
		Position = UDim2.new(1, -76, 0, 4),
		size = UDim2.fromOffset(76, 20),
		parent = header,
	})

	local toolbar = Components.create("Frame", {
		Name = "Toolbar",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		parent = frame,
	})

	Components.list(toolbar, { direction = Enum.FillDirection.Horizontal, gap = Theme.Spacing.sm })

	local function action(text, command, order)
		Components.button(toolbar, {
			Text = text,
			Size = UDim2.fromOffset(84, 30),
			layoutOrder = order,
		}, function()
			local ok, err = context.commandBus:execute(command)

			if not ok then
				context.logger:warn("Recorder", err)
			end
		end)
	end

	action("Start", "recorder.start", 1)
	action("Pause", "recorder.pause", 2)
	action("Resume", "recorder.resume", 3)
	action("Stop", "recorder.stop", 4)

	local scroll = Components.create("ScrollingFrame", {
		Name = "Timeline",
		Size = UDim2.new(1, 0, 1, -70),
		BackgroundColor3 = palette.surface,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		parent = frame,
	})

	Components.corner(scroll, Theme.Radius.sm)
	Components.padding(scroll, Theme.Spacing.sm)
	Components.list(scroll, { gap = 2 })

	local maid = Maid.new()
	local counter = 0

	local function append(entry)
		counter += 1

		Components.label(scroll, {
			Text = ("%8.3f  [%s] %s"):format(entry.timestamp or 0, entry.tag, entry.message),
			Font = Theme.Font.mono,
			TextSize = Theme.TextSize.xs,
			color = entry.level and entry.level >= 30 and palette.warn or palette.textMuted,
			Size = UDim2.new(1, 0, 0, 16),
			layoutOrder = counter,
			parent = scroll,
		})
	end

	maid:Add(context.logger.Emitted:Connect(append))

	local function refresh()
		local value = context.uiState and context.uiState:get("recorderStatus", "idle") or "idle"
		local text = status:FindFirstChild("Text")

		if text then
			text.Text = value
		end

		local color = STATUS_COLORS[value] or palette.textMuted
		local stroke = status:FindFirstChildOfClass("UIStroke")

		if stroke then
			stroke.Color = color
		end

		if text then
			text.TextColor3 = color
		end
	end

	maid:Add(context.uiState.ChangedKey:Connect(function(key)
		if key == "recorderStatus" then
			refresh()
		end
	end))

	if frame.Destroying then
		maid:Add(frame.Destroying:Connect(function()
			maid:Destroy()
		end))
	end

	refresh()

	return {
		frame = frame,
		refresh = refresh,
		destroy = function()
			maid:Destroy()
		end,
	}
end

return RecorderPage
