---@class UICheckbox:Object
local Checkbox = Object:extend("UICheckbox")

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

function Checkbox:new(x, y, size, checked, callback)
	Checkbox.super.new(self, x, y)

	self.size = size or 20
	self.width = self.size
	self.height = self.size
	self.checked = checked or false
	self.hovered = false

	self.color = Color.fromRGB(36, 34, 46)
	self.checkColor = Color.fromRGB(110, 215, 145)
	self.borderColor = {1, 1, 1}
	self.borderSize = 1.5

	self.callback = callback
end

function Checkbox:setChecked(value, triggerCallback)
	self.checked = not not value
	if triggerCallback and self.callback then
		self.callback(self.checked)
	end
end

function Checkbox:update(dt)
	Checkbox.super.update(self, dt)
	if not self.visible then
		self.hovered = false
		return
	end

	self.width, self.height = self.size, self.size
	local mx, my = getMousePos(self)

	self.hovered = (mx >= self.x and mx <= self.x + self.size and
		my >= self.y and my <= self.y + self.size)

	if self.hovered and game.mouse.justPressedLeft then
		self.checked = not self.checked
		if self.callback then self.callback(self.checked) end
	end
end

function Checkbox:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local lineWidth = love.graphics.getLineWidth()

	local x, y = self.x - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		self.y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)
	local size = self.size
	local bs = self.borderSize

	love.graphics.setColor(self.borderColor[1], self.borderColor[2],
		self.borderColor[3], self.alpha)
	love.graphics.setLineWidth(bs)
	love.graphics.rectangle("fill", x, y, size, size, 3, 3)

	love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.alpha)
	love.graphics.rectangle("fill", x + bs, y + bs, size - bs * 2, size - bs * 2, 2, 2)

	if self.checked then
		love.graphics.setColor(self.checkColor[1], self.checkColor[2],
			self.checkColor[3], self.alpha)
		love.graphics.setLineWidth(math.max(2, size * 0.14))
		love.graphics.line(
			x + size * 0.22, y + size * 0.52,
			x + size * 0.44, y + size * 0.74,
			x + size * 0.78, y + size * 0.28
		)
	end

	if self.hovered then
		love.graphics.setColor(1, 1, 1, 0.1 * self.alpha)
		love.graphics.rectangle("fill", x, y, size, size, 3, 3)
	end

	love.graphics.setColor(r, g, b, a)
	love.graphics.setLineWidth(lineWidth)
end

return Checkbox
