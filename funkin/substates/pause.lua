local PauseSubstate = Substate:extend("PauseSubstate")

function PauseSubstate:new()
	PauseSubstate.super.new(self)

	local songData = PlayState.SONG
	local diffs = (songData and type(songData.difficulties) == "table") and songData.difficulties or {}

	self.menuItems = {"Resume", "Restart song", "Options", "Exit to menu"}
	if #diffs > 1 then
		table.insert(self.menuItems, 3, "Change difficulty")
	end

	self.blockInput = false
	self.lock = false
	self._closed = false

	self:loadMusic()

	self.bg = Graphic(0, 0, game.width, game.height, Color.BLACK)
	self.bg.alpha = 0
	self.bg.scrollFactor:set()
	self:add(self.bg)

	self.menuList = MenuList(paths.getSound('scrollMenu'), false,
		love.system.getDevice() == "Mobile" and "mobile" or nil)
	self.menuList.selectCallback = bind(self, self.selectOption)
	self:add(self.menuList)

	self.diffTextList = AtlasText(18, 18, "Change difficulty", "bold")
	self.diffList = MenuList(paths.getSound('scrollMenu'), false,
		love.system.getDevice() == "Mobile" and "mobile" or nil)
	self.diffList.selectCallback = bind(self, self.selectDifficulty)
	self.diffList.lock, self.diffList.open = true, false

	for i = 1, #self.menuItems do
		local item = AtlasText(0, 0, self.menuItems[i], "bold")
		self.menuList:add(item)
	end
	for i = 1, #diffs do
		if diffs[i]:lower() ~= (PlayState.songDifficulty or ""):lower() then
			local item = AtlasText(0, 0, diffs[i], "bold")
			self.diffList:add(item)
		end
	end

	self.menuList:changeSelection()

	local displayName = (songData and songData.metadata and songData.metadata.displayName)
		or (songData and songData.song) or "?"
	local txt, font = displayName, paths.getFont("vcr.ttf", 32)
	self.songText = Text(0, 15, txt, font)
	self.songText.x = game.width - self.songText:getWidth() - 28
	self.songText.alpha = 0
	self:add(self.songText)

	txt = "Difficulty: " .. (PlayState.songDifficulty or "?")
	self.diffText = Text(0, 47, txt, font)
	self.diffText.x = game.width - self.diffText:getWidth() - 28
	self.diffText.alpha = 0
	self:add(self.diffText)

	txt = GameOverSubstate.deaths .. " Blue Balls"
	self.deathsText = Text(0, 79, txt, font)
	self.deathsText.x = game.width - self.deathsText:getWidth() - 28
	self.deathsText.alpha = 0
	self:add(self.deathsText)
end

function PauseSubstate:loadMusic()
	self.curPauseMusic = self:loadPauseMusic()
	if not self.curPauseMusic or self.curPauseMusic == "" or self.curPauseMusic:lower() == "none" then
		self.music = nil
		return
	end
	local asset = paths.getMusic('pause/' .. self.curPauseMusic) or paths.getMusic('pause/railways')
	self.music = asset and game.sound.load(asset) or nil
end

function PauseSubstate:enter()
	if self.music then
		self.music:play(0, true)
		self.music:fade(6, 0, ClientPrefs.data.menuMusicVolume / 100)
	end

	Tween.tween(self.bg, {alpha = 0.6}, 0.4, {ease = 'quartInOut'})
	Tween.tween(self.songText, {y = self.songText.y + 5, alpha = 1},
		0.4, {ease = 'quartInOut'})
	Tween.tween(self.diffText, {y = self.diffText.y + 5, alpha = 1},
		0.4, {ease = 'quartInOut', startDelay = 0.2})
	Tween.tween(self.deathsText, {y = self.deathsText.y + 5, alpha = 1},
		0.4, {ease = 'quartInOut', startDelay = 0.4})

	self._openingFrame = true

	if love.system.getDevice() == "Mobile" then
		self.buttons = util.createButtons("b")
		self:add(self.buttons)

		if self.parent and self.parent.pauseButton then
			self.parent:remove(self.parent.pauseButton)
			self:add(self.parent.pauseButton)
			if self.parent.pauseButton.setPadStunned then
				self.parent.pauseButton:setPadStunned(true)
			end
			Tween.cancelTweensOf(self.parent.pauseButton)
			Tween.tween(self.parent.pauseButton, {alpha = 0}, 0.6, {ease = Ease.quartOut, startDelay = 0.5});
		end
	end
