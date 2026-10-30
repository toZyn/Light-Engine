local Touch = {
	touches = {},
	maxTouches = 10,

	idMap = {},
	nextSlot = 0,

	anyTouchJustPressed = false,
	anyTouchPressed = false,
	anyTouchJustReleased = false,
	anyTouchReleased = true,

	isPinching = false,
	pinchDistance = 0,
	prevPinchDistance = 0,
	pinchScale = 1,

	centerX = 0,
	centerY = 0,
	screenCenterX = 0,
	screenCenterY = 0
}

for i = 0, Touch.maxTouches - 1 do
	Touch.touches[i] = {
		id = nil,
		x = 0,
		y = 0,
		screenX = 0,
		screenY = 0,
		deltaX = 0,
		deltaY = 0,
		deltaScreenX = 0,
		deltaScreenY = 0,
		__prevX = 0,
		__prevY = 0,
		__prevScreenX = 0,
		__prevScreenY = 0,

		justPressed = false,
		pressed = false,
		justReleased = false,
		released = true,

		isMoved = false,
		startX = 0,
		startY = 0,
		startScreenX = 0,
		startScreenY = 0,
		pressure = 0,
		active = false
	}
end

local function getSlotForId(loveId)
	local idStr = tostring(loveId)

	if Touch.idMap[idStr] then
		return Touch.idMap[idStr]
	end

	for i = 0, Touch.maxTouches - 1 do
		if not Touch.touches[i].active then
			Touch.idMap[idStr] = i
			return i
		end
	end

	return nil
end

local function releaseSlot(loveId)
	local idStr = tostring(loveId)
	local slot = Touch.idMap[idStr]
	if slot then
		Touch.idMap[idStr] = nil
		if Touch.touches[slot] then
			Touch.touches[slot].active = false
		end
	end
end

function Touch.reset()
	Touch.anyTouchJustPressed = false
	Touch.anyTouchJustReleased = false

	for i = 0, Touch.maxTouches - 1 do
		local touch = Touch.touches[i]
		if touch.active then
			if touch.justPressed then
				touch.justPressed = false
			end
			if touch.justReleased then
				touch.justReleased = false
				touch.active = false
				touch.pressed = false
				touch.released = true
			end
			if touch.isMoved then
				touch.isMoved = false
			end
			touch.deltaX = 0
			touch.deltaY = 0
			touch.deltaScreenX = 0
			touch.deltaScreenY = 0
		end
	end

	local any = false
	for i = 0, Touch.maxTouches - 1 do
		if Touch.touches[i].active and Touch.touches[i].pressed then
			any = true
			break
		end
	end
	Touch.anyTouchPressed = any
	Touch.anyTouchReleased = not any

	Touch.prevPinchDistance = Touch.pinchDistance
	Touch:updateGestures()
end

function Touch.onPressed(id, x, y, dx, dy, pressure)
	local slot = getSlotForId(id)
	if not slot then return end

	local winWidth, winHeight = love.graphics.getDimensions()
	local scale = math.min(winWidth / game.width, winHeight / game.height)

	local gameX = (x - (winWidth - scale * game.width) / 2) / scale
	local gameY = (y - (winHeight - scale * game.height) / 2) / scale

	local touch = Touch.touches[slot]
	touch.id = tostring(id)
	touch.x = gameX
	touch.y = gameY
	touch.screenX = x
	touch.screenY = y
	touch.__prevX = gameX
	touch.__prevY = gameY
	touch.__prevScreenX = x
	touch.__prevScreenY = y
	touch.startX = gameX
	touch.startY = gameY
	touch.startScreenX = x
	touch.startScreenY = y
	touch.pressure = pressure or 1

	touch.justPressed = true
	touch.pressed = true
	touch.justReleased = false
	touch.released = false
	touch.active = true
	touch.isMoved = false

	Touch.anyTouchJustPressed = true
	Touch.anyTouchPressed = true
	Touch.anyTouchReleased = false
end

function Touch.onReleased(id, x, y, dx, dy, pressure)
	local idStr = tostring(id)
	local slot = Touch.idMap[idStr]
	if not slot then return end

	local touch = Touch.touches[slot]
	if touch.active then
		touch.justPressed = false
		touch.pressed = false
		touch.justReleased = true
		touch.released = true

		Touch.anyTouchJustReleased = true
		local remains = false
		for i = 0, Touch.maxTouches - 1 do
			if Touch.touches[i].active and Touch.touches[i].pressed then
				remains = true
				break
			end
		end
		if not remains then
			Touch.anyTouchPressed = false
			Touch.anyTouchReleased = true
		end
	end
end

function Touch.onMoved(id, x, y, dx, dy, pressure)
	local idStr = tostring(id)
	local slot = Touch.idMap[idStr]
	if not slot then return end

	local touch = Touch.touches[slot]
	if not touch.active then return end

	local winWidth, winHeight = love.graphics.getDimensions()
	local scale = math.min(winWidth / game.width, winHeight / game.height)

	touch.__prevX = touch.x
	touch.__prevY = touch.y
	touch.__prevScreenX = touch.screenX
	touch.__prevScreenY = touch.screenY

	touch.x = (x - (winWidth - scale * game.width) / 2) / scale
	touch.y = (y - (winHeight - scale * game.height) / 2) / scale
	touch.screenX = x
	touch.screenY = y
	touch.pressure = pressure or 1

	touch.isMoved = true
	touch.deltaX = touch.x - touch.__prevX
	touch.deltaY = touch.y - touch.__prevY
	touch.deltaScreenX = touch.screenX - touch.__prevScreenX
	touch.deltaScreenY = touch.screenY - touch.__prevScreenY
