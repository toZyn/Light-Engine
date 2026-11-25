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
--   * `Convert.toLua` pushes, `Convert.fromLua` reads back the top of the stack;
--   * `Lua.getglobal` looks in that registry, `Lua.pcall` calls what it found.
--
-- What is left is the part that matters: Psych's argument handling, its
-- coercion, its callback ordering. That is the code being reused, not rewritten.
--
-- The engine's own natives arrive as `api` (see funkin/backend/scripts/compat.lua)
-- and this module only routes Psych's registrations to them.

local PsychBindings = {}

-- Which state the MusicBeatState store currently points at, and how to ask for the
-- current one. A connection is made before a state exists, so the store cannot be
-- bound at connection time; it binds when first used.
local storeOwner
local compatState

-- Registries. One table of callbacks per script, so two scripts cannot see each
-- other's functions, which is the isolation a real Lua state would give.
local registries = setmetatable({}, {__mode = "k"})

-- Values Psych pushes as globals through `set`. They behave like Lua globals, so
-- they live in a table that `Lua.getglobal` consults after the registry.
local function registryFor(state)
	-- A nil state means the caller passed a host without a Lua handle. Left to
	-- itself, `registries[nil] = registry` raises "table index is nil" with no
	-- mention of which callback or which script did it.
	assert(state ~= nil, "Psych registry: no Lua state (a callback was registered without one)")
	local registry = registries[state]
	if registry then return registry end
	-- `globals` is the script's environment, not a side table. In Psych the
	-- script's own `function onCreate()` and Psych's `set('curBeat', 4)` share one
	-- Lua state, so a script can read what Psych set and Psych can call what the
	-- script defined. One table with a fallback to the real globals reproduces it.
	--
	-- `callbacks` and `globals` are two views of that one table, because they are
	-- two views in Psych too: `Lua_helper.add_callback(lua, "setVar", fn)` makes
	-- setVar a global the script calls, and `set(name, value)` does the same. Keeping
	-- them apart left every one of Psych's 222 functions registered but invisible to
	-- the mod -- a script that loads, runs, and calls nil.
	local env = setmetatable({}, {__index = _G})
	registry = {
		callbacks = env,
		globals = env,
		stack = {},
	}
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
-- One module for every scope: the shim reads globals through the same object the
-- engine does, so there is one stack and one registry, not one per environment.
local Lua

