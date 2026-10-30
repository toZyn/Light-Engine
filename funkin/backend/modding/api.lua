local JSON = require "funkin.backend.jsonbuilder"

local ModAPI = {
	_objects = {},
	_stateBound = nil
}

local function syncObjectStore()
	local st = game and game.getState and game.getState() or nil
	if ModAPI._stateBound ~= st then
		ModAPI._objects = {}
		ModAPI._stateBound = st
	end
	return ModAPI._objects
end

local function registerTagged(tag, obj)
	if type(tag) == "string" and tag ~= "" and obj ~= nil then
		local store = syncObjectStore()
		store[tag] = obj
	end
	return obj
end

local function resolveCamera(cam)
	local st = game.getState()
	if type(cam) == "string" then
		local lower = cam:lower()
		if st then
			if lower == "hud" or lower == "camhud" then return st.camHUD end
			if lower == "other" or lower == "camother" or lower == "notes" then
				return st.camOther or st.camNotes or st.camHUD
			end
			if lower == "game" or lower == "camgame" then return st.camGame end
		end
		return game.camera
	elseif type(cam) == "table" then
		return cam
	end
	return nil
end

local function applyObjectOptions(obj, opts)
	if not opts then return obj end
	if opts.scale then
		if type(opts.scale) == "table" then
			obj.scale:set(opts.scale[1] or opts.scale.x or 1, opts.scale[2] or opts.scale.y or 1)
		else
			obj.scale:set(opts.scale, opts.scale)
		end
		if obj.updateHitbox then obj:updateHitbox() end
	end
	if opts.scroll ~= nil then
		if type(opts.scroll) == "table" then
			obj.scrollFactor:set(opts.scroll[1] or opts.scroll.x or 1, opts.scroll[2] or opts.scroll.y or 1)
		else
			obj.scrollFactor:set(opts.scroll, opts.scroll)
		end
	end
	if opts.alpha ~= nil then obj.alpha = opts.alpha end
	if opts.angle ~= nil then obj.angle = opts.angle end
	if opts.flipX ~= nil then obj.flipX = opts.flipX end
	if opts.flipY ~= nil then obj.flipY = opts.flipY end
	if opts.antialiasing ~= nil then obj.antialiasing = opts.antialiasing end
	if opts.visible ~= nil then obj.visible = opts.visible end
	if opts.color ~= nil then
		local r, g, b = Color.get(opts.color)
		obj.color = {r, g, b}
	end
	if opts.camera then
		local c = resolveCamera(opts.camera)
		if c then obj.cameras = {c} end
	end
	if opts.center then
		obj:screenCenter(type(opts.center) == "string" and opts.center or "xy")
	end
	if opts.add ~= false then
		local st = game.getState()
		if st and st.add then
			if opts.behind and st.stage then
				st:insert(1, obj)
			else
				st:add(obj)
			end
		end
	end
	return obj
end

---Retrieves a tagged object created via Mod.sprite / Mod.text / Mod.graphic / Mod.button.
function ModAPI.get(tag)
	if type(tag) ~= "string" or tag == "" then return nil end
	return syncObjectStore()[tag]
end

---Removes and destroys a tagged object (or object reference) from the current state.
function ModAPI.remove(targetOrTag)
	local store = syncObjectStore()
	local obj = type(targetOrTag) == "string" and store[targetOrTag] or targetOrTag
	if type(targetOrTag) == "string" then
		store[targetOrTag] = nil
	else
		for k, v in pairs(store) do
			if v == obj then store[k] = nil end
		end
	end
	if not obj then return false end
	local st = game.getState()
	if st and st.remove then
		pcall(st.remove, st, obj)
	end
	if obj.destroy then
		pcall(obj.destroy, obj)
	end
	return true
end

