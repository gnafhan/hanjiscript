local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")
local Icons = require("ui.Icons")
local Motion = require("ui.Motion")

local palette = Theme.Dark

local InspectorPage = {
	id = "inspector",
	title = "Inspector",
	subtitle = "Explore the live Workspace tree",
	icon = "inspector",
	order = 2,
}

local MAX_ENTRIES = 250

local function scanWorkspace()
	local entries = {}

	if not game then
		return entries
	end

	local workspaceService = game:GetService("Workspace")

	for _, instance in ipairs(workspaceService:GetChildren()) do
		table.insert(entries, instance)

		if #entries >= MAX_ENTRIES then
			break
		end
	end

	return entries
end

local function classBadge(parent, text, color, position)
	local badge = Components.create("Frame", {
		Name = "Badge",
		BackgroundColor3 = color,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 18),
		Position = position,
		parent = parent,
	})

	Components.corner(badge, Theme.Radius.sm)
	Components.padding(badge, { left = 8, right = 8, top = 2, bottom = 2 })

	local label = Components.label(badge, {
		text = text,
		font = Theme.Font.mono,
		textSize = Theme.Text.micro,
		color = color,
		size = UDim2.new(1, 0, 1, 0),
		automaticSize = Enum.AutomaticSize.X,
	})

	label.AutomaticSize = Enum.AutomaticSize.X
	return badge
end

