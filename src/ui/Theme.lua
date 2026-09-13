local Theme = {}

Theme.Dark = {
	background = Color3.fromRGB(13, 14, 19),
	backgroundTop = Color3.fromRGB(24, 26, 35),

	surface = Color3.fromRGB(26, 28, 37),
	surfaceAlt = Color3.fromRGB(34, 37, 48),
	surfaceHover = Color3.fromRGB(45, 49, 63),
	surfaceActive = Color3.fromRGB(56, 61, 79),

	border = Color3.fromRGB(51, 55, 71),
	borderStrong = Color3.fromRGB(78, 84, 106),

	text = Color3.fromRGB(246, 247, 252),
	textSecondary = Color3.fromRGB(194, 199, 214),
	textMuted = Color3.fromRGB(144, 150, 168),
	textFaint = Color3.fromRGB(106, 112, 130),

	accent = Color3.fromRGB(112, 143, 255),
	accentHover = Color3.fromRGB(139, 166, 255),
	accentSoft = Color3.fromRGB(52, 64, 110),

	success = Color3.fromRGB(80, 226, 138),
	warn = Color3.fromRGB(252, 211, 77),
	danger = Color3.fromRGB(248, 122, 122),
	info = Color3.fromRGB(96, 165, 250),

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

Theme.Font = {
	display = Enum.Font.GothamBold,
	title = Enum.Font.GothamBold,
	medium = Enum.Font.GothamMedium,
	body = Enum.Font.Gotham,
	mono = Enum.Font.Code,
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
