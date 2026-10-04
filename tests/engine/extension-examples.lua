require 'loxel'
require 'funkin'

local function file(path, contents)
	assert(love.filesystem.createDirectory(path:match('^(.*)/[^/]+$')))
	assert(love.filesystem.write(path, contents))
end

function love.load()
	local ok, message = xpcall(function()
		love.window.setMode(320, 240, {vsync = 0})
		game.width, game.height = 320, 240
		local root = 'tests-extension-addons'
		for _, item in ipairs({{'tempo-tools-addon', 'beat'}, {'judgement-tools-addon', 'statistics'}}) do
			local source = 'examples/' .. item[1] .. '/modules/' .. item[2] .. '.lua'
			file(root .. '/' .. item[1] .. '/modules/' .. item[2] .. '.lua', assert(love.filesystem.read(source)))
		end
		Addons.root = root
		Addons.all = {{path = 'tempo-tools-addon', active = true}, {path = 'judgement-tools-addon', active = true}}
		local state = Group()
		state.camHUD = Camera()
		state.conductor = Conductor({Parser.newTimeChange(0, 120), Parser.newTimeChange(1000, 180)})
		state.playerNotefield = {time = 0.53}
		require('loxel.lib.gamestate').stack[1] = state
		local before = #Script.messages.listeners
		local meter = Script('examples/beat-meter-mod/data/scripts/beat-meter.lua', true, true, true)
		assert(meter.chunk and not meter.closed)
		meter:call('postCreate')
		assert(#state.members == 1 and #state.conductor.onBeat.listeners == 1)
		state.conductor.time = 1500
		meter:call('update', 0.1)
		assert(state.members[1].content:find('Beat 4', 1, true), state.members[1].content)
		state.conductor.onBeat:dispatch(3)
		meter:call('leave')
		meter:call('leave')
		assert(#state.members == 0 and #state.conductor.onBeat.listeners == 0, 'beat meter leaked its label or subscription')
		assert(next(meter.__failedfunc) == nil)
		meter:close()
		local trainer = Script('examples/timing-trainer-mod/data/scripts/timing-trainer.lua', true, true, true)
		assert(trainer.chunk and not trainer.closed)
		trainer:call('postCreate')
		assert(#state.members == 1)
		local note = {time = 0.5, parent = state.playerNotefield, sustain = false}
		trainer:call('goodNoteHit', note, {name = 'good'})
		assert(state.members[1].content:find('1 hits', 1, true), state.members[1].content)
		assert(state.members[1].content:find('+30.0 ms', 1, true), state.members[1].content)
		note.sustain = true
		trainer:call('goodNoteHit', note, {name = 'good'})
		trainer:call('noteMiss', note)
		assert(state.members[1].content:find('1 misses', 1, true))
		trainer:call('leave')
		assert(next(trainer.__failedfunc) == nil and #state.members == 0)
		trainer:close()
		assert(#Script.messages.listeners == before)
		Addons.all[1].active, Addons.all[2].active = false, false
		for _, source in ipairs({'beat-meter-mod/data/scripts/beat-meter.lua', 'timing-trainer-mod/data/scripts/timing-trainer.lua'}) do
			local optional = Script('examples/' .. source, true, true, true)
			assert(optional.chunk and not optional.closed, 'disabled optional dependency prevented the mod from loading')
			optional:call('postCreate')
			assert(next(optional.__failedfunc) == nil and #state.members == 0)
			optional:close()
		end
		state.conductor:destroy()
		state.camHUD:destroy()
		paths.async.stop()
		print('EXTENSION EXAMPLES PASSED: two addons, two native mods, tempo boundaries, hit/miss statistics, disabled dependencies and cleanup')
	end, debug.traceback)
	if not ok then print('EXTENSION EXAMPLES FAILED: ' .. message) end
	love.event.quit(ok and 0 or 1)
end

function love.update() end
function love.draw() end
function love.quit() end
function love.errorhandler(message)
	print(message)
	return function() return 1 end
end
