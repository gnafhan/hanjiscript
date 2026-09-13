local require = ...

local Theme = require("ui.Theme")

local Icons = {}

local function part(parent, opts)
	local frame = Instance.new("Frame")
	frame.Name = opts.name or "Part"
	frame.BackgroundColor3 = opts.color
	frame.BackgroundTransparency = opts.transparency or 0
	frame.BorderSizePixel = 0
	frame.AnchorPoint = opts.anchor or Vector2.new(0, 0)
	frame.Position = opts.position or UDim2.fromOffset(0, 0)
	frame.Size = opts.size or UDim2.fromOffset(2, 2)
	frame.Rotation = opts.rotation or 0
	frame.ZIndex = opts.zIndex or 1
	frame.Parent = parent

	if opts.radius then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(opts.radius, 0)
		corner.Parent = frame
	end

	if opts.stroke then
		local stroke = Instance.new("UIStroke")
		stroke.Color = opts.color
		stroke.Thickness = opts.stroke
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = frame
	end

	return frame
end

local GLYPHS = {}

function GLYPHS.dashboard(container, size, color)
	local gap = math.max(1.5, size * 0.14)
	local cell = (size - gap) / 2
	local r = 1

	part(container, { color = color, size = UDim2.fromOffset(cell, cell), position = UDim2.fromOffset(0, 0), radius = r })
	part(container, { color = color, size = UDim2.fromOffset(cell, cell), position = UDim2.fromOffset(cell + gap, 0), radius = r })
	part(container, { color = color, size = UDim2.fromOffset(cell, cell), position = UDim2.fromOffset(0, cell + gap), radius = r })
	part(container, { color = color, size = UDim2.fromOffset(cell, cell), position = UDim2.fromOffset(cell + gap, cell + gap), radius = r })
end

function GLYPHS.inspector(container, size, color)
	local diameter = size * 0.7

	part(container, {
		color = color,
		size = UDim2.fromOffset(diameter, diameter),
		position = UDim2.fromOffset(0, 0),
		radius = 0.5,
		stroke = math.max(1.5, size * 0.1),
		transparency = 1,
	})

	part(container, {
		color = color,
		anchor = Vector2.new(0.5, 0.5),
		size = UDim2.fromOffset(math.max(2, size * 0.34), math.max(1.6, size * 0.11)),
		position = UDim2.fromOffset(size * 0.66, size * 0.66),
		rotation = 45,
		radius = 0.5,
	})
end

function GLYPHS.recorder(container, size, color)
	local ring = size * 0.82
	local dot = size * 0.34

	part(container, {
		color = color,
		size = UDim2.fromOffset(ring, ring),
		position = UDim2.fromOffset((size - ring) / 2, (size - ring) / 2),
		radius = 0.5,
		stroke = math.max(1.5, size * 0.1),
		transparency = 1,
	})

	part(container, {
		color = color,
		size = UDim2.fromOffset(dot, dot),
		position = UDim2.fromOffset((size - dot) / 2, (size - dot) / 2),
		radius = 0.5,
	})
end

function GLYPHS.settings(container, size, color)
	local thickness = math.max(1.5, size * 0.1)
	local knob = math.max(4, size * 0.28)

	local lines = {
		{ y = 0.18, x = 0.64 },
		{ y = 0.5, x = 0.34 },
		{ y = 0.82, x = 0.7 },
	}

	for _, line in ipairs(lines) do
		part(container, {
			color = color,
			size = UDim2.fromOffset(size, thickness),
			position = UDim2.fromOffset(0, size * line.y - thickness / 2),
			transparency = 0.25,
		})

		part(container, {
			color = color,
			size = UDim2.fromOffset(knob, knob),
			position = UDim2.fromOffset(size * line.x - knob / 2, size * line.y - knob / 2),
			radius = 0.5,
		})
	end
end

