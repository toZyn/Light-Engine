local Statistics = {}
Statistics.__index = Statistics

function Statistics.new()
	return setmetatable({count = 0, total = 0, absolute = 0, peak = 0}, Statistics)
end

function Statistics:add(milliseconds)
	if type(milliseconds) ~= 'number' or milliseconds ~= milliseconds or math.abs(milliseconds) == math.huge then
		error('timing sample must be a finite number', 2)
	end
	self.count = self.count + 1
	self.total = self.total + milliseconds
	self.absolute = self.absolute + math.abs(milliseconds)
	self.peak = math.max(self.peak, math.abs(milliseconds))
end

function Statistics:snapshot()
	return {
		count = self.count,
		mean = self.count > 0 and self.total / self.count or 0,
		meanAbsolute = self.count > 0 and self.absolute / self.count or 0,
		peak = self.peak
	}
end

return Statistics
