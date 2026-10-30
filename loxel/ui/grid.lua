---@class UIGrid:Object
local Grid = Object:extend("UIGrid")

function Grid:new(x, y, rows, columns, size, color1, color2)
	Grid.super.new(self, x, y)

	self.color1 = color1 or {1, 1, 1}
	self.color2 = color2 or {0.7, 0.7, 0.7}

	self.rows = rows or 8
	self.columns = columns or 8
	self.cellSize = size or 32

	self.width = self.columns * self.cellSize
	self.height = self.rows * self.cellSize
end

function Grid:__render(camera)
	local r, g, b, a = love.graphics.getColor()
	local sx, sy = self.scale.x * self.zoom.x, self.scale.y * self.zoom.y

	local x, y = self.x - self.offset.x - (camera.scroll.x * self.scrollFactor.x),
		self.y - self.offset.y - (camera.scroll.y * self.scrollFactor.y)
	local size = self.cellSize
	local rows, cols = self.rows, self.columns
	local cellW, cellH = size * sx, size * sy
	local totalW, totalH = cols * cellW, rows * cellH

	-- Draw base rectangle once for color2, then batch all color1 cells under a single setColor
	local c2 = self.color2
	love.graphics.setColor(c2[1], c2[2], c2[3], (c2[4] or 1) * self.alpha)
	love.graphics.rectangle("fill", x, y, totalW, totalH)

	local c1 = self.color1
	love.graphics.setColor(c1[1], c1[2], c1[3], (c1[4] or 1) * self.alpha)
	for row = 0, rows - 1 do
		local ry = y + row * cellH
		local startCol = row % 2
		for col = startCol, cols - 1, 2 do
			love.graphics.rectangle("fill", x + col * cellW, ry, cellW, cellH)
		end
	end

	love.graphics.setColor(r, g, b, a)
end

return Grid
