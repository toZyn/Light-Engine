---@class PlayState:State
local PlayState = State:extend("PlayState")
local PauseButton = require "funkin.gameplay.ui.pausebutton"

PlayState.defaultDifficulty = "normal"
PlayState.transIn = TransitionData(0.5)

PlayState.inputDirections = {
	note_left = 0,
	note_down = 1,
	note_up = 2,
	note_right = 3
}
PlayState.keysControls = {}
for control, key in pairs(PlayState.inputDirections) do
	PlayState.keysControls[key] = control
end

PlayState.SONG = nil
PlayState.songDifficulty = ""

PlayState.storyPlaylist = {}
PlayState.storyMode = false
PlayState.storyWeek = ""
PlayState.storyScore = 0
PlayState.storyWeekFile = ""

PlayState.seenCutscene = false
PlayState.canFadeInReceptors = true
PlayState.prevCamFollow = nil

-- Charting Stuff
PlayState.chartingMode = false
PlayState.startPos = 0

local function showSongLoadNotice(err)
	local text = tostring(err or "Failed to load chart")
	if Toast and Toast.error then
		local prev = Toast.showErrors
		Toast.showErrors = true
		pcall(Toast.error, text)
		Toast.showErrors = prev
	end
end

function PlayState.loadSong(song, diff)
	diff = diff or PlayState.defaultDifficulty
	PlayState.songDifficulty = diff

	local chart, err = Parser.getChart(song, diff, {strict = true})
	if not chart then
		PlayState.SONG = nil
		PlayState.lastLoadError = err
		showSongLoadNotice(err)
		return false, err
	end

	PlayState.SONG = chart
	PlayState.lastLoadError = nil
	return true, chart
end

function PlayState.getCutscene(isEnd)
	local name = paths.formatToSongPath(PlayState.SONG.song)
	if isEnd then name = name .. "-end" end

	for _, path in ipairs({
		paths.getPath("data/cutscenes/" .. name .. ".lua"),
		paths.getPath("data/cutscenes/" .. name .. ".json")
	}) do
		if paths.exists(path, "file") then
			return name, path:ext() == "lua" and 1 or 2
		end
	end
end

function PlayState:new(storyMode, song, diff)
	PlayState.super.new(self)
	self.startPos = PlayState.startPos or 0

	if storyMode ~= nil then
		PlayState.storyMode = storyMode
		PlayState.storyWeek = ""
		PlayState.storyScore = 0
	end

	if type(song) == "number" then
		self.startPos = song
		PlayState.startPos = song
		song = nil
	end

	if song ~= nil then
		if storyMode and type(song) == "table" and #song > 0 then
			PlayState.storyPlaylist = song
			song = song[1]
		end
		if not PlayState.loadSong(song, diff) then
			local Fallback = PlayState.storyMode and StoryMenuState or FreeplayState
			setmetatable(self, Fallback)
			Fallback.new(self)
		end
	end
end

function PlayState:preload()
	if PlayState.SONG == nil then PlayState.loadSong("test") end
	local skin = paths.getSkin(PlayState.SONG and PlayState.SONG.skin or "default")
	PlayState.SONG.skin = skin

	local function skinPath(type, name) return {type, skin:getPath(name, type)} end
	local song = paths.formatToSongPath(PlayState.SONG.song)
	local diff, async = PlayState.songDifficulty:lower(), paths.async

	local function getVocals(suffix, fallback, skip)
		local shortSuffix = suffix:match("^[^%-]*")
		return async.getVoices(song, suffix .. "-" .. diff, nil, true)
			or async.getVoices(song, diff, nil, true)
			or async.getVoices(song, shortSuffix .. "-" .. diff, nil, true)
			or async.getVoices(song, shortSuffix, nil, true)
			or async.getVoices(song, suffix, nil, true)
			or (fallback and async.getVoices(song, fallback, nil, true) or nil)
			or (not skip and async.getVoices(song, nil, nil, true) or nil)
	end

	local p1, p2 = PlayState.SONG.player1, PlayState.SONG.player2
	local playerVocals, enemyVocals =
		getVocals(p1 or "Player", "Player"),
		getVocals(p2 or "Opponent", "Opponent", true)
	if not async.getInst(song, diff, nil, true) then
		async.getInst(song)
	end

	local list = {
		skinPath("image", "ready"), skinPath("image", "set"), skinPath("image", "go"),
		skinPath("sound", "intro3"), skinPath("sound", "intro2"), skinPath("sound", "intro1"),
		skinPath("sound", "introGo"), {"sound", "hitsound"}
	}

	local defaultSkinPath = "skins/" .. tostring(skin.skin or "default") .. "/"
	for _, part in pairs(skin.data or {}) do
		local sprite = type(part) == "table" and part.sprite or nil
		local partPath = (type(part) == "table" and part.skin)
			and ("skins/" .. part.skin .. "/") or defaultSkinPath
		if sprite then
			table.insert(list, {"image", partPath .. sprite})
		end
	end

	self.ratings = {
		{name = "sick", time = 0.045, score = 350, splash = true,  mod = 1},
		{name = "good", time = 0.090, score = 200, splash = false, mod = 0.7},
		{name = "bad",  time = 0.135, score = 100, splash = false, mod = 0.4, resetCombo = true},
		{name = "shit", time = -1,    score = 50,  splash = false, mod = 0,   resetCombo = true}
	}
	for _, rating in ipairs(self.ratings) do
		table.insert(list, skinPath("image", rating.name))
	end
	for i = 0, 9 do
		table.insert(list, skinPath("image", "num" .. i))
	end
	table.insert(list, skinPath("image", "healthBar"))
	table.insert(list, skinPath("image", "numnegative"))

	for i = 1, 3 do table.insert(list, {"sound", "gameplay/missnote" .. i}) end

	self.stage = Stage(PlayState.SONG.stage)
	for _, char in pairs({PlayState.SONG.gfVersion, PlayState.SONG.player2, PlayState.SONG.player1}) do
		if char and char ~= "" then
			local data = Parser.getCharacter(char)
			if data and data.sprite then
				local kind = "image"
				if paths.exists(paths.getPath("images/" .. data.sprite .. "/Animation.json"), "file") then
					kind = "animate"
				end
				table.insert(list, {kind, data.sprite, nil, true})
				if data.animations and kind ~= "animate" then
					for _, anim in pairs(data.animations) do
						local atlas = type(anim) == "table" and (anim[7] or anim.assetPath or anim.image) or nil
						if type(atlas) == "string" and atlas ~= "" then
							table.insert(list, {"image", atlas, nil, true})
						end
					end
				end
				local iconPath = HealthIcon and HealthIcon.resolveIconPath
					and HealthIcon.resolveIconPath(data.icon or "face")
					or ("icons/" .. (data.icon or "face"))
				table.insert(list, {"image", iconPath, nil, true})
			end
			if char == "nene" or char == "abot" then
				table.insert(list, {"animate", "characters/abot/abotSystem"})
				table.insert(list, {"animate", "characters/abot/systemEyes"})
				table.insert(list, {"image", "characters/abot/aBotViz", nil, true})
				table.insert(list, {"image", "characters/abot/stereoBG", nil, true})
			end
		end
	end
	paths.async.loadBatch(list)
	self._preloaded = true
end

