local require = ...

local Theme = require("ui.Theme")
local Motion = require("ui.Motion")
local Icons = require("ui.Icons")

local Components = {}
local palette = Theme.Dark

local FRAME_OVERRIDES = {
	Name = true,
	Position = true,
	Size = true,
	AnchorPoint = true,
	Visible = true,
	ZIndex = true,
	LayoutOrder = true,
	AutomaticSize = true,
	BackgroundColor3 = true,
	BackgroundTransparency = true,
	BorderSizePixel = true,
	ClipsDescendants = true,
}

local TEXT_OVERRIDES = {
	Name = true,
	Position = true,
	Size = true,
	AnchorPoint = true,
	Visible = true,
	ZIndex = true,
	LayoutOrder = true,
	AutomaticSize = true,
	BackgroundColor3 = true,
	BackgroundTransparency = true,
	BorderSizePixel = true,
	Text = true,
	Font = true,
	TextSize = true,
	TextColor3 = true,
	TextXAlignment = true,
	TextYAlignment = true,
	TextWrapped = true,
	TextTruncate = true,
	RichText = true,
	TextScaled = true,
}

local function applyOverrides(resolved, props, allowed)
	for key, value in pairs(props) do
		if allowed[key] then
			resolved[key] = value
		end
	end
end

local function create(className, props)
	local instance = Instance.new(className)
	props = props or {}

	for key, value in pairs(props) do
		if key ~= "parent" and key ~= "children" then
			instance[key] = value
		end
	end

	for _, child in ipairs(props.children or {}) do
		child.Parent = instance
	end

	if props.parent then
		instance.Parent = props.parent
	end

	return instance
end

Components.create = create

local function corner(parent, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius or Theme.Radius.md),
		parent = parent,
	})
end

Components.corner = corner

function Components.stroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color or palette.border,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		parent = parent,
	})
end

function Components.gradient(parent, colorSequence, rotation, transparency)
	return create("UIGradient", {
		Color = colorSequence,
		Rotation = rotation or 90,
		Transparency = transparency,
		parent = parent,
	})
end

function Components.padding(parent, amount)
	local value = amount or Theme.Spacing.md

	if type(value) == "number" then
		value = { top = value, bottom = value, left = value, right = value }
	end

	return create("UIPadding", {
		PaddingTop = UDim.new(0, value.top or 0),
		PaddingBottom = UDim.new(0, value.bottom or 0),
		PaddingLeft = UDim.new(0, value.left or 0),
		PaddingRight = UDim.new(0, value.right or 0),
		parent = parent,
	})
end

function Components.list(parent, props)
	props = props or {}

	return create("UIListLayout", {
		FillDirection = props.direction or Enum.FillDirection.Vertical,
		HorizontalAlignment = props.horizontal or Enum.HorizontalAlignment.Left,
		VerticalAlignment = props.vertical or Enum.VerticalAlignment.Top,
		SortOrder = props.sortOrder or Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, props.gap or Theme.Spacing.sm),
		parent = parent,
	})
end

function Components.grid(parent, props)
	props = props or {}

	return create("UIGridLayout", {
		CellSize = props.cellSize or UDim2.fromOffset(160, 96),
		CellPadding = props.cellPadding or UDim2.fromOffset(10, 10),
		SortOrder = props.sortOrder or Enum.SortOrder.LayoutOrder,
		FillDirectionMaxCells = props.maxCells or 0,
		parent = parent,
	})
end

function Components.label(parent, props)
	props = props or {}

	local resolved = {
		Name = props.name or "Label",
		Text = props.text or "",
		Font = props.font or Theme.Font.body,
		TextSize = props.textSize or Theme.Text.body,
		TextColor3 = props.color or palette.text,
		TextXAlignment = props.align or Enum.TextXAlignment.Left,
		TextYAlignment = props.verticalAlign or Enum.TextYAlignment.Center,
		TextWrapped = props.wrapped == true,
		TextTruncate = props.truncate or Enum.TextTruncate.None,
		RichText = props.rich == true,
		BackgroundTransparency = props.backgroundTransparency or 1,
		BackgroundColor3 = props.background or palette.surface,
		BorderSizePixel = 0,
		Size = props.size or UDim2.new(1, 0, 0, props.height or 18),
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.None,
		LayoutOrder = props.layoutOrder or 0,
		Position = props.position or UDim2.fromScale(0, 0),
		AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
	}

	applyOverrides(resolved, props, TEXT_OVERRIDES)
	resolved.parent = parent

	return create("TextLabel", resolved)
