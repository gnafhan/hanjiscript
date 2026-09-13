local Theme = {}

Theme.Dark = {
	background = Color3.fromRGB(10, 11, 15),
	backgroundTop = Color3.fromRGB(19, 20, 28),

	surface = Color3.fromRGB(19, 20, 26),
	surfaceAlt = Color3.fromRGB(26, 27, 35),
	surfaceHover = Color3.fromRGB(35, 37, 47),
	surfaceActive = Color3.fromRGB(43, 46, 60),

	border = Color3.fromRGB(39, 41, 53),
	borderStrong = Color3.fromRGB(58, 61, 78),

	text = Color3.fromRGB(237, 239, 246),
	textSecondary = Color3.fromRGB(172, 176, 190),
	textMuted = Color3.fromRGB(118, 122, 138),
	textFaint = Color3.fromRGB(88, 92, 106),

	accent = Color3.fromRGB(105, 137, 255),
	accentHover = Color3.fromRGB(129, 157, 255),
	accentSoft = Color3.fromRGB(45, 55, 96),

	success = Color3.fromRGB(74, 222, 128),
	warn = Color3.fromRGB(250, 204, 21),
	danger = Color3.fromRGB(248, 113, 113),
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