function PlayState:enter()
	self._postCreated = false
	if PlayState.SONG == nil then PlayState.loadSong("test") end
	if not self._preloaded or not self.ratings then
		self:preload()
	end
	self.startPos = self.startPos or PlayState.startPos or 0
	PlayState.startPos = 0

	local songName = paths.formatToSongPath(PlayState.SONG.song)

	PlayState.SONG.skin = paths.getSkin(PlayState.SONG and PlayState.SONG.skin or "default")
	local skin = PlayState.SONG.skin

	local difficulty = PlayState.songDifficulty:lower()
	if game.sound.music then game.sound.music:reset(true) end
	game.sound.loadMusic(paths.getInst(songName, difficulty, true)
		or paths.getInst(songName, nil, true))
	game.sound.music.looped = false
	game.sound.music.volume = ClientPrefs.data.musicVolume / 100
	game.sound.music.onComplete = bind(self, self.endSong)

	local conductor = Conductor(PlayState.SONG.timeChanges)
	conductor.time = self.startPos - conductor.crotchet * 5
	conductor.onStep:add(bind(self, self.step))
	conductor.onBeat:add(bind(self, self.beat))
	conductor.onMeasure:add(bind(self, self.measure))
	PlayState.conductor = conductor

	self.skipConductor = false

	Note.defaultSustainSegments = 3
	NoteModifier.reset()

	self.timer = TimerManager()
	self.tween = Tween()
	self.camPosTween = nil

	if Discord then self:updateDiscordRPC() end

	self.startingSong = true
	self.startedCountdown = false
	self.doCountdownAtBeats = nil
	self.lastCountdownBeats = nil

	self.isDead = false

	self.usedBotPlay = ClientPrefs.data.botplayMode
	self.downScroll = ClientPrefs.data.downScroll
	self.middleScroll = ClientPrefs.data.middleScroll
	self.playback = 1
	self.timer.timeScale = 1
	self.tween.timeScale = 1

	self.camNotes = Camera() --Camera will be changed to ActorCamera once that class is done
	self.camHUD = Camera()
	self.camOther = Camera()
	game.cameras.add(self.camHUD, false)
	game.cameras.add(self.camNotes, false)
	game.cameras.add(self.camOther, false)

	self.camHUD.bgColor[4] = ClientPrefs.data.backgroundDim / 100

	self.cameraOffset = Point()
	self.ghostTime = 0

	self.scripts = ScriptsHandler()
	self.scripts:loadDirectory("data/scripts", "data/scripts/" .. songName, "songs/" .. songName)
	conductor.onTimeChange:add(function()
		self.scripts:set("bpm", conductor.bpm)
		self.scripts:set("crotchet", conductor.crotchet)
		self.scripts:set("stepCrotchet", conductor.stepCrotchet)
	end)
	conductor.onTimeChange:dispatch()

	self.events = table.clone(PlayState.SONG.events)
	self.eventIndex = 1
	self.eventScripts = {}
	self._sustainHitBuffer = {}

	local eventAliases = {
		["change scroll speed"] = "scrollspeed",
		["camera follow pos"] = "focuscamera",
		["add camera zoom"] = "addcamerazoom",
		["change character"] = "changecharacter",
		["play animation"] = "playanimation",
		["camera flash"] = "cameraflash",
		["screen shake"] = "screenshake",
		["hey!"] = "hey"
	}

	local function resolveEventPath(name)
		local lower = tostring(name or ""):lower()
		local candidates = {
			"data/events/" .. lower:gsub(" ", "-"),
			"data/events/" .. lower:gsub("[%s%-_!]", ""),
			"data/events/" .. lower
		}
		if eventAliases[lower] then
			table.insert(candidates, 1, "data/events/" .. eventAliases[lower])
		end
		for _, cand in ipairs(candidates) do
			if paths.exists(paths.getPath(cand .. ".lua"), "file") then
				return cand
			end
		end
		return nil
	end
	self._resolveEventPath = resolveEventPath

	for _, e in ipairs(self.events) do
		if e and e.e and not self.eventScripts[e.e] then
			local scriptPath = resolveEventPath(e.e)
			if scriptPath then
				self.eventScripts[e.e] = Script(scriptPath)
				self.scripts:add(self.eventScripts[e.e])
			else
				Logger.log("debug", "[PlayState] Event script not found (will dispatch onEvent only): " .. tostring(e.e))
			end
		end
	end

	-- Auto-load custom NoteType scripts from data/notetypes/<type>.lua
	self.noteTypeScripts = {}
	if PlayState.SONG.notes then
		for _, sectionNotes in pairs(PlayState.SONG.notes) do
			if type(sectionNotes) == "table" then
				for _, n in ipairs(sectionNotes) do
					local kind = n and n.k
					if type(kind) == "string" and kind ~= "" and kind ~= "alt" and kind ~= "gf" and not self.noteTypeScripts[kind] then
						local ntSlug = kind:gsub(" ", "-"):lower()
						local ntCompact = kind:gsub("[%s%-_]", ""):lower()
						for _, cand in ipairs({"data/notetypes/" .. kind, "data/notetypes/" .. ntSlug, "data/notetypes/" .. ntCompact}) do
							if paths.exists(paths.getPath(cand .. ".lua"), "file") then
								local scr = Script(cand)
								self.noteTypeScripts[kind] = scr
								self.scripts:add(scr)
								break
							end
						end
						if not self.noteTypeScripts[kind] then
							self.noteTypeScripts[kind] = false
						end
					end
				end
			end
		end
	end

	self.scripts:call("create")

	if not self.stage then
		self.stage = Stage(PlayState.SONG.stage)
	end

	self.stage:load()
	self:add(self.stage)
	if self.stage.script then self.scripts:add(self.stage.script) end
	self:add(self.stage.foreground)

	self.boyfriend, self.dad, self.gf =
		self.stage.boyfriend, self.stage.dad, self.stage.gf

	if self.boyfriend then self.scripts:add(self.boyfriend.script) end
	if self.gf then self.scripts:add(self.gf.script) end
	if self.dad then self.scripts:add(self.dad.script) end

	self.judgeSprites = Judgements(game.width / 3, 264, PlayState.SONG.skin)
	self:add(self.judgeSprites)

	game.camera.zoom, self.camZoom,
	self.camZoomSpeed, self.camSpeed, self.camTarget =
		self.stage.camZoom, self.stage.camZoom,
		self.stage.camZoomSpeed, self.stage.camSpeed

	self.zoomRate = conductor.timeSignNum
	self.hudZoomIntensity = 0.03
	self.camZoomIntensity = 1.015
	self.camZoomMult = 1

	if PlayState.prevCamFollow then
		self.camFollow = PlayState.prevCamFollow
		PlayState.prevCamFollow = nil
	else
		self.camFollow = Point()
		self.camFollow.tweening = false
	end

	local volume = ClientPrefs.data.vocalVolume / 100
	local function getVocals(char, fallback, n)
		local shortChar = char:match("^[^%-]*")
		local file = (paths.getVoices(songName, char .. "-" .. difficulty)
				or paths.getVoices(songName, shortChar .. "-" .. difficulty)
				or paths.getVoices(songName, difficulty)
				or paths.getVoices(songName, char, true)
				or paths.getVoices(songName, shortChar, true))
			or (fallback and paths.getVoices(songName, fallback, true) or nil)
			or (n and paths.getVoices(songName, nil))
		if file then
			local vocal = game.sound.load(file)
			vocal.volume, vocal.looped = volume, false
			return vocal
		end
	end

	local p1, p2 = self.boyfriend and self.boyfriend.voiceSuffix or self.SONG.player1,
		self.dad and self.dad.voiceSuffix or PlayState.SONG.player2
	local playerVocals = getVocals(p1 or "Player", "Player", true)
	local enemyVocals = getVocals(p2 or "Opponent", "Opponent") or playerVocals

	-- {field name, char, vocals, botplay, splash}
	self.notefields = {}
	local y, keys, speed = game.height / 2, 4, PlayState.SONG.speed
	local config = {
		{"player", self.boyfriend, playerVocals, ClientPrefs.data.botplayMode, true},
		{"enemy",  self.dad,       enemyVocals,  true},
	}
	for _, nf in ipairs(config) do
		local field, notes = nf[1] .. "Notefield", PlayState.SONG.notes[nf[1]]
		self[field] = Notefield(0, y, keys, skin, nf[2], nf[3], speed)
		local notefield = self[field]
		notefield.bot = nf[4]
		notefield.canSpawnSplash = nf[5] or false
		notefield.cameras = {self.camNotes}
		self:add(notefield)
		if notes then notefield:makeNotesFromChart(notes) end
		table.insert(self.notefields, notefield)
	end
	self:positionNotefields()
	table.insert(self.notefields, 3, {character = self.gf})

	if PlayState.canFadeInReceptors then
		for _, notefield in pairs(self.notefields) do
			if notefield.is then
				for _, receptor in ipairs(notefield.receptors) do
					receptor.alpha = 0
				end
			end
		end
	end

	local notefield
	for i, event in ipairs(self.events) do
		if event.t > 10 then
			break
		elseif event.e == "FocusCamera" then
			self:executeEvent(event)
			table.remove(self.events, i)
			break
		end
	end

	self.countdown = Countdown()
	self.countdown:screenCenter()
	self:add(self.countdown)

	local isPixel = skin.isPixel
	local event = self.scripts:event("onCountdownCreation",
		Events.CountdownCreation({}, isPixel and {x = 7, y = 7} or {x = 1, y = 1}, not isPixel))
	if not event.cancelled then
		self.countdown.data = #event.data == 0 and {
			{
				sound = skin:getPath("intro3", "sound"),
			},
			{
				sound = skin:getPath("intro2", "sound"),
				image = skin:getPath("ready", "image")
			},
			{
				sound = skin:getPath("intro1", "sound"),
				image = skin:getPath("set", "image")
			},
			{
				sound = skin:getPath("introGo", "sound"),
				image = skin:getPath("go", "image")
			}
		} or event.data
		self.countdown.scale = event.scale
		self.countdown.antialiasing = event.antialiasing
	end

	self.healthBar = HealthBar(self.boyfriend and self.boyfriend.icon or nil,
		self.dad and self.dad.icon or nil, skin)
	self.healthBar:screenCenter("x").y = game.height * (self.downScroll and 0.1 or 0.9)
	self:add(self.healthBar)

	self.scoreText = Text(0, 0, "", paths.getFont("vcr.ttf", 16), Color.WHITE, "right")
	self.scoreText.outline.width = 1
	self.scoreText.antialiasing = false
	self:add(self.scoreText)

	for _, o in ipairs({
		self.judgeSprites, self.countdown, self.healthBar, self.scoreText
	}) do o.cameras = {self.camHUD} end

	self.ratingNeedsRecalc = false
	self.score = 0
	self.combo = 0
	self.misses = 0
	self.health = 1
	for _, r in ipairs(self.ratings) do
		self[r.name .. "s"] = 0
	end

	if love.system.getDevice() == "Mobile" then
		local pad = ClientPrefs.data.margin
		local w, h = (game.width - pad * 2) / 4, game.height

		self.buttons = VirtualPadGroup()
		self.pauseButton = PauseButton(game.width - 130 - ClientPrefs.data.margin, 20, skin, function()
			if self.startedCountdown and self.canPause and not self.isDead
				and not self.substate and not self:hasActiveDialogue() then
				self:tryPause()
			end
		end)
		self:add(self.pauseButton)
		self.buttons.cameras = {self.camOther}
		self.pauseButton.cameras = self.buttons.cameras

		local left = VirtualPad("left", pad, 0, w, h, Color.PURPLE)
		local down = VirtualPad("down", pad + w, 0, w, h, Color.BLUE)
		local up = VirtualPad("up", pad + w * 2, 0, w, h, Color.LIME)
		local right = VirtualPad("right", pad + w * 3, 0, w, h, Color.RED)

		self.buttons:add(left)
		self.buttons:add(down)
		self.buttons:add(up)
		self.buttons:add(right)
		self.buttons:set({
			fill = "line",
			lined = false,
			blend = "add",
			releasedAlpha = 0,
			config = {round = {0, 0}}
		})
		self.pauseButton:promotePad()
	end
	if self.buttons then self.buttons:disable() end

	self.lastTick = love.timer.getTime()

	self.bindedKeyPress = bind(self, self.onKeyPress)
	controls:bindPress(self.bindedKeyPress)

	self.bindedKeyRelease = bind(self, self.onKeyRelease)
	controls:bindRelease(self.bindedKeyRelease)

	if self.downScroll then
		for _, notefield in pairs(self.notefields) do
			if notefield.is then notefield.downscroll = true end
		end
	end
	self:positionText()

	if Recorder then
		Recorder.onGameplayEnter(PlayState.SONG and PlayState.SONG.song)
	end

	if PlayState.storyMode and not PlayState.seenCutscene then
		local name, type = PlayState.getCutscene()
		if name then
			self:executeCutscene(name, type, function(event)
				local skipCountdown = event and event.params[1] or false
				if skipCountdown then
					if self.buttons and not table.find(self.members, self.buttons) then
						self:add(self.buttons)
					end
					if self.pauseButton and self.pauseButton.promotePad then
						self.pauseButton:promotePad()
					end
					self:playSong(self.startPos)
					self:fadeReceptors()
				else
					self:startCountdown()
				end
			end)
		else
			self:startCountdown()
		end
	else
		self:startCountdown()
	end
	self:recalculateRating()

	PlayState.super.enter(self)
	collectgarbage()

	self.scripts:call("postCreate")
	self._postCreated = true

	game.camera:follow(self.camFollow, nil, 2.4 * self.camSpeed)
	game.camera:snapToTarget()

	self.lastSongTime = 0

	self:update(0)
