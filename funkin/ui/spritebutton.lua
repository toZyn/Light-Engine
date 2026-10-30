local SpriteButton = Sprite:extend("SpriteButton")

function SpriteButton:new(x, y, key, texture, callback)
	SpriteButton.super.new(self, x, y)
	self.scrollFactor:zero()
	self.key = key or "return"
	self.callback = callback

	if type(texture) == "table" then
		self:setFrames(texture)
	elseif type(texture) == "string" then
		local xmlExists = paths.exists(paths.getPath("images/" .. texture .. ".xml"), "file")
		local txtExists = not xmlExists and paths.exists(paths.getPath("images/" .. texture .. ".txt"), "file")
		if xmlExists or txtExists then
			self:setFrames(paths.getAtlas(texture))
		else
			local img = paths.getImage(texture)
			if img then
				self:loadTexture(img)
			else
				self:loadTexture(texture)
			end
		end
	elseif texture ~= nil then
		self:loadTexture(texture)
	end

	local bw = (self.width and self.width > 0) and self.width or 150
	local bh = (self.height and self.height > 0) and self.height or 150
	self.button = VirtualPad(self.key, self.x, self.y, bw, bh)
	self.button.visible = false
	self._prevBtnSyncX, self._prevBtnSyncY = self.x, self.y
	self._mouseDownInside = false

	self.button.onPress:add(function()
		self:onPress()
	end)
	self.button.onRelease:add(function()
		self:onRelease()
		if self.callback then self.callback(self) end
	end)
	self.button:enter()
end

function SpriteButton:updateHitbox()
	SpriteButton.super.updateHitbox(self)
	if self.button and self.width > 0 and self.height > 0 then
		self.button.width = self.width
		self.button.height = self.height
	end
end

function SpriteButton:enter()
	if SpriteButton.super.enter then SpriteButton.super.enter(self) end
	if self.button then self.button:enter() end
end

function SpriteButton:leave()
	if SpriteButton.super.leave then SpriteButton.super.leave(self) end
	if self.button then self.button:leave() end
end

function SpriteButton:update(dt)
	SpriteButton.super.update(self, dt)
	if self.button then
		if self.x ~= self._prevBtnSyncX then
			self.button.x = self.button.x + (self.x - (self._prevBtnSyncX or 0))
			self._prevBtnSyncX = self.x
		end
		if self.y ~= self._prevBtnSyncY then
			self.button.y = self.button.y + (self.y - (self._prevBtnSyncY or 0))
			self._prevBtnSyncY = self.y
		end
	end

	if not self.visible or self.exists == false or (self.button and self.button.stunned) then
		self._mouseDownInside = false
		return
	end

	if Mouse and not (self.button and self.button.pressed) then
		local over = Mouse.overlaps(self)
		if over and Mouse.justPressedLeft then
			self._mouseDownInside = true
			self:onPress()
		elseif self._mouseDownInside and Mouse.justReleasedLeft then
			self._mouseDownInside = false
			self:onRelease()
			if over and self.callback then
				self.callback(self)
			end
		elseif not Mouse.pressedLeft then
			self._mouseDownInside = false
		end
	end
end

function SpriteButton:onPress() end

function SpriteButton:onRelease() end

function SpriteButton:destroy()
	SpriteButton.super.destroy(self)
	if self.button then
		self.button:leave()
		self.button:destroy()
		self.button = nil
	end
end

return SpriteButton
