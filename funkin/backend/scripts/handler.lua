local ScriptsHandler = Classic:extend("ScriptsHandler")

local function syncGlobals(script, state, name)
	local conductor = state.conductor
	if conductor then
		script:set("bpm", state.SONG and state.SONG.bpm or conductor.bpm)
		script:set("curBpm", conductor.bpm)
		script:set("curDecStep", conductor.step.f)
		script:set("curDecBeat", conductor.beat.f)
		script:set("crochet", conductor.crotchet)
		script:set("stepCrochet", conductor.stepCrotchet)
	end
	script:set("songLength", (game.sound.music and game.sound.music.duration or 0) * 1000)
	script:set("curStep", conductor and conductor.step.i or 0)
	script:set("curBeat", conductor and conductor.beat.i or 0)
	local sectionIndex = state.psychSectionIndex or 1
	local section = state.psychSections and state.psychSections[sectionIndex]
	script:set("curSection", sectionIndex - 1)
	script:set("mustHitSection", section and section.mustHitSection or false)
	script:set("altAnim", section and section.altAnim or false)
	script:set("gfSection", section and section.gfSection or false)
	script:set("playbackRate", state.playback or 1)
	script:set("botPlay", state.cpuControlled == true)
	script:set("inGameOver", state.isDead == true)

	if name == "countdownStarted" then
		for label, group in pairs({Player = "playerStrums", Opponent = "opponentStrums"}) do
			local get = script._psych.installed.getPropertyFromGroup
			for index = 0, 3 do
				script:set("default" .. label .. "StrumX" .. index, get(group, index, "x") or 0)
				script:set("default" .. label .. "StrumY" .. index, get(group, index, "y") or 0)
			end
		end
	end
end

local function call(script, name, ...)
	local bridge = script._psych
	if not bridge then return script:call(name, ...) end
	if bridge.disposed then return end
	if name == "update" or name == "postUpdate" or name == "create" or name == "postCreate" or name == "countdownStarted" or name == "beat" or name == "step" or name == "section" then
		syncGlobals(script, bridge.state, name)
	end
	if name == "create" then
		if script._psychCreateCalled then return end
		script._psychCreateCalled = true
	end
	if name == "update" then return bridge:update(...) end
	if name == "section" then return script:call("onSectionHit") end
	if name == "onEvent" then return bridge:forward("event", ...) end
	if name:sub(1, 16) == "onCustomSubstate" or name == "onNextDialogue" or name == "onSkipDialogue" then
		return script:call(name, ...)
	end
	if bridge.callbackNames[name] then return bridge:forward(name, ...) end
	if name == "leave" then return script:call("onDestroy") end
	if name == "pause" then return script:call("onPause") end
	if name == "startCountdown" then return script:call("onStartCountdown") end
	if name == "countdownStarted" then return script:call("onCountdownStarted") end
	if name == "countdownTick" then
		local tick = ...
		if script.hscriptCall then
			return script:call("onCountdownTick", tick, tick)
		end
		return script:call("onCountdownTick", tick)
	end
	if name == "postSubstateClosed" then return script:call("onResume") end
	if name == "gameOverConfirm" or name == "gameOverQuit" then
		return script:call("onGameOverConfirm", name == "gameOverConfirm")
	end
	if name == "gameOverStart" then return script:call("onGameOverStart") end
	if name == "cameraFocus" then return script:call("onMoveCamera", ...) end
	if name == "measure" then return script:call("onSectionHit") end
	if name == "keyPressPre" then return script:call("onKeyPressPre", ...) end
	if name == "keyReleasePre" then return script:call("onKeyReleasePre", ...) end
	if name == "keyPressPost" then return script:call("onKeyPress", ...) end
	if name == "keyReleasePost" then return script:call("onKeyRelease", ...) end
	if name == "ghostTap" then return script:call("onGhostTap", ...) end
	if name == "preUpdateScore" or name == "onUpdateScore" or name == "onRecalculateRating" then
		if script:hasCallback(name) then
			syncGlobals(script, bridge.state, name)
			return script:call(name, ...)
		end
		return
	end
	if name == "postMiss" then return script:call("noteMissPress", ...) end
	if name == "postGoodNoteHit" or name == "postNoteMiss" or name == "noteSpawn" then
		local note, _, completed = ...
		if completed == false then return end
		local callback = name == "noteSpawn" and "onSpawnNote" or name == "postNoteMiss" and "noteMiss"
			or note.parent == bridge.state.playerNotefield and "goodNoteHit" or "opponentNoteHit"
		if not script:hasCallback(callback) then return end
		if script.hscriptCall then
			local proxy = require("funkin.backend.scripts.psych").note(note, bridge.state.playerNotefield, bridge.state)
			return script:call(callback, proxy)
		end
		local index = bridge.psychNoteIndex(note)
		if name == "noteSpawn" then
			return script:call(callback, index, note.direction, note.type or "", false, note.time * 1000)
		end
		return script:call(callback, index, note.direction, note.type or "", false)
	end