end

function PlayState:executeCutscene(name, type, onComplete)
	PlayState.seenCutscene = true
	if type == 1 then
		local cutsceneScript = Script("data/cutscenes/" .. name)
		cutsceneScript.errorCallback:add(function()
			print("Cutscene returned a error. Skipping")
			cutsceneScript:close()
		end)
		cutsceneScript.closeCallback:add(function()
			if self.scripts and self.scripts.scripts then
				table.delete(self.scripts.scripts, cutsceneScript)
			end
			if onComplete then onComplete() end
			onComplete = nil
		end)

		self.scripts:add(cutsceneScript)
		cutsceneScript:call("create")
		if self._postCreated then
			cutsceneScript:call("postCreate")
		end
	else
		local s, data = pcall(paths.getJSON, "data/cutscenes/" .. name)
		if not s then
			print("JSON cutscene returned a error. Skipping;", data)
			if onComplete then onComplete() end
			return
		end

		for _, e in ipairs(data.cutscene) do
			Timer():start(e.time / 1000, function()
				self:executeCutsceneEvent(e.event, onComplete)
			end)
		end
	end
end

function PlayState:executeCutsceneEvent(event, onComplete)
	switch(event.name, {
		['Camera Position'] = function()
			local xCam, yCam = event.params[1], event.params[2]
			local isTweening = event.params[3]
			local time = event.params[4]
			local ease = event.params[5]
			if isTweening then
				game.camera:follow(self.camFollow, nil)
				Tween.tween(self.camFollow, {x = xCam, y = yCam}, time, {ease = Ease[ease]})
			else
				self.camFollow:set(xCam, yCam)
				game.camera:follow(self.camFollow, nil, 2.4 * self.camSpeed)
			end
		end,
		['Camera Zoom'] = function()
			local zoomCam = event.params[1]
			local isTweening = event.params[2]
			local time = event.params[3]
			local ease = event.params[4]
			if isTweening then
				Tween.tween(game.camera, {zoom = zoomCam}, time, {ease = Ease[ease]})
			else
				game.camera.zoom = zoomCam
			end
		end,
		["Play Sound"] = function()
			local soundPath = event.params[1]
			local volume = event.params[2]
			local isFading = event.params[3]
			local time = event.params[4]
			local volStart, volEnd = event.params[5], event.params[6]

			local sound = util.playSfx(paths.getSound(soundPath), volume)
			if isFading then sound:fade(time, volStart, volEnd) end
		end,
		["Play Animation"] = function()
			local character, nf, anim = nil, self.notefields, event.params[2]
			switch(event.params[1], {
				[{"bf", "boyfriend", "player"}] = function() character = nf[1].character end,
				[{"gf", "girlfriend", "bystander"}] = function() character = nf[3].character end,
				[{"dad", "enemy", "opponent"}] = function() character = nf[2].character end
			})
			if character then character:playAnim(anim, true) end
		end,
		["End Cutscene"] = function()
			game.camera:follow(self.state.camFollow, nil, 2.4 * self.camSpeed)
			if onComplete then onComplete(event) end
		end
	})
