local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")

local palette = Theme.Dark

local SettingsPage = {
	id = "settings",
	title = "Settings",
	order = 4,
}

function SettingsPage.create(context, parent)
	local frame = Components.create("Frame", {
		Name = "SettingsPage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		parent = parent,
	})

	Components.padding(frame, Theme.Spacing.md)
	Components.list(frame, { gap = Theme.Spacing.sm })

	Components.label(frame, {
		Text = "Settings",
		Font = Theme.Font.bold,
		TextSize = Theme.TextSize.lg,
		LayoutOrder = 0,
		parent = frame,
	})

	local function configRow(labelText, path, order)
		local row = Components.create("Frame", {
			Name = path,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = palette.surface,
			BorderSizePixel = 0,
			LayoutOrder = order,
			parent = frame,
		})

		Components.corner(row, Theme.Radius.sm)

		Components.label(row, {
			Text = labelText,
			Font = Theme.Font.medium,
			TextSize = Theme.TextSize.sm,
			Position = UDim2.fromOffset(Theme.Spacing.md, 0),
			Size = UDim2.new(0.6, -8, 1, 0),
			parent = row,
		})

		local value = Components.label(row, {
			Text = tostring(context.config:get(path)),
			Font = Theme.Font.mono,
			TextSize = Theme.TextSize.sm,
			color = palette.textMuted,
			align = Enum.TextXAlignment.Right,
			Position = UDim2.new(0.6, 0, 0, 0),
			Size = UDim2.new(0.4, -Theme.Spacing.md, 1, 0),
			parent = row,
		})

		return value
	end

	local overlayValue = configRow("Overlay enabled", "ui.overlayEnabled", 1)
	local themeValue = configRow("Theme", "ui.theme", 2)
	local logValue = configRow("Log level", "telemetry.logLevel", 3)
	local recorderValue = configRow("Recorder sample rate", "recorder.movementSampleRate", 4)

	local toolbar = Components.create("Frame", {
		Name = "Toolbar",
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		LayoutOrder = 5,
		parent = frame,
	})

	Components.list(toolbar, { direction = Enum.FillDirection.Horizontal, gap = Theme.Spacing.sm })

	Components.button(toolbar, {
		Text = "Toggle Overlay",
		Size = UDim2.fromOffset(120, 30),
		layoutOrder = 1,
	}, function()
		local value = not context.config:get("ui.overlayEnabled", false)
		context.config:set("ui.overlayEnabled", value)
		overlayValue.Text = tostring(value)
		context.logger:info("Settings", "overlay toggled", { enabled = value })
	end)

	Components.button(toolbar, {
		Text = "Cycle Log Level",
		Size = UDim2.fromOffset(120, 30),
		layoutOrder = 2,
	}, function()
		local order = { "debug", "info", "warn", "error" }
		local current = context.config:get("telemetry.logLevel", "info")
		local index = table.find(order, current) or 2
		local nextLevel = order[(index % #order) + 1]
		context.config:set("telemetry.logLevel", nextLevel)
		context.logger:setLevel(nextLevel)
		logValue.Text = nextLevel
		context.logger:info("Settings", "log level changed", { level = nextLevel })
	end)

	local function refresh()
		overlayValue.Text = tostring(context.config:get("ui.overlayEnabled"))
		themeValue.Text = tostring(context.config:get("ui.theme"))
		logValue.Text = tostring(context.config:get("telemetry.logLevel"))
		recorderValue.Text = tostring(context.config:get("recorder.movementSampleRate"))
	end

	refresh()

	return {
		frame = frame,
		refresh = refresh,
	}
end

return SettingsPage
