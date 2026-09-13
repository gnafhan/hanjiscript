local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")
local Icons = require("ui.Icons")
local Motion = require("ui.Motion")
local Maid = require("utils.Maid")

local palette = Theme.Dark

local RecorderPage = {
	id = "recorder",
	title = "Recorder",
	subtitle = "Capture sessions into a semantic timeline",
	icon = "recorder",
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

local STATUS_LABEL = {
	idle = "Idle",
	starting = "Starting",
	running = "Recording",
	paused = "Paused",
	stopping = "Stopping",
	stopped = "Stopped",
	failed = "Failed",
}

function RecorderPage.create(context, parent)
	local frame = Components.create("Frame", {
		Name = "RecorderPage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		parent = parent,
	})

	Components.list(frame, { gap = Theme.Spacing.md })

	local hero = Components.card(frame, {
		name = "Hero",
		padding = Theme.Spacing.lg,
		size = UDim2.new(1, 0, 0, 116),
		layoutOrder = 0,
	})

	local indicator = Components.create("Frame", {
		Name = "Indicator",
		BackgroundColor3 = palette.textMuted,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(52, 52),
		parent = hero,
	})

	Components.corner(indicator, 0.5)

	local ring = Components.stroke(indicator, palette.textMuted, 1.5, 0.3)

	local icon = Icons.create(indicator, "recorder", {
		size = 24,
		color = palette.textMuted,
		anchorPoint = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
	})

	local title = Components.label(hero, {
		text = "Idle",
		font = Theme.Font.display,
		textSize = Theme.Text.title,
		color = palette.text,
		position = UDim2.fromOffset(74, 20),
		size = UDim2.new(1, -360, 0, 24),
	})

	local subtitle = Components.label(hero, {
		text = "No active session",
		font = Theme.Font.body,
		textSize = Theme.Text.caption,
		color = palette.textMuted,
		position = UDim2.fromOffset(74, 46),
		size = UDim2.new(1, -360, 0, 16),
	})

	local controls = Components.create("Frame", {
		Name = "Controls",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(340, 36),
		parent = hero,
	})

	Components.list(controls, {
		direction = Enum.FillDirection.Horizontal,
		horizontal = Enum.HorizontalAlignment.Right,
		vertical = Enum.VerticalAlignment.Center,
		gap = Theme.Spacing.sm,
	})

	local function action(text, command, variant, order)
		Components.button(controls, {
			text = text,
			variant = variant,
			size = UDim2.fromOffset(80, 36),
			layoutOrder = order,
		}, function()
			local ok, err = context.commandBus:execute(command)

			if not ok then
				context.logger:warn("Recorder", err)
			end
		end)
	end

	action("Start", "recorder.start", "primary", 1)
	action("Pause", "recorder.pause", "secondary", 2)
	action("Resume", "recorder.resume", "secondary", 3)
	action("Stop", "recorder.stop", "danger", 4)

	local timelineCard = Components.card(frame, {
		name = "Timeline",
		padding = Theme.Spacing.md,
		gap = Theme.Spacing.sm,
		size = UDim2.new(1, 0, 1, -128),
		layoutOrder = 1,
	})

	Components.label(timelineCard, {
		text = "Timeline",
		font = Theme.Font.medium,
		textSize = Theme.Text.label,
		color = palette.textSecondary,
		size = UDim2.new(1, 0, 0, 16),
		layoutOrder = 0,
	})

	local scroll = Components.create("ScrollingFrame", {
		Name = "Events",
		Size = UDim2.new(1, 0, 1, -24),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = palette.borderStrong,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		parent = timelineCard,
	})

	Components.list(scroll, { gap = 2 })

	local maid = Maid.new()
	local counter = 0

	local function append(entry)
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
			Name = "Event",
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundColor3 = palette.surfaceAlt,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			LayoutOrder = -counter,
			parent = scroll,
		})

		Components.corner(row, Theme.Radius.sm)

		local bar = Components.create("Frame", {
			Name = "Bar",
			BackgroundColor3 = levelColor,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(0, 3, 0.6, 0),
			parent = row,
		})

		Components.corner(bar, Theme.Radius.pill)

		Components.label(row, {
			text = ("%7.2fs"):format(entry.timestamp or 0),
			font = Theme.Font.mono,
			textSize = Theme.Text.micro,
			color = palette.textFaint,
			position = UDim2.fromOffset(12, 0),
			size = UDim2.fromOffset(66, 22),
		})

		Components.label(row, {
			text = ("%s  %s"):format(string.upper(entry.tag), entry.message),
			font = Theme.Font.mono,
			textSize = Theme.Text.micro,
			color = palette.textSecondary,
			truncate = Enum.TextTruncate.AtEnd,
			position = UDim2.fromOffset(82, 0),
			size = UDim2.new(1, -90, 1, 0),
		})
	end

	maid:Add(context.logger.Emitted:Connect(append))

	local recordedTypes = {
		"movement.sample",
		"interaction.completed",
		"world.entity_added",
		"world.entity_removed",
		"inventory.changed",
		"semantic.action",
		"workflow.state_changed",
		"workflow.plan_updated",
		"navigation.started",
		"navigation.path_computed",
		"navigation.completed",
		"snapshot.captured",
	}
	for _, eventType in ipairs(recordedTypes) do
		maid:Add(context.eventBus:on(eventType, function(data)
			local recorder = context.recorder
			if recorder and recorder.status == "running" then
				local message = data.target or data.name or data.path or data.kind or data.state
				if eventType == "inventory.changed" and data.before and data.after then
					message = ("%d → %d items"):format(data.before, data.after)
				elseif eventType == "semantic.action" and data.kind then
					message = data.kind .. (data.target and (" · " .. tostring(data.target)) or "")
				elseif eventType == "workflow.state_changed" and data.state then
					message = data.previousState and (data.previousState .. " → " .. data.state) or data.state
				elseif eventType == "navigation.path_computed" and data.pathLength then
					message = ("%.1f studs · %d waypoints"):format(data.pathLength, data.waypoints or 0)
				elseif eventType == "navigation.completed" and data.success ~= nil then
					message = data.success and "path ready" or (data.reason or "failed")
				elseif eventType == "snapshot.captured" and data.world then
					message = ("%d entities · %d items"):format(
						data.world.entityCount or 0,
						data.inventory and data.inventory.count or 0
					)
				end
				append({ timestamp = os.clock() - recorder.startedAt, tag = eventType, message = message or "observed", level = 20 })
			end
		end))
	end

	local function setStatus(status)
		local color = STATUS_COLORS[status] or palette.textMuted

		title.Text = STATUS_LABEL[status] or status
		title.TextColor3 = palette.text
		subtitle.Text = status == "running"
			and ("Capturing · %d events"):format(context.uiState:get("eventCount", 0))
			or "No active session"

		indicator.BackgroundColor3 = color
		ring.Color = color
		ring.Transparency = 0.2

		for _, child in ipairs(icon:GetChildren()) do
			if child:IsA("Frame") then
				local childStroke = child:FindFirstChild("UIStroke")
				if childStroke then
					childStroke.Color = color
				else
					child.BackgroundColor3 = color
				end
			end
		end

		Motion.tween(indicator, Theme.Motion.easeOut, { BackgroundTransparency = status == "running" and 0.7 or 0.82 })
	end

	maid:Add(context.uiState.ChangedKey:Connect(function(key)
		if key == "recorderStatus" then
			setStatus(context.uiState:get("recorderStatus", "idle"))
		elseif key == "eventCount" then
			setStatus(context.uiState:get("recorderStatus", "idle"))
		end
	end))

	if frame.Destroying then
		maid:Add(frame.Destroying:Connect(function()
			maid:Destroy()
		end))
	end

	setStatus(context.uiState:get("recorderStatus", "idle"))

	local function refresh()
		setStatus(context.uiState:get("recorderStatus", "idle"))
	end

	return {
		frame = frame,
		refresh = refresh,
	}
end

return RecorderPage
