local Theme = {}

Theme.Dark = {
	-- A restrained "mission control" palette: one strong action color and
	-- neutral blue-black surfaces keep operational information easy to scan.
	background = Color3.fromRGB(11, 16, 27),
	backgroundTop = Color3.fromRGB(17, 24, 39),

	surface = Color3.fromRGB(20, 29, 47),
	surfaceAlt = Color3.fromRGB(29, 40, 62),
	surfaceHover = Color3.fromRGB(38, 52, 79),
	surfaceActive = Color3.fromRGB(48, 65, 98),

	border = Color3.fromRGB(51, 67, 96),
	borderStrong = Color3.fromRGB(81, 103, 142),

	text = Color3.fromRGB(244, 247, 255),
	textSecondary = Color3.fromRGB(201, 211, 230),
	textMuted = Color3.fromRGB(139, 155, 185),
	textFaint = Color3.fromRGB(100, 116, 146),

	accent = Color3.fromRGB(89, 128, 255),
	accentHover = Color3.fromRGB(120, 153, 255),
	accentSoft = Color3.fromRGB(32, 57, 112),

	success = Color3.fromRGB(73, 214, 142),
	warn = Color3.fromRGB(251, 194, 69),
	danger = Color3.fromRGB(244, 113, 129),
	info = Color3.fromRGB(77, 171, 255),

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
	lg = 12,
	xl = 22,
	pill = 999,
}

Theme.Text = {
	display = 24,
	title = 18,
	subtitle = 14,
	body = 14,
	label = 13,
	caption = 13,
	micro = 11,
	mono = 12,
}

local function packagedFont(family, weight, fallback)
	-- rbxasset font families are bundled by Roblox, unlike a web font URL.  The
	-- fallback keeps the interface legible in older runtimes that lack FontFace.
	local ok, font = pcall(function()
		return Font.new(
			"rbxasset://fonts/families/" .. family .. ".json",
			weight,
			Enum.FontStyle.Normal
		)
	end)

	return ok and font or fallback
end

Theme.Font = {
	-- One UI family gives every screen a consistent voice.  Mono remains only
	-- for values where fixed-width scanning is useful (logs, versions, IDs).
	display = packagedFont("Montserrat", Enum.FontWeight.ExtraBold, Enum.Font.GothamBold),
	title = packagedFont("Montserrat", Enum.FontWeight.Bold, Enum.Font.GothamBold),
	medium = packagedFont("Montserrat", Enum.FontWeight.SemiBold, Enum.Font.GothamMedium),
	body = packagedFont("Montserrat", Enum.FontWeight.Medium, Enum.Font.Gotham),
	mono = packagedFont("RobotoMono", Enum.FontWeight.Regular, Enum.Font.Code),
}

Theme.Motion = {
	fast = 0.12,
	normal = 0.22,
	slow = 0.36,
	easeOut = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	easeInOut = TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
}

Theme.Layout = {
	windowWidth = 960,
	windowHeight = 620,
	minWidth = 640,
	minHeight = 440,
	topbarHeight = 58,
	statusbarHeight = 28,
	sidebarWidth = 224,
}

function Theme.palette(_name)
	return Theme.Dark
end

return Theme
