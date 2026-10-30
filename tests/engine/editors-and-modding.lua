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