end

function PlayState:positionNotefields()
	local playerNF, enemyNF = self.playerNotefield, self.enemyNotefield
	if self.middleScroll then
		local splitWidth = ClientPrefs.data.splitReceptors and ClientPrefs.data.splitWidth or nil
		playerNF:setWidth(splitWidth, ClientPrefs.data.noteWidth)
		playerNF:screenCenter("x")

		enemyNF.groupScale:set(0.5, 0.5)
		enemyNF:setPosition(game.width * 0.086, game.height * (self.downScroll and 0.1 or 1.8))
		enemyNF:hideNotes(true)
	else
		local x = 44
		enemyNF.groupScale:set(1, 1)
		enemyNF:hideNotes(false)
		enemyNF:setPosition(x, game.height / 2)

		playerNF:setWidth()
		playerNF.x = x + game.width / 2
	end
end

function PlayState:positionText()
	self.scoreText.x, self.scoreText.y = self.healthBar.x + self.healthBar.bg.width - 190, self.healthBar.y + 30
end

function PlayState:getRating(a, b)
	local diff = math.abs(a - b)
	for _, r in ipairs(self.ratings) do
		if diff <= (r.time < 0 and Note.safeZoneOffset or r.time) then return r end
	end
end

function PlayState:hasActiveDialogue()
	if not self.members or not DialogueBox then return false end
	for _, m in ipairs(self.members) do
		if m and not m._closed and m.exists ~= false and m.is and m:is(DialogueBox) then
			return true
		end
	end
	return false
end

function PlayState:startCountdown()
	if self.buttons and not table.find(self.members, self.buttons) then
		self:add(self.buttons)
	end
	if self.pauseButton and self.pauseButton.promotePad then
		self.pauseButton:promotePad()
	end

	local event = self.scripts:call("startCountdown")
	if event == Script.Event_Cancel then return end

	self:setPlayback(ClientPrefs.data.playback)

	if not PlayState.conductor then return end
	self.doCountdownAtBeats = PlayState.startPos / PlayState.conductor.crotchet - 4
	self.startedCountdown = true
	self.countdown.duration = PlayState.conductor.crotchet / 1000
	self.countdown.playback = 1

	self:fadeReceptors()
end

function PlayState:fadeReceptors()
	for _, notefield in pairs(self.notefields) do
		if notefield.is and PlayState.canFadeInReceptors then
			notefield:fadeInReceptors(self.tween)
		end
	end
	PlayState.canFadeInReceptors = false
end

function PlayState:setPlayback(playback)
	playback = playback or self.playback
	game.sound.music.pitch = playback

	local lastVocals
	for _, notefield in pairs(self.notefields) do
		if notefield.vocals and lastVocals ~= notefield.vocals then
			notefield.vocals.pitch = playback
			lastVocals = notefield.vocals
		end
	end
	lastVocals = nil

	self.playback = playback
	self.timer.timeScale = playback
	self.tween.timeScale = playback
end

function PlayState:playSong(daTime)
	self:updateDiscordRPC()
	self:setPlayback(self.playback)

	if daTime then game.sound.music.time = daTime end
	game.sound.music:play()

	local time, lastVocals = game.sound.music.time
	for _, notefield in pairs(self.notefields) do
		if notefield.vocals and lastVocals ~= notefield.vocals then
			notefield.vocals.time = time
			notefield.vocals:play()
			lastVocals = notefield.vocals
		end
	end
	lastVocals = nil
	PlayState.conductor:update(time * 1000)

	self.paused = false
	if Recorder then
		Recorder.onSongStart(PlayState.SONG and PlayState.SONG.song)
	end
end

function PlayState:pauseSong()
	game.sound.music:pause()
	self:updateDiscordRPC(true)
	local lastVocals
	for _, notefield in pairs(self.notefields) do
		if notefield.vocals and lastVocals ~= notefield.vocals then
			notefield.vocals:pause()
			lastVocals = notefield.vocals
		end
	end
	lastVocals = nil

	self.paused = true
end

function PlayState:resyncSong()
	local time, rate = game.sound.music.time, math.max(self.playback, 1)
	if math.abs(time - self.conductor.time / 1000) > 0.015 * rate then
		PlayState.conductor:update(time * 1000)
	end
	local maxDelay, vocals, lastVocals = 0.009262 * rate
	for _, notefield in pairs(self.notefields) do
		vocals = notefield.vocals
		if vocals and lastVocals ~= vocals and vocals:isPlaying()
			and vocals.time > 0.8 and math.abs(time - vocals.time) > maxDelay then
			vocals:pause()
			vocals.time = time
			vocals:play()
			lastVocals = vocals
		end
	end
	lastVocals = nil
end

function PlayState:getCameraPosition(char)
	if not char then char = self.dad end
	local camX, camY = char:getMidpoint()
	if char == self.gf then
		camX, camY = camX - char.cameraPosition.x + self.stage.gfCam.x,
			camY - char.cameraPosition.y + self.stage.gfCam.y
	elseif char.isPlayer then
		camX, camY = camX - char.cameraPosition.x + self.stage.boyfriendCam.x,
			camY + char.cameraPosition.y + self.stage.boyfriendCam.y
	else
		camX, camY = camX + char.cameraPosition.x + self.stage.dadCam.x,
			camY + char.cameraPosition.y + self.stage.dadCam.y
	end
	return camX, camY
end

function PlayState:cameraMovement(ox, oy, easing, time)
	local event = self.scripts:event("onCameraMove", Events.CameraMove(self.camTarget))
	if event.cancelled then return false end
	local camX, camY = (ox or 0) + event.offset.x, (oy or 0) + event.offset.y
	if self.camPosTween then
		self.camPosTween:cancel()
	end
	camX, camY = camX - self.cameraOffset.x, camY - self.cameraOffset.y

	if easing then
		if game.camera.followLerp then
			game.camera:follow(self.camFollow, nil)
		end
		self.camPosTween = self.tween:tween(self.camFollow, {x = camX, y = camY}, time, {
			ease = Ease[easing],
			onComplete = function()
				self.camFollow.tweening = false
			end
		})
	else
		if not game.camera.followLerp then
			game.camera:follow(self.camFollow, nil, 2.4 * self.camSpeed)
		end
		self.camPosTween = nil
		self.camFollow:set(camX, camY)
	end
end

function PlayState:step(s)
	if self.skipConductor then return end

	if not self.startingSong then
		self:resyncSong()
	end

	self.scripts:set("curStep", s)
	self.scripts:call("step", s)
	self.scripts:call("postStep", s)
end

function PlayState:beat(b)
	if self.skipConductor then return end

	self.scripts:set("curBeat", b)
	self.scripts:call("beat", b)

	local character
	for _, notefield in pairs(self.notefields) do
		character = notefield.character
		if character then character:beat(b) end
	end

	local val, healthBar = 1.2, self.healthBar
	healthBar.iconScale = val
	if healthBar.iconP1 then
		healthBar.iconP1:setScale(val)
	end
	if healthBar.iconP2 then
		healthBar.iconP2:setScale(val)
	end

	if --[[ClientPrefs.data.zoomCamera and]] game.camera.zoom < 1.35 and
		self.zoomRate > 0 and self.conductor.currentBeat % self.zoomRate == 0 then
		self.camZoomMult = self.camZoomIntensity
		self.camHUD.zoom = 1 + self.hudZoomIntensity
	end

	self.scripts:call("postBeat", b)
