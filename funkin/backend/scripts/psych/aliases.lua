local Aliases = {}
local Hud = require "funkin.backend.scripts.psych.hud"

local function readOnly(get)
	return {get = get}
end

Aliases.playstate = {
	camFollowPos = {get = function(state) return state.camFollow end,
		set = function(state, value) state.camFollow = value end},
	camGame = {get = function(state) return state.camGame or game.camera end,
		set = function(state, value) state.camGame = value end},
	defaultCamZoom = {get = function(state) return state.camZoom end,
		set = function(state, value)
			state.defaultCamZoom = value
			state.camZoom = value
		end},
	cameraSpeed = {get = function(state) return state.camSpeed end,
		set = function(state, value) state.camSpeed = value end},
	songScore = {field = "score"},
	songMisses = {field = "misses"},
	songHits = {field = "songHits"},
	health = {field = "health"},
	songLength = readOnly(function() return (game.sound.music and game.sound.music.duration or 0) * 1000 end),
	scoreTxt = {get = function(state) return Hud.scoreText(state) end},
	botplayTxt = {get = function(state) return Hud.botplayText(state) end},
	timeBar = readOnly(function(state) return Hud.timeBar(state, "timeBar") end),
	timeTxt = readOnly(function(state) return Hud.timeBar(state, "timeTxt") end),
	timeBarBG = readOnly(function(state) return Hud.timeBar(state, "timeBarBG") end),
	mustHitNoteGroup = readOnly(function(state) return state.playerNotefield end),
	opponentNoteGroup = readOnly(function(state) return state.enemyNotefield end),
	eventNotes = readOnly(function(state) return state.events end),
	generatedMusic = {field = "psychGeneratedMusic"},
	updateTime = {field = "psychUpdateTime"},
	canPause = {field = "canPause"},
	startedCountdown = {field = "startedCountdown"},
	seenCutscene = {get = function() return PlayState.seenCutscene end,
		set = function(_, value) PlayState.seenCutscene = value end},
	inCutscene = {field = "inCutscene"},
	endingSong = {field = "endingSong"},
	isDead = {field = "isDead"},
	cpuControlled = {field = "cpuControlled"},
	healthGainMult = {field = "healthGain"},
	healthLossMult = {field = "healthLoss"},
	playbackRate = {field = "playback"},
	freezeCamera = {field = "psychFreezeCamera"},
	skipCountdown = {field = "psychSkipCountdown"},
	isCameraOnForcedPos = {field = "psychCameraForced"},
}

Aliases.sprite = {
	width = readOnly(function(object) return object.width end),
	height = readOnly(function(object) return object.height end),
	frameWidth = readOnly(function(object)
		local ok, value = pcall(object.getFrameWidth, object)
		return ok and value or nil
	end),
	frameHeight = readOnly(function(object)
		local ok, value = pcall(object.getFrameHeight, object)
		return ok and value or nil
	end),
	numFrames = readOnly(function(object) return object.frames and #object.frames.frames or 1 end),
	graphic = {get = function(object) return object.texture end,
		set = function(object, value) object.texture = value end},
	offset = {get = function(object) return object.offset end,
		set = function(object, value) object.offset:set(value.x or value[1] or 0, value.y or value[2] or 0) end},
	origin = {get = function(object) return object.origin end,
		set = function(object, value) object.origin:set(value.x or value[1] or 0, value.y or value[2] or 0) end},
	scale = {get = function(object) return object.scale end,
		set = function(object, value) object.scale:set(value.x or value[1] or 1, value.y or value[2] or 1) end},
}

Aliases.animation = {
	curAnimName = readOnly(function(controller)
		return controller.curAnim and controller.curAnim.name or nil
	end),
	curAnimFrame = readOnly(function(controller)
		return controller.curAnim and (controller.curAnim.frame - 1) or -1
	end),
	curAnimFinished = readOnly(function(controller)
		return controller.curAnim ~= nil and controller.curAnim.finished == true
	end),
	frameRate = readOnly(function(controller)
		return controller.curAnim and controller.curAnim.framerate or 0
	end),
}

Aliases.character = {
	curCharacter = {get = function(character) return character.char end,
		set = function(character, value) character.char = value end},
	healthIcon = {field = "icon"},
	cameraPosition = {field = "cameraPosition"},
	animOffsets = {field = "animOffsets"},
	animationsArray = {field = "animationsTable"},
	danceEveryNumBeats = {field = "danceEveryNumBeats"},
	heldKeys = {field = "heldKeys"},
	shouldDance = {field = "shouldDance"},
	singDuration = {field = "singDuration"},
}

Aliases.text = {
	text = {get = function(text) return text.content end,
		set = function(text, value)
			text.content = tostring(value or "")
			if text.__updateDimension then text:__updateDimension() end
		end},
	size = readOnly(function(text)
		return text.font and text.font:getHeight() or 0
	end),
	borderSize = {get = function(text)
		return text.outline and text.outline.width or 0
	end,
		set = function(text, value)
			if text.outline then text.outline.width = tonumber(value) or 0 end
		end},
	borderStyle = {get = function(text)
		if text.outline and text.outline.style == "simple" then return "shadow" end
		return text.outline and text.outline.width > 0 and "outline" or "none"
	end},
	color = {get = function(text) return text.color end,
		set = function(text, value) text.color = value end},
	alignment = {get = function(text) return text.alignment end,
		set = function(text, value) text.alignment = tostring(value or "left") end},
	width = readOnly(function(text)
		local ok, value = pcall(text.getWidth, text)
		return ok and value or text.limit
	end),
	height = readOnly(function(text)
		local ok, value = pcall(text.getHeight, text)
		return ok and value or nil
	end),
	fieldWidth = {get = function(text) return text.limit end,
		set = function(text, value)
			text.limit = value
			if text.__updateDimension then text:__updateDimension() end
		end},
}

local function group(object)
	if object == nil then return nil end
	if type(object) ~= "table" then return nil end
	if object.__psychAlias then return object.__psychAlias end
	if type(object.is) ~= "function" then return nil end
	if Character and object:is(Character) then return Aliases.character end
	if Text and object:is(Text) then return Aliases.text end
	if AnimationController and object:is(AnimationController) then return Aliases.animation end
	if Object and object:is(Object) then return Aliases.sprite end
	return nil
end

function Aliases.get(object, key)
	local set = group(object)
	local entry = set and set[key]
	if entry == nil then return nil, false end
	if entry.field then return object[entry.field], true end
	if entry.get then return entry.get(object), true end
	return nil, false
end

function Aliases.set(object, key, value)
	local set = group(object)
	local entry = set and set[key]
	if entry == nil then return false end
	if entry.field then
		object[entry.field] = value
		return true
	end
	if entry.set then
		entry.set(object, value)
		return true
	end
	return false
end

return Aliases
