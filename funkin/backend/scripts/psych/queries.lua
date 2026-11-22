local Queries = {}

local function resolve(compat, path)
	local ok, object = pcall(compat._object, compat, path)
	if ok then return object end
end

local function overlap(first, second)
	if not first or not second or first.exists == false or second.exists == false then return false end
	if first.members then
		for _, member in ipairs(first.members) do if overlap(member, second) then return true end end
		return false
	end
	if second.members then
		for _, member in ipairs(second.members) do if overlap(first, member) then return true end end
		return false
	end
	if first == second then return false end
	return first.x < second.x + second.width and first.x + first.width > second.x
		and first.y < second.y + second.height and first.y + first.height > second.y
end

function Queries.install(compat, api)
	for _, axis in ipairs({"x", "y"}) do
		api["getScreenPosition" .. axis:upper()] = function(path, name)
			compat:_active()
			local object = resolve(compat, path)
			if not object then return 0 end
			local camera = ({game = game.camera, hud = compat.state.camHUD, other = compat.state.camOther})[name or "game"]
			camera = camera or (compat.state.psychVariables and compat.state.psychVariables[name]) or game.camera
			return object[axis] - camera.scroll[axis] * object.scrollFactor[axis]
		end
	end
	api.objectsOverlap = function(first, second)
		compat:_active()
		return overlap(resolve(compat, first), resolve(compat, second))
	end
	api.getPixelColor = function(path, x, y)
		compat:_active()
		local object = resolve(compat, path)
		if not object or not object.texture then return -16777216 end
		local width, height = object.texture:getDimensions()
		x, y = math.modf(x), math.modf(y)
		if x < 0 or y < 0 or x >= width or y >= height then return 0 end
		local canvas = love.graphics.newCanvas(width, height)
		love.graphics.push("all")
		love.graphics.setCanvas(canvas)
		love.graphics.origin()
		love.graphics.setScissor()
		love.graphics.setShader()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.clear()
		love.graphics.draw(object.texture)
		love.graphics.pop()
		local data = canvas:newImageData(1, 1, x, y, 1, 1)
		local r, g, b, a = data:getPixel(0, 0)
		data:release()
		canvas:release()
		return bit.tobit(math.floor(a * 255 + 0.5) * 16777216 + math.floor(r * 255 + 0.5) * 65536
			+ math.floor(g * 255 + 0.5) * 256 + math.floor(b * 255 + 0.5))
	end
end

return Queries