end

function PlayState:measure(m)
	if self.skipConductor then return end

	self.scripts:set("curMeasure", m)
	self.scripts:call("measure", m)

	self.scripts:call("postMeasure", m)
end

function PlayState:focus(f)
	self.scripts:call("focus", f)
	self:reconcileReceptors()
	if Discord and love.autoPause then self:updateDiscordRPC(not f) end
	self.scripts:call("postFocus", f)
end

function PlayState:executeEvent(event)
	if self.eventScripts[event.e] then
		self.eventScripts[event.e]:call("event", event)
	end
	self.scripts:call("onEvent", event)
end

function PlayState:pushEvent(name, params)
	if params == nil then
		Logger.log("error", "pushEvent: argument 2 must be the event parameter(s).")
		return
	end

	if not self.eventScripts[name] then
		local path = (self._resolveEventPath and self._resolveEventPath(name))
			or ("data/events/" .. tostring(name):gsub(" ", "-"):lower())
		if paths.exists(paths.getPath(path .. ".lua"), "file") then
			self.eventScripts[name] = Script(path)
			self.scripts:add(self.eventScripts[name])
		end
	end

	self:executeEvent({e = name, v = params, t = PlayState.conductor and PlayState.conductor.time or 0})
end

function PlayState:swapCharacter(slot, newCharName)
	if not newCharName or newCharName == "" or not self.stage then return nil end
	local s = tostring(slot or "bf"):lower()
	local isBF = (s == "bf" or s == "boyfriend" or s == "player" or s == "0" or s == "player1")
	local isGF = (s == "gf" or s == "girlfriend" or s == "2" or s == "gfversion")

	local oldChar = isBF and self.boyfriend or (isGF and self.gf or self.dad)
	if oldChar and (oldChar.char == newCharName or oldChar.curCharacter == newCharName) then return oldChar end

	local ok, newChar = pcall(Character, 0, 0, newCharName, isBF)
	if not ok or not newChar then return nil end

	local posPoint = isBF and self.stage.boyfriendPos or (isGF and self.stage.gfPos or self.stage.dadPos)
	local camPoint = isBF and self.stage.boyfriendCam or (isGF and self.stage.gfCam or self.stage.dadCam)
	if posPoint then
		newChar:setPosition(newChar.x + posPoint.x, newChar.y + posPoint.y)
	end
	if camPoint and newChar.cameraPosition then
		newChar.cameraPosition.x = newChar.cameraPosition.x + camPoint.x
		newChar.cameraPosition.y = newChar.cameraPosition.y + camPoint.y
	end

	if oldChar then
		local idx = table.find(self.stage.members, oldChar)
		if idx then
			self.stage.members[idx] = newChar
		else
			self.stage:add(newChar)
		end
		if oldChar.script and self.scripts then
			self.scripts:remove(oldChar.script)
			oldChar.script:close()
		end
	else
		self.stage:add(newChar)
	end

	if newChar.script and self.scripts then
		self.scripts:add(newChar.script)
	end

	if isBF then
		self.boyfriend = newChar
		self.stage.boyfriend = newChar
		if self.playerNotefield then self.playerNotefield.character = newChar end
		if self.healthBar and self.healthBar.iconP1 then
			self.healthBar.iconP1:changeIcon(newChar.icon)
		end
	elseif isGF then
		newChar.isGF = true
		self.gf = newChar
		self.stage.gf = newChar
		if self.notefields and self.notefields[3] then
			self.notefields[3].character = newChar
		end
	else
		self.dad = newChar
		self.stage.dad = newChar
		if self.enemyNotefield then self.enemyNotefield.character = newChar end
		if self.healthBar and self.healthBar.iconP2 then
			self.healthBar.iconP2:changeIcon(newChar.icon)
		end
	end

	if newChar.script then
		newChar.script:call("postCreate")
	end

	if self.camTarget == oldChar then
		self.camTarget = newChar
	end
	if oldChar then oldChar:destroy() end
	return newChar
end

function PlayState:doCountdown(beat)
	if self.lastCountdownBeats == beat then return end
	self.lastCountdownBeats = beat

	if beat > #self.countdown.data then
		self.doCountdownAtBeats = nil
	else
		self.countdown:doCountdown(beat)
	end
end

function PlayState:resetStroke(notefield, dir, doPress)
	local receptor = notefield.receptors[dir + 1]
	if receptor then
		receptor:play((doPress and not notefield.bot)
			and "pressed" or "static")
	end
end

function PlayState:reconcileReceptors()
	if not self.notefields then return end
	if controls and controls.update then
		controls:update()
	end
	for _, notefield in pairs(self.notefields) do
		if notefield and notefield.is and not notefield.bot and notefield.receptors then
			for dir = 0, #notefield.receptors - 1 do
				local controlName = PlayState.keysControls[dir]
				local held = controlName and controls and controls:down(controlName)
				if not held then
					local receptor = notefield.receptors[dir + 1]
					local curName = receptor and receptor.animation and receptor.animation.curAnim
						and receptor.animation.curAnim.name or ""
					if curName == "pressed" or curName:sub(1, 12) == "pressed-note" then
						self:resetStroke(notefield, dir, false)
					end
				end
			end
		end
	end
end

function PlayState:resetState()
	self.load = LoadScreen(getmetatable(game.getState())())
	self.load.cameras = {self.camOther}
	self:add(self.load)
end

