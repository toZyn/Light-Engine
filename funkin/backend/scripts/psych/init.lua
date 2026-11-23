local HScript = {}
local Reflection = require "funkin.backend.scripts.psych.reflection"
local Gameplay = require "funkin.backend.scripts.psych.gameplay"
local Notes = require "funkin.backend.scripts.psych.notes"
local createRuntime
local haxeLibraries = {
	FlxG = "flixel", FlxCamera = "flixel", FlxSprite = "flixel", FlxText = "flixel.text", FlxColor = "flixel.util",
	FlxTimer = "flixel.util", FlxTween = "flixel.tweens", FlxEase = "flixel.tweens",
	Paths = "", Conductor = "backend", FlxPoint = "flixel.math", FlxMath = "flixel.math", ShaderFilter = "openfl.filters", FlxGroup = "flixel.group", FlxTypedGroup = "flixel.group"
}

local function runtime()
	if createRuntime then return createRuntime end
	local loadRuntime = assert(love.filesystem.load("funkin/backend/scripts/psych/runtime.lua"))
	local runtimeTable = setmetatable({unpack = unpack}, {__index = table})
	local scope = setmetatable({table = runtimeTable}, {__index = _G})
	scope._G = scope
	setfenv(loadRuntime, scope)()
	createRuntime = assert(scope.lightHScriptCreate)
	return createRuntime
end

local function hexColor(color)
	if type(color) == "number" then return ("%06x"):format(color % 2^24) end
	return color
end

