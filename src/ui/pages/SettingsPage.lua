local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")
local Motion = require("ui.Motion")

local palette = Theme.Dark

local SettingsPage = {
	id = "settings",
	title = "Settings",
	subtitle = "Configuration and diagnostics",
	icon = "settings",
	order = 4,
}

local LOG_LEVELS = { "debug", "info", "warn", "error" }
local SAMPLE_RATES = { 1, 2, 5, 10 }

function SettingsPage.create(context, parent)
	local frame = Components.create("Frame", {
		Name = "SettingsPage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		parent = parent,
	})

	Components.list(frame, { gap = Theme.Spacing.md })

	local function buttonLabel(button)
		local content = button:FindFirstChild("Content")
		return content and content:FindFirstChild("Label")
	end

	local preferences = Components.card(frame, {
		name = "Preferences",
		padding = Theme.Spacing.md,
		gap = Theme.Spacing.sm,
		size = UDim2.new(1, 0, 0, 190),
		layoutOrder = 0,
	})

	Components.label(preferences, {
		text = "Preferences",
		font = Theme.Font.medium,
		textSize = Theme.Text.label,
		color = palette.textSecondary,
		size = UDim2.new(1, 0, 0, 16),
		layoutOrder = 0,
	})

	local overlayRow = Components.row(preferences, {
		title = "Overlay",
		subtitle = "Draw entity labels over the world",
		layoutOrder = 1,
	})

	local overlayToggle = Components.toggle(overlayRow.right, {
		value = context.config:get("ui.overlayEnabled", false),
		position = UDim2.fromScale(0.5, 0.5),
		anchorPoint = Vector2.new(0.5, 0.5),
	}, function(value)
		context.config:set("ui.overlayEnabled", value)
		context.logger:info("Settings", ("overlay %s"):format(value and "enabled" or "disabled"))
	end)

	local logRow = Components.row(preferences, {
		title = "Log Level",
		subtitle = "Minimum severity sent to the logger",
		layoutOrder = 2,
	})

	local logButton = Components.button(logRow.right, {
		text = string.upper(context.config:get("telemetry.logLevel", "info")),
		variant = "secondary",
		size = UDim2.fromOffset(96, 30),
	}, function()
		local current = context.config:get("telemetry.logLevel", "info")
		local index = table.find(LOG_LEVELS, current) or 2
		local next_ = LOG_LEVELS[(index % #LOG_LEVELS) + 1]

		context.config:set("telemetry.logLevel", next_)
		context.logger:setLevel(next_)

		local label = buttonLabel(logButton)
		if label then
			label.Text = string.upper(next_)
		end

		context.logger:info("Settings", ("log level -> %s"):format(next_))
	end)

	local rateRow = Components.row(preferences, {
		title = "Movement Sample Rate",
		subtitle = "Samples captured per second",
		layoutOrder = 3,
	})

	local rateButton = Components.button(rateRow.right, {
		text = ("%d Hz"):format(context.config:get("recorder.movementSampleRate", 5)),
		variant = "secondary",
		size = UDim2.fromOffset(96, 30),
	}, function()
		local current = context.config:get("recorder.movementSampleRate", 5)
		local index = table.find(SAMPLE_RATES, current) or 3
		local next_ = SAMPLE_RATES[(index % #SAMPLE_RATES) + 1]

		context.config:set("recorder.movementSampleRate", next_)

		local label = buttonLabel(rateButton)
		if label then
			label.Text = ("%d Hz"):format(next_)
		end

		context.logger:info("Settings", ("sample rate -> %d Hz"):format(next_))
	end)

	local about = Components.card(frame, {
		name = "About",
		padding = Theme.Spacing.md,
		gap = Theme.Spacing.sm,
		size = UDim2.new(1, 0, 1, -202),
		layoutOrder = 1,
	})

	Components.label(about, {
		text = "About",
		font = Theme.Font.medium,
		textSize = Theme.Text.label,
		color = palette.textSecondary,
		size = UDim2.new(1, 0, 0, 16),
		layoutOrder = 0,
	})

	local capabilities = context.capabilities or {}

	local aboutRows = {
		{ key = "Framework", value = "v" .. tostring(context.uiState:get("version", "0.1.0")) },
		{ key = "Adapter", value = (context.adapter and context.adapter.id or "none") },
		{ key = "Environment", value = (context.runtime and context.runtime.environment or "unknown") },
		{ key = "HTTP", value = capabilities.http and "available" or "unavailable" },
		{ key = "Persistence", value = capabilities.persistence and "available" or "unavailable" },
	}

	for index, item in ipairs(aboutRows) do
		local row = Components.create("Frame", {
			Name = item.key,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),
			LayoutOrder = index,
			parent = about,
		})

		Components.label(row, {
			text = item.key,
			font = Theme.Font.body,
			textSize = Theme.Text.caption,
			color = palette.textMuted,
			size = UDim2.new(0.5, 0, 1, 0),
		})

		Components.label(row, {
			text = item.value,
			font = Theme.Font.mono,
			textSize = Theme.Text.caption,
			color = palette.text,
			align = Enum.TextXAlignment.Right,
			position = UDim2.new(0.5, 0, 0, 0),
			size = UDim2.new(0.5, 0, 1, 0),
		})
	end

	local function refresh()
		overlayToggle.set(context.config:get("ui.overlayEnabled", false))

		local logLabel = buttonLabel(logButton)
		if logLabel then
			logLabel.Text = string.upper(context.config:get("telemetry.logLevel", "info"))
		end

		local rateLabel = buttonLabel(rateButton)
		if rateLabel then
			rateLabel.Text = ("%d Hz"):format(context.config:get("recorder.movementSampleRate", 5))
		end
	end

	return {
		frame = frame,
		refresh = refresh,
	}
end

return SettingsPage
