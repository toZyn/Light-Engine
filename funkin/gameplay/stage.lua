local Stage = Group:extend("Stage")

function Stage:new(name)
	Stage.super.new(self)
	self.name = name
	if name == "" then return end

	local path, noScript, noData = "stages/" .. name
	if paths.exists(paths.getPath("data/" .. path .. ".lua"), "file") then
		self.script = Script("data/" .. path, nil, true)
		self.script:linkObject(self)
		self.script:set("SCRIPT_PATH", path .. "/")
		self.script:set("self", self)

		local list = self.script:call("preload")
		if list and type(list) == "table" then
			paths.async.loadBatch(list)
		end
	else
		noScript = true
	end

	self.data = Parser.getStage(self.name)
	noData = self.data == false

	if self.data then
		local list = {}
		for _, prop in pairs(self.data.props) do
			if prop.assetPath:sub(1, 1) ~= '#' then
				table.insert(list, {"image", path .. "/" .. prop.assetPath})
			end
		end
		paths.async.loadBatch(list)
	end

	if noData and noScript then
		Logger.log("error", "No stage found for " .. name)
	end
end

function Stage:load()
	local data = self.data or Parser.getDummyStage()
	self.camZoom, self.camSpeed, self.camZoomSpeed = data.cameraZoom or 0.4, 1, 1

	self.boyfriendPos = Point(770, 100)
	self.gfPos = Point(400, 130)
	self.dadPos = Point(100, 100)

	self.boyfriendCam = Point(-100, -100)
	self.gfCam = Point()
	self.dadCam = Point(150, -100)

	for char, data in pairs(data.characters) do
		local c = char == "bf" and "boyfriend" or char
		if data.position then self[c .. "Pos"]:set(unpack(data.position)) end
		if data.cameraOffsets then self[c .. "Cam"]:set(unpack(data.cameraOffsets)) end
	end

	self.foreground = Group()

	if self.script then
		self.script:linkObject(game.getState())
		self.script:set("state", game.getState())
		self.script:linkObject(self) -- link this back so playstate doesnt overrides
		self.script:call("create")
	end

	local characters = {
		gf = {"gfVersion", "gf", false, 100},
		dad = {"player2", "dad", false, 300},
		bf = {"player1", "boyfriend", true, 200}
	}
	for n, props in pairs(characters) do
		local key, name, player, z, scroll = unpack(props)
		local char, pos = PlayState.SONG[key], self[name .. "Pos"]
		if char and char ~= "" then
			self[name] = Character(pos.x, pos.y, char, player)
			local character = self[name]
			character.scrollFactor:set(scroll or 1, scroll or 1)
			character.zIndex = data.characters[n] and data.characters[n].zIndex or z
			local scale = data.characters[n] and data.characters[n].scale or 1
			character.scale:mul(scale)
			self:add(character)

			character:dance()
			if character.type == "VSlice" then
				character:updateHitbox()
				character.x = character.x - character.width / 2
				character.y = character.y - character.height
			end
		end
	end
	if self.gf and self.dad and self.dad.char:startsWith("gf") then
		self.gf.visible = false
		self.dad:setPosition(self.gf.x, self.gf.y)
	end

	if self.data then
		self:generateStage()
	end

	self:refresh()
end

function Stage:generateStage()
	local path = "stages/" .. self.name .. '/'

	for _, prop in pairs(self.data.props) do
		local instance
		local isAnimated = prop.animations and next(prop.animations)

		if isAnimated then
			instance = Sprite(prop.position[1], prop.position[2])
			instance:setFrames(paths.getAtlas(path .. prop.assetPath))
			for _, anim in pairs(prop.animations) do
				local name = anim.name
				if anim.frameIndices then
					instance.animation:addByIndices(name, anim.prefix or '', anim.frameIndices, nil, anim.frameRate or 24, anim.looped or false)
				else
					instance.animation:addByPrefix(name, anim.prefix or '', anim.frameRate or 24, anim.looped or false)
				end
				if anim.offsets then
					local anima = instance.animation:get(name)
					if anima then anima.offset:set(anim.offsets[1], anim.offsets[2]) end
				end
			end
			instance.animation:play(prop.startingAnimation or "danceLeft", true)
		elseif prop.assetPath:sub(1, 1) == '#' then
			instance = Graphic(prop.position[1], prop.position[2], prop.scale[1] or 1.0, prop.scale[2] or 1.0)
			instance.color = Color.fromString(prop.assetPath or Color.BLACK)
		else
			instance = Sprite(prop.position[1], prop.position[2], paths.getImage(path .. prop.assetPath))
		end

		instance.scale:set(prop.scale[1] or 1, prop.scale[2] or 1)
		instance.flipX, instance.flipY = prop.flipX or false, prop.flipY or false
		instance.scrollFactor:set(prop.scroll[1] or 1, prop.scroll[2] or 1)
		instance.name, instance.zIndex = prop.name, prop.zIndex or 0
		instance.blend = prop.blend or instance.blend
		instance.alpha = prop.alpha or 1

		self:add(instance)
		if self.script then
			self.script:set(prop.name, instance)
		end
	end
end

function Stage:refresh()
	self:sort(function(a, b) return (a.zIndex or 0) < (b.zIndex or 0) end)
end

function Stage:add(obj, foreground)
	if foreground then
		return self.foreground:add(obj)
	end
	Stage.super.add(self, obj)
	if not obj.zIndex then obj.zIndex = #self.members end
end

