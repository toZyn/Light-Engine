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

	local field = state.playerNotefield
	local note = field:addNote(Note(10, 0, 0, "Hazard", field.skin))
	local proxy = require("funkin.backend.scripts.psych.notes").note(note, field, state)
	proxy.ignoreNote = true
	proxy.hitCausesMiss = true
	proxy.missHealth = 0.4
	assert(table.find(field:getNotes(10, 0), note))
	assert(not table.find(field:getNotes(10, nil, true), note))
	state.health = 1
	local misses, hits = state.misses, state.songHits
	state:goodNoteHit(note, 10)
	assert(math.abs(state.health - 0.6) < 0.0001)
	assert(state.misses == misses + 1 and state.songHits == hits)
end)

check('Psych stage separators preserve strict JSON as the default', function()
	local decode = (loxreq "lib.json").decode
	local source = '{"opponent":[100,100]\n"hide_girlfriend":true,}'
	assert(not pcall(decode, source))
	local stage = decode(source, nil, {relaxedObjectSeparators = true})
	assert(stage.hide_girlfriend and stage.opponent[2] == 100)
	assert(not pcall(decode, source))
end)

check("Psych Camera Follow Pos holds coordinates until explicitly released", function()
	local state = setmetatable({
		camFollow = Point(),
		cameraOffset = Point(),
		scripts = ScriptsHandler(),
		eventScripts = {},
		camSpeed = 1
	}, PlayState)
	state:executeEvent({e = "Camera Follow Pos", v = {"0", "345"}, psych = true})
	assert(state.psychForcedCamera and state.camFollow.x == 0 and state.camFollow.y == 345)
	state:cameraMovement(100, 200)
	assert(state.camFollow.x == 0 and state.camFollow.y == 345)
	state:executeEvent({e = "Camera Follow Pos", v = {"", ""}, psych = true})
	state:cameraMovement(100, 200)
	assert(not state.psychForcedCamera and state.camFollow.x == 100 and state.camFollow.y == 200)
end)

check("Psych note textures and score counters work in both note-hit callbacks", function()
	local asset = "psych-note-regression"
	local folder = "assets/images"
	assert(love.filesystem.createDirectory(folder))
	local image = love.image.newImageData(32, 32)
	image:encode("png", folder .. "/" .. asset .. ".png")
	image:release()
	local xml = {'<TextureAtlas imagePath="' .. asset .. '.png">'}
	for _, color in ipairs({"purple", "blue", "green", "red"}) do
		for _, suffix in ipairs({"0", " hold piece", " hold end"}) do
			xml[#xml + 1] = ('<SubTexture name="%s" x="0" y="0" width="32" height="32"/>'):format(color .. suffix)
		end
	end
	xml[#xml + 1] = "</TextureAtlas>"
	assert(love.filesystem.write(folder .. "/" .. asset .. ".xml", table.concat(xml)))

	local state = Group()
	state.scripts = ScriptsHandler()
	state.playerNotefield = Notefield(0, 0, 4, "default")
	state.enemyNotefield = Notefield(0, 0, 4, "default")
	local script = Script("tests/engine/compat-fixture.lua", false, true, true)
	script._psych = require("funkin.backend.scripts.compat").new(state, script, true)
	state.scripts:add(script)
	local api = script.variables
	local recalculations = 0
	state.recalculateRating = function() recalculations = recalculations + 1 end
	script:set("onSpawnNote", function(id)
		api.setPropertyFromGroup("notes", id, "texture", asset)
	end)
	script:set("goodNoteHit", function() api.addMisses(2) end)
	script:set("opponentNoteHit", function() api.addMisses(3) end)
	api.setPropertyFromClass("PlayState", "SONG.arrowSkin", asset)
	assert(api.getPropertyFromClass("states.PlayState", "SONG.arrowSkin") == asset)
	for _, field in ipairs({state.playerNotefield, state.enemyNotefield}) do
		local note = field:addNote(Note(0, 0, 4, "Glitch", field.skin))
		state.scripts:call("noteSpawn", note)
		assert(note.skin.psychTexture == asset and note.shader == nil)
		assert(note.texture == paths.getAtlas(asset).texture)
		assert(note.sustain.texture == note.texture and note.sustainEnd.texture == note.texture)
		assert(note.sustain:getCurrentFrame().name == "purple hold piece")
		assert(note.sustainEnd:getCurrentFrame().name == "purple hold end")
		api.setPropertyFromGroup("notes", script._psych.psychNoteIndex(note), "texture", "")
		assert(note.skin == field.skin and note.sustain:getCurrentFrame().name ~= "purple hold piece")
		state.scripts:call("postGoodNoteHit", note, 0, true)
	end
	assert(api.getMisses() == 5 and recalculations == 2)
	assert(api.getProperty("songMisses") == 5)
	state.psychSections = {
		{step = 0, mustHitSection = false},
		{step = 12, mustHitSection = true, altAnim = true},
		{step = 32, gfSection = true}
	}
	local sections = {}
	script:set("onSectionHit", function()
		sections[#sections + 1] = {api.curSection, api.mustHitSection, api.altAnim, api.gfSection}
	end)
	for _, step in ipairs({0, 11, 12, 31, 32, 12}) do PlayState.updatePsychSection(state, step) end
	assert(#sections == 4 and sections[1][1] == 0)
	assert(sections[2][1] == 1 and sections[2][2] and sections[2][3])
	assert(sections[3][1] == 2 and sections[3][4] and sections[4][1] == 1)
	assert(not next(script.__failedfunc))
	script:close()
	state.playerNotefield:destroy()
	state.enemyNotefield:destroy()
end)
