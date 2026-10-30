---@class UIDropDown:Object
local Dropdown = Object:extend("UIDropDown")

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

local function truncateText(font, str, maxW)
	str = tostring(str or "")
	if maxW <= 0 or font:getWidth(str) <= maxW then return str end
	for i = #str - 1, 1, -1 do
		local candidate = str:sub(1, i) .. ".."
		if font:getWidth(candidate) <= maxW then
			return candidate
		end
	end
	return ""
end

function Dropdown:new(x, y, options, onChanged, selected, width, height)
	Dropdown.super.new(self, x, y)

	if onChanged ~= nil and type(onChanged) ~= "function" then
		-- Support Dropdown(x, y, options, selected, width, height, callback)
		local cb = height
		height = width
		width = selected
		selected = onChanged
		onChanged = type(cb) == "function" and cb or nil
	end

	self.width = width or 120
	self.height = height or 22

	self.options = options and table.clone(options) or {}
	self.items = self.options
	self.selectedOption = 1
	self.curSelected = 1
	self.selectedLabel = self.options[1] or ""
	self.label = {content = self.selectedLabel}
	self.isOpen = false
	self.hovered = false
	self.hoveredRow = nil

	self.color = Color.fromRGB(42, 40, 54)
	self.hoveredColor = Color.fromRGB(58, 56, 74)
	self.optionColor = Color.fromRGB(32, 30, 42)
	self.optionHoverColor = Color.fromRGB(72, 108, 178)
	self.optionSelectedColor = Color.fromRGB(50, 74, 124)
	self.borderColor = {0.8, 0.8, 0.88}
	self.borderSize = 1

	self.font = love.graphics.getFont()
	self.textColor = {1, 1, 1}

	self.onChanged = onChanged
	self.callback = onChanged
	self.__maxShow = 8
	self.curScroll = 0

	if selected ~= nil then
		self:selectOption(selected, false)
	end
end

