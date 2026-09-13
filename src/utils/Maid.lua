local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {}, _destroyed = false }, Maid)
end

function Maid:Add(task)
	if self._destroyed then
		error("cannot add task to a destroyed Maid", 2)
	end

	table.insert(self._tasks, task)
	return task
end

function Maid:Clean()
	for i = #self._tasks, 1, -1 do
		local task = self._tasks[i]
		self._tasks[i] = nil

		if type(task) == "function" then
			task()
		elseif type(task) == "table" then
			if type(task.Destroy) == "function" then
				task:Destroy()
			elseif type(task.Disconnect) == "function" then
				task:Disconnect()
			end
		end
	end
end

function Maid:Destroy()
	if self._destroyed then
		return
	end

	self._destroyed = true
	self:Clean()
end

return Maid
