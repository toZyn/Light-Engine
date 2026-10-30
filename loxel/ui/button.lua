---@class UIButton:Object
local Button = Object:extend("UIButton")

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

function Button:new(x, y, width, height, text, callback)
	Button.super.new(self, x, y)

	self.width = width or 80
	self.height = height or 20
	self.text = text or "Button"

	self.color = Color.fromRGB(48, 46, 58)
	self.hoveredColor = Color.fromRGB(64, 62, 78)
	self.pressedColor = Color.fromRGB(34, 32, 42)
	self.disabledColor = Color.fromRGB(28, 26, 34)

	self.lineColor = {1, 1, 1}
	self.lineSize = 1

	self.hovered = false
	self.pressed = false
	self.disabled = false

	self.font = love.graphics.getFont()
	self.textColor = {1, 1, 1}

	self.callback = callback
end

function Button:update(dt)
	Button.super.update(self, dt)

	if self.disabled or not self.visible then
		self.hovered = false
		self.pressed = false
		return
	end

	local mx, my = getMousePos(self)
	self.hovered = (mx >= self.x and mx <= self.x + self.width and
		my >= self.y and my <= self.y + self.height)

	if self.hovered then
		if game.mouse.justPressedLeft then
			self.pressed = true
		elseif game.mouse.justReleasedLeft and self.pressed then
			self.pressed = false
			if self.callback then self.callback() end
		elseif not game.mouse.pressedLeft then
			self.pressed = false
		end
	else
		if not game.mouse.pressedLeft then
			self.pressed = false
		end
	end
end

function Button:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local lineWidth = love.graphics.getLineWidth()
	local prevFont = love.graphics.getFont()

	local x, y = self.x - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		self.y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)
	local width, height = self.width, self.height
	local lineSize = self.lineSize

	local color = self.disabled and self.disabledColor or
		(self.pressed and self.pressedColor or
			(self.hovered and self.hoveredColor or self.color))

	love.graphics.setColor(self.lineColor[1], self.lineColor[2],
		self.lineColor[3], self.alpha)
	love.graphics.setLineWidth(lineSize)
	love.graphics.rectangle("fill", x, y, width, height, 3, 3)

	love.graphics.setColor(color[1], color[2], color[3], self.alpha)
	love.graphics.rectangle("fill", x + lineSize, y + lineSize,
		width - lineSize * 2, height - lineSize * 2, 2, 2)

	if self.hovered and not self.pressed and not self.disabled then
		love.graphics.setColor(1, 1, 1, 0.08 * self.alpha)
		love.graphics.rectangle("fill", x + lineSize, y + lineSize,
			width - lineSize * 2, height - lineSize * 2, 2, 2)
	end

	local font = self.font or prevFont
	love.graphics.setFont(font)
	local textAlpha = self.disabled and (0.5 * self.alpha) or self.alpha
	love.graphics.setColor(self.textColor[1], self.textColor[2],
		self.textColor[3], textAlpha)
	love.graphics.printf(tostring(self.text or ""), x + 2,
		y + (height - font:getHeight()) * 0.5, math.max(1, width - 4), "center")

	love.graphics.setFont(prevFont)
	love.graphics.setColor(r, g, b, a)
	love.graphics.setLineWidth(lineWidth)
end

return Button
