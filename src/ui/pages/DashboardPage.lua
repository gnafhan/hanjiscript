local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")

local palette = Theme.Dark

local DashboardPage = {
	id = "dashboard",
	title = "Dashboard",
	order = 1,
}

local function statRow(parent, key, order)
	local row = Components.create("Frame", {
		Name = key,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = palette.surface,
		BorderSizePixel = 0,
		LayoutOrder = order,
		parent = parent,
	})

	Components.corner(row, Theme.Radius.sm)

	Components.label(row, {
		Text = key,
		Font = Theme.Font.medium,
		TextSize = Theme.TextSize.sm,
		color = palette.textMuted,
		Position = UDim2.fromOffset(Theme.Spacing.md, 0),
		Size = UDim2.new(0.4, -8, 1, 0),
		parent = row,
	})

	local value = Components.label(row, {
		Name = "Value",
		Text = "—",
		Font = Theme.Font.mono,
		TextSize = Theme.TextSize.sm,
		align = Enum.TextXAlignment.Right,
		Position = UDim2.new(0.4, 0, 0, 0),
		Size = UDim2.new(0.6, -Theme.Spacing.md, 1, 0),
		parent = row,
	})

	return value
end

function DashboardPage.create(context, parent)
	local frame = Components.create("Frame", {
		Name = "DashboardPage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		parent = parent,
	})

	Components.padding(frame, Theme.Spacing.md)
	Components.list(frame, { gap = Theme.Spacing.sm })

	Components.label(frame, {
		Text = "System Overview",
		Font = Theme.Font.bold,
		TextSize = Theme.TextSize.lg,
		LayoutOrder = 0,
		parent = frame,
	})

	local values = {
		experience = statRow(frame, "Experience", 1),
		adapter = statRow(frame, "Adapter", 2),
		place = statRow(frame, "PlaceId", 3),
		game = statRow(frame, "GameId", 4),
		runtime = statRow(frame, "Runtime", 5),
		recorder = statRow(frame, "Recorder", 6),
		automation = statRow(frame, "Automation", 7),
		events = statRow(frame, "Events", 8),
	}

	local actions = Components.create("Frame", {
		Name = "Actions",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = 9,
		parent = frame,
	})

	Components.list(actions, { direction = Enum.FillDirection.Horizontal, gap = Theme.Spacing.sm })

	local function action(text, command, order)
		local button = Components.button(actions, {
			Text = text,
			Size = UDim2.new(0, 120, 1, 0),
			layoutOrder = order,
		}, function()
			local ok, err = context.commandBus:execute(command)

			if not ok then
				context.logger:warn("Dashboard", err)
			end
		end)

		return button
	end

	action("Start Recorder", "recorder.start", 1)
	action("Stop Recorder", "recorder.stop", 2)
	action("Toggle UI", "ui.toggle", 3)

	local function refresh()
		local experience = context.experience or {}
		local runtime = context.runtime or {}
		local adapter = context.adapter
		local state = context.uiState

		values.experience.Text = tostring(experience.name or "Unknown")
		values.adapter.Text = adapter and adapter.id or "none"
		values.place.Text = tostring(experience.placeId or 0)
		values.game.Text = tostring(experience.gameId or 0)
		values.runtime.Text = ("%s / %s"):format(runtime.platform or "?", runtime.environment or "?")
		values.recorder.Text = state and state:get("recorderStatus", "idle") or "idle"
		values.automation.Text = state and state:get("automationStatus", "idle") or "idle"
		values.events.Text = tostring(state and state:get("eventCount", 0) or 0)
	end

	refresh()

	return {
		frame = frame,
		refresh = refresh,
	}
end

return DashboardPage
