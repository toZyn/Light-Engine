---@class UINavbar:Object
local Navbar = Object:extend("UINavbar")

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

function Navbar:new(items, position, size)
	Navbar.super.new(self, 0, 0)

	self.position = position or "top"
	self.size = size or 32
	self:updateBounds()

	self.items = items or {}
	self.hoveredIndex = nil
	self.pressedIndex = nil
	self.openMenuIndex = nil
	self.hoveredSubIndex = nil

	self.color = Color.fromRGB(28, 26, 38)
	self.itemColor = Color.fromRGB(38, 36, 52)
	self.hoveredColor = Color.fromRGB(64, 92, 152)
	self.pressedColor = Color.fromRGB(44, 62, 108)
	self.lineColor = Color.fromRGB(88, 86, 114)
	self.lineSize = 1

	self.font = love.graphics.getFont()
	self.textColor = {1, 1, 1}
end

function Navbar:updateBounds()
	if self.position == "top" then
		self.x, self.y = 0, 0
		self.width, self.height = game.width, self.size
	elseif self.position == "bottom" then
		self.x, self.y = 0, game.height - self.size
		self.width, self.height = game.width, self.size
	elseif self.position == "left" then
		self.x, self.y = 0, 0
		self.width, self.height = self.size, game.height
	elseif self.position == "right" then
		self.x, self.y = game.width - self.size, 0
		self.width, self.height = self.size, game.height
	end
end

function Navbar:update(dt)
	Navbar.super.update(self, dt)
	if not self.visible then return end

	self:updateBounds()
	local mx, my = getMousePos(self)

	self.hoveredIndex = nil
	local itemCount = #self.items
	if itemCount == 0 then return end

	local isHorizontal = (self.position == "top" or self.position == "bottom")
	local itemSpan = isHorizontal and math.min(140, self.width / itemCount) or (self.height / itemCount)

	for i = 1, itemCount do
		local ix = isHorizontal and (self.x + (i - 1) * itemSpan) or self.x
		local iy = isHorizontal and self.y or (self.y + (i - 1) * itemSpan)
		local iw = isHorizontal and itemSpan or self.width
		local ih = isHorizontal and self.height or itemSpan

		if mx >= ix and mx <= ix + iw and my >= iy and my <= iy + ih then
			self.hoveredIndex = i
			break
		end
	end

	if self.hoveredIndex then
		if game.mouse.justPressedLeft then
			self.pressedIndex = self.hoveredIndex
		elseif game.mouse.justReleasedLeft and self.pressedIndex == self.hoveredIndex then
			local item = self.items[self.hoveredIndex]
			if item then
				local fn = item[2] or item.callback
				if fn then fn() end
			end
			self.pressedIndex = nil
		elseif not game.mouse.pressedLeft then
			self.pressedIndex = nil
		end
	elseif not game.mouse.pressedLeft then
		self.pressedIndex = nil
	end
end

function Navbar:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local lineWidth = love.graphics.getLineWidth()
	local prevFont = love.graphics.getFont()

	local x = self.x - self.offset.x - (camera.scroll.x * self.scrollFactor.x)
	local y = self.y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)
	local width, height = self.width, self.height
	local font = self.font or prevFont
	love.graphics.setFont(font)

	love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.96 * self.alpha)
	love.graphics.rectangle("fill", x, y, width, height)

	local itemCount = #self.items
	local isHorizontal = (self.position == "top" or self.position == "bottom")
	local itemSpan = itemCount > 0 and (isHorizontal and math.min(140, width / itemCount) or (height / itemCount)) or 0

	for i, item in ipairs(self.items) do
		local ix = isHorizontal and (x + (i - 1) * itemSpan) or x
		local iy = isHorizontal and y or (y + (i - 1) * itemSpan)
		local iw = isHorizontal and itemSpan or width
		local ih = isHorizontal and height or itemSpan

		local col = (self.pressedIndex == i) and self.pressedColor or
			((self.hoveredIndex == i) and self.hoveredColor or self.itemColor)

		love.graphics.setColor(col[1], col[2], col[3], self.alpha)
		love.graphics.rectangle("fill", ix + 2, iy + 2, iw - 4, ih - 4, 3, 3)

		if self.hoveredIndex == i and self.pressedIndex ~= i then
			love.graphics.setColor(1, 1, 1, 0.1 * self.alpha)
			love.graphics.rectangle("fill", ix + 2, iy + 2, iw - 4, ih - 4, 3, 3)
		end

		local label = item[1] or item.label or ""
		love.graphics.setColor(self.textColor[1], self.textColor[2],
			self.textColor[3], self.alpha)
		love.graphics.printf(tostring(label), ix + 4,
			iy + (ih - font:getHeight()) * 0.5, math.max(1, iw - 8), "center")
	end

	love.graphics.setColor(self.lineColor[1], self.lineColor[2], self.lineColor[3], self.alpha)
	love.graphics.setLineWidth(self.lineSize)
	if self.position == "top" then
		love.graphics.line(x, y + height, x + width, y + height)
	elseif self.position == "bottom" then
		love.graphics.line(x, y, x + width, y)
	end

	love.graphics.setFont(prevFont)
	love.graphics.setColor(r, g, b, a)
	love.graphics.setLineWidth(lineWidth)
end

return Navbar
