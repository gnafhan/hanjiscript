local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")
local Motion = require("ui.Motion")
local Icons = require("ui.Icons")
local UIState = require("ui.UIState")
local Notifications = require("ui.Notifications")
local Maid = require("utils.Maid")

local DashboardPage = require("ui.pages.DashboardPage")
local InspectorPage = require("ui.pages.InspectorPage")
local RecorderPage = require("ui.pages.RecorderPage")
local SettingsPage = require("ui.pages.SettingsPage")

local palette = Theme.Dark
local Layout = Theme.Layout

local PAGE_MODULES = {
	DashboardPage,
	InspectorPage,
	RecorderPage,
	SettingsPage,
}

local AppUI = {}
AppUI.__index = AppUI

local function getGuiParent()
	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)

	if ok and coreGui then
		return coreGui
	end

	local players = game:GetService("Players")

	if players.LocalPlayer then
		return players.LocalPlayer:WaitForChild("PlayerGui")
	end

	return nil
end

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

function AppUI.new(context)
	local config = context.config
	local adapter = context.adapter
	local experience = context.experience or {}
	local runtime = context.runtime or {}

	local versions = context.versions or {}

	local state = UIState.new({
		visible = config and config:get("ui.startVisible", true) or true,
		minimized = false,
		activePage = "dashboard",
		recorderStatus = "idle",
		automationStatus = "idle",
		adapterId = adapter and adapter.id or "none",
		experienceName = experience.name or "Unknown Experience",
		placeId = experience.placeId or 0,
		gameId = experience.gameId or 0,
		platform = runtime.platform or "unknown",
		environment = runtime.environment or "unknown",
		eventCount = 0,
		lastLog = "ready",
		version = versions.framework or "0.1.0",
	})

	return setmetatable({
		context = context,
		state = state,
		_maid = Maid.new(),
		_pages = {},
		_pageHosts = {},
		_navItems = {},
		_mounted = false,
		_activePage = nil,
		_expandedSize = UDim2.fromOffset(Layout.windowWidth, Layout.windowHeight),
	}, AppUI)
end

function AppUI:getState()
	return self.state
end

function AppUI:notify(options)
	if self._notifications then
		return self._notifications:push(options)
	end
	return nil
end

function AppUI:_buildScreen()
	local parent = getGuiParent()

	if not parent then
		error("AppUI: unable to resolve a Gui parent (CoreGui/PlayerGui)", 2)
	end

	self._screen = Components.create("ScreenGui", {
		Name = "HanjiScript",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 50,
		parent = parent,
	})

	self._notifications = Notifications.new(self._screen)
end

function AppUI:_buildWindow()
	local shadow = Components.create("Frame", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Layout.windowWidth + 22, Layout.windowHeight + 22),
		BackgroundColor3 = palette.shadow,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 1,
		parent = self._screen,
	})

	Components.corner(shadow, Theme.Radius.xl)
	self._shadow = shadow

	local window = Components.create("CanvasGroup", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = self._expandedSize,
		BackgroundColor3 = palette.background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		GroupTransparency = 1,
		ZIndex = 2,
		parent = self._screen,
	})

	Components.corner(window, Theme.Radius.xl)
	Components.stroke(window, palette.border)
	Components.gradient(window, ColorSequence.new({
		ColorSequenceKeypoint.new(0, palette.backgroundTop),
		ColorSequenceKeypoint.new(1, palette.background),
	}), 90)

	self._window = window
end

function AppUI:_buildTopbar()
	local bar = Components.create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, Layout.topbarHeight),
		BackgroundColor3 = palette.backgroundTop,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 3,
		parent = self._window,
	})

	local logo = Components.create("Frame", {
		Name = "Logo",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = palette.accent,
		BorderSizePixel = 0,
		parent = bar,
	})

	Components.corner(logo, Theme.Radius.sm)
	Components.gradient(logo, ColorSequence.new({
		ColorSequenceKeypoint.new(0, palette.accentHover),
		ColorSequenceKeypoint.new(1, palette.accent),
	}), 45)

	Icons.create(logo, "activity", {
		size = 16,
		color = Color3.fromRGB(250, 250, 255),
		anchorPoint = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
	})

	Components.label(bar, {
		text = "HanjiScript",
		font = Theme.Font.title,
		textSize = Theme.Text.subtitle,
		color = palette.text,
		position = UDim2.new(0, 52, 0, 8),
		size = UDim2.new(1, -140, 0, 16),
	})

	Components.label(bar, {
		text = "Roblox Automation Platform",
		font = Theme.Font.body,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		position = UDim2.new(0, 52, 0, 24),
		size = UDim2.new(1, -140, 0, 14),
	})

	self._closeButton = Components.iconButton(bar, {
		name = "Close",
		icon = "close",
		iconSize = 12,
		size = 30,
		variant = "ghost",
		anchorPoint = Vector2.new(1, 0.5),
		position = UDim2.new(1, -11, 0.5, 0),
	})

	self._minimizeButton = Components.iconButton(bar, {
		name = "Minimize",
		icon = "minimize",
		iconSize = 12,
		size = 30,
		variant = "ghost",
		anchorPoint = Vector2.new(1, 0.5),
		position = UDim2.new(1, -45, 0.5, 0),
	})

	Components.divider(bar, 0).Position = UDim2.new(0, 0, 1, -1)

	self:_makeDraggable(bar, self._window)

	return bar