function Dropdown:setOptions(options, selected)
	self.options = options and table.clone(options) or {}
	self.items = self.options
	self.curScroll = 0
	if selected ~= nil then
		self:selectOption(selected, false)
	elseif self.options[1] ~= nil then
		self.selectedOption = math.clamp(self.selectedOption or 1, 1, #self.options)
		self.curSelected = self.selectedOption
		self.selectedLabel = tostring(self.options[self.selectedOption] or "")
		self.label.content = self.selectedLabel
	else
		self.selectedOption = 1
		self.curSelected = 1
		self.selectedLabel = ""
		self.label.content = ""
	end
end

Dropdown.setItems = Dropdown.setOptions

function Dropdown:setSelected(value, notify)
	self:selectOption(value, notify == true)
end

function Dropdown:selectOption(value, notify)
	if value == nil then return end
	if type(value) == "number" then
		local idx = math.clamp(math.floor(value), 1, math.max(1, #self.options))
		self.selectedOption = idx
		self.curSelected = idx
		self.selectedLabel = tostring(self.options[idx] or "")
	else
		local strVal = tostring(value)
		local found = table.find(self.options, strVal)
		if found then
			self.selectedOption = found
			self.curSelected = found
			self.selectedLabel = strVal
		else
			self.selectedLabel = strVal
		end
	end
	self.label.content = self.selectedLabel
	local cb = self.callback or self.onChanged
	if notify and cb and self.selectedLabel ~= "" then
		cb(self.selectedLabel, self.selectedOption)
	end
end

function Dropdown:containsPoint(mx, my)
	if mx >= self.x and mx <= self.x + self.width and
		my >= self.y and my <= self.y + self.height then
		return true
	end
	if self.isOpen and #self.options > 0 then
		local visCount = math.min(#self.options, self.__maxShow)
		local listH = visCount * self.height
		if mx >= self.x and mx <= self.x + self.width and
			my >= self.y + self.height and my <= self.y + self.height + listH then
			return true
		end
	end
	return false
end

function Dropdown:update(dt)
	Dropdown.super.update(self, dt)
	if not self.visible then
		self.isOpen = false
		self.hovered = false
		return
	end

	local mx, my = getMousePos(self)
	self.hovered = (mx >= self.x and mx <= self.x + self.width and
		my >= self.y and my <= self.y + self.height)

	self.hoveredRow = nil
	local visCount = math.min(#self.options, self.__maxShow)

	if self.isOpen and visCount > 0 then
		if game.mouse.wheel ~= 0 and self:containsPoint(mx, my) then
			local maxScroll = math.max(0, #self.options - visCount)
			self.curScroll = math.clamp(self.curScroll - game.mouse.wheel, 0, maxScroll)
		end

		if mx >= self.x and mx <= self.x + self.width and
			my >= self.y + self.height and my < self.y + self.height * (1 + visCount) then
			local row = math.floor((my - (self.y + self.height)) / self.height) + 1
			if row >= 1 and row <= visCount then
				self.hoveredRow = row
			end
		end
	end

	if game.mouse.justPressedLeft then
		if self.hovered then
			self.isOpen = not self.isOpen
		elseif self.isOpen and self.hoveredRow then
			local optIdx = self.hoveredRow + self.curScroll
			if self.options[optIdx] ~= nil then
				self:selectOption(optIdx, true)
			end
			self.isOpen = false
		else
			self.isOpen = false
		end
	elseif self.isOpen and game.keys.justPressed.ESCAPE then
		self.isOpen = false
	end
end

function Dropdown:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local lineWidth = love.graphics.getLineWidth()
	local prevFont = love.graphics.getFont()

	local x, y = self.x - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		self.y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)
	local width, height = self.width, self.height
	local bs = self.borderSize
	local font = self.font or prevFont
	love.graphics.setFont(font)

	local bgCol = (self.hovered or self.isOpen) and self.hoveredColor or self.color

	love.graphics.setColor(self.borderColor[1], self.borderColor[2],
		self.borderColor[3], self.alpha)
	love.graphics.rectangle("fill", x, y, width, height, 3, 3)

	love.graphics.setColor(bgCol[1], bgCol[2], bgCol[3], self.alpha)
	love.graphics.rectangle("fill", x + bs, y + bs, width - bs * 2, height - bs * 2, 2, 2)

	local arrowW = height
	local textMaxW = math.max(10, width - arrowW - 8)
	local label = self.selectedLabel ~= "" and self.selectedLabel or (self.options[self.selectedOption] or "-")
	love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.alpha)
	love.graphics.print(truncateText(font, label, textMaxW), x + 5,
		y + (height - font:getHeight()) * 0.5)

	-- Draw dropdown arrow indicator
	local ax = x + width - arrowW * 0.5
	local ay = y + height * 0.5
	if self.isOpen then
		love.graphics.polygon("fill", ax - 4, ay + 2, ax + 4, ay + 2, ax, ay - 3)
	else
		love.graphics.polygon("fill", ax - 4, ay - 2, ax + 4, ay - 2, ax, ay + 3)
	end

	if self.isOpen and #self.options > 0 then
		local visCount = math.min(#self.options, self.__maxShow)
		local listH = visCount * height
		local ly = y + height

		love.graphics.setColor(self.borderColor[1], self.borderColor[2],
			self.borderColor[3], self.alpha)
		love.graphics.rectangle("fill", x, ly, width, listH + bs, 2, 2)

		local hasScroll = #self.options > visCount
		local rowTextW = math.max(10, width - (hasScroll and 14 or 8))

		for row = 1, visCount do
			local idx = row + self.curScroll
			local ry = ly + (row - 1) * height
			local rowCol = self.optionColor
			if row == self.hoveredRow then
				rowCol = self.optionHoverColor
			elseif idx == self.selectedOption then
				rowCol = self.optionSelectedColor
			end

			love.graphics.setColor(rowCol[1], rowCol[2], rowCol[3], self.alpha)
			love.graphics.rectangle("fill", x + bs, ry, width - bs * 2, height - (row == visCount and bs or 0))

			love.graphics.setColor(self.textColor[1], self.textColor[2], self.textColor[3], self.alpha)
			love.graphics.print(truncateText(font, self.options[idx], rowTextW),
				x + 5, ry + (height - font:getHeight()) * 0.5)
		end

		if hasScroll then
			local trackH = listH - 4
			local barH = math.max(12, trackH * (visCount / #self.options))
			local maxScroll = math.max(1, #self.options - visCount)
			local barY = ly + 2 + (trackH - barH) * (self.curScroll / maxScroll)
			love.graphics.setColor(1, 1, 1, 0.2 * self.alpha)
			love.graphics.rectangle("fill", x + width - 6, ly + 2, 4, trackH, 2, 2)
			love.graphics.setColor(1, 1, 1, 0.75 * self.alpha)
			love.graphics.rectangle("fill", x + width - 6, barY, 4, barH, 2, 2)
		end
	end

	love.graphics.setFont(prevFont)
	love.graphics.setColor(r, g, b, a)
	love.graphics.setLineWidth(lineWidth)
end

return Dropdown
