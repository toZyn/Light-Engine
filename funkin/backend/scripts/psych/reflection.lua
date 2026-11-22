local Reflection = {}

local Aliases
local function aliases()
	if Aliases == nil then Aliases = require "funkin.backend.scripts.psych.aliases" end
	return Aliases
end

local function warn(message)
	if Logger and Logger.log then Logger.log("warn", "[Psych] " .. tostring(message), 3) end
end

function Reflection.trace(script, message, deprecated)
	if script and deprecated then
		local enabled = rawget(script.variables, "luaDeprecatedWarnings")
		if enabled ~= true then return end
	end
	if script and rawget(script.variables, "luaDebugMode") == true and script.chat then
		script:chat(tostring(message))
		return
	end
	warn(message)
end

function Reflection.coerce(value)
	if type(value) == "string" then
		local number = tonumber(value)
		if number then return number end
	end
	return value
end

function Reflection.split(path)
	if type(path) ~= "string" then return nil end
	local parts = {}
	local head, rest = path:match("^([^%[]*)(.*)$")
	for token in head:gmatch("[^%.]+") do
		parts[#parts + 1] = token:match("^%s*(.-)%s*$")
	end
	for index in rest:gmatch("%[([^%]]*)%]") do
		parts[#parts + 1] = {index = tonumber(index) or 0}
	end
	return parts
end

function Reflection.field(object, key)
	if object == nil then return nil end
	local kind = type(object)
	if kind == "string" then
		if key == "length" then return #object end
		return nil
	end
	if kind ~= "table" and kind ~= "userdata" then return nil end
	return object[key]
end

function Reflection.assign(object, key, value)
	if object == nil then return value end
	local kind = type(object)
	if kind ~= "table" and kind ~= "userdata" then return value end
	object[key] = value
	return value
end

function Reflection.get(object, key)
	if object == nil then return nil end
	if object.__psychGetField then
		local value, found = object:__psychGetField(key)
		if found then return value end
	end
	if type(key) == "string" then
		local value, found = aliases().get(object, key)
		if found then return value end
	end
	return Reflection.field(object, key)
end

function Reflection.set(object, key, value)
	if object == nil then return value end
	if object.__psychSetField then
		if object:__psychSetField(key, value) then return value end
	end
	if type(key) == "string" and aliases().set(object, key, value) then return value end
	return Reflection.assign(object, key, value)
end

function Reflection.walk(root, parts, last, create)
	local object = root
	for index = 1, last - 1 do
		if object == nil then return nil end
		local part = parts[index]
		if type(part) == "table" then object = object[part.index + 1]
		else object = Reflection.get(object, part) end
	end
	return object
end

function Reflection.readPath(root, parts)
	if not parts or #parts == 0 then return nil end
	local object = Reflection.walk(root, parts, #parts, false)
	return Reflection.get(object, parts[#parts])
end

function Reflection.writePath(root, parts, value)
	if not parts or #parts == 0 then return value end
	local object = Reflection.walk(root, parts, #parts, false)
	local key = parts[#parts]
	if type(key) == "table" then
		if object then object[key.index + 1] = value end
		return value
	end
	return Reflection.set(object, key, value)
end

function Reflection.parseInstance(compat, value)
	if type(value) ~= "string" then return value end
	local marker = value:find("::", 1, true)
	if not marker then return value end
	local rest = value:sub(marker + 2)
	local last = rest:match(".*()::")
	local root
	if last then
		local className = rest:sub(last + 2)
		rest = rest:sub(1, last - 1)
		root = compat:_class(className)
	else
		root = compat.state
	end
	if root == nil then return nil end
	for part in rest:gmatch("[^%.]+") do
		root = Reflection.get(root, part)
	end
	return root
end

function Reflection.parseInstances(compat, value)
	if type(value) ~= "table" then return Reflection.parseInstance(compat, value) end
	local result = {}
	for key, item in pairs(value) do result[key] = Reflection.parseInstance(compat, item) end
	return result
end

Reflection.warn = warn

return Reflection
