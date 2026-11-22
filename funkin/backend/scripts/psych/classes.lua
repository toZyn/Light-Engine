local Classes = {}

local Resolve = require "funkin.backend.scripts.psych.resolve"
local Reflection = require "funkin.backend.scripts.psych.reflection"

local function unpack4(...)
	return table.unpack({...})
end

function Classes.install(compat, api)
	local state = compat.state
	local function warn(message, deprecated)
		compat:psychWarn(message, deprecated)
	end

	local function variables()
		state.psychVariables = state.psychVariables or {}
		return state.psychVariables
	end

	local function arguments(values)
		if values == nil then return {} end
		if type(values) ~= "table" then return {values} end
		local list = {}
		if values.length then
			for index = 0, values.length - 1 do list[#list + 1] = Reflection.parseInstance(compat, values[index]) end
			return list
		end
		for index = 1, #values do list[#list + 1] = Reflection.parseInstance(compat, values[index]) end
		return list
	end

	local function call(object, path, list)
		if object == nil then return nil end
		local parts = Reflection.split("value." .. tostring(path or "")) or {}
		table.remove(parts, 1)
		if #parts == 0 then return nil end
		local owner = Reflection.walk(object, parts, #parts)
		local key = parts[#parts]
		if owner == nil or type(key) == "table" then return nil end
		local method = Reflection.get(owner, key)
		if type(method) == "function" then return method(owner, unpack4(table.unpack(list))) end
		return nil
	end
	compat.psychCall = call

	api.instanceArg = function(name, className)
		local value = "##PSYCHLUA_STRINGTOOBJ::" .. tostring(name)
		if className ~= nil then value = value .. "::" .. tostring(className) end
		return value
	end
	api.addInstance = function(name, inFront)
		compat:_active()
		local object = variables()[name]
		if object == nil then
			warn("addInstance: Can't add what doesn't exist~ (" .. tostring(name) .. ")")
			return
		end
		if inFront then
			state:add(object)
			return
		end
		local stage = state.stage
		local index = stage and state:indexOf(stage)
		if index and state.insert then state:insert(index, object) else state:add(object) end
	end
	api.addToGroup = function(group, tag, index)
		compat:_active()
		local object = Resolve.get(compat, tag)
		if object == nil or type(object.destroy) ~= "function" then
			warn("addToGroup: Object " .. tostring(tag) .. " is not valid!")
			return
		end
		local container = Resolve.get(compat, group)
		if container == nil or type(container) == "function" then
			warn("addToGroup: Group/Array " .. tostring(group) .. " is not valid!")
			return
		end
		if type(index) ~= "number" or index < 0 then
			if container.members then container:add(object)
			elseif container.add then container:add(object)
			else container[#container + 1] = object end
		elseif container.insert then
			container:insert(index + 1, object)
		else
			table.insert(container, index + 1, object)
		end
	end
	api.removeFromGroup = function(group, index, tag, destroy)
		compat:_active()
		local object
		if tag ~= nil then
			object = Resolve.get(compat, tag)
			if object == nil or type(object.destroy) ~= "function" then
				warn("removeFromGroup: Object " .. tostring(tag) .. " is not valid!")
				return
			end
		end
		local container = Resolve.get(compat, group)
		if container == nil or type(container) == "function" then
			warn("removeFromGroup: Group/Array " .. tostring(group) .. " is not valid!")
			return
		end
		local position = (type(index) == "number" and index or -1) + 1
		if container.members then
			object = object or container.members[position]
			if object ~= nil then
				container:remove(object)
				if destroy ~= false and object.destroy then object:destroy() end
			end
		elseif type(container) == "table" then
			if object then
				table.delete(container, object)
			else
				object = container[position]
				table.remove(container, position)
			end
			if destroy ~= false and object and object.destroy then object:destroy() end
		end
	end
	api.callMethod = function(path, values)
		compat:_active()
		local name = tostring(path or ""):match("^%s*(.-)%s*$")
		local first = name:match("^([^%.]+)")
		local stored = first and variables()[Reflection.split(first)[1]]
		local parent = stored
		if parent ~= nil then
			name = name:sub(#first + 2):match("^%s*(.-)%s*$")
		else
			parent = state
		end
		if name ~= "" then return call(parent, name, arguments(values)) end
		if type(parent) == "function" then return parent(unpack4(table.unpack(arguments(values)))) end
		return nil
	end
	api.callMethodFromClass = function(className, path, values)
		return call(compat:_class(className), path, arguments(values))
	end
	api.createInstance = function(name, className, values)
		compat:_active()
		local key = tostring(name or ""):gsub("%.", ""):match("^%s*(.-)%s*$")
		if variables()[key] ~= nil then
			warn("createInstance: Variable " .. key .. " is already being used and cannot be replaced!")
			return false
		end
		local class = compat:_class(className)
		if class == nil then
			warn("createInstance: Class " .. tostring(className) .. " not found")
			return false
		end
		local constructor = type(class) == "function" and class or (type(class) == "table" and class.new)
		if type(constructor) ~= "function" then
			warn("createInstance: Failed to create " .. key .. ", arguments are possibly wrong.")
			return false
		end
		local ok, created = pcall(constructor, unpack4(table.unpack(arguments(values))))
		if not ok or created == nil then
			warn("createInstance: Failed to create " .. key .. ", arguments are possibly wrong.")
			return false
		end
		variables()[key] = created
		return true
	end
end

return Classes
