---@class UIWindow:Object
local Window = Object:extend("UIWindow")

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

function Window:new(x, y, width, height, title, closable, minimizable)
	Window.super.new(self, x, y)

	self.width = width or 300
	self.height = height or 200
	self.title = title or "Window"

	self.bgColor = Color.fromRGB(30, 28, 42)
	self.titleBarColor = Color.fromRGB(52, 74, 128)
	self.borderColor = Color.fromRGB(98, 96, 126)
	self.textColor = {1, 1, 1}
	self.buttonColor = Color.fromRGB(64, 62, 84)
	self.buttonHoveredColor = Color.fromRGB(205, 72, 72)

	self.titleBarHeight = 28
	self.borderSize = 1.5
	self.font = love.graphics.getFont()

	self.isDragging = false
	self.dragOffsetX = 0
	self.dragOffsetY = 0

	self.minimized = false
	self.closed = false

	self.closable = closable ~= false
	self.minimizable = minimizable ~= false

	self.hoveredButton = nil
	self.pressedButton = nil

	self.children = {}
	self.onClose = nil
end

function Window:add(child)
	table.insert(self.children, child)
	return child
end

function Window:remove(child)
	table.delete(self.children, child)
	return child
end

function Window:update(dt)
	if self.closed or not self.visible then return end
	Window.super.update(self, dt)

	local mx, my = getMousePos(self)
	local buttonSize = self.titleBarHeight - 8

	self.hoveredButton = nil
	local btnRight = self.x + self.width - 4
	if self.closable then
		local bx, by = btnRight - buttonSize, self.y + 4
		if mx >= bx and mx <= bx + buttonSize and my >= by and my <= by + buttonSize then
			self.hoveredButton = "close"
		end
		btnRight = bx - 4
	end
	if self.minimizable and not self.hoveredButton then
		local bx, by = btnRight - buttonSize, self.y + 4
		if mx >= bx and mx <= bx + buttonSize and my >= by and my <= by + buttonSize then
			self.hoveredButton = "minimize"
		end
	end

	if self.hoveredButton then
		if game.mouse.justPressedLeft then
			self.pressedButton = self.hoveredButton
		elseif game.mouse.justReleasedLeft and self.pressedButton == self.hoveredButton then
			if self.pressedButton == "close" then
				self.closed = true
				if self.onClose then self.onClose() end
			elseif self.pressedButton == "minimize" then
				self.minimized = not self.minimized
			end
			self.pressedButton = nil
		elseif not game.mouse.pressedLeft then
			self.pressedButton = nil
		end
	else
		if not game.mouse.pressedLeft then
			self.pressedButton = nil
		end
		if game.mouse.justPressedLeft and mx >= self.x and mx <= self.x + self.width and
			my >= self.y and my <= self.y + self.titleBarHeight then
			self.isDragging = true
			self.dragOffsetX = mx - self.x
			self.dragOffsetY = my - self.y
		end
	end

	if self.isDragging then
		if game.mouse.pressedLeft then
			self.x = mx - self.dragOffsetX
			self.y = my - self.dragOffsetY
		else
			self.isDragging = false
		end
	end

	if not self.minimized then
		local ox = (self.__uiOffsetX or 0) + self.x
		local oy = (self.__uiOffsetY or 0) + self.y + self.titleBarHeight
		for _, child in ipairs(self.children) do
			if child and child.exists and child.active then
				child.__uiOffsetX = ox
				child.__uiOffsetY = oy
				if self.cameras and not child.cameras then
					child.cameras = self.cameras
				end
				child:update(dt)
			end
		end
	end
end

function Window:__render(camera)
	if self.closed or not self.visible then return end

	local r, g, b, a = love.graphics.getColor()
	local lineWidth = love.graphics.getLineWidth()
	local prevFont = love.graphics.getFont()

	local x = self.x - self.offset.x - (camera.scroll.x * self.scrollFactor.x)
	local y = self.y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)
	local w = self.width
	local h = self.minimized and self.titleBarHeight or self.height
	local font = self.font or prevFont
	love.graphics.setFont(font)

	love.graphics.setColor(self.bgColor[1], self.bgColor[2], self.bgColor[3], 0.96 * self.alpha)
	love.graphics.rectangle("fill", x, y, w, h, 4, 4)

	love.graphics.setColor(self.titleBarColor[1], self.titleBarColor[2],
		self.titleBarColor[3], self.alpha)
	love.graphics.rectangle("fill", x, y, w, self.titleBarHeight, 4, 4)

	love.graphics.setColor(self.borderColor[1], self.borderColor[2],
		self.borderColor[3], self.alpha)
	love.graphics.setLineWidth(self.borderSize)
	love.graphics.rectangle("line", x, y, w, h, 4, 4)

	love.graphics.setColor(self.textColor[1], self.textColor[2],
		self.textColor[3], self.alpha)
	love.graphics.print(tostring(self.title or ""), x + 8,
		y + (self.titleBarHeight - font:getHeight()) * 0.5)

	local buttonSize = self.titleBarHeight - 8
	local btnRight = x + w - 4
	if self.closable then
		local bx, by = btnRight - buttonSize, y + 4
		local col = (self.hoveredButton == "close") and self.buttonHoveredColor or self.buttonColor
		love.graphics.setColor(col[1], col[2], col[3], self.alpha)
		love.graphics.rectangle("fill", bx, by, buttonSize, buttonSize, 2, 2)
		love.graphics.setColor(1, 1, 1, self.alpha)
		love.graphics.printf("X", bx, by + (buttonSize - font:getHeight()) * 0.5, buttonSize, "center")
		btnRight = bx - 4
	end
	if self.minimizable then
		local bx, by = btnRight - buttonSize, y + 4
		local col = (self.hoveredButton == "minimize") and Color.fromRGB(90, 90, 120) or self.buttonColor
		love.graphics.setColor(col[1], col[2], col[3], self.alpha)
		love.graphics.rectangle("fill", bx, by, buttonSize, buttonSize, 2, 2)
		love.graphics.setColor(1, 1, 1, self.alpha)
		love.graphics.printf(self.minimized and "+" or "-", bx,
			by + (buttonSize - font:getHeight()) * 0.5, buttonSize, "center")
	end

	if not self.minimized then
		love.graphics.push()
		love.graphics.translate(x, y + self.titleBarHeight)
		for _, child in ipairs(self.children) do
			if child and child:_canDraw() then
				local pa = child.alpha
				child.alpha = pa * self.alpha
				child:__render(camera)
				child.alpha = pa
			end
		end
		love.graphics.pop()
	end

	love.graphics.setFont(prevFont)
	love.graphics.setColor(r, g, b, a)
	love.graphics.setLineWidth(lineWidth)
end

return Window