function InspectorPage.create(context, parent)
	local frame = Components.create("Frame", {
		Name = "InspectorPage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		parent = parent,
	})

	Components.list(frame, { gap = Theme.Spacing.md })

	local toolbar = Components.card(frame, {
		name = "Toolbar",
		padding = { top = 8, bottom = 8, left = Theme.Spacing.md, right = Theme.Spacing.md },
		size = UDim2.new(1, 0, 0, 50),
		layoutOrder = 0,
	})

	local buttonRow = Components.create("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		parent = toolbar,
	})

	Components.list(buttonRow, {
		direction = Enum.FillDirection.Horizontal,
		vertical = Enum.VerticalAlignment.Center,
		gap = Theme.Spacing.sm,
	})

	local scanButton = Components.button(buttonRow, {
		text = "Scan Workspace",
		variant = "primary",
		icon = "inspector",
		size = UDim2.fromOffset(150, 34),
		layoutOrder = 1,
	})

	Components.button(buttonRow, {
		text = "Clear",
		variant = "ghost",
		icon = "close",
		size = UDim2.fromOffset(90, 34),
		layoutOrder = 2,
	}, function()
		render({})
	end)

	local result = Components.label(buttonRow, {
		text = "not scanned",
		font = Theme.Font.mono,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		size = UDim2.new(1, -260, 1, 0),
		layoutOrder = 3,
	})

	local main = Components.create("Frame", {
		Name = "Main",
		Size = UDim2.new(1, 0, 1, -62),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		parent = frame,
	})

	local listCard = Components.card(main, {
		name = "List",
		padding = Theme.Spacing.sm,
		size = UDim2.new(0.56, -6, 1, 0),
	})

	local detailCard = Components.card(main, {
		name = "Detail",
		padding = Theme.Spacing.lg,
		gap = Theme.Spacing.sm,
		position = UDim2.new(0.56, 6, 0, 0),
		size = UDim2.new(0.44, -6, 1, 0),
	})

	local scroll = Components.create("ScrollingFrame", {
		Name = "Entries",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = palette.borderStrong,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		parent = listCard,
	})

	Components.list(scroll, { gap = 3 })

	Components.label(detailCard, {
		text = "Selection",
		font = Theme.Font.medium,
		textSize = Theme.Text.label,
		color = palette.textSecondary,
		size = UDim2.new(1, 0, 0, 16),
		layoutOrder = 0,
	})

	local detail = {}

	local function detailRow(key, order)
		local row = Components.create("Frame", {
			Name = key,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),
			LayoutOrder = order,
			parent = detailCard,
		})

		Components.label(row, {
			text = key,
			font = Theme.Font.body,
			textSize = Theme.Text.caption,
			color = palette.textMuted,
			size = UDim2.new(0.42, 0, 1, 0),
		})

		local value = Components.label(row, {
			text = "—",
			font = Theme.Font.mono,
			textSize = Theme.Text.caption,
			color = palette.text,
			align = Enum.TextXAlignment.Right,
			position = UDim2.new(0.42, 0, 0, 0),
			size = UDim2.new(0.58, 0, 1, 0),
			truncate = Enum.TextTruncate.AtEnd,
		})

		return value
	end

	detail.name = detailRow("Name", 1)
	detail.class = detailRow("Class", 2)
	detail.path = detailRow("Path", 3)
	detail.children = detailRow("Children", 4)

	local placeholder = Components.label(detailCard, {
		text = "Select an instance from the list to inspect it.",
		font = Theme.Font.body,
		textSize = Theme.Text.caption,
		color = palette.textFaint,
		wrapped = true,
		size = UDim2.new(1, 0, 1, -140),
		layoutOrder = 20,
	})

	local selectedRow

	local function select(entry, row)
		if selectedRow and selectedRow ~= row then
			Motion.tween(selectedRow, Theme.Motion.easeOut, { BackgroundTransparency = 1 })
		end

		selectedRow = row

		if row then
			Motion.tween(row, Theme.Motion.easeOut, { BackgroundTransparency = 0 })
		end

		if not entry then
			placeholder.Visible = true
			return
		end

		placeholder.Visible = false
		local instance = entry.instance or entry
		detail.name.Text = entry.name or instance.Name
		detail.class.Text = entry.className or instance.ClassName
		detail.path.Text = entry.path or instance:GetFullName()
		detail.children.Text = tostring(#instance:GetChildren())
	end

	local function render(entries)
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end

		selectedRow = nil
		select(nil)

		for index, entry in ipairs(entries) do
			local instance = entry.instance or entry
			local row = Components.create("TextButton", {
				Name = "Entry",
				Text = "",
				BackgroundColor3 = palette.surfaceAlt,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = index,
				parent = scroll,
			})

			Components.corner(row, Theme.Radius.sm)

			Components.label(row, {
				text = tostring(index),
				font = Theme.Font.mono,
				textSize = Theme.Text.micro,
				color = palette.textFaint,
				size = UDim2.fromOffset(28, 30),
				position = UDim2.fromOffset(8, 0),
			})

			Components.label(row, {
				text = entry.name or instance.Name,
				font = Theme.Font.medium,
				textSize = Theme.Text.caption,
				color = palette.text,
				truncate = Enum.TextTruncate.AtEnd,
				position = UDim2.fromOffset(36, 0),
				size = UDim2.new(1, -180, 1, 0),
			})

			classBadge(row, entry.className or instance.ClassName, palette.accent, UDim2.new(1, -70, 0.5, -9))

			row.MouseEnter:Connect(function()
				if selectedRow ~= row then
					Motion.tween(row, Theme.Motion.easeOut, { BackgroundTransparency = 0.5 })
				end
			end)

			row.MouseLeave:Connect(function()
				if selectedRow ~= row then
					Motion.tween(row, Theme.Motion.easeOut, { BackgroundTransparency = 1 })
				end
			end)

			row.MouseButton1Click:Connect(function()
				select(entry, row)
			end)
		end

		result.Text = ("%d root children"):format(#entries)
	end

	scanButton.MouseButton1Click:Connect(function()
		local entries = context.world and context.world:list() or scanWorkspace()
		render(entries)
		context.logger:info("Inspector", ("scanned %d instances"):format(#entries))
	end)

	local function refresh() end

	render({})

	return {
		frame = frame,
		refresh = refresh,
	}
end

return InspectorPage
