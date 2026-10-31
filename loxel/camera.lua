-- TODO: make offsets works me think

---@diagnostic disable: duplicate-set-field
---@class Camera:Object
local Camera = Object:extend("Camera")

local stencilSupport = false
local canvasTable = {nil, stencil = true}

Camera.__defaultCameras = {}
Camera.defaultResolution = 1

function Camera.__init()
	if love.graphics.getTextureFormats then
		stencilSupport = love.graphics.getTextureFormats({canvas = true})["stencil8"]
	else
		local cv = love.graphics.getCanvas()
		stencilSupport = pcall(love.graphics.setCanvas, canvasTable)
		pcall(love.graphics.setCanvas, cv)
	end

	if not stencilSupport then
		Camera.draw = function(self)
			if self.__forceComplex then
				if not self.canvas then
					self:resize(self.width, self.height, self.__resolutionX, self.__resolutionY, true)
				end
				if not self:canDraw() then
					if self.canvas then
						local grap = love.graphics
						local prev = grap.getCanvas()
						local c = self.bgColor
						grap.setCanvas(self.canvas)
						grap.clear(c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 0)
						grap.setCanvas(prev)
					end
					return
				end
				return self:drawComplex(true)
			end
			return self:drawSimple(true)
		end
	end
end

function Camera:new(x, y, width, height)
	Camera.super.new(self, x, y)

	self.simple = true
	self.isSimple = true -- indicates if its in simple render

	-- these will turn complex rendering mode in some cases
	self.clipCam = not Project.flags.loxelDefaultClipCamera == false
	self.antialiasing = true
	self.pixelPerfect = false

	self:resize(
		width and (width > 0 and width) or game.width,
		height and (height > 0 and height) or game.height,
		nil, nil, true
	)

	self.scroll = Point()
	self.scroll.offset = Point()

	self.rotation = 0
	self.angle = 0
	self.zoom = 1

	self.target = nil
	self.followType = nil
	self.followLerp = 0

	self.minScrollX = nil
	self.maxScrollX = nil
	self.minScrollY = nil
	self.maxScrollY = nil
	self.minZoom = nil
	self.__pixelScaleDivisor = nil

	self.bgColor = {0, 0, 0, 0}

	self.__zoom = {x = 1, y = 1}
	self.__renderQueue = {}

	self.__flashColor = Color.WHITE
	self.__flashAlpha = 0
	self.__flashDuration = 0
	self.__flashComplete = nil

	self.__fadeColor = Color.WHITE
	self.__fadeAlpha = 0
	self.__fadeDuration = 0
	self.__fadeComplete = nil
	self.__fadeIn = false

	self.__shakeX = 0
	self.__shakeY = 0
	self.__shakeAxes = 'xy'
	self.__shakeIntensity = 0
	self.__shakeDuration = 0
	self.__shakeComplete = nil

	self.freezed = false
	self.__freeze = false
end

function Camera:shake(intensity, duration, onComplete, force, axes)
	if not force and (self.__shakeDuration > 0) then return end

	self.__shakeAxes = axes or 'xy'
	self.__shakeIntensity = intensity
	self.__shakeDuration = duration or 1
	self.__shakeComplete = onComplete or nil
end

function Camera:flash(color, duration, onComplete, force)
	if not force and (self.__flashAlpha > 0) then return end

	self.__flashColor = color or Color.WHITE
	duration = duration or 1
	if duration <= 0 then duration = 0.000001 end
	self.__flashDuration = duration
	self.__flashComplete = onComplete or nil
	self.__flashAlpha = 1
end

function Camera:fade(color, duration, fadeIn, onComplete, force)
	if not force and (self.__fadeDuration > 0) then return end

	self.__fadeColor = color or Color.BLACK
	duration = duration or 1
	if duration <= 0 then duration = 0.000001 end
	self.__fadeDuration = duration
	self.__fadeComplete = onComplete or nil
	self.__fadeAlpha = fadeIn and 0.999999 or 0.000001
	self.__fadeIn = fadeIn
end

function Camera:follow(target, type, lerp)
	if target == nil then return end

	self.target = target
	self.followType = type --soon
	self.followLerp = lerp
end

function Camera:unfollow(resetType)
	if self.target == nil then return end
	if resetType == nil then resetType = true end

	self.target = nil
	if resetType then
		self.followType = nil
		self.followLerp = nil
	end
