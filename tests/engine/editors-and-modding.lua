local JsonDecode = require "loxel.lib.json"

check("JSONBuilder escapes special characters, handles NaN/Inf, and round-trips", function()
	local payload = {
		title = 'Song "Quoted" \\ Line1\nLine2\tTab\b\f\r' .. string.char(1),
		nanVal = 0 / 0,
		infVal = math.huge,
		colors = {146, 113, 253},
		nested = {ok = true, empty = {}}
	}
	local encoded = JSON.encode(payload, true)
	assert(encoded:find('"nanVal": 0', 1, true), "NaN must serialize safely as 0")
	assert(encoded:find('"infVal": 0', 1, true), "Inf must serialize safely as 0")
	local decoded = JsonDecode.decode(encoded)
	assert(decoded.title == payload.title, "escaped string must decode identically")
	assert(decoded.nanVal == 0 and decoded.infVal == 0, "NaN/Inf round-trip safely")
	assert(decoded.colors[1] == 146 and decoded.colors[3] == 253, "numeric array round-trip")
	assert(decoded.nested.ok == true, "boolean field round-trip")
end)

check("All 10 loxel.ui widgets instantiate, update, and draw cleanly", function()
	local state = State()
	local grid = ui.UIGrid(0, 0, 4, 4, 16, Color.WHITE, Color.GRAY)
	local btn = ui.UIButton(10, 10, 100, 26, "Click")
	local cb = ui.UICheckbox(10, 44, 20)
	local slider = ui.UISlider(10, 74, 120, 12, 0.5, 0, 1, 0.1)
	local input = ui.UIInputTextBox(10, 96, 140, 24)
	local stepper = ui.UINumericStepper(10, 128, 0.1, 1.0, 0, 10, 120, 24)
	local dd = ui.UIDropDown(10, 160, {"One", "Two", "Three"}, 1, 120, 24)
	local tabs = ui.UITabMenu(200, 10, {"TabA", "TabB"}, 260, 220)
	local tabContent = Group()
	local innerBtn = ui.UIButton(12, 12, 80, 24, "Inner")
	tabContent:add(innerBtn)
	tabs:addGroup(tabContent, 1)
	local nav = ui.UINavbar({{"File", function() end}, {"Help", function() end}})
	local win = ui.UIWindow(480, 40, 200, 150, "Inspector")

	for _, w in ipairs({grid, btn, cb, slider, input, stepper, dd, tabs, nav, win}) do
		state:add(w)
	end
	state:update(1 / 60)
	assert(innerBtn.offsetX == 200 and innerBtn.offsetY == 10 + tabs.tabHeight,
		"UITabMenu must propagate container offsets to child widgets")

	-- Verify stepper float rounding avoids 0.30000000000000004 drift
	stepper:setValue(0.1 + 0.2)
	assert(stepper.text == "0.3", "UINumericStepper must round clean decimals, got: " .. tostring(stepper.text))

	local canvas = love.graphics.newCanvas(game.width, game.height)
	canvas:renderTo(function() state:draw() end)
	canvas:release()
	state:destroy()
end)

check("ModAPI scaffolds mod template, persists mod data, and keeps compat opt-in", function()
	local modRoot = Mods.root or "mods"
	local modId = "unit-test-mod-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
	local ok, pathMsg = ModAPI.createTemplate(modId, {
		name = "Unit Test Mod",
		description = "Automated template verification"
	})
	assert(ok, "ModAPI.createTemplate failed: " .. tostring(pathMsg))
	assert(love.filesystem.getInfo(modRoot .. "/" .. modId .. "/meta.json", "file"), "meta.json must exist")
	assert(love.filesystem.getInfo(modRoot .. "/" .. modId .. "/songs/bopeebo/charts/normal.json", "file"), "starter chart must exist")
	assert(love.filesystem.getInfo(modRoot .. "/" .. modId .. "/data/weeks/week1.json", "file"), "starter week must exist")

	assert(ModAPI.saveData("highscore_flag", {cleared = true, stars = 3}))
	local loaded = ModAPI.loadData("highscore_flag")
	assert(type(loaded) == "table" and loaded.cleared == true and loaded.stars == 3, "ModAPI save/load round-trip")

	-- Verify Mod is available in native scripts via environment metatable without polluting rawget(variables)
	assert(Storage.writeFile("assets/data/scripts/mod_env_probe.lua", [[
		function checkMod()
			return type(Mod) == "table" and type(Mod.flash) == "function"
		end
	]]))
	local scr = Script("data/scripts/mod_env_probe", false)
	assert(rawget(scr.variables, "getProperty") == nil, "compat globals must stay opt-in")
	assert(rawget(scr.variables, "Mod") == nil, "Mod must live on shared env metatable, not raw variables")
	assert(scr:call("checkMod") == true, "Mod table must be accessible inside scripts")
	scr:close()
end)

