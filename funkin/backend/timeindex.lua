local TimeIndex = {}
TimeIndex.__index = TimeIndex

function TimeIndex.lowerBound(list, time)
	local lo, hi = 1, #list + 1
	while lo < hi do
		local mid = math.floor((lo + hi) / 2)
		if list[mid].t < time then lo = mid + 1 else hi = mid end
	end
	return lo
end

function TimeIndex.sort(list)
	for i = 2, #list do
		if list[i].t < list[i - 1].t then
			table.sort(list, function(a, b) return a.t < b.t end)
			return list
		end
	end
	return list
end

function TimeIndex.new(list)
	local self = setmetatable({list = list, ends = {}, blockSize = 128}, TimeIndex)
	self.blocks = math.ceil(#list / self.blockSize)
	local size = 1
	while size < self.blocks do size = size * 2 end
	self.size = size
	for block = 1, size do
		local ending = -math.huge
		for i = (block - 1) * self.blockSize + 1, math.min(block * self.blockSize, #list) do
			local note = list[i]
			ending = math.max(ending, note.t + math.max(0, note.l or 0))
		end
		self.ends[size + block - 1] = ending
	end
	for i = size - 1, 1, -1 do
		self.ends[i] = math.max(self.ends[i * 2], self.ends[i * 2 + 1])
	end
	return self
end

local function findBlock(self, node, left, right, from, last, time)
	if right < from or left > last or self.ends[node] < time then return end
	if left == right then return left end
	local mid = math.floor((left + right) / 2)
	return findBlock(self, node * 2, left, mid, from, last, time)
		or findBlock(self, node * 2 + 1, mid + 1, right, from, last, time)
end

function TimeIndex:each(firstTime, lastTime)
	local list, blockSize = self.list, self.blockSize
	local last = TimeIndex.lowerBound(list, lastTime)
	while last <= #list and list[last].t <= lastTime do last = last + 1 end
	last = last - 1
	local lastBlock = math.ceil(last / blockSize)
	local block, cursor, limit = 0, 1, 0
	return function()
		while true do
			while cursor <= limit do
				local i = cursor
				cursor = cursor + 1
				local note = list[i]
				if note.t + math.max(0, note.l or 0) >= firstTime then return i, note end
			end
			block = findBlock(self, 1, 1, self.size, block + 1, lastBlock, firstTime)
			if not block then
				block = self.size + 1
				return
			end
			cursor, limit = (block - 1) * blockSize + 1, math.min(block * blockSize, last)
		end
	end
end

return TimeIndex
