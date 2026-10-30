local DialogueBox = SpriteGroup:extend("DialogueBox")

local function dispatchAnims(spr, data)
	for _, anim in ipairs(data) do
		local name, prefix, indices, offset, fps, loop =
			unpack(anim)

		if #indices > 0 then
			spr.animation:addByIndices(name, prefix, indices, nil, fps, loop)
		else
			spr.animation:addByPrefix(name, prefix, fps, loop)
		end
		if offset then
			local anim = spr.animation:get(name)
			if anim then anim.offset:set(unpack(offset)) end
		end
	end
end

function DialogueBox:onFinishAnim(name)
	if self.animation:has(name .. "-loop") then
		self.animation:play(name .. "-loop")
	elseif name == "enter" and self.animation:has("loop") then
		self.animation:play("loop")
	end
	self:updateHitbox()
end

function DialogueBox:onCharFinishAnim(name)
	if self.finished and self.animation:has(name .. "-loop") then
		self.animation:play(name .. "-loop")
	elseif not self.finished then
		self.animation:play(name, true)
	end
end

function DialogueBox:new(box, anim, song, ...)
	DialogueBox.super.new(self)
	self.scrollFactor:set(0, 0)
	self._layoutOffsetX = ((game.width or 1280) - (Project and Project.width or 1280)) / 2

	local path = "data/dialogue/boxes/" .. box
	self.jsonData = paths.getJSON(path)

	song = paths.formatToSongPath(song)

	self.script = Script(path, false)
	self.script:linkObject(self)
	self.script:set("self", self)
	self.script:call("create", box, anim, song, ...)

	self.characters, self.box = SpriteGroup(), SpriteGroup()
	self.characters.visible, self.box.visible = false, false
	self:add(self.characters); self:add(self.box)

	self:loadBox(anim)

	self.dialogues = {}
	self.jsonCache = {}

	if love.system.getDevice() == "Mobile" then
		self.button = VirtualPad("return", 0, 0, game.width, game.height, false)
		self.button.onPress:add(function()
			self._virtualAcceptPending = true
		end)
		self:add(self.button)
	end

	self.started, self.finished, self.allFinished = false, false, false
	self._closed = false
	self:syncMobileButton()

	local read = love.filesystem.read
	local file = read(paths.getPath("songs/" .. song .."/dialogue.txt"))
	if not file or file == "" then
		print("[DialogueBox] No dialogue file found for " .. song .. ", closing dialogue")
		return self:closeDialogue()
	end
	self.curDialogue = 1
	self.dialogueDelay = 0.3
	self:splitDialogues(file)

	local event = self.script:call("postCreate")
	if event ~= Script.Event_Cancel then
		self:startDialogue()
	end
end

