---@class UIInputTextBox:Object
local InputTextBox = Object:extend("UIInputTextBox")

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

local function fitTextEnd(font, str, maxWidth)
	if maxWidth <= 0 or str == "" then return "" end
	if font:getWidth(str) <= maxWidth then return str end
	local len = #str
	for i = 2, len do
		local sub = str:sub(i)
		if font:getWidth(sub) <= maxWidth then
			return sub
		end
	end
	return ""
end

local function fitTextStart(font, str, maxWidth)
	if maxWidth <= 0 or str == "" then return "" end
	if font:getWidth(str) <= maxWidth then return str end
	for i = #str - 1, 1, -1 do
		local sub = str:sub(1, i)
		if font:getWidth(sub) <= maxWidth then
			return sub
		end
	end
	return ""
end

function InputTextBox:new(x, y, width, height, placeholder, font)
	InputTextBox.super.new(self, x, y)

	if placeholder ~= nil and type(placeholder) ~= "string" then
		font = placeholder
		placeholder = nil
	end

	self.width = width or 150
	self.height = height or 22

	self.text = ""
	self.placeholder = placeholder or "Type here..."

	self.focused = false
	self.hovered = false
	self.cursorPos = 0
	self.cursorBlinkTime = 0.5
	self.cursorTimer = 0
	self.cursorVisible = true

	self.font = font or love.graphics.getFont()

	self.color = Color.fromRGB(36, 34, 46)
	self.focusedColor = Color.fromRGB(48, 46, 64)
	self.textColor = {1, 1, 1}
	self.placeholderColor = {0.6, 0.6, 0.65}
	self.borderColor = {0.75, 0.75, 0.82}
	self.focusedBorderColor = Color.fromRGB(110, 175, 255)
	self.borderSize = 1
	self.cursorColor = {1, 1, 1}

	self.onChanged = nil
	self.onSubmit = nil
	self.maxLength = 256
end

