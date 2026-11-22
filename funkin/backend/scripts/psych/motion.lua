local Motion = {}

function Motion.install(interpreter, compat, api)
	local serial = 0
	local function tag()
		serial = serial + 1
		return "_psychMotion" .. serial
	end

	local function callback(fn, object)
		if type(fn) ~= "function" or compat.disposed then return end
		local key = tag()
		interpreter:bind(key, fn)
		local ok, message = pcall(interpreter.invoke, interpreter, key, {object}, 1)
		interpreter:bind(key, nil)
		if not ok then Logger.log("error", compat.script.path .. ": " .. tostring(message)) end
	end

	local timers = {}
	local timerCallback = compat._callback
	compat._callback = function(self, name, ...)
		local key, elapsed, left = ...
		if name == "onTimerCompleted" and timers[key] then
			local timer = timers[key]
			timer.elapsedLoops, timer.loopsLeft = elapsed, left
			if timer.loops ~= 0 and left == 0 then
				timer.active, timer.finished = false, true
				timers[key] = nil
			end
			callback(timer.onComplete, timer)
			return
		end
		return timerCallback(self, name, ...)
	end

	local function makeTimer()
		local key = tag()
		local timer = {active = false, finished = false, elapsedLoops = 0}
		function timer:start(seconds, onComplete, loops)
			self.time, self.loops = seconds or 1, loops or 1
			api.runTimer(key, self.time, self.loops)
			self.active, self.finished = true, false
			self.elapsedLoops, self.loopsLeft = 0, self.loops
			self.onComplete = onComplete
			timers[key] = self
			return self
		end
		function timer:cancel()
			api.cancelTimer(key)
			timers[key] = nil
			self.active, self.finished = false, true
			self.onComplete = nil
		end
		timer.destroy = timer.cancel
		return timer
	end

	local flxTimer = {}
	interpreter:bind("FlxTimer", flxTimer)
	interpreter:expose("flixel.util.FlxTimer", flxTimer)
	interpreter:registerConstructor("FlxTimer", makeTimer)
	interpreter:registerConstructor("flixel.util.FlxTimer", makeTimer)

	local flxTween = {__name__ = "flixel.tweens.FlxTween"}
	function flxTween.tween(object, properties, duration, options)
		local targets = {}
		for field in pairs(properties.__fields__ or properties) do
			local value = properties[field]
			assert(type(value) == "number" and type(object[field]) == "number", "HScript tween properties must be numeric")
			targets[field] = value
		end
		options = options or {}
		duration = duration or 1
		assert(type(duration) == "number" and duration > 0 and duration < math.huge, "Invalid HScript tween duration")
		local key = tag()
		local tween
		local proxy = {active = true, finished = false}
		function proxy:cancel()
			compat:_cancelTween(key)
			self.active, self.finished = false, true
		end
		tween = compat.tween:tween(object, targets, duration, {
			ease = options.ease or "linear",
			startDelay = options.startDelay,
			onComplete = function()
				compat.tweens[key] = nil
				proxy.active, proxy.finished = false, true
				callback(options.onComplete, proxy)
			end
		})
		tween.compatTag = key
		compat.tweens[key] = tween
		return proxy
	end
	local flxEase = {__name__ = "flixel.tweens.FlxEase"}
	for key, value in pairs(Ease) do
		if type(value) == "function" then flxEase[key] = value end
	end
	interpreter:bind("FlxTween", flxTween)
	interpreter:expose("flixel.tweens.FlxTween", flxTween)
	interpreter:bind("FlxEase", flxEase)
	interpreter:expose("flixel.tweens.FlxEase", flxEase)
end

return Motion
