local require = ...

local Signal = require("utils.Signal")

local ReplayClock = {}
ReplayClock.__index = ReplayClock

function ReplayClock.new()
	return setmetatable({
		time = 0,
		speed = 1,
		playing = false,
		Tick = Signal.new(),
		connection = nil,
	}, ReplayClock)
end

function ReplayClock:onTick(callback)
	return self.Tick:Connect(callback)
end

function ReplayClock:setSpeed(speed)
	self.speed = math.max(0.05, tonumber(speed) or 1)
	return self.speed
end

function ReplayClock:seek(time)
	self.time = math.max(0, tonumber(time) or 0)
	self.Tick:Fire(self.time, 0)
	return self.time
end

function ReplayClock:step(delta)
	if not self.playing and delta == nil then
		return self.time
	end
	local amount = math.max(0, tonumber(delta) or 0) * self.speed
	self.time += amount
	self.Tick:Fire(self.time, amount)
	return self.time
end

function ReplayClock:play()
	if self.playing then
		return false
	end
	self.playing = true
	if not self.connection then
		self.connection = game:GetService("RunService").Heartbeat:Connect(function(delta)
			if self.playing then
				self:step(delta)
			end
		end)
	end
	return true
end

function ReplayClock:pause()
	if not self.playing then
		return false
	end
	self.playing = false
	return true
end

function ReplayClock:destroy()
	self.playing = false
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	self.Tick:Destroy()
end

return ReplayClock
