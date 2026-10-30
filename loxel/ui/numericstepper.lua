---@class UINumericStepper:Object
local NumericStepper = Object:extend("UINumericStepper")

local function getMousePos(self)
	local mx, my = game.mouse.x, game.mouse.y
	local cam = self.cameras and self.cameras[1]
	if cam then
		local z = cam.zoom or 1
		if z ~= 0 and z ~= 1 then
			mx = (mx - cam.width * 0.5) / z + cam.width * 0.5
			my = (my - cam.height * 0.5) / z + cam.height * 0.5
		end
		mx = mx + cam.scroll.x * (self.scrollFactor and self.scrollFactor.x or 1)
		my = my + cam.scroll.y * (self.scrollFactor and self.scrollFactor.y or 1)
	end
	return mx - (self.__uiOffsetX or 0), my - (self.__uiOffsetY or 0)
end

local function formatNumber(n)
	if type(n) ~= "number" or n ~= n then return "0" end
	local rounded = tonumber(string.format("%.4f", n)) or n
	if rounded == 0 then rounded = 0 end
	return tostring(rounded)
end

function NumericStepper:new(x, y, stepSize, defaultValue, min, max, width, height, onChanged)
	NumericStepper.super.new(self, x, y)

	self.min = min or -math.huge
	self.max = max or math.huge
	self.step = stepSize or 1

	local numVal = tonumber(defaultValue)
	if numVal == nil then numVal = 1 end
	numVal = math.clamp(numVal, self.min, self.max)
	self.numValue = numVal
	self.value = formatNumber(numVal)
	self.text = self.value

	self.width = math.max(width or 90, 54)
	self.height = height or 22

	self.focused = false
	self.hoveredBox = false
	self.hoveredDec = false
	self.hoveredInc = false
	self.pressedDec = false
	self.pressedInc = false

	self.cursorPos = #self.value
	self.cursorBlinkTime = 0.5
	self.cursorTimer = 0
	self.cursorVisible = true

	self.font = love.graphics.getFont()

	self.color = Color.fromRGB(36, 34, 46)
	self.focusedColor = Color.fromRGB(48, 46, 64)
	self.textColor = {1, 1, 1}
	self.borderColor = {0.75, 0.75, 0.82}
	self.focusedBorderColor = Color.fromRGB(110, 175, 255)
	self.borderSize = 1
	self.cursorColor = {1, 1, 1}

	self.buttonColor = Color.fromRGB(54, 52, 68)
	self.buttonHoveredColor = Color.fromRGB(72, 70, 90)
	self.buttonPressedColor = Color.fromRGB(38, 36, 48)
	self.buttonSymbolColor = {1, 1, 1}

	self.onChanged = onChanged
	self._pendingTextInput = ""
	self._onTextInput = function(t)
		if self.focused and self.visible and type(t) == "string" and t ~= "" then
			self._pendingTextInput = self._pendingTextInput .. t
		end
	end
	if TextInput then
		TextInput:add(self._onTextInput)
	end
end

local function updateSoftKeyboard(self, focused)
	if not (love.keyboard and love.keyboard.setTextInput) then return end
	if focused then
		local cam = self.cameras and self.cameras[1]
		local sx = self.x + (self.__uiOffsetX or 0) - (cam and cam.scroll.x * (self.scrollFactor and self.scrollFactor.x or 1) or 0)
		local sy = self.y + (self.__uiOffsetY or 0) - (cam and cam.scroll.y * (self.scrollFactor and self.scrollFactor.y or 1) or 0)
		pcall(love.keyboard.setTextInput, true, sx, sy, self.width, self.height)
	elseif love.system and love.system.getDevice and love.system.getDevice() == "Mobile" then
		pcall(love.keyboard.setTextInput, false)
	end
end

function NumericStepper:destroy()
	if self.focused then
		self.focused = false
		updateSoftKeyboard(self, false)
	end
	if TextInput and self._onTextInput then
		TextInput:remove(self._onTextInput)
		self._onTextInput = nil
	end
	NumericStepper.super.destroy(self)
end