end

function PauseSubstate:resetState()
	self.lock = true

	self.load = LoadScreen(getmetatable(game.getState())())
	self:add(self.load)
end

function PauseSubstate:selectDifficulty(daChoice)
	PlayState.loadSong(PlayState.SONG.song, PlayState.SONG.difficulties[
		table.find(PlayState.SONG.difficulties, tostring(daChoice))])
	self:resetState()
end

function PauseSubstate:selectOption(daChoice)
	if self.lock or self.blockInput then return end

	switch(tostring(daChoice):lower(), {
		["resume"] = function() self:close() end,
		["restart song"] = function()
			self:resetState()
		end,
		["change difficulty"] = function()
			self:openDifficultyMenu()
		end,
		["options"] = function()
			if self.buttons then self:remove(self.buttons) end
			self.optionsUI = self.optionsUI or Options(false, function()

				if self.buttons then self:add(self.buttons) end

				self.menuList.alpha = 1
				self.menuList.lock = false
				self.blockInput = false
			end)
			self.optionsUI.applySettings = bind(self, self.onSettingChange)
			self.optionsUI.scrollFactor:set()
			self.optionsUI:screenCenter()
			self:add(self.optionsUI)

			self.menuList.alpha = 0.25
			self.menuList.lock = true
			self.blockInput = true
		end,
		["exit to menu"] = function()
			game.sound.music.pitch = 1
			self.music:stop()
			util.playMenuMusic()
			PlayState.chartingMode = false
			PlayState.startPos = 0
			if PlayState.storyMode then
				PlayState.seenCutscene = false
				local stickers = Stickers()
				stickers:start(StoryMenuState())
				self:add(stickers)
			else
				local stickers = Stickers()
				stickers:start(FreeplayState())
				self:add(stickers)
			end
			GameOverSubstate.deaths = 0
			PlayState.canFadeInReceptors = true
		end,
		default = function() print("missing option") end
	})
end

function PauseSubstate:update(dt)
	if self.load then
		if paths.async.getProgress() == 1 then
			local state = self.load.nextState
			state.skipTransIn = true
			self.parent.skipTransOut = true
			game.switchState(state)
		end
	end
	PauseSubstate.super.update(self, dt)

	if self._openingFrame then
		self._openingFrame = false
		return
	end

	if self.lock or self.blockInput or self.optionsUI then return end

	if self.diffList.open then
		if controls:pressed("back") then
			self:closeDifficultyMenu()
		end
	elseif controls:pressed("back") or (controls:pressed("pause") and not controls:pressed("accept")) then
		self:close()
	end
end

function PauseSubstate:openDifficultyMenu()
	if self.diffList.open or self.lock then return end
	util.playSfx(paths.getSound("scrollMenu"))

	self:add(self.diffList)
	self:add(self.diffTextList)
	self.diffTextList.alpha = 0

	Tween.cancelTweensOf(self.diffList)
	Tween.cancelTweensOf(self.diffTextList)
	Tween.cancelTweensOf(self.menuList)

	for i = 1, #self.diffList.members do
		self.diffList.members[i].target = 0
	end
	self.diffList:updatePositions(game.dt, 0)
	self.diffList:changeSelection(nil, true)

	self.menuList.lock = true
	self.blockInput = true
	Timer(self.timer):start(0.1, function() self.diffList.lock = false end)

	self.diffList.x = -300
	Tween.tween(self.diffList, {x = 120}, 0.4, {ease = "circOut", onComplete = function()
		self.diffList.open = true
	end})
	Tween.tween(self.menuList, {alpha = 0}, 0.4, {ease = "circOut"})
	Tween.tween(self.diffTextList, {alpha = 1}, 0.2, {ease = "circOut"})