function PlayState:update(dt)
	if game.keys.justPressed.F5 then
		self:resetState()
	end
	if self.load then
		self.load:update(dt)
		if paths.async.getProgress() == 1 then
			local state = self.load.nextState
			state.skipTransIn = true
			self.skipTransOut = true
			game.switchState(state)
		end
		return
	end

	if not self.paused and game.sound.music:isPlaying() and not self.skipResync then
		self.lastSongTime = game.sound.music.time
	end

	if self.ghostTime > 0 then self.ghostTime = self.ghostTime - dt end

	self.timer:update(dt)
	self.tween:update(dt)

	dt = dt * self.playback
	self.lastTick = love.timer.getTime()

	if self.startedCountdown then
		local time = PlayState.conductor.time + 1000 * dt
		PlayState.conductor:update(time)
		if self.skipConductor then self.skipConductor = false end

		if self.startingSong and PlayState.conductor.time >= self.startPos then
			self.startingSong = false

			local startSec = (self.startPos or 0) / 1000
			if startSec > 0 then
				for _, nf in pairs(self.notefields) do
					if nf and nf.seekTo then nf:seekTo(startSec) end
				end
				while self.events and self.events[self.eventIndex or 1] and
					self.events[self.eventIndex or 1].t < self.startPos do
					local skipped = self.events[self.eventIndex or 1]
					if skipped.e == "FocusCamera" or skipped.e == "ScrollSpeed"
						or skipped.e == "Change Scroll Speed" or skipped.e == "Change Character"
						or skipped.e == "ChangeCharacter" then
						self:executeEvent(skipped)
					end
					self.eventIndex = (self.eventIndex or 1) + 1
				end
			end

			self:playSong(startSec)
			PlayState.conductor.time = self.startPos
			self.scripts:call("songStart")
		else
			local noFocus, events = true, self.events
			local idx = self.eventIndex or 1
			local curMusicMs = game.sound.music.time * 1000
			while events[idx] do
				local e = events[idx]
				if e.t <= curMusicMs then
					self:executeEvent(e)
					idx = idx + 1
					if e.e == "FocusCamera" then noFocus = false end
				else
					break
				end
			end
			self.eventIndex = idx
			if noFocus and self.camTarget and game.camera.followLerp then
				self:cameraMovement(self:getCameraPosition(self.camTarget))
			end
		end

		if self.startingSong and self.doCountdownAtBeats then
			self:doCountdown(math.floor(
				PlayState.conductor.currentBeatFloat - self.doCountdownAtBeats + 1
			))
		end
	end

	local hadDialogue = self:hasActiveDialogue()
	if hadDialogue then
		self._dialogueStunnedPads = true
		if self.buttons then self.buttons:set({stunned = true}) end
		if self.pauseButton and self.pauseButton.pauseButton and self.pauseButton.pauseButton.button then
			self.pauseButton.pauseButton.button.stunned = true
		end
	end

	self.scripts:call("update", dt)
	PlayState.super.update(self, dt)

	local inDialogue = hadDialogue or self:hasActiveDialogue()
	if not inDialogue and self._dialogueStunnedPads then
		self._dialogueStunnedPads = false
		if self.buttons and table.find(self.members, self.buttons) and not self.buttons.pendingEnable then
			self.buttons:set({stunned = false})
		end
		if self.pauseButton and self.pauseButton.pauseButton and self.pauseButton.pauseButton.button then
			self.pauseButton.pauseButton.button.stunned = false
		end
	end

	local time = PlayState.conductor.time / 1000
	local missOffset = time - Note.safeZoneOffset / 1.25
	local shouldRecalculateRating = false
	for _, nf in pairs(self.notefields) do
		if not nf.is then goto continue end
		nf.time, nf.beat = time, PlayState.conductor.currentBeatFloat
		local isPlayer, isPNF, sustainOffset = not nf.bot, nf == self.playerNotefield, 0.25 / nf.speed

		for _, note in ipairs(nf:getNotes(time, nil, true, self._sustainHitBuffer)) do
			local hasInput = not isPlayer or controls:down(PlayState.keysControls[note.direction])
			local char = note.character or (note.gf and self.gf or nf.character)

			if note.wasGoodHit then
				if not note.lastPress or hasInput then note.lastPress = time end

				if not note.wasGoodSustainHit then
					if hasInput and isPNF then
						if not note.__lastScoreTime then note.__lastScoreTime = note.time end

						local currentCap = math.min(time, note.time + note.sustainTime)
						if currentCap > note.__lastScoreTime then
							local diff = currentCap - note.__lastScoreTime
							if diff > 0 and not PlayState.practiceMode then
								self.score = self.score + math.floor(diff * 300)

								self.ratingNeedsRecalc = true
								note.__lastScoreTime = currentCap
							end
						end
					end

					local noteEnd = note.time + note.sustainTime
					if noteEnd - sustainOffset <= note.lastPress then
						local fullHeld = noteEnd <= note.lastPress
						if fullHeld then
							note.wasFullSustainHit = true
						end
						if fullHeld or not hasInput then
							self:goodSustainHit(note, time, fullHeld)
							if hasInput and not isPlayer and char then
								char.lastHit = PlayState.conductor.time
							end
						end
					elseif not hasInput and isPlayer and note.time <= time then
						self:goodSustainHit(note, time)
						note.tooLate = true
					elseif not isPlayer and hasInput and char then
						char.lastHit = PlayState.conductor.time
					end
				end
			elseif isPlayer then
				if not note.wasGoodSustainHit and (note.lastPress or note.time) <= missOffset then
					self:miss(note)
				end
			elseif note.time <= time then
				self:goodNoteHit(note, time)
			end
		end
		::continue::
	end

	if self.ratingNeedsRecalc then
		self:recalculateRating()
		self.ratingNeedsRecalc = false
	end

	self.camZoomMult = util.coolLerp(self.camZoomMult, 1, 3, dt * self.camZoomSpeed)
	local zoomPlusBop = self.camZoom * self.camZoomMult
	game.camera.zoom = zoomPlusBop

	self.camHUD.zoom = util.coolLerp(self.camHUD.zoom, 1, 3, dt * self.camZoomSpeed)
	self.camNotes.zoom = self.camHUD.zoom

	if self.startedCountdown and not inDialogue and controls:pressed("pause") then
		self:tryPause()
	end

	self.healthBar.value = util.coolLerp(self.healthBar.value, self.health, 15, dt)
	if not self.isDead and self.health <= 0 then self:tryGameOver() end

	if self.startedCountdown then
		if controls:pressed("debug_1") then
			game.camera:unfollow()
			self:pauseSong()
			game.switchState(ChartingState())
		end

		if controls:pressed("debug_2") then
			game.camera:unfollow()
			game.sound.music:pause()
			self:pauseSong()
			CharacterEditor.onPlayState = true
			game.switchState(CharacterEditor())
		end

		if not self.isDead and controls:pressed("reset") then self:tryGameOver() end
	end

	if Project.DEBUG_MODE then
		if game.keys.justPressed.ONE then self.playerNotefield.bot = not self.playerNotefield.bot end
		if game.keys.justPressed.TWO then self:endSong() end
		if game.keys.justPressed.THREE and not self.startingSong then
			local time, vocals = (PlayState.conductor.time +
				PlayState.conductor.crotchet * (game.keys.pressed.SHIFT and 8 or 4)) / 1000
			self.skipConductor, PlayState.conductor.time = true, time * 1000
			game.sound.music.time = time
			for _, notefield in pairs(self.notefields) do
				vocals = notefield.vocals
				if vocals then vocals.time = time end
			end
		end
	end

	self.scripts:call("postUpdate", dt)
end

function PlayState:draw()
	self.scripts:call("draw")
	PlayState.super.draw(self)
	self.scripts:call("postDraw")
end

function PlayState:onSettingChange(category, setting)
	game.camera.freezed = false
	self.camNotes.freezed = false
	self.camHUD.freezed = false

	if category == "gameplay" then
		switch(setting, {
			["downScroll"] = function()
				local downscroll = ClientPrefs.data.downScroll
				for _, notefield in pairs(self.notefields) do
					if notefield.is then notefield.downscroll = downscroll end
				end

				self.healthBar.y = game.height * (downscroll and 0.1 or 0.9)
				self:positionText()
				self.downScroll = downscroll
				self:positionNotefields()
			end,
			[{"middleScroll", "splitReceptors", "noteWidth", "splitWidth"}] = function()
				self.middleScroll = ClientPrefs.data.middleScroll
				self:positionNotefields()
			end,
			["botplayMode"] = function()
				self.playerNotefield.bot = ClientPrefs.data.botplayMode
				self:recalculateRating()
				self.usedBotPlay = true
			end,
			["backgroundDim"] = function()
				self.camHUD.bgColor[4] = ClientPrefs.data.backgroundDim / 100
			end,
			["playback"] = function()
				self:setPlayback(ClientPrefs.data.playback)
			end
		})

		game.sound.music.volume = ClientPrefs.data.musicVolume / 100
		local volume, vocals = ClientPrefs.data.vocalVolume / 100
		for _, notefield in pairs(self.notefields) do
			vocals = notefield.vocals
			if vocals then vocals.volume = volume end
		end
	elseif category == "controls" then
		controls:unbindPress(self.bindedKeyPress)
		controls:unbindRelease(self.bindedKeyRelease)

		self.bindedKeyPress = bind(self, self.onKeyPress)
		controls:bindPress(self.bindedKeyPress)

		self.bindedKeyRelease = bind(self, self.onKeyRelease)
		controls:bindRelease(self.bindedKeyRelease)
	end

	self.scripts:call("onSettingChange", category, setting)
end

