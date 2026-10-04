local Beat = {}

function Beat.phase(conductor, milliseconds)
	local position = conductor:getTimeInSteps(milliseconds) / 4
	return position % 1, math.floor(position)
end

function Beat.subscribe(conductor, callback)
	assert(type(callback) == 'function', 'beat callback must be a function')
	conductor.onBeat:add(callback)
	local attached = true
	return function()
		if attached then
			attached = false
			conductor.onBeat:remove(callback)
		end
	end
end

return Beat