---Creates a Sprite or Animated Atlas Sprite automatically.
---Supports both Mod.sprite(key, x, y, opts) and Mod.sprite(tag, key, x, y, opts).
function ModAPI.sprite(a, b, c, d, e)
	local tag, key, x, y, opts
	if type(a) == "string" and type(b) == "string" then
		tag, key, x, y, opts = a, b, c, d, e
	else
		key, x, y, opts = a, b, c, d
	end

	local spr = Sprite(x or 0, y or 0)
	if key and key ~= "" then
		local xmlExists = paths.exists(paths.getPath("images/" .. key .. ".xml"), "file")
		local txtExists = not xmlExists and paths.exists(paths.getPath("images/" .. key .. ".txt"), "file")
		if xmlExists or txtExists then
			local frames = paths.getAtlas(key)
			if frames then spr:setFrames(frames) end
		else
			local tex = paths.getImage(key)
			if tex then spr:loadTexture(tex) end
		end
	end

	if opts and opts.anims then
		for _, anim in ipairs(opts.anims) do
			local name = anim.name or anim[1]
			local prefix = anim.prefix or anim[2]
			local fps = anim.fps or anim[3] or 24
			local loop = anim.loop ~= nil and anim.loop or (anim[4] or false)
			if name and prefix then
				if anim.indices and #anim.indices > 0 then
					spr.animation:addByIndices(name, prefix, anim.indices, nil, fps, loop)
				else
					spr.animation:addByPrefix(name, prefix, fps, loop)
				end
			end
		end
	end

	applyObjectOptions(spr, opts)
	if opts and opts.play and spr.animation then
		spr.animation:play(opts.play, true)
	end
	return registerTagged(tag, spr)
end

---Creates a styled Text object (defaults to HUD camera when in PlayState).
---Supports Mod.text(content, x, y, size, opts), Mod.text(tag, content, x, y, opts), and Mod.text(tag, content, x, y, size, opts).
function ModAPI.text(a, b, c, d, e, f)
	local tag, content, x, y, size, opts
	if type(a) == "string" and type(b) == "string" then
		tag, content, x, y = a, b, c, d
		if type(e) == "table" then
			opts = e
			size = opts.size
		else
			size, opts = e, f
		end
	else
		content, x, y = a, b, c
		if type(d) == "table" then
			opts = d
			size = opts.size
		else
			size, opts = d, e
		end
	end
	opts = opts and table.clone(opts) or {}
	local fontName = opts.font or "vcr.ttf"
	local font = paths.getFont(fontName, size or opts.size or 20) or love.graphics.getFont()
	local txt = Text(x or 0, y or 0, tostring(content or ""), font,
		opts.color and {Color.get(opts.color)} or Color.WHITE,
		opts.align or "left", opts.limit)
	if opts.outline ~= false then
		txt.outline.width = opts.outlineWidth or 1.5
		if opts.outlineColor then
			local r, g, b2, a2 = Color.get(opts.outlineColor)
			txt.outline.color = {r, g, b2, a2}
		end
	end
	if opts.camera == nil then
		local st = game.getState()
		if st and st.camHUD then opts.camera = st.camHUD end
	end
	return registerTagged(tag, applyObjectOptions(txt, opts))
end

---Creates a solid Graphic rectangle.
---Supports Mod.graphic(x, y, width, height, color, opts) and Mod.graphic(tag, x, y, width, height, color, opts).
function ModAPI.graphic(a, b, c, d, e, f, g)
	local tag, x, y, width, height, color, opts
	if type(a) == "string" then
		tag, x, y, width, height, color, opts = a, b, c, d, e, f, g
	else
		x, y, width, height, color, opts = a, b, c, d, e, f
	end
	local r, gr, bl, al = Color.get(color or Color.BLACK)
	local grp = Graphic(x or 0, y or 0, width or 100, height or 100, {r, gr, bl})
	grp.alpha = (opts and opts.alpha) or al or 1
	return registerTagged(tag, applyObjectOptions(grp, opts))
end