function PlayState:goodNoteHit(note, time)
	local rating = self:getRating(note.time, time)
	self.scripts:call("goodNoteHit", note, rating, time)

	local notefield, dir, isSustain =
		note.parent, note.direction, note.sustain
	local event = self.scripts:event("onNoteHit",
		Events.NoteHit(notefield, note,
			note.character or (note.gf and self.gf or notefield.character), rating))

	if not event.cancelled and not note.wasGoodHit then
		note.wasGoodHit = true

		if event.unmuteVocals then
			local vocals = notefield.vocals
			if vocals then vocals.volume = ClientPrefs.data.vocalVolume / 100 end
		end

		local char = event.character
		if char and not event.cancelledAnim then
			char.waitReleaseAfterSing = not notefield.bot
			local type, lastsus = note.type ~= "alt" and nil or note.type, notefield.lastSustain
			local sustime = lastsus and lastsus.sustainTime or 0
			if (not lastsus or sustime <= 0 or note.sustainTime > sustime or
					(time - lastsus.time) / sustime >= 0.5) then
				char:sing(dir, type)
				notefield.lastSustain = note
			end
		end

		if not isSustain then
			notefield:removeNote(note)
		elseif rating.mod < 0.5 then
			note:ghost()
		end

		local receptor = notefield.receptors[dir + 1]
		if receptor then
			if not event.strumGlowCancelled and not note.strumGlowCancelled then
				receptor:play("confirm", true)
				if not note.sustain then receptor.holdTime = notefield.bot and 0.15 or 0.25 end
				if ClientPrefs.data.noteSplash and notefield.canSpawnSplash and rating.splash then
					receptor:spawnSplash()
				end
			end
			if isSustain and not event.coverSpawnCancelled and not note.coverSpawnCancelled then
				receptor:spawnCover(note)
			end
		end

		if self.playerNotefield == notefield then
			self.health = math.clamp(self.health + 0.023, 0, 2)
			self.score = self.score + rating.score
			if rating.resetCombo and self.gf then
				local drop = self.gf:getDropAnim(self.combo)
				if drop then self.gf:playAnim(drop, true, nil, true) end
			end

			self.combo = (rating.resetCombo and math.min(self.combo, 0) - 1 or
				math.max(self.combo, 0) + 1)

			if self.gf and self.gf:hasAnim("combo" .. self.combo) then
				self.gf:playAnim("combo" .. self.combo, false, nil, true)
				self.gf.lastHit = notefield.time * 1000
			end

			self:recalculateRating(rating.name)

			local hitSoundVolume = ClientPrefs.data.hitSound
			if hitSoundVolume > 0 then
				game.sound.play(paths.getSound("hitsound"), hitSoundVolume / 100)
			end
		end
	end

	self.scripts:call("postGoodNoteHit", note, rating)
end

function PlayState:goodSustainHit(note, time, fullyHeldSustain)
	self.scripts:call("goodSustainHit", note)

	local notefield, dir, fullScore =
		note.parent, note.direction, fullyHeldSustain ~= nil
	local event = self.scripts:event("onSustainHit",
		Events.NoteHit(notefield, note,
			note.character or (note.gf and self.gf or notefield.character)))
	if not event.cancelled and not note.wasGoodSustainHit then
		note.wasGoodSustainHit = true
		if notefield.lastSustain == note then notefield.lastSustain = nil end

		if not event.cancelledAnim then
			self:resetStroke(notefield, dir, fullyHeldSustain)
		end
		if fullScore then notefield:removeNote(note) end
	end

	self.scripts:call("postGoodSustainHit", note)
end

-- dir can be nil for non-ghost-tap
function PlayState:miss(note, dir)
	local ghostMiss = dir ~= nil
	if not ghostMiss then dir = note.direction end

	local funcParam = ghostMiss and dir or note
	self.scripts:call(ghostMiss and "miss" or "noteMiss", funcParam)

	local notefield = ghostMiss and note or note.parent
	local event = self.scripts:event(ghostMiss and "onMiss" or "onNoteMiss",
		Events.Miss(notefield, dir, ghostMiss and nil or note,
			note.character or (note.gf and self.gf or notefield.character)))
	if not event.cancelled and (ghostMiss or not note.tooLate) then
		if not ghostMiss then
			note.tooLate = true
		end

		if event.muteVocals and notefield.vocals then notefield.vocals.volume = 0 end

		if event.triggerSound then
			util.playSfx(paths.getSound("gameplay/missnote" .. love.math.random(1, 3)),
				love.math.random(1, 2) / 10)
		end

		local char = event.character
		if char and not event.cancelledAnim then
			char:sing(dir, "miss")
		end

		if notefield == self.playerNotefield then
			self.health = math.clamp(self.health - (ghostMiss and 0.04 or 0.0475), 0, 2)
			self.score, self.misses = self.score - 100, self.misses + 1
			if not ghostMiss then
				if self.gf and not event.cancelledSadGF then
					local drop = self.gf:getDropAnim(self.combo)
					if drop then self.gf:playAnim(drop, true, nil, true) end
				end
				self.combo = math.min(self.combo, 0) - 1
				self:popUpScore()
			end
			self:recalculateRating()
		end
	end
	notefield.lastSustain = nil

	self.scripts:call(ghostMiss and "postMiss" or "postNoteMiss", funcParam)
end

function PlayState:recalculateRating(rating)
	self.scoreText.content = ClientPrefs.data.botplayMode and "Botplay Enabled" or
		"Score: " .. util.formatNumber(math.floor(self.score))
	if rating then
		local field = rating .. "s"
		self[field] = (self[field] or 0) + 1
		self:popUpScore(rating)
	end
end

function PlayState:popUpScore(rating)
	local event = self.scripts:event('onPopUpScore', Events.PopUpScore())
	if not event.cancelled then
		self.judgeSprites.ratingVisible = not event.hideRating
		self.judgeSprites.comboNumVisible = not event.hideScore
		self.judgeSprites:spawn(rating, self.combo)
	end
end

function PlayState:tryPause()
	local event = self.scripts:call("pause")
	if event ~= Script.Event_Cancel then
		game.camera:unfollow(false)
		game.camera:freeze()
		self.camNotes:freeze()
		self.camHUD:freeze()

		self:pauseSong()

		if self.buttons then self:remove(self.buttons) end

		local pause = PauseSubstate()
		pause.cameras = {self.camOther}
		self:openSubstate(pause)
	end
end

function PlayState:tryGameOver()
	local event = self.scripts:event("onGameOver", Events.GameOver())
	if not event.cancelled then
		if self.buttons then self:remove(self.buttons) end

		GameOverSubstate.characterName = event.characterName
		GameOverSubstate.deathSoundName = event.deathSoundName
		GameOverSubstate.loopSoundName = event.loopSoundName
		GameOverSubstate.endSoundName = event.endSoundName
		GameOverSubstate.deaths = GameOverSubstate.deaths + 1

		local tween = Tween.tween(self, {playback = 0.001}, 1, {
			ease = Ease.quadOut,
			onUpdate = function() self:setPlayback() end
		})

		self.scripts:call("gameOverCreate")

		local function openGameOver()
			if game.getState() ~= self then return end
			if event.pauseSong then
				self:pauseSong()
			end
			self.paused = event.pauseGame
			tween:cancel()
			self:setPlayback(1)

			self.camHUD.visible, self.camNotes.visible = false, false
			if self.boyfriend then
				self.boyfriend.visible = false
			end
			self:openSubstate(GameOverSubstate(self.stage.boyfriendPos.x,
				self.stage.boyfriendPos.y))
			self.scripts:call("postGameOverCreate")
		end

		if GameOverSubstate.characterName ~= "" then
			local data = Parser.getCharacter(GameOverSubstate.characterName)
			if data and data.sprite then
				if paths.exists(paths.getPath("images/" .. data.sprite .. "/Animation.json"), "file") then
					paths.getAnimateAtlas(data.sprite)
					openGameOver()
				else
					paths.async.getImage(data.sprite, openGameOver)
				end
			else
				openGameOver()
			end
		else
			openGameOver()
		end

		self.isDead = true
	end