function DialogueBox:loadBox(anim)
	local event = self.script:call("onLoadBox", anim)
	if event == Script.Event_Cancel then return end

	local data = self.jsonData[anim] or self.jsonData.default
	self.curBoxAnim = anim
	self.curBoxData = data
	local offsetX = ((game.width or 1280) - (Project and Project.width or 1280)) / 2
	self._layoutOffsetX = offsetX

	local isNewBoxSpr = self.boxSpr == nil
	self.boxSpr = self.boxSpr or Sprite()
	self.boxSpr.scale:set(1, 1)
	self.boxSpr.animation:reset()
	if data.animations then
		self.boxSpr:setFrames(paths.getAtlas("dialogue/boxes/" .. data.sprite))
		dispatchAnims(self.boxSpr, data.animations)
		self.boxSpr.animation:play("enter")
		if not self.boxSpr._dialogueFinishBound then
			self.boxSpr.animation.onFinish:add(bind(self.boxSpr, self.onFinishAnim))
			self.boxSpr._dialogueFinishBound = true
		end
	else
		self.boxSpr:loadTexture(paths.getImage("dialogue/boxes/" .. data.sprite))
		self.boxSpr.frames = nil
	end

	if data.scale and data.scale ~= 1 then
		self.boxSpr.scale:set(data.scale, data.scale)
	end
	self.boxSpr.antialiasing = data.antialiasing == nil and true or data.antialiasing
	self.boxSpr:updateHitbox()

	self.boxSpr.y = 0
	self.boxSpr:screenCenter('x')
	self.boxSpr.x, self.boxSpr.y = self.boxSpr.x + data.position[1], data.position[2]
	if isNewBoxSpr then self.box:add(self.boxSpr) end

	if data.finishedDialogueSprite then
		local ndata = data.finishedDialogueSprite
		local isNewFinishSpr = self.finishSpr == nil
		local spr = self.finishSpr or Sprite()
		spr.scale:set(1, 1)
		spr.animation:reset()
		spr:setPosition(ndata.position[1] + offsetX, ndata.position[2])
		if ndata.animations then
			spr:setFrames(paths.getAtlas("dialogue/boxes/" .. ndata.sprite))
			dispatchAnims(spr, ndata.animations)
			spr.animation:play("enter")
			if not spr._dialogueFinishBound then
				spr.animation.onFinish:add(bind(spr, self.onFinishAnim))
				spr._dialogueFinishBound = true
			end
		else
			spr:loadTexture(paths.getImage("dialogue/boxes/" .. ndata.sprite))
			spr.frames = nil
		end
		if ndata.scale and ndata.scale ~= 1 then
			spr.scale:set(ndata.scale, ndata.scale)
		end
		spr:updateHitbox()
		spr.visible = false
		spr.antialiasing = ndata.antialiasing == nil and true or ndata.antialiasing
		if isNewFinishSpr then self.box:add(spr) end
		self.finishSpr = spr
	end

	self.skipSound = paths.getSound(data.skipSound)
	self.nextSound = paths.getSound(data.nextSound)
	self.textSound = paths.getSound(data.textSound)

	local function getTextObject(data)
		local kind = data.type or "font"

		local pos = data.position or {100, 100}
		local tx, ty = pos[1] + offsetX, pos[2]
		local color = data.color and Color.fromString(data.color) or Color.WHITE
		local align = data.align or "left"
		local limit = data.limit or game.width * 0.6
		local font = data.font or (kind == "font" and {"vcr.ttf", 16} or {"default", 0.9})
		local fnt, text

		if kind == "font" then
			fnt = paths.getFont(font[1], font[2])
			text = TypeText(tx, ty, "", fnt, color, align, limit)
			if data.outline then
				local kind, size, color, offset = data.outline[1], data.outline[2], data.outline[3]
				if type(size) == "table" then size, offset = 0, {x = size[1], y = size[2]} end
				text:setOutline(kind, size, offset, Color.fromString(color))
			end
			text.sound = self.textSound
		else
			fnt = AtlasText.getFont(font[1], font[2])
			text = AtlasText(tx, ty, "", fnt, limit, align)
			text.color = color
		end
		text.antialiasing = data.antialiasing == nil and true or data.antialiasing
		return text
	end

	if self.text then
		self.box:remove(self.text)
		self.text:destroy()
		self.text = nil
	end
	self.text = getTextObject(data.text)
	self.box:add(self.text)
end

function DialogueBox:startDialogue()
	if self._closed or self.allFinished then return end
	self.curDialogue = self.curDialogue or 0
	local prev = self.dialogues[self.curDialogue - 1]
	local dialogue = self.dialogues[self.curDialogue]
	if not dialogue then return end

	local event = self.script:call("onStartDialogue")
	if event == Script.Event_Cancel then return end

	self.finished = false

	self.characters.visible = true
	if not self.box.visible then
		self.box.visible = true
		if self.boxSpr.animation:has("enter") then self.boxSpr.animation:play("enter") end
	end

	if self.finishSpr then self.finishSpr.visible = false end

	if not prev or prev[3] ~= dialogue[3] then
		self:resetCharacters(dialogue[1])
	end

	local function func()
		if self._closed or self.allFinished or not self.text then return end
		if self.text:is(TypeText) then
			self.text:resetText(dialogue[2])
		else
			self.text:setTyping(dialogue[2], 0.04, self.textSound)
		end
		self.text.completeCallback = function()
			if self._closed then return end
			if self.finishSpr then
				self.finishSpr.visible = true
				if self.finishSpr.animation:has("enter") then
					self.finishSpr.animation:play("enter")
				end
			end
			self.finished = true
		end
		self.started = true
		self.dialogueDelay = 0
	end

	if self.dialogueDelay > 0 then
		Timer.wait(self.dialogueDelay, func)
	else
		func()
	end
end

function DialogueBox:resetCharacters(chars)
	local event = self.script:call("onResetCharacters", chars)
	if event == Script.Event_Cancel then return end

	local offsetX = ((game.width or 1280) - (Project and Project.width or 1280)) / 2
	for _, member in pairs(self.characters.members) do
		member:kill()
	end

	for _, char in ipairs(chars) do
		local spr = self.characters:recycle()

		spr.x, spr.y = char.position[1] + offsetX, char.position[2]
		spr.scale:set(1, 1)
		spr.animation:reset()
		if char.animations then
			spr:setFrames(paths.getAtlas("dialogue/characters/" .. char.sprite))
			dispatchAnims(spr, char.animations)
			spr.animation:play("enter")
			if not spr._dialogueCharFinishBound then
				spr.animation.onFinish:add(bind(spr, self.onCharFinishAnim))
				spr._dialogueCharFinishBound = true
			end
		else
			spr:loadTexture(paths.getImage("dialogue/characters/" .. char.sprite))
			spr.frames = nil
		end
		if char.scale and char.scale ~= 1 then
			spr.scale:set(char.scale, char.scale)
		end
		spr:updateHitbox()
		spr.antialiasing = char.antialiasing ~= false
	end
