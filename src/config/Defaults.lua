return {
	schemaVersion = 1,
	frameworkVersion = "0.1.0",

	recorder = {
		enabled = false,
		movementSampleRate = 5,
		snapshotInterval = 5,
	},

	automation = {
		enabled = false,
		retryCount = 3,
		maxCycles = 100,
		maxRuntime = 600,
	},

	ui = {
		enabled = true,
		overlayEnabled = false,
		backdropEnabled = true,
		theme = "dark",
		startVisible = true,
	},

	telemetry = {
		logLevel = "info",
	},
}