end

function Camera:snapToTarget()
	if self.target == nil then return end

	self:syncPixelPerfectWidth()
	self.scroll.x = self.target.x - self.width / 2
	self.scroll.y = self.target.y - self.height / 2
	self:clampScroll()
end

function Camera:freeze()
	self.__freeze = true
	self.freezed = not self.isSimple
end

function Camera:unfreeze()
	self.__freeze = false
	self.freezed = false
end

function Camera:resize(width, height, resX, resY, force)
	resX = resX or Camera.defaultResolution
	resY = resY or resX
	if self.pixelPerfect then resX, resY = 1, 1 end

	local wantCanvas = force or self.__forceComplex or Camera.draw ~= Camera.drawSimple
	if self.width == width and self.height == height
		and self.__resolutionX == resX and self.__resolutionY == resY
		and (not wantCanvas or self.canvas ~= nil) then return end

	self.width, self.height, self.resolutionX, self.resolutionY = width, height, resX, resY
	self.__requestCanvas = not force and self.freezed
	if not self.__requestCanvas and wantCanvas then
		if self.canvas then self.canvas:release() end
		self.__resolutionX, self.__resolutionY, self.canvas = resX, resY, love.graphics.newCanvas(width * resX, height * resY, {
			format = "normal",
			dpiscale = 1,
		})
	end
end

local trunc = function(i) return math.truncate(i, 1) end

function Camera:syncPixelPerfectWidth()
	if not self.pixelPerfect or not Project then return end
	if game.width <= Project.width or self.height <= 0 or self.height >= game.height then return end
	local k = math.floor(Project.height / self.height + 0.5)
	if k >= 2 and math.abs(self.height * k - Project.height) <= k then
		local basePixelW = math.floor(Project.width / k)
		local targetPixelW = math.ceil(game.width / k)
		if (self.width == basePixelW or self.__pixelScaleDivisor == k) and self.width ~= targetPixelW then
			self.__pixelScaleDivisor = k
			self:resize(targetPixelW, self.height, 1, 1, true)
		elseif self.width == targetPixelW and not self.__pixelScaleDivisor then
			self.__pixelScaleDivisor = k
		end
	end
end

function Camera:clampScroll()
	local isnum = type(self.zoom) == "number"
	if self.minZoom and isnum and self.zoom < self.minZoom then
		self.zoom = self.minZoom
	end
	self.__zoom.x = isnum and self.zoom or self.zoom.x
	self.__zoom.y = isnum and self.zoom or self.zoom.y

	if self.minScrollX == nil and self.maxScrollX == nil
		and self.minScrollY == nil and self.maxScrollY == nil then
		return
	end

	local zx = math.abs(self.scale.x * self.__zoom.x)
	local zy = math.abs(self.scale.y * self.__zoom.y)
	local halfW = zx > 0 and (self.width * 0.5) / zx or (self.width * 0.5)
	local halfH = zy > 0 and (self.height * 0.5) / zy or (self.height * 0.5)

	local cx = self.scroll.x + self.width * 0.5
	local cy = self.scroll.y + self.height * 0.5

	if self.minScrollX ~= nil and self.maxScrollX ~= nil then
		if (self.maxScrollX - self.minScrollX) <= halfW * 2 then
			cx = (self.minScrollX + self.maxScrollX) * 0.5
		else
			cx = math.clamp(cx, self.minScrollX + halfW, self.maxScrollX - halfW)
		end
	elseif self.minScrollX ~= nil then
		cx = math.max(cx, self.minScrollX + halfW)
	elseif self.maxScrollX ~= nil then
		cx = math.min(cx, self.maxScrollX - halfW)
	end

	if self.minScrollY ~= nil and self.maxScrollY ~= nil then
		if (self.maxScrollY - self.minScrollY) <= halfH * 2 then
			cy = (self.minScrollY + self.maxScrollY) * 0.5
		else
			cy = math.clamp(cy, self.minScrollY + halfH, self.maxScrollY - halfH)
		end
	elseif self.minScrollY ~= nil then
		cy = math.max(cy, self.minScrollY + halfH)
	elseif self.maxScrollY ~= nil then
		cy = math.min(cy, self.maxScrollY - halfH)
	end

	self.scroll.x = cx - self.width * 0.5
	self.scroll.y = cy - self.height * 0.5
