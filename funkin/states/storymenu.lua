local StoryMenuState = State:extend("StoryMenuState")

local StoryCharacter = require "funkin.ui.storymenu.character"
local StoryWeek = require "funkin.ui.storymenu.week"

StoryMenuState.curDifficulty = 2

function StoryMenuState:enter()
	self.notCreated = false

	self.script = Script("data/states/storymenu", false)
	local event = self.script:call("create")
	if event == Script.Event_Cancel then
		StoryMenuState.super.enter(self)
		self.notCreated = true
		self.script:call("postCreate")
		return
	end

	-- Update Presence
	if Discord then
		Discord.changePresence({details = "In the Menus", state = "Story Menu"})
	end

	self.lerpScore = 0
	self.intendedScore = 0

	self.inSubstate = false

	self.persistentUpdate = true
	self.persistentDraw = true

	self.movedBack = false
	self.selectedWeek = false
	self.diffs = {"Easy", PlayState.defaultDifficulty, "Hard"}

	PlayState.storyMode = true

	self.scoreText = Text(10, 10, "SCORE: 0",
		paths.getFont('vcr.ttf', 36), Color.WHITE, 'right')
	self.scoreText.antialiasing = false

	self.txtWeekTitle = Text(game.width * 0.7, 10, "",
		paths.getFont('vcr.ttf', 32), Color.WHITE, 'right')
	self.txtWeekTitle.alpha = 0.7
	self.txtWeekTitle.antialiasing = false

	local ui_tex = paths.getSparrowAtlas(
		'menus/storymenu/campaign_menu_UI_assets');
	local bgYellow =
		Graphic(0, 56, game.width, 386, Color.fromRGB(249, 207, 81))

	self.weekList = MenuList(paths.getSound("scrollMenu"), true, "centered")
	self.weekList.changeCallback = bind(self, self.changeWeek)
	self:add(self.weekList)

	local blackBar = Graphic(0, 0, game.width, 56, Color.BLACK)
	self:add(blackBar)

	self.grpWeekCharacters = Group()

	self.grpLocks = Group()
	self:add(self.grpLocks)

	self.weeksData = {}
	self:loadWeeks()
	local l = #self.weeksData
	if l ~= 0 and self.weekList.curSelected > l then
		self.weekList.curSelected = l
	end

	if #self.weeksData > 0 then
		for i, week in pairs(self.weeksData) do
			local weekThing = StoryWeek(0, bgYellow.y + bgYellow.height + 10,
				week.sprite)

			self.weekList:add(weekThing)
			weekThing.spaceFactor = 1
			weekThing.yAdd = game.height * 0.68

			if week.locked then
				local lock = Sprite(weekThing.width + 10 + weekThing.x)
				lock:setFrames(ui_tex)
				lock.animation:addByPrefix('lock', 'lock')
				lock.animation:play('lock')

				weekThing.attach = lock
			end
		end

		local charTable = self.weeksData[self.weekList.curSelected].characters
		for char = 0, 2 do
			local weekCharThing = StoryCharacter(
				(game.width * 0.25) * (1 + char) - 150,
				charTable[char + 1])
			weekCharThing.y = weekCharThing.y + 70
			self.grpWeekCharacters:add(weekCharThing)
		end

		self.difficultySelector = SpriteGroup()
		self:add(self.difficultySelector)

		self.leftArrow = Sprite(0, self.weekList.members[1].y)
		self.leftArrow:setFrames(ui_tex)
		self.leftArrow.animation:addByPrefix('idle', "arrow left")
		self.leftArrow.animation:addByPrefix('press', "arrow push left")
		self.leftArrow.animation:play('idle')
		self.difficultySelector:add(self.leftArrow)

		self.sprDifficulty = Sprite(0, self.leftArrow.y)
		self.difficultySelector:add(self.sprDifficulty)

		self.rightArrow = Sprite(self.leftArrow.x + 376, self.leftArrow.y)
		self.rightArrow:setFrames(ui_tex)
		self.rightArrow.animation:addByPrefix('idle', "arrow right")
		self.rightArrow.animation:addByPrefix('press', "arrow push right")
		self.rightArrow.animation:play('idle')
		self.difficultySelector:add(self.rightArrow)

		local grp = self.weekList.members[1]
		self.difficultySelector.x = grp.x + grp.width + 10
	end

	self:add(bgYellow)
	self:add(self.grpWeekCharacters)

	if #self.weeksData == 0 then
		self.noWeeksTxt = AtlasText(0, 210, 'No weeks here', "bold")
		self.noWeeksTxt:screenCenter('x')
		self:add(self.noWeeksTxt)
	end

	self.txtTrackList = Text(game.width * 0.05,
		bgYellow.x + bgYellow.height + 100, "TRACKS",
		paths.getFont('vcr.ttf', 32),
		Color.fromRGB(229, 87, 119), 'center')
	self.txtTrackList.visible = (#self.weeksData > 0)
	self.txtTrackList.antialiasing = false
	self:add(self.txtTrackList)
	self:add(self.scoreText)
	self:add(self.txtWeekTitle)

	self.throttles = {}
	self.throttles.left = Throttle:make({controls.down, controls, "ui_left"})
	self.throttles.right = Throttle:make({controls.down, controls, "ui_right"})

	if love.system.getDevice() == "Mobile" then
		self.buttons = util.createButtons(self.noWeeksTxt and "b" or "lrudab")
		self:add(self.buttons)
	end

	if #self.weeksData > 0 then
		self:changeWeek()
		self.weekList:changeSelection()
		self:changeDifficulty()
	end

	StoryMenuState.super.enter(self)

	self.script:call("postCreate")
end

function StoryMenuState:update(dt)
	self.script:call("update", dt)
	if self.notCreated then
		StoryMenuState.super.update(self, dt)
		self.script:call("postUpdate")
		return
	end

	self.lerpScore = util.coolLerp(self.lerpScore, self.intendedScore, 30, dt)
	local roundedScore = math.round(self.lerpScore)
	if self._lastRoundedScore ~= roundedScore then
		self._lastRoundedScore = roundedScore
		self.scoreText.content = 'LEVEL SCORE:' .. roundedScore
	end

	if #self.weeksData > 0 and not self.movedBack and not self.selectedWeek and
		not self.inSubstate and self.throttles then
		if controls:down("ui_left") then
			self.leftArrow.animation:play('press')
		elseif self.leftArrow.animation.name ~= "idle" then
			self.leftArrow.animation:play('idle')
		end
		if controls:down("ui_right") then
			self.rightArrow.animation:play('press')
		elseif self.rightArrow.animation.name ~= "idle" then
			self.rightArrow.animation:play('idle')
		end

		if self.throttles.left:check() then self:changeDifficulty(-1) end
		if self.throttles.right:check() then self:changeDifficulty(1) end

		if controls:pressed("accept") then self:selectWeek() end
	end

	if controls:pressed("back") and not self.movedBack and not self.selectedWeek and
		not self.inSubstate then
		util.playSfx(paths.getSound("cancelMenu"))
		self.movedBack = true
		game.switchState(MainMenuState())
	end

	StoryMenuState.super.update(self, dt)

	self.script:call("postUpdate", dt)
end

function StoryMenuState:selectWeek()
	if not self.weeksData[self.weekList.curSelected].locked then
		local songTable = {}
		local leWeek = self.weeksData[self.weekList.curSelected]
		for i = 1, #leWeek.songs do
			local entry = leWeek.songs[i]
			table.insert(songTable, type(entry) == "table" and entry[1] or entry)
		end

		local songDiffs = (type(leWeek.difficulties) == "table" and #leWeek.difficulties > 0)
			and leWeek.difficulties or self.diffs
		StoryMenuState.curDifficulty = (StoryMenuState.curDifficulty - 1) % #songDiffs + 1
		local diff = songDiffs[StoryMenuState.curDifficulty]

		if #songTable == 0 or not PlayState.loadSong(songTable[1], diff) then
			self.selectedWeek = false
			self.weekList.lock = false
			util.playSfx(paths.getSound('cancelMenu'))
			return false
		end

		local toState = LoadState(PlayState(true, songTable, diff))
		PlayState.storyWeek = leWeek.name
		PlayState.storyWeekFile = leWeek.file

		if not self.selectedWeek then
			util.playSfx(paths.getSound('confirmMenu'))
			self.weekList.members[self.weekList.curSelected]:startFlashing()
			for _, char in pairs(self.grpWeekCharacters.members) do
				if char.character ~= '' and char.hasConfirmAnimation then
					char.animation:play('confirm')
				end
			end
			self.selectedWeek = true
			self.weekList.lock = true
		end

		Timer.wait(1, function() game.switchState(toState) end)
	else
		util.playSfx(paths.getSound('cancelMenu'))
	end
end

function StoryMenuState:changeDifficulty(change)
	if change == nil then change = 0 end
	local leWeek = self.weeksData[self.weekList.curSelected]
	local songDiffs = (leWeek and type(leWeek.difficulties) == "table" and #leWeek.difficulties > 0)
		and leWeek.difficulties or self.diffs

	StoryMenuState.curDifficulty = StoryMenuState.curDifficulty + change
	StoryMenuState.curDifficulty = (StoryMenuState.curDifficulty - 1) % #songDiffs + 1

	local storyDiff = songDiffs[StoryMenuState.curDifficulty]
	local newImage = paths.getImage('menus/storymenu/difficulties/' ..
		paths.formatToSongPath(storyDiff))

	if self.sprDifficulty.texture ~= newImage then
		self.sprDifficulty:loadTexture(newImage)
		local area = (self.leftArrow.x + self.leftArrow.width) + self.rightArrow.x
		self.sprDifficulty.x = (area - self.sprDifficulty.width) / 2
		self.sprDifficulty.y = self.leftArrow.y - 15
		self.sprDifficulty.alpha = 0

		Tween.cancelTweensOf(self.sprDifficulty)
		Tween.tween(self.sprDifficulty,
			{y = self.leftArrow.y + 15, alpha = 1}, 0.07)
	end

	self.intendedScore = Highscore.getWeekScore(self.weeksData[self.weekList.curSelected].file,
		songDiffs[StoryMenuState.curDifficulty])
end

function StoryMenuState:changeWeek(change)
	local leWeek = self.weeksData[self.weekList.curSelected]
	self.txtWeekTitle.content = (leWeek.name or leWeek.storyName or leWeek.file or ""):upper()
	self.txtWeekTitle.x = game.width - (self.txtWeekTitle:getWidth() + 10)

	for _, spr in pairs(self.difficultySelector.members) do
		spr.visible = not leWeek.locked
	end

	self:changeDifficulty(0)
	self:updateText()
end

function StoryMenuState:updateText()
	local weekTable = self.weeksData[self.weekList.curSelected].characters or {"", "bf", "gf"}
	for i = 1, math.min(3, #self.grpWeekCharacters.members) do
		self.grpWeekCharacters.members[i]:changeCharacter(weekTable[i] or "")
	end

	local leWeek = self.weeksData[self.weekList.curSelected]
	local songNames = {}
	for i = 1, #(leWeek.songs or {}) do
		local entry = leWeek.songs[i]
		songNames[i] = tostring(type(entry) == "table" and entry[1] or entry)
	end
	local songs = table.concat(songNames, "\n")
	self.txtTrackList.content = 'TRACKS\n\n' .. songs
	self.txtTrackList:screenCenter("x")
	self.txtTrackList.x = self.txtTrackList.x - game.width * 0.35

	local songDiffs = (type(leWeek.difficulties) == "table" and #leWeek.difficulties > 0)
		and leWeek.difficulties or self.diffs
	StoryMenuState.curDifficulty = (StoryMenuState.curDifficulty - 1) % #songDiffs + 1
	self.intendedScore = Highscore.getWeekScore(self.weeksData[self.weekList.curSelected].file,
		songDiffs[StoryMenuState.curDifficulty])
end

function StoryMenuState:closeSubstate()
	self.inSubstate = false
	StoryMenuState.super.closeSubstate(self)
end

local function normalizeWeekData(data, week)
	if type(data) ~= "table" then return nil end
	if data.hide_sm or data.hideStoryMode then return nil end
	data.file = week
	data.name = data.name or data.storyName or data.weekName or week
	data.sprite = data.sprite or data.itemFile or week
	data.characters = data.characters or data.weekCharacters or data.chars or {"", "bf", "gf"}
	if data.locked == nil and data.startUnlocked ~= nil then
		data.locked = not data.startUnlocked
	end
	if type(data.difficulties) == "string" then
		local parsed = {}
		for part in data.difficulties:gmatch("([^,]+)") do
			local trimmed = part:gsub("^%s+", ""):gsub("%s+$", "")
			if trimmed ~= "" then table.insert(parsed, trimmed) end
		end
		data.difficulties = #parsed > 0 and parsed or nil
	end
	return data
end

function StoryMenuState:loadWeeks()
	local func = Mods.currentMod and paths.getMods or function(...)
		return paths.getPath(..., false)
	end
	if paths.exists(func('data/weekList.txt'), 'file') then
		for _, rawWeek in pairs((paths.getText('weekList') or ""):gsub('\r', ''):split('\n')) do
			local week = rawWeek:gsub("^%s+", ""):gsub("%s+$", "")
			if week ~= "" and week:sub(1, 1) ~= "#" then
				local data = normalizeWeekData(paths.getJSON('data/weeks/weeks/' .. week), week)
				if data then
					table.insert(self.weeksData, data)
				end
			end
		end
	elseif paths.exists(func('data/weeks/weeks'), 'directory') then
		for _, str in pairs(love.filesystem.getDirectoryItems(func('data/weeks/weeks'))) do
			if str:endsWith('.json') then
				local week = str:withoutExt()
				local data = normalizeWeekData(paths.getJSON('data/weeks/weeks/' .. week), week)
				if data then
					table.insert(self.weeksData, data)
				end
			end
		end
	end
end

function StoryMenuState:leave()
	self.script:call("leave")
	if self.throttles then
		for _, v in pairs(self.throttles) do v:destroy() end
		self.throttles = nil
	end
	self.script:call("postLeave")
	self.script:close()
end

return StoryMenuState
