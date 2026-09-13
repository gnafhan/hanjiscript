local Theme = {}

Theme.Dark = {
	background = Color3.fromRGB(16, 16, 20),
	surface = Color3.fromRGB(24, 24, 30),
	surfaceAlt = Color3.fromRGB(32, 32, 40),
	surfaceHover = Color3.fromRGB(40, 40, 50),
	border = Color3.fromRGB(48, 48, 60),
	text = Color3.fromRGB(236, 236, 242),
	textMuted = Color3.fromRGB(148, 148, 162),
	accent = Color3.fromRGB(79, 140, 255),
	accentMuted = Color3.fromRGB(43, 78, 145),
	success = Color3.fromRGB(74, 202, 129),
	warn = Color3.fromRGB(240, 190, 90),
	danger = Color3.fromRGB(235, 90, 90),
}

Theme.Spacing = {
	xs = 4,
	sm = 8,
	md = 12,
	lg = 16,
	xl = 24,
}

Theme.Radius = {
	sm = 4,
	md = 6,
	lg = 10,
}

Theme.Font = {
	body = Enum.Font.Gotham,
	medium = Enum.Font.GothamMedium,
	bold = Enum.Font.GothamBold,
	mono = Enum.Font.Code,
}

Theme.TextSize = {
	xs = 11,
	sm = 13,
	md = 14,
	lg = 17,
	xl = 20,
}

function Theme.palette(name)
	return Theme[name == "light" and "Dark" or "Dark"]
end

return Theme