end

function Camera:update(dt)
	self:syncPixelPerfectWidth()
	local isnum = type(self.zoom) == "number"
	self.__zoom.x = isnum and self.zoom or self.zoom.x
	self.__zoom.y = isnum and self.zoom or self.zoom.y

	if self.target then
		local targetX, targetY = self.target.x - self.width / 2, self.target.y - self.height / 2
		-- targetX, targetY = targetX + self.scroll.offset.x,
			-- targetY + self.scroll.offset.y

		if self.followLerp then
			local lerp = 1 - math.exp(-dt * self.followLerp)
			targetX, targetY = math.lerp(self.scroll.x, targetX, lerp),
				math.lerp(self.scroll.y, targetY, lerp)
		end

		-- TODO: follow type
		self.scroll.x, self.scroll.y = targetX, targetY
	end
	self:clampScroll()

	if self.__flashAlpha > 0 then
		self.__flashAlpha = self.__flashAlpha - dt / self.__flashDuration
		if self.__flashAlpha <= 0 and self.__flashComplete ~= nil then
			self.__flashComplete()
		end
	end

	if self.__fadeDuration > 0 then
		if self.__fadeIn then
			self.__fadeAlpha = self.__fadeAlpha - dt / self.__fadeDuration
			if self.__fadeAlpha <= 0 and self.__fadeComplete ~= nil then
				self.__fadeAlpha = 0
				self.__fadeComplete()
				self.__fadeDuration = 0
			end
		else
			self.__fadeAlpha = self.__fadeAlpha + dt / self.__fadeDuration
			if self.__fadeAlpha >= 1 and self.__fadeComplete ~= nil then
				self.__fadeAlpha = 1
				self.__fadeComplete()
				self.__fadeDuration = 0
			end
		end
	end

	self.__shakeX, self.__shakeY = 0, 0
	if self.__shakeDuration > 0 then
		self.__shakeDuration = self.__shakeDuration - dt
		if self.__shakeDuration <= 0 then
			if self.__shakeComplete ~= nil then
				self.__shakeComplete()
			end
		else
			if self.__shakeAxes:find('x') then
				local shakeVal =
					love.math.random(-1, 1) * self.__shakeIntensity * self.width
				self.__shakeX = self.__shakeX + shakeVal * self.__zoom.x
			end

			if self.__shakeAxes:find('y') then
				local shakeVal =
					love.math.random(-1, 1) * self.__shakeIntensity *
					self.height
				self.__shakeY = self.__shakeY + shakeVal * self.__zoom.y
			end
		end
	end
end

function Camera:_getCameraBoundary()
	self:getZoomXY()
	local w, h = self.width, self.height
	return 0, 0, w, h, 1 / math.abs(self.__zoom.x), 1 / math.abs(self.__zoom.y), w / 2, h / 2
end

function Camera:getZoomXY()
	local isnum = type(self.zoom) == "number"
	self.__zoom.x = isnum and self.zoom or self.zoom.x
	self.__zoom.y = isnum and self.zoom or self.zoom.y
	return self.__zoom.x, self.__zoom.y
end

function Camera:worldToScreen(worldX, worldY, sfx, sfy)
	sfx = sfx == nil and 1 or sfx
	sfy = sfy == nil and 1 or sfy
	local w, h = self.width, self.height
	local w2, h2 = w / 2, h / 2
	local zoomX, zoomY = self:getZoomXY()

	local dx = (worldX - self.scroll.x * sfx) - w2
	local dy = (worldY - self.scroll.y * sfy) - h2

	local totalDeg = (self.angle or 0) + (self.rotation or 0)
	if totalDeg ~= 0 then
		local r = math.rad(totalDeg)
		local c, s = math.cos(r), math.sin(r)
		dx, dy = dx * c - dy * s, dx * s + dy * c
	end

	local scx, scy, pScale = 1, 1, 1
	if self.pixelPerfect and w > 0 and h > 0 then
		scx, scy = game.width / w, game.height / h
		pScale = math.min(scx, scy)
	end

	local cx = ((self.clipCam ~= false) and (w2 + self.x) or w2) * scx
	local cy = ((self.clipCam ~= false) and (h2 + self.y) or h2) * scy

	return cx + dx * zoomX * self.scale.x * pScale,
		cy + dy * zoomY * self.scale.y * pScale
end