---Creates an interactive UIButton or SpriteButton (mouse, touch, and optional keyboard shortcut).
---Supports:
---  Mod.button(x, y, width, height, label, callback, opts)
---  Mod.button(tag, x, y, width, height, label, callback, opts)
---  Mod.button(tag, x, y, label, callback, opts) / Mod.button(x, y, label, callback, opts)
function ModAPI.button(...)
	local args = {...}
	local idx = 1
	local tag
	if type(args[1]) == "string" and type(args[2]) == "number" then
		tag = args[1]
		idx = 2
	end
	local x = tonumber(args[idx]) or 0
	local y = tonumber(args[idx + 1]) or 0
	local width, height, label, callback, opts
	if type(args[idx + 2]) == "number" and type(args[idx + 3]) == "number" then
		width = args[idx + 2]
		height = args[idx + 3]
		label = args[idx + 4]
		callback = args[idx + 5]
		opts = args[idx + 6]
	else
		width = 160
		height = 40
		label = args[idx + 2]
		callback = args[idx + 3]
		opts = args[idx + 4]
	end
	if type(label) == "function" then
		opts = callback
		callback = label
		label = tag or "Button"
	end
	opts = opts and table.clone(opts) or {}
	if opts.width then width = opts.width end
	if opts.height then height = opts.height end
	if opts.scroll == nil then opts.scroll = 0 end
	if opts.camera == nil then
		local st = game.getState()
		if st and st.camHUD then opts.camera = st.camHUD end
	end

	local btn
	local texKey = opts.atlas or opts.image
	if texKey then
		btn = SpriteButton(x, y, opts.key or "return", texKey, callback)
		if opts.anims then
			for _, anim in ipairs(opts.anims) do
				local name = anim.name or anim[1]
				local prefix = anim.prefix or anim[2]
				local fps = anim.fps or anim[3] or 24
				local loop = anim.loop ~= nil and anim.loop or (anim[4] or false)
				if name and prefix then
					if anim.indices and #anim.indices > 0 then
						btn.animation:addByIndices(name, prefix, anim.indices, nil, fps, loop)
					else
						btn.animation:addByPrefix(name, prefix, fps, loop)
					end
				end
			end
		end
		if opts.play and btn.animation then
			btn.animation:play(opts.play, true)
		end
		btn:updateHitbox()
	else
		btn = ui.UIButton(x, y, width or 160, height or 40, tostring(label or "Button"), callback)
		local fontName = opts.font or "vcr.ttf"
		local fontSize = opts.fontSize or opts.size or 18
		btn.font = paths.getFont(fontName, fontSize) or btn.font
		if opts.key then btn.shortcutKey = tostring(opts.key) end
		if opts.hoveredColor then
			local r, g, b = Color.get(opts.hoveredColor)
			btn.hoveredColor = {r, g, b}
		end
		if opts.pressedColor then
			local r, g, b = Color.get(opts.pressedColor)
			btn.pressedColor = {r, g, b}
		end
		if opts.textColor then
			local r, g, b = Color.get(opts.textColor)
			btn.textColor = {r, g, b}
		end
		if opts.lineColor then
			local r, g, b = Color.get(opts.lineColor)
			btn.lineColor = {r, g, b}
		end
	end

	return registerTagged(tag, applyObjectOptions(btn, opts))
end

---Adds a selectable menu button to MainMenuState (or any state exposing :addMenuButton).
---@param id string Menu option identifier
---@param labelOrCallback string|function Display text (when using AtlasText) or callback function
---@param callbackOrOpts? function|table Selection callback or options table
---@param maybeOpts? table {index, stay, flicker, atlas, idlePrefix, selectedPrefix, useText, font}
function ModAPI.addMenuButton(id, labelOrCallback, callbackOrOpts, maybeOpts)
	local st = game.getState()
	if st and type(st.addMenuButton) == "function" then
		return st:addMenuButton(id, labelOrCallback, callbackOrOpts, maybeOpts)
	end
	return nil
end

---Ergonomic Tween helper supporting string ease names (e.g. "quadOut", "cubeInOut", "sineOut") and tagged targets.
function ModAPI.tween(targetOrTag, values, duration, ease, onComplete)
	local target = type(targetOrTag) == "string" and ModAPI.get(targetOrTag) or targetOrTag
	if not target or not values then return nil end

	local options
	if type(ease) == "table" then
		options = table.clone(ease)
		if onComplete and not options.onComplete then
			options.onComplete = onComplete
		end
	else
		local easeFn = ease
		if type(ease) == "string" then
			easeFn = Ease[ease] or Ease.linear
		elseif ease == nil then
			easeFn = Ease.quadOut
		end
		options = {ease = easeFn, onComplete = onComplete}
	end

	local st = game.getState()
	if st and st.tween and type(st.tween.tween) == "function" then
		return st.tween:tween(target, values, duration or 0.5, options)
	end
	return Tween.tween(target, values, duration or 0.5, options)
