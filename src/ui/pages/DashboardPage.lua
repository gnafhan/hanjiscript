local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")
local Icons = require("ui.Icons")
local Maid = require("utils.Maid")

local palette = Theme.Dark

local DashboardPage = {
	id = "dashboard",
	title = "Dashboard",
	subtitle = "System overview and quick actions",
	icon = "dashboard",
	order = 1,
}

local function metricCard(parent, options)
	local card = Components.card(parent, {
		name = options.name or "Metric",
		padding = Theme.Spacing.lg,
		layoutOrder = options.order or 0,
	})

	local accent = options.accent or palette.accent
	local iconTile = Components.create("Frame", {
		Name = "IconTile",
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(34, 34),
		parent = card,
	})
	Components.corner(iconTile, Theme.Radius.md)
	Icons.create(iconTile, options.icon or "dot", {
		size = 16,
		color = accent,
		anchorPoint = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
	})

	Components.label(card, {
		text = string.upper(options.label or "Metric"),
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		position = UDim2.fromOffset(46, 1),
		size = UDim2.new(1, -46, 0, 18),
	})

	local value = Components.label(card, {
		text = "—",
		font = Theme.Font.title,
		textSize = Theme.Text.title,
		color = palette.text,
		truncate = Enum.TextTruncate.AtEnd,
		position = UDim2.fromOffset(0, 50),
		size = UDim2.new(1, 0, 0, 24),
	})

	local meta = Components.label(card, {
		text = options.meta or "",
		font = Theme.Font.body,
		textSize = Theme.Text.caption,
		color = palette.textMuted,
		truncate = Enum.TextTruncate.AtEnd,
		position = UDim2.fromOffset(0, 78),
		size = UDim2.new(1, 0, 0, 18),
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
	local frame = Components.create("ScrollingFrame", {
		Name = "DashboardPage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = palette.borderStrong,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		parent = parent,
	})
	Components.list(frame, { gap = Theme.Spacing.md })

	local metrics = Components.create("Frame", {
		Name = "Metrics",
		Size = UDim2.new(1, 0, 0, 236),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		parent = frame,
	})
	Components.grid(metrics, {
		cellSize = UDim2.new(0.5, -6, 0, 112),
		cellPadding = UDim2.fromOffset(12, 12),
		maxCells = 2,
	})

	local stats = {
		experience = metricCard(metrics, { label = "Experience", icon = "dashboard", accent = palette.accent, order = 1 }),
		adapter = metricCard(metrics, { label = "Adapter", icon = "settings", accent = palette.info, order = 2 }),
		runtime = metricCard(metrics, { label = "Runtime", icon = "activity", accent = palette.success, order = 3 }),
		events = metricCard(metrics, { label = "Events captured", icon = "recorder", accent = palette.warn, order = 4 }),
	}

	local actions = Components.card(frame, {
		name = "QuickActions",
		padding = Theme.Spacing.lg,
		size = UDim2.new(1, 0, 0, 102),
		layoutOrder = 1,
	})
	Components.label(actions, {
		text = "QUICK ACTIONS",
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		size = UDim2.new(1, 0, 0, 18),
	})
	Components.label(actions, {
		text = "Recorder controls",
		font = Theme.Font.body,
		textSize = Theme.Text.caption,
		color = palette.textFaint,
		position = UDim2.fromOffset(0, 18),
		size = UDim2.new(1, 0, 0, 16),
	})

	local actionRow = Components.create("Frame", {
		Name = "Actions",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 1, -38),
		Size = UDim2.new(1, 0, 0, 38),
		parent = actions,
	})
	Components.list(actionRow, { direction = Enum.FillDirection.Horizontal, gap = Theme.Spacing.sm })

	local function action(text, command, variant, icon, order)
		return Components.button(actionRow, {
			text = text,
			variant = variant,
			icon = icon,
			size = UDim2.new(1 / 3, -6, 0, 38),
			layoutOrder = order,
		}, function()
			local ok, err = context.commandBus:execute(command)
			if not ok then
				context.logger:warn("Dashboard", err)
			end
		end)
	end

	action("Start", "recorder.start", "primary", "recorder", 1)
	action("Stop", "recorder.stop", "secondary", "minimize", 2)
	action("Hide window", "ui.toggle", "ghost", "dashboard", 3)

	local snapshotCard = Components.card(frame, {
		name = "RuntimeSnapshot",
		padding = Theme.Spacing.lg,
		size = UDim2.new(1, 0, 0, 118),
		layoutOrder = 2,
	})
	Components.label(snapshotCard, {
		text = "RUNTIME SNAPSHOT",
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		size = UDim2.new(1, 0, 0, 18),
	})

	local snapshotLabels = {}
	local snapshotFields = {
		{ key = "WorldModel", position = UDim2.fromOffset(0, 28) },
		{ key = "Workflow", position = UDim2.new(0.5, 0, 0, 28) },
		{ key = "Target", position = UDim2.fromOffset(0, 67) },
		{ key = "Inventory", position = UDim2.new(0.5, 0, 0, 67) },
	}
	for _, field in ipairs(snapshotFields) do
		Components.label(snapshotCard, {
			text = string.upper(field.key),
			font = Theme.Font.medium,
			textSize = Theme.Text.micro,
			color = palette.textFaint,
			position = field.position,
			size = UDim2.new(0.5, -10, 0, 14),
		})
		snapshotLabels[field.key] = Components.label(snapshotCard, {
			text = "—",
			font = Theme.Font.mono,
			textSize = Theme.Text.caption,
			color = palette.text,
			position = (field.key == "Workflow" or field.key == "Inventory")
				and UDim2.new(0.5, 0, 0, field.position.Y.Offset + 14)
				or UDim2.fromOffset(0, field.position.Y.Offset + 14),
			size = UDim2.new(0.5, -10, 0, 16),
			truncate = Enum.TextTruncate.AtEnd,
		})
	end

	local activity = Components.card(frame, {
		name = "Activity",
		padding = Theme.Spacing.lg,
		size = UDim2.new(1, 0, 0, 182),
		layoutOrder = 4,
	})

	local analyticsCard = Components.card(frame, {
		name = "Analytics",
		padding = Theme.Spacing.lg,
		size = UDim2.new(1, 0, 0, 112),
		layoutOrder = 3,
	})
	Components.label(analyticsCard, {
		text = "OBSERVABILITY",
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		size = UDim2.new(1, 0, 0, 18),
	})

	local analyticsLabels = {}
	local analyticsFields = {
		{ key = "Route", value = "—", x = 0 },
		{ key = "Nav success", value = "—", x = 0.25 },
		{ key = "Cycles", value = "—", x = 0.5 },
		{ key = "Items / min", value = "—", x = 0.75 },
	}
	for _, field in ipairs(analyticsFields) do
		local position = UDim2.new(field.x, 0, 0, 32)
		Components.label(analyticsCard, {
			text = string.upper(field.key),
			font = Theme.Font.medium,
			textSize = Theme.Text.micro,
			color = palette.textFaint,
			position = position,
			size = UDim2.new(0.25, -8, 0, 14),
		})
		analyticsLabels[field.key] = Components.label(analyticsCard, {
			text = field.value,
			font = Theme.Font.mono,
			textSize = Theme.Text.caption,
			color = palette.text,
			position = UDim2.new(field.x, 0, 0, 53),
			size = UDim2.new(0.25, -8, 0, 18),
			truncate = Enum.TextTruncate.AtEnd,
		})
	end
	Components.label(activity, {
		text = "RECENT ACTIVITY",
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		size = UDim2.new(1, 0, 0, 18),
	})

	local scroll = Components.create("ScrollingFrame", {
		Name = "Log",
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, 0, 1, -28),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = palette.borderStrong,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		parent = activity,
	})
	Components.list(scroll, { gap = 4 })

	local maid = Maid.new()
	local counter = 0
	local MAX_ROWS = 60

	local function addEntry(entry)
		counter += 1
		local color = entry.level >= 40 and palette.danger
			or entry.level >= 30 and palette.warn
			or entry.level >= 20 and palette.info
			or palette.textMuted

		local row = Components.create("Frame", {
			Name = "Entry",
			Size = UDim2.new(1, -4, 0, 24),
			BackgroundColor3 = palette.surfaceAlt,
			BackgroundTransparency = 0.58,
			BorderSizePixel = 0,
			LayoutOrder = -counter,
			parent = scroll,
		})
		Components.corner(row, Theme.Radius.sm)
		Components.create("Frame", {
			Name = "Level",
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 5),
			Size = UDim2.fromOffset(3, 14),
			parent = row,
		})
		Components.label(row, {
			text = ("%s  %s"):format(string.upper(entry.tag), entry.message),
			font = Theme.Font.mono,
			textSize = Theme.Text.micro,
			color = palette.textSecondary,
			truncate = Enum.TextTruncate.AtEnd,
			position = UDim2.fromOffset(12, 0),
			size = UDim2.new(1, -18, 1, 0),
		})

		if counter > MAX_ROWS then
			for _, child in ipairs(scroll:GetChildren()) do
				if child.Name == "Entry" and child.LayoutOrder == -1 then
					child:Destroy()
					break
				end
			end
		end
	end

	maid:Add(context.logger.Emitted:Connect(addEntry))
	maid:Add(frame.Destroying:Connect(function()
		maid:Destroy()
	end))

	local function refresh()
		local experience = context.experience or {}
		local runtime = context.runtime or {}
		local adapter = context.adapter
		local state = context.uiState
		stats.experience.setValue(experience.name or "Unknown experience")
		stats.experience.setMeta(("Place ID %s"):format(tostring(experience.placeId or 0)))
		stats.adapter.setValue(adapter and adapter.id or "None")
		stats.adapter.setMeta("Universal compatibility layer")
		stats.runtime.setValue(runtime.environment or "Unknown")
		stats.runtime.setMeta((runtime.platform or "Unknown") .. " client")
		stats.events.setValue(tostring(state and state:get("eventCount", 0) or 0))
		local analytics = context.analytics and context.analytics:snapshot() or {}
		stats.events.setMeta(("Recorder %s · %d interactions"):format(
			state and state:get("recorderStatus", "idle") or "idle",
			analytics.interactionsCompleted or 0
		))

		local world = context.world
		local workflow = context.workflowRunner and context.workflowRunner:getSnapshot() or {}
		local target = workflow.plan and workflow.plan.target
		local inventory = context.inventorySensor and context.inventorySensor:getCount() or 0
		local capacity = context.config:get("automation.inventoryCapacity", 20)
		local analyticsSnapshot = context.analytics and context.analytics:snapshot() or {}
		snapshotLabels.WorldModel.Text = world and ("%d entities"):format(world:count()) or "unavailable"
		snapshotLabels.Workflow.Text = workflow.running and (workflow.state or "running") or "idle"
		snapshotLabels.Target.Text = target and (target.name or target.path or "selected") or "—"
		snapshotLabels.Inventory.Text = ("%d / %d items"):format(inventory, capacity)
		analyticsLabels.Route.Text = analyticsSnapshot.averagePathLength > 0
			and ("%.1f studs"):format(analyticsSnapshot.averagePathLength)
			or "—"
		analyticsLabels["Nav success"].Text = analyticsSnapshot.navigationCompleted > 0
			and ("%d%%"):format(math.floor(analyticsSnapshot.navigationSuccessRate * 100 + 0.5))
			or "—"
		analyticsLabels.Cycles.Text = tostring(analyticsSnapshot.workflowCycles or 0)
		analyticsLabels["Items / min"].Text = analyticsSnapshot.itemsPerMinute > 0
			and ("%.1f"):format(analyticsSnapshot.itemsPerMinute)
			or "—"
	end

	for _, eventType in ipairs({
		"workflow.state_changed",
		"workflow.plan_updated",
		"automation.state_changed",
		"inventory.changed",
		"navigation.started",
		"navigation.path_computed",
		"navigation.completed",
		"semantic.action",
	}) do
		maid:Add(context.eventBus:on(eventType, refresh))
	end

	for _, entry in ipairs(context.logger:history()) do
		addEntry(entry)
	end
	refresh()

	return { frame = frame, refresh = refresh }
end

return DashboardPage