end

function AppUI:_buildBody()
	local body = Components.create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, Layout.topbarHeight),
		Size = UDim2.new(1, 0, 1, -(Layout.topbarHeight + Layout.statusbarHeight)),
		BackgroundTransparency = 1,
		parent = self._window,
	})

	local sidebar = Components.create("Frame", {
		Name = "Sidebar",
		Size = UDim2.fromOffset(Layout.sidebarWidth, 1),
		BackgroundColor3 = palette.background,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		parent = body,
	})

	sidebar.Size = UDim2.new(0, Layout.sidebarWidth, 1, 0)

	local sidebarInner = Components.create("Frame", {
		Name = "Inner",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		parent = sidebar,
	})

	Components.padding(sidebarInner, { top = Theme.Spacing.md, bottom = Theme.Spacing.md, left = Theme.Spacing.md, right = Theme.Spacing.md })
	Components.list(sidebarInner, { gap = Theme.Spacing.xs })

	self._sidebarInner = sidebarInner

	local separator = Components.create("Frame", {
		Name = "Separator",
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = palette.border,
		BorderSizePixel = 0,
		parent = sidebar,
	})

	local content = Components.create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(Layout.sidebarWidth, 0),
		Size = UDim2.new(1, -Layout.sidebarWidth, 1, 0),
		BackgroundTransparency = 1,
		parent = body,
	})

	self._content = content

	local header = Components.create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundTransparency = 1,
		parent = content,
	})

	Components.padding(header, { top = Theme.Spacing.lg, left = Theme.Spacing.xl, right = Theme.Spacing.xl })

	self._headerTitle = Components.label(header, {
		text = "Dashboard",
		font = Theme.Font.display,
		textSize = Theme.Text.title,
		color = palette.text,
		position = UDim2.fromScale(0, 0),
		size = UDim2.new(1, -180, 0, 22),
	})

	self._headerSubtitle = Components.label(header, {
		text = "Overview",
		font = Theme.Font.body,
		textSize = Theme.Text.caption,
		color = palette.textMuted,
		position = UDim2.fromOffset(0, 24),
		size = UDim2.new(1, -180, 0, 14),
	})

	self._headerPill = Components.statusPill(header, {
		text = "idle",
		anchorPoint = Vector2.new(1, 0.5),
		position = UDim2.new(1, 0, 0.5, 0),
	})

	Components.divider(content, 1).Position = UDim2.new(0, 0, 0, 60)

	local pageHost = Components.create("Frame", {
		Name = "PageHost",
		Position = UDim2.fromOffset(0, 61),
		Size = UDim2.new(1, 0, 1, -61),
		BackgroundTransparency = 1,
		parent = content,
	})

	Components.padding(pageHost, { top = Theme.Spacing.lg, left = Theme.Spacing.xl, right = Theme.Spacing.xl, bottom = Theme.Spacing.lg })

	self._pageHost = pageHost
end

function AppUI:_buildStatusbar()
	local bar = Components.create("Frame", {
		Name = "Statusbar",
		Position = UDim2.new(0, 0, 1, -Layout.statusbarHeight),
		Size = UDim2.new(1, 0, 0, Layout.statusbarHeight),
		BackgroundColor3 = palette.backgroundTop,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		ZIndex = 3,
		parent = self._window,
	})

	Components.divider(bar, 0).Position = UDim2.new(0, 0, 0, 0)

	self._statusLabel = Components.label(bar, {
		text = "booting...",
		font = Theme.Font.mono,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		truncate = Enum.TextTruncate.AtEnd,
		position = UDim2.new(0, 16, 0, 0),
		size = UDim2.new(1, -280, 1, 0),
	})

	local adapter = self.state:get("adapterId", "none")
	local platform = self.state:get("platform", "unknown")
	local version = self.state:get("version", "0.1.0")

	self._metaLabel = Components.label(bar, {
		text = ("%s  ·  %s  ·  v%s"):format(adapter, platform, version),
		font = Theme.Font.mono,
		textSize = Theme.Text.micro,
		color = palette.textMuted,
		align = Enum.TextXAlignment.Right,
		anchorPoint = Vector2.new(1, 0),
		position = UDim2.new(1, -16, 0, 0),
		size = UDim2.fromOffset(260, Layout.statusbarHeight),
	})