end

function Touch.getTouch(slot)
	if slot >= 0 and slot < Touch.maxTouches and Touch.touches[slot].active then
		return Touch.touches[slot]
	end
	return nil
end

function Touch.getTouchCount()
	local count = 0
	for i = 0, Touch.maxTouches - 1 do
		if Touch.touches[i].active then
			count = count + 1
		end
	end
	return count
end

local function pointOverlapsObject(gameX, gameY, obj, cam, parentX, parentY, parentSfx, parentSfy)
	if not obj or obj.exists == false then return false end
	parentX, parentY = parentX or 0, parentY or 0
	parentSfx = parentSfx == nil and 1 or parentSfx
	parentSfy = parentSfy == nil and 1 or parentSfy

	local camera = cam or (obj.cameras and obj.cameras[1]) or game.camera
	if type(obj.overlapsPoint) == "function" then
		return obj:overlapsPoint(gameX, gameY, camera)
	end

	if SpriteGroup and obj.is and obj:is(SpriteGroup) then
		local ox = parentX + (obj.x or 0) + (obj.offset and obj.offset.x or 0)
		local oy = parentY + (obj.y or 0) + (obj.offset and obj.offset.y or 0)
		local sfx = parentSfx * (obj.scrollFactor and obj.scrollFactor.x or 1)
		local sfy = parentSfy * (obj.scrollFactor and obj.scrollFactor.y or 1)
		for _, o in ipairs(obj.members) do
			if o and pointOverlapsObject(gameX, gameY, o, camera, ox, oy, sfx, sfy) then
				return true
			end
		end
		return false
	elseif Group and obj.is and obj:is(Group) then
		for _, o in ipairs(obj.members) do
			if o and pointOverlapsObject(gameX, gameY, o, cam, parentX, parentY, parentSfx, parentSfy) then
				return true
			end
		end
		return false
	elseif Object and obj.is and obj:is(Object) then
		local sfx = parentSfx * (obj.scrollFactor and obj.scrollFactor.x or 1)
		local sfy = parentSfy * (obj.scrollFactor and obj.scrollFactor.y or 1)
		local wx, wy
		if camera and camera.screenToWorld then
			wx, wy = camera:screenToWorld(gameX, gameY, sfx, sfy)
		else
			wx = gameX + (camera and camera.scroll and camera.scroll.x or 0) * sfx
			wy = gameY + (camera and camera.scroll and camera.scroll.y or 0) * sfy
		end
		local x = (obj.x or 0) + parentX
		local y = (obj.y or 0) + parentY
		local w = obj.width or 0
		local h = obj.height or 0
		return wx >= x and wx <= x + w and wy >= y and wy <= y + h
	end
	return false
end

function Touch.overlaps(obj, cam)
	for i = 0, Touch.maxTouches - 1 do
		local touch = Touch.touches[i]
		if touch.active and touch.pressed and pointOverlapsObject(touch.x, touch.y, obj, cam) then
			return true, touch
		end
	end
	return false, nil
end

function Touch.touchOverlaps(touch, obj, cam)
	if not touch or not touch.active or not touch.pressed then return false end
	return pointOverlapsObject(touch.x, touch.y, obj, cam)
end

function Touch:updateGestures()
	local activeTouches = {}
	for i = 0, self.maxTouches - 1 do
		if self.touches[i].active then
			table.insert(activeTouches, self.touches[i])
		end
	end

	if #activeTouches >= 2 then
		local dx = activeTouches[1].x - activeTouches[2].x
		local dy = activeTouches[1].y - activeTouches[2].y
		self.pinchDistance = math.sqrt(dx * dx + dy * dy)
		if self.prevPinchDistance > 0 then
			self.pinchScale = self.pinchDistance / self.prevPinchDistance
		end

		self.isPinching = true
		self.centerX = (activeTouches[1].x + activeTouches[2].x) / 2
		self.centerY = (activeTouches[1].y + activeTouches[2].y) / 2
		self.screenCenterX = (activeTouches[1].screenX + activeTouches[2].screenX) / 2
		self.screenCenterY = (activeTouches[1].screenY + activeTouches[2].screenY) / 2
	else
		self.isPinching = false
		self.pinchScale = 1

		if #activeTouches == 1 then
			self.centerX = activeTouches[1].x
			self.centerY = activeTouches[1].y
			self.screenCenterX = activeTouches[1].screenX
			self.screenCenterY = activeTouches[1].screenY
		end
	end
end

function Touch.getDistance(slot1, slot2)
	local touch1 = Touch.getTouch(slot1)
	local touch2 = Touch.getTouch(slot2)
	if not touch1 or not touch2 then return 0 end
	local dx = touch1.x - touch2.x
	local dy = touch1.y - touch2.y
	return math.sqrt(dx * dx + dy * dy)
end

function Touch.getAngle(slot1, slot2)
	local touch1 = Touch.getTouch(slot1)
	local touch2 = Touch.getTouch(slot2)
	if not touch1 or not touch2 then return 0 end
	return math.atan2(touch2.y - touch1.y, touch2.x - touch1.x)
end

function Touch.hasTouchMoved(slot, threshold)
	local touch = Touch.getTouch(slot)
	if not touch then return false end
	threshold = threshold or 7

	local dx = touch.x - touch.startX
	local dy = touch.y - touch.startY
	local distance = math.sqrt(dx * dx + dy * dy)

	return distance > threshold
end

return Touch