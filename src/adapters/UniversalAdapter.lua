local UniversalAdapter = {
	id = "universal",
	version = "1.0.0",
	description = "Generic adapter that boots on any Roblox place.",
}

function UniversalAdapter.supports(_self, _context)
	return true
end

function UniversalAdapter.init(self, context)
	self.context = context
end

function UniversalAdapter.start(_self) end

function UniversalAdapter.stop(_self) end

function UniversalAdapter.getEntityRules(_self)
	return {}
end

function UniversalAdapter.getWorkflows(_self)
	return {}
end

function UniversalAdapter.getFeatures(_self)
	return {}
end

return UniversalAdapter
