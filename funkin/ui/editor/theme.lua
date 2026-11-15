local Theme = {}
local fonts = {}

function Theme.font(size)
	if not fonts[size] then fonts[size] = love.graphics.newFont(size) end
	return fonts[size]
end

function Theme.apply(widget)
	local kind = widget.__class
	if kind and kind:sub(1, 2) == "UI" then
		if widget.font then widget.font = Theme.font(kind == "UINavbar" and 12 or 14) end
	end
	if kind == "UIButton" then
		widget.color = Color.fromRGB(48, 51, 58)
		widget.hoveredColor = Color.fromRGB(65, 72, 84)
		widget.pressedColor = Color.fromRGB(35, 62, 96)
		widget.lineColor = Color.fromRGB(98, 105, 118)
	elseif kind == "UITabMenu" then
		widget.bgColor = Color.fromRGB(27, 30, 35)
		widget.bgAlpha = 1
		widget.borderColor = Color.fromRGB(74, 80, 90)
		widget.tabColor = Color.fromRGB(38, 42, 49)
		widget.tabHoverColor = Color.fromRGB(54, 61, 73)
		widget.tabActiveColor = Color.fromRGB(43, 83, 130)
	elseif kind == "UIInputTextBox" then
		widget.color = Color.fromRGB(19, 22, 27)
		widget.focusedColor = Color.fromRGB(26, 34, 45)
		widget.borderColor = Color.fromRGB(104, 111, 125)
		widget.placeholderColor = Color.fromRGB(174, 182, 196)
	elseif kind == "UIDropDown" then
		widget.color = Color.fromRGB(40, 44, 52)
		widget.hoveredColor = Color.fromRGB(54, 61, 73)
		widget.optionColor = Color.fromRGB(27, 30, 35)
		widget.borderColor = Color.fromRGB(104, 111, 125)
	elseif kind == "UINavbar" then
		widget.color = Color.fromRGB(24, 27, 32)
		widget.itemColor = Color.fromRGB(35, 39, 46)
		widget.lineColor = Color.fromRGB(74, 80, 90)
	end
	for _, child in ipairs(widget.members or {}) do Theme.apply(child) end
end

return Theme
