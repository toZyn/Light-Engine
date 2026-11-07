---@class VirtualPad:Graphic
local VirtualPad = Graphic:extend("VirtualPad")
VirtualPad.instances = {}
VirtualPad.active = {}

-- Optional sprite sheet skin (assets/images/ui/virtual-input.png .txt):
-- each button frame is 3 variants wide (idle, pressed, unused) in this order.
VirtualPad.skinAtlas = nil
VirtualPad.skinFramesMap = {}
VirtualPad.skinQuads = {}
VirtualPad.skinKeys = {
	["left"] = "left", ["right"] = "right", ["up"] = "up", ["down"] = "down",
	["return"] = "a", ["escape"] = "b", ["tab"] = "c"
}

local function getSkinAtlas()
	if not (paths and paths.getPackerAtlas) then return nil end
	local okGet, atlas = pcall(paths.getPackerAtlas, "ui/virtual-input")
	if not okGet or type(atlas) ~= "table" then return nil end
	if atlas == VirtualPad.skinAtlas then return atlas end
	-- paths.clearCache() can rebuild atlases; refresh our frame cache then.
	VirtualPad.skinAtlas = atlas
	VirtualPad.skinFramesMap, VirtualPad.skinQuads = {}, {}
	for i = 1, atlas:getFrameCount() do
		local frame = atlas:getFrame(i)
		if frame and frame.name then VirtualPad.skinFramesMap[frame.name] = frame end
	end
	if atlas.texture and atlas.texture.setFilter then
		pcall(atlas.texture.setFilter, atlas.texture, "linear", "linear")
	end
	return atlas
end

function VirtualPad:new(key, x, y, width, height, color)
	VirtualPad.super.new(self, x, y)
	getSkinAtlas()
	self.width = width or 134
	self.height = height or 134
	self.key = key

	if color == false then
		self.visible = false
		color = nil
	end
	self.color = color or Color.fromRGB(28, 26, 40)

	self.scrollFactor:zero()

	self.onPress = Signal()
	self.onRelease = Signal()

	self.pressed = false
	self.pressedAlpha = 1
	self.releasedAlpha = getSkinAtlas() and 0.55 or 0.25

	self.alpha = self.releasedAlpha
	self.stunned = false

	self.lined = true
	self.pressedLineWidth = 4
	self.releasedLineWidth = 2

	self.line.width = self.releasedLineWidth
	self.config.round = {18, 18}
end

function VirtualPad:enter()
	-- not supposed to exist, but it avoids unwanted
	-- presses when the button isn't added to a state or group
	if not table.find(VirtualPad.instances, self) then
		table.insert(VirtualPad.instances, self)
	end
end

local function press(button, id, time)
	if not button or button.pressed then return end
	button.pressed = true
	VirtualPad._press(button.key, time or love.timer.getTime())
	VirtualPad.active[id] = button
	button.onPress:dispatch(button)
end

local function release(button, id, time)
	if not button or not button.pressed then return end
	button.pressed = false
	VirtualPad._release(button.key, time or love.timer.getTime())
	if id ~= nil then
		VirtualPad.active[id] = nil
	end
	button.onRelease:dispatch(button)
end

function VirtualPad:leave()
	if table.find(VirtualPad.instances, self) then
		table.delete(VirtualPad.instances, self)
	end
	for id, actived in pairs(VirtualPad.active) do
		if actived == self then
			release(self, id, love.timer.getTime())
		end
	end
	if self.pressed then
		release(self, nil, love.timer.getTime())
	end
end

local activeTouches = {}
function VirtualPad.updatePress()
	local touches = love.touch.getTouches()
	activeTouches = {}

	for _, id in ipairs(touches) do
		local x, y = love.touch.getPosition(id)
		x, y = VirtualPad.remap(x, y)

		local active = VirtualPad.active[id]
		local found = false

		for i = #VirtualPad.instances, 1, -1 do
			local button = VirtualPad.instances[i]
			if button and button:check(x, y) and not found then
				found = true
				if not active then
					press(button, id)
				elseif active ~= button then
					release(active, id)
					press(button, id)
				end
				activeTouches[id] = true
			elseif active == button then
				release(active, id)
			end
		end

		if not found and active then
			release(active, id)
		end
	end

	for id, button in pairs(VirtualPad.active) do
		if not activeTouches[id] then
			release(button, id)
		end
	end
end