end

function AppUI:_buildResizeHandle()
	local handle = Components.create("TextButton", {
		Name = "Resize",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(20, 20),
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -2, 1, -2),
		Text = "",
		ZIndex = 5,
		parent = self._window,
	})

	Icons.create(handle, "activity", {
		size = 10,
		color = palette.textFaint,
		anchorPoint = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.62, 0.62),
		rotation = 0,
	})

	self:_makeResizable(handle, self._window)
end

function AppUI:_mountPages()
	for _, pageModule in ipairs(PAGE_MODULES) do
		local host = Components.create("CanvasGroup", {
			Name = "Host_" .. pageModule.id,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			GroupTransparency = 1,
			Visible = false,
			parent = self._pageHost,
		})

		local page = pageModule.create(self.context, host)

		if type(page) ~= "table" then
			page = { frame = page }
		end

		self._pages[pageModule.id] = page
		self._pageHosts[pageModule.id] = host

		local nav = Components.navItem(self._sidebarInner, {
			id = pageModule.id,
			text = pageModule.title,
			icon = pageModule.icon or "dot",
			active = false,
			layoutOrder = pageModule.order or 0,
		}, function()
			self:showPage(pageModule.id)
		end)

		self._navItems[pageModule.id] = nav
	end
end

function AppUI:_buildMeta()
	local footer = Components.create("Frame", {
		Name = "Footer",
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundTransparency = 1,
		LayoutOrder = 1000,
		parent = self._sidebarInner,
	})

	Components.divider(footer, 0).Position = UDim2.new(0, 0, 0, 0)

	local dot = Components.create("Frame", {
		Name = "Dot",
		BackgroundColor3 = palette.success,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 1, 0.5, 0),
		Size = UDim2.fromOffset(7, 7),
		parent = footer,
	})

	Components.corner(dot, 0.5)

	local pulse = Instance.new("UIScale")
	pulse.Scale = 1
	pulse.Parent = dot

	task.spawn(function()
		while dot.Parent do
			Motion.tween(dot, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.6 })
			task.wait(1.4)
			Motion.tween(dot, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0 })
			task.wait(1.4)
		end
	end)

	Components.label(footer, {
		text = "operational",
		font = Theme.Font.medium,
		textSize = Theme.Text.micro,
		color = palette.success,
		position = UDim2.fromOffset(14, 12),
		size = UDim2.new(1, -14, 0, 14),
	})

	Components.label(footer, {
		text = "v" .. tostring(self.state:get("version", "0.1.0")),
		font = Theme.Font.mono,
		textSize = Theme.Text.micro,
		color = palette.textFaint,
		position = UDim2.fromOffset(14, 26),
		size = UDim2.new(1, -14, 0, 14),
	})
end

function AppUI:_bindState()
	self._maid:Add(self.state.ChangedKey:Connect(function(key, value)
		if key == "visible" then
			self:_applyVisibility(value)
		elseif key == "minimized" then
			self:_applyMinimized(value)
		elseif key == "activePage" then
			self:_applyPage(value)
		elseif key == "lastLog" then
			if self._statusLabel then
				self._statusLabel.Text = tostring(value)
			end
		elseif key == "recorderStatus" then
			self:_applyRecorderStatus(value)
		end
	end))

	self._maid:Add(self.context.logger.Emitted:Connect(function(entry)
		self.state:set("eventCount", self.state:get("eventCount", 0) + 1)
		self.state:set("lastLog", ("[%s] %s"):format(entry.tag, entry.message))

		if entry.level >= 40 and self._notifications then
			self._notifications:error(entry.message, entry.tag)
		elseif entry.level >= 30 and self._notifications then
			self._notifications:warn(entry.message, entry.tag)
		end
	end))
end

