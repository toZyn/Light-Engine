local Notes = {}
local PsychSkin = require "funkin.backend.scripts.psych.note-skin"
local receptorFields = {x = true, y = true, angle = true, alpha = true, visible = true, direction = true}
local noteFields = {
	noteType = "type", noteData = "direction", ignoreNote = "ignoreNote", noAnimation = "noAnimation",
	wasGoodHit = "wasGoodHit", tooLate = "tooLate", alpha = "alpha", visible = "visible",
	gfNote = "gf", hitHealth = "hitHealth", missHealth = "missHealth",
	hitCausesMiss = "hitCausesMiss", noMissAnimation = "noMissAnimation",
	-- Fields Psych mods read and do arithmetic with in note callbacks. Leaving them
	-- out answered nil, which surfaced as "attempt to perform arithmetic on a nil
	-- value" inside otherwise healthy onCreate/onStepHit handlers.
	speed = "speed", angle = "angle", offsetX = "offsetX",
	offsetY = "offsetY", scaleX = "scaleX", scaleY = "scaleY", column = "direction",
	sustainNote = "sustainNote", animationPlayed = "animationPlayed",
	hitByOpponent = "hitByOpponent", prevNote = "prevNote", nextNote = "nextNote",
	rating = "rating", hits = "hits", misses = "misses",
}
local editable = {
	ignoreNote = true, noAnimation = true, alpha = true, visible = true, gfNote = true,
	hitHealth = true, missHealth = true, hitCausesMiss = true, noMissAnimation = true,
	speed = true, offsetX = true, offsetY = true, scaleX = true, scaleY = true,
	angle = true, column = true, -- column writes through to noteData, like Psych
}
-- Psych leaves these at 0/false on a fresh note; returning nil here is what broke
-- mods that immediately use the value in arithmetic.
local defaults = {
	hitHealth = 0.023, missHealth = 0.0475, hitCausesMiss = false, noMissAnimation = false,
	gfNote = false, speed = 1, angle = 0, offsetX = 0, offsetY = 0,
	scaleX = 1, scaleY = 1, column = 0, hits = 0, misses = 0,
}

function Notes.note(note, playerField, state)
	-- Writes the native Note cannot model are remembered here and replayed by
	-- Notes.replay when the note object is replaced (skin change, respawn).
	local extra = {}
	local proxy
	proxy = setmetatable({}, {
		__index = function(_, key)
			if key == "texture" then return note.skin.psychTexture or (state and state.psychArrowSkin) or "" end
			if key == "strumTime" then return note.time * 1000 end
			if key == "sustainLength" then return (note.sustainTime or 0) * 1000 end
			if key == "mustPress" then return note.parent == playerField end
			if key == "isSustainNote" then return false end
			if key == "noteType" then return note.type or "" end
			if key == "extraParams" then return extra end
			local native = noteFields[key]
			if native then
				local value = note[native]
				if value ~= nil then return value end
				return defaults[key]
			end
			-- Psych exposes a fixed set of numeric note fields. Answering nil for a
			-- known one is what turned into "arithmetic on a nil value" inside the
			-- mod, far from the read that caused it.
			if defaults[key] ~= nil then return defaults[key] end
			return extra[key]
		end,
		__newindex = function(_, key, value)
			if key == "texture" and state then
				local base = note.parent and note.parent.skin or note.skin
				local skin = PsychSkin.resolve(state, base, value)
				if skin then
					if value ~= "" then skin = PsychSkin.withoutRgb(state, skin) end
					note:setSkin(skin)
				end
				return
			end
			local native = noteFields[key]
			if not editable[key] and not (native and editable[native]) then
				-- Psych lets mods stash anything on a note (onSpawnNote callbacks are
				-- the usual place). Remember it and keep the callback alive.
				extra[key] = value
				return
			end
			if key == "ignoreNote" then note.psychIgnoreNote = true end
			if key == "hitHealth" or key == "missHealth" then
				value = tonumber(value) or value
			end
			note[native or key] = value
		end
	})
	return proxy
end