function PsychBindings.installLuaApi(scope, onMissing)
	scope = scope or _G

	local Lua_helper = {__name__ = "Lua_helper"}
	Lua_helper.add_callback = function(state, name, callback)
		if type(name) ~= "string" then return end
		local registry = registryFor(state)
		registry.callbacks[name] = callback
	end

	Lua = {__name__ = "Lua"}
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

	-- The value `Lua.getglobal` just pushed, without the stack dance. A host
	-- inspecting a script -- what scriptName was set to, what a callback wrote --
	-- has no C stack to consult, and faking the sequence is how it first read 0
	-- for every global.
	Lua.readglobal = function(state, name)
		local registry = registryFor(state)
		local value = registry.callbacks[name]
		if value == nil then value = registry.globals[name] end
		return value
	end

	-- The last error this script raised, or nil.
	--
	-- Psych reports a failed callback through `luaTrace`, which does nothing unless
	-- the mod turns on `luaDebugMode`. A mod whose callback throws therefore fails
	-- completely silently: no trace, no debug text, nothing. The engine needs to be
	-- able to log that -- and to a person debugging a mod, this is the whole story.
	Lua.readerror = function(state)
		local registry = registryFor(state)
		local value = registry.error
		registry.error = nil
		return value
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
		if not entry or entry.value == nil then
			-- A failed call leaves a nil on the stack and the message in the
			-- registry; this is the call that is supposed to print that message.
			if registry.error then return tostring(registry.error) end
			return nil
		end
		-- A status code is not the value that was asked about. Psych prints whatever
		-- comes back as the error when loading fails, so answering with the status
		-- made every load failure report itself as a number and nothing else. The
		-- real message is in the registry.
		if type(index) == "number" and index ~= -1 and type(entry.value) == "number" then
			if registry.error then return tostring(registry.error) end
			return nil
		end
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
		local count = (nargs or 0) + 1
		local stack = registry.stack
		-- Psych calls this after pushing the function and then each argument, so the
		-- frame is the last nargs+1 entries: the function first, then its arguments.
		-- Reading the top of the stack as the function is what made every call pass
		-- the last argument as the callee.
		if #stack < count then return Lua.LUA_ERRRUN end
		local frame = {}
		for index = #stack - count + 1, #stack do frame[#frame + 1] = stack[index] end
		for _ = 1, count do stack[#stack] = nil end
		local fn = frame[1] and frame[1].value
		if type(fn) ~= "function" then return Lua.LUA_ERRRUN end
		local args = {}
		for index = 2, #frame do args[#args + 1] = frame[index].value end
		-- LuaJIT has `unpack`; 5.2+ moved it onto `table`.
		local expand = unpack or rawget(table, "unpack")
		local results = {pcall(fn, expand(args, 1, #args))}
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
		local env = registryFor(state).globals
		local fn, problem
		if loadstring then
			fn, problem = loadstring(source)
			if fn and setfenv then setfenv(fn, env) end
		else
			fn, problem = load(source, "=psych", "t", env)
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
		-- A mod's scripts live in the game's filesystem -- a mounted archive in a
		-- packaged build, the save directory when a mod is installed at runtime.
		-- `io.open` only sees the real disk, so reading through LÖVE first is what
		-- makes a mod script load at all outside a source checkout.
		local source
		if love and love.filesystem and love.filesystem.read then
			source = love.filesystem.read(path)
		end
		if not source then
			local handle = io and io.open and io.open(path, "r")
			if not handle then
				registryFor(state).error = "could not read script: " .. tostring(path)
				return Lua.LUA_ERRRUN
			end
			source = handle:read("*a")
			handle:close()
		end
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
	-- `toLua` is Psych's "push this value for the following Lua call". `set()` is
	-- `Convert.toLua(lua, data); Lua.setglobal(lua, name);`, so a toLua that only
	-- returned its argument left the stack empty and setglobal stored nil -- every
	-- global the constructor and every setVar went in as nil, silently.
	Convert.toLua = function(state, value)
		local registry = registryFor(state)
		registry.stack[#registry.stack + 1] = {value = value}
		return value
	end
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
	if not source and compat and compat.psychShimSourceFor then
		-- Ask once. The retry below reloads with this source, and that reload must
		-- not ask again: it did, and the loader recursed until it ran out of stack.
		source = compat.psychShimSourceFor()
		if source then compat.psychShimSource = source end
	end
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
	-- One table stands in for the globals, for every environment involved.
	--
	-- The compiled layer assigns its entry points through `_G`, and Haxe output
	-- defines each function in whatever environment its chunk was loaded with.
	-- Those two do not have to agree, and when they did not, the exports were
	-- stored in the scope but executed against the real globals, where `LuaL`
	-- does not exist. Sharing a single globals table removes the question:
	-- assignments, lookups and definitions all resolve to the same place,
	-- without relying on setfenv (which Lua 5.2+ lacks) to arrange it.
	local shared = setmetatable({}, {__index = _G})
	local scope = setmetatable({}, {__index = shared})
	scope._G = shared
	PsychBindings.installLuaApi(shared)
	PsychBindings.installLuaApi(scope)

	-- Haxe resolves `psychlua.HScript.implement(...)` through a package table that
	-- its runtime builds. The compiled output here registers classes only in its own
	-- local `_hxClasses`, so the package does not exist and the constructor dies on
	-- its last few lines -- after doing all of its real work.
	--
	-- It has to exist before the chunk runs: the shim resolves the package while it
	-- defines those classes, not when it calls them.
	shared.psychlua = setmetatable({}, {
		__index = function(_, name)
			local classes = shared._hxClasses
			if type(classes) == "table" then
				return classes["psychlua." .. name]
			end
			return nil
		end,
	})

	local chunk = source
	if type(source) == "string" then
		-- LuaJIT and 5.1 take the environment afterwards via setfenv; 5.2+ takes it
		-- as load's fourth argument. Passing it here matters: a plain `load` runs
		-- the chunk against the real globals, where the shim's own `LuaL` lookup
		-- finds nothing and Psych's constructor dies on its first line.
		if loadstring then
			chunk = loadstring(source)
		else
			chunk = load(source, "=psych-shim", "t", scope)
		end
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
		-- Not memoised: a load that failed for want of the engine's globals should
		-- be retried once those exist, instead of latching the failure per process.
		return nil
	end

	-- Two of the modules Psych's constructor calls were not part of the compile:
	-- `psychlua.HScript` (runHaxeCode / runHaxeFunction) and `psychlua.CustomSubstate`
	-- (mod-defined substates). Python's MODULES list in tools/build_psych_lua.py
	-- leaves them out because they are a different feature, not because they are
	-- small, but the constructor calls `implement` on both unconditionally.
	--
	-- Providing an `implement` that registers nothing keeps the constructor working
	-- for mods that never touch those features, and leaves a mod that does use them
	-- failing on the function's own name -- `runHaxeCode` is nil -- instead of on a
	-- package that does not exist. Implementing them is separate work, not a gap in
	-- this path.
	local function unsupportedModule(name)
		return {
			implement = function() end,
			__lightEngineUnsupported = name,
		}
	end
	for _, entry in ipairs({ { "HScript", "runHaxeCode / runHaxeFunction" },
		{ "CustomSubstate", "mod-defined substates" } }) do
		local package = shared.psychlua
		local seen = type(package) == "table" and package[entry[1]]
		if seen == nil then
			shared.psychlua[entry[1]] = unsupportedModule(entry[2])
			if entry[1] == "CustomSubstate" then
				shared.CustomSubstate = shared.psychlua.CustomSubstate
			end
		end
	end

	-- A load that failed for want of the engine globals is retried once the host
	-- can supply the compiled source. Guarded by a flag rather than by "no source
	-- yet", which is true on exactly the retry as well.
	if compat and compat.psychShimSourceFor and not compat.psychShimRetried then
		compat.psychShimRetried = true
		local retry = compat.psychShimSourceFor()
		if retry then
			return PsychBindings.runShim(compat, retry)
		end
	end

	-- `cast value:String` in Haxe turns a number into its string form, so
	-- `argStr.length > n` is false for a non-string and the value is returned
	-- untouched. The compiled output keeps the number and takes `#argStr`, which
	-- raises in Lua -- so `setVar('beats', 1)` failed before storing anything and
	-- every numeric variable a mod published was lost, while string values worked.
	--
	-- Applied after the chunk has run, because the function does not exist before
	-- it defines itself. It is in the chunk's own environment: a global assignment in
	-- the compiled code lands in the scope it was loaded with, not in `shared`.
	local reflection = rawget(scope, "__psychlua_ReflectionFunctions")
		or rawget(shared, "__psychlua_ReflectionFunctions")
	if type(reflection) == "table" and type(reflection.parseSingleInstance) == "function" then
		local parse = reflection.parseSingleInstance
		reflection.parseSingleInstance = function(value)
			local kind = type(value)
			if kind ~= "string" and kind ~= "table" then return value end
			return parse(value)
		end
	end

	loaded = {
		install = scope.lightPsychInstall,
		createScript = scope.lightPsychCreateScript,
		scope = scope,
		-- The compiled layer registers through `Lua_helper` in the shared globals,
		-- so that is where a caller finds the callbacks Psych registered.
		bridge = PsychBindings.installLuaApi(scope),
		globals = shared,
	}

	-- The shim's own state factory. Psych asks `LuaL.newstate()` in the shared
	-- globals; going through it here keeps the caller and the compiled layer on
	-- the same implementation, including when the globals have been swapped.
	function loaded.state()
		return shared.LuaL.newstate()
	end
	return loaded
end

--- Makes `script.variables` see what the mod's own script defined.
--
-- A compiled Psych script runs in its own environment: `created = true` inside
-- onCreate lands there, not in `script.variables`. The engine reads `variables`
-- (hasCallback, the script harness, the event-prep code), so a callback that ran was
-- invisible -- indistinguishable from one that never ran.
--
-- Read-through only: assigning to `variables` still writes to `variables`, because
-- that is how the compatibility layer publishes globals into a script.
function PsychBindings.bindVariables(script, luaState)
	if type(script) ~= "table" or script.variables == nil or luaState == nil then return end
	local registry = registryFor(luaState)
	local variables = script.variables
	local previous = getmetatable(variables)
	if previous and previous.__psychBound == registry.globals then return end
	setmetatable(variables, {
		__psychBound = registry.globals,
		__index = function(_, key)
			local value = registry.globals[key]
			if value ~= nil then return value end
			if previous and previous.__index then
				if type(previous.__index) == "table" then return previous.__index[key] end
				return previous.__index(variables, key)
			end
			return nil
		end,
		__newindex = previous and previous.__newindex or nil,
	})
end

--- Copies what a mod's script defined back into `script.variables`.
--
-- The read-through in bindVariables covers keys that were never set on `variables`,
-- but anything the compatibility layer already published is set there and would
-- shadow the script's own value -- a mod that wrote `countdownCounter` in a callback
-- stayed invisible behind the initial snapshot. The engine calls sync after each
-- callback, which is exactly when the script's values are new.
function PsychBindings.syncVariables(script)
	if type(script) ~= "table" or script.variables == nil then return end
	local luaState = script.psychScript and script.psychScript.lua
	if luaState == nil then return end
	local registry = registryFor(luaState)
	local variables = script.variables
	local bound = getmetatable(variables) and getmetatable(variables).__psychBound
	if bound ~= registry.globals then return end
	for key, value in pairs(registry.globals) do
		if type(key) == "string" then rawset(variables, key, value) end
	end
end

--- Writes a global into a script's own environment.
--
-- The refresh publishes the values that change per frame, and a compiled Psych
-- script reads them from the environment it runs in -- not from the wrapper's
-- `variables` table. Writing only to the wrapper left every playhead global nil
-- inside the mod, which is the original complaint.
function PsychBindings.writeGlobal(luaState, name, value)
	if luaState == nil then return false end
	local registry = registryFor(luaState)
	registry.globals[name] = value
	return true
end

--- Runs `source` as a Psych script.
--
-- Returns the script object on success. The caller owns it and must keep it
-- alive: the 128 callbacks registered during construction live on it.
function PsychBindings.runScript(compat, source, name)
	local shim = PsychBindings.loadShim(compat)
	if not shim or not shim.createScript then
		return nil, "Psych shim unavailable"
	end
	-- Psych's constructor takes the script's *path*, not its code: it trims the
	-- name, splits it on "/" to work out which mod folder the script belongs to,
	-- and publishes it as the `scriptName` global for the mod to read. Passing the
	-- source text left that path parsing to work on a nil and die in StringTools.
	local ok, script = pcall(shim.createScript, name or source)
	if not ok then
		return nil, tostring(script)
	end
	if script == nil then
		return nil, "Psych script did not build"
	end
	-- PsychBridge.install is what gives a script object its helper functions; a
	-- script that is never installed has the 128 callbacks from its constructor and
	-- none of the functions those callbacks use. The engine never called it.
	if type(shim.install) == "function" then
		local okInstall, installError = pcall(shim.install, script)
		if not okInstall then
			return nil, "Psych helpers could not be installed: " .. tostring(installError)
		end
	end
	return script
end


--- Points the compiled layer's globals at the live game.
--
-- The shim runs in its own environment, so the Haxe globals Psych's constructor
-- reads (PlayState, Conductor, FlxG, Mods, ...) are not visible to it. Without
-- this it sees `PlayState.instance == nil` and silently skips the song-time half
-- of its own setup: no luaArray registration, no curBeat/curSection publishing,
-- no resetting of the per-song globals. The script still "works", which is the
-- worst part -- it just does not see the song.
--
-- Values are copied by reference, so they stay live: the shim holds the same
-- table the engine mutates, not a snapshot.
-- Names the compiled layer reads, mapped to where the engine keeps them.
--
-- Psych's Haxe refers to `Paths`, `FlxG`, `Difficulty`, `Song`, `WeekData` and
-- friends as global classes. The engine has Lua modules instead: `paths` is a
-- module, and several of the others have no global at all -- their logic lives
-- inside the compatibility layer (which is why `Psych.shaders` and `Psych.classes`
-- exist). This table is the mapping, and it is deliberately explicit: guessing
-- which names exist produced a shim that failed on `Paths` with "attempt to index
-- a nil value" after everything looked fine.
local LIVE_GLOBALS = {
	PlayState = "PlayState", Conductor = "Conductor", FlxG = "FlxG",
	Paths = "paths", Mods = "Mods", ClientPrefs = "ClientPrefs",
	Character = "Character", Note = "Note", GameOverSubstate = "GameOverSubstate",
	MainMenuState = "MainMenuState",
}
-- Fields Psych's constructor reads off those globals, which the engine does not
-- define but a mod can legitimately check with `version` or `getProperty`.
--
-- `MainMenuState.psychEngineVersion` is the first one that bit: the constructor
-- trims it to publish the `version` global, and a state table has no such field, so
-- the whole script died on a nil trim. These are identity values, not behaviour --
-- the engine targets one Psych release.
local MAINMENU_FIELDS = {
	psychEngineVersion = "1.0.4",
}

--- Identity classes Psych's constructor publishes as globals.
--
-- `Song`, `Difficulty` and `WeekData` are Haxe classes with static state. The engine
-- keeps the same information on `PlayState` (`songDifficulty`, `storyWeek`,
-- `seenCutscene`) and in its chart, so these are read-through views rather than
-- copies: a value the engine changes later is still visible, and nothing here can
-- drift from what the state actually holds.
local function psychIdentity(state)
	local song = state and state.SONG or (rawget(_G, "PlayState") or {}).SONG
	local difficulty = (rawget(_G, "PlayState") or {}).songDifficulty
	local names = { easy = "Easy", normal = "Normal", hard = "Hard" }
	local function difficultyName()
		local raw = tostring(difficulty or "normal")
		return names[raw] or (raw:gsub("^%l", string.upper))
	end
	-- Note skins: Psych derives a filename postfix from the skin name, and the
	-- engine has no skin system yet, so the honest postfix is the empty one -- the
	-- default skin -- rather than a guess that would load the wrong images.
	local function skinPostfix()
		return ""
	end
	return {
		-- `Note` and `NoteSplash` are classes here, so the constructor's static
		-- calls need somewhere to live. The engine's Note is a real class; its
		-- splash equivalent does not exist yet.
		NoteSplash = { getSplashSkinPostfix = skinPostfix },
		Song = {
			-- Haxe calls this the loaded song; for a running state that is the song
			-- in the chart.
			loadedSongName = song and (song.song or song.name) or nil,
			chartPath = state and state.psychChartPath or nil,
			loadFromJson = function(name) return song end,
		},
		Difficulty = {
			getString = function(translated) return difficultyName() end,
			getFilePath = function() return tostring(difficulty or "normal") end,
		},
		-- Psych indexes this by PlayState.storyWeek, which is a number there and a
		-- string here; week-end songs are the only case that matters and the engine
		-- has no list for them yet, so it is an empty list rather than a wrong one.
		WeekData = { weeksList = {} },
	}
end

--- `MusicBeatState`, the store Psych keeps script variables in.
--
-- 79 call sites in the compiled layer go through `MusicBeatState.getVariables()`,
-- which is where setVar/getVar read and write, and `getState()` is how the
-- reflection helpers resolve an object by name. The engine's states have no such
-- static, so those 79 call sites had nothing to talk to.
--
-- One store per game, created through the compiled layer's own StringMap so the
-- values it holds are the ones Psych's `tnull` handling expects.
local function psychMusicBeatState(shared, state)
	local store
	-- The backing table is resolved lazily and only once there is a state to own it.
	--
	-- getVariables() is called during construction, before the state exists, and
	-- whatever store it hands back is the one that gets written to. Creating it then
	-- meant every mod wrote into a table nothing could read -- the value was present
	-- in the store and absent from state.psychVariables. So the store is created on
	-- the first real use, and the engine's own table backs it from then on.
	local function currentState()
		local owner = (compatState and compatState()) or state
		return type(owner) == "table" and owner or nil
	end
	local function ensure()
		local owner = currentState()
		if owner == nil then return store end
		-- A store created before its owner existed -- during construction -- is not
		-- the store the mod will write to; re-anchor it once there is a state, even
		-- if something was already created.
		if store and store.h == owner.psychVariables then return store end
		if store == nil then
		local newMap = shared.__haxe_ds_StringMap
		if type(newMap) == "table" and type(newMap.new) == "function" then
			store = newMap.new()
		else
			store = { h = {} }
		end
		end
		owner.psychVariables = owner.psychVariables or {}
		store.h = owner.psychVariables
		return store
	end
	-- A store for a caller that only wants to read the map shape. Not memoised, so it
	-- cannot become the one a mod writes to before a state exists.
	local function scratch() return { h = {} } end
	return {
		getVariables = function()
			return ensure() or scratch()
		end,
		getState = function()
			return game and game.getState and game.getState() or nil
		end,
		switchState = function(target)
			if game and game.switchState then return game.switchState(target) end
		end,
	}
end

--- `FileSystem`, over the game's filesystem.
--
-- Psych asks whether a script exists before deciding whether to load it by path or
-- to treat the argument as source. The engine has no FileSystem class, so that check
-- was the thing standing between a mod file and its own code -- and, because it is
-- read first, the failure said "attempt to index FileSystem" rather than naming the
-- script.
--
-- Every path a mod uses is a path in the game's filesystem, not on the real disk.
local function psychFileSystem()
	local filesystem = love and love.filesystem
	if not filesystem then return nil end
	return {
		exists = function(path)
			if type(path) ~= "string" then return false end
			local info = filesystem.getInfo(path)
			return info ~= nil
		end,
		readDirectory = function(path)
			local items = filesystem.getDirectoryItems(path) or {}
			local array = { length = #items }
			for index, name in ipairs(items) do array[index - 1] = name end
			return array
		end,
		deleteFile = function(path)
			return filesystem.remove(path)
		end,
	}
end

--- Builds the `FlxG` surface Psych's constructor and helpers read.
--
-- Flixel's global game state is not a thing this engine has: there is no FlxG table,
-- the camera belongs to the state (`camGame`, `camHUD`), and the music is the global
-- `game.sound.music`. Rather than pretend, each field is mapped to the live object,
-- and the ones with no equivalent stay absent so a mod fails on a name instead of on
-- a plausible-looking lie.
--
-- `songLength` is the constructor's first real read -- `FlxG.sound.music.length`
-- decided whether a script loaded at all -- so `sound.music` has to be the playing
-- handle, not a copy.
local function psychFlxG(state)
	local flx = {}
	if type(state) == "table" then
		local camera = state.camGame or state.camHUD
		flx.camera = camera
	end
	local sound = { music = game and game.sound and game.sound.music or nil }
	flx.sound = sound
	flx.width, flx.height = (game and game.width) or 1280, (game and game.height) or 720
	flx.keys = rawget(_G, "keys") or {}
	flx.mouse = rawget(_G, "mouse") or {}
	flx.overlap = rawget(_G, "overlap")
	flx.gamepads = rawget(_G, "gamepads")
	return flx
end

--- Adapts the engine's Lua modules to the shapes Psych's Haxe calls.
--
-- The engine and Psych name the same things differently, and in two cases the
-- shape differs, not just the name: Haxe calls `Paths.image(key)` and reads
-- `Mods.currentModDirectory` as a field, while the engine has `paths.getPath(key)`
-- and `Mods.currentMod`. Handing the engine table over unchanged is what produced
-- "attempt to call field 'mods'". This translates instead of copying.
local function psychPaths()
	local engine = rawget(_G, "paths")
	if type(engine) ~= "table" then return nil end
	local adapter = {}
	-- Path builders: Haxe hands back a path, the engine's getPath does the lookup.
	local function builder(kind)
		return function(key)
			if type(engine.getPath) ~= "function" then return key end
			return engine.getPath(key, true, false)
		end
	end
	adapter.mods = function() return engine.getMods and engine.getMods("mods") or "mods" end
	adapter.getSharedPath = builder("shared")
	adapter.formatToSongPath = function(name)
		if type(engine.formatToSongPath) == "function" then return engine.formatToSongPath(name) end
		return name
	end
	for _, name in ipairs({ "image", "sound", "music", "font", "video", "getPath" }) do
		adapter[name] = builder(name)
	end
	-- Atlas loaders live in the graphics layer, not in paths; leaving them absent
	-- makes the shim fail with a name instead of silently loading nothing.
	for _, name in ipairs({ "getSparrowAtlas", "getPackerAtlas", "getAtlas", "getMultiAtlas",
		"getAsepriteAtlas", "loadAnimateAtlas", "getTextFromFile" }) do
		if type(engine[name]) == "function" then adapter[name] = engine[name] end
	end
	return adapter
end

local function psychMods()
	local engine = rawget(_G, "Mods")
	if type(engine) ~= "table" then return nil end
	-- A field in Haxe, a field in the engine: keep it live with a metatable so a
	-- mod switch after load is still visible.
	return setmetatable({}, {
		__index = function(_, key)
			if key == "currentModDirectory" then return engine.currentMod end
			if key == "getGlobalMods" then
				return function() return engine.getGlobalMods and engine.getGlobalMods() or {} end
			end
			if key == "loadTopMod" then
				return function() return engine.reload and engine.reload() end
			end
			return engine[key]
		end,
	})
end

function PsychBindings.exposeGame(compat)
	local shim = PsychBindings.loadShim(compat)
	if not shim then return nil end
	local globals = shim.globals
	-- One local for the whole function: reading compat.state again further down is
	-- how this briefly used a `state` before declaring it.
	local state = compat and compat.state
	compatState = function() return compat and compat.state end
	for psychName, engineName in pairs(LIVE_GLOBALS) do
		local value = rawget(_G, engineName)
		if value ~= nil then globals[psychName] = value end
	end
	-- Class-standing-in-for-a-Haxe-class surface.
	for name, value in pairs(psychIdentity(compat and compat.state)) do
		if globals[name] == nil then globals[name] = value end
	end
	-- The engine's Note is a real class, but Psych also calls static skin helpers on
	-- it; add them to the class itself so mods that call them keep working.
	local note = globals.Note
	if type(note) == "table" and note.getNoteSkinPostfix == nil then
		note.getNoteSkinPostfix = function() return "" end
	end
	-- Re-created for each connection, not once per process: the store belongs to the
	-- state being played. Created once, the first state's table was reused for the
	-- rest of the session -- a new song writing into the previous song's variables.
	-- Rebuilt whenever the state changes: the store belongs to the state being
	-- played, so a new connection must not inherit the previous one's table.
	if state ~= nil and state ~= storeOwner then
		storeOwner = state
		globals.MusicBeatState = psychMusicBeatState(globals, state)
	elseif globals.MusicBeatState == nil then
		-- Nothing to own the store yet. It is rebuilt below as soon as a state
		-- exists, so this only has to exist for the constructor's calls.
		globals.MusicBeatState = psychMusicBeatState(globals, nil)
	end
	if globals.FileSystem == nil then
		local filesystem = psychFileSystem()
		if filesystem then globals.FileSystem = filesystem end
	end
	-- Flixel's global surface, built per call because it points at live objects.
	local flx = psychFlxG(state)
	if type(flx) == "table" then globals.FlxG = flx end
	-- Identity fields Psych's constructor reads off a class the engine does define.
	local mainmenu = globals.MainMenuState
	if type(mainmenu) == "table" then
		for field, value in pairs(MAINMENU_FIELDS) do
			if mainmenu[field] == nil then mainmenu[field] = value end
		end
	end
	-- The two that need translating rather than copying.
	local paths = psychPaths()
	if paths then globals.Paths = paths end
	local mods = psychMods()
	if mods then globals.Mods = mods end
	-- The constructor calls `game.luaArray:push(self)`; Psych's PlayState owns that
	-- array, and the engine's state has no equivalent, so it is provided here
	-- rather than making the shim special-case a nil.
	--
	-- It has to actually store the script. The first version returned the value and
	-- dropped it, which made every mod load, register nothing, and never be called
	-- -- a script that exists and is invisible. Psych reads this as a Haxe Array:
	-- zero-based, with a `.length` field, and `getRunningScripts` walks it that way.
	local play = globals.PlayState
	if type(play) == "table" then
		if play.instance == nil then play.instance = state end
		if play.luaArray == nil then
			local array = { length = 0 }
			function array:push(value)
				self[self.length] = value
				self.length = self.length + 1
				return value
			end
			function array:remove(value)
				for i = 0, self.length - 1 do
					if self[i] == value then
						for j = i, self.length - 2 do self[j] = self[j + 1] end
						self[self.length - 1] = nil
						self.length = self.length - 1
						return true
					end
				end
				return false
			end
			play.luaArray = array
		end
	end
	-- `game.luaArray` above and `PlayState.instance.luaArray` in helpers must be the
	-- same object, or a script registered one way is invisible the other.
	if type(state) == "table" and type(play) == "table" and state.luaArray == nil then
		state.luaArray = play.luaArray
	end
	return shim
end

--- Builds the loader Script:new should use for a Psych `.lua` script.
--
-- The engine's load order is fixed: loader -> setfenv -> configure -> chunk().
-- `configure` is where the script receives its compatibility object, so a
-- FunkinLua cannot be built at loader time. The loader therefore returns the
-- *chunk*, which the engine runs after configure -- the first moment Psych's
-- runtime exists.
--
-- Returns nil plus a message when the shim is missing, so such a script fails
-- like a syntax error instead of quietly doing nothing.
function PsychBindings.scriptLoader(compat)
	local shim = PsychBindings.loadShim(compat)
	if not shim or not shim.createScript then
		return nil, "Psych shim unavailable"
	end
	return function(script, source)
		return function()
			local runtime = script and script._psych and script._psych.psychRuntime
			if not runtime then return end
			runtime(source, script)
		end
	end
end

return PsychBindings
