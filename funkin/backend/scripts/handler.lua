local ScriptsHandler = Classic:extend("ScriptsHandler")

local function call(script, name, ...)
	local bridge = script._psych
	if not bridge then return script:call(name, ...) end
	if bridge.disposed then return end
	if name == "update" then return bridge:update(...) end
	if name == "onEvent" then return bridge:forward("event", ...) end
	if bridge.callbackNames[name] then return bridge:forward(name, ...) end
	if name == "leave" then return script:call("onDestroy") end
	if name == "pause" then return script:call("onPause") end
	if name == "startCountdown" then return script:call("onStartCountdown") end
	if name == "postGoodNoteHit" or name == "postNoteMiss" then
		local note = ...
		local callback = name == "postNoteMiss" and "noteMiss"
			or note.parent == bridge.state.playerNotefield and "goodNoteHit" or "opponentNoteHit"
		if not script:hasCallback(callback) then return end
		if script.hscriptCall then
			local proxy = require("funkin.backend.scripts.psych").note(note, bridge.state.playerNotefield)
			return script:call(callback, proxy)
		end
		local index = table.find(note.parent.activeNotes, note)
		return script:call(callback, index and index - 1 or -1, note.direction, note.type or "", false)
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
		if retScript == Script.Event_Cancel then
			retValue = Script.Event_Cancel
		end
	end
	return retValue
end

function ScriptsHandler:event(func, event)
	if not self.scripts then return event end
	for _, script in ipairs(self.scripts) do
		if not script._psych then script:call(func, event) end
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
