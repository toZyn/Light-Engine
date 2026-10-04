check('quick menu taps move once and accept the selected item', function()
	for _, navigation in ipairs({{'vertical', 's'}, {'horizontal', 'd'}}) do
		local menu = MenuList(nil, false, navigation[1])
		for _ = 1, 3 do menu:add(Sprite()) end
		controls:onKeyPress(navigation[2])
		controls:onKeyRelease(navigation[2])
		controls:update()
		Throttle:update(0.016)
		menu:update(0.016)
		assert(menu.curSelected == 2, 'a quick direction tap did not move the menu')
		controls:update()
		Throttle:update(0.016)
		menu:update(0.016)
		assert(menu.curSelected == 2, 'one direction tap moved twice')
		local selected, calls = nil, 0
		menu.selectCallback = function(item) selected = item; calls = calls + 1 end
		controls:onKeyPress('return')
		controls:onKeyRelease('return')
		controls:update()
		menu:update(0.016)
		assert(selected == menu.members[2] and calls == 1, 'a quick accept tap did not select the second item')
		for _, throttle in pairs(menu.throttles) do throttle:destroy() end
		menu:destroy()
	end
end)

check('keyboard hits, misses and pause preserve a native song and mod HUD', function()
	ClientPrefs.data.botplayMode = false
	ClientPrefs.data.ghostTap = false
	ClientPrefs.data.autoPause = false
	local root = 'tests-gameplay-addons'
	assert(love.filesystem.createDirectory(root .. '/judgement-tools-addon/modules'))
	assert(love.filesystem.write(root .. '/judgement-tools-addon/modules/statistics.lua',
		assert(love.filesystem.read('examples/judgement-tools-addon/modules/statistics.lua'))))
	Addons.root = root
	Addons.all = {{path = 'judgement-tools-addon', active = true}}
	local state = PlayState(false, 'bopeebo', 'normal')
	state:preload()
	paths.async.stop()
	game.switchState(state, true)
	game.update(0)
	local trainer = Script('examples/timing-trainer-mod/data/scripts/timing-trainer.lua', true, true, true)
	assert(trainer.chunk and not trainer.closed)
	state.scripts:add(trainer)
	trainer:call('postCreate')
	local label
	for _, member in ipairs(state.members) do
		if member.content and member.content:find('0 hits', 1, true) then label = member end
	end
	assert(label, 'timing trainer HUD was not created')
	state.startingSong, state.startedCountdown = false, true
	local field = state.playerNotefield
	field.time = field.chartNotes[1].t / 1000
	field:update(0)
	local note = assert(field:getNotes(field.time)[1], 'chart did not spawn a hittable note')
	state:playSong(note.time)
	local score, combo = state.score, state.combo
	local keys = {'a', 's', 'w', 'd'}
	state.lastTick = love.timer.getTime()
	state:onKeyPress(keys[note.direction + 1], 'key', nil, false, state.lastTick + 0.03)
	assert(note.wasGoodHit and state.score > score and state.combo == combo + 1, 'keyboard hit did not score')
	assert(label.content:find('1 hits', 1, true) and label.content:find('+30.0 ms', 1, true), label.content)
	state:onKeyRelease(keys[note.direction + 1], 'key', nil, state.lastTick + 0.04)
	local missed = assert(field.activeNotes[1], 'chart did not spawn a second note')
	local misses = state.misses
	state:miss(missed)
	assert(state.misses == misses + 1 and label.content:find('1 misses', 1, true), 'miss did not reach score and HUD')
	state:pauseSong()
	assert(state.paused and not game.sound.music:isPlaying(), 'pause left music playing')
	local position = game.sound.music.time
	state:playSong()
	assert(not state.paused and game.sound.music:isPlaying(), 'resume did not restart music')
	assert(math.abs(game.sound.music.time - position) < 0.05, 'resume rewound the song')
	state:pauseSong()
	trainer:call('leave')
	assert(not table.find(state.members, label) and next(trainer.__failedfunc) == nil, 'trainer cleanup failed')
	state.scripts:remove(trainer)
	trainer:close()
end)
