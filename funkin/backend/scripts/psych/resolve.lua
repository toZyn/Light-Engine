local Reflection = require "funkin.backend.scripts.psych.reflection"
local Aliases = require "funkin.backend.scripts.psych.aliases"
local Hud = require "funkin.backend.scripts.psych.hud"

-- LuaJIT/Lua 5.1 has no table.unpack.
local unpack = unpack or table.unpack

local Resolve = {warn = Reflection.warn}

local function playstate(state, key)
	local entry = Aliases.playstate[key]
	if entry == nil then return nil, false end
	if entry.field then return state[entry.field], true end
	if entry.get then return entry.get(state), true end
	return nil, false
end

local function setPlaystate(state, key, value)
	local entry = Aliases.playstate[key]
	if entry == nil then return false end
	if entry.field then
		state[entry.field] = value
		return true
	end
	if entry.set then
		entry.set(state, value)
		return true
	end
	return false
end

local function camera(state, name)
	if name == "camGame" or name == "camera" then return state.camGame or game.camera end
	if name == "camHUD" then return state.camHUD or game.camera end
	if name == "camOther" then return state.camOther or game.camera end
	if name == "camNotes" then return state.camNotes or game.camera end
	return nil
end

local function icon(state, name)
	local bar = state.healthBar
	if bar == nil then return nil end
	if name == "iconP1" then return bar.iconP1 end
	if name == "iconP2" then return bar.iconP2 end
	if name == "icon-bf" then return bar.iconP1 end
	if name == "icon-dad" then return bar.iconP2 end
	return nil
end

function Resolve.root(compat, name)
	if type(name) ~= "string" then return nil end
	local owner = compat:_owner(name)
	if owner ~= compat then owner = owner:_owner(name) end
	local object = compat.objects[name] or (owner and owner.objects and owner.objects[name])
	if object ~= nil then return object end
	local state = compat.state
	if state.psychVariables and state.psychVariables[name] ~= nil then return state.psychVariables[name] end
	if name == "this" or name == "instance" or name == "game" then return state end
	local value = camera(state, name)
	if value then return value end
	value = icon(state, name)
	if value then return value end
	if name == "timeBar" or name == "timeTxt" or name == "timeBarBG" then return Hud.timeBar(state, name) end
	if name == "botplayTxt" then return Hud.botplayText(state) end
	if name == "scoreTxt" and state.scoreText == nil then return Hud.scoreText(state) end
	value = Aliases.playstate[name]
	if value ~= nil then
		local entry = value
		if type(entry) == "table" then
			if entry.field then return state[entry.field] end
			if entry.get then return entry.get(state) end
		end
	end
	return state[name]
end

function Resolve.get(compat, path, allowMaps)
	if type(path) ~= "string" then return nil end
	local parts = Reflection.split(path)
	if parts == nil or #parts == 0 then return nil end
	local first = parts[1]
	if type(first) == "table" then return nil end
	local object = Resolve.root(compat, first)
	if #parts == 1 then return object end
	if object == nil then return nil end
	local variables = compat.state.psychVariables
	if (first == "this" or first == "instance" or first == "game") and variables[parts[2]] ~= nil then
		object = variables[parts[2]]
		return Reflection.readPath(object, {unpack(parts, 3, #parts)})
	end
	return Reflection.readPath(object, {unpack(parts, 2, #parts)})
end

function Resolve.set(compat, path, value, allowMaps, allowInstances)
	if type(path) ~= "string" then return value end
	value = Reflection.coerce(value)
	if allowInstances then value = Reflection.parseInstances(compat, value) end
	local parts = Reflection.split(path)
	if parts == nil or #parts == 0 then return value end
	local first = parts[1]
	if type(first) == "table" then return value end
	if #parts == 1 then
		local state = compat.state
		if state.psychVariables and state.psychVariables[first] ~= nil then
			state.psychVariables[first] = value
			return value
		end
		if setPlaystate(state, first, value) then return value end
		if state[first] ~= nil then
			state[first] = value
			return value
		end
		return value
	end
	local object = Resolve.root(compat, first)
	if object == nil then return value end
	return Reflection.writePath(object, {unpack(parts, 2, #parts)}, value)
end

function Resolve.member(compat, path)
	local value = Resolve.root(compat, path)
	if value == nil then
		local variables = compat.state.psychVariables
		value = variables and variables[path]
	end
	return value
end

Resolve.playstate = playstate
Resolve.setPlaystate = setPlaystate
Resolve.camera = camera

return Resolve
