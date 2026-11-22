local Hud = {}

local WIDTH, HEIGHT, OFFSET = 600, 18, 3

local function panel(width, height, color, alpha)
	local graphic = Graphic(0, 0, width, height, color)
	graphic.alpha = alpha or 1
	graphic.origin:set(0, 0)
	return graphic
end

local function build(state)
	local width, height = WIDTH, HEIGHT
	local group = Group()
	group.x, group.y = (game.width - width) / 2 + width / 2, 54 + height / 2
	group.visible = false

	local background = panel(width, height, Color.fromHEX(0x1A1A1A), 0.7)
	background.origin:set(width / 2, height / 2)
	local left = panel(width - OFFSET * 2, height - OFFSET * 2, Color.WHITE, 0.95)
	local right = panel(width - OFFSET * 2, height - OFFSET * 2, Color.BLACK, 1)
	left.x, left.y = -(width / 2) + OFFSET, -(height - OFFSET * 2) / 2
	right.x, right.y = left.x, left.y
	group:add(background)
	group:add(right)
	group:add(left)

	local bar = {
		bg = background, leftBar = left, rightBar = right, group = group,
		barWidth = width - OFFSET * 2, barHeight = height - OFFSET * 2,
		barOffset = Point(OFFSET, OFFSET), percent = 0, leftToRight = true, center = 0
	}
	function bar:setBounds() end
	function bar:setColors(leftColor, rightColor)
		if leftColor ~= nil then left.color = {Color.get(leftColor)} end
		if rightColor ~= nil then right.color = {Color.get(rightColor)} end
	end
	function bar:update()
		local music = game.sound and game.sound.music
		local length = music and music.duration or 0
		local position = (state.conductor and state.conductor.time or 0) / 1000
		local percent = length > 0 and math.max(0, math.min(1, position / length)) or 0
		self.percent = percent * 100
		local size = self.barWidth * (self.leftToRight and percent or 1 - percent)
		left.width, right.width = size, self.barWidth - size
		right.x = -(width / 2) + OFFSET + size
		self.center = size
		local remaining = math.max(0, math.floor(length - position))
		self.text.content = ("%d:%02d"):format(math.floor(remaining / 60), remaining % 60)
	end

	local text = Text(0, 0, "", paths.getFont("vcr.ttf", 32), Color.WHITE, "center")
	text.outline.style = "normal"
	text.outline.width = 2
	text.limit = 400
	text.x, text.y = (game.width - 400) / 2, 19
	text.alpha, text.visible = 0, false
	bar.text = text

	-- PlayState already owns a score text; only build a Psych stand-in for
	-- contexts (tests, custom states) that lack one.
	local scoreTxt = nil
	if state.scoreText == nil then
		scoreTxt = Text(0, 0, "", paths.getFont("vcr.ttf", 20), Color.WHITE, "center")
		scoreTxt.outline.style = "normal"
		scoreTxt.outline.width = 1.25
		scoreTxt.antialiasing = false
		scoreTxt.limit = game.width
	end
	local botplay = Text(400, 0, "BOTPLAY", paths.getFont("vcr.ttf", 32), Color.WHITE, "center")
	botplay.outline.style = "normal"
	botplay.outline.width = 1.25
	botplay.antialiasing = false
	botplay.limit = game.width - 800
	botplay.x = 400
	botplay.visible = state.cpuControlled == true
	local driver = {exists = true, active = true}
	function driver:update(dt)
		local shown = state.startedCountdown ~= false and not state.inCutscene
		group.visible, text.visible = shown, shown
		local health = state.healthBar
		local hudY = health and health.y or game.height * (state.downScroll and 0.1 or 0.9)
		botplay.y = (state.downScroll and hudY + 70) or (hudY - 90)
		botplay.visible = shown and state.cpuControlled == true
		if scoreTxt then
			scoreTxt.y = hudY + 40
			scoreTxt.visible = shown and ClientPrefs.data.hideHud ~= true
		end
		if shown then
			bar:update()
			if text.alpha < 1 then text.alpha = math.min(1, text.alpha + dt * 2) end
		end
	end

	if state.camHUD then
		group.cameras, text.cameras = {state.camHUD}, {state.camHUD}
		botplay.cameras = {state.camHUD}
		if scoreTxt then scoreTxt.cameras = {state.camHUD} end
	end
	state:add(group)
	state:add(text)
	state:add(botplay)
	if scoreTxt then state:add(scoreTxt) end
	state:add(driver)

	local hud = {timeBar = bar, timeTxt = text, timeBarBG = background, botplayTxt = botplay, scoreTxt = scoreTxt}
	state.psychHud = hud
	return hud
end

function Hud.timeBar(state, name)
	local hud = state.psychHud or build(state)
	return hud[name]
end

function Hud.botplayText(state)
	local hud = state.psychHud or build(state)
	return hud.botplayTxt
end

local function rating(state)
	local name = tostring(state.ratingName or "?")
	if (state.totalPlayed or 0) == 0 then return name end
	local percent = math.floor((state.ratingPercent or 0) * 10000) / 100
	return ("%s (%.2f%%) - %s"):format(name, percent, tostring(state.ratingFC or ""))
end

function Hud.scoreText(state)
	local text = state.scoreText
	if text ~= nil and text.content ~= nil then return text end
	local hud = state.psychHud or build(state)
	return hud.scoreTxt
end

function Hud.updateScoreText(state)
	if state.updateInformation then
		state:updateInformation()
		if state.scoreText ~= nil and state.scoreText.content ~= nil then return true end
	end
	local text = Hud.scoreText(state)
	if text == nil or text.content == nil then return false end
	local score, misses = math.floor(state.score or 0), math.floor(state.misses or 0)
	local label = rating(state)
	if state.instakillOnMiss then
		text.content = ("Score: %d | Rating: %s"):format(score, label)
	else
		text.content = ("Score: %d | Misses: %d | Rating: %s"):format(score, misses, label)
	end
	if state.positionText then state:positionText() end
	return true
end

return Hud