end

---Ergonomic Timer helper bound to the current state's timer when available.
function ModAPI.timer(delay, callback, loops)
	if type(callback) ~= "function" then return nil end
	local st = game.getState()
	local mgr = (st and st.timer) or Timer.globalManager
	local t = Timer(mgr)
	t:start(delay or 0, callback, loops or 1)
	return t
end

---Plays a sound effect from sounds/.
function ModAPI.sound(key, volume, pitch)
	local snd = paths.getSound(key)
	if not snd then return nil end
	return util.playSfx(snd, volume or 1, false, true, pitch or 1)
end

---Flashes a camera ("game", "hud", "other").
function ModAPI.flash(color, duration, camName)
	local cam = resolveCamera(camName or "game") or game.camera
	if not cam then return end
	local r, g, b, a = Color.get(color or Color.WHITE)
	cam:flash({r, g, b, a}, duration or 0.5, nil, true)
end

---Shakes a camera ("game", "hud", "other").
function ModAPI.shake(intensity, duration, camName)
	local cam = resolveCamera(camName or "game") or game.camera
	if not cam then return end
	cam:shake(intensity or 0.01, duration or 0.25, nil, true)
end

---Adds an instant camera bop/zoom pulse in PlayState.
function ModAPI.zoom(gameAdd, hudAdd)
	local st = game.getState()
	if not st then return end
	if st.camGame then st.camGame.zoom = st.camGame.zoom + (gameAdd or 0.015) end
	if st.camHUD then st.camHUD.zoom = st.camHUD.zoom + (hudAdd or 0.03) end
end

---Swaps a character ("bf", "dad", "gf") dynamically during gameplay.
function ModAPI.swapCharacter(slot, charName)
	local st = game.getState()
	if not st or not charName or charName == "" then return nil end
	if st.swapCharacter then
		return st:swapCharacter(slot, charName)
	end
	return nil
end

---Triggers a PlayState chart event by name.
function ModAPI.triggerEvent(name, params)
	local st = game.getState()
	if st and st.executeEvent then
		st:executeEvent({e = tostring(name or ""), v = params or {}, t = st.conductor and st.conductor.time or 0})
		return true
	end
	return false
end

---Saves persistent key-value data scoped to the current mod.
function ModAPI.saveData(key, value, modId)
	local id = modId or (Mods and Mods.currentMod) or "_global"
	game.save.data.modData = game.save.data.modData or {}
	game.save.data.modData[id] = game.save.data.modData[id] or {}
	game.save.data.modData[id][tostring(key)] = value
	if ClientPrefs and ClientPrefs.saveData then
		pcall(ClientPrefs.saveData)
	end
	return value
end

---Loads persistent key-value data scoped to the current mod.
function ModAPI.loadData(key, defaultValue, modId)
	local id = modId or (Mods and Mods.currentMod) or "_global"
	local store = game.save.data.modData and game.save.data.modData[id]
	if store and store[tostring(key)] ~= nil then
		return store[tostring(key)]
	end
	return defaultValue
end

