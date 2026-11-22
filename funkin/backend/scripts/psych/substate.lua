local CustomSubstate = {}

function CustomSubstate.install(compat, api)
	local state = compat.state
	local function active()
		local substate = state.substate
		if substate and substate.psychName and not substate.psychClosing then return substate end
	end

	local function callback(substate, name, ...)
		if state.scripts then state.scripts:call(name, substate.psychName, ...) end
	end

	api.openCustomSubstate = function(name, pauseGame)
		compat:_active()
		if state.substate then return false end
		assert(type(name) == "string" and name ~= "", "Expected a Psych substate name")
		local substate = Substate()
		substate.psychName = name
		substate.cameras = state.camOther and {state.camOther} or nil
		substate.psychObjects = {}
		local update, enter = substate.update, substate.enter
		local oldUpdate, oldDraw = state.persistentUpdate, state.persistentDraw
		local paused = pauseGame == true and not state.paused
		state.persistentUpdate, state.persistentDraw = not pauseGame, true
		if paused then state:pauseSong() end

		function substate:enter(...)
			callback(self, "onCustomSubstateCreate")
			if not self.psychClosing then
				enter(self, ...)
				callback(self, "onCustomSubstateCreatePost")
			end
		end
		function substate:update(dt)
			callback(self, "onCustomSubstateUpdate", dt)
			if not self.psychClosing then update(self, dt) end
			if not self.psychClosing then callback(self, "onCustomSubstateUpdatePost", dt) end
		end
		function substate:leave()
			self.psychClosing = true
			callback(self, "onCustomSubstateDestroy")
			for object in pairs(self.psychObjects) do self:remove(object) end
			self.psychObjects = {}
			state.persistentUpdate, state.persistentDraw = oldUpdate, oldDraw
			if paused and not state.startingSong then state:playSong() end
		end

		state:openSubstate(substate)
		return true
	end

	api.closeCustomSubstate = function()
		compat:_active()
		local substate = active()
		if not substate then return false end
		substate.psychClosing = true
		State.closeSubstate(state)
		return true
	end

	api.insertToCustomSubstate = function(tag, pos)
		compat:_active()
		local substate = active()
		local object = compat.objects[tag]
		if not substate or not object then return false end
		if substate.psychObjects[object] then substate:remove(object) end
		if compat.added[tag] then state:remove(object); compat.added[tag] = nil end
		local size = #substate.members
		if pos == nil or pos < 0 then substate:add(object)
		else substate:insert(math.min(math.floor(pos), size) + 1, object) end
		substate.psychObjects[object] = true
		return true
	end

	local remove = compat._remove
	compat._remove = function(self, tag, destroy)
		local substate = state.substate
		local object = self.objects[tag]
		if substate and substate.psychObjects and substate.psychObjects[object] then
			substate.psychObjects[object] = nil
			substate:remove(object)
		end
		return remove(self, tag, destroy)
	end
end

return CustomSubstate
