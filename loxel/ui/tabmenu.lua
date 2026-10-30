---@class UITabMenu:SpriteGroup
local TabMenu = SpriteGroup:extend("UITabMenu")

local function getScreenMouse(self)
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

function TabMenu:new(x, y, tabs, title, width, height)
	TabMenu.super.new(self, x, y)

	if type(tabs) == "number" and type(title) == "number" then
		-- Support TabMenu(x, y, width, height, tabs, title)
		self.width = tabs
		self.height = title
		tabs = width
		title = height
	elseif type(title) == "number" then
		-- Support TabMenu(x, y, tabs, width, height, title)
		local realTitle = height
		self.width = title
		self.height = width or 380
		title = realTitle
	else
		self.width = width or 340
		self.height = height or 380
	end

	self.tabs = tabs and table.clone(tabs) or {}
	self.groups = {}
	self.selected = 1
	self.hoveredTab = nil
	self.title = title
	self.headerHeight = (#self.tabs > 0 or title) and 28 or 0
	self.tabHeight = self.headerHeight

	self.bgColor = Color.fromRGB(24, 22, 32)
	self.bgAlpha = 0.92
	self.borderColor = Color.fromRGB(92, 90, 118)
	self.tabColor = Color.fromRGB(36, 34, 48)
	self.tabHoverColor = Color.fromRGB(54, 52, 72)
	self.tabActiveColor = Color.fromRGB(72, 108, 178)
	self.textColor = {1, 1, 1}
	self.font = love.graphics.getFont()
	self.onTabChanged = nil
end

function TabMenu:getHeaderOffset()
	if #self.tabs > 0 or (self.title and self.title ~= "") then
		return self.headerHeight
	end
	return 0
end

function TabMenu:addGroup(group, label)
	if not group then return nil end
	table.insert(self.groups, group)
	local idx = #self.groups
	if type(label) == "string" and not self.tabs[idx] then
		self.tabs[idx] = label
	end
	if self.headerHeight == 0 and #self.tabs > 0 then
		self.headerHeight = 28
	end
	self.tabHeight = self.headerHeight
	self:add(group)
	group.visible = (idx == self.selected)
	group.active = (idx == self.selected)
	return group
end

function TabMenu:selectTab(index)
	if #self.groups == 0 and #self.tabs == 0 then return end
	local maxIdx = math.max(#self.groups, #self.tabs)
	index = math.clamp(index, 1, maxIdx)
	if self.selected ~= index then
		-- Close any open dropdown in previous group
		local prevGroup = self.groups[self.selected]
		if prevGroup and prevGroup.members then
			for _, m in ipairs(prevGroup.members) do
				if m then
					m.isOpen = false
					m.focused = false
				end
			end
		end
		self.selected = index
		if self.onTabChanged then
			self.onTabChanged(index, self.tabs[index])
		end
	end
	for i, g in ipairs(self.groups) do
		g.visible = (i == self.selected)
		g.active = (i == self.selected)
	end
end

function TabMenu:hasFocusedInput()
	local activeGroup = self.groups[self.selected]
	if not activeGroup or not activeGroup.members then return false end
	for _, m in ipairs(activeGroup.members) do
		if m and m.focused then return true end
	end
	return false
end

function TabMenu:isMouseOver()
	if not self.visible then return false end
	local mx, my = getScreenMouse(self)
	return mx >= self.x and mx <= self.x + self.width and
		my >= self.y and my <= self.y + self.height
end

local function propagateOffsets(group, ox, oy, cams)
	if not group or not group.members then return end
	for _, m in ipairs(group.members) do
		if m then
			m.__uiOffsetX = ox
			m.__uiOffsetY = oy
			m.offsetX = ox
			m.offsetY = oy
			if cams and not m.cameras then
				m.cameras = cams
			end
			if m.members then
				propagateOffsets(m, ox + (m.x or 0), oy + (m.y or 0), cams)
			end
		end
	end
end

function TabMenu:update(dt)
	if not self.visible or not self.active then return end

	local mx, my = getScreenMouse(self)
	local headerH = self:getHeaderOffset()
	self.hoveredTab = nil

	if #self.tabs > 0 and headerH > 0 then
		local tabCount = #self.tabs
		local tabW = self.width / tabCount
		if mx >= self.x and mx <= self.x + self.width and
			my >= self.y and my <= self.y + headerH then
			local idx = math.clamp(math.floor((mx - self.x) / tabW) + 1, 1, tabCount)
			self.hoveredTab = idx
			if game.mouse.justPressedLeft then
				self:selectTab(idx)
				return
			end
		end
	end

	for i, g in ipairs(self.groups) do
		g.visible = (i == self.selected)
		g.active = (i == self.selected)
	end

	local activeGroup = self.groups[self.selected]
	if activeGroup and activeGroup.members then
		local ox = (self.__uiOffsetX or 0) + self.x + (activeGroup.x or 0)
		local oy = (self.__uiOffsetY or 0) + self.y + headerH + (activeGroup.y or 0)
		propagateOffsets(activeGroup, ox, oy, self.cameras)

		-- Give open dropdown priority so clicks on open options don't trigger buttons below
		local openDropdown = nil
		for _, m in ipairs(activeGroup.members) do
			if m and m.isOpen and m.containsPoint then
				openDropdown = m
				break
			end
		end

		if openDropdown then
			local localMx, localMy = mx - self.x - (activeGroup.x or 0),
				my - self.y - headerH - (activeGroup.y or 0)
			local clickedInDropdown = game.mouse.justPressedLeft and openDropdown:containsPoint(localMx, localMy)
			openDropdown:update(dt)
			if clickedInDropdown then
				-- Update non-click state of other members without letting the click pass through
				local savedJustPressed = game.mouse.justPressedLeft
				local savedJustPressedAny = game.mouse.justPressed
				game.mouse.justPressedLeft = false
				game.mouse.justPressed = false
				for _, m in ipairs(activeGroup.members) do
					if m and m ~= openDropdown and m.exists and m.active then
						m:update(dt)
					end
				end
				game.mouse.justPressedLeft = savedJustPressed
				game.mouse.justPressed = savedJustPressedAny
				return
			end
		end

		for _, m in ipairs(activeGroup.members) do
			if m and m ~= openDropdown and m.exists and m.active then
				m:update(dt)
			end
		end
	end
end

function TabMenu:_canDraw()
	return self.visible and self.exists and self.alpha > 0
end

function TabMenu:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local prevFont = love.graphics.getFont()
	local lineWidth = love.graphics.getLineWidth()

	local x = self.x - self.offset.x - (camera.scroll.x * self.scrollFactor.x)
	local y = self.y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)
	local w, h = self.width, self.height
	local headerH = self:getHeaderOffset()

	-- Panel background & border
	love.graphics.setColor(self.bgColor[1], self.bgColor[2], self.bgColor[3],
		self.bgAlpha * self.alpha)
	love.graphics.rectangle("fill", x, y, w, h, 4, 4)

	love.graphics.setColor(self.borderColor[1], self.borderColor[2],
		self.borderColor[3], self.alpha)
	love.graphics.setLineWidth(1.5)
	love.graphics.rectangle("line", x, y, w, h, 4, 4)

	local font = self.font or prevFont
	love.graphics.setFont(font)

	-- Tab header bar
	if headerH > 0 then
		if #self.tabs > 0 then
			local tabCount = #self.tabs
			local tabW = w / tabCount
			for i = 1, tabCount do
				local tx = x + (i - 1) * tabW
				local col = (i == self.selected) and self.tabActiveColor or
					((i == self.hoveredTab) and self.tabHoverColor or self.tabColor)
				love.graphics.setColor(col[1], col[2], col[3], self.alpha)
				love.graphics.rectangle("fill", tx + 1, y + 1, tabW - 2, headerH - 2, 2, 2)

				love.graphics.setColor(self.textColor[1], self.textColor[2],
					self.textColor[3], (i == self.selected and 1 or 0.8) * self.alpha)
				love.graphics.printf(tostring(self.tabs[i] or ""), tx + 2,
					y + (headerH - font:getHeight()) * 0.5, math.max(1, tabW - 4), "center")
			end
		elseif self.title then
			love.graphics.setColor(self.tabActiveColor[1], self.tabActiveColor[2],
				self.tabActiveColor[3], self.alpha)
			love.graphics.rectangle("fill", x + 1, y + 1, w - 2, headerH - 2, 2, 2)
			love.graphics.setColor(self.textColor[1], self.textColor[2],
				self.textColor[3], self.alpha)
			love.graphics.printf(tostring(self.title), x + 6,
				y + (headerH - font:getHeight()) * 0.5, math.max(1, w - 12), "left")
		end

		love.graphics.setColor(self.borderColor[1], self.borderColor[2],
			self.borderColor[3], self.alpha)
		love.graphics.line(x, y + headerH, x + w, y + headerH)
	end

	-- Active tab content (draw open dropdowns last so they stay on top!)
	local activeGroup = self.groups[self.selected]
	if activeGroup and activeGroup.members then
		love.graphics.push()
		love.graphics.translate(x + (activeGroup.x or 0), y + headerH + (activeGroup.y or 0))

		local deferredDropdowns = nil
		for _, member in ipairs(activeGroup.members) do
			if member and member:_canDraw() then
				if member.isOpen then
					deferredDropdowns = deferredDropdowns or {}
					table.insert(deferredDropdowns, member)
				else
					local pa = member.alpha
					member.alpha = pa * self.alpha
					member:__render(camera)
					member.alpha = pa
				end
			end
		end

		if deferredDropdowns then
			for _, dd in ipairs(deferredDropdowns) do
				local pa = dd.alpha
				dd.alpha = pa * self.alpha
				dd:__render(camera)
				dd.alpha = pa
			end
		end

		love.graphics.pop()
	end

	love.graphics.setFont(prevFont)
	love.graphics.setLineWidth(lineWidth)
	love.graphics.setColor(r, g, b, a)
end

return TabMenu
