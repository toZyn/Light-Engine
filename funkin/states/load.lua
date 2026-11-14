local LoadScreen = require "funkin.ui.loadscreen"
local LoadState = State:extend("LoadState")

function LoadState:new(state)
	LoadState.super.new(self)
	self.nextState = state
	self.persistCache = true
end

function LoadState:enter()
	self.notCreated = false

	self.script = Script("data/states/load", false)
	local event = self.script:call("create")
	if event == Script.Event_Cancel then
		LoadState.super.enter(self)
		self.notCreated = true
		self.script:call("postCreate")
		return
	end

	self.skipTransIn, self.skipTransOut = true, true
	self.load = LoadScreen(self.nextState)
	self:add(self.load)

	LoadState.super.enter(self)

	if game.sound.music then
		game.sound.music:fade(0.66, ClientPrefs.data.menuMusicVolume / 100, 0)
	end
	self.script:call("postCreate")
end

function LoadState:update(dt)
	self.script:call("update", dt)
	if self.notCreated then
		LoadState.super.update(self, dt)
		self.script:call("postUpdate", dt)
		return
	end

	if self.load:isReady() and not self._loaded then
		self._loaded = true
  self.load:handoff(self)
		if game.sound.music then
			game.sound.music:cancelFade()
		end
		game.switchState(self.nextState)
	end
	LoadState.super.update(self, dt)
	self.script:call("postUpdate", dt)
end

function LoadState:resize()
 if self.load then self.load:resize() end
end

function LoadState:leave()
 if self.load and not self._loaded then self.load:cancel();paths.async.stop() end
	self.script:call("leave")
	if self.notCreated then
		self.script:call("postLeave")
		return
	end

	self.script:call("postLeave")
	self.script:close()
end

return LoadState
