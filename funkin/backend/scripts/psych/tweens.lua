local Tweens = {}

local Resolve = require "funkin.backend.scripts.psych.resolve"
local Reflection = require "funkin.backend.scripts.psych.reflection"

local function properties(values)
	if type(values) ~= "table" then return nil end
	local result = {}
	if values.length then
		for index = 0, values.length - 1 do
			local value = values[index]
			if type(value) ~= "table" then return nil end
			for key, item in pairs(value) do
				if key ~= "length" and key ~= "__fields__" then result[key] = item end
			end
		end
	else
		for key, item in pairs(values) do
			if key ~= "__fields__" then result[key] = item end
		end
	end
	if not next(result) then return nil end
	return result
end

local function tweenType(value)
	local kind = type(value) == "string" and value:lower() or "oneshot"
	if kind == "persist" or kind == "looping" or kind == "pingpong" or kind == "backward" then return kind end
	return "oneshot"
end

local function range(object, targets)
	for key, value in pairs(targets) do
		object[key] = value
	end
end

function Tweens.install(compat, api)
	local state = compat.state
	local function warn(message, deprecated)
		compat:psychWarn(message, deprecated)
	end
	local function variables()
		state.psychVariables = state.psychVariables or {}
		return state.psychVariables
	end
	local function formatted(tag)
		return "tween_" .. tostring(tag):match("^%s*(.-)%s*$"):gsub(" ", "_"):gsub("%.", "")
	end
	local function call(name, ...)
		if type(name) == "string" and name ~= "" then compat:psychDispatch(name, ...) end
	end

	api.startTween = function(tag, vars, values, duration, options)
		compat:_active()
		local object = Resolve.get(compat, vars)
		if object == nil then
			warn("startTween: Couldnt find object: " .. tostring(vars))
			return nil
		end
		local targets = properties(values)
		if targets == nil then
			warn("startTween: No values on 2nd argument!")
			return nil
		end
		local settings = type(options) == "table" and options or {}
		if tag ~= nil then compat:_cancelTween(tag) end
		if type(tag) == "string" then variables()[tag] = true end
		local ease = api.psychEase and api.psychEase(settings.ease) or "linear"
		local tween
		local hookUpdate, hookStart = settings.onUpdate, settings.onStart
		local completion = settings.onComplete
		tween = compat.tween:tween(object, targets, tonumber(duration) or 1, {
			ease = ease, type = tweenType(settings.type),
			startDelay = tonumber(settings.startDelay) or 0,
			loopDelay = tonumber(settings.loopDelay) or 0,
			onStart = function() if hookStart then call(hookStart, formatted(tag), vars) end end,
			onUpdate = function() if hookUpdate then call(hookUpdate, formatted(tag), vars) end end,
			onComplete = function()
				if completion then call(completion, formatted(tag), vars) end
			end
		})
		if type(tag) == "string" then
			compat.tweens[tag] = tween
			tween.compatTag = tag
		else
			compat.anonymousTweens[#compat.anonymousTweens + 1] = tween
		end
		return tag
	end

	api.doTweenColor = function(tag, vars, targetColor, duration, ease)
		compat:_active()
		local object = Resolve.get(compat, vars)
		if object == nil then
			warn("doTweenColor: Couldnt find object: " .. tostring(vars))
			return nil
		end
		local current = object.color
		local from = {current[1], current[2], current[3], object.alpha or 1}
		local value
		if type(targetColor) == "number" then value = targetColor
		elseif api.psychColorFromString then
			local ok, parsed = pcall(api.psychColorFromString, targetColor)
			value = ok and parsed or 0xFFFFFFFF
		else value = 0xFFFFFFFF end
		local target = {Color.get(value)}
		local key = tag
		if tag ~= nil then compat:_cancelTween(tag) end
		local progress = {value = 0}
		local tween
		local resolved = api.psychEase and api.psychEase(ease) or "linear"
		tween = compat.tween:tween(progress, {value = 1}, tonumber(duration) or 1, {
			ease = resolved,
			onUpdate = function()
				local t = progress.value
				object.color = {
					from[1] + (target[1] - from[1]) * t,
					from[2] + (target[2] - from[2]) * t,
					from[3] + (target[3] - from[3]) * t
				}
				local alpha = from[4] + ((target[4] or 1) - from[4]) * t
				object.alpha = alpha
			end,
			onComplete = function()
				if type(key) == "string" then compat.tweens[key] = nil end
				if type(key) == "string" then compat:psychDispatch("onTweenCompleted", key, vars) end
			end
		})
		if type(key) == "string" then
			compat.tweens[key] = tween
			tween.compatTag = key
		end
		return key
	end
end

return Tweens
