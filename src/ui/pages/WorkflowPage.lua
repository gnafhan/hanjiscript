local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")
local Maid = require("utils.Maid")
local EventTypes = require("core.EventTypes")

local palette = Theme.Dark

local WorkflowPage = {
	id = "workflow",
	title = "Automation",
	subtitle = "Review a validated workflow plan in dry-run mode",
	icon = "activity",
	order = 4,
}

local STATUS_COLORS = {
	idle = palette.textMuted,
	running = palette.success,
	stopped = palette.textMuted,
}

local function text(value, fallback)
	if value == nil or value == "" then
		return fallback or "—"
	end
	return tostring(value)
end

function WorkflowPage.create(context, parent)
	local frame = Components.create("ScrollingFrame", {
		Name = "WorkflowPage",
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

	local hero = Components.card(frame, {
		name = "WorkflowHero",
		padding = Theme.Spacing.lg,
		size = UDim2.new(1, 0, 0, 132),
		layoutOrder = 0,
	})

	Components.label(hero, {
		text = "COLLECT AND SELL",
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		position = UDim2.fromOffset(0, 0),
		size = UDim2.new(1, -170, 0, 18),
	})

	local stateLabel = Components.label(hero, {
		text = "Find item",
		font = Theme.Font.display,
		textSize = Theme.Text.title,
		color = palette.text,
		position = UDim2.fromOffset(0, 24),
		size = UDim2.new(1, -170, 0, 24),
	})

	local modeLabel = Components.label(hero, {
		text = "Observation only · no game actions are executed",
		font = Theme.Font.body,
		textSize = Theme.Text.caption,
		color = palette.textMuted,
		position = UDim2.fromOffset(0, 50),
		size = UDim2.new(1, -170, 0, 18),
	})

	local status = Components.statusPill(hero, {
		text = "idle",
		position = UDim2.new(1, -Theme.Spacing.lg, 0, 2),
		anchorPoint = Vector2.new(1, 0),
	})

	local controls = Components.create("Frame", {
		Name = "Controls",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 1, -36),
		Size = UDim2.new(1, 0, 0, 34),
		parent = hero,
	})
	Components.list(controls, {
		direction = Enum.FillDirection.Horizontal,
		gap = Theme.Spacing.sm,
	})

	local function commandButton(label, command, variant)
		return Components.button(controls, {
			text = label,
			variant = variant,
			size = UDim2.fromOffset(104, 34),
		}, function()
			local ok, err = context.commandBus:execute(command)
			if not ok then
				context.logger:warn("Automation", err)
			end
		end)
	end

	commandButton("Start", "automation.start", "primary")
	commandButton("Advance", "automation.advance", "secondary")
	commandButton("Stop", "automation.stop", "danger")

	local pipeline = Components.card(frame, {
		name = "Pipeline",
		padding = Theme.Spacing.md,
		size = UDim2.new(1, 0, 0, 106),
		layoutOrder = 1,
	})

	Components.label(pipeline, {
		text = "WORKFLOW PIPELINE",
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		size = UDim2.new(1, 0, 0, 18),
	})

	local steps = Components.create("Frame", {
		Name = "Steps",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 48),
		parent = pipeline,
	})
	Components.list(steps, {
		direction = Enum.FillDirection.Horizontal,
		vertical = Enum.VerticalAlignment.Center,
		gap = Theme.Spacing.xs,
	})

	local runner = context.workflowRunner
	local definition = runner and runner.definition or { states = {} }
	local stateOrder = { "find_item", "move_to_item", "pickup", "check_inventory", "move_to_seller", "sell" }
	local stepLabels = {}
	for index, stateId in ipairs(stateOrder) do
		local definitionState = definition.states[stateId] or {}
		local chip = Components.create("Frame", {
			Name = "Step_" .. stateId,
			BackgroundColor3 = palette.surfaceAlt,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Size = UDim2.new(1 / #stateOrder, -5, 0, 42),
			LayoutOrder = index,
			parent = steps,
		})
		Components.corner(chip, Theme.Radius.sm)
		Components.stroke(chip, palette.border, 1, 0.2)
		local label = Components.label(chip, {
			text = definitionState.label or stateId,
			font = Theme.Font.medium,
			textSize = Theme.Text.micro,
			color = palette.textMuted,
			align = Enum.TextXAlignment.Center,
			wrapped = true,
			size = UDim2.fromScale(1, 1),
		})
		stepLabels[stateId] = { frame = chip, label = label }
	end

	local planCard = Components.card(frame, {
		name = "Plan",
		padding = Theme.Spacing.lg,
		size = UDim2.new(1, 0, 0, 214),
		layoutOrder = 2,
	})

	Components.label(planCard, {
		text = "NEXT VALIDATED STEP",
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		size = UDim2.new(1, 0, 0, 18),
	})

	local actionLabel = Components.label(planCard, {
		text = "Waiting",
		font = Theme.Font.title,
		textSize = Theme.Text.subtitle,
		color = palette.text,
		position = UDim2.fromOffset(0, 25),
		size = UDim2.new(1, 0, 0, 20),
	})

	local targetLabel = Components.label(planCard, {
		text = "Target  —",
		font = Theme.Font.mono,
		textSize = Theme.Text.caption,
		color = palette.info,
		position = UDim2.fromOffset(0, 53),
		size = UDim2.new(1, 0, 0, 18),
		truncate = Enum.TextTruncate.AtEnd,
	})

	local reasonLabel = Components.label(planCard, {
		text = "Start the workflow to generate a plan from the live WorldModel.",
		font = Theme.Font.body,
		textSize = Theme.Text.caption,
		color = palette.textMuted,
		position = UDim2.fromOffset(0, 82),
		size = UDim2.new(1, 0, 0, 36),
		wrapped = true,
	})

	local previewLabel = Components.label(planCard, {
		text = "Preview  —",
		font = Theme.Font.mono,
		textSize = Theme.Text.micro,
		color = palette.info,
		position = UDim2.fromOffset(0, 132),
		size = UDim2.new(1, 0, 0, 18),
		truncate = Enum.TextTruncate.AtEnd,
	})

	local evidenceLabel = Components.label(planCard, {
		text = "Evidence  —",
		font = Theme.Font.mono,
		textSize = Theme.Text.micro,
		color = palette.textFaint,
		position = UDim2.fromOffset(0, 160),
		size = UDim2.new(1, 0, 0, 18),
		truncate = Enum.TextTruncate.AtEnd,
	})

	local safetyLabel = Components.label(planCard, {
		text = "Guard  —",
		font = Theme.Font.mono,
		textSize = Theme.Text.micro,
		color = palette.textFaint,
		position = UDim2.fromOffset(0, 184),
		size = UDim2.new(1, 0, 0, 18),
		truncate = Enum.TextTruncate.AtEnd,
	})

	local maid = Maid.new()

	local function render()
		local snapshot = runner and runner:getSnapshot() or {}
		local machineState = snapshot.state or "find_item"
		local definitionState = definition.states[machineState] or {}
		local isRunning = snapshot.running == true
		local plan = snapshot.plan or {}
		local target = plan.target

		stateLabel.Text = definitionState.label or machineState
		status.set(isRunning and "running" or "idle", isRunning and palette.success or palette.textMuted)
		modeLabel.Text = snapshot.dryRun == true
			and "Observation only · no game actions are executed"
			or "Live mode"
		actionLabel.Text = plan.action or "Waiting"
		targetLabel.Text = "Target  " .. (target and (target.name or target.path) or "—")
		reasonLabel.Text = plan.reason or "Start the workflow to generate a plan from the live WorldModel."
		local navigation = plan.navigation
		local interaction = plan.interaction
		local distance = navigation and navigation.distance
		local actionCount = interaction and interaction.actions and #interaction.actions or 0
		previewLabel.Text = distance
			and ("Preview  %.1f studs · %d interaction(s)"):format(distance, actionCount)
			or "Preview  unavailable until a target is selected"
		local observation = snapshot.lastObservation
		evidenceLabel.Text = "Evidence  " .. (observation and text(observation.type, "observed") or "—")
		local limits = snapshot.limits or {}
		safetyLabel.Text = ("Guard  %d/%d cycles · %.0f/%.0fs runtime"):format(
			snapshot.cycleCount or 0,
			limits.maxCycles or 0,
			snapshot.runtime or 0,
			limits.maxRuntime or 0
		)

		for stateId, step in pairs(stepLabels) do
			local active = stateId == machineState
			step.frame.BackgroundColor3 = active and palette.accentSoft or palette.surfaceAlt
			step.frame.BackgroundTransparency = active and 0 or 0.35
			step.label.TextColor3 = active and palette.text or palette.textMuted
		end
	end

	maid:Add(context.eventBus:on(EventTypes.WorkflowStateChanged, render))
	maid:Add(context.eventBus:on(EventTypes.WorkflowPlanUpdated, render))
	maid:Add(context.eventBus:on(EventTypes.SemanticAction, render))
	maid:Add(frame.Destroying:Connect(function()
		maid:Destroy()
	end))

	render()

	return {
		frame = frame,
		refresh = render,
	}
end

return WorkflowPage
