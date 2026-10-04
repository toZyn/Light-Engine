-- Native scene controls installed into one explicit compatibility context.
local Controls = {}
local utf8 = require "utf8"

local function fail(message) error("[Lua compatibility] " .. message, 3) end
local function number(value, name, zero, negative)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge or
		(not negative and (value < 0 or (not zero and value == 0))) then
		fail(name .. " must be a finite " .. (negative and "number" or zero and "nonnegative number" or "positive number"))
	end
	return value
end
local function rgb(value)
	local hex = tostring(value):gsub("^#", ""):gsub("^0[xX]", "")
	if not hex:match("^%x%x%x%x%x%x$") then fail("color must contain six hexadecimal RGB digits") end
	return Color.fromHEX(tonumber(hex, 16))
end
local function content(value)
	if value == nil then return "" end
	if type(value) ~= "string" and type(value) ~= "number" then fail("text content must be a string or number") end
	value = tostring(value)
	if not utf8.len(value) then fail("text content must be valid UTF-8") end
	return value
end
local function size(value)
	number(value, "text size")
	if value % 1 ~= 0 then fail("text size must be an integer") end
	return value
end

function Controls.install(ctx, api)
	local control = {fonts = {}, effects = {}, completions = {}, requests = {}, nextRequest = 0}
	local contextRef = setmetatable({ctx}, {__mode = "v"})
	local function text(tag)
		local object = ctx:_owned(tag)
		if not object.is or not object:is(Text) then fail("tag must name an owned Text: " .. tostring(tag)) end
		return object
	end
	local function camera(name)
		ctx:_active()
		local aliases = {game = "camGame", hud = "camHUD", other = "camOther", notes = "camNotes"}
		local key = aliases[name] or name
		if key ~= "camGame" and key ~= "camHUD" and key ~= "camOther" and key ~= "camNotes" then fail("unsupported camera: " .. tostring(name)) end
		local object = ctx:_root(key)
		if not object or not object.is or not object:is(Camera) or object.exists == false then fail("name must resolve to a live native Camera: " .. tostring(name)) end
		return object, key
	end
	local function fontRecord(key, fontSize)
		local font
		if key then
			font = paths.getFont(key, fontSize)
			if not font then fail("missing font: " .. key) end
		else font = love.graphics.newFont(fontSize) end
		return {font = font, key = key, size = fontSize, owned = key == nil}
	end
	local function releaseFont(tag)
		local record = control.fonts[tag]
		control.fonts[tag] = nil
		if record and record.owned then record.font:release() end
	end
	local remove = ctx._remove
	ctx._remove = function(self, tag, destroy)
		local result = remove(self, tag, destroy)
		if destroy then releaseFont(tag) end
		return result
	end
	api.makeLuaText = function(tag, value, width, x, y)
		ctx:_active()
		if type(tag) ~= "string" or not tag:match("^[%a_][%w_]*$") then fail("text tag must be an identifier") end
		value = content(value); width = number(width or 0, "text width", true)
		x, y = number(x or 0, "text x", true, true), number(y or 0, "text y", true, true)
		local record = fontRecord(nil, 16)
		local ok, object = pcall(Text, x, y, value, record.font, Color.WHITE, "left", width > 0 and width or nil)
		if not ok then record.font:release(); error(object, 0) end
		if ctx.objects[tag] then ctx:_remove(tag, true) end
		ctx.objects[tag], control.fonts[tag] = object, record
		return object
	end
	api.addLuaText = function(tag) text(tag); return api.addLuaSprite(tag, true) end
	api.removeLuaText = function(tag, destroy) text(tag); return api.removeLuaSprite(tag, destroy) end
	api.setTextString = function(tag, value) local object = text(tag); object.content = content(value); object:__updateDimension() end
	api.setTextColor = function(tag, color) text(tag).color = rgb(color) end
	api.setTextAlignment = function(tag, alignment)
		local object = text(tag)
		if alignment ~= "left" and alignment ~= "center" and alignment ~= "right" and alignment ~= "justify" then fail("unsupported text alignment: " .. tostring(alignment)) end
		object.alignment = alignment
	end
	local function changeFont(tag, key, fontSize)
		local object = text(tag)
		local record = fontRecord(key, size(fontSize))
		local old = control.fonts[tag]
		object.font, control.fonts[tag] = record.font, record
		object:__updateDimension()
		if old and old.owned then old.font:release() end
	end
	api.setTextSize = function(tag, fontSize) text(tag); changeFont(tag, control.fonts[tag].key, fontSize) end
	api.setTextFont = function(tag, key)
		text(tag)
		if type(key) ~= "string" or key == "" then fail("font key must be a nonempty Paths font filename") end
		changeFont(tag, key, control.fonts[tag].size)
	end
	local fields = {shake = "__shakeComplete", flash = "__flashComplete", fade = "__fadeComplete"}
	local function effect(kind, name, duration, forced, tag, color, intensity, axes, fadeIn)
		local object, key = camera(name)
		number(duration, "camera effect duration")
		if tag ~= nil and (type(tag) ~= "string" or tag == "") then fail("camera completion tag must be a nonempty string") end
		local busy = kind == "flash" and object.__flashAlpha > 0 or kind == "fade" and object.__fadeDuration > 0 or kind == "shake" and object.__shakeDuration > 0
		if busy and not forced then return false end
		control.effects[object] = control.effects[object] or {}
		local token = {valid = true, tag = tag, camera = object, name = key, kind = kind}
		local field = fields[kind]
		token.callback = function()
			if ctx.disposed or not token.valid or control.effects[object][kind] ~= token or object[field] ~= token.callback then return end
			object[field] = nil
			control.completions[#control.completions + 1] = token
		end
		local previous = control.effects[object][kind]
		if previous then previous.valid = false end
		control.effects[object][kind] = token
		if kind == "shake" then object:shake(intensity, duration, token.callback, forced, axes)
		elseif kind == "flash" then object:flash(color, duration, token.callback, forced)
		else object:fade(color, duration, fadeIn, token.callback, forced) end
		return true
	end
	api.cameraShake = function(name, intensity, duration, forced, axes, tag)
		number(intensity, "shake intensity", true)
		axes = axes or "xy"
		if axes ~= "x" and axes ~= "y" and axes ~= "xy" then fail("shake axes must be x, y or xy") end
		return effect("shake", name, duration or 1, forced, tag, nil, intensity, axes)
	end
	api.cameraFlash = function(name, color, duration, forced, tag) return effect("flash", name, duration or 1, forced, tag, rgb(color or "FFFFFF")) end
	api.cameraFade = function(name, color, duration, forced, fadeIn, tag) return effect("fade", name, duration or 1, forced, tag, rgb(color or "000000"), nil, nil, fadeIn == true) end
	api.getSongPosition = function()
		ctx:_active(); return (game.sound.music and game.sound.music.time or 0) * 1000
	end
	api.getSongBpm = function() ctx:_active(); return ctx.state.conductor and ctx.state.conductor.bpm or nil end
	api.getSongBeat = function() ctx:_active(); return ctx.state.conductor and ctx.state.conductor.currentBeatFloat or nil end
	local loaders = {image = "getImage", sound = "getSound", music = "getMusic"}
	local function assetKey(key)
		if type(key) ~= "string" or key == "" then fail("asset key must be a nonempty Paths key") end
		return key
	end
	for kind, loader in pairs(loaders) do
		local method = loader
		api["precache" .. kind:sub(1, 1):upper() .. kind:sub(2)] = function(key)
			ctx:_active(); assetKey(key)
			local resource = paths[method](key)
			if not resource then fail("missing asset: " .. key) end
			return resource
		end
	end
	api.cancelAssetRequest = function(tag)
		ctx:_active()
		local token = control.requests[tag]
		if token then token.valid = false; control.requests[tag] = nil end
	end
	api.requestAsset = function(kind, key, tag, callbackName)
		ctx:_active(); assetKey(key)
		if not loaders[kind] then fail("asset request kind must be image, sound or music") end
		if tag == nil then control.nextRequest = control.nextRequest + 1; tag = "asset" .. control.nextRequest end
		if type(tag) ~= "string" or tag == "" then fail("asset request tag must be a nonempty string") end
		callbackName = callbackName or "onAssetLoaded"
		if type(callbackName) ~= "string" or callbackName == "" then fail("asset callback name must be a nonempty string") end
		api.cancelAssetRequest(tag)
		local token = {valid = true, generation = paths.async.getStats().generation}
		control.requests[tag] = token
		paths.async[loaders[kind]](key, function(resource, err)
			local context = contextRef[1]
			-- Check cancellation/generation before touching any returned userdata.
			-- A blocked shared request must not keep a disposed scene/state alive.
			if not context or context.disposed or not token.valid or control.requests[tag] ~= token or token.generation ~= paths.async.getStats().generation then return end
			token.valid = false; control.requests[tag] = nil
			-- Native URL successes pass their URL as argument two, not an error.
			local errorMessage
			if not resource then errorMessage = err or "asset not found: " .. key end
			context:_callback(callbackName, tag, kind, key, resource, errorMessage)
		end)
		return tag
	end
	local update = ctx.update
	ctx.update = function(self, dt)
		self:_active(); number(dt, "elapsed time", true)
		local completed = control.completions; control.completions = {}
		for _, token in ipairs(completed) do
			if token.valid and control.effects[token.camera][token.kind] == token then
				token.valid = false; control.effects[token.camera][token.kind] = nil
				if token.tag then self:_callback("onCameraEffectCompleted", token.tag, token.name, token.kind) end
				if self.disposed then return end
			end
		end
		return update(self, dt)
	end
	local dispose = ctx.dispose
	ctx.dispose = function(self)
		if self.disposed then return end
		for _, token in pairs(control.requests) do token.valid = false end
		control.requests, control.completions = {}, {}
		for object, effects in pairs(control.effects) do
			for kind, token in pairs(effects) do
				token.valid = false
				-- These are Lua fields, safe to detach even after Camera:destroy().
				if object[fields[kind]] == token.callback then
					object[fields[kind]] = nil
					if kind == "shake" then object.__shakeDuration = 0; object.__shakeX, object.__shakeY = 0, 0
					elseif kind == "flash" then object.__flashDuration = 0; object.__flashAlpha = 0
					else object.__fadeDuration = 0; object.__fadeAlpha = 0 end
				end
			end
		end
		control.effects = {}
		dispose(self) -- Native Text destruction clears references before font release.
		for tag in pairs(control.fonts) do releaseFont(tag) end
	end
end

return Controls
