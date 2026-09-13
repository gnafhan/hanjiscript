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
		inventoryCapacity = 20,
		maxCycles = 100,
		maxRuntime = 600,
	},

	ui = {
		enabled = true,
		overlayEnabled = true,
		overlayMaxMarkers = 60,
		overlayRadius = 140,
		pathOverlayEnabled = true,
		pathOverlayMaxWaypoints = 128,
		backdropEnabled = true,
		theme = "dark",
		startVisible = true,
	},

	telemetry = {
		logLevel = "info",
	},
}
