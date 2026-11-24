-- Runs Psych Engine's own compiled Lua layer on top of the engine's natives.
--
-- `runtime.lua` is Haxe output: it is the whole of Psych's `psychlua` package,
-- compiled by tools/build_psych_lua.py. What it does on the Lua side is call
-- `Lua_helper.add_callback(state, name, fn)` for each of its 222 callbacks, and
-- then call those functions by name when the song fires an event.
--
-- In Psych those registrations land in a LuaJIT state through linc_luajit, and
-- every value crossing the boundary is marshalled by `Convert`. Light Engine has
-- no separate Lua state to marshal into: its Haxe values are already Lua values,
-- because the engine itself runs on LuaJIT. So the boundary collapses:
--
--   * `Lua_helper.add_callback` records the function in a registry;
--   * `Convert.toLua`/`fromLua` are the identity;
--   * `Lua.getglobal` looks in that registry, `Lua.pcall` calls what it found.
--
-- What is left is the part that matters: Psych's argument handling, its
-- coercion, its callback ordering. That is the code being reused, not rewritten.
--
-- The engine's own natives arrive as `api` (see funkin/backend/scripts/compat.lua)
-- and this module only routes Psych's registrations to them.

local PsychBindings = {}

-- Registries. One table of callbacks per script, so two scripts cannot see each
-- other's functions, which is the isolation a real Lua state would give.
local registries = setmetatable({}, {__mode = "k"})

-- Values Psych pushes as globals through `set`. They behave like Lua globals, so
-- they live in a table that `Lua.getglobal` consults after the registry.
local function registryFor(state)
	local registry = registries[state]
	if registry then return registry end
	registry = {callbacks = {}, globals = {}, stack = {}}
	registries[state] = registry
	return registry
end

local function identity(value)
	return value
end

