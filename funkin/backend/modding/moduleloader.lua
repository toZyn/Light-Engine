-- Addon modules are explicit imports, scoped to one native Script. They never
-- enter package.loaded or resolve through mod/other-addon asset precedence.
local ModuleLoader = {}
ModuleLoader.__index = ModuleLoader

local function fail(message) error("[Addon modules] " .. message, 3) end
local function identifier(id)
	if type(id) ~= "string" or id == "" or id == "." or id == ".." or id:find("[/\\:%c]") then
		fail("addon identifier must be a single directory name without separators, colons or control bytes")
	end
	return id
end
local function modulePath(name)
	if type(name) ~= "string" or name == "" then fail("module name must contain identifier segments separated by dots") end
	local segments = {}
	for segment in name:gmatch("[^.]+") do
		if not segment:match("^[%a_][%w_]*$") then fail("invalid module name: " .. name) end
		segments[#segments + 1] = segment
	end
	if #segments == 0 or table.concat(segments, ".") ~= name then fail("invalid module name: " .. name) end
	return table.concat(segments, "/")
end

function ModuleLoader.resolve(addons, id, name)
	identifier(id)
	local relative = modulePath(name)
	local addon
	for _, item in ipairs(addons.all) do if item.path == id then addon = item; break end end
	if not addon then fail("addon is not installed: " .. id) end
	if not addon.active then fail("addon is disabled: " .. id) end
	local base = addons.root .. "/" .. id .. "/modules/" .. relative
	if love.filesystem.getInfo(base .. ".lua", "file") then return base .. ".lua" end
	if love.filesystem.getInfo(base .. "/init.lua", "file") then return base .. "/init.lua" end
	fail("module not found: " .. id .. "/" .. name)
end

local closedEnvironment = {
	__index = function() fail("module's parent Script is closed") end,
	__newindex = function() fail("module's parent Script is closed") end
}
local function seal(env)
	for key in pairs(env) do rawset(env, key, nil) end
	setmetatable(env, closedEnvironment)
end
local function trace(message)
	local ok, text = pcall(tostring, message)
	return debug.traceback(ok and text or "<unprintable addon module error>", 2)
end

function ModuleLoader.new(script, legacyRequire)
	return setmetatable({script = script, legacyRequire = legacyRequire, cache = {}, loading = {}, stack = {}, environments = {}, closed = false}, ModuleLoader)
end

function ModuleLoader:_active()
	if self.closed or not self.script or self.script.closed then fail("parent Script is closed") end
end

function ModuleLoader:import(id, name)
	self:_active()
	-- Check active state even on cache hits: disabling an addon blocks imports.
	local path = ModuleLoader.resolve(Addons, id, name)
	local cached = self.cache[path]
	if cached then return cached.value end
	local label = id .. "/" .. name
	if self.loading[path] then
		local chain = {}; for i, item in ipairs(self.stack) do chain[i] = item end
		chain[#chain + 1] = label
		fail("cyclic dependency: " .. table.concat(chain, " -> "))
	end
	local chunk, loadError = love.filesystem.load(path)
	if not chunk then fail("cannot load " .. label .. ": " .. tostring(loadError)) end
	local parent = self.script.variables
	local env = setmetatable({state = parent.state, script = self.script}, {
		__index = function(_, key)
			if self.closed then fail("module's parent Script is closed") end
			return parent[key]
		end
	})
	setfenv(chunk, env)
	self.environments[path], self.loading[path] = env, true
	self.stack[#self.stack + 1] = label
	local ok, exports = xpcall(chunk, trace)
	self.loading[path] = nil
	self.stack[#self.stack] = nil
	if not ok then
		self.environments[path] = nil; seal(env)
		error("[Addon modules] failed to import " .. label .. ":\n" .. exports, 0)
	end
	if self.closed or self.script.closed then
		seal(env); fail("parent Script closed during import: " .. label)
	end
	if exports == nil then exports = true end
	self.cache[path] = {value = exports, id = id, module = name}
	return exports
end

function ModuleLoader:tryImport(id, name)
	local ok, value = pcall(self.import, self, id, name)
	if ok then return value, nil end
	return nil, value
end

function ModuleLoader:getImports()
	self:_active()
	local imports = {}
	for path, entry in pairs(self.cache) do
		imports[#imports + 1] = {id = entry.id, module = entry.module, path = path}
	end
	table.sort(imports, function(a, b) return a.path < b.path end)
	return imports
end

function ModuleLoader:checkDependencies(requirements)
	self:_active()
	local issues = {}
	if type(requirements) ~= "table" then fail("dependencies must be an array of addon IDs or {id, module} records") end
	local count = 0
	for key in pairs(requirements) do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #requirements then
			fail("dependencies must be a contiguous array")
		end
		count = count + 1
	end
	if count ~= #requirements then fail("dependencies must be a contiguous array") end
	for _, requirement in ipairs(requirements) do
		local id, name = requirement, nil
		if type(requirement) == "table" then id, name = requirement.id, requirement.module end
		local ok, message = pcall(function()
			if name ~= nil then return ModuleLoader.resolve(Addons, id, name) end
			identifier(id)
			if not Addons.has(id) then fail("addon is not installed: " .. id) end
			if not Addons.has(id, true) then fail("addon is disabled: " .. id) end
		end)
		if not ok then issues[#issues + 1] = {id = id, module = name, message = message} end
	end
	if #issues > 0 then
		local messages = {"Addon dependencies unavailable:"}
		for _, issue in ipairs(issues) do messages[#messages + 1] = tostring(issue.message) end
		require("funkin.backend.recoverable-errors").report(table.concat(messages, "\n"), debug.traceback("", 2), {source = "addon-dependencies"})
	end
	return #issues == 0, issues
end

function ModuleLoader:bind()
	local loader = self
	self.script:set("requireAddon", function(id, name) return loader:import(id, name) end)
	self.script:set("tryRequireAddon", function(id, name) return loader:tryImport(id, name) end)
	self.script:set("checkAddonDependencies", function(requirements) return loader:checkDependencies(requirements) end)
	self.script:set("getAddonImports", function() return loader:getImports() end)
	self.script:set("require", function(name)
		loader:_active()
		if type(name) == "string" and name:sub(1, 6) == "addon:" then
			local id, module = name:match("^addon:([^/]+)/(.+)$")
			if not id then fail("invalid addon namespace; use addon:<id>/<dotted.module>") end
			return loader:import(id, module)
		end
		return loader.legacyRequire(name)
	end)
end

function ModuleLoader:close()
	if self.closed then return end
	self.closed = true
	for _, env in pairs(self.environments) do seal(env) end
	self.cache, self.loading, self.stack, self.environments = {}, {}, {}, {}
	self.script, self.legacyRequire = nil, nil
end

return ModuleLoader