function NumericStepper:setValue(val, notify)
	local num = tonumber(val)
	if not num then return end
	num = tonumber(string.format("%.4f", math.clamp(num, self.min, self.max))) or 0
	if num == 0 then num = 0 end
	self.numValue = num
	self.value = formatNumber(num)
	self.text = self.value
	self.cursorPos = math.clamp(self.cursorPos, 0, #self.value)
	local cb = self.onChanged or self.callback
	if notify and cb then
		cb(self.numValue)
	end
end

function NumericStepper:commitText(notify)
	local parsed = tonumber(self.value)
	if not parsed then
		parsed = self.numValue or 0
	end
	self:setValue(parsed, notify ~= false)
end

function NumericStepper:stepBy(mult)
	local base = tonumber(self.value) or self.numValue or 0
	local delta = self.step * mult
	if game.keys.pressed.SHIFT then delta = delta * 10 end
	self:setValue(base + delta, true)
end

function NumericStepper:update(dt)
	NumericStepper.super.update(self, dt)
	if not self.visible then
		if self.focused then
			self.focused = false
			updateSoftKeyboard(self, false)
		end
		self._pendingTextInput = ""
		return
	end

	local mx, my = getMousePos(self)
	local btnW = math.min(self.height, math.floor(self.width * 0.28))
	local boxW = self.width - btnW * 2

	self.hoveredBox = (mx >= self.x and mx < self.x + boxW and
		my >= self.y and my <= self.y + self.height)
	self.hoveredDec = (mx >= self.x + boxW and mx < self.x + boxW + btnW and
		my >= self.y and my <= self.y + self.height)
	self.hoveredInc = (mx >= self.x + boxW + btnW and mx <= self.x + self.width and
		my >= self.y and my <= self.y + self.height)

	if game.mouse.justPressedLeft then
		local wasFocused = self.focused
		if self.hoveredBox then
			self.focused = true
			self.cursorPos = #self.value
			self.cursorVisible = true
			self.cursorTimer = 0
			if not wasFocused then
				self._pendingTextInput = ""
				updateSoftKeyboard(self, true)
			end
		else
			self.focused = false
			self._pendingTextInput = ""
			if wasFocused then
				updateSoftKeyboard(self, false)
				self:commitText(true)
			end
		end

		if self.hoveredDec then
			self.pressedDec = true
			self:stepBy(-1)
		elseif self.hoveredInc then
			self.pressedInc = true
			self:stepBy(1)
		end
	elseif not game.mouse.pressedLeft then
		self.pressedDec = false
		self.pressedInc = false
	end

	if not self.focused then
		self._pendingTextInput = ""
		return
	end

	self.cursorTimer = self.cursorTimer + dt
	if self.cursorTimer >= self.cursorBlinkTime then
		self.cursorTimer = self.cursorTimer - self.cursorBlinkTime
		self.cursorVisible = not self.cursorVisible
	end

	if game.keys.justPressed.ENTER or game.keys.justPressed.ESCAPE then
		self.focused = false
		self._pendingTextInput = ""
		updateSoftKeyboard(self, false)
		self:commitText(true)
		return
	elseif game.keys.justPressed.UP then
		self:stepBy(1)
		return
	elseif game.keys.justPressed.DOWN then
		self:stepBy(-1)
		return
	end

	if self._pendingTextInput ~= "" then
		local pending = self._pendingTextInput
		self._pendingTextInput = ""
		for i = 1, #pending do
			self:input(pending:sub(i, i))
		end
	else
		for key in pairs(game.keys.input.justPressed) do
			if type(key) == "string" and #key == 1 then
				self:input(key)
			end
		end
	end

	if game.keys.justPressed.BACKSPACE then
		self:backspace()
	elseif game.keys.justPressed.DELETE then
		self:delete()
	elseif game.keys.justPressed.LEFT then
		self.cursorPos = math.max(0, self.cursorPos - 1)
	elseif game.keys.justPressed.RIGHT then
		self.cursorPos = math.min(#self.value, self.cursorPos + 1)
	end
end

function NumericStepper:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local prevFont = love.graphics.getFont()

	local x, y = self.x - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		self.y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)
	local width, height = self.width, self.height
	local bs = self.borderSize
	local btnW = math.min(height, math.floor(width * 0.28))
	local boxW = width - btnW * 2

	local borderCol = self.focused and self.focusedBorderColor or self.borderColor
	local bgCol = self.focused and self.focusedColor or self.color

	love.graphics.setColor(borderCol[1], borderCol[2], borderCol[3], self.alpha)
	love.graphics.rectangle("fill", x, y, width, height, 3, 3)

	love.graphics.setColor(bgCol[1], bgCol[2], bgCol[3], self.alpha)
	love.graphics.rectangle("fill", x + bs, y + bs, boxW - bs, height - bs * 2, 2, 2)

	local decCol = self.pressedDec and self.buttonPressedColor or
		(self.hoveredDec and self.buttonHoveredColor or self.buttonColor)
	local incCol = self.pressedInc and self.buttonPressedColor or
		(self.hoveredInc and self.buttonHoveredColor or self.buttonColor)

	love.graphics.setColor(decCol[1], decCol[2], decCol[3], self.alpha)
	love.graphics.rectangle("fill", x + boxW + bs * 0.5, y + bs, btnW - bs, height - bs * 2)

	love.graphics.setColor(incCol[1], incCol[2], incCol[3], self.alpha)
	love.graphics.rectangle("fill", x + boxW + btnW + bs * 0.5, y + bs, btnW - bs * 1.5, height - bs * 2)

	local font = self.font or prevFont
	love.graphics.setFont(font)
	local textY = y + (height - font:getHeight()) * 0.5

	love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.alpha)
	local displayStr = tostring(self.value or "0")
	love.graphics.print(displayStr, x + 4, textY)

	if self.focused and self.cursorVisible then
		local cx = x + 4 + font:getWidth(displayStr:sub(1, self.cursorPos))
		love.graphics.setColor(self.cursorColor[1], self.cursorColor[2], self.cursorColor[3], self.alpha)
		love.graphics.rectangle("fill", math.min(cx, x + boxW - 3), textY, 1.5, font:getHeight())
	end

	love.graphics.setColor(self.buttonSymbolColor[1], self.buttonSymbolColor[2],
		self.buttonSymbolColor[3], self.alpha)
	love.graphics.printf("-", x + boxW, textY, btnW, "center")
	love.graphics.printf("+", x + boxW + btnW, textY, btnW, "center")

	love.graphics.setFont(prevFont)
	love.graphics.setColor(r, g, b, a)