end

Components.text = Components.label

function Components.card(parent, props)
	props = props or {}

	local resolved = {
		Name = props.name or "Card",
		BackgroundColor3 = props.background or palette.surface,
		BackgroundTransparency = props.transparency or 0,
		BorderSizePixel = 0,
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position or UDim2.fromScale(0, 0),
		AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.None,
		LayoutOrder = props.layoutOrder or 0,
		ClipsDescendants = props.clip == true,
	}

	applyOverrides(resolved, props, FRAME_OVERRIDES)
	resolved.parent = parent

	local card = create("Frame", resolved)
	corner(card, props.radius or Theme.Radius.lg)

	if props.stroke ~= false then
		Components.stroke(card, props.strokeColor or palette.border)
	end

	if props.padding then
		Components.padding(card, props.padding)
	end

	if props.gap then
		Components.list(card, { gap = props.gap })
	end

	return card
end

local BUTTON_VARIANTS = {
	primary = {
		background = palette.accent,
		hover = palette.accentHover,
		text = Color3.fromRGB(250, 250, 255),
		stroke = palette.accent,
		ripple = Color3.fromRGB(255, 255, 255),
	},
	secondary = {
		background = palette.surfaceAlt,
		hover = palette.surfaceHover,
		text = palette.text,
		stroke = palette.border,
		ripple = palette.accent,
	},
	ghost = {
		background = palette.surface,
		hover = palette.surfaceHover,
		text = palette.textSecondary,
		stroke = nil,
		ripple = palette.text,
		transparent = true,
	},
	danger = {
		background = Color3.fromRGB(84, 33, 40),
		hover = Color3.fromRGB(120, 45, 55),
		text = Color3.fromRGB(255, 205, 205),
		stroke = Color3.fromRGB(150, 60, 70),
		ripple = palette.danger,
	},
}

function Components.button(parent, props, onClick)
	props = props or {}

	local variant = BUTTON_VARIANTS[props.variant or "secondary"]
	local background = props.background or variant.background
	local hover = props.hover or variant.hover
	local textColor = props.color or variant.text

	local resolved = {
		Name = props.name or "Button",
		BackgroundColor3 = background,
		BackgroundTransparency = variant.transparent and 1 or 0,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Size = props.size or UDim2.new(1, 0, 0, props.height or 32),
		Position = props.position or UDim2.fromScale(0, 0),
		AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
		LayoutOrder = props.layoutOrder or 0,
		Text = "",
		TextTransparency = 1,
	}

	applyOverrides(resolved, props, { Size = true, Position = true, LayoutOrder = true, Name = true, Visible = true, ZIndex = true, AnchorPoint = true })
	resolved.parent = parent

	local button = create("TextButton", resolved)
	corner(button, props.radius or Theme.Radius.md)

	if variant.stroke then
		Components.stroke(button, props.strokeColor or variant.stroke)
	end

	local content = create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		parent = button,
	})

	Components.list(content, {
		direction = Enum.FillDirection.Horizontal,
		horizontal = Enum.HorizontalAlignment.Center,
		vertical = Enum.VerticalAlignment.Center,
		gap = props.iconGap or 7,
	})

	if props.icon then
		Icons.create(content, props.icon, { size = props.iconSize or 15, color = textColor })
	end

	Components.label(content, {
		text = props.text or "Button",
		font = props.font or Theme.Font.medium,
		textSize = props.textSize or Theme.Text.label,
		color = textColor,
		align = Enum.TextXAlignment.Center,
		size = UDim2.new(0, 0, 1, 0),
		automaticSize = Enum.AutomaticSize.X,
	})

	Motion.hover(button, { BackgroundColor3 = hover }, { BackgroundColor3 = background })
	Motion.press(button)
	Motion.ripple(button, variant.ripple)

	if onClick then
		button.MouseButton1Click:Connect(onClick)
	end

	return button
end