function GLYPHS.activity(container, size, color)
	local barWidth = math.max(2, size * 0.13)
	local heights = { 0.4, 0.75, 0.55, 0.95, 0.62 }

	for index, ratio in ipairs(heights) do
		local height = size * ratio
		part(container, {
			color = color,
			anchor = Vector2.new(0.5, 1),
			size = UDim2.fromOffset(barWidth, height),
			position = UDim2.fromOffset(size * (index / (#heights + 1)), size),
			radius = 0.5,
		})
	end
end

function GLYPHS.close(container, size, color)
	local length = size * 0.8
	local thickness = math.max(1.6, size * 0.11)

	part(container, {
		color = color,
		anchor = Vector2.new(0.5, 0.5),
		size = UDim2.fromOffset(length, thickness),
		position = UDim2.fromOffset(size / 2, size / 2),
		rotation = 45,
		radius = 0.5,
	})

	part(container, {
		color = color,
		anchor = Vector2.new(0.5, 0.5),
		size = UDim2.fromOffset(length, thickness),
		position = UDim2.fromOffset(size / 2, size / 2),
		rotation = -45,
		radius = 0.5,
	})
end

function GLYPHS.minimize(container, size, color)
	part(container, {
		color = color,
		anchor = Vector2.new(0.5, 0.5),
		size = UDim2.fromOffset(size * 0.8, math.max(1.6, size * 0.11)),
		position = UDim2.fromOffset(size / 2, size / 2),
		radius = 0.5,
	})
end

function GLYPHS.plus(container, size, color)
	local thickness = math.max(1.6, size * 0.11)
	part(container, {
		color = color,
		anchor = Vector2.new(0.5, 0.5),
		size = UDim2.fromOffset(size * 0.72, thickness),
		position = UDim2.fromOffset(size / 2, size / 2),
		radius = 0.5,
	})
	part(container, {
		color = color,
		anchor = Vector2.new(0.5, 0.5),
		size = UDim2.fromOffset(thickness, size * 0.72),
		position = UDim2.fromOffset(size / 2, size / 2),
		radius = 0.5,
	})
end

function GLYPHS.minus(container, size, color)
	local thickness = math.max(1.6, size * 0.11)
	part(container, {
		color = color,
		anchor = Vector2.new(0.5, 0.5),
		size = UDim2.fromOffset(size * 0.72, thickness),
		position = UDim2.fromOffset(size / 2, size / 2),
		radius = 0.5,
	})
end

function GLYPHS.chevron(container, size, color)
	local thickness = math.max(1.6, size * 0.12)

	part(container, {
		color = color,
		anchor = Vector2.new(0.5, 0.5),
		size = UDim2.fromOffset(math.max(2, size * 0.34), thickness),
		position = UDim2.fromOffset(size * 0.38, size * 0.42),
		rotation = 45,
		radius = 0.5,
	})

	part(container, {
		color = color,
		anchor = Vector2.new(0.5, 0.5),
		size = UDim2.fromOffset(math.max(2, size * 0.34), thickness),
		position = UDim2.fromOffset(size * 0.38, size * 0.58),
		rotation = -45,
		radius = 0.5,
	})
end

function GLYPHS.check(container, size, color)
	local thickness = math.max(1.6, size * 0.12)

	part(container, {
		color = color,
		anchor = Vector2.new(0.5, 0.5),
		size = UDim2.fromOffset(size * 0.36, thickness),
		position = UDim2.fromOffset(size * 0.33, size * 0.6),
		rotation = 45,
		radius = 0.5,
	})

	part(container, {
		color = color,
		anchor = Vector2.new(0.5, 0.5),
		size = UDim2.fromOffset(size * 0.52, thickness),
		position = UDim2.fromOffset(size * 0.63, size * 0.45),
		rotation = -45,
		radius = 0.5,
	})
end

function GLYPHS.power(container, size, color)
	local diameter = size * 0.78

	part(container, {
		color = color,
		size = UDim2.fromOffset(diameter, diameter),
		position = UDim2.fromOffset((size - diameter) / 2, (size - diameter) / 2 + size * 0.06),
		radius = 0.5,
		stroke = math.max(1.5, size * 0.1),
		transparency = 1,
	})

	part(container, {
		color = color,
		anchor = Vector2.new(0.5, 0),
		size = UDim2.fromOffset(math.max(1.6, size * 0.11), size * 0.34),
		position = UDim2.fromOffset(size / 2, 0),
		radius = 0.5,
	})
end

function GLYPHS.dot(container, size, color)
	local diameter = size * 0.5

	part(container, {
		color = color,
		size = UDim2.fromOffset(diameter, diameter),
		position = UDim2.fromOffset((size - diameter) / 2, (size - diameter) / 2),
		radius = 0.5,
	})
end

function Icons.create(parent, name, opts)
	opts = opts or {}

	local size = opts.size or 16
	local color = opts.color or Theme.Dark.text

	local container = Instance.new("Frame")
	container.Name = "Icon_" .. tostring(name)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Size = UDim2.fromOffset(size, size)
	container.Position = opts.position or UDim2.fromOffset(0, 0)
	container.AnchorPoint = opts.anchorPoint or Vector2.new(0, 0)
	container.LayoutOrder = opts.layoutOrder or 0
	container.ZIndex = opts.zIndex or 1
	container.Parent = parent

	local glyph = GLYPHS[name]

	if glyph then
		glyph(container, size, color)
	end

	return container
end

Icons.Glyphs = GLYPHS

return Icons
