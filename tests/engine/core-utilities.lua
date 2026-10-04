-- Exercise the compatibility fallback even on Lua versions with table.move.
table.move = nil
require 'loxel.lib.override'
Classic = require 'loxel.lib.classic'
Basic = require 'loxel.basic'
Signal = require 'loxel.util.signal'

local passed, failed = 0, 0
local function check(name, test)
	local ok, message = xpcall(test, debug.traceback)
	if ok then passed = passed + 1 else failed = failed + 1 end
	print((ok and 'PASS ' or 'FAIL ') .. name .. (ok and '' or ': ' .. message))
end

function love.load()
	check('table.move preserves offsets and overlapping ranges', function()
		local source, destination = {'a', 'b', 'c', 'd'}, {}
		assert(table.move(source, 2, 3, 1, destination) == destination)
		assert(table.concat(destination, ',') == 'b,c')
		table.move(source, 1, 3, 2)
		assert(table.concat(source, ',') == 'a,a,b,c')
		table.move(source, 2, 4, 1)
		assert(table.concat(source, ',') == 'a,b,c,c')
	end)
	check('trimming preserves the last nonspace character', function()
		for _, value in ipairs({'a', 'song', 'song ', 'song\t\n', '  song  '}) do
			local expected = value:match('%S+')
			assert(value:trim() == expected, value)
		end
		assert((''):trim() == '' and (' \t\n'):trim() == '')
	end)
	check('a one-shot listener does not skip the next listener', function()
		local signal, calls = Signal(), {}
		signal:addOnce(function() calls[#calls + 1] = 'once' end)
		signal:add(function() calls[#calls + 1] = 'always' end)
		signal:dispatch()
		signal:dispatch()
		assert(table.concat(calls, ',') == 'once,always,always')
	end)
	check('a self-removing listener does not skip the next listener', function()
		local signal, calls = Signal(), 0
		local listener
		listener = function() signal:remove(listener) end
		signal:add(listener)
		signal:add(function() calls = calls + 1 end)
		signal:dispatch()
		assert(calls == 1)
	end)
	check('new listeners wait until the next dispatch', function()
		local signal, calls = Signal(), 0
		local function added() calls = calls + 1 end
		signal:addOnce(function() signal:add(added) end)
		signal:dispatch()
		assert(calls == 0)
		signal:dispatch()
		assert(calls == 1)
	end)
	check('one-shot listeners are removed before recursive dispatch', function()
		local signal, calls = Signal(), 0
		signal:addOnce(function()
			calls = calls + 1
			if calls < 2 then signal:dispatch() end
		end)
		signal:dispatch()
		assert(calls == 1)
	end)
	check('removing a listener releases its one-shot record', function()
		local signal = Signal()
		local function listener() end
		signal:addOnce(listener)
		signal:remove(listener)
		assert(signal.onceCalls[listener] == nil)
	end)
	check('add accepts its documented once flag', function()
		local signal, calls = Signal(), 0
		signal:add(function() calls = calls + 1 end, true)
		signal:dispatch()
		signal:dispatch()
		assert(calls == 1)
	end)
	print(('CORE UTILITIES: %d passed, %d failed'):format(passed, failed))
	love.event.quit(failed == 0 and 0 or 1)
end

function love.update() end
function love.draw() end
function love.errorhandler(message)
	print(message)
	return function() return 1 end
end
