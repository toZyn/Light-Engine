local ABot, abot = require "abot"
local lowHealth, raisedKnife, loweredKnife = false, false, true

function postCreate()
	abot = ABot(self.x, self.y + 100)
	-- characters arent spritegroups so we add on the stage instead
	state.stage:insert(state.stage:indexOf(self), abot)

	self.x = self.x + 150
	self.y = self.y - 208
end

function onEvent(e)
	if not abot then return end
	if e.e == "FocusCamera" then
		local isTable = _G.type(e.v) == "table"
		local n = isTable and e.v.char or tonumber(e.v)
		switch(n, {
			[0] = function() abot:setEyeDirection(1) end,
			[1] = function() abot:setEyeDirection(0) end,
		})
	end
end

function postUpdate(dt)
	if state.health <= 0.2 and not raisedKnife then
		playAnim("raiseKnife", nil, nil, true)
		lowHealth, raisedKnife, loweredKnife = true, true, false
	elseif state.health > 0.2 and not loweredKnife then
		lowHealth, raisedKnife, loweredKnife = false, false, true
		playAnim("lowerKnife", nil, nil, true)
		self.danced = true
	end
end

function postBeat()
	if not abot then return end
	abot:beat()
end

function postMeasure(m)
	if m % 2 == 0 then
		if self.anim.curAnim.name == "raiseKnife-loop" then
			self.anim:play("raiseKnife-loop", true)
			self.danced = false
		end
	end
end

function onPlayAnim()
	if lowHealth then return Event_Cancel end
end


function postAnimFinish(name)
	if name == "lowerKnife" then dance() end
end

function draw()
	if not abot then return end
	abot.color, abot.alpha, abot.visible, abot.shader =
		color, alpha, visible, shader
end