end

function ScriptsHandler:new(link)
	self.scripts = {}
	self.variables = {}
end

function ScriptsHandler:loadScript(file) self:add(Script(file)) end

function ScriptsHandler:add(script)
	if not self.scripts then return end
	if self.variables then
		for k, v in pairs(self.variables) do
			script:set(k, v)
		end
	end
	table.insert(self.scripts, script)
end

function ScriptsHandler:remove(script)
	if not self.scripts then return end
	table.delete(self.scripts, script)
end

function ScriptsHandler:loadDirectory(...)
	if not self.scripts then return end
	for _, dir in ipairs({...}) do
		for _, file in ipairs(paths.getItems(dir, "file", "lua")) do
			self:loadScript(dir .. "/" .. file:withoutExt())
		end
	end
end

function ScriptsHandler:call(func, ...)
	local retValue = Script.Event_Continue
	if not self.scripts then return retValue end
	for _, script in ipairs(self.scripts) do
		local retScript = call(script, func, ...)
		if retScript == Script.Event_Cancel or (script._psych and retScript == '##PSYCHLUA_FUNCTIONSTOP') then
			retValue = Script.Event_Cancel
		end
	end
	return retValue
end

function ScriptsHandler:preparePsychEvent(event)
	local value1, value2 = event.v, nil
	if type(event.v) == "table" then value1, value2 = event.v[1], event.v[2] end
	local offset
	for _, script in ipairs(self.scripts) do
		if script._psych then
			script:call("onEventPushed", event.e, value1 or "", value2 or "", event.t)
			if not offset then
				local result = script:call("eventEarlyTrigger", event.e, value1 or "", value2 or "", event.t)
				if type(result) == "number" and result == result and math.abs(result) < math.huge and result ~= 0 then
					offset = result
				end
			end
		end
	end
	if offset then event.t = event.t - offset end
	return offset ~= nil
end

function ScriptsHandler:event(func, event)
	if not self.scripts then return event end
	for _, script in ipairs(self.scripts) do
		if not script._psych then
			script:call(func, event)
		elseif func == "onGameOver" then
			local result = script:call('onGameOver')
			if result == Script.Event_Cancel or result == '##PSYCHLUA_FUNCTIONSTOP' then event:cancel(false) end
		elseif func == "onNoteHit" then
			local bridge, note = script._psych, event.note
			local name = note.parent == bridge.state.playerNotefield and "goodNoteHitPre" or "opponentNoteHitPre"
			if script:hasCallback(name) then
				local result
				if script.hscriptCall then
					result = script:call(name, require("funkin.backend.scripts.psych").note(note, bridge.state.playerNotefield, bridge.state))
				else
					result = script:call(name, bridge.psychNoteIndex(note), note.direction, note.type or "", false)
				end
				if result == Script.Event_Cancel or result == '##PSYCHLUA_FUNCTIONSTOP' then event:cancel(false) end
			end
		end
		if event.cancelled and not event.__continueCalls then break end
	end
	return event
end

function ScriptsHandler:set(variable, value)
	if not self.scripts or not self.variables then return end
	self.variables[variable] = value
	for _, script in ipairs(self.scripts) do
		script:set(variable, value)
	end
end

function ScriptsHandler:close()
	if not self.scripts then return end
	for _, script in ipairs(self.scripts) do
		script:close()
	end
	self.scripts = nil
	self.variables = nil
end

return ScriptsHandler
