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

	local allEntries = {}
	local expanded = {}
	local render
	local visibleEntries
	local searchBox

	local scanButton = Components.button(buttonRow, {
		text = "Scan tree",
		variant = "primary",
		icon = "inspector",
		size = UDim2.fromOffset(126, 34),
		layoutOrder = 1,
	})

	Components.button(buttonRow, {
		text = "Clear",
		variant = "ghost",
		icon = "close",
		size = UDim2.fromOffset(76, 34),
		layoutOrder = 2,
	}, function()
		allEntries = {}
		if searchBox then
			searchBox.Text = ""
		end
		render({})
	end)

	Components.button(buttonRow, {
		text = "Expand all",
		variant = "ghost",
		icon = "plus",
		size = UDim2.fromOffset(88, 34),
		layoutOrder = 3,
	}, function()
		for _, entry in ipairs(allEntries) do
			if entry.hasChildren then expanded[entry.path] = true end
		end
		render(visibleEntries())
	end)

	Components.button(buttonRow, {
		text = "Collapse",
		variant = "ghost",
		icon = "minus",
		size = UDim2.fromOffset(82, 34),
		layoutOrder = 4,
	}, function()
		for _, entry in ipairs(allEntries) do
			if entry.hasChildren then expanded[entry.path] = false end
		end
		render(visibleEntries())
	end)

	searchBox = Components.create("TextBox", {
		Name = "Search",
		Text = "",
		PlaceholderText = "Filter name, class, path or tag",
		PlaceholderColor3 = palette.textFaint,
		TextColor3 = palette.text,
		TextSize = Theme.Text.caption,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		BackgroundColor3 = palette.surfaceAlt,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Size = UDim2.fromOffset(200, 34),
		LayoutOrder = 5,
		parent = buttonRow,
	})
	Components.corner(searchBox, Theme.Radius.md)
	Components.stroke(searchBox, palette.border)
	Components.padding(searchBox, { left = 10, right = 10 })
	Components.applyFont(searchBox, Theme.Font.body)

	local result = Components.label(buttonRow, {
		text = "not scanned",
		font = Theme.Font.mono,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		size = UDim2.new(1, -620, 1, 0),
		layoutOrder = 6,
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
	detail.assets = detailRow("Assets", 5)
	detail.tags = detailRow("Tags", 6)
	detail.attributes = detailRow("Attributes", 7)

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
		local assets = entry.assets or {}
		local values = {}
		for _, asset in pairs(assets) do if asset and asset ~= "" then table.insert(values, tostring(asset)) end end
		for _, ref in ipairs(entry.assetRefs or {}) do
			local value = ref.kind and ref.id and (tostring(ref.kind) .. ": " .. tostring(ref.id)) or ref.id
			if value then table.insert(values, tostring(value)) end
		end
		detail.assets.Text = #values > 0 and table.concat(values, ", ") or "—"
		detail.tags.Text = entry.tags and table.concat(entry.tags, ", ") or "—"
		local attributes = {}
		for key, value in pairs(entry.attributes or {}) do
			table.insert(attributes, tostring(key) .. "=" .. tostring(value))
		end
		table.sort(attributes)
		detail.attributes.Text = #attributes > 0 and table.concat(attributes, ", ") or "—"
	end

	local function matches(entry, query)
		if query == "" then
			return true
		end

		local assetText = {}
		for _, asset in pairs(entry.assets or {}) do
			table.insert(assetText, tostring(asset))
		end
		for _, ref in ipairs(entry.assetRefs or {}) do
			table.insert(assetText, tostring(ref.id or ""))
		end

		local haystack = table.concat({
			entry.name or "",
			entry.className or "",
			entry.path or "",
			table.concat(entry.tags or {}, " "),
			table.concat(assetText, " "),
		}, " "):lower()
		return haystack:find(query, 1, true) ~= nil
	end

	local function isExpanded(entry)
		return expanded[entry.path] ~= false
	end

	function visibleEntries()
		local query = searchBox and searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "") or ""
		local keep = {}
		if query == "" then
			for index = 1, #allEntries do keep[index] = true end
		else
			for index, entry in ipairs(allEntries) do
				if matches(entry, query) then
					keep[index] = true
					local childDepth = entry.depth or 0
					for parentIndex = index - 1, 1, -1 do
						if (allEntries[parentIndex].depth or 0) < childDepth then
							keep[parentIndex] = true
							childDepth = allEntries[parentIndex].depth or 0
							if childDepth == 0 then break end
						end
					end
				end
			end
		end

		local result = {}
		local collapsed = {}
		for index, entry in ipairs(allEntries) do
			local depth = entry.depth or 0
			local hidden = false
			for parentDepth = 0, depth - 1 do
				if collapsed[parentDepth] then
					hidden = true
					break
				end
			end
			if not hidden and keep[index] then
				table.insert(result, entry)
			end
			for parentDepth = depth, #collapsed do
				collapsed[parentDepth] = nil
			end
			if entry.hasChildren then
				collapsed[depth] = not isExpanded(entry)
			end
		end
		return result
	end

	function render(entries)
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

			local indent = math.min((entry.depth or 0) * 14, 98)
			local caret = Components.create("TextButton", {
				Name = "Caret",
				Text = entry.hasChildren and (isExpanded(entry) and "⌄" or "›") or "·",
				TextColor3 = palette.textFaint,
				TextSize = Theme.Text.micro,
				FontFace = Theme.Font.mono,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Size = UDim2.fromOffset(28, 30),
				Position = UDim2.fromOffset(8 + indent, 0),
				parent = row,
			})
			caret.MouseButton1Click:Connect(function()
				if entry.hasChildren then
					expanded[entry.path] = not isExpanded(entry)
					render(visibleEntries())
				end
			end)

			Components.label(row, {
				text = "",
				font = Theme.Font.mono,
				textSize = Theme.Text.micro,
				color = palette.textFaint,
				size = UDim2.fromOffset(0, 0),
			})

			Components.label(row, {
				text = entry.name or instance.Name,
				font = Theme.Font.medium,
				textSize = Theme.Text.caption,
				color = palette.text,
				truncate = Enum.TextTruncate.AtEnd,
				position = UDim2.fromOffset(28 + indent, 0),
				size = UDim2.new(1, -(172 + indent), 1, 0),
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

		result.Text = ("%d / %d visible nodes"):format(#entries, #allEntries)
	end

	local function applyFilter()
		render(visibleEntries())
	end

	scanButton.MouseButton1Click:Connect(function()
		allEntries = context.world and context.world:tree(600) or scanWorkspace()
		expanded = {}
		applyFilter()
		context.logger:info("Inspector", ("scanned %d instances"):format(#allEntries))
	end)

	searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)

	local function refresh() end

	render({})

	return {
		frame = frame,
		refresh = refresh,
	}
end

return InspectorPage
