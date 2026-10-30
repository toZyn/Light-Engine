local Mouse = {
	LEFT = 1,
	RIGHT = 2,
	MIDDLE = 3,

	wheel = 0,
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

	isMoved = false,

	justPressed = false,
	justPressedLeft = false,
	justPressedRight = false,
	justPressedMiddle = false,

	pressed = false,
	pressedLeft = false,
	pressedRight = false,
	pressedMiddle = false,

	justReleased = false,
	justReleasedLeft = false,
	justReleasedRight = false,
	justReleasedMiddle = false,

	released = true,
	releasedLeft = true,
	releasedRight = true,
	releasedMiddle = true
}

function Mouse.reset()
	if Mouse.wheel ~= 0 then Mouse.wheel = 0 end
	if Mouse.isMoved then Mouse.isMoved = false end
	if Mouse.justPressed then
		Mouse.justPressed = false
		Mouse.justPressedLeft = false
		Mouse.justPressedRight = false
		Mouse.justPressedMiddle = false
	end
	if Mouse.justReleased then
		Mouse.justReleased = false
		Mouse.justReleasedLeft = false
		Mouse.justReleasedRight = false
		Mouse.justReleasedMiddle = false
	end
	Mouse.deltaX = 0
	Mouse.deltaY = 0
	Mouse.deltaScreenX = 0
	Mouse.deltaScreenY = 0
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

function Mouse.overlaps(obj, cam)
	return pointOverlapsObject(Mouse.x, Mouse.y, obj, cam)
end

function Mouse.onPressed(button)
	if button == Mouse.LEFT then
		Mouse.justPressedLeft = true
		Mouse.pressedLeft = true
		Mouse.justReleasedLeft = false
		Mouse.releasedLeft = false
	elseif button == Mouse.RIGHT then
		Mouse.justPressedRight = true
		Mouse.pressedRight = true
		Mouse.justReleasedRight = false
		Mouse.releasedRight = false
	elseif button == Mouse.MIDDLE then
		Mouse.justPressedMiddle = true
		Mouse.pressedMiddle = true
		Mouse.justReleasedMiddle = false
		Mouse.releasedMiddle = false
	end
	Mouse.justPressed = true
	Mouse.pressed = true
	Mouse.justReleased = false
	Mouse.released = false
end

function Mouse.onReleased(button)
	if button == Mouse.LEFT then
		Mouse.justPressedLeft = false
		Mouse.pressedLeft = false
		Mouse.justReleasedLeft = true
		Mouse.releasedLeft = true
	elseif button == Mouse.RIGHT then
		Mouse.justPressedRight = false
		Mouse.pressedRight = false
		Mouse.justReleasedRight = true
		Mouse.releasedRight = true
	elseif button == Mouse.MIDDLE then
		Mouse.justPressedMiddle = false
		Mouse.pressedMiddle = false
		Mouse.justReleasedMiddle = true
		Mouse.releasedMiddle = true
	end
	Mouse.justPressed = false
	Mouse.pressed = false
	Mouse.justReleased = true
	Mouse.released = true
end

function Mouse.onMoved(x, y)
	local winWidth, winHeight = love.graphics.getDimensions()
	local scale = math.min(winWidth / game.width, winHeight / game.height)

	Mouse.__prevX = Mouse.x
	Mouse.__prevY = Mouse.y
	Mouse.__prevScreenX = Mouse.screenX
	Mouse.__prevScreenY = Mouse.screenY

	Mouse.x, Mouse.y = (x - (winWidth - scale * game.width) / 2) / scale,
		(y - (winHeight - scale * game.height) / 2) / scale

	Mouse.screenX, Mouse.screenY = x, y
	Mouse.isMoved = true

	Mouse.deltaX = Mouse.x - Mouse.__prevX
	Mouse.deltaY = Mouse.y - Mouse.__prevY
	Mouse.deltaScreenX = Mouse.screenX - Mouse.__prevScreenX
	Mouse.deltaScreenY = Mouse.screenY - Mouse.__prevScreenY
end

return Mouse
