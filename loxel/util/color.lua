local function fromRGB(r, g, b)
	return {r / 255, g / 255, b / 255}
end

local function fromHEX(hex)
	return fromRGB(bit.band(bit.rshift(hex, 16), 0xFF),
		bit.band(bit.rshift(hex, 8), 0xFF),
		bit.band(hex, 0xFF))
end

---@class ColorTable
local colorTable = {
	BLACK   = fromHEX(0x000000),
	BLUE    = fromHEX(0x0000FF),
	BROWN   = fromHEX(0x8B4513),
	CYAN    = fromHEX(0x00FFFF),
	GRAY    = fromHEX(0x808080),
	GREEN   = fromHEX(0x008000),
	LIME    = fromHEX(0x00FF00),
	MAGENTA = fromHEX(0xFF00FF),
	ORANGE  = fromHEX(0xFFA500),
	PINK    = fromHEX(0xFFC0CB),
	PURPLE  = fromHEX(0x800080),
	RED     = fromHEX(0xFF0000),
	WHITE   = fromHEX(0xFFFFFF),
	YELLOW  = fromHEX(0xFFFF00)
}

---@class Color:ColorTable
local Color = {}

function Color.get(c)
	if type(c) == "table" then
		local r, g, b, a = c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1
		if r > 1 or g > 1 or b > 1 then
			r, g, b = r / 255, g / 255, b / 255
			if a > 1 then a = a / 255 end
		end
		return r, g, b, a
	elseif type(c) == "string" then
		local parsed = Color.fromString(c)
		return parsed[1], parsed[2], parsed[3], parsed[4] or 1
	elseif type(c) == "number" then
		local parsed = fromHEX(c)
		return parsed[1], parsed[2], parsed[3], 1
	end
	return 1, 1, 1, 1
end

function Color.fromHEX(hex) return fromHEX(hex) end

function Color.fromRGB(...) return fromRGB(...) end

function Color.HSLtoRGB(h, s, l)
	local c = (1 - math.abs(l + l - 1)) * s
	local m = l - 0.5 * c
	local r, g, b = m, m, m
	if h == h then
		local h = (h % 1.0) * 6.0
		local x = c * (1 - math.abs(h % 2 - 1))
		c, x = c + m, x + m
		if h < 1 then
			r, g, b = c, x, m
		elseif h < 2 then
			r, g, b = x, c, m
		elseif h < 3 then
			r, g, b = m, c, x
		elseif h < 4 then
			r, g, b = m, x, c
		elseif h < 5 then
			r, g, b = x, m, c
		else
			r, g, b = c, m, x
		end
	end
	return r, g, b
end

function Color.RGBtoHSL(r, g, b)
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local h, s, l = 0, 0, (max + min) / 2

	if max ~= min then
		local d = max - min
		s = l > 0.5 and d / (2 - max - min) or d / (max + min)
		if max == r then
			h = (g - b) / d + (g < b and 6 or 0)
		elseif max == g then
			h = (b - r) / d + 2
		else
			h = (r - g) / d + 4
		end
		h = h / 6
	end

	return h, s, l
end

function Color.fromHSL(...)
	return {Color.HSLtoRGB(...)}
end

function Color.fromString(str)
	if type(str) == "table" then
		local r, g, b, a = Color.get(str)
		return {r, g, b, a}
	elseif type(str) == "number" then
		return fromHEX(str)
	elseif type(str) ~= "string" then
		return {1, 1, 1}
	end
	local upper = str:upper():gsub("^%s+", ""):gsub("%s+$", "")
	if colorTable[upper] then
		local p = colorTable[upper]
		return {p[1], p[2], p[3]}
	end
	local clean = upper:gsub("^#", ""):gsub("^0X", "")
	if #clean == 3 then
		clean = clean:sub(1, 1):rep(2) .. clean:sub(2, 2):rep(2) .. clean:sub(3, 3):rep(2)
	elseif #clean == 8 then
		local a = (tonumber("0x" .. clean:sub(1, 2)) or 255) / 255
		local r = (tonumber("0x" .. clean:sub(3, 4)) or 255) / 255
		local g = (tonumber("0x" .. clean:sub(5, 6)) or 255) / 255
		local b = (tonumber("0x" .. clean:sub(7, 8)) or 255) / 255
		return {r, g, b, a}
	end
	local r = tonumber("0x" .. clean:sub(1, 2)) or 255
	local g = tonumber("0x" .. clean:sub(3, 4)) or 255
	local b = tonumber("0x" .. clean:sub(5, 6)) or 255
	return Color.fromRGB(r, g, b)
end

function Color.toHexString(c, includeHash)
	local r, g, b = Color.get(c or Color.WHITE)
	local prefix = (includeHash == false) and "" or "#"
	return string.format("%s%02X%02X%02X", prefix,
		math.clamp(math.round(r * 255), 0, 255),
		math.clamp(math.round(g * 255), 0, 255),
		math.clamp(math.round(b * 255), 0, 255))
end

function Color.convert(rgb)
	return {rgb[1] / 255,
		rgb[2] / 255,
		rgb[3] / 255}
end

function Color.saturate(rgb, amount)
	local h, s, l = Color.RGBtoHSL(rgb[1], rgb[2], rgb[3])
	s = math.min(1, math.max(0, s + amount))
	return {Color.HSLtoRGB(h, s, l)}
end

function Color.lerp(x, y, i)
	return {math.lerp(x[1], y[1], i),
		math.lerp(x[2], y[2], i),
		math.lerp(x[3], y[3], i)}
end

function Color.lerpDelta(x, y, i, delta)
	local t = math.exp(-(delta or game.dt) * i)
	return {math.lerp(y[1], x[1], t),
		math.lerp(y[2], x[2], t),
		math.lerp(y[3], x[3], t)}
end

function Color.vec4(tbl, a, b, c, d)
	local n = #tbl
	if n >= 4 then return tbl[1], tbl[2], tbl[3], tbl[4] end
	if n == 3 then return tbl[1], tbl[2], tbl[3], a or 0 end
	if n == 2 then return tbl[1], tbl[2], a or 0, b or 0 end
	if n == 1 then return tbl[1], a or 0, b or 0, c or 0 end
	return a or 0, b or 0, c or 0, d or 0
end

setmetatable(Color, {
	__index = function(_, key)
		local p = colorTable[key]
		if p then return {p[1], p[2], p[3]} end
	end
})

return Color