---Generates a ready-to-edit mod folder structure on disk (cross-platform).
---@param modId string Folder slug (e.g. "my-awesome-mod")
---@param opts? table {name, description, color}
---@return boolean, string
function ModAPI.createTemplate(modId, opts)
	opts = opts or {}
	local slug = tostring(modId or ""):gsub("^%s+", ""):gsub("%s+$", "")
	slug = slug:gsub("[^%w%-%_ ]", ""):gsub("%s+", "-"):lower()
	if slug == "" then
		return false, "Invalid mod folder name."
	end

	local root = (Mods and Mods.root or "mods") .. "/" .. slug
	if paths.exists(root .. "/meta.json", "file") then
		return false, "Mod '" .. slug .. "' already exists."
	end

	local subdirs = {
		"songs",
		"data/characters",
		"data/stages",
		"data/scripts",
		"data/events",
		"data/notetypes",
		"data/weeks/weeks",
		"images/characters",
		"images/icons",
		"images/menus",
		"sounds",
		"music",
		"fonts"
	}
	for _, dir in ipairs(subdirs) do
		local ok, err = Storage.ensureDir(root .. "/" .. dir)
		if not ok then return false, tostring(err) end
	end

	local meta = {
		name = opts.name and opts.name ~= "" and opts.name or slug:gsub("%-", " "):gsub("^%l", string.upper),
		description = opts.description or "Created with Light Engine Mod Generator.",
		color = opts.color or "#5B8CFF",
		version = "1.0.0"
	}

	local ok, dest = Storage.writeFile(root .. "/meta.json", JSON.encode(meta, true) .. "\n")
	if not ok then return false, dest end

	local starterScript = table.concat({
		"-- Global gameplay script (runs in every song when this mod is active)",
		"-- You can use native Loxel classes or the built-in `Mod` helper API!",
		"",
		"function postCreate()",
		"\t-- Example: Mod.text('Playing ' .. PlayState.SONG.song, 16, 688, 16, {alpha = 0.7})",
		"end",
		"",
		"function beat(curBeat)",
		"\t-- Runs on every musical beat",
		"end",
		""
	}, "\n")
	Storage.writeFile(root .. "/data/scripts/mod-example.lua", starterScript)

	local hurtNoteScript = table.concat({
		"-- Example custom Note Type: 'hurt'",
		"-- Place notes with type 'hurt' in the Chart Editor!",
		"",
		"function noteSpawn(note)",
		"\tif note.type == 'hurt' then",
		"\t\tnote.ignoreNote = true -- Player doesn't miss by ignoring it",
		"\t\tnote.color = {1, 0.25, 0.25}",
		"\tend",
		"end",
		"",
		"function onNoteHit(event)",
		"\tif event.note and event.note.type == 'hurt' and not event.character.isGF then",
		"\t\tstate.health = state.health - 0.35",
		"\t\tMod.shake(0.012, 0.18, 'game')",
		"\tend",
		"end",
		""
	}, "\n")
	Storage.writeFile(root .. "/data/notetypes/hurt.lua", hurtNoteScript)

	local starterWeek = {
		name = meta.name:upper(),
		sprite = "week1",
		chars = {"dad", "bf", "gf"},
		songs = {{"bopeebo", "dad", {146, 113, 253}}},
		difficulties = {"Easy", "Normal", "Hard"}
	}
	Storage.ensureDir(root .. "/data/weeks")
	Storage.writeFile(root .. "/data/weeks/week1.json", JSON.encode(starterWeek, true) .. "\n")

	Storage.ensureDir(root .. "/songs/bopeebo/charts")
	local starterSongMeta = {
		songName = "Bopeebo",
		difficulties = {"easy", "normal", "hard"},
		stage = "stage",
		skin = "default",
		characters = {player = "bf", opponent = "dad", girlfriend = "gf"}
	}
	Storage.writeFile(root .. "/songs/bopeebo/meta.json", JSON.encode(starterSongMeta, true) .. "\n")

	local starterChart = {
		song = {
			song = "bopeebo",
			bpm = 100,
			speed = 1.8,
			needsVoices = false,
			player1 = "bf",
			player2 = "dad",
			gfVersion = "gf",
			stage = "stage",
			skin = "default",
			format = "psych_v1",
			notes = {
				{sectionBeats = 4, mustHitSection = false, sectionNotes = {{0, 4, 0}, {600, 5, 0}, {1200, 6, 0}, {1800, 7, 0}}},
				{sectionBeats = 4, mustHitSection = true, sectionNotes = {{2400, 0, 0}, {3000, 1, 0}, {3600, 2, 0}, {4200, 3, 300}}}
			},
			events = {}
		}
	}
	for _, d in ipairs({"easy", "normal", "hard"}) do
		Storage.writeFile(root .. "/songs/bopeebo/charts/" .. d .. ".json", JSON.encode(starterChart, true) .. "\n")
	end

	if Mods and Mods.reload then Mods.reload() end
	if Parser and Parser.clearCache then Parser.clearCache() end
	return true, dest
end

return ModAPI