--- Builds the Lua-side `Lua_helper`, `Lua`, `LuaL` and `Convert` modules.
--
-- These are the four externs Psych's layer talks to. Everything else it calls is
-- either its own code or the engine surface bound separately.
function PsychBindings.installLuaApi(scope, onMissing)
	scope = scope or _G

	local Lua_helper = {__name__ = "Lua_helper"}
	Lua_helper.add_callback = function(state, name, callback)
		if type(name) ~= "string" then return end
		local registry = registryFor(state)
		registry.callbacks[name] = callback
	end

	local Lua = {__name__ = "Lua"}
	Lua.LUA_TNONE = -1
	Lua.LUA_TNIL = 0
	Lua.LUA_TBOOLEAN = 1
	Lua.LUA_TLIGHTUSERDATA = 2
	Lua.LUA_TNUMBER = 3
	Lua.LUA_TSTRING = 4
	Lua.LUA_TTABLE = 5
	Lua.LUA_TFUNCTION = 6
	Lua.LUA_TUSERDATA = 7
	Lua.LUA_TTHREAD = 8
	Lua.LUA_OK = 0
	Lua.LUA_YIELD = 1
	Lua.LUA_ERRRUN = 2
	Lua.LUA_ERRSYNTAX = 3
	Lua.LUA_ERRMEM = 4
	Lua.LUA_ERRERR = 5

	-- Psych's `getglobal` + `type` + `pop` + `pcall` sequence is how `call()`
	-- invokes a script callback. Rather than emulate a stack, the four calls are
	-- collapsed into the one thing the sequence means: "the function called
	-- `name`, or nil". `Lua.type` then answers for whatever was looked up, so the
	-- existing Psych branch still decides what to do about a non-function.
	Lua.getglobal = function(state, name)
		local registry = registryFor(state)
		local value = registry.callbacks[name]
		if value == nil then value = registry.globals[name] end
		registry.stack[#registry.stack + 1] = {name = name, value = value}
		return 0
	end

	Lua.type = function(state, index)
		local registry = registryFor(state)
		local entry = registry.stack[#registry.stack]
		if not entry then return Lua.LUA_TNONE end
		local value = entry.value
		if value == nil then return Lua.LUA_TNIL end
		local kind = type(value)
		if kind == "function" then return Lua.LUA_TFUNCTION end
		if kind == "string" then return Lua.LUA_TSTRING end
		if kind == "number" then return Lua.LUA_TNUMBER end
		if kind == "boolean" then return Lua.LUA_TBOOLEAN end
		if kind == "table" then return Lua.LUA_TTABLE end
		return Lua.LUA_TUSERDATA
	end

	Lua.pop = function(state, count)
		local registry = registryFor(state)
		for _ = 1, count or 1 do
			registry.stack[#registry.stack] = nil
		end
	end

	Lua.tostring = function(state, index)
		local registry = registryFor(state)
		local entry = registry.stack[#registry.stack]
		if not entry or entry.value == nil then return nil end
		return tostring(entry.value)
	end

	Lua.setglobal = function(state, name)
		local registry = registryFor(state)
		local entry = table.remove(registry.stack)
		registry.globals[name] = entry and entry.value
	end

	-- `pcall(state, nargs, nresults, errfunc)` is called right after Psych has
	-- pushed the looked-up function and its arguments. The arguments come from
	-- the caller, not the stack, because Psych already has them as Lua values.
	Lua.pcall = function(state, nargs, nresults, errfunc)
		local registry = registryFor(state)
		local entry = registry.stack[#registry.stack]
		if not entry then return Lua.LUA_ERRRUN end
		local fn = entry.value
		if type(fn) ~= "function" then return Lua.LUA_ERRRUN end
		local args = registry.pendingArgs or {}
		local results = {pcall(fn, table.unpack(args, 1, nargs or #args))}
		if not results[1] then
			registry.error = results[2]
			registry.stack[#registry.stack + 1] = {value = nil}
			return Lua.LUA_ERRRUN
		end
		registry.stack[#registry.stack + 1] = {value = results[2]}
		return Lua.LUA_OK
	end

	Lua.close = function(state)
		registries[state] = nil
	end

	Lua.luaTrace = function() end

	local LuaL = {__name__ = "LuaL"}
	LuaL.newstate = function()
		local state = {__state = true}
		registryFor(state)
		return state
	end
	LuaL.openlibs = function() end
	LuaL.dostring = function(state, source)
		local chunk, err = loadstring or load, nil
		local fn, problem
		if _VERSION == "Lua 5.1" then
			fn, problem = loadstring(source)
		else
			fn, problem = load(source, "=psych")
		end
		if not fn then
			registryFor(state).error = problem
			return Lua.LUA_ERRSYNTAX
		end
		local ok, runError = pcall(fn)
		if not ok then
			registryFor(state).error = runError
			return Lua.LUA_ERRRUN
		end
		return Lua.LUA_OK
	end
	LuaL.dofile = function(state, path)
		local handle = io and io.open and io.open(path, "r")
		if not handle then return Lua.LUA_ERRRUN end
		local source = handle:read("*a")
		handle:close()
		return LuaL.dostring(state, source)
	end
	LuaL.loadstring = LuaL.dostring
	LuaL.loadfile = LuaL.dofile

	-- Convert is the boundary marker. With no second state to cross into, the
	-- value it hands back is the one Psych already has -- but it still has to
	-- *read the stack*, because `fromLua(lua, -1)` is how Psych retrieves a
	-- callback's return value. Passing the index through unchanged returned the
	-- index itself (-1), which every callback then reported as its result.
	local Convert = {__name__ = "Convert"}
	Convert.toLua = function(_, value) return identity(value) end
	Convert.fromLua = function(state, index)
		if type(index) ~= "number" then return index end
		local registry = registryFor(state)
		local entry = registry.stack[#registry.stack]
		return entry and entry.value
	end
	Convert.cToLua = function() end

	scope.Lua_helper = Lua_helper
	scope.Lua = Lua
	scope.LuaL = LuaL
	scope.Convert = Convert

	return {
		Lua_helper = Lua_helper, Lua = Lua, LuaL = LuaL, Convert = Convert,
		registryFor = registryFor,
	}
end

--- Loads Psych's compiled layer and returns its factory.
--
-- The generated file is a Lua port of Psych's entire `psychlua` package. It
-- assigns two globals: `lightPsychInstall(host)` for the 94 callbacks in the
-- helper classes, and `lightPsychCreateScript(source)` for the other 128 plus
-- the actual script run.
--
-- Loading is lazy and once per process: the chunk is ~6,300 lines of table
-- construction and there is no reason to pay for it twice or for a session that
-- never plays a Psych mod.
local loaded

function PsychBindings.loadShim(compat)
	if loaded then return loaded end

	local source = compat and compat.psychShimSource or nil
	if not source then
		-- Same loader the engine uses for its own compiled runtime, so a packaged
		-- build and a source checkout both find the file.
		local path = "funkin/backend/scripts/psych/shim.lua"
		local chunkLoader = love and love.filesystem and love.filesystem.load
		if chunkLoader then
			local chunk = chunkLoader(path)
			if not chunk then
				loaded = false
				return nil
			end
			return PsychBindings.runShim(compat, chunk)
		end
		local handle = io and io.open and io.open(path, "r")
		if not handle then
			loaded = false
			return nil
		end
		source = handle:read("*a")
		handle:close()
	end
	return PsychBindings.runShim(compat, source)
end

--- Runs an already-obtained shim chunk or source and returns its entry points.
function PsychBindings.runShim(compat, chunkOrSource)
	if loaded then return loaded end
	local source = chunkOrSource

	-- The shim gets its own environment, the way the engine runs a script: what
	-- it assigns stays local to it, everything else falls through to the real
	-- globals. Without the fallback `setmetatable` is nil and the compiled
	-- layer dies on its first line.
	local scope = setmetatable({}, {__index = _G})
	scope._G = scope
	PsychBindings.installLuaApi(scope)

	local chunk = source
	if type(source) == "string" then
		chunk = loadstring and loadstring(source) or load(source, "=psych-shim")
	end
	if not chunk then
		loaded = false
		return nil
	end
	if setfenv then setfenv(chunk, scope) end

	local ok, err = pcall(chunk)
	if not ok then
		loaded = false
		if compat and compat.psychWarn then
			compat:psychWarn("Psych shim failed to load: " .. tostring(err))
		end
		return nil
	end

	loaded = {
		install = scope.lightPsychInstall,
		createScript = scope.lightPsychCreateScript,
		scope = scope,
	}
	return loaded
end

--- Runs `source` as a Psych script.
--
-- Returns the script object on success. The caller owns it and must keep it
-- alive: the 128 callbacks registered during construction live on it.
function PsychBindings.runScript(compat, source)
	local shim = PsychBindings.loadShim(compat)
	if not shim or not shim.createScript then
		return nil, "Psych shim unavailable"
	end
	local ok, script = pcall(shim.createScript, source)
	if not ok then
		return nil, tostring(script)
	end
	if script == nil then
		return nil, "Psych script did not build"
	end
	return script
end


return PsychBindings