function Camera:screenToWorld(gameX, gameY, sfx, sfy)
	sfx = sfx == nil and 1 or sfx
	sfy = sfy == nil and 1 or sfy
	local w, h = self.width, self.height
	local w2, h2 = w / 2, h / 2
	local zoomX, zoomY = self:getZoomXY()

	local scx, scy, pScale = 1, 1, 1
	if self.pixelPerfect and w > 0 and h > 0 then
		scx, scy = game.width / w, game.height / h
		pScale = math.min(scx, scy)
	end

	local cx = ((self.clipCam ~= false) and (w2 + self.x) or w2) * scx
	local cy = ((self.clipCam ~= false) and (h2 + self.y) or h2) * scy

	local ex = zoomX * self.scale.x * pScale
	local ey = zoomY * self.scale.y * pScale
	if ex == 0 or ey == 0 then
		return gameX + self.scroll.x * sfx, gameY + self.scroll.y * sfy
	end

	local dx = (gameX - cx) / ex
	local dy = (gameY - cy) / ey

	local totalDeg = (self.angle or 0) + (self.rotation or 0)
	if totalDeg ~= 0 then
		local r = -math.rad(totalDeg)
		local c, s = math.cos(r), math.sin(r)
		dx, dy = dx * c - dy * s, dx * s + dy * c
	end

	return w2 + dx + self.scroll.x * sfx,
		h2 + dy + self.scroll.y * sfy
end

function Camera:canDraw()
	self:getZoomXY()

	return self.visible and self.exists and (self.bgColor[4] and self.bgColor[4] > 0) or ((
			self.freezed or next(self.__renderQueue)
			or self.__flashAlpha > 0 or self.__fadeDuration > 0
		) and
		self.alpha > 0 and (self.scale.x * self.__zoom.x) ~= 0 and
		(self.scale.y * self.__zoom.y) ~= 0)
end

function Camera:draw()
	if self.__freeze then return self:drawComplex(true) end
	if not self:canDraw() then
		if self.__forceComplex and self.canvas then
			local grap = love.graphics
			local prev = grap.getCanvas()
			local c = self.bgColor
			grap.setCanvas(self.canvas)
			grap.clear(c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 0)
			grap.setCanvas(prev)
		end
		return
	end

	local winWidth, winHeight = love.graphics.getDimensions()
	local scale = math.min(winWidth / game.width, winHeight / game.height)
	if self.__forceComplex or self.pixelPerfect or not self.simple or self.shader or (self.antialiasing and
			(self.x ~= math.floor(self.x) or self.y ~= math.floor(self.y) or
				self.scale.x ~= 1 or self.scale.y ~= 1 or
				self.__resolutionX ~= scale or self.__resolutionY ~= scale) or
			scale > 1) or
		self.alpha < 1 or self.rotation ~= 0 then
		if not self.canvas then
			self:resize(self.width, self.height, self.__resolutionX, self.__resolutionY, true)
		end
		self:drawComplex(true)
	else
		self:drawSimple(true)
	end
end

function Camera:destroy()
	Camera.super.destroy(self)
	if self.canvas then self.canvas:release() end
	self.canvas = nil
end

-- Simple Render
local _simpleCamera, _ogSetColor
local function setSimpleColor(r, g, b, a)
	if type(r) == "table" then
		_ogSetColor(_simpleCamera:getMultColor(r[1], r[2], r[3], r[4]))
	else
		_ogSetColor(_simpleCamera:getMultColor(r, g, b, a))
	end
end

function Camera:renderObjects()
	for i, o in ipairs(self.__renderQueue) do
		if type(o) == "function" then
			o(self)
		else
			if o.exists ~= false and type(o.__render) == "function" then o:__render(self) end
			if o.__cameraQueue then table.clear(o.__cameraQueue) end
		end
		self.__renderQueue[i] = nil
	end
end

