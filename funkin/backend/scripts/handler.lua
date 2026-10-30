local ScriptsHandler = Classic:extend("ScriptsHandler")

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
		local retScript = script:call(func, ...)
		if retScript == Script.Event_Cancel then
			retValue = Script.Event_Cancel
		end
	end
	return retValue
end

function ScriptsHandler:event(func, event)
	if not self.scripts then return event end
	for _, script in ipairs(self.scripts) do
		script:call(func, event)
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
