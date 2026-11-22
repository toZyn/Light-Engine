local Gameplay = {}
local preferences = {
	downScroll = "downScroll", middleScroll = "middleScroll", ghostTapping = "ghostTap",
	noteSplashes = "noteSplash", flashing = "flashingLights", lowQuality = "lowQuality"
}
local stateFields = {health = "health", songScore = "score", songMisses = "misses", songHits = "songHits", combo = "combo", ratingName='ratingName', ratingPercent='ratingPercent', ratingFC='ratingFC',
 totalPlayed='totalPlayed', totalNotesHit='totalNotesHit', BF_X='BF_X', BF_Y='BF_Y', DAD_X='DAD_X', DAD_Y='DAD_Y',
 GF_X='GF_X', GF_Y='GF_Y', ratingsData='ratingsData', ratingStuff='ratingStuff'}
local aliases = {boyfriend = "boyfriend", dad = "dad", gf = "gf"}
local gameOverFields = {
	characterName = "characterName", deathSoundName = "deathSoundName",
	loopSoundName = "loopSoundName", endSoundName = "endSoundName"
}
local function isPlayStateClass(class)
	return class == "states.PlayState" or class == "PlayState"
end

local function isGameOverClass(class)
	return class == "substates.GameOverSubstate" or class == "GameOverSubstate"
end

local characterFields = {x = true, y = true, alpha = true, visible = true, angle = true, flipX = true}

function Gameplay.install(compat, api)
	local state = compat.state
	api.getPropertyFromClass = function(class, field)
		compat:_active()
		if isGameOverClass(class) and gameOverFields[field] then
			local options = state.psychGameOver
			return options and options[field] or GameOverSubstate[field]
		elseif class == "backend.ClientPrefs" or class == "ClientPrefs" then
			local name = field:gsub("^data%.", "")
			local preference = preferences[name]
			if preference then return ClientPrefs.data[preference] end
			if name == "windowMove" then return false end
		elseif class == "openfl.Lib" then
			local axis = field:match("^application%.window%.([xy])$")
			if axis then
				if love.system.getDevice() == "Mobile" then return 0 end
				local x, y = love.window.getPosition()
				return axis == "x" and x or y
			end
		elseif class == "backend.Conductor" or class == "Conductor" then
			if field == "songPosition" then return api.getSongPosition() end
			if field == "bpm" then return api.getSongBpm() end
			if state.conductor then
				if field == "crochet" then return state.conductor.crotchet end
				if field == "stepCrochet" then return state.conductor.stepCrotchet end
			end
		elseif isPlayStateClass(class) then
			if field == "SONG.arrowSkin" then return state.psychArrowSkin or "" end
			if field == "SONG.disableNoteRGB" then return state.psychDisableNoteRGB == true end
			if field == "isStoryMode" then return PlayState.storyMode end
			if field == "songName" then return PlayState.SONG and PlayState.SONG.song end
		end
		error("Psych class property unavailable: " .. tostring(class) .. "." .. tostring(field), 2)
	end

	api.setPropertyFromClass = function(class, field, value)
		compat:_active()
		if isPlayStateClass(class) and field == "SONG.arrowSkin" and type(value) == "string" then
			state.psychArrowSkin = value
			return true
		end
		if isPlayStateClass(class) and field == "SONG.disableNoteRGB" and type(value) == "boolean" then
			state.psychDisableNoteRGB = value
			return true
		end
		if isGameOverClass(class) and gameOverFields[field] and type(value) == "string" then
			state.psychGameOver = state.psychGameOver or {}
			state.psychGameOver[field] = value
			return true
		end
		error("Psych class property unavailable for writing: " .. tostring(class) .. "." .. tostring(field), 2)
	end

	api.startCountdown = function()
		compat:_active()
		if state.startedCountdown or state.psychStartingCountdown then return false end
		state.psychStartingCountdown = true
		local ok, failure = pcall(state.startCountdown, state)
		state.psychStartingCountdown = false
		if not ok then error(failure, 2) end
		return state.startedCountdown == true
	end

 for _, entry in ipairs({{'Percent','ratingPercent','rating'},{'Name','ratingName','ratingName'},{'FC','ratingFC','ratingFC'}}) do
  local field, global = entry[2], entry[3]
  api['setRating' .. entry[1]] = function(value)
   state[field] = value
   if state.scripts then state.scripts:set(global,value) end
  end
 end
	api.getHealth = function() return state.health end
	api.setHealth = function(health) api.setProperty("health", health) end
	api.addHealth = function(amount) api.setHealth(api.getHealth() + amount) end
	for label, field in pairs({Score = "score", Misses = "misses", Hits = "songHits"}) do
		local function get() return state[field] or 0 end
		local function set(value)
			state[field] = math.modf(tonumber(value) or 0)
			if state.recalculateRating then state:recalculateRating() end
		end
		api["get" .. label] = get
		api["set" .. label] = set
		api["add" .. label] = function(value) set(get() + (tonumber(value) or 0)) end
	end
end

function Gameplay.bind(interpreter, compat, api, gameProxy)
	local state = compat.state
	local characters = {}
	for name, slot in pairs(aliases) do
		local function getCharacter() return assert(state[slot], "Missing Psych character: " .. slot) end
		characters[name] = setmetatable({
			playAnim = function(_, animation, force)
				api.characterPlayAnim(slot, animation, force)
			end
		}, {
			__index = function(_, field)
				if field == "curCharacter" then return getCharacter().char end
				if characterFields[field] then return getCharacter()[field] end
			end,
			__newindex = function(_, field, value)
				assert(characterFields[field], "Unsupported Psych character field: " .. field)
				getCharacter()[field] = value
			end
		})
	end
	setmetatable(gameProxy, {
		__index = function(_, key)
			local field = stateFields[key]
			if field then return state[field] end
			if characters[key] and state[aliases[key]] then return characters[key] end
		end,
		__newindex = function(_, key, value)
			local field = stateFields[key]
			assert(field, "Unsupported Psych PlayState field: " .. tostring(key))
			api.setProperty(field, value)
		end
	})
	local songFields = {song = true, bpm = true, speed = true, stage = true, player1 = true, player2 = true, gfVersion = true}
	local chart = setmetatable({}, {
		__index = function(_, key)
			if key == "arrowSkin" or key == "disableNoteRGB" then
				return api.getPropertyFromClass("PlayState", "SONG." .. key)
			end
			local song = state.SONG
			if song and songFields[key] then return song[key] end
		end,
		__newindex = function(_, key, value)
			api.setPropertyFromClass("PlayState", "SONG." .. key, value)
		end
	})
	local playState = {SONG = chart, instance = gameProxy}
	interpreter:expose("states.PlayState", playState)
	interpreter:bind("PlayState", playState)
	for _, name in ipairs({"getPropertyFromClass", "setPropertyFromClass", "getHealth", "setHealth", "addHealth", "getScore", "setScore", "addScore", "getMisses", "setMisses", "addMisses", "getHits", "setHits", "addHits"}) do
		interpreter:bind(name, api[name])
	end
end

return Gameplay
