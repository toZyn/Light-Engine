local JSON = {}

local escapeMap = {
	['\\'] = '\\\\',
	['"'] = '\\"',
	['\b'] = '\\b',
	['\f'] = '\\f',
	['\n'] = '\\n',
	['\r'] = '\\r',
	['\t'] = '\\t'
}

local function escapeString(str)
	return (tostring(str):gsub('[%z\1-\31\\"]', function(c)
		return escapeMap[c] or string.format("\\u%04x", c:byte())
	end))
end

local function isArray(tbl)
	local count = 0
	local maxIdx = 0
	for k in pairs(tbl) do
		if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
			return false, 0
		end
		count = count + 1
		if k > maxIdx then maxIdx = k end
	end
	if maxIdx ~= count then
		return false, 0
	end
	return true, count
end

local function isInlinePrimitiveArray(tbl, len)
	if len == 0 then return true end
	if len > 8 then return false end
	for i = 1, len do
		local t = type(tbl[i])
		if t == "table" then return false end
		if t == "string" and #tbl[i] > 32 then return false end
	end
	return true
end

local function formatNumber(n)
	if n ~= n or n == math.huge or n == -math.huge then
		return "0"
	end
	if math.floor(n) == n and math.abs(n) < 1e14 then
		return string.format("%d", n)
	end
	local s = string.format("%.6f", n):gsub("0+$", ""):gsub("%.$", "")
	if s == "-0" or s == "" then s = "0" end
	return s
end

local function encodeValue(val, indentLevel, pretty)
	local t = type(val)
	if t == "string" then
		return '"' .. escapeString(val) .. '"'
	elseif t == "number" then
		return formatNumber(val)
	elseif t == "boolean" then
		return tostring(val)
	elseif val == nil then
		return "null"
	elseif t == "table" then
		local arr, len = isArray(val)
		if arr then
			if len == 0 then return "[]" end
			if not pretty or isInlinePrimitiveArray(val, len) then
				local parts = {}
				for i = 1, len do
					parts[i] = encodeValue(val[i], indentLevel + 1, pretty)
				end
				return "[" .. table.concat(parts, pretty and ", " or ",") .. "]"
			end
			local indent = string.rep("\t", indentLevel + 1)
			local closeIndent = string.rep("\t", indentLevel)
			local parts = {}
			for i = 1, len do
				parts[i] = indent .. encodeValue(val[i], indentLevel + 1, pretty)
			end
			return "[\n" .. table.concat(parts, ",\n") .. "\n" .. closeIndent .. "]"
		else
			local keys = {}
			for k in pairs(val) do
				if type(k) == "string" or type(k) == "number" then
					keys[#keys + 1] = k
				end
			end
			if #keys == 0 then return "{}" end
			table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
			if not pretty then
				local parts = {}
				for i, k in ipairs(keys) do
					parts[i] = '"' .. escapeString(k) .. '":' .. encodeValue(val[k], indentLevel + 1, false)
				end
				return "{" .. table.concat(parts, ",") .. "}"
			end
			local indent = string.rep("\t", indentLevel + 1)
			local closeIndent = string.rep("\t", indentLevel)
			local parts = {}
			for i, k in ipairs(keys) do
				parts[i] = indent .. '"' .. escapeString(k) .. '": ' .. encodeValue(val[k], indentLevel + 1, true)
			end
			return "{\n" .. table.concat(parts, ",\n") .. "\n" .. closeIndent .. "}"
		end
	end
	return "null"
end

function JSON.build(tbl, indentLevel)
	return encodeValue(tbl, indentLevel or 0, true)
end

function JSON.encode(tbl, pretty)
	return encodeValue(tbl, 0, pretty ~= false)
end

function JSON.buildChar(charData)
	return encodeValue(charData, 0, true)
end

return JSON