end

function DialogueBox:getEffectiveScrollFactor()
	local sfx = (self.scrollFactor and self.scrollFactor.x or 0)
		* (self.box and self.box.scrollFactor and self.box.scrollFactor.x or 1)
		* (self.boxSpr and self.boxSpr.scrollFactor and self.boxSpr.scrollFactor.x or 1)
	local sfy = (self.scrollFactor and self.scrollFactor.y or 0)
		* (self.box and self.box.scrollFactor and self.box.scrollFactor.y or 1)
		* (self.boxSpr and self.boxSpr.scrollFactor and self.boxSpr.scrollFactor.y or 1)
	return sfx, sfy
end

function DialogueBox:getLocalHitboxBounds()
	if not self.boxSpr then
		return 0, 0, game.width or 1280, game.height or 720
	end
	local baseX = (self.x or 0) + (self.offset and self.offset.x or 0)
		+ (self.box and self.box.x or 0) + (self.box and self.box.offset and self.box.offset.x or 0)
	local baseY = (self.y or 0) + (self.offset and self.offset.y or 0)
		+ (self.box and self.box.y or 0) + (self.box and self.box.offset and self.box.offset.y or 0)

	local data = self.curBoxData
	local hx, hy, hw, hh
	if data and type(data.hitbox) == "table" and #data.hitbox >= 4 then
		local offsetX = self._layoutOffsetX or 0
		hx = baseX + data.hitbox[1] + offsetX
		hy = baseY + data.hitbox[2]
		hw = data.hitbox[3]
		hh = data.hitbox[4]
	elseif data and type(data.hitboxOffset) == "table" and #data.hitboxOffset >= 4 then
		local sx = math.abs(self.boxSpr.scale.x * self.boxSpr.zoom.x)
		local sy = math.abs(self.boxSpr.scale.y * self.boxSpr.zoom.y)
		hx = baseX + self.boxSpr.x + data.hitboxOffset[1] * sx
		hy = baseY + self.boxSpr.y + data.hitboxOffset[2] * sy
		hw = data.hitboxOffset[3] * sx
		hh = data.hitboxOffset[4] * sy
	else
		hx = baseX + self.boxSpr.x
		hy = baseY + self.boxSpr.y
		hw = self.boxSpr.width
		hh = self.boxSpr.height
	end

	if self.finishSpr and self.finishSpr.visible then
		local fx1 = baseX + self.finishSpr.x
		local fy1 = baseY + self.finishSpr.y
		local fx2 = fx1 + self.finishSpr.width
		local fy2 = fy1 + self.finishSpr.height
		local x2, y2 = hx + hw, hy + hh
		hx = math.min(hx, fx1)
		hy = math.min(hy, fy1)
		hw = math.max(x2, fx2) - hx
		hh = math.max(y2, fy2) - hy
	end

	return hx, hy, hw, hh
end

function DialogueBox:getScreenHitboxBounds(cam)
	local hx, hy, hw, hh = self:getLocalHitboxBounds()
	local camera = cam or (self.cameras and self.cameras[1]) or game.camera
	if not camera or not camera.worldToScreen then
		return hx, hy, hw, hh
	end
	local sfx, sfy = self:getEffectiveScrollFactor()
	local x1, y1 = camera:worldToScreen(hx, hy, sfx, sfy)
	local x2, y2 = camera:worldToScreen(hx + hw, hy, sfx, sfy)
	local x3, y3 = camera:worldToScreen(hx, hy + hh, sfx, sfy)
	local x4, y4 = camera:worldToScreen(hx + hw, hy + hh, sfx, sfy)
	local minX = math.min(x1, x2, x3, x4)
	local maxX = math.max(x1, x2, x3, x4)
	local minY = math.min(y1, y2, y3, y4)
	local maxY = math.max(y1, y2, y3, y4)
	return minX, minY, maxX - minX, maxY - minY
end

function DialogueBox:overlapsPoint(gameX, gameY, cam)
	if self._closed or self.allFinished or not self.box or not self.box.visible then
		return false
	end
	local hx, hy, hw, hh = self:getLocalHitboxBounds()
	local camera = cam or (self.cameras and self.cameras[1]) or game.camera
	local sfx, sfy = self:getEffectiveScrollFactor()
	local wx, wy
	if camera and camera.screenToWorld then
		wx, wy = camera:screenToWorld(gameX, gameY, sfx, sfy)
	else
		wx = gameX + (camera and camera.scroll and camera.scroll.x or 0) * sfx
		wy = gameY + (camera and camera.scroll and camera.scroll.y or 0) * sfy
	end
	return wx >= hx and wx <= hx + hw and wy >= hy and wy <= hy + hh