check("EditorMenu opens, navigates, and cleans up throttles on close", function()
	local beforeCount = #Throttle.list
	local host = State()
	game.switchState(host, true)
	game.update(1 / 60)
	local menu = EditorMenu()
	host:openSubstate(menu)
	game.update(1 / 60)
	menu:changeSelection(1)
	assert(menu.curSelected == 2, "EditorMenu selection must advance")
	menu:close()
	assert(#Throttle.list == beforeCount, "EditorMenu must destroy all throttles on close")
end)

check("ChartingState edits notes/events, supports undo/redo, and round-trips chart JSON", function()
	PlayState.loadSong("bopeebo", "normal")
	local charter = ChartingState()
	game.switchState(charter, true)
	game.update(1 / 60)
	game.draw()

	assert(not charter:isTyping(), "ChartingState must not lock keyboard shortcuts when inputs are unfocused")

	-- Clear & place specific notes + custom event
	charter:pushUndo()
	charter.song.notes.player = {}
	charter.song.notes.enemy = {}
	charter.song.events = {}

	table.insert(charter.song.notes.player, {t = 500, d = 0, l = 250})
	table.insert(charter.song.notes.player, {t = 1000, d = 2, l = 0, gf = true})
	table.insert(charter.song.notes.enemy, {t = 1500, d = 3, l = 125, k = "alt"})
	table.insert(charter.song.notes.player, {t = 2000, d = 1, l = 0, k = "Hurt Note"})
	table.insert(charter.song.events, {t = 1000, e = "Add Camera Zoom", v = {"0.02", "0.04"}})

	-- Undo & Redo check
	charter:pushUndo()
	charter.song.notes.player = {}
	assert(#charter.song.notes.player == 0)
	charter:undo()
	assert(#charter.song.notes.player == 3, "Undo must restore 3 player notes")

	-- Save chart and parse back through vanilla parser
	charter.song.song = "roundtrip-test"
	charter.curDifficulty = "hard"
	local savedOk, savedPath = charter:saveChart(false)
	assert(savedOk, "ChartingState:saveChart failed: " .. tostring(savedPath))

	local reparsed = Parser.getChart("roundtrip-test", "hard")
	assert(#reparsed.notes.player == 3, "Reparsed chart must have 3 player notes, got " .. #reparsed.notes.player)
	assert(#reparsed.notes.enemy == 1, "Reparsed chart must have 1 enemy note, got " .. #reparsed.notes.enemy)
	assert(reparsed.notes.player[1].l == 250, "Sustain length must survive round-trip")
	assert(reparsed.notes.player[2].gf == true, "GF Sing flag must survive round-trip")
	assert(reparsed.notes.enemy[1].k == "alt", "Alt anim flag must survive round-trip")
	assert(reparsed.notes.player[3].k == "Hurt Note", "Custom note type must survive round-trip")

	local foundZoomEv = false
	for _, ev in ipairs(reparsed.events) do
		if ev.e == "Add Camera Zoom" then foundZoomEv = true end
	end
	assert(foundZoomEv, "Custom chart event must survive round-trip")
end)

check("CharacterEditor & CutsceneState run cleanly and save valid JSON", function()
	CharacterEditor.onPlayState = false
	local charEd = CharacterEditor()
	game.switchState(charEd, true)
	game.update(1 / 60)
	game.draw()
	assert(not charEd:isTyping(), "CharacterEditor must not trap keyboard input when unfocused")

	charEd:changeOffsets(12, -8)
	assert(charEd.curAnim[6][1] == 12 and charEd.curAnim[6][2] == -8, "CharacterEditor offset update")
	charEd.inCharId.text = "bf-edited-test"
	local okSave = charEd:saveCharacter(false)
	assert(okSave, "CharacterEditor:saveCharacter must succeed cross-platform")
	local parsedChar = Parser.getCharacter("bf-edited-test")
	assert(parsedChar and parsedChar.animations[1][6][1] == 12, "Saved character JSON must round-trip offsets")

	-- Cutscene & Stage Editor
	local cutEd = CutsceneState()
	game.switchState(cutEd, true)
	game.update(1 / 60)
	game.draw()
	cutEd.inStageId.text = "custom-stage-test"
	cutEd.curZoom = 0.85
	cutEd:saveStageJSON()
	local parsedStage = Parser.getStage("custom-stage-test")
	assert(parsedStage and math.abs(parsedStage.cameraZoom - 0.85) < 0.001,
		"Native JSON stage saved from CutsceneState must parse via Parser.getStage")
end)

check("Notefield seekTo advances spawn cursor and updates notes every frame", function()
	local rawNotes = {
		{t = 200, d = 0, l = 0},
		{t = 800, d = 1, l = 0},
		{t = 5000, d = 2, l = 0},
		{t = 5500, d = 3, l = 0}
	}
	local nf = Notefield(0, 0, 4, "default", nil, nil, 1.0)
	nf:makeNotesFromChart(rawNotes)
	nf:seekTo(4.9)
	assert(#nf.activeNotes == 0, "Notes well before seek target must be skipped without spawning")
	nf.time = 4.95
	nf:update(1 / 60)
	assert(#nf.activeNotes >= 1 and nf.activeNotes[1].time == 5.0, "Upcoming notes after seek target must spawn cleanly")
	nf:destroy()
end)

check("ChartingState playback audio seek/tell, Soft-Keyboard TextInput, and direct PlayState switch work cleanly", function()
	PlayState.loadSong("bopeebo", "normal")
	local charter = ChartingState()
	game.switchState(charter, true)
	game.update(1 / 60)

	-- Regression for charting.lua:1209: attempt to call method 'seek' (a nil value)
	charter:seekMs(1250)
	charter:setPlaybackPlaying(true)
	game.update(1 / 60)
	if charter.inst then
		assert(type(charter.inst.seek) == "function" and type(charter.inst.tell) == "function",
			"Loxel Sound must expose seek() and tell() methods")
	end
	charter:setPlaybackPlaying(false)

	-- Soft keyboard / IME TextInput signal into UIInputTextBox and UINumericStepper
	local box = ui.UIInputTextBox(0, 0, 140, 24)
	box.focused = true
	TextInput:dispatch("mod_song")
	box:update(1 / 60)
	assert(box.text == "mod_song", "UIInputTextBox must accept TextInput signal, got: " .. tostring(box.text))
	box:destroy()

	local step = ui.UINumericStepper(0, 0, 1, 120, 20, 999, 120, 24)
	step.value = ""
	step.cursorPos = 0
	step.focused = true
	TextInput:dispatch("180")
	step:update(1 / 60)
	assert(step.text == "180", "UINumericStepper must accept TextInput text, got: " .. tostring(step.text))
	step:commitText(true)
	assert(step.numValue == 180, "UINumericStepper must commit numeric value, got: " .. tostring(step.numValue))
	step:destroy()

	-- Regression for play.lua:471: bad argument #1 to 'ipairs' (table expected, got nil)
	-- when switching directly into PlayState(false, startMs) from ChartingState / CharacterEditor
	PlayState.loadSong("bopeebo", "normal")
	local ps = PlayState(false, 800)
	assert(ps.startPos == 800, "PlayState(false, startMs) must set numeric startPos")
	game.switchState(ps, true)
	game.update(1 / 60)
	assert(type(ps.ratings) == "table" and #ps.ratings == 4, "PlayState:enter() must auto-preload ratings when not run via LoadScreen")
	ps:pauseSong()
	paths.async.stop()
end)

check("B5: Mod.button, Mod.addMenuButton, SpriteButton, UIButton touch, and custom-button-mod work cleanly", function()
	local modRoot = (Mods.root or "mods") .. "/custom-button-mod-test"
	Storage.ensureDir(modRoot .. "/data/states")
	Storage.ensureDir(modRoot .. "/data/scripts")
	Storage.writeFile(modRoot .. "/meta.json", assert(love.filesystem.read("examples/custom-button-mod/meta.json")))
	Storage.writeFile(modRoot .. "/data/states/mainmenu.lua",
		assert(love.filesystem.read("examples/custom-button-mod/data/states/mainmenu.lua")))
	Storage.writeFile(modRoot .. "/data/scripts/hud-button.lua",
		assert(love.filesystem.read("examples/custom-button-mod/data/scripts/hud-button.lua")))

	Mods.reload()
	local prevMod = Mods.currentMod
	Mods.currentMod = "custom-button-mod-test"

	local mm = MainMenuState()
	game.switchState(mm, true)
	game.update(1 / 60)
	assert(mm.menuItems[#mm.menuItems] == "bonusbop",
		"custom-button-mod must register 'bonusbop' in MainMenuState.menuItems")
	mm.menuList:setSelection(#mm.menuItems, true)
	mm:enterSelection("bonusbop")
	for _ = 1, 80 do
		Timer.globalManager:update(1 / 60)
		game.update(1 / 60)
	end
	assert(not mm.selectedSomethin and not mm.menuList.lock,
		"MainMenuState stay=true custom button must unlock menu after selection")

	local uiTouches = 0
	local btn = ModAPI.button("test_ui_btn", 40, 40, 140, 40, "Tap Test", function()
		uiTouches = uiTouches + 1
	end)
	assert(ModAPI.get("test_ui_btn") == btn, "Mod.get must retrieve tagged Mod.button")
	game.touchpressed("b5_touch", 80, 60, 0, 0, 1, 0)
	game.update(1 / 60)
	game.touchreleased("b5_touch", 80, 60, 0, 0, 1, 0)
	game.update(1 / 60)
	assert(uiTouches == 1, "UIButton created via Mod.button must respond to touch, got " .. tostring(uiTouches))
	assert(ModAPI.remove("test_ui_btn") and ModAPI.get("test_ui_btn") == nil,
		"Mod.remove must remove and unregister tagged button")

	local sprClicks = 0
	local sprBtn = SpriteButton(200, 120, "f7", "menus/menuBG", function()
		sprClicks = sprClicks + 1
	end)
	mm:add(sprBtn)
	game.mousepressed(220, 140, 1)
	game.update(1 / 60)
	game.mousereleased(220, 140, 1)
	game.update(1 / 60)
	assert(sprClicks == 1, "SpriteButton must load string texture keys and fire callback on click")
	mm:remove(sprBtn)
	sprBtn:destroy()

	local timerFired = false
	ModAPI.timer(0.05, function() timerFired = true end)
	for _ = 1, 6 do
		Timer.globalManager:update(1 / 60)
		game.update(1 / 60)
	end
	assert(timerFired, "Mod.timer must fire callback without nil method errors")

	Mods.currentMod = prevMod
	paths.async.stop()
end)

check("Editor saves target saves/ by default with saves/ > mods/ > assets/ priority", function()
	local prevMod = Mods.currentMod
	Mods.currentMod = nil

	PlayState.loadSong("bopeebo", "normal")
	local charter = ChartingState()
	game.switchState(charter, true)
	game.update(1 / 60)

	local prefix = charter:getSaveBasePrefix()
	local savesRoot = Storage.getContentRoot("saves") .. "/"
	assert(prefix == savesRoot,
		"Editor save prefix without active mod must be '" .. savesRoot .. "', got '" .. tostring(prefix) .. "'")
	assert(prefix ~= "assets/", "Editor save prefix must never be 'assets/'")

	charter.song.song = "priority-probe-song"
	charter.curDifficulty = "normal"
	charter.song.bpm = 148
	local okChart, savedChartPath = charter:saveChart(false)
	assert(okChart, "ChartingState:saveChart(false) must succeed: " .. tostring(savedChartPath))
	local okMeta, savedMetaPath = charter:saveSongMeta()
	assert(okMeta, "ChartingState:saveSongMeta() must succeed: " .. tostring(savedMetaPath))

	local expectedRelChart = savesRoot .. "songs/priority-probe-song/charts/normal.json"
	local expectedRelMeta = savesRoot .. "songs/priority-probe-song/meta.json"
	assert(paths.exists(expectedRelChart, "file"), "Saved chart must exist in saves/: " .. expectedRelChart)
	assert(paths.exists(expectedRelMeta, "file"), "Saved meta must exist in saves/: " .. expectedRelMeta)
	assert(not paths.exists("assets/songs/priority-probe-song/charts/normal.json", "file"),
		"Editor must never write charts under assets/")

	-- Verify priority: saves/ > mods/ > assets/
	local modId = "priority-probe-mod"
	local modRoot = (Mods.root or "mods") .. "/" .. modId
	Storage.writeFile(modRoot .. "/meta.json", '{"name":"Priority Probe"}')
	Storage.writeFile(modRoot .. "/songs/bopeebo/meta.json",
		'{"version":"2.2.4","songName":"ModBopeebo","timeChanges":[{"t":0,"bpm":111}],"playData":{"stage":"stage","difficulties":["normal"],"characters":{"player":"bf","opponent":"dad","girlfriend":"gf"}}}')
	Mods.reload()
	Mods.currentMod = modId
	paths.clearCache()
	assert(paths.getPath("songs/bopeebo/meta.json") == modRoot .. "/songs/bopeebo/meta.json",
		"mods/ must override assets/ when saves/ has no override")

	Storage.writeFile(savesRoot .. "songs/bopeebo/meta.json",
		'{"version":"2.2.4","songName":"SaveBopeebo","timeChanges":[{"t":0,"bpm":133}],"playData":{"stage":"stage","difficulties":["normal"],"characters":{"player":"bf","opponent":"dad","girlfriend":"gf"}}}')
	paths.clearCache()
	assert(paths.getPath("songs/bopeebo/meta.json") == savesRoot .. "songs/bopeebo/meta.json",
		"saves/ must have higher priority than mods/ and assets/")

	-- Removing saves/ override restores mods/ or assets/ cleanly
	if Storage.mounted and Storage.savePath then
		os.remove(Storage.savePath .. "/songs/bopeebo/meta.json")
	else
		love.filesystem.remove("saves/songs/bopeebo/meta.json")
	end
	paths.clearCache()
	assert(paths.getPath("songs/bopeebo/meta.json") == modRoot .. "/songs/bopeebo/meta.json",
		"Deleting saves/ override must fall back to active mod")
	Mods.currentMod = nil
	paths.clearCache()
	assert(paths.getPath("songs/bopeebo/meta.json") == "assets/songs/bopeebo/meta.json",
		"Deleting saves/ override with no mod active must restore base assets/")

	Mods.currentMod = prevMod
	Parser.clearCache()
	paths.async.stop()
end)

check("FreeplayState survives malformed metadata.json, displays Toast notice, and stays interactive", function()
	local prevMod = Mods.currentMod
	Mods.currentMod = nil
	local savesRoot = Storage.getContentRoot("saves") .. "/"

	-- Write a purposefully malformed metadata.json in saves/songs/bopeebo/meta.json
	Storage.writeFile(savesRoot .. "songs/bopeebo/meta.json", '{"version":"2.2.4"}')
	Parser.clearCache()
	paths.clearCache()

	local fp = FreeplayState()
	game.switchState(fp, true)
	game.update(1 / 60)

	local openOk, openErr = fp:openSong({
		songName = "bopeebo",
		diffs = {"normal"},
		meta = Parser.getMeta("bopeebo")
	})
	assert(openOk == false, "FreeplayState:openSong must refuse invalid metadata without crashing")
	assert(type(openErr) == "string"
		and openErr:find("bopeebo")
		and openErr:find("meta%.json")
		and openErr:find("playData"),
		"Error must report song, path, and failing field; got: " .. tostring(openErr))
	assert(fp.songs.lock == false, "FreeplayState must unlock song list after error")
	assert(game.getState() == fp, "Game must remain in FreeplayState")
	assert(Toast and #Toast.instances > 0, "Visible Toast error notice must be displayed")

	-- Clean up malformed override and verify bopeebo loads cleanly again
	if Storage.mounted and Storage.savePath then
		os.remove(Storage.savePath .. "/songs/bopeebo/meta.json")
	else
		love.filesystem.remove("saves/songs/bopeebo/meta.json")
	end
	Parser.clearCache()
	paths.clearCache()
	local okClean = PlayState.loadSong("bopeebo", "normal")
	assert(okClean == true, "Restoring saves/ override must let bopeebo load cleanly again")

	Mods.currentMod = prevMod
	paths.async.stop()
end)

check("PlayState:preload and LoadScreen resolve default, pixel, mod skins, and plain serialized skin tables", function()
	local prevMod = Mods.currentMod
	local modId = "skin-probe-mod"
	local modRoot = (Mods.root or "mods") .. "/" .. modId
	Storage.ensureDir(modRoot .. "/data/skins")
	local baseSkinJson = assert(love.filesystem.read("assets/data/skins/default.json"))
	Storage.writeFile(modRoot .. "/meta.json", '{"name":"Skin Probe Mod"}')
	Storage.writeFile(modRoot .. "/data/skins/mod-neon.json", baseSkinJson)
	Mods.reload()
	Mods.currentMod = modId
	paths.clearCache()

	for _, testCase in ipairs({
		{song = "bopeebo", diff = "normal", overrideSkin = nil, expected = "default"},
		{song = "senpai", diff = "normal", overrideSkin = nil, expected = "default-pixel"},
		{song = "bopeebo", diff = "normal", overrideSkin = "mod-neon", expected = "mod-neon"},
		-- Plain JSON table without metatable (reproducing legacy editor-serialized skin object)
		{song = "thorns", diff = "hard", overrideSkin = {skin = "default-pixel", isPixel = true, data = {}}, expected = "default-pixel"}
	}) do
		assert(PlayState.loadSong(testCase.song, testCase.diff))
		if testCase.overrideSkin ~= nil then
			PlayState.SONG.skin = testCase.overrideSkin
		end
		local loadState = LoadState(PlayState(false, nil, testCase.diff))
		game.switchState(loadState, true)
		game.update(1 / 60)
		assert(type(PlayState.SONG.skin) == "table" and type(PlayState.SONG.skin.getPath) == "function",
			"PlayState:preload must resolve PlayState.SONG.skin into a Skin instance with :getPath()")
		assert(PlayState.SONG.skin.skin == testCase.expected,
			"Expected skin '" .. testCase.expected .. "', got '" .. tostring(PlayState.SONG.skin.skin) .. "'")
		paths.async.stop()
	end

	if Timer and Timer.globalManager then Timer.globalManager:clear() end
	Mods.currentMod = prevMod
	Parser.clearCache()
	paths.clearCache()
	paths.async.stop()
end)

check("B6: Pause & resume work across keyboard, gamepad, and mobile touch in normal gameplay, post-dialogue, post-cutscene, and post-alt-tab", function()
	local origGetDevice = love.system.getDevice
	local origJoystick = controls.config.joystick

	-- Mock connected gamepad for baton
	local padState = {}
	local mockJoy = {
		isConnected = function() return true end,
		isGamepad = function() return true end,
		isGamepadDown = function(_, btn) return padState[btn] == true end,
		isDown = function() return false end,
		getGamepadAxis = function() return 0 end,
		getAxis = function() return 0 end,
		getHat = function() return "c" end
	}
	controls.config.joystick = mockJoy

	local function stepFrame(dt)
		dt = dt or (1 / 60)
		controls:update()
		game.update(dt)
	end

	-- Boot PlayState under Mobile device mode so VirtualPad + PauseButton + lane pads are all active
	love.system.getDevice = function() return "Mobile" end
	PlayState.storyMode = false
	assert(PlayState.loadSong("fresh", "normal"))
	local ps = PlayState(false, nil, "normal")
	game.switchState(ps, true)
	for _ = 1, 8 do
		stepFrame()
	end
	assert(ps.startedCountdown and ps.pauseButton ~= nil and ps.buttons ~= nil,
		"Mobile PlayState must create both pauseButton and 4-lane VirtualPad buttons")

	local pausePad = ps.pauseButton.pauseButton.button
	local px = pausePad.x + pausePad.width * 0.5
	local py = pausePad.y + pausePad.height * 0.5

	local function verifyAllThreeInputs(phaseLabel)
		-- 1) Mobile touch on top-right PauseButton pauses, and Mobile 'B' button resumes
		assert(ps.substate == nil, phaseLabel .. ": expected unpaused before mobile touch")
		game.touchpressed("b6_mob", px, py, 0, 0, 1, 0)
		stepFrame()
		game.touchreleased("b6_mob", px, py, 0, 0, 1, 0)
		assert(ps.substate ~= nil and ps.substate:is(PauseSubstate),
			phaseLabel .. ": Mobile touch on PauseButton must open PauseSubstate")
		for _ = 1, 14 do stepFrame() end
		local bBtn = ps.substate.buttons and ps.substate.buttons.members[1]
		assert(bBtn ~= nil, phaseLabel .. ": PauseSubstate on Mobile must create 'B' back button")
		local bx, by = bBtn.x + bBtn.width * 0.5, bBtn.y + bBtn.height * 0.5
		game.touchpressed("b6_back", bx, by, 0, 0, 1, 0)
		stepFrame()
		game.touchreleased("b6_back", bx, by, 0, 0, 1, 0)
		stepFrame()
		assert(ps.substate == nil, phaseLabel .. ": Mobile 'B' button must resume gameplay from PauseSubstate")

		-- 2) Gamepad 'start' pauses and Gamepad 'start' resumes
		padState.start = true
		controls:onGamepadPress(mockJoy, "start")
		stepFrame()
		padState.start = false
		controls:onGamepadRelease(mockJoy, "start")
		stepFrame()
		assert(ps.substate ~= nil and ps.substate:is(PauseSubstate),
			phaseLabel .. ": Gamepad Start must open PauseSubstate")
		padState.start = true
		controls:onGamepadPress(mockJoy, "start")
		stepFrame()
		padState.start = false
		controls:onGamepadRelease(mockJoy, "start")
		stepFrame()
		assert(ps.substate == nil, phaseLabel .. ": Gamepad Start must resume from PauseSubstate")

		-- 3) Keyboard Return pauses and Keyboard Escape resumes
		controls:onKeyPress("return", "return", false)
		controls:onKeyRelease("return", "return")
		stepFrame()
		assert(ps.substate ~= nil and ps.substate:is(PauseSubstate),
			phaseLabel .. ": Keyboard Return must open PauseSubstate")
		stepFrame()
		controls:onKeyPress("escape", "escape", false)
		controls:onKeyRelease("escape", "escape")
		stepFrame()
		assert(ps.substate == nil, phaseLabel .. ": Keyboard Escape must resume from PauseSubstate")
	end

	-- Phase 1: Normal gameplay
	verifyAllThreeInputs("Normal gameplay")

	-- Phase 2: Right after dialogue closes
	local dlg = DialogueBox("pixel", "normal", "senpai")
	ps:add(dlg)
	stepFrame()
	assert(ps:hasActiveDialogue(), "DialogueBox must be active during dialogue")
	dlg._closed = true
	if dlg.button and dlg.button.leave then dlg.button:leave() end
	ps:remove(dlg)
	stepFrame() -- clears hadDialogue latching frame cleanly
	verifyAllThreeInputs("Right after dialogue")

	-- Phase 3: Right after cutscene completion (both startCountdown and skipCountdown paths)
	ps:remove(ps.buttons)
	ps:startCountdown()
	stepFrame()
	verifyAllThreeInputs("Right after cutscene")

	-- Phase 4: Right after alt-tab (focus lost -> focus regained)
	if funkin and funkin.releaseStuckInputs then funkin.releaseStuckInputs(true) end
	game.focus(false)
	stepFrame()
	game.focus(true)
	stepFrame()
	verifyAllThreeInputs("After alt-tab")

	ps:pauseSong()
	controls.config.joystick = origJoystick
	love.system.getDevice = origGetDevice
	paths.async.stop()
end)

check("TexturePacker JSON atlases, UTF-8 BOM JSON/XML, and mod excludeAssets", function()
	local FrameCollection = require "loxel.animation.frame.collection"
	local imgData = love.image.newImageData(64, 64)
	local tex = love.graphics.newImage(imgData)

	-- 1. JSON Hash with UTF-8 BOM, unsorted keys, trim offsets, and rotation
	local bom = "\239\187\191"
	local hashJson = bom .. JSON.encode({
		frames = {
			["idle0001"] = {
				frame = {x = 16, y = 0, w = 12, h = 20},
				rotated = false,
				trimmed = true,
				spriteSourceSize = {x = 4, y = 6, w = 12, h = 20},
				sourceSize = {w = 24, h = 32}
			},
			["idle0000"] = {
				frame = {x = 0, y = 0, w = 16, h = 24},
				rotated = true,
				trimmed = false,
				spriteSourceSize = {x = 0, y = 0, w = 16, h = 24},
				sourceSize = {w = 16, h = 24}
			}
		}
	})
	local colHash = FrameCollection.fromTexturePackerJson(tex, hashJson)
	assert(colHash:getFrameCount() == 2, "JSON Hash must load 2 frames")
	local f0 = colHash:getFrame(1)
	local f1 = colHash:getFrame(2)
	assert(f0.name == "idle0000" and f1.name == "idle0001", "JSON Hash frames must sort deterministically by key")
	assert(f0.rotated == true, "Rotated flag must be preserved")
	local _, _, qw0, qh0 = f0.quad:getViewport()
	assert(qw0 == 24 and qh0 == 16, "Rotated TexturePacker quad must swap packed w/h")
	assert(f1.offset.x == -4 and f1.offset.y == -6, "spriteSourceSize trim offset must negate to Sparrow convention")
	assert(f1.width == 24 and f1.height == 32, "sourceSize dimensions must populate frame width/height")

	-- 2. JSON Array format
	local arrJson = JSON.encode({
		frames = {
			{filename = "singLEFT0000", frame = {x = 0, y = 0, w = 10, h = 10}, spriteSourceSize = {x = 2, y = 3, w = 10, h = 10}, sourceSize = {w = 14, h = 16}},
			{filename = "singLEFT0001", frame = {x = 10, y = 0, w = 10, h = 10}, spriteSourceSize = {x = 0, y = 0, w = 10, h = 10}, sourceSize = {w = 10, h = 10}}
		}
	})
	local colArr = FrameCollection.fromTexturePackerJson(tex, arrJson)
	assert(colArr:getFrameCount() == 2 and colArr:getFrame(1).name == "singLEFT0000", "JSON Array must preserve array order")

	-- 3. paths.excludeAssets strips active mod and addon subpaths
	local prevMod = Mods.currentMod
	Mods.currentMod = "test-mod-atlas"
	local stripped = paths.excludeAssets(Mods.root .. "/test-mod-atlas/images/SATAN")
	Mods.currentMod = prevMod
	assert(stripped == "images/SATAN", "excludeAssets must strip active mod folder prefix, got: " .. tostring(stripped))

	colHash:destroy()
	colArr:destroy()
	tex:release()
	imgData:release()
end)

check("Psych events.json envelope, stage defaultZoom, and character sing_duration parse cleanly", function()
	local vanillaChart = require "funkin.backend.parser.chart.vanilla"
	local stageParser = require "funkin.backend.parser.stage"
	local psychChar = require "funkin.backend.parser.character.psych"

	-- 1. Psych events.json {"song": {"events": [...]}} + inline chart events deduplicated & merged
	local rawChart = {
		song = {
			song = "Dejection",
			bpm = 140,
			speed = 2.6,
			stage = "vecindario",
			player1 = "bf-retro",
			player2 = "mouse",
			gfVersion = "gf-retro",
			events = {
				{1000, {{"Add Camera Zoom", "0.02", "0.04"}}},
				{2000, {{"Play Animation", "risa", "dad"}}}
			},
			notes = {
				{
					mustHitSection = true,
					sectionNotes = {
						{500, 0, 0, "Alt Animation"},
						{750, 1, 0, "No Animation"}
					}
				}
			}
		}
	}
	local externalEvents = {
		song = {
			events = {
				{1000, {{"Add Camera Zoom", "0.02", "0.04"}}}, -- duplicate of inline -> must fire once
				{1500, {{"Screen Shake", "0.5, 0.02", ""}}}
			}
		}
	}
	local parsed = vanillaChart.parse(rawChart, externalEvents, nil, "hard")
	local psychEvCount = 0
	for _, ev in ipairs(parsed.events) do
		if ev.psych then psychEvCount = psychEvCount + 1 end
	end
	assert(psychEvCount == 3, "Expected 3 merged/deduplicated Psych events, got " .. tostring(psychEvCount))
	assert(parsed.notes.player[1].k == "alt", "Alt Animation noteType must normalize to 'alt'")
	assert(parsed.notes.player[2].k == "No Animation", "No Animation noteType must remain inspectable")

	-- 2. Stage defaultZoom
	local st = stageParser.getParser({defaultZoom = 0.67, boyfriend = {770, 100}, opponent = {100, 99}}).parse({
		defaultZoom = 0.67, boyfriend = {770, 100}, opponent = {100, 99}
	})
	assert(math.abs(st.cameraZoom - 0.67) < 1e-6, "Psych stage defaultZoom must populate cameraZoom")

	-- 3. Psych character sing_duration
	local ch = psychChar.parse({
		image = "characters/BOYFRIEND",
		healthicon = "bf",
		sing_duration = 6.1,
		animations = {}
	})
	assert(math.abs(ch.sing_duration - 6.1) < 1e-6, "Psych character sing_duration must be preserved")
end)

check("Ultrawide 1612x720 viewports frame standard and pixel-perfect stages without black overflow", function()
	local oldW, oldH = game.width, game.height
	local ok, err = pcall(function()
		game.width, game.height = 1612, 720

		-- 1. Pixel-perfect camera authored at 1280/6 x 720/6 (213x120) expands cleanly to ceil(1612/6)=269x120
		local pixCam = Camera()
		pixCam:resize(math.floor(1280 / 6), math.floor(720 / 6), 1, 1, true)
		pixCam.pixelPerfect = true
		pixCam:syncPixelPerfectWidth()
		assert(pixCam.width == 269 and pixCam.height == 120,
			"Expected ultrawide pixel camera 269x120, got " .. tostring(pixCam.width) .. "x" .. tostring(pixCam.height))
		assert(pixCam.__pixelScaleDivisor == 6, "Expected pixel scale divisor 6")

		-- Clamp pixel camera inside evilSchoolFG (311x161 with wiggle pad)
		pixCam.minScrollX, pixCam.maxScrollX = 5, 306
		pixCam.minScrollY, pixCam.maxScrollY = 3, 157
		pixCam.target = Point(240, 130)
		pixCam:snapToTarget()
		assert(pixCam.scroll.x + pixCam.width <= 306.001, "Pixel camera right edge must stay within stage bounds")
		assert(pixCam.scroll.y + pixCam.height <= 157.001, "Pixel camera bottom edge must stay within stage bounds")
		if pixCam.canvas then pixCam.canvas:release(); pixCam.canvas = nil end

		-- 2. Standard ultrawide stage (tank-like sky + ground) expands sky & clamps horizontal scroll
		local stdCam = Camera(0, 0, 1612, 720)
		stdCam.zoom = 0.9
		local stg = Stage("")
		stg.camZoom = 0.9
		local sky = Graphic(-380, -204, 1830, 762)
		sky.scrollFactor:set(0, 0)
		stg:add(sky)
		local ground = Graphic(-420, 534, 2208, 485)
		ground.scrollFactor:set(1, 1)
		stg:add(ground)

		stg:fitViewport(stdCam)
		stdCam.target = Point(980, 450)
		stdCam:snapToTarget()

		local halfViewW = (stdCam.width * 0.5) / stdCam.zoom
		local viewRight = (stdCam.scroll.x + stdCam.width * 0.5) + halfViewW
		assert(viewRight <= 1788.01, "Ultrawide camera right edge spilled past tankGround: " .. tostring(viewRight))

		local skyX, _, skyW = sky:getWorldBounds()
		local w2 = stdCam.width * 0.5
		local skyLeftScreen = w2 + (skyX - w2) * stdCam.zoom
		local skyRightScreen = w2 + (skyX + skyW - w2) * stdCam.zoom
		assert(skyLeftScreen <= 0.5 and skyRightScreen >= 1611.5,
			string.format("Ultrawide sky must cover [0, 1612], got [%.1f, %.1f]", skyLeftScreen, skyRightScreen))

		PlayState.resize({stage = stg, camZoom = 0.8}, 1280, 720)

		stg:destroy()
		if stdCam.canvas then stdCam.canvas:release(); stdCam.canvas = nil end
	end)
	game.width, game.height = oldW, oldH
	assert(ok, err)
end)

check("VSlice characters ground properly on legacy stages and resolve variant health icons", function()
	local iconPath, resolved = HealthIcon.resolveIconPath("pico-playable")
	assert(iconPath == "icons/pico" and resolved == "pico",
		"pico-playable must resolve to icons/pico instead of face, got " .. tostring(iconPath))

	local prevSong = PlayState.SONG
	PlayState.SONG = {
		song = "Ugh",
		player1 = "pico-playable",
		player2 = "tankman",
		gfVersion = "nene"
	}
	local ok, err = pcall(function()
		local stg = Stage("tank")
		stg:load()
		assert(stg.boyfriend and stg.boyfriend.y > 250,
			"pico-playable on legacy tank stage must be grounded (y > 250), got " .. tostring(stg.boyfriend and stg.boyfriend.y))
		assert(stg.gf and stg.gf.y > -50,
			"nene on legacy tank stage must be grounded (y > -50), got " .. tostring(stg.gf and stg.gf.y))
		stg:destroy()
	end)
	PlayState.SONG = prevSong
	assert(ok, err)
end)

check("Psych characters with non-unit scale update hitbox to match HaxeFlixel top-left origin", function()
	local savedRoot = Mods.root
	local savedMod = Mods.currentMod
	local modDir = "saves/__test_psych_scale_mod"
	love.filesystem.createDirectory(modDir .. "/data/characters")
	love.filesystem.createDirectory(modDir .. "/images/characters")

	local ok, err = pcall(function()
		local imgData = love.image.newImageData(100, 200)
		local pngBytes = imgData:encode("png"):getString()
		imgData:release()
		assert(love.filesystem.write(modDir .. "/images/characters/scaled_test.png", pngBytes))
		assert(love.filesystem.write(modDir .. "/images/characters/scaled_test.xml", [[<?xml version="1.0" encoding="utf-8"?>
<TextureAtlas imagePath="scaled_test.png">
	<SubTexture name="idle0000" x="0" y="0" width="100" height="200"/>
</TextureAtlas>]]))
		assert(love.filesystem.write(modDir .. "/data/characters/scaled-psych.json", [[{
	"image": "characters/scaled_test",
	"healthicon": "bf",
	"scale": 1.2,
	"position": [10, 20],
	"camera_position": [0, 0],
	"sing_duration": 6.1,
	"flip_x": false,
	"no_antialiasing": false,
	"animations": [
		{"anim": "idle", "name": "idle", "fps": 24, "loop": false, "indices": [], "offsets": [0, 0]}
	]
}]]))

		Mods.root = "saves"
		Mods.currentMod = "__test_psych_scale_mod"
		local ch = Character(100, 50, "scaled-psych", false)
		assert(ch.type == "Psych", "Expected Psych parser, got " .. tostring(ch.type))
		assert(math.abs(ch.width - 120) < 0.01 and math.abs(ch.height - 240) < 0.01,
			"Expected scaled hitbox 120x240, got " .. tostring(ch.width) .. "x" .. tostring(ch.height))
		assert(math.abs(ch.offset.x - (-10)) < 0.01 and math.abs(ch.offset.y - (-20)) < 0.01,
			"Expected top-left fixOffsets (-10, -20), got " .. tostring(ch.offset.x) .. ", " .. tostring(ch.offset.y))
		ch:destroy()
	end)

	Mods.root = savedRoot
	Mods.currentMod = savedMod
	love.filesystem.remove(modDir .. "/data/characters/scaled-psych.json")
	love.filesystem.remove(modDir .. "/images/characters/scaled_test.xml")
	love.filesystem.remove(modDir .. "/images/characters/scaled_test.png")
	love.filesystem.remove(modDir .. "/data/characters")
	love.filesystem.remove(modDir .. "/images/characters")
	love.filesystem.remove(modDir)
	assert(ok, err)
end)





