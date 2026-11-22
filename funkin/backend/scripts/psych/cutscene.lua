local Cutscene = {}
local utf8 = require "utf8"

local function resourceName(name)
	assert(type(name) == "string" and name:match("^[%w_%-]+$"), "Invalid Psych cutscene name")
	return name
end

function Cutscene.install(compat, api)
	local state = compat.state
	local current, kind
	local function call(event, ...)
		if state.scripts then state.scripts:call(event, ...) end
	end
	local function close(resume)
		if not current then return end
		local object = current
		current = nil
		if state.psychCutscene == object then state.psychCutscene = nil end
		if state.videoCutscene == object then state.videoCutscene = nil end
		if kind == "dialogue" then api.stopSound("__psychDialogue") end
		state:remove(object)
		object:destroy()
		if resume and not state.startedCountdown and state.startCountdown then state:startCountdown() end
	end

	api.startVideo = function(name, canSkip, forMidSong, loop, playOnLoad)
		compat:_active()
		if state.psychCutscene or state.videoCutscene then return false end
		name = resourceName(name)
		local key = "videos/" .. name
		local path = paths.getPath(key .. ".ogv")
		if not love.filesystem.getInfo(path, "file") then
			local mp4 = paths.getPath(key .. ".mp4")
			if love.filesystem.getInfo(mp4, "file") then
				Logger.log("warn", "[Psych] Video skipped. This build needs an OGV copy of " .. mp4)
			else
				Logger.log("warn", "[Psych] Video not found: " .. key)
			end
			return false
		end

		local ok, video = pcall(Video, 0, 0, name, false, false, loop == true)
		if not ok then
			Logger.log("warn", "[Psych] Could not open video " .. path .. ": " .. tostring(video))
			return false
		end
		video:adjust(game.width, 0)
		video.y = (game.height - video.height * video.scale.y) / 2
		video.scrollFactor:set(0, 0)
		video.cameras = state.camOther and {state.camOther} or nil
		video.onComplete = function() close(not forMidSong) end
		local update = video.update
		function video:update(dt)
			if canSkip ~= false and self._started and controls:pressed("accept") then
				close(not forMidSong)
				return
			end
			update(self, dt)
		end
		current, kind, state.videoCutscene = video, "video", video
		if not forMidSong then state.psychCutscene = video end
		state:add(video)
		if playOnLoad ~= false then video:play() end
		return true
	end

	api.startDialogue = function(name, music)
		compat:_active()
		if state.psychCutscene or current then return false end
		name = resourceName(name)
		local song = PlayState.SONG and PlayState.SONG.song
		assert(song, "Psych dialogue needs an active song")
		local key = "data/" .. paths.formatToSongPath(song) .. "/" .. name
		local data = paths.getJSON(key)
		if type(data) ~= "table" or type(data.dialogue) ~= "table" or #data.dialogue == 0 then
			error("Invalid Psych dialogue: " .. key .. ".json", 2)
		end

		for _, entry in ipairs(data.dialogue) do
			assert(type(entry) == "table" and type(entry.text) == "string" and utf8.len(entry.text),
				"Invalid Psych dialogue line")
		end
		local dialogue = SpriteGroup()
		dialogue.scrollFactor:set(0, 0)
		dialogue.cameras = state.camOther and {state.camOther} or nil
		local panel = Graphic(36, game.height - 179, game.width - 72, 142, Color.BLACK)
		panel.alpha = 0.86
		dialogue:add(panel)
		local portrait = Sprite(54, game.height - 174)
		dialogue:add(portrait)
		local text = TypeText(200, game.height - 158, "", paths.getFont("vcr.ttf", 28), Color.WHITE, "left", game.width - 255)
		dialogue:add(text)
		function text:addLetter(amount)
			local content = self:getWrappedContent()
			self.index = math.min(self.index + amount, utf8.len(content))
			local boundary = utf8.offset(content, self.index + 1) or #content + 1
			self.content = content:sub(1, boundary - 1)
			self.timer = 0
		end
		local line, firstUpdate = 1, true
		local update = dialogue.update

		local function show()
			local entry = data.dialogue[line]
			local image = type(entry.portrait) == "string" and entry.portrait:match("^[%w_%-]+$")
				and paths.getImage("dialogue/" .. entry.portrait)
			portrait.visible = image ~= nil and image ~= false
			if portrait.visible then
				portrait:loadTexture(image)
				portrait:setGraphicSize(112)
				portrait:updateHitbox()
			end
			text.speed = math.max(tonumber(entry.speed) or 0.04, 0.001)
			text:resetText(entry.text)
			call("onNextDialogue", line)
		end
		function dialogue:update(dt)
			update(self, dt)
			if firstUpdate then firstUpdate = false; return end
			local mobileTap = love.system.getDevice() == "Mobile" and game.touch.anyTouchJustReleased
			if not controls:pressed("accept") and not mobileTap then return end
			if not text.finished then
				text:forceEnd()
				call("onSkipDialogue", line)
			elseif line == #data.dialogue then
				close(true)
			else
				line = line + 1
				show()
			end
		end
		current, kind, state.psychCutscene = dialogue, "dialogue", dialogue
		state:add(dialogue)
		if type(music) == "string" and music ~= "" then compat:_playSound(music, 1, "__psychDialogue", true, true) end
		show()
		return true
	end

	compat.disposePsychCutscene = function() close(false) end
end

return Cutscene