end

function PauseSubstate:closeDifficultyMenu()
	if self.diffList.closing or self.lock then return end
	util.playSfx(paths.getSound("cancelMenu"))

	self.diffList.closing = true
	Tween.tween(self.diffList, {x = -300}, 0.21, {ease = "circIn", onComplete = function()
		self:remove(self.diffList)
		self.diffList.closing = false
		self.diffList.open = false
	end})
	Tween.tween(self.menuList, {alpha = 1}, 0.21, {ease = "circIn", onComplete = function()
		Tween.cancelTweensOf(self.menuList)
	end})
	Tween.tween(self.diffTextList, {alpha = 0}, 0.2, {ease = "circOut", onComplete = function()
		self:remove(self.diffTextList)
	end})

	self.menuList.lock = false
	self.diffList.lock = true
	self.blockInput = false
end

function PauseSubstate:onSettingChange(setting, option)
	if self.parent and self.parent.onSettingChange then
		self.parent:onSettingChange(setting, option)
	end

	if setting == "gameplay" then
		if option == "pauseMusic" then
			if self.activeTimer then
				Timer.cancel(self.activeTimer)
				self.activeTimer = nil
			end

			self.activeTimer = Timer.start(1, function()
				if self._closed or not self.parent or ClientPrefs.data.pauseMusic == self.curPauseMusic then return end
				if self.music then
					self.music:fade(0.7, self.music:getVolume(), 0)
				end
				self.activeTimer = Timer.start(0.8, function()
					if self._closed or not self.parent or ClientPrefs.data.pauseMusic == self.curPauseMusic then return end
					if self.music then
						self.music:stop()
						self.music:cancelFade()
						self.music:destroy()
						self.music = nil
					end
					self:loadMusic()
					if self.music then
						self.music:play(ClientPrefs.data.menuMusicVolume / 100, true)
					end
				end)
			end)
		elseif option == "menuMusicVolume" then
			if self.music then
				self.music:fade(1, self.music:getVolume(), ClientPrefs.data.menuMusicVolume / 100)
			end
		end
	end
end

function PauseSubstate:loadPauseMusic()
	local pauseMusic = ClientPrefs.data.pauseMusic or "railways"
	if pauseMusic == "breakfast" then
		local songName = (PlayState.SONG and PlayState.SONG.song or ""):lower()
		if songName == "pico" or songName == "philly nice" or songName == "blammed" then
			pauseMusic = pauseMusic .. "-pico"
		elseif songName == "senpai" or songName == "roses" or songName == "thorns" then
			pauseMusic = pauseMusic .. "-pixel"
		end
	end
	return pauseMusic
end

function PauseSubstate:close()
	self._closed = true
	if self.activeTimer then
		Timer.cancel(self.activeTimer)
		self.activeTimer = nil
	end

	if self.parent and self.parent.pauseButton then
		self:remove(self.parent.pauseButton)
		self.parent:add(self.parent.pauseButton)
		if self.parent.pauseButton.setPadStunned then
			self.parent.pauseButton:setPadStunned(false)
		end
		if self.parent.pauseButton.promotePad then
			self.parent.pauseButton:promotePad()
		end
		Tween.cancelTweensOf(self.parent.pauseButton)
		Tween.tween(self.parent.pauseButton, {alpha = 1}, 0.25, {ease = Ease.quartOut})
		if self.parent.pauseCircle then
			Tween.cancelTweensOf(self.parent.pauseCircle)
			Tween.tween(self.parent.pauseCircle, {alpha = 0.1}, 0.25, {ease = Ease.quartOut})
		end
	end

	if self.music then
		self.music:stop()
		self.music:destroy()
		self.music = nil
	end

	if self.optionsUI then self.optionsUI:destroy() end
	self.optionsUI = nil

	if self.buttons then self.buttons:destroy() end

	PauseSubstate.super.close(self)
end

return PauseSubstate
