local TimerManager = Classic:extend("TimerManager")

function TimerManager:new(timeScale)
	self.instances = {}
	self.timeScale = timeScale or 1
end

function TimerManager:insert(instance)
	table.insert(self.instances, instance)
end

function TimerManager:remove(instance)
	if self._removedDuringUpdate then self._removedDuringUpdate[instance] = true end
	table.delete(self.instances, instance)
end

function TimerManager:clear()
	for i = #self.instances, 1, -1 do
		local timer = self.instances[i]
		timer:cancel()
	end
end

function TimerManager:update(dt)
	if dt == 0 or self._updating then return end
	-- Callbacks may clear/cancel/add timers. Iterate the tick's original members
	-- once, skipping removals; new or reinserted members wait for the next tick.
	local snapshot = {}
	for i, timer in ipairs(self.instances) do snapshot[i] = timer end
	self._updating = true
	self._removedDuringUpdate = {}
	local ok, err = xpcall(function()
		for i = #snapshot, 1, -1 do
			local timer = snapshot[i]
			if not self._removedDuringUpdate[timer] then
				timer:update(dt * self.timeScale)
			end
		end
	end, debug.traceback)
	self._removedDuringUpdate = nil
	self._updating = false
	if not ok then error(err, 0) end
end

return TimerManager
