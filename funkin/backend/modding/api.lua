local JSON = require "funkin.backend.jsonbuilder"

local ModAPI = {}

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

---Creates a Sprite or Animated Atlas Sprite automatically.
---@param key string Image or Atlas key inside images/
---@param x? number
---@param y? number
---@param opts? table {scale, scroll, alpha, camera, anims, play, add, behind, center, color}
function ModAPI.sprite(key, x, y, opts)
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
	return spr
end

---Creates a styled Text object (defaults to HUD camera when in PlayState).
function ModAPI.text(content, x, y, size, opts)
	opts = opts or {}
	local fontName = opts.font or "vcr.ttf"
	local font = paths.getFont(fontName, size or 20) or love.graphics.getFont()
	local txt = Text(x or 0, y or 0, tostring(content or ""), font,
		opts.color and {Color.get(opts.color)} or Color.WHITE,
		opts.align or "left", opts.limit)
	if opts.outline ~= false then
		txt.outline.width = opts.outlineWidth or 1.5
		if opts.outlineColor then
			local r, g, b, a = Color.get(opts.outlineColor)
			txt.outline.color = {r, g, b, a}
		end
	end
	if opts.camera == nil then
		local st = game.getState()
		if st and st.camHUD then opts.camera = st.camHUD end
	end
	return applyObjectOptions(txt, opts)
end

---Creates a solid Graphic rectangle.
function ModAPI.graphic(x, y, width, height, color, opts)
	local r, g, b, a = Color.get(color or Color.BLACK)
	local grp = Graphic(x or 0, y or 0, width or 100, height or 100, {r, g, b})
	grp.alpha = (opts and opts.alpha) or a or 1
	return applyObjectOptions(grp, opts)
end

---Ergonomic Tween helper supporting string ease names (e.g. "quadOut", "cubeInOut", "sineOut").
function ModAPI.tween(target, values, duration, ease, onComplete)
	if not target or not values then return nil end
	local easeFn = ease
	if type(ease) == "string" then
		easeFn = Ease[ease] or Ease.linear
	elseif ease == nil then
		easeFn = Ease.quadOut
	end
	local st = game.getState()
	local mgr = (st and st.tween) or Tween
	return mgr:tween(target, values, duration or 0.5, easeFn, onComplete)
end

---Ergonomic Timer helper bound to the current state's timer when available.
function ModAPI.timer(delay, callback, loops)
	if type(callback) ~= "function" then return nil end
	local st = game.getState()
	local mgr = (st and st.timer) or Timer
	if loops and loops ~= 1 then
		return mgr:every(delay or 1, callback, loops > 0 and loops or nil)
	end
	return mgr:after(delay or 0, callback)
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

	if Mods and Mods.loadMods then Mods.loadMods() end
	if Parser and Parser.clearCache then Parser.clearCache() end
	return true, dest
end

return ModAPI
