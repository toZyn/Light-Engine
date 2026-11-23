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

	-- Deprecated in Psych but still shipped and still used by plenty of mods.
	-- Every one of them was missing here, so the call raised "attempt to call a
	-- nil value" and killed the callback that made it.
	local function oldTween(name, tag, vars, targets, duration, ease)
		if targets == nil or next(targets) == nil then
			warn(name .. ": No values on 2nd argument!", true)
			return nil
		end
		return api.startTween(tag, vars, targets, duration, {ease = ease})
	end
	for _, entry in ipairs({{"doTweenX", "x"}, {"doTweenY", "y"},
		{"doTweenAngle", "angle"}, {"doTweenAlpha", "alpha"}}) do
		local name, field = entry[1], entry[2]
		api[name] = function(tag, vars, value, duration, ease)
			compat:_active()
			return oldTween(name, tag, vars, {[field] = value}, duration, ease)
		end
	end
	-- doTweenZoom targets a camera, not an object, and rejects unknown names back
	-- to camGame exactly like Psych's switch does.
	api.doTweenZoom = function(tag, camera, value, duration, ease)
		compat:_active()
		local target = type(camera) == "string" and camera:lower() or "camgame"
		if target == "camgame" or target == "game" then target = "camGame"
		elseif target == "camhud" or target == "hud" then target = "camHUD"
		elseif target == "camother" or target == "other" then target = "camOther"
		else target = "camGame" end
		return oldTween("doTweenZoom", tag, target, {zoom = value}, duration, ease)
	end

	-- Strum line tweens: note 0-3 is the opponent, 4-7 is the player.
	local function noteObject(index)
		index = tonumber(index) or 0
		local field, lane
		if index >= 4 then
			field = state.playerNotefield or state.playerField
			lane = index - 3
		else
			field = state.enemyNotefield or state.opponentField
			lane = index + 1
		end
		local entry = field and field.lanes and field.lanes[lane]
		return entry and entry.receptor or nil
	end
	for _, entry in ipairs({{"noteTweenX", "x"}, {"noteTweenY", "y"},
		{"noteTweenAngle", "angle"}, {"noteTweenAlpha", "alpha"},
		{"noteTweenDirection", "direction"}}) do
		local name, field = entry[1], entry[2]
		api[name] = function(tag, note, value, duration, ease)
			compat:_active()
			local object = noteObject(note)
			if object == nil then
				warn(name .. ": Couldnt find note " .. tostring(note), true)
				return nil
			end
			if tag ~= nil then compat:_cancelTween(tag) end
			local tween = compat.tween:tween(object, {[field] = value}, tonumber(duration) or 1,
				{ease = api.psychEase and api.psychEase(ease) or "linear", type = "oneshot"})
			if type(tag) == "string" then
				compat.tweens[tag] = tween
				tween.compatTag = tag
			else
				compat.anonymousTweens[#compat.anonymousTweens + 1] = tween
			end
			return tag
		end
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