function Components.iconButton(parent, props, onClick)
	props = props or {}

	local size = props.size or 30
	local variant = props.variant or "ghost"

	local button = Components.button(parent, {
		size = UDim2.fromOffset(size, size),
		position = props.position,
		layoutOrder = props.layoutOrder,
		anchorPoint = props.anchorPoint,
		variant = variant,
		name = props.name,
		radius = props.radius or Theme.Radius.md,
		icon = props.icon,
		iconSize = props.iconSize or size * 0.52,
		text = "",
		iconGap = 0,
	}, onClick)

	local content = button:FindFirstChild("Content")

	if content then
		local label = content:FindFirstChild("Label")

		if label then
			label.Text = ""
			label.Size = UDim2.fromOffset(0, 0)
		end
	end

	return button
end

function Components.statusPill(parent, props)
	props = props or {}

	local frame = create("Frame", {
		Name = props.name or "StatusPill",
		BackgroundColor3 = props.background or palette.surfaceAlt,
		BorderSizePixel = 0,
		Size = props.size or UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = props.position or UDim2.fromScale(0, 0),
		AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
		LayoutOrder = props.layoutOrder or 0,
		parent = parent,
	})

	corner(frame, Theme.Radius.pill)
	Components.stroke(frame, props.strokeColor or palette.border)
	Components.padding(frame, { left = 10, right = 12, top = 3, bottom = 3 })

	Components.list(frame, {
		direction = Enum.FillDirection.Horizontal,
		vertical = Enum.VerticalAlignment.Center,
		gap = 7,
	})

	local dot = create("Frame", {
		Name = "Dot",
		BackgroundColor3 = props.dotColor or palette.textMuted,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(7, 7),
		LayoutOrder = 0,
		parent = frame,
	})

	corner(dot, 0.5)

	local label = Components.label(frame, {
		name = "Text",
		text = props.text or "idle",
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = props.color or palette.textSecondary,
		size = UDim2.new(0, 0, 1, 0),
		automaticSize = Enum.AutomaticSize.X,
		layoutOrder = 1,
	})

	return {
		frame = frame,
		set = function(text, color, dotColor)
			label.Text = tostring(text)
			label.TextColor3 = color or palette.textSecondary
			dot.BackgroundColor3 = dotColor or color or palette.textMuted
		end,
	}
end

function Components.toggle(parent, props, onChange)
	props = props or {}

	local value = props.value == true

	local track = create("Frame", {
		Name = props.name or "Toggle",
		BackgroundColor3 = value and palette.accent or palette.surfaceActive,
		BorderSizePixel = 0,
		Size = props.size or UDim2.fromOffset(42, 24),
		Position = props.position or UDim2.fromScale(0, 0),
		AnchorPoint = props.anchorPoint,
		LayoutOrder = props.layoutOrder or 0,
		parent = parent,
	})

	corner(track, Theme.Radius.pill)
	Components.stroke(track, palette.border)

	local knob = create("Frame", {
		Name = "Knob",
		BackgroundColor3 = Color3.fromRGB(245, 246, 250),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(18, 18),
		Position = value and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
		parent = track,
	})

	corner(knob, 0.5)

	local hit = create("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		parent = track,
	})

	local function render(animate)
		local targetTrack = value and palette.accent or palette.surfaceActive
		local targetKnob = value and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)

		if animate then
			Motion.tween(track, Theme.Motion.easeInOut, { BackgroundColor3 = targetTrack })
			Motion.tween(knob, Theme.Motion.easeInOut, { Position = targetKnob })
		else
			track.BackgroundColor3 = targetTrack
			knob.Position = targetKnob
		end
	end

	hit.MouseButton1Click:Connect(function()
		value = not value
		render(true)

		if onChange then
			onChange(value)
		end
	end)

	return {
		frame = track,
		get = function()
			return value
		end,
		set = function(next)
			value = next == true
			render(true)
		end,
	}
end