local function installRuntimeShaders(interpreter, compat, gameProxy)
	local runtimeShaders = compat.psychShaderBindings
	local proxies, filters = {}, {}
	local function create(_, name)
		local shader = runtimeShaders.create(name)
		if not shader then return end
		local proxy = {}
		-- Uniform writes on a shader that never compiled must be no-ops: Psych
		-- mods create the proxy and immediately send uniforms, and an error here
		-- aborts onCreate inside the HScript interpreter, which swallows it and
		-- leaves the rest of the script unexecuted.
		local function send(_, uniform, value)
			if not shader:hasUniform(uniform) then
				require("funkin.backend.scripts.psych.reflection").warn(
					"runtime shader uniform " .. tostring(uniform) .. " is not declared")
				return false
			end
			shader:send(uniform, value)
			return true
		end
		proxy.setFloat, proxy.setInt, proxy.setBool = send, send, send
		proxies[proxy] = shader
		return proxy
	end
	local function filter(args)
		local shader = assert(proxies[args[0]], "Expected a Psych runtime shader")
		local object = {}
		filters[object] = shader
		return object
	end

	gameProxy.createRuntimeShader = create
	local class = {}
	interpreter:bind("ShaderFilter", class)
	interpreter:expose("openfl.filters.ShaderFilter", class)
	interpreter:registerConstructor("ShaderFilter", filter)
	interpreter:registerConstructor("openfl.filters.ShaderFilter", filter)
	return function(tag, object, list)
		if not list or list.length == 0 then runtimeShaders.remove(tag); return end
		local shaders = {}
		for index = 0, list.length - 1 do
			local shader = filters[list[index]]
			-- A filter built from a shader that never compiled is skipped instead of
			-- aborting the callback that installed it.
			if shader then shaders[#shaders + 1] = shader end
		end
		if #shaders == 0 then runtimeShaders.remove(tag); return end
		runtimeShaders.filters(tag, object, shaders)
	end, function(tag, object, proxy)
		if not proxy then runtimeShaders.remove(tag); return end
		runtimeShaders.attach(tag, object, assert(proxies[proxy], "Expected a Psych runtime shader"))
	end
end

local function camera(compat, api, name, field, native)
	local function actual()
		local object = native or compat:_root(field)
		-- A PlayState under construction (or a substate) may not own a HUD camera
		-- yet. Returning nil made `game.camHUD.height` nil, and mods that size
		-- their own sprites from it died with
		--   attempt to perform arithmetic on local 'tdGameH' (a nil value).
		-- Fall back to the game camera so reads stay numeric.
		if object == nil and name ~= "game" then return game.camera end
		return object
	end
	local fields = {x = true, y = true, zoom = true, alpha = true, visible = true, angle = true}
	local proxy = {
		shake = function(_, intensity, duration)
			if native then return native:shake(intensity or 0.01, duration or 0.25, nil, true) end
			return api.cameraShake(name, intensity, duration)
		end,
		flash = function(_, color, duration, _, force)
			if native then return native:flash(Color.fromHEX((color or 0xFFFFFFFF) % 2^32), duration or 1, nil, force) end
			return api.cameraFlash(name, hexColor(color), duration, force)
		end,
		fade = function(_, color, duration, fadeIn, _, force)
			if native then return native:fade(Color.fromHEX((color or 0xFF000000) % 2^32), duration or 1, fadeIn, nil, force) end
			return api.cameraFade(name, hexColor(color), duration, force, fadeIn)
		end
	}
	return setmetatable(proxy, {
		__index = function(_, key)
			local object = actual()
			if not object then return end
			if key == "width" or key == "height" or fields[key] then return object[key] end
			if key == "bgColor" then
				return bit.tobit((object.bgColor[4] or 1) * 255 * 2^24
					+ tonumber(Color.toHexString(object.bgColor, false), 16))
			end
		end,
		__newindex = function(_, key, value)
			local object = assert(actual(), "HScript camera is unavailable")
			if key == "bgColor" then
				local color = Color.fromHEX(value)
				color[4] = bit.band(bit.rshift(value, 24), 255) / 255
				object.bgColor = color
				return
			end
			assert(fields[key], "HScript camera field unavailable: " .. tostring(key))
			object[key] = value
		end
	})
end

local function installCameras(interpreter, compat, flxG, cameras, setFilters)
	local owned, serial = {}, 0
	local class = {}
	local function make(args)
		serial = serial + 1
		local native = Camera(args[0] or 0, args[1] or 0, args[2], args[3])
		native.zoom = args[4] or 1
		local proxy = camera(compat, nil, nil, nil, native)
		local token = "_runtimeCamera" .. serial
		owned[proxy] = {native = native, token = token}
		cameras[proxy] = native
		rawset(proxy, "setFilters", function(_, filters) setFilters(token, native, filters) end)
		return proxy
	end
	interpreter:bind("FlxCamera", class)
	interpreter:expose("flixel.FlxCamera", class)
	interpreter:registerConstructor("FlxCamera", make)
	interpreter:registerConstructor("flixel.FlxCamera", make)
	flxG.cameras = {
		add = function(_, proxy, default)
			local entry = assert(owned[proxy], "Expected an owned HScript camera")
			if not table.find(game.cameras.list, entry.native) then game.cameras.add(entry.native, default) end
			return proxy
		end,
		remove = function(_, proxy, destroy)
			local entry = assert(owned[proxy], "Expected an owned HScript camera")
			if destroy ~= false then
				compat.psychShaderBindings.remove(entry.token)
				owned[proxy], cameras[proxy] = nil, nil
			end
			game.cameras.remove(entry.native, destroy ~= false)
		end
	}
	compat.disposePsychCameras = function()
		for _, entry in pairs(owned) do
			if table.find(game.cameras.list, entry.native) then game.cameras.remove(entry.native)
			elseif entry.native.exists then entry.native:destroy() end
		end
	end
end

local function invoke(session, name, ...)
	return session:invoke(name, {...}, select("#", ...))
end

local spriteFields = {
	x = "x", y = "y", alpha = "alpha", visible = "visible", angle = "angle",
	width = "width", height = "height", flipX = "flipX", flipY = "flipY",
	antialiasing = "antialiasing", text = "content"
}
local spriteMethods = {
	updateHitbox = "updateHitbox", screenCenter = "screenCenter",
	setScrollFactor = "setScrollFactor", setGraphicSize = "setGraphicSize"
}

local function installSprites(interpreter, compat, api, gameProxy, cameras, setShader)
	local metadata = setmetatable({}, {__mode = "k"})
	local proxyFor, tagsByObject, parents, children = {}, {}, {}, {}
	local atlases = setmetatable({}, {__mode = "k"})
	local assetPaths = {__name__ = "Paths", image = function(key) return key end}
	function assetPaths.getSparrowAtlas(key)
		local token = {}
		atlases[token] = assert(paths.getAtlas(key), "Missing HScript atlas: " .. tostring(key))
		return token
	end
	interpreter:bind("Paths", assetPaths)
	interpreter:expose("backend.Paths", assetPaths)
	interpreter:expose("Paths", assetPaths)
	local serial = 0
	local function newTag()
		repeat
			serial = serial + 1
		until not compat.objects["_hscript" .. serial]
		return "_hscript" .. serial
	end
	local function detach(tag)
		local parent = parents[tag]
		if parent then
			parents[tag] = nil
			children[parent][tag] = nil
			compat.objects[parent]:remove(compat.objects[tag])
		end
	end
	local remove = compat._remove
	compat._remove = function(self, tag, destroy)
		detach(tag)
		if destroy then
			if children[tag] then
				for child in pairs(children[tag]) do detach(child) end
				children[tag] = nil
			end
			local object = compat.objects[tag]
			if object then tagsByObject[object] = nil end
			proxyFor[tag] = nil
		end
		return remove(self, tag, destroy)
	end
	local function construct(kind, arguments)
		local tag = newTag()
		local x, y = arguments[0] or 0, arguments[1] or 0
		local object
		if kind == "FlxText" then
			object = api.makeLuaText(tag, arguments[3], arguments[2], x, y)
			if arguments[4] then api.setTextSize(tag, arguments[4]) end
		else
			object = api.makeLuaSprite(tag, arguments[2], x, y)
		end
		local proxy = {}
		metadata[proxy], proxyFor[tag], tagsByObject[object] = tag, proxy, tag
		proxy.animation = {
			add = function(_, ...) return api.addAnimation(tag, ...) end,
			addByPrefix = function(_, ...) return api.addAnimationByPrefix(tag, ...) end,
			addByIndices = function(_, name, prefix, indices, postfix, fps, looped)
				local frames = {}
				for index = 0, indices.length - 1 do frames[index + 1] = indices[index] end
				local sprite = compat:_owned(tag)
				sprite.animation:addByIndices(name, prefix, frames, postfix or "", fps or 24, looped == true)
			end,
			play = function(_, ...) return api.playAnim(tag, ...) end
		}
		for method, native in pairs(spriteMethods) do
			proxy[method] = function(_, ...)
				compat:_owned(tag)[native](object, ...)
				return proxy
			end
		end
		proxy.screenCenter = function(_, axes) api.screenCenter(tag, axes); return proxy end
		proxy.setScrollFactor = function(_, xValue, yValue) api.setScrollFactor(tag, xValue, yValue); return proxy end
		proxy.makeGraphic = function(_, width, height, color)
			api.makeGraphic(tag, width, height, hexColor(color))
			return proxy
		end
		proxy.loadGraphic = function(_, image, animated, width, height)
			local asset = assert(paths.getImage(image), "Missing HScript image: " .. tostring(image))
			compat:_owned(tag):loadTexture(asset, animated == true, width, height)
			return proxy
		end
		proxy.destroy = function() api.removeLuaSprite(tag, true) end

		return setmetatable(proxy, {
			__index = function(_, field)
				local sprite = compat:_owned(tag)
				local native = spriteFields[field]
				if native then return sprite[native] end
			end,
			__newindex = function(_, field, value)
				local sprite = compat:_owned(tag)
				local native = spriteFields[field]
				if native then sprite[native] = value; return end
				if field == "shader" then
					setShader(tag, sprite, value)
					return
				end
				if field == "frames" then
					sprite:setFrames(assert(atlases[value], "Expected an HScript atlas"))
					return
				end
				if field == "cameras" then
					local targets = {}
					for index = 0, value.length - 1 do
						local target = cameras[value[index]]
						assert(target, "Unknown HScript camera")
						if type(target) == "string" then target = compat:_root(target) end
						targets[#targets + 1] = assert(target, "HScript camera unavailable")
					end
					sprite.cameras = targets
					return
				end
				error("HScript sprite field unavailable: " .. tostring(field), 2)
			end
		})
	end

	for name, path in pairs({FlxSprite = "flixel.FlxSprite", FlxText = "flixel.text.FlxText"}) do
		local class = {}
		local make = function(args) return construct(name, args) end
		interpreter:expose(path, class)
		interpreter:bind(name, class)
		interpreter:registerConstructor(name, make)
		interpreter:registerConstructor(path, make)
	end
	local function group()
		local tag = newTag()
		local object = SpriteGroup()
		compat.objects[tag], children[tag] = object, {}
		local proxy = {}
		metadata[proxy], proxyFor[tag], tagsByObject[object] = tag, proxy, tag
		local function childTag(sprite)
			local child = assert(metadata[sprite], "Expected an HScript group member")
			assert(compat.objects[child], "HScript group member was destroyed")
			local cursor = tag
			while cursor do
				assert(cursor ~= child, "HScript groups cannot contain themselves")
				cursor = parents[cursor]
			end
			return child
		end
		function proxy:insert(index, sprite)
			local child = childTag(sprite)
			detach(child)
			if compat.added[child] then
				compat.state:remove(compat.objects[child])
				compat.added[child] = nil
			end
			object:insert(math.min(math.max(index, 0), #object.members) + 1, compat.objects[child])
			parents[child], children[tag][child] = tag, true
			return sprite
		end
		function proxy:add(sprite) return self:insert(#object.members, sprite) end
		function proxy:remove(sprite)
			local child = metadata[sprite]
			if parents[child] == tag then detach(child) end
			return sprite
		end
		function proxy:forEach(callback)
			local members = {}
			for _, child in ipairs(object.members) do members[#members + 1] = child end
			for _, child in ipairs(members) do
				local memberTag = tagsByObject[child]
				if memberTag and parents[memberTag] == tag then callback(proxyFor[memberTag]) end
			end
		end
		function proxy:destroy() api.removeLuaSprite(tag, true) end
		proxy.members = setmetatable({}, {__index = function(_, index)
			if index == "length" then return #object.members end
			if type(index) ~= "number" then return end
			local member = object.members[index + 1]
			return proxyFor[tagsByObject[member]]
		end})
		return setmetatable(proxy, {
			__index = function(_, key)
				if key == "length" then return #object.members end
				if key == "visible" or key == "alpha" or key == "active" then return object[key] end
			end,
			__newindex = function(_, key, value)
				assert(key == "visible" or key == "alpha" or key == "active", "Unsupported HScript group field")
				object[key] = value
			end
		})
	end
	for _, name in ipairs({"FlxGroup", "FlxTypedGroup"}) do
		local class = {}
		interpreter:bind(name, class)
		interpreter:expose("flixel.group." .. name, class)
		interpreter:expose("flixel.group.FlxGroup." .. name, class)
		interpreter:registerConstructor(name, group)
		interpreter:registerConstructor("flixel.group." .. name, group)
		interpreter:registerConstructor("flixel.group.FlxGroup." .. name, group)
	end
	gameProxy.add = function(_, sprite)
		local tag = assert(metadata[sprite], "Expected an HScript sprite")
		detach(tag)
		api.addLuaSprite(tag, true)
		return sprite
	end
	gameProxy.remove = function(_, sprite)
		api.removeLuaSprite(assert(metadata[sprite], "Expected an HScript sprite"), false)
		return sprite
	end
	gameProxy.insert = function(_, index, sprite)
		local tag = assert(metadata[sprite], "Expected an HScript sprite")
		detach(tag)
		api.addLuaSprite(tag, true)
		api.setObjectOrder(tag, index)
		return sprite
	end
end

function HScript.install(compat, api)
	local session
	local script = compat.script
	Gameplay.install(compat, api)
	require("funkin.backend.scripts.psych.input").install(compat, api)
	require("funkin.backend.scripts.psych.utilities").install(compat, api)
	require("funkin.backend.scripts.psych.files").install(compat, api)
	require("funkin.backend.scripts.psych.queries").install(compat, api)
	require("funkin.backend.scripts.psych.media").install(compat, api)
	require("funkin.backend.scripts.psych.scripts").install(compat, api)
	local installNoteGroups = Notes.install(compat, api)
	local function getSession()
		if session then return session end
		session = runtime()(script.path)
		local camGame = camera(compat, api, "game", "camGame")
		local gameProxy = {
			camGame = camGame,
			camHUD = camera(compat, api, "hud", "camHUD"),
			camOther = camera(compat, api, "other", "camOther")
		}
		local flxG = {state = gameProxy, camera = camGame, width = game.width, height = game.height}
		session:expose("flixel.FlxG", flxG)
		session:bind("FlxG", flxG)
		session:bind("game", gameProxy)
		local setFilters, setShader = installRuntimeShaders(session, compat, gameProxy)
		local cameras = {[camGame] = "camGame", [gameProxy.camHUD] = "camHUD", [gameProxy.camOther] = "camOther"}
		for proxy, name in pairs(cameras) do
			rawset(proxy, "setFilters", function(_, filters)
				setFilters("_runtimeShader" .. name, assert(compat:_root(name), "HScript camera unavailable"), filters)
			end)
		end
		installCameras(session, compat, flxG, cameras, setFilters)
		installSprites(session, compat, api, gameProxy, cameras, setShader)
		installNoteGroups(gameProxy)
		Gameplay.bind(session, compat, api, gameProxy)
		require("funkin.backend.scripts.psych.motion").install(session, compat, api)
		require("funkin.backend.scripts.psych.primitives").install(session, api, flxG)
		local colors = {
			__name__ = "flixel.util.FlxColor",
			BLACK = 0xFF000000, WHITE = 0xFFFFFFFF, RED = 0xFFFF0000,
			TRANSPARENT = 0, BLUE = 0xFF0000FF, GREEN = 0xFF008000
		}
		colors.fromRGB = function(red, green, blue, alpha)
			return bit.bor(bit.lshift(alpha or 255, 24), bit.lshift(red, 16), bit.lshift(green, 8), blue)
		end
		session:bind("FlxColor", colors)
		session:expose("flixel.util.FlxColor", colors)
		local countdown = {THREE = 0, TWO = 1, ONE = 2, GO = 3, START = 4}
		session:bind("Countdown", countdown)
		session:expose("states.PlayState.Countdown", countdown)
		session:bind("Function_Continue", Script.Event_Continue)
		session:bind("Function_Stop", Script.Event_Cancel)
		local operations = {
			"getProperty", "setProperty", "getPropertyFromGroup", "setPropertyFromGroup",
			"makeLuaSprite", "makeGraphic", "addLuaSprite", "removeLuaSprite",
			"setObjectCamera", "runTimer", "cancelTimer", "triggerEvent",
			"cameraShake", "cameraFlash", "cameraFade", "playSound", "stopSound",
			"getSongPosition", "getSongBpm", "getSongBeat", "setVar", "getVar",
			"initLuaShader", "setSpriteShader", "removeSpriteShader", "setShaderFloat", "setShaderBool", "setShaderInt",
			"getShaderFloat", "getShaderInt", "getShaderBool", "setShaderSampler2D",
			"setShaderFloatArray", "setShaderIntArray", "setShaderBoolArray",
			"noteTweenX", "noteTweenY", "noteTweenAngle", "noteTweenAlpha", "noteTweenDirection",
			"openCustomSubstate", "closeCustomSubstate", "insertToCustomSubstate",
			"startCountdown", "keyboardPressed", "keyboardJustPressed", "keyboardReleased",
			"startVideo", "startDialogue", "addLuaScript", "addHScript", "removeLuaScript", "removeHScript",
			"isRunning", "getGlobalFromScript", "setGlobalFromScript",
			"getColorFromHex", "loadGraphic", "loadFrames", "setGraphicSize", "setBlendMode",
			"getCharacterX", "getCharacterY", "setCharacterX", "setCharacterY",
			"cameraSetTarget", "setCameraScroll", "setCameraFollowPoint", "getMouseX", "getMouseY",
			"luaSoundExists", "soundFadeIn", "soundFadeOut", "soundFadeCancel", "getSoundTime",
			"setSoundTime", "getSoundPitch", "setSoundPitch", "debugPrint"
		}
		for _, name in ipairs(operations) do
			local operation = api[name]
			if operation then
				session:bind(name, function(...)
					local first = operation(...)
					if type(first) ~= "table" and type(first) ~= "userdata" then return first end
				end)
			end
		end
		for key, value in pairs(script.psychValues or {}) do session:bind(key, value) end
		for _, key in ipairs({"bpm", "crotchet", "stepCrotchet", "curStep", "curBeat", "curMeasure", "startedCountdown"}) do
			session:bind(key, rawget(script.variables, key))
		end
		script.hscriptBind = function(key, value)
			session:bind(key, value)
		end
		return session
	end

	api.setVar = function(key, value)
		compat:_active()
		local state = compat.state
		state.psychVariables = state.psychVariables or {}
		state.psychVariables[key] = Reflection.parseInstance(compat, value)
		return value
	end
	api.getVar = function(key)
		compat:_active()
		local values = compat.state.psychVariables
		if values then return values[key] end
	end

	api.runHaxeCode = function(source, variables, name, args)
		compat:_active()
		local interpreter = getSession()
		if variables ~= nil and type(variables) ~= "table" then error("HScript variables must be a table", 2) end
		for key, value in pairs(variables or {}) do
			if type(key) ~= "string" or not key:match("^[%a_][%w_]*$") then error("Invalid HScript variable name", 2) end
			interpreter:bind(key, value)
		end
		local result = interpreter:eval(source)
		if name then return interpreter:invoke(name, args or {}, args and #args or 0) end
		return result
	end
	api.runHaxeFunction = function(name, args)
		compat:_active()
		if not session then error("Call runHaxeCode before runHaxeFunction", 2) end
		return session:invoke(name, args or {}, args and #args or 0)
	end
	api.addHaxeLibrary = function(name, package)
		local namespace = haxeLibraries[name]
		if namespace and (not package or package == "" or package == namespace
			or name == "Paths" and package == "backend") then
			getSession()
			return true
		end
		-- Psych mods call addHaxeLibrary for classes they only touch defensively
		-- (Assets, File, Type). Psych traces the miss and keeps the script alive, so
		-- do the same instead of aborting onCreate.
		Reflection.warn("addHaxeLibrary(" .. tostring(name) .. ") is not available; the script keeps running")
		return false
	end

	return function(source)
		local interpreter = getSession()
		interpreter:eval(source)
		return function(name, ...) return invoke(interpreter, name, ...) end, function(name) return interpreter:has(name) end
	end
end

HScript.note = Notes.note

return HScript