function Camera:drawSimple(_skipCheck)
	if not _skipCheck and not self:canDraw() then return end
	self:clampScroll()
	self.isSimple = true

	local grap = love.graphics
	local r, g, b, a = grap.getColor()
	local blendMode, alphaMode = grap.getBlendMode()
	local xc, yc, wc, hc = grap.getScissor()

	local x, y, w, h = self.x, self.y, self.width, self.height
	local sx, sy = self.scale.x, self.scale.y
	local w2, h2 = w / 2, h / 2
	local shx, shy = self.__shakeX, self.__shakeY

	_simpleCamera = self
	_ogSetColor, grap.setColor = grap.setColor, setSimpleColor

	game.__pushBoundScissor(w, h, sx, sy)
	if not Project.flags.loxelDisableScissorOnRenderCameraSimple then
		if self.clipCam then
			grap.setScissor(x, y, w, h)
		else
			grap.setScissor(0, 0, w, h)
		end
	end

	grap.push()

	local color = self.bgColor
	if color ~= nil and (not color[4] or color[4] > 0) then
		setSimpleColor(color)
		grap.rectangle("fill", 0, 0, w, h)
		setSimpleColor(r, g, b, a)
	end

	grap.translate(w2 + x + shx, h2 + y + shy)
	grap.scale(self.__zoom.x * sx, self.__zoom.y * sy)
	grap.rotate(math.rad(self.angle + self.rotation))
	grap.translate(-w2, -h2)

	grap.setBlendMode("alpha", "alphamultiply")
	self:renderObjects()

	game.__popBoundScissor()
	grap.pop()

	color = self.__flashColor
	if self.__flashAlpha > 0 then
		setSimpleColor(color[1], color[2], color[3], self.__flashAlpha)
		grap.rectangle("fill", 0, 0, w, h)
	end

	color = self.__fadeColor
	if self.__fadeDuration > 0 then
		setSimpleColor(color[1], color[2], color[3], self.__fadeAlpha)
		grap.rectangle("fill", 0, 0, w, h)
	end

	grap.setColor = _ogSetColor
	grap.setScissor(xc, yc, wc, hc)
	grap.setColor(r, g, b, a)
	grap.setBlendMode(blendMode, alphaMode)
end

function Camera:drawComplex(_skipCheck)
	if not _skipCheck and not self:canDraw() then return end
	self:syncPixelPerfectWidth()
	if self.__requestCanvas and not self.freezed then
		self:resize(self.width, self.height, self.resolutionX, self.resolutionY, true)
	end
	self:clampScroll()
	self.isSimple = false

	local canvas = self.canvas
	local grap = love.graphics
	local r, g, b, a = grap.getColor()
	local shader = grap.getShader()
	local blendMode, alphaMode = grap.getBlendMode()
	local cv = grap.getCanvas()

	local x, y, w, h, resX, resY = self.x, self.y, self.width, self.height, self.__resolutionX, self.__resolutionY

	if self.pixelPerfect then resX, resY = 1, 1 end

	local sx, sy = self.scale.x / resX, self.scale.y / resY
	local w2, h2 = w / 2, h / 2
	local shx, shy = self.__shakeX, self.__shakeY

	if not self.freezed then
		if self.__freeze then
			self.freezed = next(self.__renderQueue) ~= nil
			self.__freeze = self.freezed
		end

		local _, _, anisotropy = canvas:getFilter()
		local mode = self.antialiasing and "linear" or "nearest"

		canvasTable[1] = canvas
		canvas:setFilter(mode, mode, anisotropy)

		local color = self.bgColor
		if stencilSupport then
			grap.setCanvas(canvasTable)
		else
			grap.setCanvas(canvas)
		end
		grap.clear(color[1], color[2], color[3], color[4])
		grap.push(); grap.origin(); game.__literalBoundScissor(w, h, 1, 1)

		grap.scale(resX, resY)

		local px, py
		if self.clipCam then
			px, py = w2 + shx, h2 + shy
		else
			px, py = w2 + x + shx, h2 + y + shy
		end
		grap.translate(px, py)

		grap.rotate(math.rad(self.angle))
		grap.scale(self.__zoom.x, self.__zoom.y)
		grap.translate(-w2, -h2)

		grap.setBlendMode("alpha", "alphamultiply")
		self:renderObjects()

		color = self.__flashColor
		if self.__flashAlpha > 0 then
			if self.clipCam then
				grap.translate(w2 + shx, h2 + shy)
			else
				grap.translate(w2 + x + shx, h2 + y + shy)
			end
			grap.scale(1 / self.__zoom.x, 1 / self.__zoom.y)
			grap.translate(-w2, -h2)
			grap.setColor(color[1], color[2], color[3], self.__flashAlpha)
			grap.rectangle("fill", 0, 0, w, h)
		end

		color = self.__fadeColor
		if self.__fadeDuration > 0 then
			if self.clipCam then
				grap.translate(w2 + shx, h2 + shy)
			else
				grap.translate(w2 + x + self.__shakeX, h2 + y + self.__shakeY)
			end
			grap.scale(1 / self.__zoom.x, 1 / self.__zoom.y)
			grap.translate(-w2, -h2)
			grap.setColor(color[1], color[2], color[3], self.__fadeAlpha)
			grap.rectangle("fill", 0, 0, w, h)
		end

		game.__popBoundScissor()
		grap.pop()

		grap.setCanvas(cv)
	end

	local alpha = self.alpha
	local color = self.color
	grap.setShader(self.shader)
	grap.setBlendMode("alpha", "premultiplied")
	grap.setColor(color[1] * alpha, color[2] * alpha, color[3] * alpha, alpha)

	local filter = self.antialiasing and "linear" or "nearest"
	local cmin, cmag = canvas:getFilter()
	if cmin ~= filter or cmag ~= filter then
		canvas:setFilter(filter, filter)
	end

	local scx, scy = 1, 1
	if self.pixelPerfect then
		scx, scy = game.width / self.width, game.height / self.height
		local scale = self.__pixelScaleDivisor and scy or math.min(scx, scy)
		sx, sy = sx * scale, sy * scale
	end

	if self.clipCam then
		grap.draw(canvas, (w2 + x) * scx, (h2 + y) * scy, math.rad(self.rotation), sx, sy, w2 * resX, h2 * resY)
	else
		grap.draw(canvas, w2 * scx, h2 * scy, math.rad(self.rotation), sx, sy, w2 * resX, h2 * resY)
	end

	grap.setColor(r, g, b, a)
	grap.setBlendMode(blendMode, alphaMode)
	if self.shader then grap.setShader(shader) end
