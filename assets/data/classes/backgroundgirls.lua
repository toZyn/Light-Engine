local BackgroundGirls = Sprite:extend("BackgroundGirls")

function BackgroundGirls:new(x, y, isPissed)
	BackgroundGirls.super.new(self, x, y)

	self:setFrames(paths.getSparrowAtlas('stages/school/bgFreaks'))
	if isPissed then
		self.animation:addByIndices('danceLeft', 'BG fangirls dissuaded', {
			0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
		}, nil, 24, false)
		self.animation:addByIndices('danceRight', 'BG fangirls dissuaded', {
			15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30
		}, nil, 24, false)
	else
		self.animation:addByIndices('danceLeft', 'BG girls group', {
			0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
		}, nil, 24, false)
		self.animation:addByIndices('danceRight', 'BG girls group', {
			15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30
		}, nil, 24, false)
	end

	self:dance()
	self.animation:finish()
end

BackgroundGirls.danceDir = false
function BackgroundGirls:dance()
	self.danceDir = not self.danceDir
	if self.danceDir then
		self.animation:play('danceRight', true)
	else
		self.animation:play('danceLeft', true)
	end
end

return BackgroundGirls
