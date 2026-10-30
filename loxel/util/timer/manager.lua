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
	local onError = self.onError or TimerManager.onError
	local scaledDt = dt * self.timeScale
	local propagatedErr = nil

	for i = #snapshot, 1, -1 do
		local timer = snapshot[i]
		if not self._removedDuringUpdate[timer] then
			local ok, err = xpcall(function()
				timer:update(scaledDt)
			end, function(e)
				return {
					message = tostring(e),
					trace = debug.traceback(tostring(e), 2)
				}
			end)
			if not ok then
				if timer.active and not timer.finished then
					pcall(timer.cancel, timer)
				end
				if type(onError) == "function" then
					onError(err.message, err.trace, timer)
				else
					propagatedErr = err.trace
					break
				end
			end
		end
	end

	self._removedDuringUpdate = nil
	self._updating = false
	if propagatedErr ~= nil then error(propagatedErr, 0) end
end

return TimerManager