end

function DialogueBox:syncMobileButton()
	if not self.button then return end
	local sx, sy, sw, sh = self:getScreenHitboxBounds()
	self.button.x, self.button.y = sx, sy
	self.button.width, self.button.height = sw, sh
	self.button.stunned = (self._closed or self.allFinished or not self.started or not self.box or not self.box.visible)
end

function DialogueBox:resize(w, h)
	local newOffsetX = ((game.width or 1280) - (Project and Project.width or 1280)) / 2
	local delta = newOffsetX - (self._layoutOffsetX or 0)
	self._layoutOffsetX = newOffsetX
	if delta ~= 0 then
		if self.boxSpr then self.boxSpr.x = self.boxSpr.x + delta end
		if self.finishSpr then self.finishSpr.x = self.finishSpr.x + delta end
		if self.text then self.text.x = self.text.x + delta end
		if self.characters and self.characters.members then
			for _, m in ipairs(self.characters.members) do
				if m and m.x then m.x = m.x + delta end
			end
		end
	end
	if self.script and not self.script.closed then
		self.script:call("resize", w, h)
	end
	self:syncMobileButton()
end

function DialogueBox:advanceOrSkip()
	if not self.started or self._closed or self.allFinished then return end
	if self.finished and self.curDialogue == #self.dialogues then
		self.allFinished = true
		local event = self.script:call("finishDialogue")
		if event ~= Script.Event_Cancel then
			self:closeDialogue()
		end
	elseif self.finished then
		self.curDialogue = self.curDialogue + 1
		self:startDialogue()
		if self.nextSound then util.playSfx(self.nextSound) end
	else
		self.text:forceEnd()
		if self.skipSound then util.playSfx(self.skipSound) end
	end
end

function DialogueBox:update(dt)
	if self._closed then return end
	self:syncMobileButton()
	self.script:call("update", dt)

	local acceptPressed = controls:pressed("accept")
	if acceptPressed and self._ignoreNextAcceptKey then
		self._ignoreNextAcceptKey = false
		acceptPressed = false
	end

	local virtualPressed = false
	if self._virtualAcceptPending then
		self._virtualAcceptPending = false
		virtualPressed = true
		if not acceptPressed then
			self._ignoreNextAcceptKey = true
		end
	end

	local pointerPressed = false
	if not acceptPressed and not virtualPressed and not (self.button and self.button.pressed) then
		if Mouse and Mouse.justPressedLeft and self:overlapsPoint(Mouse.x, Mouse.y) then
			pointerPressed = true
		elseif Touch and Touch.anyTouchJustPressed then
			for i = 0, Touch.maxTouches - 1 do
				local t = Touch.touches[i]
				if t and t.active and t.justPressed and self:overlapsPoint(t.x, t.y) then
					pointerPressed = true
					break
				end
			end
		end
	end

	if (acceptPressed or virtualPressed or pointerPressed) and self.started then
		self:advanceOrSkip()
	end

	if self._closed then return end
	self:syncMobileButton()
	DialogueBox.super.update(self, dt)
	if self.script and not self.script.closed then
		self.script:call("postUpdate", dt)
	end
end

function DialogueBox:getCachedChar(char, expression)
	if not self.jsonCache[char] then
		self.jsonCache[char] = paths.getJSON("data/dialogue/characters/" .. char)
		self.jsonCache[char].name = char .. expression
	end
	return self.jsonCache[char][expression]
end

function DialogueBox:splitDialogues(data)
	local lines = data:split('\n')
	for i, line in ipairs(lines) do
		if line:match('%S') then
			local stuff = line:split(':')

			local dialogue = stuff[#stuff]
			stuff[#stuff] = nil

			local chars = {}
			for i = 1, #stuff do
				local line = stuff[i]
				local name, expr = line:match("([^.]+)%.?(.*)")
				if not expr or expr == "" then expr = "default" end
				table.insert(chars, self:getCachedChar(name, expr))
			end

			table.insert(self.dialogues, {chars, dialogue, table.concat(stuff)})
		end
	end
end

function DialogueBox:closeDialogue()
	if self._closed then return end
	self._closed = true
	self.allFinished = true
	if self.button then
		self:remove(self.button)
		self.button:destroy()
		self.button = nil
	end
	local onFinish = self.onFinish
	self.onFinish = nil
	if onFinish then onFinish() end
	if self.script and not self.script.closed then
		self.script:close()
	end
	self:destroy()
end

return DialogueBox
