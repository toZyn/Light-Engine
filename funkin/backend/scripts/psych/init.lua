local HScript = {}
local createRuntime

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

local function camera(compat, api, name, field)
	local proxy = {
		shake = function(_, intensity, duration) return api.cameraShake(name, intensity, duration) end,
		flash = function(_, color, duration, _, force)
			return api.cameraFlash(name, hexColor(color), duration, force)
		end,
		fade = function(_, color, duration, fadeIn, _, force)
			return api.cameraFade(name, hexColor(color), duration, force, fadeIn)
		end
	}
	return setmetatable(proxy, {
		__index = function(_, key)
			local actual = compat.state[field] or (field == "camGame" and game.camera)
			if actual and (key == "zoom" or key == "alpha" or key == "visible") then return actual[key] end
		end,
		__newindex = function(_, key, value)
			local actual = compat.state[field] or (field == "camGame" and game.camera)
			if not actual or (key ~= "zoom" and key ~= "alpha" and key ~= "visible") then
				error("HScript camera field unavailable: " .. tostring(key), 2)
			end
			actual[key] = value
		end
	})
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

local function installSprites(interpreter, compat, api, gameProxy, cameras)
	local metadata = setmetatable({}, {__mode = "k"})
	local serial = 0
	local function construct(kind, arguments)
		repeat
			serial = serial + 1
		until not compat.objects["_hscript" .. serial]
		local tag = "_hscript" .. serial
		local x, y = arguments[0] or 0, arguments[1] or 0
		local object
		if kind == "FlxText" then
			object = api.makeLuaText(tag, arguments[3], arguments[2], x, y)
			if arguments[4] then api.setTextSize(tag, arguments[4]) end
		else
			object = api.makeLuaSprite(tag, arguments[2], x, y)
		end
		local proxy = {}
		metadata[proxy] = tag
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
		proxy.loadGraphic = function(_, image, animated)
			if animated then error("HScript loadGraphic sprite sheets require an atlas adapter", 2) end
			local asset = assert(paths.getImage(image), "Missing HScript image: " .. tostring(image))
			compat:_owned(tag):loadTexture(asset)
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
				if field == "cameras" then
					local targets = {}
					for index = 0, value.length - 1 do
						local name = cameras[value[index]]
						assert(name, "Unknown HScript camera")
						targets[#targets + 1] = assert(compat:_root(name), "HScript camera unavailable")
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
	gameProxy.add = function(_, sprite)
		api.addLuaSprite(assert(metadata[sprite], "Expected an HScript sprite"), true)
		return sprite
	end
	gameProxy.remove = function(_, sprite)
		api.removeLuaSprite(assert(metadata[sprite], "Expected an HScript sprite"), false)
		return sprite
	end
	gameProxy.insert = function(_, index, sprite)
		local tag = assert(metadata[sprite], "Expected an HScript sprite")
		api.addLuaSprite(tag, true)
		api.setObjectOrder(tag, index)
		return sprite
	end
end

function HScript.install(compat, api)
	local session
	local script = compat.script
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
		installSprites(session, compat, api, gameProxy, {
			[camGame] = "camGame", [gameProxy.camHUD] = "camHUD", [gameProxy.camOther] = "camOther"
		})
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
		session:bind("Function_Continue", Script.Event_Continue)
		session:bind("Function_Stop", Script.Event_Cancel)
		local operations = {
			"getProperty", "setProperty", "getPropertyFromGroup", "setPropertyFromGroup",
			"makeLuaSprite", "makeGraphic", "addLuaSprite", "removeLuaSprite",
			"setObjectCamera", "runTimer", "cancelTimer", "triggerEvent",
			"cameraShake", "cameraFlash", "cameraFade", "playSound", "stopSound",
			"getSongPosition", "getSongBpm", "getSongBeat", "setVar", "getVar"
		}
		for _, name in ipairs(operations) do
			local operation = api[name]
			session:bind(name, function(...)
				local first = operation(...)
				if type(first) ~= "table" and type(first) ~= "userdata" then return first end
			end)
		end
		for _, key in ipairs({"bpm", "crotchet", "stepCrotchet", "curStep", "curBeat", "curMeasure"}) do
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
		state.psychVariables[key] = value
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
		local libraries = {FlxG = "flixel", FlxSprite = "flixel", FlxText = "flixel.text", FlxColor = "flixel.util"}
		if libraries[name] and (not package or package == "" or package == libraries[name]) then
			getSession()
			return true
		end
		error("HScript class unavailable: " .. tostring(name), 2)
	end

	return function(source)
		local interpreter = getSession()
		interpreter:eval(source)
		return function(name, ...) return invoke(interpreter, name, ...) end, function(name) return interpreter:has(name) end
	end
end

function HScript.note(note, playerField)
	local fields = {
		noteType = "type", noteData = "direction", ignoreNote = "ignoreNote",
		noAnimation = "noAnimation", wasGoodHit = "wasGoodHit",
		x = "x", y = "y", alpha = "alpha", visible = "visible"
	}
	return setmetatable({}, {
		__index = function(_, key)
			if key == "strumTime" then return note.time * 1000 end
			if key == "sustainLength" then return (note.sustainTime or 0) * 1000 end
			if key == "mustPress" then return note.parent == playerField end
			if key == "isSustainNote" then return false end
			local native = fields[key]
			if native then return note[native] end
		end,
		__newindex = function(_, key, value)
			if key == "ignoreNote" or key == "noAnimation" or key == "alpha" or key == "visible" then
				note[fields[key]] = value
				return
			end
			error("HScript note field unavailable for writing: " .. tostring(key), 2)
		end
	})
end

return HScript
