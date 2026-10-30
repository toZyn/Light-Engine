require 'loxel'
require 'funkin'

local passed, failed = 0, 0
local function check(name, test)
	local ok, message = xpcall(test, debug.traceback)
	if ok then passed = passed + 1 else failed = failed + 1 end
	print((ok and 'PASS ' or 'FAIL ') .. name .. (ok and '' or ': ' .. message))
end
local function near(actual, expected)
	assert(math.abs(actual - expected) < 0.0001, tostring(actual) .. ' ~= ' .. tostring(expected))
end

function love.load()
	love.window.setMode(320, 240, {vsync = 0})
	check('steps keep quarter-beat timing in 3/4 and 7/8', function()
		for _, signature in ipairs({{3, 4, 1500}, {7, 8, 1750}}) do
			local c = Conductor({Parser.newTimeChange(0, 120, nil, signature[1], signature[2])})
			c.curTimeChange = c.timeChanges[1]
			near(c.stepCrotchet, 125)
			near(c.measureCrotchet, signature[3])
			near(c:getTimeInSteps(500), 4)
			near(c:getStepTimeInMs(4), 500)
			near(c:getBeatTimeInMs(1), 500)
			c:destroy()
		end
	end)
	check('time changes dispatch once when the active tempo changes', function()
		local c = Conductor({Parser.newTimeChange(0, 120), Parser.newTimeChange(1000, 180)})
		local music, changes = game.sound.music, 0
		game.sound.music = {time = 0.1}
		c.onTimeChange:add(function() changes = changes + 1 end)
		c:update(100)
		local initial = changes
		c:update(100)
		assert(changes == initial, 'unchanged tempo dispatched again')
		game.sound.music.time = 1.1
		c:update(1100)
		assert(changes == initial + 1, 'crossing a tempo boundary dispatched multiple events')
		near(c.bpm, 180)
		game.sound.music = music
		c:destroy()
	end)
	check('cached charts keep V-Slice notes on the same side', function()
		local root, mod = Mods.root, Mods.currentMod
		Mods.root, Mods.currentMod = 'tests-chart-mods', 'timing'
		local directory = Mods.root .. '/' .. Mods.currentMod .. '/songs/cache-probe'
		assert(love.filesystem.createDirectory(directory))
		assert(love.filesystem.write(directory .. '/chart.json', [[
{"version":"2.0.0","scrollSpeed":{"normal":1},"notes":{"normal":[
{"t":250,"d":0,"l":0},{"t":500,"d":4,"l":0}]},"events":[]}
]]))
		local first = Parser.getChart('cache-probe', 'normal')
		local second = Parser.getChart('cache-probe', 'normal')
		assert(first == second, 'successful chart parsing was not cached')
		assert(#second.notes.player == 1 and #second.notes.enemy == 1)
		near(second.notes.enemy[1].d, 0)
		Mods.root, Mods.currentMod = root, mod
	end)
	check('Codename event files carry camera and BPM events together', function()
		local chart = require('funkin.backend.parser.chart.codename').parse({
			strumLines = {}, stage = 'stage', scrollSpeed = 1
		}, {events = {
			{name = 'BPM Change', time = 1000, params = {180}},
			{name = 'Camera Movement', time = 1200, params = {0}}
		}}, {bpm = 120})
		local c = Conductor(chart.timeChanges)
		near(c:getBPM(true), 120)
		near(c:getTimeInSteps(500), 4)
		near(c:getTimeInSteps(1000), 8)
		near(c:getTimeInSteps(1500), 14)
		near(c:getStepTimeInMs(14), 1500)
		c:destroy()
		assert(chart.events[2].e == 'FocusCamera' and chart.events[2].v == 1)
		local atStart = require('funkin.backend.parser.chart.codename').parse({strumLines = {}},
			{events = {{name = 'BPM Change', time = 0, params = {150}}}}, {bpm = 120})
		local initial = Conductor(atStart.timeChanges)
		near(initial:getBPM(true), 150)
		near(initial:getTimeInSteps(400), 4)
		initial:destroy()
	end)
	check('legacy charts carrying version field (test.json) route to Vanilla and all 27 base songs parse cleanly', function()
		Parser.clearCache()
		local testChart, testErr = Parser.getChart('test', 'normal', {strict = true})
		assert(testChart ~= nil and testErr == nil, 'test song must parse cleanly: ' .. tostring(testErr))
		assert(type(testChart.speed) == 'number', 'test song speed must be numeric, got ' .. type(testChart.speed))
		assert(#testChart.notes.player + #testChart.notes.enemy > 0, 'test song must contain parsed notes')

		for _, songDir in ipairs(love.filesystem.getDirectoryItems('assets/songs')) do
			if paths.exists('assets/songs/' .. songDir, 'directory') then
				local meta = Parser.getMeta(songDir)
				local diffs = (meta and meta.difficulties) or {'normal'}
				for _, diff in ipairs(diffs) do
					local c, err = Parser.getChart(songDir, diff, {strict = true})
					assert(c ~= nil, string.format('Song "%s" [%s] failed to parse: %s',
						tostring(songDir), tostring(diff), tostring(err)))
				end
			end
		end
	end)
	check('malformed metadata.json logs song + path + field, shows Toast notice, and keeps Freeplay alive', function()
		local root, mod = Mods.root, Mods.currentMod
		Mods.root, Mods.currentMod = 'tests-chart-mods', 'broken-meta-mod'
		local songDir = Mods.root .. '/' .. Mods.currentMod .. '/songs/corrupt-probe'
		assert(love.filesystem.createDirectory(songDir))
		assert(love.filesystem.write(songDir .. '/chart.json',
			'{"version":"2.0.0","scrollSpeed":{"normal":1.2},"notes":{"normal":[{"t":500,"d":1,"l":0}]},"events":[]}'))

		-- 1) Missing playData in V-Slice metadata
		assert(love.filesystem.write(songDir .. '/meta.json', '{"version":"2.2.4"}'))
		Parser.clearCache()
		paths.clearCache()
		local okLoad, loadErr = PlayState.loadSong('corrupt-probe', 'normal')
		assert(okLoad == false, 'PlayState.loadSong must fail gracefully on invalid V-Slice metadata')
		assert(type(loadErr) == 'string'
			and loadErr:find('corrupt%-probe')
			and loadErr:find('meta%.json')
			and loadErr:find('playData'),
			'Error must include song name, file path, and failing field; got: ' .. tostring(loadErr))

		-- 2) Invalid JSON syntax in meta.json
		assert(love.filesystem.write(songDir .. '/meta.json', '{ broken json !!!'))
		Parser.clearCache()
		paths.clearCache()
		local safeMeta = Parser.getMeta('corrupt-probe')
		assert(type(safeMeta) == 'table' and safeMeta.song == 'corrupt-probe',
			'Parser.getMeta must return fallback metadata without crashing on broken JSON')
		local openOk, openErr = PlayState.loadSong('corrupt-probe', 'normal')
		assert(openOk == false, 'PlayState.loadSong must fail gracefully on broken JSON syntax')
		assert(type(openErr) == 'string' and openErr:find('corrupt%-probe') and openErr:find('meta%.json'),
			'Broken JSON error must cite song and meta.json path; got: ' .. tostring(openErr))

		Mods.root, Mods.currentMod = root, mod
		Parser.clearCache()
		paths.clearCache()
	end)
	paths.async.stop()
	print(('CHART TIMING: %d passed, %d failed'):format(passed, failed))
	love.event.quit(failed == 0 and 0 or 1)
end

function love.update() end
function love.draw() end
function love.quit() end
function love.errorhandler(message)
	print(message)
	return function() return 1 end
end