function AppUI:_applyRecorderStatus(status)
	if not self._headerPill then
		return
	end

	local colors = {
		idle = palette.textMuted,
		starting = palette.warn,
		running = palette.success,
		paused = palette.warn,
		stopping = palette.warn,
		stopped = palette.textMuted,
		failed = palette.danger,
	}

	local color = colors[status] or palette.textMuted
	self._headerPill.set(status, color, color)
end

function AppUI:_applyVisibility(visible)
	if not self._screen then
		return
	end

	self._screen.Enabled = visible == true

	if visible then
		self._window.GroupTransparency = 1
		Motion.tween(self._window, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { GroupTransparency = 0 })
	end
end

function AppUI:_applyMinimized(minimized)
	if not self._window then
		return
	end

	if minimized then
		Motion.tween(self._window, Theme.Motion.easeInOut, {
			Size = UDim2.fromOffset(self._expandedSize.X.Offset, Layout.topbarHeight + Layout.statusbarHeight),
			GroupTransparency = 0.15,
		})
	else
		Motion.tween(self._window, Theme.Motion.easeInOut, { Size = self._expandedSize, GroupTransparency = 0 })
	end
end

function AppUI:_applyPage(activeId)
	local previous = self._activePage

	if previous and previous ~= activeId and self._pageHosts[previous] then
		self._pageHosts[previous].Visible = false
	end

	local host = self._pageHosts[activeId]

	if not host then
		return
	end

	self._activePage = activeId
	host.Visible = true
	host.GroupTransparency = 1
	host.Position = UDim2.fromOffset(0, 10)

	Motion.tween(host, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		GroupTransparency = 0,
		Position = UDim2.fromOffset(0, 0),
	})

	for id, nav in pairs(self._navItems) do
		nav.setActive(id == activeId)
	end

	local pageModule
	for _, module in ipairs(PAGE_MODULES) do
		if module.id == activeId then
			pageModule = module
			break
		end
	end

	if pageModule then
		self._headerTitle.Text = pageModule.title
		self._headerSubtitle.Text = pageModule.subtitle or ""
	end

	local page = self._pages[activeId]

	if page and type(page.refresh) == "function" then
		page.refresh()
	end
end

function AppUI:showPage(id)
	if not self._pages[id] then
		return
	end

	self.state:set("activePage", id)
end

function AppUI:_makeDraggable(handle, target)
	local userInput = game:GetService("UserInputService")
	local dragging = false
	local dragStart
	local startPosition

	local function update(input)
		local delta = input.Position - dragStart
		target.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end

	self._maid:Add(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = target.Position
		end
	end))

	self._maid:Add(handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	self._maid:Add(userInput.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end))
end

function AppUI:_makeResizable(handle, target)
	local userInput = game:GetService("UserInputService")
	local resizing = false
	local resizeStart
	local startSize

	local function update(input)
		local delta = input.Position - resizeStart
		local width = clamp(startSize.X.Offset + delta.X, Layout.minWidth, 2400)
		local height = clamp(startSize.Y.Offset + delta.Y, Layout.minHeight, 1800)
		self._expandedSize = UDim2.fromOffset(width, height)
		target.Size = self._expandedSize
		self._shadow.Size = UDim2.fromOffset(width + 22, height + 22)
	end

	self._maid:Add(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = input.Position
			startSize = target.Size
		end
	end))

	self._maid:Add(handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			resizing = false
		end
	end))

	self._maid:Add(userInput.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end))
end

function AppUI:mount()
	if self._mounted then
		return self
	end

	self._mounted = true

	self:_buildScreen()
	self:_buildWindow()
	self:_buildTopbar()
	self:_buildBody()
	self:_buildStatusbar()
	self:_buildResizeHandle()
	self:_mountPages()
	self:_buildMeta()
	self:_bindState()

	self._closeButton.MouseButton1Click:Connect(function()
		Motion.tween(self._window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { GroupTransparency = 1 })

		task.delay(0.2, function()
			self.state:set("visible", false)
		end)
	end)

	self._minimizeButton.MouseButton1Click:Connect(function()
		self.state:set("minimized", not self.state:get("minimized"))
	end)

	self:showPage(self.state:get("activePage"))
	self:_applyRecorderStatus(self.state:get("recorderStatus", "idle"))

	if self.state:get("visible", true) then
		self._screen.Enabled = true
		Motion.tween(self._window, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { GroupTransparency = 0 })
	else
		self._screen.Enabled = false
	end

	return self
end

function AppUI:unmount()
	if not self._mounted then
		return
	end

	self._mounted = false
	self._maid:Destroy()

	if self._screen then
		self._screen:Destroy()
		self._screen = nil
	end
end

return AppUI
