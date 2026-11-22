local Notes = {}
local PsychSkin = require "funkin.backend.scripts.psych.note-skin"
local receptorFields = {x = true, y = true, angle = true, alpha = true, visible = true, direction = true}
local noteFields = {
	noteType = "type", noteData = "direction", ignoreNote = "ignoreNote", noAnimation = "noAnimation",
	wasGoodHit = "wasGoodHit", tooLate = "tooLate", alpha = "alpha", visible = "visible",
	gfNote = "gf", hitHealth = "hitHealth", missHealth = "missHealth",
	hitCausesMiss = "hitCausesMiss", noMissAnimation = "noMissAnimation"
}
local editable = {
	ignoreNote = true, noAnimation = true, alpha = true, visible = true, gfNote = true,
	hitHealth = true, missHealth = true, hitCausesMiss = true, noMissAnimation = true
}
local defaults = {hitHealth = 0.023, missHealth = 0.0475, hitCausesMiss = false, noMissAnimation = false, gfNote = false}

function Notes.note(note, playerField, state)
	return setmetatable({}, {
		__index = function(_, key)
			if key == "texture" then return note.skin.psychTexture or (state and state.psychArrowSkin) or "" end
			if key == "strumTime" then return note.time * 1000 end
			if key == "sustainLength" then return (note.sustainTime or 0) * 1000 end
			if key == "mustPress" then return note.parent == playerField end
			if key == "isSustainNote" then return false end
			if key == "noteType" then return note.type or "" end
			local native = noteFields[key]
			if native then
				local value = note[native]
				if value ~= nil then return value end
				return defaults[key]
			end
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
			assert(editable[key], "Psych note property unavailable for writing: " .. tostring(key))
			if key == "ignoreNote" then note.psychIgnoreNote = true end
			if key == "hitHealth" or key == "missHealth" then
				value = assert(tonumber(value), "Psych note health must be numeric")
			end
			note[noteFields[key]] = value
		end
	})
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
			assert(receptorFields[key], "Psych receptor property unavailable for writing: " .. tostring(key))
			if key == "x" or key == "y" then
				local scale, offset = transform(key)
				assert(scale ~= 0, "Cannot move a receptor on a zero-scale axis")
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
		assert(member(group, index), "Psych group index out of range")[property] = value
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
			compat:_tweenObject(tag, object, property, value, duration, ease)
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
