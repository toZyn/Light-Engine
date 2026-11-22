local Scripts = {}

local function cleanName(name)
	assert(type(name) == "string" and name:match("^[%w_%-][%w_/%-%.]*$"), "Invalid Psych script path")
	for part in name:gmatch("[^/]+") do
		assert(part ~= "." and part ~= "..", "Invalid Psych script path")
	end
	assert(not name:find("//", 1, true) and name:sub(-1) ~= "/", "Invalid Psych script path")
	return name
end

function Scripts.install(compat, api)
	local script = compat.script
	local function registry()
		return script.psychRegistry or {}
	end
	local function find(name, extension)
		name = cleanName(name):gsub("%." .. extension .. "$", "")
		local loaded = registry()
		local target = loaded[name .. "." .. extension] or loaded["scripts/" .. name .. "." .. extension]
		if target and not target.closed then return target end
	end

	local function add(name, extension)
		compat:_active()
		if type(script.psychLoadScript) ~= "function" then return false end
		name = cleanName(name):gsub("%." .. extension .. "$", "") .. "." .. extension
		local target, fresh = script.psychLoadScript(name)
		if not target and not name:find("/", 1, true) then
			target, fresh = script.psychLoadScript("scripts/" .. name)
		end
		if not fresh then return false end
		target._psychCreateCalled = true
		target:call("onCreate")
		if compat.state._postCreated then target:call("onCreatePost") end
		return not target.closed
	end

	local function remove(name, extension)
		compat:_active()
		local target = find(name, extension)
		if not target then return false end
		target:call("onDestroy")
		target:close()
		return true
	end
	api.addLuaScript = function(name) return add(name, "lua") end
	api.addHScript = function(name) return add(name, "hx") end
	api.removeLuaScript = function(name) return remove(name, "lua") end
	api.removeHScript = function(name) return remove(name, "hx") end
	api.isRunning = function(name) return find(name, "lua") ~= nil or find(name, "hx") ~= nil end
	api.callScript = function(name, callback, args)
		local target = find(name, "lua")
		if target then return target:call(callback, unpack(args or {})) end
	end
	api.getGlobalFromScript = function(name, key)
		local target = find(name, "lua")
		if target then return rawget(target.variables, key) end
	end
	api.setGlobalFromScript = function(name, key, value)
		local target = find(name, "lua")
		if target then target:set(key, value); return true end
		return false
	end
end

return Scripts
