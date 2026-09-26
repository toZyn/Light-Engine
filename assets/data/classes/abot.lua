local ABot = Group:extend("ABot")

local Visualizer = SpriteGroup:extend("Visualizer")

function Visualizer:new(x, y, fftInstance, spacing)
	Visualizer.super.new(self, x, y)

	self.fft = fftInstance
	self.barCount = 7
	self.time = 0
	self.slideOffset = 0

	local frames = paths.getSparrowAtlas("characters/abot/aBotViz")
	local positionX = {0, 59, 56, 66, 54, 52, 51}
	local positionY = {0, -8, -3.5, -0.4, 0.5, 4.7, 7}

	for i = 1, self.barCount do
		local posX = 0
		local posY = 0
		for j = 1, i do
			posX = posX + positionX[j]
			posY = posY + positionY[j]
		end

		local sprite = Sprite(posX, posY)
		sprite:setFrames(frames)
		sprite.animation:addByPrefix("VIZ", "viz" .. i .. "0", 0)
		sprite.animation:play("VIZ")
		self:add(sprite)
	end
end

function Visualizer:__render(c)
	Visualizer.super.__render(self, c)
	local bars = self.fft:getBars(true)
	for i = 1, 7 do
		local member = self.members[i]

		local bar = bars[i]
		member.alpha = bar > 0 and 1 or 0.000001
		local animFrame = 0

		if game.sound.__volume > 0 and not game.sound.__muted then
			animFrame = math.floor(bar * 6) + 1
		end

		animFrame = animFrame - 1
		animFrame = math.max(1, math.min(7, animFrame))
		animFrame = math.abs(animFrame - 7)

		if member.animation and member.animation.curAnim then
			member.animation.curAnim.frame = animFrame
		end
	end
	
	
end

function ABot:new(x, y)
	ABot.super.new(self)
	self.eyeWhites = Graphic(x + 50, y + 240, 160, 60)
	self.eyeWhites.color = Color.WHITE -- duh !!!!
	self:add(self.eyeWhites)
	self.stereoBG = Sprite(x + 160, y + 30, paths.getImage('characters/abot/stereoBG'))
	self:add(self.stereoBG)

	local path = "songs/" .. paths.formatToSongPath(PlayState.SONG.song) .. "/Inst.ogg"
	local fft = FFT(7, path, game.sound.music._source)
	fft.fftSize = 256
	self.visualizer = Visualizer(x + 200, y + 80, fft)
	self:add(self.visualizer)
	self.fft = fft

	self.pupil = AnimateAtlas(x + 55, y + 235, paths.getAnimateAtlas("characters/abot/systemEyes"))
	local lf = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}
	local rg = {17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36}
	self.pupil.animation:addByIndices("pupilLeft", '', lf, 24)
	self.pupil.animation:addByIndices("pupilRight", '', rg, 24)
	self.pupil.animation:play("pupilLeft")
	self:add(self.pupil)

	self.abot = AnimateAtlas(x, y, paths.getAnimateAtlas("characters/abot/abotSystem"))
	self.abot.animation:add("beat", "", 24, false)
	self.abot.animation:play("beat")
	self:add(self.abot)
end

function ABot:update(dt)
	ABot.super.update(self, dt)
	self.fft:update(dt)
end

function ABot:setEyeDirection(n)
	if n == 1 and self.abot.animation.curAnim.name ~= "pupilRight" then
		return self.pupil.animation:play("pupilRight")
	elseif self.pupil.animation.curAnim.name ~= "pupilLeft" then
		return self.pupil.animation:play("pupilLeft")
	end
end

function ABot:beat()
	self.abot.animation:play("beat", true)
end

function ABot:destroy()
	ABot.super.destroy(self)
end

return ABot