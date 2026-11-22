local Text = {}

local Resolve = require "funkin.backend.scripts.psych.resolve"
local Reflection = require "funkin.backend.scripts.psych.reflection"

local borderStyles = {
	none = "none", outline = "normal", outline_fast = "normal", outlinefast = "normal", shadow = "simple"
}

local function object(compat, tag)
	local value = Resolve.get(compat, tag)
	if value ~= nil and type(value) == "table" and value.content ~= nil then return value end
	local stem = tostring(tag or ""):match("^(.-)%.font$") or tostring(tag or ""):match("^(.-)%.color$")
	if stem then
		value = Resolve.get(compat, stem)
		if value ~= nil and type(value) == "table" and value.content ~= nil then return value end
	end
end

local function resize(text)
	if text.__updateDimension then text:__updateDimension() end
end

function Text.install(compat, api)
	local function warn(message, deprecated)
		compat:psychWarn(message, deprecated)
	end
	local function missing(name, tag)
		warn(name .. ": Object " .. tostring(tag) .. " doesn't exist!")
	end

	api.setTextWidth = function(tag, width)
		local text = object(compat, tag)
		if not text then missing("setTextWidth", tag); return false end
		text.limit = width
		text.fieldWidth = width
		resize(text)
		return true
	end
	api.setTextHeight = function(tag, height)
		local text = object(compat, tag)
		if not text then missing("setTextHeight", tag); return false end
		text.fieldHeight = height
		text.height = height
		return true
	end
	api.setTextAutoSize = function(tag, value)
		local text = object(compat, tag)
		if not text then missing("setTextAutoSize", tag); return false end
		text.autoSize = value == true
		if text.autoSize then
			text.limit, text.fieldWidth = nil, nil
			resize(text)
		end
		return true
	end
	api.setTextBorder = function(tag, size, color, style)
		local text = object(compat, tag)
		if not text then missing("setTextBorder", tag); return false end
		local styleName = tostring(style or "outline"):lower():match("^%s*(.-)%s*$")
		local kind = (tonumber(size) or 0) > 0 and (borderStyles[styleName] or "normal") or "none"
		local outline = text.outline
		outline.style = kind == "simple" and "simple" or "normal"
		outline.width = kind == "none" and 0 or size
		outline.offset:set(kind == "simple" and size or 0, kind == "simple" and size or 0)
		if color ~= nil and api.psychColorFromString then
			outline.color = {Color.get(api.psychColorFromString(color))}
		end
		return true
	end
	api.setTextItalic = function(tag, italic)
		local text = object(compat, tag)
		if not text then missing("setTextItalic", tag); return false end
		text.italic = italic == true
		return true
	end
	api.getTextSize = function(tag)
		local text = object(compat, tag)
		if not text then missing("getTextSize", tag); return -1 end
		return text.font and text.font:getHeight() or 0
	end
	api.getTextFont = function(tag)
		local text = object(compat, tag)
		if not text then missing("getTextFont", tag); return nil end
		return text._compatFontName or text.__psychFont or "vcr.ttf"
	end
	api.getTextWidth = function(tag)
		local text = object(compat, tag)
		if not text then missing("getTextWidth", tag); return 0 end
		return text.fieldWidth or text.limit or text:getWidth()
	end
end

return Text
