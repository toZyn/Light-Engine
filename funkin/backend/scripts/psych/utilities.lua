local Utilities = {}
local seed = love.math.random(1, 2147483646)
local modulus = 2147483647

function Utilities.setRandomSeed(value)
	seed = math.max(1, math.min(modulus - 1, math.floor(value)))
end

local function generate()
	seed = (seed * 48271) % modulus
	return seed / modulus
end

local function exclusions(value, integer)
	local result = {}
	for item in tostring(value or ""):gmatch("[^,]+") do
		local trimmed = item:match("^%s*(.-)%s*$")
		local number = tonumber(integer and (trimmed:match("^[+-]?0[xX][%da-fA-F]+") or trimmed:match("^[+-]?%d+")) or trimmed)
		if number then result[number] = true end
	end
	return result
end

local function random(minimum, maximum, exclude, integer)
	minimum = tonumber(minimum) or 0
	maximum = tonumber(maximum) or (integer and modulus or 1)
	if integer then minimum, maximum = math.modf(minimum), math.modf(maximum) end
	if minimum == maximum then return minimum end
	if minimum > maximum then minimum, maximum = maximum, minimum end
	local excluded = exclusions(exclude, integer)
	if integer then
		local count = 0
		for value in pairs(excluded) do
			if value % 1 == 0 and value >= minimum and value <= maximum then count = count + 1 end
		end
		assert(count < maximum - minimum + 1, "Psych random range is entirely excluded")
	end
	local result
	repeat
		result = minimum + generate() * (maximum - minimum + (integer and 1 or 0))
		if integer then result = math.floor(result) end
	until not excluded[result]
	return result
end

function Utilities.install(compat, api)
	api.stringStartsWith = function(value, prefix) return value:sub(1, #prefix) == prefix end
	api.stringEndsWith = function(value, suffix) return suffix == "" or value:sub(-#suffix) == suffix end
	api.stringSplit = function(value, delimiter)
		local result = {}
		if delimiter == "" then
			for character in value:gmatch("[%z\1-\127\194-\244][\128-\191]*") do result[#result + 1] = character end
			return result
		end
		local position = 1
		while true do
			local first, last = value:find(delimiter, position, true)
			result[#result + 1] = value:sub(position, first and first - 1 or #value)
			if not first then return result end
			position = last + 1
		end
	end
	api.stringTrim = function(value) return value:match("^[ \t\n\r]*(.-)[ \t\n\r]*$") end
	api.getRandomInt = function(minimum, maximum, exclude) return random(minimum, maximum, exclude, true) end
	api.getRandomFloat = function(minimum, maximum, exclude) return random(minimum, maximum, exclude, false) end
	api.getRandomBool = function(chance) return random(0, 100, nil, false) < (tonumber(chance) or 50) end
	api.getRunningScripts = function()
		compat:_active()
		local result = {}
		for _, script in ipairs(compat.state.scripts and compat.state.scripts.scripts or {}) do
			if script._psych and not script.hscriptCall and not script.closed then result[#result + 1] = script.path end
		end
		return result
	end
end

return Utilities
