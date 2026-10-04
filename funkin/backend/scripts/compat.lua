-- Explicit, scoped Lua convenience APIs. This does not execute Haxe or translate
-- whole Psych scripts; native scripts choose which callbacks to forward.
local Compat = {}
Compat.__index = Compat

local function fail(message)
	error("[Lua compatibility] " .. message, 3)
end

local function positive(value, name, allowZero)
	if type(value) ~= "number" or value ~= value or value == math.huge or
		value < 0 or (not allowZero and value == 0) then
		fail(name .. " must be a finite " .. (allowZero and "nonnegative" or "positive") .. " number")
	end
	return value
end

local function tokens(path)
	if type(path) ~= "string" or path == "" then fail("invalid property path") end
	local result, position = {}, 1
	while position <= #path do
		local tail = path:sub(position)
		local word = tail:match("^([%a_][%w_]*)") or tail:match("^(%d+)")
		if not word then fail("invalid property path: " .. path) end
		result[#result + 1] = tonumber(word) and tonumber(word) + 1 or word
		position = position + #word
		while path:sub(position, position) == "[" do
			local index = path:sub(position):match("^%[(%d+)%]")
			if not index then fail("invalid property path: " .. path) end
			result[#result + 1] = tonumber(index) + 1
			position = position + #index + 2
		end
		if position <= #path then
			if path:sub(position, position) ~= "." or position == #path then fail("invalid property path: " .. path) end
			position = position + 1
		end
	end
	if type(result[1]) ~= "string" then fail("property path needs a named root") end
	return result
end

function Compat:_active()
	if self.disposed then fail("context is disposed") end
end

function Compat:_root(name)
	local object = self.objects[name]
	if object ~= nil then return object end
	if name == "camGame" then return self.state.camGame or game.camera end
	return self.state[name]
end

function Compat:_resolve(path)
	self:_active()
	local parts = tokens(path)
	if #parts == 1 then
		local target = self.objects[parts[1]] ~= nil and self.objects or self.state
		return target, parts[1], self:_root(parts[1])
	end
	local object = self:_root(parts[1])
	for i = 2, #parts - 1 do
		if object == nil then fail("missing property in " .. path) end
		object = object[parts[i]]
	end
	if object == nil then fail("missing property in " .. path) end
	return object, parts[#parts], object[parts[#parts]]
end

function Compat:_object(tag)
	self:_active()
	local _, _, object = self:_resolve(tag)
	if not object then fail("missing object: " .. tostring(tag)) end
	return object
end

function Compat:_owned(tag)
	self:_active()
	if not self.objects[tag] then fail("sprite tag is not owned by this context: " .. tostring(tag)) end
	return self.objects[tag]
end

function Compat:_remove(tag, destroy)
	local object = self:_owned(tag)
	if self.added[tag] then self.state:remove(object); self.added[tag] = nil end
	if destroy then
		object:destroy()
		if self.textures[tag] then self.textures[tag]:release(); self.textures[tag] = nil end
		self.objects[tag] = nil
	end
	return object
end

function Compat:_sprite(tag, image, x, y, animated)
	self:_active()
	if type(tag) ~= "string" or not tag:match("^[%a_][%w_]*$") then fail("sprite tag must be an identifier") end
	if self.objects[tag] then self:_remove(tag, true) end
	local asset
	if image and image ~= "" then
		asset = animated and paths.getAtlas(image) or paths.getImage(image)
		if not asset then fail("missing " .. (animated and "atlas" or "image") .. ": " .. image) end
	end
	local object = Sprite(x or 0, y or 0)
	if asset then
		if animated then object:setFrames(asset) else object:loadTexture(asset) end
	end
	self.objects[tag] = object
	return object
end

function Compat:_callback(name, ...)
	if self.disposed or self.script.closed then return end
	if self.calling[name] then fail("recursive callback forwarding: " .. name .. "; choose a distinct callbackNames target") end
	self.calling[name] = true
	local result = self.script:call(name, ...)
	self.calling[name] = nil
	return result
end

local callbacks = {
	create = "onCreate", postCreate = "onCreatePost", postUpdate = "onUpdatePost",
	step = "onStepHit", postStep = "onStepHitPost", beat = "onBeatHit",
	postBeat = "onBeatHitPost", songStart = "onSongStart", endSong = "onEndSong", event = "onEvent"
}

function Compat:forward(nativeName, ...)
	self:_active()
	if nativeName == "step" or nativeName == "beat" then
		self.script:set(nativeName == "step" and "curStep" or "curBeat", select(1, ...))
	end
	if nativeName == "event" then
		local event = ...
		if type(event) ~= "table" then fail("event forwarding requires a native chart event") end
		local values = event.v
		if type(values) == "table" and values[1] ~= nil then
			return self:_callback(self.callbackNames.event, event.e, values[1], values[2])
		end
		return self:_callback(self.callbackNames.event, event.e, values, nil)
	end
	local callback = self.callbackNames[nativeName]
	if not callback then fail("unsupported native callback: " .. tostring(nativeName)) end
	return self:_callback(callback, ...)
end

function Compat:update(dt)
	self:_active()
	positive(dt, "elapsed time", true)
	self:_callback("onUpdate", dt)
	if self.disposed then return end
	-- Completion callbacks can cancel peers or dispose the entire context.
	-- Snapshot handles so native manager array mutation cannot skip/crash work.
	local timers = {}; for i, timer in ipairs(self.timer.instances) do timers[i] = timer end
	for i = #timers, 1, -1 do
		timers[i]:update(dt)
		if self.disposed then return end
	end
	-- Native Tween does not clamp overshoot before easing. Clamp here so a
	-- long frame ends at its target without invalid circular-easing values.
	local tweens = {}; for i, tween in ipairs(self.tween.instances) do tweens[i] = tween end
	for i = #tweens, 1, -1 do
		local tween = tweens[i]
		if self.tweens[tween.compatTag] == tween then
			tween:update(math.min(dt, math.max(0, tween.duration - tween.time)))
		end
		if self.disposed then return end
	end
	-- Sounds belong to the global SoundManager; it updates them once per frame.
end

function Compat:_cancelTween(tag)
	local tween = self.tweens[tag]
	if tween then tween:destroy(); self.tweens[tag] = nil end
end

function Compat:_tween(tag, path, value, duration, ease)
	self:_active()
	positive(duration, "tween duration")
	if type(tag) ~= "string" or tag == "" then fail("tween tag must be a nonempty string") end
	local object, key, current = self:_resolve(path)
	if type(current) ~= "number" or type(value) ~= "number" then fail("tweens require numeric properties") end
	ease = ease or "linear"
	if type(ease) ~= "string" or not Ease[ease] then fail("unsupported easing: " .. tostring(ease)) end
	self:_cancelTween(tag)
	local tween
	tween = self.tween:tween(object, {[key] = value}, duration, {
		ease = ease, onComplete = function()
			if self.tweens[tag] == tween then
				self.tweens[tag] = nil
				self:_callback("onTweenCompleted", tag)
			end
		end
	})
	self.tweens[tag] = tween
	tween.compatTag = tag
	return tween
end

function Compat:_stopSound(tag)
	local sound = self.sounds[tag]
	if sound then
		self.sounds[tag] = nil
		game.sound.list:remove(sound)
		sound:destroy()
	end
end

function Compat:_playSound(key, volume, tag, music, looped)
	self:_active()
	local asset = music and paths.getMusic(key) or paths.getSound(key)
	if not asset then fail("missing audio: " .. tostring(key)) end
	if tag == nil or tag == "" then
		self.nextSound = self.nextSound + 1
		tag = "__sound" .. self.nextSound
	end
	self:_stopSound(tag)
	local sound = Sound()
	sound:load(asset, false, function()
		if self.sounds[tag] == sound then
			self:_stopSound(tag)
			self:_callback("onSoundFinished", tag)
		end
	end)
	self.sounds[tag] = sound
	game.sound.list:add(sound)
	sound:play(volume or 1, looped or false)
	return tag
end

function Compat.new(state, script)
	if not state or not state.add or not state.remove or not state.members then fail("state must be a native Group/State") end
	if not script or script.closed or not script.variables or not script.set or not script.call then fail("script must be an open native Script") end
	if script._compatibility and not script._compatibility.disposed then fail("script already has a compatibility context") end
	local self = setmetatable({state = state, script = script, objects = {}, added = {}, textures = {},
		timers = {}, tweens = {}, sounds = {}, installed = {}, previous = {}, nextSound = 0,
		timer = TimerManager(), tween = Tween(), callbackNames = {}, calling = {}}, Compat)
	for name, callback in pairs(callbacks) do self.callbackNames[name] = callback end
	local api = {}
	api.getProperty = function(path) local _, _, value = self:_resolve(path); return value end
	api.setProperty = function(path, value)
		local object, key, old = self:_resolve(path)
		if old == nil then fail("missing property: " .. path) end
		object[key] = value; return true
	end
	local function groupPath(group, index, property)
		positive(index, "group index", true)
		if index % 1 ~= 0 then fail("group index must be an integer") end
		local object = self:_object(group)
		return group .. (object.members and ".members" or "") .. "[" .. index .. "]." .. tostring(property)
	end
	api.getPropertyFromGroup = function(group, index, property) return api.getProperty(groupPath(group, index, property)) end
	api.setPropertyFromGroup = function(group, index, property, value) return api.setProperty(groupPath(group, index, property), value) end
	api.makeLuaSprite = function(tag, image, x, y) return self:_sprite(tag, image, x, y, false) end
	api.makeAnimatedLuaSprite = function(tag, image, x, y) return self:_sprite(tag, image, x, y, true) end
	api.makeGraphic = function(tag, width, height, color)
		local sprite = self:_owned(tag)
		positive(width, "graphic width"); positive(height, "graphic height")
		if width % 1 ~= 0 or height % 1 ~= 0 then fail("graphic dimensions must be integers") end
		local hex = tostring(color or "FFFFFF"):gsub("^#", ""):gsub("^0[xX]", "")
		if not hex:match("^%x%x%x%x%x%x$") then fail("graphic color must be six hexadecimal RGB digits") end
		local data = love.image.newImageData(width, height)
		data:mapPixel(function() return 1, 1, 1, 1 end)
		local texture = love.graphics.newImage(data); data:release()
		if self.textures[tag] then self.textures[tag]:release() end
		self.textures[tag] = texture
		sprite.frames = nil; sprite.animation.curAnim = nil
		sprite:loadTexture(texture); sprite.color = Color.fromHEX(tonumber(hex, 16))
		sprite.scale:set(1, 1); sprite:updateHitbox()
		return sprite
	end
	api.addLuaSprite = function(tag, front)
		local sprite = self:_owned(tag)
		if self.added[tag] then self.state:remove(sprite) end
		if front then self.state:add(sprite) else self.state:insert(1, sprite) end
		self.added[tag] = true; return sprite
	end
	api.removeLuaSprite = function(tag, destroy) return self:_remove(tag, destroy ~= false) end
	api.getObjectOrder = function(tag)
		local sprite = self:_object(tag)
		for i, member in ipairs(self.state.members) do if member == sprite then return i - 1 end end
		return -1
	end
	api.setObjectOrder = function(tag, index)
		local sprite = self:_owned(tag)
		positive(index, "object order", true)
		if index % 1 ~= 0 or index >= #self.state.members or not self.added[tag] then fail("object order is outside the state") end
		self.state:remove(sprite); self.state:insert(index + 1, sprite)
	end
	api.setObjectCamera = function(tag, camera)
		local names = {game = "camGame", hud = "camHUD", other = "camOther", notes = "camNotes"}
		local name = names[camera] or camera
		if name ~= "camGame" and name ~= "camHUD" and name ~= "camOther" and name ~= "camNotes" then fail("unsupported camera: " .. tostring(camera)) end
		local target = self:_root(name)
		if not target then fail("camera is unavailable: " .. name) end
		self:_object(tag).cameras = {target}
	end
	api.scaleObject = function(tag, x, y, updateHitbox)
		local object = self:_object(tag); object.scale:set(x, y or x)
		if updateHitbox ~= false then object:updateHitbox() end
	end
	api.setScrollFactor = function(tag, x, y) self:_object(tag).scrollFactor:set(x, y) end
	api.updateHitbox = function(tag) self:_object(tag):updateHitbox() end
	api.screenCenter = function(tag, axes) self:_object(tag):screenCenter(axes) end
	api.addAnimationByPrefix = function(tag, name, prefix, fps, looped)
		local object = self:_object(tag)
		object.animation:addByPrefix(name, prefix, fps or 24, looped == true)
		if not object.animation:has(name) then fail("animation prefix has no frames: " .. prefix) end
	end
	api.addAnimationByIndices = function(tag, name, prefix, indices, fps, looped)
		local list = indices
		if type(indices) == "string" then
			list = {}; for item in indices:gmatch("[^,]+") do
				local index = tonumber(item)
				if not index or index < 0 or index % 1 ~= 0 then fail("animation indices must be zero-based integers") end
				list[#list + 1] = index
			end
		end
		if type(list) ~= "table" or #list == 0 then fail("animation indices must be a nonempty table or comma-separated string") end
		local object = self:_object(tag)
		object.animation:addByIndices(name, prefix, list, "", fps or 24, looped == true)
		if not object.animation:has(name) or #object.animation:get(name).frames == 0 then fail("animation indices have no frames") end
	end
	api.addOffset = function(tag, name, x, y)
		local animation = self:_object(tag).animation:get(name)
		if not animation then fail("missing animation: " .. name) end
		animation.offset:set(x or 0, y or 0)
	end
	api.playAnim = function(tag, name, force, reversed, frame)
		local object = self:_object(tag)
		if not object.animation:has(name) then fail("missing animation: " .. tostring(name)) end
		object.animation:play(name, force, nil, reversed)
		if frame then
			positive(frame, "animation frame", true)
			local animation = object.animation.curAnim
			if frame % 1 ~= 0 or frame >= #animation.frames then fail("animation frame is out of range") end
			animation.frame = frame + 1
		end
	end
	api.objectPlayAnimation = api.playAnim
	api.doTweenProperty = function(tag, path, value, duration, ease) return self:_tween(tag, path, value, duration, ease) end
	for _, property in ipairs({"x", "y", "alpha", "angle", "zoom"}) do
		local key = property
		api["doTween" .. key:sub(1, 1):upper() .. key:sub(2)] = function(tag, object, value, duration, ease)
			return self:_tween(tag, object .. "." .. key, value, duration, ease)
		end
	end
	api.cancelTween = function(tag) self:_active(); self:_cancelTween(tag) end
	api.cancelTimer = function(tag)
		self:_active(); if self.timers[tag] then self.timers[tag]:cancel(); self.timers[tag] = nil end
	end
	api.runTimer = function(tag, seconds, loops)
		self:_active(); positive(seconds, "timer interval")
		loops = loops == nil and 1 or loops; positive(loops, "timer loops", true)
		if loops % 1 ~= 0 then fail("timer loops must be an integer") end
		if type(tag) ~= "string" or tag == "" then fail("timer tag must be a nonempty string") end
		api.cancelTimer(tag)
		local timer = Timer(self.timer); self.timers[tag] = timer
		timer:start(seconds, function(instance)
			if self.timers[tag] ~= instance then return end
			local left = loops == 0 and 0 or math.max(0, loops - instance.elapsedLoops)
			if loops ~= 0 and left == 0 then self.timers[tag] = nil end
			self:_callback("onTimerCompleted", tag, instance.elapsedLoops, left)
		end, loops)
		return timer
	end
	api.playSound = function(key, volume, tag) return self:_playSound(key, volume, tag, false, false) end
	api.playMusic = function(key, volume, looped) return self:_playSound(key, volume, "__music", true, looped ~= false) end
	api.stopSound = function(tag) self:_active(); self:_stopSound(tag) end
	for name, method in pairs({pauseSound = "pause", resumeSound = "play"}) do
		local action = method
		api[name] = function(tag) self:_active(); if self.sounds[tag] then self.sounds[tag][action](self.sounds[tag]) end end
	end
	api.setSoundVolume = function(tag, volume) self:_active(); if self.sounds[tag] then self.sounds[tag].volume = volume end end
	api.getSoundVolume = function(tag) self:_active(); return self.sounds[tag] and self.sounds[tag].volume end
	api.runHaxeCode = function() fail("runHaxeCode is unsupported; use native Lua engine APIs") end
	api.runHaxeFunction = function() fail("runHaxeFunction is unsupported; use native Lua engine APIs") end
	require("funkin.backend.scripts.compat-controls").install(self, api)
	for name, fn in pairs(api) do
		self.previous[name] = rawget(script.variables, name)
		self.installed[name] = fn; script:set(name, fn)
	end
	script._compatibility = self
	if script.closeCallback then
		self.onClose = function()
			self.closing = true
			self:dispose()
			self.closing = false
		end
		script.closeCallback:add(self.onClose)
	end
	return self
end

function Compat:dispose()
	if self.disposed then return end
	self.timer:clear(); self.tween:clear()
	local tags = {}; for tag in pairs(self.objects) do tags[#tags + 1] = tag end
	for _, tag in ipairs(tags) do self:_remove(tag, true) end
	tags = {}; for tag in pairs(self.sounds) do tags[#tags + 1] = tag end
	for _, tag in ipairs(tags) do self:_stopSound(tag) end
	if self.script.variables then
		for name, fn in pairs(self.installed) do
			if rawget(self.script.variables, name) == fn then self.script:set(name, self.previous[name]) end
		end
	end
	-- Signal dispatch iterates its live array; removing our listener while it is
	-- executing would skip the listener after us. A closed Script cannot repeat.
	if self.onClose and not self.closing then self.script.closeCallback:remove(self.onClose) end
	if self.script._compatibility == self then self.script._compatibility = nil end
	self.disposed = true
end

return Compat