function InputTextBox:setText(value, notify)
	local str = tostring(value or "")
	if self.maxLength and #str > self.maxLength then
		str = str:sub(1, self.maxLength)
	end
	self.text = str
	self.cursorPos = math.clamp(self.cursorPos, 0, #self.text)
	if notify and self.onChanged then
		self.onChanged(self.text)
	end
end

function InputTextBox:update(dt)
	InputTextBox.super.update(self, dt)
	if not self.visible then
		self.focused = false
		self.hovered = false
		return
	end

	local mx, my = getMousePos(self)
	self.hovered = (mx >= self.x and mx <= self.x + self.width and
		my >= self.y and my <= self.y + self.height)

	if game.mouse.justPressedLeft then
		local wasFocused = self.focused
		self.focused = self.hovered
		if self.focused then
			self.cursorTimer = 0
			self.cursorVisible = true
			self.cursorPos = #self.text
		elseif wasFocused and self.onSubmit then
			self.onSubmit(self.text)
		end
	end

	if not self.focused then return end

	self.cursorTimer = self.cursorTimer + dt
	if self.cursorTimer >= self.cursorBlinkTime then
		self.cursorTimer = self.cursorTimer - self.cursorBlinkTime
		self.cursorVisible = not self.cursorVisible
	end

	if game.keys.justPressed.ENTER or game.keys.justPressed.ESCAPE then
		self.focused = false
		if self.onSubmit then self.onSubmit(self.text) end
		return
	end

	local ctrl = game.keys.pressed.CONTROL
	if ctrl and game.keys.justPressed.V and love.system.getClipboardText then
		local clip = (love.system.getClipboardText() or ""):gsub("[\r\n]", "")
		if clip ~= "" then
			self:input(clip)
		end
		return
	elseif ctrl and game.keys.justPressed.C and love.system.setClipboardText then
		love.system.setClipboardText(self.text)
		return
	elseif ctrl then
		return
	end

	for key in pairs(game.keys.input.justPressed) do
		if type(key) == "string" and #key == 1 then
			self:input(key)
		end
	end

	if game.keys.justPressed.BACKSPACE then
		self:backspace()
	elseif game.keys.justPressed.DELETE then
		self:delete()
	elseif game.keys.justPressed.LEFT then
		self.cursorPos = math.max(0, self.cursorPos - 1)
		self.cursorVisible = true
		self.cursorTimer = 0
	elseif game.keys.justPressed.RIGHT then
		self.cursorPos = math.min(#self.text, self.cursorPos + 1)
		self.cursorVisible = true
		self.cursorTimer = 0
	elseif game.keys.justPressed.HOME then
		self.cursorPos = 0
	elseif game.keys.justPressed.END then
		self.cursorPos = #self.text
	end
end

function InputTextBox:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local prevFont = love.graphics.getFont()

	local x, y = self.x - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		self.y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)
	local width, height = self.width, self.height
	local bs = self.borderSize

	local borderCol = self.focused and self.focusedBorderColor or self.borderColor
	local bgCol = self.focused and self.focusedColor or self.color

	love.graphics.setColor(borderCol[1], borderCol[2], borderCol[3], self.alpha)
	love.graphics.rectangle("fill", x, y, width, height, 3, 3)

	love.graphics.setColor(bgCol[1], bgCol[2], bgCol[3], self.alpha)
	love.graphics.rectangle("fill", x + bs, y + bs, width - bs * 2, height - bs * 2, 2, 2)

	if self.hovered and not self.focused then
		love.graphics.setColor(1, 1, 1, 0.06 * self.alpha)
		love.graphics.rectangle("fill", x + bs, y + bs, width - bs * 2, height - bs * 2, 2, 2)
	end

	local font = self.font or prevFont
	love.graphics.setFont(font)
	local padX = 5
	local innerW = math.max(4, width - padX * 2)
	local textY = y + (height - font:getHeight()) * 0.5

	if #self.text > 0 then
		love.graphics.setColor(self.textColor[1], self.textColor[2],
			self.textColor[3], self.alpha)
		local beforeCursor = self.text:sub(1, self.cursorPos)
		local visBefore = fitTextEnd(font, beforeCursor, innerW)
		local beforeW = font:getWidth(visBefore)
		local afterCursor = self.text:sub(self.cursorPos + 1)
		local visAfter = fitTextStart(font, afterCursor, math.max(0, innerW - beforeW))
		love.graphics.print(visBefore .. visAfter, x + padX, textY)

		if self.focused and self.cursorVisible then
			local cx = x + padX + beforeW
			love.graphics.setColor(self.cursorColor[1], self.cursorColor[2],
				self.cursorColor[3], self.alpha)
			love.graphics.rectangle("fill", cx, textY, 1.5, font:getHeight())
		end
	else
		if self.placeholder ~= "" and not self.focused then
			love.graphics.setColor(self.placeholderColor[1], self.placeholderColor[2],
				self.placeholderColor[3], self.alpha)
			love.graphics.print(fitTextStart(font, self.placeholder, innerW), x + padX, textY)
		end
		if self.focused and self.cursorVisible then
			love.graphics.setColor(self.cursorColor[1], self.cursorColor[2],
				self.cursorColor[3], self.alpha)
			love.graphics.rectangle("fill", x + padX, textY, 1.5, font:getHeight())
		end
	end

	love.graphics.setFont(prevFont)
	love.graphics.setColor(r, g, b, a)
end

function InputTextBox:input(char)
	if not self.focused or not char or char == "" then return end
	if self.maxLength and (#self.text + #char) > self.maxLength then return end
	self.text = self.text:sub(1, self.cursorPos) .. char .. self.text:sub(self.cursorPos + 1)
	self.cursorPos = self.cursorPos + #char
	self.cursorVisible = true
	self.cursorTimer = 0
	if self.onChanged then self.onChanged(self.text) end
end

function InputTextBox:backspace()
	if self.cursorPos > 0 then
		self.text = self.text:sub(1, self.cursorPos - 1) .. self.text:sub(self.cursorPos + 1)
		self.cursorPos = self.cursorPos - 1
		self.cursorVisible = true
		self.cursorTimer = 0
		if self.onChanged then self.onChanged(self.text) end
	end
end

function InputTextBox:delete()
	if self.cursorPos < #self.text then
		self.text = self.text:sub(1, self.cursorPos) .. self.text:sub(self.cursorPos + 2)
		self.cursorVisible = true
		self.cursorTimer = 0
		if self.onChanged then self.onChanged(self.text) end
	end
end

return InputTextBox