end

function PlayState:getKeyFromEvent(controls)
	for _, control in pairs(controls) do
		local dir = PlayState.inputDirections[control]
		if dir ~= nil then return dir end
	end
	return -1
end

function PlayState:onKeyPress(key, type, scancode, isrepeat, time)
	if isrepeat then return end
	if self.substate and not self.persistentUpdate then return end
	if self:hasActiveDialogue() then return end
	local boundControls = controls:getControlsFromSource(type .. ":" .. key)
	local ghostTap = ClientPrefs.data.ghostTap and self.ghostTime <= 0

	if not boundControls then return end
	key = self:getKeyFromEvent(boundControls)
	if key < 0 then return end

	local pressWallTime = time or love.timer.getTime()
	local fixedKey, offset = key + 1,
		(pressWallTime - (self.lastTick or pressWallTime)) * game.sound.music:getActualPitch()
	for _, notefield in pairs(self.notefields) do
		if notefield.is and not notefield.bot then
			local nfTime = notefield.time + offset
			local hitNotes, hasSustain = notefield:getNotes(nfTime, key)
			local l = #hitNotes

			if l == 0 then
				local receptor = notefield.receptors[fixedKey]
				if receptor then
					receptor:play(hasSustain and "confirm" or "pressed")
				end
				if not hasSustain and not ghostTap then
					self:miss(notefield, key)
				end
			else
				-- remove stacked notes (this is dedicated to spam songs)
				local i, firstNote, note = 2, hitNotes[1]
				while i <= l do
					note = hitNotes[i]
					if note and math.abs(note.time - firstNote.time) < 0.01 then
						notefield:removeNote(note)
					else
						break
					end
					i = i + 1
				end
				self:goodNoteHit(firstNote, nfTime)
				self.ghostTime = 0.17
			end
		end
	end
end

function PlayState:onKeyRelease(key, type, scancode, time)
	if self.substate and not self.persistentUpdate then return end
	local boundControls = controls:getControlsFromSource(type .. ":" .. key)

	if not boundControls then return end
	key = self:getKeyFromEvent(boundControls)

	if key < 0 then return end
	local controlName = PlayState.keysControls[key]
	if controlName and controls:down(controlName) then return end

	for _, notefield in pairs(self.notefields) do
		if notefield.is and not notefield.bot then
			self:resetStroke(notefield, key)
		end
	end
end

function PlayState:closeSubstate()
	self.scripts:call("substateClosed")
	PlayState.super.closeSubstate(self)

	game.camera:unfreeze()
	self.camNotes:unfreeze()
	self.camHUD:unfreeze()

	game.camera.target = self.camFollow

	if not self.startingSong then
		self:playSong()
		if Discord then self:updateDiscordRPC() end
	end

	if self.buttons and not table.find(self.members, self.buttons) then
		self:add(self.buttons)
	end
	if self.pauseButton and self.pauseButton.promotePad then
		self.pauseButton:promotePad()
	end
	self:reconcileReceptors()

	self.scripts:call("postSubstateClosed")
end

function PlayState:endSong(skip)
	if PlayState.storyMode and not skip then
		local name, type = PlayState.getCutscene(true)
		if name then
			self:executeCutscene(name, type, function()
				self:endSong(true)
			end)
			return
		end
	end
	PlayState.seenCutscene = false

	local event = self.scripts:call("endSong")
	if event == Script.Event_Cancel then return end

	if Recorder then Recorder.onSongEnd() end

	game.sound.music:reset(true)
	for _, notefield in pairs(self.notefields) do
		if notefield.vocals then notefield.vocals:stop() end
	end

	if not self.usedBotPlay and not self.chartingMode and not PlayState.chartingMode then
		Highscore.saveScore(PlayState.SONG.song, self.score, self.songDifficulty)
	end
	if self.chartingMode or PlayState.chartingMode then
		controls:unbindPress(self.bindedKeyPress)
		controls:unbindRelease(self.bindedKeyRelease)
		game.sound.music.onComplete = nil
		self.skipResync = true
		game.switchState(ChartingState())
		return
	end

	if PlayState.storyMode then
		PlayState.canFadeInReceptors = false
		if not self.usedBotPlay then
			PlayState.storyScore = PlayState.storyScore + self.score
		end

		table.remove(PlayState.storyPlaylist, 1)
		if #PlayState.storyPlaylist > 0 then
			game.sound.music:stop()

			if Discord then
				local detailsText = "Freeplay"
				if PlayState.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

				Discord.changePresence({
					details = detailsText,
					state = 'Loading next song..'
				})
			end

			if not PlayState.loadSong(PlayState.storyPlaylist[1], PlayState.songDifficulty) then
				GameOverSubstate.deaths = 0
				PlayState.storyScore = 0
				PlayState.canFadeInReceptors = true
				local stickers = Stickers(nil, StoryMenuState())
				self:add(stickers)
				util.playMenuMusic()
			else
				self:resetState()
			end
		else
			GameOverSubstate.deaths = 0
			PlayState.canFadeInReceptors = true
			if not self.usedBotPlay then
				Highscore.saveWeekScore(PlayState.storyWeekFile, PlayState.storyScore, self.songDifficulty)
			end
			PlayState.storyScore = 0

			local stickers = Stickers(nil, StoryMenuState())
			self:add(stickers)

			util.playMenuMusic()
		end
		Parser.clearCache()
	else
		GameOverSubstate.deaths = 0
		PlayState.canFadeInReceptors = true
		game.camera:unfollow()

		local stickers = Stickers(nil, FreeplayState())
		self:add(stickers)

		util.playMenuMusic()
	end
	controls:unbindPress(self.bindedKeyPress)
	controls:unbindRelease(self.bindedKeyRelease)
	game.sound.music.onComplete = nil
	self.skipResync = true

	self.scripts:call("postEndSong")
end

function PlayState:updateDiscordRPC(paused)
	if not Discord then return end

	local detailsText = "Freeplay"
	if PlayState.storyMode then detailsText = "Story Mode: " .. PlayState.storyWeek end

	local diff = (PlayState.songDifficulty and PlayState.songDifficulty ~= "")
		and PlayState.songDifficulty or PlayState.defaultDifficulty

	if paused then
		Discord.changePresence({
			details = "Paused - " .. detailsText,
			state = PlayState.SONG.song .. ' - [' .. diff .. ']'
		})
		return
	end

	if self.startingSong or not game.sound.music or not game.sound.music:isPlaying() then
		Discord.changePresence({
			details = detailsText,
			state = PlayState.SONG.song .. ' - [' .. diff .. ']'
		})
	else
		local startTimestamp = os.time() * 1000
		local remaining = math.max(0, (game.sound.music.duration - game.sound.music.time)) * 1000
		local endTimestamp = startTimestamp + remaining
		Discord.changePresence({
			details = detailsText,
			state = PlayState.SONG.song .. ' - [' .. diff .. ']',
			timestamps = {
				start = math.floor(startTimestamp),
				["end"] = math.floor(endTimestamp)
			}
		})
	end
end

function PlayState:leave()
	if Recorder then Recorder.onSongEnd() end
	self.scripts:call("leave")

	PlayState.prevCamFollow = self.camFollow
	if PlayState.conductor then
		PlayState.conductor:destroy()
		PlayState.conductor = nil
	end
	if game.sound.music then
		game.sound.music.onComplete = nil
	end
	if self.timer then self.timer:clear() end
	if self.tween then self.tween:clear() end

	controls:unbindPress(self.bindedKeyPress)
	controls:unbindRelease(self.bindedKeyRelease)
	Parser.clearCache()

	self.scripts:call("postLeave")
	self.scripts:close()
end

return PlayState
