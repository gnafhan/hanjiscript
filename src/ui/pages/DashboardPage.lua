local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")
local Icons = require("ui.Icons")
local Motion = require("ui.Motion")
local Maid = require("utils.Maid")

local palette = Theme.Dark

local DashboardPage = {
	id = "dashboard",
	title = "Dashboard",
	subtitle = "System overview and quick actions",
	icon = "dashboard",
	order = 1,
}

local function statCard(parent, options)
	local card = Components.card(parent, {
		name = options.name or "StatCard",
		padding = Theme.Spacing.md,
		layoutOrder = options.order or 0,
	})

	local accent = options.accent or palette.accent

	local tile = Components.create("Frame", {
		Name = "Tile",
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.84,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(28, 28),
		parent = card,
	})

	Components.corner(tile, Theme.Radius.sm)

	Icons.create(tile, options.icon or "dot", {
		size = 15,
		color = accent,
		anchorPoint = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
	})

	Components.label(card, {
		text = string.upper(options.label or "Metric"),
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		position = UDim2.fromOffset(38, 6),
		size = UDim2.new(1, -38, 0, 16),
	})

	local value = Components.label(card, {
		text = "—",
		font = Theme.Font.display,
		textSize = Theme.Text.title,
		color = palette.text,
		position = UDim2.fromOffset(0, 36),
		size = UDim2.new(1, 0, 0, 22),
	})

	local meta = Components.label(card, {
		text = options.meta or "",
		font = Theme.Font.body,
		textSize = Theme.Text.caption,
		color = palette.textMuted,
		position = UDim2.fromOffset(0, 60),
		size = UDim2.new(1, 0, 0, 16),
	})

	return {
		frame = card,
		setValue = function(text)
			value.Text = tostring(text)
		end,
		setMeta = function(text)
			meta.Text = tostring(text)
		end,
	}
end

function DashboardPage.create(context, parent)
	local frame = Components.create("Frame", {
		Name = "DashboardPage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		parent = parent,
	})

	Components.list(frame, { gap = Theme.Spacing.md })

	local gridHolder = Components.create("Frame", {
		Name = "Stats",
		Size = UDim2.new(1, 0, 0, 202),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		parent = frame,
	})

	Components.grid(gridHolder, {
		cellSize = UDim2.new(0.5, -6, 0, 96),
		cellPadding = UDim2.fromOffset(12, 10),
		maxCells = 2,
	})

	local stats = {
		experience = statCard(gridHolder, { label = "Experience", icon = "dashboard", accent = palette.accent, order = 1 }),
		adapter = statCard(gridHolder, { label = "Adapter", icon = "settings", accent = palette.info, order = 2 }),
		runtime = statCard(gridHolder, { label = "Runtime", icon = "activity", accent = palette.success, order = 3 }),
		events = statCard(gridHolder, { label = "Events", icon = "recorder", accent = palette.warn, order = 4 }),
	}

	local actions = Components.card(frame, {
		name = "Actions",
		padding = Theme.Spacing.md,
		gap = Theme.Spacing.md,
		size = UDim2.new(1, 0, 0, 96),
		layoutOrder = 1,
	})

	Components.label(actions, {
		text = "Quick Actions",
		font = Theme.Font.medium,
		textSize = Theme.Text.label,
		color = palette.textSecondary,
		size = UDim2.new(1, 0, 0, 16),
		layoutOrder = 0,
	})

	local actionRow = Components.create("Frame", {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		parent = actions,
	})

	Components.list(actionRow, { direction = Enum.FillDirection.Horizontal, gap = Theme.Spacing.sm })

	local function action(text, command, variant, icon, order)
		local button = Components.button(actionRow, {
			text = text,
			variant = variant,
			icon = icon,
			size = UDim2.fromOffset(150, 34),
			layoutOrder = order,
		}, function()
			local ok, err = context.commandBus:execute(command)

			if not ok then
				context.logger:warn("Dashboard", err)
			end
		end)

		return button
	end

	action("Start Recorder", "recorder.start", "primary", "recorder", 1)
	action("Stop Recorder", "recorder.stop", "secondary", "minimize", 2)
	action("Toggle Window", "ui.toggle", "ghost", "dashboard", 3)

	local activity = Components.card(frame, {
		name = "Activity",
		padding = Theme.Spacing.md,
		gap = Theme.Spacing.sm,
		size = UDim2.new(1, 0, 0, 150),
		layoutOrder = 2,
	})

	Components.label(activity, {
		text = "Recent Activity",
		font = Theme.Font.medium,
		textSize = Theme.Text.label,
		color = palette.textSecondary,
		size = UDim2.new(1, 0, 0, 16),
		layoutOrder = 0,
	})

	local scroll = Components.create("ScrollingFrame", {
		Name = "Log",
		Size = UDim2.new(1, 0, 1, -24),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = palette.borderStrong,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		parent = activity,
	})

	Components.list(scroll, { gap = 3 })

	local maid = Maid.new()
	local counter = 0
	local MAX_ROWS = 60

	local function addEntry(entry)
		counter += 1

		local levelColor = palette.textMuted
		if entry.level >= 40 then
			levelColor = palette.danger
		elseif entry.level >= 30 then
			levelColor = palette.warn
		elseif entry.level >= 20 then
			levelColor = palette.info
		end

		local row = Components.create("Frame", {
			Name = "Entry",
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			LayoutOrder = -counter,
			parent = scroll,
		})

		local dot = Components.create("Frame", {
			Name = "Dot",
			BackgroundColor3 = levelColor,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(6, 6),
			parent = row,
		})

		Components.corner(dot, 0.5)

		Components.label(row, {
			text = ("[%s] %s"):format(entry.tag, entry.message),
			font = Theme.Font.mono,
			textSize = Theme.Text.micro,
			color = palette.textSecondary,
			truncate = Enum.TextTruncate.AtEnd,
			position = UDim2.fromOffset(14, 0),
			size = UDim2.new(1, -14, 1, 0),
		})

		if counter > MAX_ROWS then
			local children = scroll:GetChildren()
			local oldest
			for _, child in ipairs(children) do
				if child.Name == "Entry" then
					if not oldest or child.LayoutOrder > oldest.LayoutOrder then
						oldest = child
					end
				end
			end
			if oldest then
				oldest:Destroy()
			end
		end
	end

	maid:Add(context.logger.Emitted:Connect(addEntry))

	if frame.Destroying then
		maid:Add(frame.Destroying:Connect(function()
			maid:Destroy()
		end))
	end

	local function refresh()
		local experience = context.experience or {}
		local runtime = context.runtime or {}
		local adapter = context.adapter
		local state = context.uiState

		stats.experience.setValue(experience.name or "Unknown")
		stats.experience.setMeta(("PlaceId %s"):format(tostring(experience.placeId or 0)))

		stats.adapter.setValue(adapter and adapter.id or "none")
		stats.adapter.setMeta("fallback: universal")

		stats.runtime.setValue(("%s"):format(runtime.environment or "unknown"))
		stats.runtime.setMeta(("%s device"):format(runtime.platform or "unknown"))

		stats.events.setValue(tostring(state and state:get("eventCount", 0) or 0))
		stats.events.setMeta(("recorder: %s"):format(state and state:get("recorderStatus", "idle") or "idle"))
	end

	for _, entry in ipairs(context.logger:history()) do
		addEntry(entry)
	end

	refresh()

	return {
		frame = frame,
		refresh = refresh,
	}
end

return DashboardPage