end

function NumericStepper:input(char)
	if not self.focused then return end
	local isDigit = char:match("%d") ~= nil
	local isDot = (char == "." and not self.value:find(".", 1, true))
	local isMinus = (char == "-" and self.cursorPos == 0 and not self.value:find("-", 1, true) and self.min < 0)
	if not (isDigit or isDot or isMinus) then return end

	self.value = self.value:sub(1, self.cursorPos) .. char .. self.value:sub(self.cursorPos + 1)
	self.cursorPos = self.cursorPos + 1
	local parsed = tonumber(self.value)
	if parsed then
		self.numValue = math.clamp(parsed, self.min, self.max)
		if self.onChanged then self.onChanged(self.numValue) end
	end
end

function NumericStepper:backspace()
	if self.cursorPos > 0 then
		self.value = self.value:sub(1, self.cursorPos - 1) .. self.value:sub(self.cursorPos + 1)
		self.cursorPos = self.cursorPos - 1
		local parsed = tonumber(self.value)
		if parsed then
			self.numValue = math.clamp(parsed, self.min, self.max)
			if self.onChanged then self.onChanged(self.numValue) end
		end
	end
end

function NumericStepper:delete()
	if self.cursorPos < #self.value then
		self.value = self.value:sub(1, self.cursorPos) .. self.value:sub(self.cursorPos + 2)
		local parsed = tonumber(self.value)
		if parsed then
			self.numValue = math.clamp(parsed, self.min, self.max)
			if self.onChanged then self.onChanged(self.numValue) end
		end
	end
end

return NumericStepper
