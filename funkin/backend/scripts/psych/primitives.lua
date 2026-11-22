local Primitives = {}

function Primitives.install(interpreter, api, flxG)
	local function expose(name, path, value, constructor)
		interpreter:bind(name, value)
		interpreter:expose(path, value)
		if constructor then
			interpreter:registerConstructor(name, constructor)
			interpreter:registerConstructor(path, constructor)
		end
	end
	local flxMath = {
		__name__ = "flixel.math.FlxMath",
		bound = function(value, minimum, maximum)
			if minimum then value = math.max(minimum, value) end
			if maximum then value = math.min(maximum, value) end
			return value
		end,
		lerp = math.lerp,
		remapToRange = math.remapToRange,
		roundDecimal = function(value, places)
			local multiplier = 10 ^ (places or 0)
			return math.round(value * multiplier) / multiplier
		end
	}
	expose("FlxMath", "flixel.math.FlxMath", flxMath)

	local function point(x, y)
		local object = {x = x or 0, y = y or 0}
		function object:set(newX, newY)
			self.x, self.y = newX or 0, newY or 0
			return self
		end
		function object:add(dx, dy) return self:set(self.x + (dx or 0), self.y + (dy or 0)) end
		function object:subtract(dx, dy) return self:add(-(dx or 0), -(dy or 0)) end
		function object:copyFrom(other) return self:set(other.x, other.y) end
		function object:clone() return point(self.x, self.y) end
		return object
	end
	local flxPoint = {__name__ = "flixel.math.FlxPoint", get = point}
	expose("FlxPoint", "flixel.math.FlxPoint", flxPoint, function(args) return point(args[0], args[1]) end)

	flxG.keys = {}
	for mode, helper in pairs({pressed = api.keyboardPressed,
		justPressed = api.keyboardJustPressed, justReleased = api.keyboardReleased}) do
		flxG.keys[mode] = setmetatable({}, {__index = function(_, key) return helper(key) end})
	end
	local conductor = setmetatable({}, {__index = function(_, field)
		if field == "songPosition" then return api.getSongPosition() end
		if field == "bpm" then return api.getSongBpm() end
		if field == "crochet" then return api.getPropertyFromClass("Conductor", field) end
		if field == "stepCrochet" then return api.getPropertyFromClass("Conductor", field) end
	end})
	expose("Conductor", "backend.Conductor", conductor)
end

return Primitives