function VirtualPad.press(id, x, y, p, time)
	x, y = VirtualPad.remap(x, y)
	local active = VirtualPad.active[id]
	for i = #VirtualPad.instances, 1, -1 do
		local button = VirtualPad.instances[i]
		if button and button:check(x, y) and not active then
			press(button, id, time)
			break
		end
	end
end

function VirtualPad.release(id, x, y, p, time)
	local active = VirtualPad.active[id]
	if active then release(active, id, time) end
end

function VirtualPad:update(dt)
	if not self.pressed then
		self.alpha = math.lerp(
			self.releasedAlpha, self.alpha, math.exp(-dt * 14.4))
		self.line.width = math.lerp(
			self.releasedLineWidth, self.line.width, math.exp(-dt * 12))
	else
		self.alpha = self.pressedAlpha
		self.line.width = self.pressedLineWidth
	end
end

function VirtualPad:__render(camera)
	local atlas = getSkinAtlas()
	local frame = atlas and VirtualPad.skinFramesMap[VirtualPad.skinKeys[self.key]]
	if not frame then
		return VirtualPad.super.__render(self, camera)
	end

	love.graphics.push("all")

	local x, y, rad, sx, sy, ox, oy, kx, ky = self:setupDrawLogic(camera, false)
	local w, h = self.width, self.height

	local fx, fy, fw, fh = frame.quad:getViewport()
	local sub = math.floor(fw / 3 + 0.5)
	local state = self.pressed and 2 or 1

	local cacheKey = self.key .. state
	local quad = VirtualPad.skinQuads[cacheKey]
	if quad == nil then
		quad = love.graphics.newQuad(fx + sub * (state - 1), fy, sub, fh,
			atlas.texture:getDimensions())
		VirtualPad.skinQuads[cacheKey] = quad
	end

	love.graphics.translate(x, y)
	love.graphics.rotate(rad)
	love.graphics.scale(sx, sy)
	love.graphics.shear(kx, ky)
	love.graphics.translate(-ox, -oy)

	love.graphics.setShader()
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, self.alpha)

	local fit = math.min(w / sub, h / fh)
	love.graphics.draw(atlas.texture, quad,
		(w - sub * fit) / 2, (h - fh * fit) / 2, 0, fit, fit)

	love.graphics.pop()
end

function VirtualPad:destroy()
	VirtualPad.super.destroy(self)
	if table.find(VirtualPad.instances, self) then
		table.delete(VirtualPad.instances, self)
	end
	for id, actived in pairs(VirtualPad.active) do
		if actived == self then
			VirtualPad._release(self.key, love.timer.getTime())
			VirtualPad.active[id] = nil
			break
		end
	end
	self.onPress:destroy()
	self.onRelease:destroy()
end

function VirtualPad:check(x, y)
	if self.exists ~= false and not self.stunned and x >= self.x and x <= self.x + self.width
		and y >= self.y and y <= self.y + self.height then
		return self
	end
	return nil
end

function VirtualPad.remap(x, y)
	local winWidth, winHeight = love.graphics.getDimensions()
	local scale = math.min(winWidth / game.width, winHeight / game.height)
	return (x - (winWidth - scale * game.width) / 2) / scale,
		   (y - (winHeight - scale * game.height) / 2) / scale
end

function VirtualPad.reset()
	for _, o in ipairs(VirtualPad.instances) do
		o:destroy()
	end
end

local keys, sc = {}, {}
function VirtualPad._press(key, time)
	local ok, code = pcall(love.keyboard.getScancodeFromKey, key)
	code = (ok and code) or key
	keys[key], sc[code] = true, true
	love.event.push("keypressed", key, code, false, time)
end

function VirtualPad._release(key, time)
	local ok, code = pcall(love.keyboard.getScancodeFromKey, key)
	code = (ok and code) or key
	keys[key], sc[code] = false, false
	love.event.push("keyreleased", key, code, time)
end

local _ogIsDown = love.keyboard.isDown
function love.keyboard.isDown(...)
	local n = select("#", ...)
	for i = 1, n do
		local k = select(i, ...)
		if k ~= nil and keys[k] then return true end
	end
	if _ogIsDown then
		local ok, res = pcall(_ogIsDown, ...)
		return ok and res or false
	end
	return false
end

local _ogIsScancodeDown = love.keyboard.isScancodeDown
function love.keyboard.isScancodeDown(...)
	local n = select("#", ...)
	for i = 1, n do
		local k = select(i, ...)
		if k ~= nil and sc[k] then return true end
	end
	if _ogIsScancodeDown then
		local ok, res = pcall(_ogIsScancodeDown, ...)
		return ok and res or false
	end
	return false
end

return VirtualPad
