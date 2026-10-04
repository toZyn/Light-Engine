Ease = loxreq "util.tween.ease"
local Instance = loxreq "util.tween.instance"
local Motion = loxreq "util.tween.motion"

local Tween = {}
Tween.__index = Tween

function Tween:tween(object, props, duration, options)
	local tween = Instance()
	tween.manager = self
	tween.persist = options and (options.persist == true) or false
	tween:tween(object, props, duration, options)

	table.insert(self.instances, tween)
	return tween
end

function Tween:quadPath(object, points, speed, isDuration, options)
	local tween = Motion.QuadPath(object, options, points, speed)
	tween.object = object
	tween:setMotion(speed, isDuration)
	table.insert(self.instances, tween)
	return tween
end

function Tween:remove(instance)
	if self._removedDuringUpdate then self._removedDuringUpdate[instance] = true end
	table.delete(self.instances, instance)
end

function Tween:update(dt)
	if dt == 0 or self._updating then return end
	-- Keep callback mutations from shifting the remaining tick into duplicate,
	-- removed or newly created entries.
	local snapshot = {}
	for i, tween in ipairs(self.instances) do snapshot[i] = tween end
	self._updating = true
	self._removedDuringUpdate = {}
	local ok, err = xpcall(function()
		for i = #snapshot, 1, -1 do
			local tween = snapshot[i]
			if not self._removedDuringUpdate[tween] then
				tween:update(dt * self.timeScale)
			end
		end
	end, debug.traceback)
	self._removedDuringUpdate = nil
	self._updating = false
	if not ok then error(err, 0) end
end

function Tween:cancelTweensOf(object)
	for i = #self.instances, 1, -1 do
		local tween = self.instances[i]

		if tween.object == object then
			tween:destroy()
		end
	end
end

function Tween:clear()
	for i = #self.instances, 1, -1 do
		local tween = self.instances[i]
		if tween and tween.destroy and not tween.persist then tween:destroy() end
	end
end

-- wrapper
function Tween.new() return setmetatable({instances = {}, timeScale = 1}, Tween) end
local def, module = Tween.new(), {}
for k in pairs(Tween) do
	if k ~= "__index" then
		module[k] = function(...) return def[k](def, ...) end
	end
end

return setmetatable(module, {__call = Tween.new})