local function receptor(field, index)
	local lane = field and field.lanes[index]
	if not lane then return end
	local object = lane.receptor
	local function transform(key)
		local scale = field.groupScale[key] * field.scale[key]
		if key == "y" and field.downscroll then scale = -scale end
		local origin = field.groupOrigin[key]
		local offset = field[key] + lane[key]
		if key == "x" then offset = offset - field.__offsetX end
		offset = origin + (offset - origin) * field.groupScale[key]
		return scale, offset
	end
	return setmetatable({}, {
		__index = function(_, key)
			if key == "x" or key == "y" then
				local scale, offset = transform(key)
				return offset + object[key] * scale
			end
			if key == "direction" then return 90 + object.directions.z end
			if receptorFields[key] then return object[key] end
		end,
		__newindex = function(_, key, value)
			if not receptorFields[key] then
				-- Receptors answer extra reads from the native object; writes the engine
				-- cannot model land there directly instead of killing the callback.
				pcall(function() object[key] = value end)
				return
			end
			if key == "x" or key == "y" then
				local scale, offset = transform(key)
				if scale == 0 then return end
				value = (value - offset) / scale
			end
			if key == "direction" then object.directions.z = value - 90
			else object[key] = value end
		end
	})
end

function Notes.install(compat, api)
	local state = compat.state
	local function count(field, kind)
		return field and #field[kind] or 0
	end
	local function fields(group)
		if group == "playerStrums" then return state.playerNotefield end
		if group == "opponentStrums" then return state.enemyNotefield end
		return state.enemyNotefield, state.playerNotefield
	end
	local function kind(group)
		return group == "notes" and "activeNotes" or "lanes"
	end

	local function member(group, index)
		if type(index) ~= "number" or index < 0 or index % 1 ~= 0 then return end
		local first, second = fields(group)
		local size = count(first, kind(group))
		local field, position = first, index + 1
		if index >= size then field, position = second, index - size + 1 end
		if group ~= "notes" then return receptor(field, position) end
		local note = field and field.activeNotes[position]
		if note then return Notes.note(note, state.playerNotefield, state) end
	end

	local groups = {notes = true, strumLineNotes = true, playerStrums = true, opponentStrums = true}
	local get, set = api.getPropertyFromGroup, api.setPropertyFromGroup
	api.getPropertyFromGroup = function(group, index, property)
		if not groups[group] then return get(group, index, property) end
		local object = member(group, index)
		if object then return object[property] end
	end
	api.setPropertyFromGroup = function(group, index, property, value)
		if not groups[group] then return set(group, index, property, value) end
		local object = member(group, index)
		-- Psych indexes group members with #group at the boundary; a miss is a no-op
		-- in Psych, not a script failure. Out-of-range writes are dropped.
		if not object then return false end
		object[property] = value
		return true
	end
	local getProperty = api.getProperty
	api.getProperty = function(path)
		local group = path:match("^([%w_]+)%.length$")
		if not groups[group] then return getProperty(path) end
		local first, second = fields(group)
		return count(first, kind(group)) + count(second, kind(group))
	end

	for _, property in ipairs({"x", "y", "alpha", "angle", "direction"}) do
		local name = "noteTween" .. property:sub(1, 1):upper() .. property:sub(2)
		api[name] = function(tag, index, value, duration, ease)
			local object = assert(member("strumLineNotes", index), "Psych receptor index out of range")
			compat:_tweenObject(tag, object, property, value, duration, ease, "strumLineNotes." .. tostring(index) .. "." .. property)
		end
	end
	compat.psychNoteIndex = function(note)
		local index = table.find(note.parent.activeNotes, note)
		if not index then return -1 end
		if note.parent == state.playerNotefield then
			index = index + count(state.enemyNotefield, "activeNotes")
		end
		return index - 1
	end
	return function(gameProxy)
		for name in pairs(groups) do
			local members = setmetatable({}, {__index = function(_, index) return member(name, index) end})
			gameProxy[name] = setmetatable({members = members}, {
				__index = function(_, key)
					if key == "length" then return api.getProperty(name .. ".length") end
				end
			})
		end
	end
end

return Notes
