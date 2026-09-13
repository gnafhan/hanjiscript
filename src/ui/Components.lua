local require = ...

local Theme = require("ui.Theme")

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
	RichText = true,
	TextScaled = true,
}

local function applyOverrides(resolved, props, allowed)
	allowed = allowed or TEXT_OVERRIDES

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

function Components.stroke(parent, color, thickness)
	return create("UIStroke", {
		Color = color or palette.border,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
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
		CellSize = props.cellSize or UDim2.fromOffset(120, 64),
		CellPadding = props.cellPadding or UDim2.fromOffset(8, 8),
		SortOrder = props.sortOrder or Enum.SortOrder.LayoutOrder,
		parent = parent,
	})
end

function Components.panel(parent, props)
	props = props or {}

	local resolved = {
		Name = props.name or "Panel",
		BackgroundColor3 = props.background or palette.surface,
		BackgroundTransparency = props.transparency or 0,
		BorderSizePixel = 0,
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position or UDim2.fromScale(0, 0),
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.None,
		LayoutOrder = props.layoutOrder or 0,
	}

	applyOverrides(resolved, props, FRAME_OVERRIDES)
	resolved.parent = parent

	local frame = create("Frame", resolved)

	if props.corner ~= false then
		corner(frame, props.radius)
	end

	if props.stroke ~= false then
		Components.stroke(frame, props.strokeColor)
	end

	if props.padding then
		Components.padding(frame, props.padding)
	end

	return frame
end

function Components.label(parent, props)
	props = props or {}

	local resolved = {
		Name = props.name or "Label",
		Text = props.text or "",
		Font = props.font or Theme.Font.body,
		TextSize = props.textSize or Theme.TextSize.md,
		TextColor3 = props.color or palette.text,
		TextXAlignment = props.align or Enum.TextXAlignment.Left,
		TextYAlignment = props.verticalAlign or Enum.TextYAlignment.Center,
		TextWrapped = props.wrapped == true,
		RichText = props.rich == true,
		BackgroundTransparency = props.backgroundTransparency or 1,
		BackgroundColor3 = props.background or palette.surface,
		BorderSizePixel = 0,
		Size = props.size or UDim2.new(1, 0, 0, props.height or 20),
		AutomaticSize = props.automaticSize or Enum.AutomaticSize.None,
		LayoutOrder = props.layoutOrder or 0,
		Position = props.position or UDim2.fromScale(0, 0),
	}

	applyOverrides(resolved, props)
	resolved.parent = parent

	return create("TextLabel", resolved)
end

function Components.button(parent, props, onClick)
	props = props or {}

	local resolved = {
		Name = props.name or "Button",
		Text = props.text or "Button",
		Font = props.font or Theme.Font.medium,
		TextSize = props.textSize or Theme.TextSize.sm,
		TextColor3 = props.color or palette.text,
		TextXAlignment = props.align or Enum.TextXAlignment.Center,
		BackgroundColor3 = props.background or palette.surfaceAlt,
		BackgroundTransparency = 0,
		AutoButtonColor = props.autoColor ~= false,
		BorderSizePixel = 0,
		Size = props.size or UDim2.new(1, 0, 0, props.height or 30),
		LayoutOrder = props.layoutOrder or 0,
		Position = props.position or UDim2.fromScale(0, 0),
	}

	applyOverrides(resolved, props)
	resolved.parent = parent

	local button = create("TextButton", resolved)

	if props.corner ~= false then
		corner(button, props.radius or Theme.Radius.sm)
	end

	if props.stroke ~= false then
		Components.stroke(button, props.strokeColor or palette.border)
	end

	if onClick then
		button.MouseButton1Click:Connect(onClick)
	end

	return button
end

function Components.badge(parent, props)
	props = props or {}

	local resolved = {
		Name = props.name or "Badge",
		BackgroundColor3 = props.background or palette.accentMuted,
		BorderSizePixel = 0,
		Size = props.size or UDim2.fromOffset(64, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = props.layoutOrder or 0,
		Position = props.position or UDim2.fromScale(0, 0),
	}

	applyOverrides(resolved, props, FRAME_OVERRIDES)
	resolved.parent = parent

	local badge = create("Frame", resolved)
	corner(badge, Theme.Radius.sm)

	if props.stroke ~= false then
		Components.stroke(badge, props.strokeColor or palette.border)
	end

	create("TextLabel", {
		Name = "Text",
		Text = props.text or props.Text or "idle",
		Font = Theme.Font.medium,
		TextSize = Theme.TextSize.xs,
		TextColor3 = props.color or palette.text,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		parent = badge,
	})

	return badge
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
