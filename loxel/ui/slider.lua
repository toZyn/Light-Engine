---@class UISlider:Object
local Slider = Object:extend("UISlider")

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

function Slider:new(x, y, width, height, value, min, max, step, orientation, style, onChanged)
	Slider.super.new(self, x, y)

	self.width = width or 100
	self.height = height or 14

	self.min = min or 0
	self.max = max or 100
	self.step = step or 1
	self.value = math.clamp(value or self.min, self.min, self.max)

	self.orientation = orientation or "horizontal"
	self.style = style or "circle"

	self.trackColor = Color.fromRGB(48, 46, 58)
	self.fillColor = Color.fromRGB(108, 168, 255)
	self.handleColor = {1, 1, 1}
	self.handleSize = math.max(self.height, 14)

	self.isDragging = false
	self.hovered = false
	self.onChanged = onChanged
end

function Slider:getRatio()
	if self.max == self.min then return 0 end
	return math.clamp((self.value - self.min) / (self.max - self.min), 0, 1)
end

function Slider:setValue(val, notify)
	local stepped = val
	if self.step and self.step > 0 then
		stepped = math.floor((val - self.min) / self.step + 0.5) * self.step + self.min
		stepped = tonumber(string.format("%.6f", stepped)) or stepped
	end
	local clamped = math.clamp(stepped, self.min, self.max)
	if clamped ~= self.value then
		self.value = clamped
		if notify and self.onChanged then
			self.onChanged(self.value)
		end
	end
end

function Slider:update(dt)
	Slider.super.update(self, dt)
	if not self.visible then
		self.isDragging = false
		self.hovered = false
		return
	end

	local mx, my = getMousePos(self)
	local pad = self.handleSize * 0.5
	self.hovered = (mx >= self.x - pad and mx <= self.x + self.width + pad and
		my >= self.y - pad and my <= self.y + self.height + pad)

	if self.hovered and game.mouse.justPressedLeft then
		self.isDragging = true
	elseif not game.mouse.pressedLeft then
		self.isDragging = false
	end

	if self.isDragging then
		local ratio
		if self.orientation == "vertical" then
			ratio = 1 - math.clamp((my - self.y) / math.max(1, self.height), 0, 1)
		else
			ratio = math.clamp((mx - self.x) / math.max(1, self.width), 0, 1)
		end
		self:setValue(self.min + ratio * (self.max - self.min), true)
	end
end

function Slider:__render(camera)
	local r, g, b, a = love.graphics.getColor()

	local x, y = self.x - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		self.y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)
	local ratio = self:getRatio()

	love.graphics.setColor(self.trackColor[1], self.trackColor[2],
		self.trackColor[3], self.alpha)
	love.graphics.rectangle("fill", x, y, self.width, self.height, 4, 4)

	love.graphics.setColor(self.fillColor[1], self.fillColor[2],
		self.fillColor[3], self.alpha)
	if self.orientation == "vertical" then
		local fh = self.height * ratio
		love.graphics.rectangle("fill", x, y + self.height - fh, self.width, fh, 4, 4)
	else
		love.graphics.rectangle("fill", x, y, self.width * ratio, self.height, 4, 4)
	end

	local hx, hy
	if self.orientation == "vertical" then
		hx = x + self.width * 0.5
		hy = y + self.height * (1 - ratio)
	else
		hx = x + self.width * ratio
		hy = y + self.height * 0.5
	end

	love.graphics.setColor(self.handleColor[1], self.handleColor[2],
		self.handleColor[3], self.alpha)
	local rad = self.handleSize * 0.5
	if self.style == "square" then
		love.graphics.rectangle("fill", hx - rad, hy - rad, self.handleSize, self.handleSize, 2, 2)
	else
		love.graphics.circle("fill", hx, hy, rad)
	end

	if self.hovered or self.isDragging then
		love.graphics.setColor(1, 1, 1, 0.2 * self.alpha)
		love.graphics.circle("fill", hx, hy, rad + 2)
	end

	love.graphics.setColor(r, g, b, a)
end

return Slider
