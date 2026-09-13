local require = ...

local Theme = require("ui.Theme")
local Components = require("ui.Components")
local UIState = require("ui.UIState")
local Maid = require("utils.Maid")

local DashboardPage = require("ui.pages.DashboardPage")
local InspectorPage = require("ui.pages.InspectorPage")
local RecorderPage = require("ui.pages.RecorderPage")
local SettingsPage = require("ui.pages.SettingsPage")

local palette = Theme.Dark

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

function AppUI.new(context)
	local config = context.config
	local adapter = context.adapter
	local experience = context.experience or {}
	local runtime = context.runtime or {}

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
	})

	return setmetatable({
		context = context,
		state = state,
		_maid = Maid.new(),
		_pages = {},
		_navButtons = {},
		_pageFrames = {},
		_mounted = false,
	}, AppUI)
end

function AppUI:getState()
	return self.state
end

function AppUI:_buildScreen()
	local parent = getGuiParent()

	if not parent then
		error("AppUI: unable to resolve a Gui parent (CoreGui/PlayerGui)", 2)
	end

	local screen = Components.create("ScreenGui", {
		Name = "HanjiScript",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 50,
		parent = parent,
	})

	self._screen = screen
end

function AppUI:_buildWindow()
	local window = Components.create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(660, 420),
		BackgroundColor3 = palette.background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		parent = self._screen,
	})

	Components.corner(window, Theme.Radius.lg)
	Components.stroke(window, palette.border)

	self._window = window
	self._expandedSize = UDim2.fromOffset(660, 420)
end

function AppUI:_buildTitleBar()
	local bar = Components.create("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = palette.surface,
		BorderSizePixel = 0,
		parent = self._window,
	})

	Components.corner(bar, Theme.Radius.lg)

	local cover = Components.create("Frame", {
		Name = "CornerCover",
		Position = UDim2.new(0, 0, 1, -Theme.Radius.lg),
		Size = UDim2.new(1, 0, 0, Theme.Radius.lg),
		BackgroundColor3 = palette.surface,
		BorderSizePixel = 0,
		parent = bar,
	})

	cover.ZIndex = 1

	Components.label(bar, {
		Name = "Title",
		Text = "HanjiScript  ·  Roblox Automation Platform",
		Font = Theme.Font.bold,
		TextSize = Theme.TextSize.sm,
		Position = UDim2.fromOffset(Theme.Spacing.md, 0),
		Size = UDim2.new(1, -140, 1, 0),
		parent = bar,
	})

	local close = Components.button(bar, {
		Name = "Close",
		Text = "×",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -34, 0, 4),
		BackgroundColor3 = palette.surfaceAlt,
		textSize = Theme.TextSize.lg,
	}, function()
		self.state:set("visible", false)
	end)

	close.ZIndex = 2

	local minimize = Components.button(bar, {
		Name = "Minimize",
		Text = "—",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -66, 0, 4),
		BackgroundColor3 = palette.surfaceAlt,
	}, function()
		self.state:set("minimized", not self.state:get("minimized"))
	end)

	minimize.ZIndex = 2

	self:_makeDraggable(bar, self._window)
end

function AppUI:_buildBody()
	local body = Components.create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 1, -58),
		BackgroundTransparency = 1,
		parent = self._window,
	})

	self._body = body

	local sidebar = Components.create("Frame", {
		Name = "Sidebar",
		Size = UDim2.fromOffset(150, 1),
		BackgroundColor3 = palette.surface,
		BorderSizePixel = 0,
		parent = body,
	})

	sidebar.Size = UDim2.new(0, 150, 1, 0)
	Components.corner(sidebar, Theme.Radius.sm)
	Components.padding(sidebar, {
		top = Theme.Spacing.md,
		bottom = Theme.Spacing.md,
		left = Theme.Spacing.sm,
		right = Theme.Spacing.sm,
	})
	Components.list(sidebar, { gap = Theme.Spacing.xs })

	self._sidebar = sidebar

	local content = Components.create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(158, 0),
		Size = UDim2.new(1, -166, 1, 0),
		BackgroundTransparency = 1,
		parent = body,
	})

	self._content = content
end

function AppUI:_buildStatusBar()
	local bar = Components.create("Frame", {
		Name = "StatusBar",
		Position = UDim2.new(0, 0, 1, -22),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = palette.surface,
		BorderSizePixel = 0,
		parent = self._window,
	})

	Components.corner(bar, Theme.Radius.sm)

	self._statusLabel = Components.label(bar, {
		Name = "Status",
		Text = "booting...",
		TextSize = Theme.TextSize.xs,
		TextColor3 = palette.textMuted,
		Position = UDim2.fromOffset(Theme.Spacing.md, 0),
		Size = UDim2.new(1, -180, 1, 0),
		parent = bar,
	})

	self._versionLabel = Components.label(bar, {
		Name = "Version",
		Text = "v0.1.0",
		TextSize = Theme.TextSize.xs,
		TextColor3 = palette.textMuted,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -160, 0, 0),
		Size = UDim2.fromOffset(148, 22),
		parent = bar,
	})
end

function AppUI:_mountPages()
	for _, pageModule in ipairs(PAGE_MODULES) do
		local page = pageModule.create(self.context, self._content)

		if type(page) == "table" and page.frame then
			page.frame.Visible = false
			self._pages[pageModule.id] = page
			self._pageFrames[pageModule.id] = page.frame
		else
			page.Visible = false
			self._pages[pageModule.id] = { frame = page }
			self._pageFrames[pageModule.id] = page
		end

		Components.button(self._sidebar, {
			name = pageModule.id,
			text = pageModule.title,
			align = Enum.TextXAlignment.Left,
			background = palette.surfaceAlt,
			color = palette.textMuted,
			height = 32,
			layoutOrder = pageModule.order or 0,
		}, function()
			self:showPage(pageModule.id)
		end)

		self._navButtons[pageModule.id] = self._sidebar:FindFirstChild(pageModule.id)
	end
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
			self._statusLabel.Text = tostring(value)
		end
	end))

	self._maid:Add(self.context.logger.Emitted:Connect(function(entry)
		self.state:set("eventCount", self.state:get("eventCount", 0) + 1)
		self.state:set("lastLog", ("[%s] %s"):format(entry.tag, entry.message))
	end))
end

function AppUI:_applyVisibility(visible)
	if self._screen then
		self._screen.Enabled = visible == true
	end
end

function AppUI:_applyMinimized(minimized)
	if not self._window then
		return
	end

	if minimized then
		self._window.Size = UDim2.fromOffset(660, 36)
	else
		self._window.Size = self._expandedSize
	end
end

function AppUI:_applyPage(activeId)
	for id, frame in pairs(self._pageFrames) do
		frame.Visible = id == activeId
	end

	for id, button in pairs(self._navButtons) do
		if id == activeId then
			button.BackgroundColor3 = palette.accentMuted
			button.TextColor3 = palette.text
		else
			button.BackgroundColor3 = palette.surfaceAlt
			button.TextColor3 = palette.textMuted
		end
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
		if not dragging then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - dragStart

		target.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end))
end

function AppUI:mount()
	if self._mounted then
		return self
	end

	self._mounted = true
	self:_buildScreen()
	self:_buildWindow()
	self:_buildTitleBar()
	self:_buildBody()
	self:_buildStatusBar()
	self:_mountPages()
	self:_bindState()

	self:showPage(self.state:get("activePage"))
	self:_applyVisibility(self.state:get("visible"))
	self:_applyMinimized(self.state:get("minimized"))

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
