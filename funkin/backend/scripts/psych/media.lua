local Media = {}
local paths = require "funkin.backend.paths"
local colorNames = {
	transparent = 0, black = 0xFF000000, white = 0xFFFFFFFF, red = 0xFFFF0000,
	lime = 0xFF00FF00, green = 0xFF008000, blue = 0xFF0000FF, yellow = 0xFFFFFF00
}

local function color(value)
	if type(value) == "number" then return bit.tobit(value) end
	value = tostring(value):lower()
	if colorNames[value] then return bit.tobit(colorNames[value]) end
	local hex = value:gsub("^#", ""):gsub("^0x", "")
	assert(hex:match("^%x+$") and (#hex == 6 or #hex == 8), "Invalid Psych color: " .. value)
	if #hex == 6 then hex = "ff" .. hex end
	return bit.tobit(tonumber(hex, 16))
end

function Media.install(compat, api)
	local state = compat.state
	api.FlxColor = color
	api.getColorFromName, api.getColorFromString, api.getColorFromHex = color, color, color
	api.psychColorFromString = color

	local function character(name)
		name = tostring(name or "dad"):lower()
		if name == "boyfriend" or name == "bf" or name == "player" or name == "0" then return state.boyfriend end
		if name == "gf" or name == "girlfriend" or name == "2" then return state.gf end
		return state.dad
	end
	for _, axis in ipairs({"x", "y"}) do
		local upper = axis:upper()
		api["getCharacter" .. upper] = function(name)
			local actor = character(name)
			return actor and actor[axis] or 0
		end
		api["setCharacter" .. upper] = function(name, value)
			local actor = character(name)
			if actor then actor[axis] = value end
		end
	end
	api.characterDance = function(name)
		local actor = character(name)
		if actor then actor:dance() end
	end

	api.loadGraphic = function(tag, image, width, height)
		local sprite = compat:_object(tag)
		local texture = assert(paths.getImage(image), "Missing Psych graphic: " .. tostring(image))
		sprite:loadTexture(texture, (width or 0) > 0 or (height or 0) > 0, width, height)
		sprite:updateHitbox()
	end
	api.loadFrames = function(tag, image)
		compat:_object(tag):setFrames(assert(paths.getAtlas(image), "Missing Psych atlas: " .. tostring(image)))
	end
	api.addAnimation = function(tag, name, frames, rate, looped)
		local object = compat:_object(tag)
		if frames.length then
			local native = {}
			for index = 0, frames.length - 1 do native[index + 1] = frames[index] end
			frames = native
		end
		object.animation:add(name, frames, rate or 24, looped == true)
	end
	api.setGraphicSize = function(tag, width, height, update)
		local object = compat:_object(tag)
		object:setGraphicSize(width or 0, height or 0)
		if update ~= false then object:updateHitbox() end
	end
	api.setBlendMode = function(tag, mode)
		local native = tostring(mode or "normal"):lower()
		if native == "normal" then native = "alpha" end
		assert(native == "alpha" or native == "add" or native == "subtract" or native == "multiply"
			or native == "lighten" or native == "darken" or native == "screen", "Unsupported Psych blend mode")
		compat:_object(tag).blend = native
	end
	api.setHealthBarColors = function(empty, filled)
		local bar = assert(state.healthBar and state.healthBar.bar, "Psych health bar is unavailable")
		bar.color = Color.fromHEX(color(filled) % 2^32)
		bar.color.bg = Color.fromHEX(color(empty) % 2^32)
	end
	for suffix, method in pairs({Midpoint = "getMidpoint", GraphicMidpoint = "getGraphicMidpoint"}) do
		for position, axis in ipairs({"X", "Y"}) do
			api["get" .. suffix .. axis] = function(tag)
				local object = compat:_object(tag)
				local x, y = object[method](object)
				return position == 1 and x or y
			end
		end
	end

	local function camera(key)
		local names = {game = "camGame", hud = "camHUD", other = "camOther", notes = "camNotes"}
		return assert(compat:_root(names[key] or key or "camGame"), "Psych camera is unavailable")
	end
	api.cameraSetTarget = function(target)
		local actor = character(target)
		if not actor then return false end
		state.camTarget = actor
		if state.getCameraPosition and state.cameraMovement then
			state:cameraMovement(state:getCameraPosition(actor))
		end
		return actor == state.dad
	end
	api.setCameraScroll = function(x, y)
		game.camera.scroll:set(x - game.width / 2, y - game.height / 2)
	end
	api.addCameraScroll = function(x, y)
		local scroll = game.camera.scroll
		scroll:set(scroll.x + (x or 0), scroll.y + (y or 0))
	end
	api.getCameraScrollX = function() return game.camera.scroll.x + game.width / 2 end
	api.getCameraScrollY = function() return game.camera.scroll.y + game.height / 2 end
	api.setCameraFollowPoint = function(x, y) if state.camFollow then state.camFollow:set(x, y) end end
	api.addCameraFollowPoint = function(x, y)
		local point = state.camFollow
		if point then point:set(point.x + (x or 0), point.y + (y or 0)) end
	end
	api.getCameraFollowX = function() return state.camFollow and state.camFollow.x or 0 end
	api.getCameraFollowY = function() return state.camFollow and state.camFollow.y or 0 end
	api.getMouseX = function(key)
		local x = camera(key):screenToWorld(game.mouse.x, game.mouse.y)
		return x
	end
	api.getMouseY = function(key)
		local _, y = camera(key):screenToWorld(game.mouse.x, game.mouse.y)
		return y
	end
	for name, field in pairs({mouseClicked = "justPressed", mousePressed = "pressed", mouseReleased = "justReleased"}) do
		api[name] = function(button)
			local suffix = ({left = "Left", right = "Right", middle = "Middle"})[button or "left"]
			return suffix and game.mouse[field .. suffix] or false
		end
	end

	local function sound(tag)
		if tag == nil or tag == "" then return compat.sounds.__music or game.sound.music end
		return compat.sounds[tag]
	end
	api.luaSoundExists = function(tag) return compat.sounds[tag] ~= nil end
	api.soundFadeIn = function(tag, duration, start, finish)
		local object = sound(tag)
		if object then object:fade(duration, start or 0, finish or 1) end
	end
	api.soundFadeOut = function(tag, duration, finish)
		local object = sound(tag)
		if object then object:fade(duration, object.volume, finish or 0) end
	end
	api.soundFadeCancel = function(tag)
		local object = sound(tag)
		if object then object:cancelFade() end
	end
	for _, property in ipairs({"time", "pitch"}) do
		local name = property:sub(1, 1):upper() .. property:sub(2)
		api["getSound" .. name] = function(tag)
			local object = sound(tag)
			if object then return object[property] * (property == "time" and 1000 or 1) end
		end
		api["setSound" .. name] = function(tag, value)
			local object = sound(tag)
			if object then object[property] = value / (property == "time" and 1000 or 1) end
		end
	end
	-- pauseSound/resumeSound were missing, so any mod that paused a cue during a
	-- cutscene raised "attempt to call a nil value" and stopped its callback.
	api.pauseSound = function(tag)
		compat:_active()
		local object = sound(tag)
		if object then object:pause() end
	end
	api.resumeSound = function(tag)
		compat:_active()
		local object = sound(tag)
		if object then object:play() end
	end

	-- Psych precaches by touching the asset path; doing nothing here is not the
	-- same thing, because a missing asset must still be reported the same way.
	local precache = {precacheImage = "getImage", precacheSound = "getSound", precacheMusic = "getMusic"}
	for entry, getter in pairs(precache) do
		local name = entry
		api[name] = function(asset)
			compat:_active()
			if type(asset) ~= "string" or asset == "" then
				compat:psychWarn(name .. ": missing asset name", true)
				return nil
			end
			local ok, value = pcall(paths[getter], asset)
			if not ok then
				compat:psychWarn(name .. ": " .. tostring(value), true)
				return nil
			end
			return value
		end
	end
	api.debugPrint = function(...) print(...) end
end

return Media
