local Extras = {}

local Resolve = require "funkin.backend.scripts.psych.resolve"
local Reflection = require "funkin.backend.scripts.psych.reflection"

local function trim(value)
	return tostring(value or ""):match("^%s*(.-)%s*$")
end

function Extras.install(compat, api)
	local state = compat.state
	local function warn(message, deprecated)
		compat:psychWarn(message, deprecated)
	end
	local function variables()
		state.psychVariables = state.psychVariables or {}
		return state.psychVariables
	end
	-- Deprecated Psych helpers accept any state member or script variable.
	local function owned(tag)
		local object = variables()[tag]
		if object ~= nil then return object end
		return Resolve.member(compat, tag)
	end
	local function song()
		return game.sound and game.sound.music
	end

	local function saveFile(name, folder)
		return "psych_saves/" .. tostring(folder or "psychenginemods") .. "/" .. tostring(name) .. ".json"
	end
	local function saveEntry(name, folder)
		local key = "save_" .. tostring(name)
		local existing = variables()[key]
		if existing ~= nil then return existing end
		local save = {data = {}, name = tostring(name), path = saveFile(name, folder)}
		variables()[key] = save
		return nil
	end
	api.initSaveData = function(name, folder)
		compat:_active()
		local key = "save_" .. tostring(name)
		if variables()[key] ~= nil then
			warn("initSaveData: Save file already initialized: " .. tostring(name))
			return
		end
		saveEntry(name, folder)
		local save = variables()[key]
		local contents = love.filesystem.read(save.path)
		if contents then
			local ok, decoded = pcall(json.decode, contents)
			if ok and type(decoded) == "table" then save.data = decoded end
		end
		compat:flushSaveData(name)
	end
	function compat.flushSaveData(name)
		local save = variables()["save_" .. tostring(name)]
		if save == nil then return false end
		local folder = save.path:match("^(.*)/[^/]*$")
		if folder then love.filesystem.createDirectory(folder) end
		return love.filesystem.write(save.path, json.encode(save.data or {})) == true
	end
	api.flushSaveData = function(name)
		compat:_active()
		if variables()["save_" .. tostring(name)] == nil then
			warn("flushSaveData: Save file not initialized: " .. tostring(name))
			return
		end
		compat:flushSaveData(name)
	end
	api.getDataFromSave = function(name, field, defaultValue)
		compat:_active()
		local save = variables()["save_" .. tostring(name)]
		if save == nil then
			warn("getDataFromSave: Save file not initialized: " .. tostring(name))
			return defaultValue
		end
		local value = (save.data or {})[field]
		if value == nil then return defaultValue end
		return value
	end
	api.setDataFromSave = function(name, field, value)
		compat:_active()
		local save = variables()["save_" .. tostring(name)]
		if save == nil then
			warn("setDataFromSave: Save file not initialized: " .. tostring(name))
			return
		end
		save.data = save.data or {}
		save.data[field] = value
	end
	api.eraseSaveData = function(name)
		compat:_active()
		local save = variables()["save_" .. tostring(name)]
		if save == nil then
			warn("eraseSaveData: Save file not initialized: " .. tostring(name))
			return
		end
		save.data = {}
		love.filesystem.remove(save.path)
	end

	api.endSong = function()
		compat:_active()
		if state.endSong then state:endSong() end
		return true
	end
	api.restartSong = function(skipTransition)
		compat:_active()
		if state.persistentUpdate ~= nil then state.persistentUpdate = false end
		if game.camera then game.camera.followLerp = 0 end
		state.psychRestartRequested = true
		state.psychRestartSkipTransition = skipTransition == true
		return true
	end
	api.exitSong = function(skipTransition)
		compat:_active()
		state.psychExitRequested = true
		state.psychExitSkipTransition = skipTransition == true
		return true
	end
	api.loadSong = function(name, difficultyNum)
		compat:_active()
		local songName = name
		if songName == nil or songName == "" then
			songName = state.SONG and state.SONG.song or (PlayState.SONG and PlayState.SONG.song)
		end
		local diff = difficultyNum
		if diff == nil or diff == -1 then
			diff = PlayState.songDifficulty or PlayState.defaultDifficulty
		end
		state.psychLoadSongRequest = {song = songName, difficulty = diff}
		return true
	end
	api.updateScoreText = function()
		compat:_active()
		if state.updateInformation then state:updateInformation() end
		return require("funkin.backend.scripts.psych.hud").updateScoreText(state)
	end
	api.setTimeBarColors = function(left, right)
		compat:_active()
		local bar = require("funkin.backend.scripts.psych.hud").timeBar(state, "timeBar")
		if not bar or not bar.setColors then return end
		local leftColor = (left ~= nil and left ~= "") and api.psychColorFromString(left) or nil
		local rightColor = (right ~= nil and right ~= "") and api.psychColorFromString(right) or nil
		bar:setColors(leftColor, rightColor)
	end

	api.musicFadeIn = function(duration, fromValue, toValue)
		compat:_active()
		local music = song()
		if not music then return end
		music:fade(duration, fromValue or 0, toValue or 1)
		warn("musicFadeIn is deprecated! Use soundFadeIn instead.", true)
	end
	api.musicFadeOut = function(duration, toValue)
		compat:_active()
		local music = song()
		if not music then return end
		music:fade(duration, music.volume or 1, toValue or 0)
		warn("musicFadeOut is deprecated! Use soundFadeOut instead.", true)
	end

	api.loadMultipleFrames = function(tag, images)
		compat:_active()
		local object = Resolve.get(compat, tag)
		if object == nil or type(images) ~= "table" then return end
		local collection
		for index = 1, #images do
			local atlas = paths.getAtlas(images[index])
			if atlas then
				if collection == nil then collection = atlas
				else collection:addCollection(atlas, true) end
			end
		end
		if collection then object:setFrames(collection) end
	end
	api.updateHitboxFromGroup = function(group, index)
		compat:_active()
		local container = Resolve.get(compat, group)
		local object = container and (container.members and container.members[index + 1] or container[index + 1])
		if object and object.updateHitbox then object:updateHitbox() end
	end

	api.addCharacterToList = function(name, kind)
		compat:_active()
		local slot = tostring(kind or "bf"):lower()
		if slot == "dad" or slot == "opponent" then slot = "dad"
		elseif slot == "gf" or slot == "girlfriend" then slot = "gf"
		else slot = "bf" end
		state.psychCharacterQueue = state.psychCharacterQueue or {}
		state.psychCharacterQueue[#state.psychCharacterQueue + 1] = {slot = slot, name = name}
		pcall(Parser.getCharacter, name)
	end

	api.changeDiscordPresence = function(details, stateText, largeImage, largeText, smallImage, smallText)
		compat:_active()
		if Discord == nil or Discord.changePresence == nil then return false end
		Discord.changePresence({
			details = details, state = stateText,
			assets = {large_image = largeImage, large_text = largeText,
				small_image = smallImage, small_text = smallText}
		})
		return true
	end
	api.changeDiscordClientID = function(id)
		compat:_active()
		if Discord == nil then return false end
		if id == nil then id = "1098761843956273304" end
		Discord.clientID = id
		if Discord.shutdown then Discord.shutdown() end
		if Discord.init then Discord.init() end
		return true
	end

	local achievements = {}
	local unlocked = {}
	state.psychAchievements = achievements
	state.psychAchievementsUnlocked = unlocked
	local function achievement(name)
		local entry = achievements[name]
		if entry == nil then
			warn("Couldnt find achievement: " .. tostring(name))
			return nil
		end
		if (entry.maxScore or 0) < 1 then return nil end
		return entry
	end
	api.achievementExists = function(name) return achievements[name] ~= nil end
	api.getAchievementScore = function(name)
		local entry = achievement(name)
		if entry == nil then return -1 end
		if unlocked[name] then return entry.maxScore end
		return entry.score or 0
	end
	api.setAchievementScore = function(name, value, saveIfNotUnlocked)
		local entry = achievement(name)
		if entry == nil then return -1 end
		if unlocked[name] then return entry.maxScore end
		local amount = math.min(value or 0, entry.maxScore)
		if amount >= entry.maxScore then unlocked[name] = true end
		entry.score = amount
		return amount
	end
	api.addAchievementScore = function(name, value, saveIfNotUnlocked)
		local entry = achievement(name)
		if entry == nil then return -1 end
		if unlocked[name] then return entry.maxScore end
		return api.setAchievementScore(name, (entry.score or 0) + (value or 1), saveIfNotUnlocked)
	end
	api.unlockAchievement = function(name)
		local entry = achievement(name)
		if entry == nil then return nil end
		if unlocked[name] then return nil end
		unlocked[name] = true
		entry.score = entry.maxScore
		pcall(function() game.sound.play(paths.getSound("confirmMenu"), 0.5) end)
		return name
	end
	api.isAchievementUnlocked = function(name)
		local entry = achievement(name)
		if entry == nil then return nil end
		return unlocked[name] == true
	end

	api.getFileTranslation = function(key) return tostring(key or "") end
	api.getTranslationPhrase = function(key, defaultPhrase, values)
		local text = defaultPhrase
		if text == nil then text = key end
		if type(values) == "table" then
			for index = 1, #values do
				text = tostring(text):gsub("{" .. index .. "}", tostring(values[index]))
			end
		end
		return text
	end

	api.makeFlxAnimateSprite = function(tag, x, y, folder)
		compat:_active()
		local name = tostring(tag or ""):gsub("%.", "")
		if game and game.width == nil then return end
		local object = AnimateAtlas(x or 0, y or 0)
		if folder ~= nil then
			local library = paths.getAnimateAtlas(folder)
			if library then
				object:load(library)
				object._mustRelease = false
			end
		end
		compat:_register(name, object)
		variables()[name] = object
		return object
	end
	api.loadAnimateAtlas = function(tag, folderOrImg, spriteJson, animationJson)
		compat:_active()
		local object = owned(tag)
		if object == nil or object.load == nil then return end
		local library = paths.getAnimateAtlas(folderOrImg)
		if library then object:load(library) end
	end
	api.addAnimationBySymbol = function(tag, name, symbol, framerate, loop, matX, matY)
		local object = owned(tag)
		if object == nil or object.animation == nil then return false end
		local ok = object.animation:add(name, symbol, framerate or 24, loop == true)
		if ok and object.animation.curAnim == nil then object.animation:play(name, true) end
		return ok and true or false
	end
	api.addAnimationBySymbolIndices = function(tag, name, symbol, indices, framerate, loop, matX, matY)
		local object = owned(tag)
		if object == nil or object.animation == nil then return false end
		local list = indices
		if list == nil then list = {0}
		elseif type(list) == "string" then
			local parsed = {}
			for item in trim(list):gmatch("[^,]+") do parsed[#parsed + 1] = tonumber(trim(item)) end
			list = parsed
		elseif type(list) == "table" and list.length then
			local parsed = {}
			for index = 0, list.length - 1 do parsed[index + 1] = list[index] end
			list = parsed
		end
		local ok = object.animation:addByIndices(name, symbol, list, framerate or 24, loop == true)
		if ok and object.animation.curAnim == nil then object.animation:play(name, true) end
		return ok and true or false
	end

	api.getShaderFloatArray = function(tag, uniform)
		local value = api.getShaderFloat and api.getShaderFloat(tag, uniform)
		if type(value) == "table" then return value end
	end
	api.getShaderIntArray = api.getShaderFloatArray
	api.getShaderBoolArray = api.getShaderFloatArray

	local deprecated = {
		luaSpriteMakeGraphic = function(tag, width, height, color)
			warn("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", true)
			local object = owned(tag)
			if object == nil then return end
			api.makeGraphic(tag, width, height, color)
		end,
		luaSpriteAddAnimationByPrefix = function(tag, name, prefix, framerate, loop)
			warn("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", true)
			local object = owned(tag)
			if object == nil then return end
			object.animation:addByPrefix(name, prefix, framerate or 24, loop ~= false)
			if object.animation.curAnim == nil then object.animation:play(name, true) end
		end,
		luaSpriteAddAnimationByIndices = function(tag, name, prefix, indices, framerate)
			warn("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", true)
			local object = owned(tag)
			if object == nil then return end
			local list = {}
			for item in trim(indices):gmatch("[^,]+") do list[#list + 1] = tonumber(trim(item)) or 0 end
			object.animation:addByIndices(name, prefix, list, "", framerate or 24, false)
			if object.animation.curAnim == nil then object.animation:play(name, true) end
		end,
		luaSpritePlayAnimation = function(tag, name, forced)
			warn("luaSpritePlayAnimation is deprecated! Use playAnim instead", true)
			local object = owned(tag)
			if object then object.animation:play(name, forced == true) end
		end,
		setLuaSpriteCamera = function(tag, camera)
			warn("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", true)
			local object = owned(tag)
			if object == nil then return false end
			api.setObjectCamera(tag, camera == nil or camera == "" and "game" or camera)
			return true
		end,
		scaleLuaSprite = function(tag, x, y)
			warn("scaleLuaSprite is deprecated! Use scaleObject instead", true)
			local object = owned(tag)
			if object == nil then return false end
			object.scale:set(x, y)
			object:updateHitbox()
			return true
		end,
		getPropertyLuaSprite = function(tag, variable)
			warn("getPropertyLuaSprite is deprecated! Use getProperty instead", true)
			local object = owned(tag)
			if object == nil then return nil end
			return Reflection.readPath(object, Reflection.split(variable) or {})
		end,
		setPropertyLuaSprite = function(tag, variable, value)
			warn("setPropertyLuaSprite is deprecated! Use setProperty instead", true)
			local object = owned(tag)
			if object == nil then return false end
			Reflection.writePath(object, Reflection.split(variable) or {}, value)
			return true
		end
	}
	for name, fn in pairs(deprecated) do api[name] = fn end
	api.addAnimationByIndicesLoop = function(tag, name, prefix, indices, framerate)
		warn("addAnimationByIndicesLoop is deprecated! Use addAnimationByIndices instead", true)
		api.addAnimationByIndices(tag, name, prefix, indices, framerate, true)
	end
end

return Extras
