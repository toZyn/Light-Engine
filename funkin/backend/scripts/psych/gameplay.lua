local Gameplay = {}
local preferences = {
	downScroll = "downScroll", middleScroll = "middleScroll", ghostTapping = "ghostTap",
	noteSplashes = "noteSplash", flashing = "flashingLights", lowQuality = "lowQuality"
}
local stateFields = {health = "health", songScore = "score", songMisses = "misses", combo = "combo"}
local aliases = {boyfriend = "boyfriend", dad = "dad", gf = "gf"}
local gameOverFields = {
	characterName = "characterName", deathSoundName = "deathSoundName",
	loopSoundName = "loopSoundName", endSoundName = "endSoundName"
}
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
		elseif class == "backend.Conductor" or class == "Conductor" then
			if field == "songPosition" then return api.getSongPosition() end
			if field == "bpm" then return api.getSongBpm() end
			if state.conductor then
				if field == "crochet" then return state.conductor.crotchet end
				if field == "stepCrochet" then return state.conductor.stepCrotchet end
			end
		elseif class == "states.PlayState" or class == "PlayState" then
			if field == "isStoryMode" then return PlayState.storyMode end
			if field == "songName" then return PlayState.SONG and PlayState.SONG.song end
		end
		error("Psych class property unavailable: " .. tostring(class) .. "." .. tostring(field), 2)
	end

	api.setPropertyFromClass = function(class, field, value)
		compat:_active()
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
	for method, source in pairs({keyboardPressed = "pressed", keyboardJustPressed = "justPressed",
		keyboardReleased = "justReleased"}) do
		api[method] = function(key)
			local keys = game.keys[source]
			return keys and keys[tostring(key):upper()] == true or false
		end
	end

	api.getHealth = function() return state.health end
	api.setHealth = function(health) api.setProperty("health", health) end
	api.addHealth = function(amount) api.setHealth(api.getHealth() + amount) end
	api.getScore = function() return state.score end
	api.setScore = function(score) api.setProperty("score", score) end
	api.addScore = function(amount) api.setScore(api.getScore() + amount) end
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
				if field == "curCharacter" then return getCharacter().name end
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
	for _, name in ipairs({"getPropertyFromClass", "setPropertyFromClass", "getHealth", "setHealth", "addHealth", "getScore", "setScore", "addScore"}) do
		interpreter:bind(name, api[name])
	end
end

return Gameplay