function Components.navItem(parent, props, onClick)
	props = props or {}

	local active = props.active == true

	local button = create("TextButton", {
		Name = props.id or "NavItem",
		BackgroundColor3 = active and palette.accentSoft or palette.surface,
		BackgroundTransparency = active and 0 or 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Size = UDim2.new(1, 0, 0, props.height or 38),
		LayoutOrder = props.layoutOrder or 0,
		parent = parent,
	})

	corner(button, Theme.Radius.md)

	local indicator = create("Frame", {
		Name = "Indicator",
		BackgroundColor3 = palette.accent,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 3, 0.5, 0),
		BackgroundTransparency = active and 0 or 1,
		parent = button,
	})

	corner(indicator, Theme.Radius.pill)

	local icon = Icons.create(button, props.icon or "dot", {
		size = props.iconSize or 17,
		color = active and palette.text or palette.textMuted,
		anchorPoint = Vector2.new(0, 0.5),
		position = UDim2.new(0, 14, 0.5, 0),
	})

	local label = Components.label(button, {
		text = props.text or "Item",
		font = active and Theme.Font.medium or Theme.Font.body,
		textSize = Theme.Text.label,
		color = active and palette.text or palette.textSecondary,
		position = UDim2.new(0, 40, 0, 0),
		size = UDim2.new(1, -48, 1, 0),
	})

	local function render(nextActive)
		active = nextActive
		button.BackgroundTransparency = active and 0 or 1

		Motion.tween(button, Theme.Motion.easeOut, {
			BackgroundTransparency = active and 0 or 1,
			BackgroundColor3 = active and palette.accentSoft or palette.surface,
		})

		Motion.tween(indicator, Theme.Motion.easeOut, {
			BackgroundTransparency = active and 0 or 1,
		})

		label.TextColor3 = active and palette.text or palette.textSecondary
		label.Font = active and Theme.Font.medium or Theme.Font.body

		for _, child in ipairs(icon:GetChildren()) do
			if child:IsA("Frame") then
				child.BackgroundColor3 = active and palette.text or palette.textMuted
			end
		end
	end

	Motion.hover(button, {
		BackgroundTransparency = active and 0 or 0.0,
		BackgroundColor3 = active and palette.accentSoft or palette.surfaceHover,
	}, {
		BackgroundTransparency = active and 0 or 1,
		BackgroundColor3 = active and palette.accentSoft or palette.surface,
	})

	if onClick then
		button.MouseButton1Click:Connect(onClick)
	end

	return {
		frame = button,
		setActive = render,
	}
end

function Components.row(parent, props)
	props = props or {}

	local row = create("Frame", {
		Name = props.name or "Row",
		BackgroundColor3 = props.background or palette.surface,
		BackgroundTransparency = props.transparency or 0,
		BorderSizePixel = 0,
		Size = props.size or UDim2.new(1, 0, 0, props.height or 50),
		LayoutOrder = props.layoutOrder or 0,
		parent = parent,
	})

	corner(row, props.radius or Theme.Radius.md)

	local title = Components.label(row, {
		text = props.title or "",
		font = Theme.Font.medium,
		textSize = Theme.Text.body,
		color = palette.text,
		position = UDim2.fromOffset(Theme.Spacing.md, props.subtitle and 9 or 0),
		size = UDim2.new(1, -140, 0, props.subtitle and 16 or 50),
	})

	local subtitle = nil

	if props.subtitle then
		subtitle = Components.label(row, {
			text = props.subtitle,
			font = Theme.Font.body,
			textSize = Theme.Text.caption,
			color = palette.textMuted,
			position = UDim2.fromOffset(Theme.Spacing.md, 27),
			size = UDim2.new(1, -140, 0, 14),
		})
	end

	local right = create("Frame", {
		Name = "Right",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -Theme.Spacing.md, 0.5, 0),
		Size = UDim2.fromOffset(120, 30),
		parent = row,
	})

	Components.list(right, {
		direction = Enum.FillDirection.Horizontal,
		horizontal = Enum.HorizontalAlignment.Right,
		vertical = Enum.VerticalAlignment.Center,
		gap = Theme.Spacing.sm,
	})

	return {
		frame = row,
		title = title,
		subtitle = subtitle,
		right = right,
	}
end

function Components.divider(parent, layoutOrder)
	return create("Frame", {
		Name = "Divider",
		BackgroundColor3 = palette.border,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		LayoutOrder = layoutOrder or 0,
		parent = parent,
	})
end

return Components
