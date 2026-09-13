local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")
local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")

local palette = Theme.Dark

local ReplayPage = {
	id = "replay",
	title = "Replay",
	subtitle = "Review a recorded session deterministically",
	icon = "recorder",
	order = 5,
}

local function formatTime(value)
	local seconds = math.max(0, tonumber(value) or 0)
	return ("%02d:%05.2f"):format(math.floor(seconds / 60), seconds % 60)
end

function ReplayPage.create(context, parent)
	local frame = Components.create("ScrollingFrame", {
		Name = "ReplayPage",
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

	local replay = context.replay
	local hero = Components.card(frame, {
		name = "ReplayHero",
		padding = Theme.Spacing.lg,
		size = UDim2.new(1, 0, 0, 132),
		layoutOrder = 0,
	})

	local title = Components.label(hero, {
		text = "No session loaded",
		font = Theme.Font.display,
		textSize = Theme.Text.title,
		color = palette.text,
		position = UDim2.fromOffset(0, 0),
		size = UDim2.new(1, -250, 0, 24),
	})
	local subtitle = Components.label(hero, {
		text = "Stop a recording to prepare it for replay.",
		font = Theme.Font.body,
		textSize = Theme.Text.caption,
		color = palette.textMuted,
		position = UDim2.fromOffset(0, 28),
		size = UDim2.new(1, -250, 0, 18),
		truncate = Enum.TextTruncate.AtEnd,
	})

	local controls = Components.create("Frame", {
		Name = "Controls",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 1, -34),
		Size = UDim2.new(1, 0, 0, 32),
		parent = hero,
	})
	Components.list(controls, { direction = Enum.FillDirection.Horizontal, gap = Theme.Spacing.sm })
	local function commandButton(label, command, variant)
		return Components.button(controls, {
			text = label,
			variant = variant,
			size = UDim2.fromOffset(92, 32),
		}, function()
			local ok, err = context.commandBus:execute(command)
			if not ok then context.logger:warn("Replay", err) end
		end)
	end
	commandButton("Play", "replay.play", "primary")
	commandButton("Pause", "replay.pause", "secondary")
	commandButton("Step", "replay.step", "secondary")
	commandButton("Restart", "replay.seek", "ghost")

	local status = Components.statusPill(hero, {
		text = "empty",
		position = UDim2.new(1, -Theme.Spacing.lg, 0, 3),
		anchorPoint = Vector2.new(1, 0),
	})

	local timeline = Components.card(frame, {
		name = "Timeline",
		padding = Theme.Spacing.lg,
		size = UDim2.new(1, 0, 0, 92),
		layoutOrder = 1,
	})
	local timeLabel = Components.label(timeline, {
		text = "00:00.00 / 00:00.00",
		font = Theme.Font.mono,
		textSize = Theme.Text.caption,
		color = palette.textSecondary,
		size = UDim2.new(1, 0, 0, 18),
	})
	local track = Components.create("Frame", {
		Name = "Track",
		BackgroundColor3 = palette.surfaceAlt,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, 10),
		parent = timeline,
	})
	Components.corner(track, Theme.Radius.pill)
	local fill = Components.create("Frame", {
		Name = "Fill",
		BackgroundColor3 = palette.accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		parent = track,
	})
	Components.corner(fill, Theme.Radius.pill)

	local snapshotCard = Components.card(frame, {
		name = "ReplayState",
		padding = Theme.Spacing.lg,
		size = UDim2.new(1, 0, 0, 196),
		layoutOrder = 2,
	})
	Components.label(snapshotCard, {
		text = "RECONSTRUCTED STATE",
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		size = UDim2.new(1, 0, 0, 18),
	})
	local stateLabels = {}
	local fields = {
		{ key = "Workflow", x = 0, y = 28 },
		{ key = "Inventory", x = 0.5, y = 28 },
		{ key = "Entities", x = 0, y = 70 },
		{ key = "Last semantic", x = 0.5, y = 70 },
		{ key = "Checkpoint", x = 0, y = 112 },
	}
	for _, field in ipairs(fields) do
		local position = UDim2.new(field.x, 0, 0, field.y)
		Components.label(snapshotCard, {
			text = string.upper(field.key),
			font = Theme.Font.medium,
			textSize = Theme.Text.micro,
			color = palette.textFaint,
			position = position,
			size = UDim2.new(0.5, -10, 0, 14),
		})
		stateLabels[field.key] = Components.label(snapshotCard, {
			text = "—",
			font = Theme.Font.mono,
			textSize = Theme.Text.caption,
			color = palette.text,
			position = UDim2.new(field.x, 0, 0, field.y + 14),
			size = UDim2.new(0.5, -10, 0, 16),
			truncate = Enum.TextTruncate.AtEnd,
		})
	end

	local lastEvent = Components.label(frame, {
		text = "No replay event applied yet.",
		font = Theme.Font.mono,
		textSize = Theme.Text.micro,
		color = palette.textFaint,
		size = UDim2.new(1, 0, 0, 18),
		layoutOrder = 3,
	})

	local maid = Maid.new()
	local function render()
		local snapshot = replay and replay:getSnapshot() or {}
		local duration = snapshot.duration or 0
		local current = snapshot.currentTime or 0
		local hasSession = snapshot.sessionId ~= nil
		local ratio = duration > 0 and math.clamp(current / duration, 0, 1) or 0
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		timeLabel.Text = ("%s / %s"):format(formatTime(current), formatTime(duration))
		status.set(hasSession and (snapshot.playing and "playing" or "ready") or "empty", hasSession and palette.success or palette.textMuted)
		if hasSession then
			title.Text = "Session " .. tostring(snapshot.sessionId)
			subtitle.Text = ("%d events · %d checkpoints · deterministic read-only playback"):format(
				snapshot.eventCount or 0,
				snapshot.snapshotCount or 0
			)
		else
			title.Text = "No session loaded"
			subtitle.Text = "Stop a recording to prepare it for replay."
		end
		local state = snapshot.state or {}
		stateLabels.Workflow.Text = state.workflowState or "—"
		stateLabels.Inventory.Text = tostring(state.inventoryCount or 0) .. " items"
		stateLabels.Entities.Text = tostring(state.entityCount or 0) .. " tracked"
		local semantic = state.lastSemantic
		stateLabels["Last semantic"].Text = semantic and (semantic.kind or "observed") or "—"
		stateLabels.Checkpoint.Text = snapshot.checkpointTime ~= nil
			and formatTime(snapshot.checkpointTime)
			or "start"
	end

	maid:Add(context.eventBus:on(EventTypes.ReplayStateChanged, render))
	maid:Add(context.eventBus:on(EventTypes.ReplayEventApplied, function(event)
		lastEvent.Text = event and ("Applied  %s  at %s"):format(event.type or "event", formatTime(event.timestamp)) or "No replay event applied yet."
	end))
	maid:Add(frame.Destroying:Connect(function() maid:Destroy() end))
	render()

	return { frame = frame, refresh = render }
end

return ReplayPage