end

function Camera:drawCanvasToTarget(targetW, targetH)
	if not self.exists or not self.visible or self.alpha <= 0 then return false end
	local canvas = self.canvas
	if not canvas then return false end
	self:getZoomXY()
	if (self.scale.x * self.__zoom.x) == 0 or (self.scale.y * self.__zoom.y) == 0 then
		return false
	end

	local grap = love.graphics
	local pr, pg, pb, pa = grap.getColor()
	local prevShader = grap.getShader()
	local prevBlend, prevAlphaMode = grap.getBlendMode()

	local w, h = self.width, self.height
	local w2, h2 = w / 2, h / 2
	local resX, resY = self.__resolutionX or 1, self.__resolutionY or 1
	local sx, sy = self.scale.x / resX, self.scale.y / resY

	local cmin, cmag, aniso = canvas:getFilter()
	local filter = self.antialiasing and "linear" or "nearest"
	if cmin ~= filter or cmag ~= filter then
		canvas:setFilter(filter, filter, aniso)
	end

	local alpha = self.alpha
	local color = self.color
	grap.setShader(self.shader)
	grap.setBlendMode("alpha", "premultiplied")
	grap.setColor(color[1] * alpha, color[2] * alpha, color[3] * alpha, alpha)

	local scx, scy = 1, 1
	if self.pixelPerfect then
		scx, scy = game.width / w, game.height / h
		local pscale = self.__pixelScaleDivisor and scy or math.min(scx, scy)
		sx, sy = sx * pscale, sy * pscale
	end

	local mapX = targetW / game.width
	local mapY = targetH / game.height
	local drawX = (self.clipCam and (w2 + self.x) or w2) * scx * mapX
	local drawY = (self.clipCam and (h2 + self.y) or h2) * scy * mapY

	grap.draw(
		canvas,
		drawX,
		drawY,
		math.rad(self.rotation or 0),
		sx * mapX,
		sy * mapY,
		w2 * resX,
		h2 * resY
	)

	if cmin ~= filter or cmag ~= filter then
		canvas:setFilter(cmin, cmag, aniso)
	end
	grap.setShader(prevShader)
	grap.setColor(pr, pg, pb, pa)
	grap.setBlendMode(prevBlend, prevAlphaMode)
	return true
end

if Project.flags.loxelForceRenderCameraComplex then
	Camera.draw = Camera.drawComplex
elseif Project.flags.loxelDisableRenderCameraComplex then
	Camera.draw = Camera.drawSimple
end

return Camera
