local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")

local palette = Theme.Dark

local InspectorPage = {
	id = "inspector",
	title = "Inspector",
	order = 2,
}

local MAX_ENTRIES = 200

local function scanWorkspace()
	local entries = {}

	if not game then
		return entries
	end

	for _, instance in ipairs(game:GetService("Workspace"):GetChildren()) do
		table.insert(entries, {
			name = instance.Name,
			className = instance.ClassName,
		})

		if #entries >= MAX_ENTRIES then
			return entries
		end
	end

	return entries
end

function InspectorPage.create(context, parent)
	local frame = Components.create("Frame", {
		Name = "InspectorPage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		parent = parent,
	})

	Components.padding(frame, Theme.Spacing.md)
	Components.list(frame, { gap = Theme.Spacing.sm })

	Components.label(frame, {
		Text = "Workspace Inspector",
		Font = Theme.Font.bold,
		TextSize = Theme.TextSize.lg,
		LayoutOrder = 0,
		parent = frame,
	})

	local toolbar = Components.create("Frame", {
		Name = "Toolbar",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		parent = frame,
	})

	Components.list(toolbar, { direction = Enum.FillDirection.Horizontal, gap = Theme.Spacing.sm })

	local result = Components.label(toolbar, {
		Name = "Result",
		Text = "not scanned",
		TextSize = Theme.TextSize.xs,
		color = palette.textMuted,
		Size = UDim2.new(1, -130, 1, 0),
		layoutOrder = 2,
		parent = toolbar,
	})

	local scroll = Components.create("ScrollingFrame", {
		Name = "Entries",
		Size = UDim2.new(1, 0, 1, -70),
		BackgroundColor3 = palette.surface,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		parent = frame,
	})

	Components.corner(scroll, Theme.Radius.sm)
	Components.padding(scroll, Theme.Spacing.sm)
	Components.list(scroll, { gap = Theme.Spacing.xs })

	local function render(entries)
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("GuiObject") and child.Name ~= "UIListLayout"
				and child.Name ~= "UIPadding" and child.Name ~= "UICorner" then
				child:Destroy()
			end
		end

		for index, entry in ipairs(entries) do
			local row = Components.label(scroll, {
				Text = ("%s  < %s >"):format(entry.name, entry.className),
				Font = Theme.Font.mono,
				TextSize = Theme.TextSize.xs,
				Size = UDim2.new(1, 0, 0, 18),
				layoutOrder = index,
				parent = scroll,
			})

			row.TextXAlignment = Enum.TextXAlignment.Left
		end
	end

	local function refresh()
		result.Text = "ready"
	end

	Components.button(toolbar, {
		Text = "Scan Workspace",
		Size = UDim2.fromOffset(120, 30),
		layoutOrder = 1,
	}, function()
		local entries = scanWorkspace()
		render(entries)
		result.Text = ("%d root children"):format(#entries)
		context.logger:info("Inspector", "workspace scanned", { count = #entries })
	end)

	Components.button(toolbar, {
		Text = "Clear",
		Size = UDim2.fromOffset(70, 30),
		layoutOrder = 0,
	}, function()
		render({})
		result.Text = "cleared"
	end)

	refresh()

	return {
		frame = frame,
		refresh = refresh,
	}
end

return InspectorPage