function Stage:fitViewport(camera)
	camera = camera or game.camera
	if not camera or self.cameraBounds == false then return end

	if camera.syncPixelPerfectWidth then
		camera:syncPixelPerfectWidth()
	end
	if game.cameras and game.cameras.list then
		for _, cam in ipairs(game.cameras.list) do
			if cam ~= camera and cam.syncPixelPerfectWidth then
				cam:syncPixelPerfectWidth()
			end
		end
	end

	local isPixelCam = camera.pixelPerfect and camera.height > 0 and camera.height < game.height
	local k = isPixelCam and (camera.__pixelScaleDivisor or math.max(1, math.floor(Project.height / camera.height + 0.5))) or 1
	local baseW = isPixelCam and math.floor(Project.width / k) or Project.width
	local baseH = isPixelCam and camera.height or Project.height
	local extraW = math.max(0, camera.width - baseW)
	local baseZoom = math.max(0.25, tonumber(self.camZoom) or 0.9)

	local refX, refCount = 0, 0
	for _, ch in ipairs({self.dad, self.gf, self.boyfriend}) do
		if ch and ch.exists ~= false and ch.getMidpoint then
			local mx = ch:getMidpoint()
			if type(mx) == "number" and mx == mx then
				refX = refX + mx
				refCount = refCount + 1
			end
		end
	end
	refX = refCount > 0 and (refX / refCount) or (baseW * 0.5)

	local minGroundW = baseW * 1.05
	local minSkyW = baseW * 0.75
	local envMinX, envMaxX = nil, nil
	local envMinY, envMaxY = nil, nil

	for _, m in ipairs(self.members or {}) do
		if m and m ~= self.boyfriend and m ~= self.dad and m ~= self.gf
			and m.members == nil
			and m.exists ~= false and m.visible ~= false
			and (tonumber(m.alpha) or 1) > 0.05
			and m.scrollFactor ~= nil and m.getWorldBounds ~= nil
			and not (Trail and m.is and m:is(Trail)) then

			if m.__stageOrigX == nil then
				m.__stageOrigX = m.x
				m.__stageOrigY = m.y
				if m.scale then
					m.__stageOrigScaleX = m.scale.x
					m.__stageOrigScaleY = m.scale.y
				end
			else
				m.x = m.__stageOrigX
				m.y = m.__stageOrigY
				if m.scale and m.__stageOrigScaleX then
					m.scale:set(m.__stageOrigScaleX, m.__stageOrigScaleY)
					if m.getWidth and m.updateHitbox then pcall(m.updateHitbox, m) end
				end
			end

			local sfx = tonumber(m.scrollFactor.x) or 1
			local sfy = tonumber(m.scrollFactor.y) or 1
			local okB, bx, by, bw, bh = pcall(m.getWorldBounds, m)
			if not okB then bx, by, bw, bh = nil, nil, nil, nil end

			if bw and bh and bw >= minSkyW and bh > 0 then
				if extraW > 0 and sfx < 0.99 then
					local shiftX = extraW * 0.5 * (1 - sfx)
					m.x = m.x + shiftX
					bx = bx + shiftX
				end

				if extraW > 0 and sfx <= 0.45 and m.scale then
					local cx, cy = bx + bw * 0.5, by + bh * 0.5
					local halfSpan = (camera.width * 0.5) / (baseZoom * 0.90) + math.abs(sfx) * (isPixelCam and 30 or 240)
					local needW = (halfSpan + math.abs(cx - camera.width * 0.5)) * 2
					if bw < needW then
						local ratio = needW / bw
						m.scale:set(m.scale.x * ratio, m.scale.y * ratio)
						if m.getWidth and m.updateHitbox then m:updateHitbox() end
						local nbx, nby, nbw, nbh = m:getWorldBounds()
						if nbw and nbw > 0 then
							m.x = m.x + (cx - (nbx + nbw * 0.5))
							m.y = m.y + (cy - (nby + nbh * 0.5))
							bx, by, bw, bh = m:getWorldBounds()
						end
					end
				end

				if sfx >= 0.85 and bw >= minGroundW and bx <= refX and (bx + bw) >= refX then
					local padX = (m.shader ~= nil) and math.ceil(bw * 0.018) or 0
					local padY = (m.shader ~= nil) and math.ceil(bh * 0.025) or 0
					local gx1, gx2 = bx + padX, bx + bw - padX
					if gx2 > gx1 then
						envMinX = envMinX and math.min(envMinX, gx1) or gx1
						envMaxX = envMaxX and math.max(envMaxX, gx2) or gx2
					end
					if sfy >= 0.85 then
						local gy2 = by + bh - padY
						envMaxY = envMaxY and math.max(envMaxY, gy2) or gy2
						if bh >= baseH * 0.95 then
							local gy1 = by + padY
							envMinY = envMinY and math.min(envMinY, gy1) or gy1
						end
					end
				end
			end
		end
	end

	if type(self.cameraBounds) == "table" and self.cameraBounds.custom then
		envMinX = self.cameraBounds.minX
		envMaxX = self.cameraBounds.maxX
		envMinY = self.cameraBounds.minY
		envMaxY = self.cameraBounds.maxY
	end

	camera.minScrollX = envMinX
	camera.maxScrollX = envMaxX
	camera.minScrollY = envMinY
	camera.maxScrollY = envMaxY

	local minZoom = nil
	if envMinX and envMaxX and (envMaxX - envMinX) > 0 then
		minZoom = camera.width / (envMaxX - envMinX)
	end
	if envMinY and envMaxY and (envMaxY - envMinY) > 0 then
		local minZoomY = camera.height / (envMaxY - envMinY)
		minZoom = minZoom and math.max(minZoom, minZoomY) or minZoomY
	end
	camera.minZoom = minZoom
	if minZoom and type(self.camZoom) == "number" and self.camZoom < minZoom then
		self.camZoom = minZoom
	end
end

return Stage
