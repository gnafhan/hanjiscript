local Theme = {}

Theme.Dark = {
	background = Color3.fromRGB(24, 27, 36),
	backgroundTop = Color3.fromRGB(38, 42, 56),

	surface = Color3.fromRGB(33, 37, 48),
	surfaceAlt = Color3.fromRGB(44, 49, 63),
	surfaceHover = Color3.fromRGB(58, 64, 82),
	surfaceActive = Color3.fromRGB(72, 79, 102),

	border = Color3.fromRGB(66, 72, 92),
	borderStrong = Color3.fromRGB(98, 106, 132),

	text = Color3.fromRGB(250, 251, 255),
	textSecondary = Color3.fromRGB(210, 215, 228),
	textMuted = Color3.fromRGB(162, 169, 188),
	textFaint = Color3.fromRGB(124, 131, 152),

	accent = Color3.fromRGB(126, 156, 255),
	accentHover = Color3.fromRGB(156, 180, 255),
	accentSoft = Color3.fromRGB(64, 80, 134),

	success = Color3.fromRGB(92, 232, 148),
	warn = Color3.fromRGB(255, 216, 96),
	danger = Color3.fromRGB(252, 136, 136),
	info = Color3.fromRGB(116, 178, 255),

	shadow = Color3.fromRGB(0, 0, 0),
}

Theme.Spacing = {
	xxs = 2,
	xs = 4,
	sm = 8,
	md = 12,
	lg = 16,
	xl = 22,
	xxl = 30,
}

Theme.Radius = {
	xs = 4,
	sm = 6,
	md = 9,
	lg = 13,
	xl = 18,
	pill = 999,
}

Theme.Text = {
	display = 22,
	title = 17,
	subtitle = 13,
	body = 13,
	label = 12,
	caption = 11,
	micro = 10,
	mono = 12,
}

local function buildFont(family, weightName, fallback)
	local ok, font = pcall(function()
		return Font.new(
			"rbxasset://fonts/families/" .. family .. ".json",
			Enum.FontWeight[weightName],
			Enum.FontStyle.Normal
		)
	end)

	if ok and font ~= nil then
		return font
	end

	return fallback
end

Theme.Font = {
	display = buildFont("Montserrat", "Bold", Enum.Font.GothamBold),
	title = buildFont("Montserrat", "Bold", Enum.Font.GothamBold),
	medium = buildFont("Montserrat", "Medium", Enum.Font.GothamMedium),
	body = buildFont("Montserrat", "Regular", Enum.Font.Gotham),
	mono = buildFont("RobotoMono", "Regular", Enum.Font.Code),
}

Theme.Motion = {
	fast = 0.12,
	normal = 0.22,
	slow = 0.36,
	easeOut = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	easeInOut = TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
}

Theme.Layout = {
	windowWidth = 780,
	windowHeight = 500,
	minWidth = 560,
	minHeight = 360,
	topbarHeight = 46,
	statusbarHeight = 26,
	sidebarWidth = 208,
}

function Theme.palette(_name)
	return Theme.Dark
end

return Theme
