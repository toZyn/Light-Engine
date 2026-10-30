-- Native LÖVE regression tests for:
-- 1. Conditional English "Recording" settings tab & "Gameplay only" (UI-free) vs "Entire game" capture
-- 2. Low-resource background worker AVI (MJPG/MPNG) video output
-- 3. Landscape viewport adaptation (portrait -> widescreen horizontal resize)
-- 4. GLSL ES 3.0 shader sanitization/compilation & Weekend 1 / Week 6 preload/icon fixes

check("Options hides Recording tab when disabled and exposes it in English when enabled", function()
	local prev = ClientPrefs.data.screenRecording
	ClientPrefs.data.screenRecording = false

	local tabsOff = Options.getTabList(false)
	assert(not table.find(tabsOff, "Recording"), "Recording tab must be hidden when disabled")

	local opts = Options(false)
	assert(not table.find(opts.settingsNames, "Recording"), "Options instance started with Recording hidden")

	ClientPrefs.data.screenRecording = true
	opts:syncRecordingTab()
	assert(table.find(opts.settingsNames, "Recording") == 3, "Recording tab must appear dynamically after Display")

	local recTab
	for _, member in ipairs(opts.tabGroup.members) do
		if member.name == "Recording" then recTab = member end
	end
	assert(recTab ~= nil and recTab.data ~= nil, "Recording tab UI must be instantiated")

	-- Verify English labels
	local labels = {}
	for _, item in ipairs(recTab.data.settings) do
		if item[2] then labels[item[1]] = item[2] end
	end
	assert(labels.recordingMode == "Capture mode", "Expected English 'Capture mode'")
	assert(labels.recordingAudio == "Record game audio", "Expected English 'Record game audio'")
	assert(labels.recordingQuality == "Video quality", "Expected English 'Video quality'")
	assert(labels.recordingScale == "Resolution scale", "Expected English 'Resolution scale'")
	assert(labels.recordingFps == "Frame rate", "Expected English 'Frame rate'")

	ClientPrefs.data.screenRecording = false
	opts:syncRecordingTab()
	assert(not table.find(opts.settingsNames, "Recording"), "Recording tab must hide again when disabled")

	opts:destroy()
	ClientPrefs.data.screenRecording = prev
end)

check("Gameplay-only capture includes stage and arrows (camNotes) while excluding HUD and camOther", function()
	local camGame = Camera()
	local camStage = Camera()
	local camHUD = Camera()
	local camNotes = Camera()
	local camOther = Camera()
	local allCams = {camGame, camStage, camHUD, camNotes, camOther}

	local mockPlay = {
		camNotes = camNotes,
		camHUD = camHUD,
		camOther = camOther,
		paused = false,
		inCutscene = false,
		substate = nil
	}

	local gpCams = Recorder.getCaptureCameras("gameplay", mockPlay, allCams)
	assert(#gpCams == 3, "Gameplay-only mode should capture stage cameras + camNotes only, got " .. #gpCams)
	assert(table.find(gpCams, camGame) ~= nil, "Stage main camera missing from gameplay capture")
	assert(table.find(gpCams, camStage) ~= nil, "Stage secondary camera missing from gameplay capture")
	assert(table.find(gpCams, camNotes) ~= nil, "Arrows/notes camera (camNotes) missing from gameplay capture")
	assert(table.find(gpCams, camHUD) == nil, "camHUD must NOT appear in Gameplay-only recording")
	assert(table.find(gpCams, camOther) == nil, "camOther must NOT appear in Gameplay-only recording")

	-- While paused or in cutscene, Gameplay-only captures 0 cameras (zero resource cost)
	mockPlay.paused = true
	assert(#Recorder.getCaptureCameras("gameplay", mockPlay, allCams) == 0, "Paused gameplay must pause capture")
	mockPlay.paused = false
	mockPlay.inCutscene = true
	assert(#Recorder.getCaptureCameras("gameplay", mockPlay, allCams) == 0, "Cutscene must pause gameplay-only capture")

	-- Entire-game mode captures all visible cameras including HUD and menus
	local entireCams = Recorder.getCaptureCameras("entire", mockPlay, allCams)
	assert(#entireCams == 5, "Entire-game mode should include all visible cameras")

	for _, c in ipairs(allCams) do c:destroy() end
end)

check("Recorder writes a valid 2-stream (mp4v + 44.1kHz Stereo ALAC) ISO-BMFF .mp4 off-thread and always saves on song end", function()
	local prevEnabled = ClientPrefs.data.screenRecording
	local prevMode = ClientPrefs.data.recordingMode
	local prevScale = ClientPrefs.data.recordingScale
	local prevFps = ClientPrefs.data.recordingFps
	local prevAudio = ClientPrefs.data.recordingAudio
	local prevQual = ClientPrefs.data.recordingQuality

	ClientPrefs.data.screenRecording = true
	ClientPrefs.data.recordingMode = "entire"
	ClientPrefs.data.recordingScale = 0.5
	ClientPrefs.data.recordingFps = 30
	ClientPrefs.data.recordingAudio = true
	ClientPrefs.data.recordingQuality = "high"

	local ok, outPath = Recorder.start("unit_test")
	assert(ok and type(outPath) == "string", "Recorder failed to start: " .. tostring(outPath))
	assert(outPath:sub(-4) == ".mp4", "Recorder output must be .mp4, got: " .. tostring(outPath))

	for i = 1, 4 do
		if i > 1 and love.timer and love.timer.sleep then
			love.timer.sleep(0.04)
		end
		Recorder.update(1 / 25)
		Recorder.preDraw()
		game.draw()
		Recorder.postDraw()
	end

	Recorder.stop(true)
	Recorder.shutdown()

	local f = assert(io.open(outPath, "rb"), "Expected MP4 file on disk: " .. tostring(outPath))
	local fullBytes = f:read("*a")
	f:close()
	os.remove(outPath)

	assert(#fullBytes > 2048, "Expected non-empty encoded video+audio MP4, got " .. tostring(#fullBytes))
	assert(fullBytes:sub(5, 12) == "ftypisom", "Invalid ISO-BMFF ftyp header in MP4")
	assert(fullBytes:find("mdat", 1, true) ~= nil, "Missing mdat media data box in MP4")
	assert(fullBytes:find("moov", 1, true) ~= nil, "Missing moov metadata box in MP4")
	assert(fullBytes:find("mp4v", 1, true) ~= nil, "Missing mp4v video sample entry in MP4")
	assert(fullBytes:find("alac", 1, true) ~= nil, "Missing alac lossless stereo audio sample entry in MP4")
	assert(fullBytes:find("soun", 1, true) ~= nil, "Missing soun audio handler box in MP4")

	ClientPrefs.data.screenRecording = prevEnabled
	ClientPrefs.data.recordingMode = prevMode
	ClientPrefs.data.recordingScale = prevScale
	ClientPrefs.data.recordingFps = prevFps
	ClientPrefs.data.recordingAudio = prevAudio
	ClientPrefs.data.recordingQuality = prevQual
end)

check("Animation boolean guard, Keyboard/VirtualPad resilience, and restored base stage state", function()
	-- 1. Animation:play boolean frame safety + 3-arg/4-arg Character:playAnim resilience
	local bf = Character(0, 0, "bf", true)
	bf:playAnim("idle", true, true)
	assert(bf.anim.curAnim ~= nil, "Character:playAnim must tolerate boolean 3rd arg without crashing")
	bf.anim:play("idle", true, false, true)
	assert(bf.anim.curAnim.frame >= 1, "Animation:play must clamp non-numeric Frame safely")
	bf:destroy()

	-- 2. External keyboard unknown/acback/isrepeat + vararg love.keyboard.isDown
	game.keys.onPressed("unknown", "unknown", false)
	game.keys.onPressed("acback", "acback", false)
	assert(game.keys.justPressed.ESCAPE == true, "Android acback must normalize to ESCAPE")
	game.keys.reset()
	game.keys.onPressed("a", "a", true)
	assert(not game.keys.justPressed.A, "Key repeat must not fire justPressed")
	game.keys.reset()
	assert(type(love.keyboard.isDown("lctrl", "rctrl")) == "boolean", "Vararg love.keyboard.isDown must work")

	-- 3. Restored v0.2.2 (1006f52) stage zooms, positions, and Week 6 pixel camera sizing
	PlayState.loadSong("bopeebo", "normal")
	local st1 = Stage("stage")
	st1:load()
	assert(math.abs(st1.camZoom - 1) < 1e-4, "Week 1 stage must preserve original camZoom 1")
	st1:destroy()

	PlayState.SONG.stage = "mall-evil"
	local stEvil = Stage("mall-evil")
	stEvil:load()
	assert(math.abs(stEvil.camZoom - 1) < 1e-4 and stEvil.dadPos.x == 100 and stEvil.dadPos.y == 100,
		"mall-evil must preserve original camZoom 1 and dadPos (100, 100)")
	stEvil:destroy()

	PlayState.SONG.stage = "school"
	local stSchool = Stage("school")
	stSchool:load()
	assert(game.camera.width == math.floor(1280 / 6) and game.camera.height == math.floor(720 / 6),
		"Week 6 school must preserve original 213x120 pixel camera")
	if stSchool.script and stSchool.script.variables.cam then
		game.cameras.remove(stSchool.script.variables.cam)
	end
	game.camera.pixelPerfect = false
	game.camera.antialiasing = true
	game.camera:resize(game.width, game.height)
	stSchool:destroy()
	paths.async.stop()
end)

check("FFT handles released LÖVE Sources and Loxel Sound wrappers without crashing", function()
	local FFT = require "funkin.backend.fft"

	local releasedMock = {
		isPlaying = function() error("Cannot use object after it has been released.", 0) end,
		tell = function() error("Cannot use object after it has been released.", 0) end
	}
	local fft1 = FFT(7, "songs/darnell/Inst.ogg", releasedMock)
	fft1:update(1 / 60)
	assert(fft1.externalSource == nil, "FFT must clear released externalSource safely")
	fft1:destroy()

	if game and game.sound and game.sound.music then
		local fft2 = FFT(7, "songs/darnell/Inst.ogg", game.sound.music)
		fft2:update(1 / 60)
		fft2:destroy()
	end
	FFT.stop()
end)

check("Portrait startup surface adapts automatically when rotating to widescreen landscape", function()
	local prevAdapt = Project.adaptableWidth
	local prevW, prevH = game.width, game.height
	Project.adaptableWidth = true

	game.resize(1080, 2400) -- transient portrait surface on mobile launch
	assert(game.width == Project.width and game.height == Project.height, "Portrait fallback dimensions wrong")

	game.resize(2400, 1080) -- rotated to 20:9 horizontal landscape
	assert(game.width == 1600 and game.height == 720, "Landscape adaptableWidth did not expand to 1600x720")
	if Transition then
		assert(Transition.width == 1600 and Transition.height == 720, "Transition bounds did not adapt to landscape")
	end

	Project.adaptableWidth = prevAdapt
	game.width, game.height = prevW, prevH
	game.resize(love.graphics.getDimensions())
end)

check("GLSL ES 3.0 shaders (rain, wiggle) and Weekend 1 AnimateAtlas / icon paths resolve cleanly", function()
	local rainShader = Shader("rain")
	assert(rainShader:get() ~= nil, "rain.frag must compile cleanly")
	rainShader.scale = 3.6
	rainShader.intensity = 0.2
	rainShader.distortionStrength = 0.5
	rainShader:update(0.016)
	rainShader:destroy()

	local wiggleShader = Shader("wiggle")
	assert(wiggleShader:get() ~= nil, "wiggle.frag must compile cleanly")
	wiggleShader:update(0.016)
	wiggleShader:destroy()

	-- Verify AnimateAtlas characters carry Animation.json under images/<sprite>/Animation.json
	for _, charName in ipairs({"darnell-blazin", "pico-blazin"}) do
		local data = Parser.getCharacter(charName)
		assert(data and data.sprite, "Missing character data for " .. charName)
		assert(paths.exists(paths.getPath("images/" .. data.sprite .. "/Animation.json"), "file"),
			"AnimateAtlas detection path failed for " .. charName .. " (" .. tostring(data.sprite) .. ")")
	end

	-- Verify multisparrow Nene carries secondary animation assetPath (anim[7])
	local neneData = Parser.getCharacter("nene")
	local foundSecondary = false
	for _, anim in pairs(neneData.animations or {}) do
		if type(anim) == "table" and anim[7] == "characters/Nene_Hair_Blowing" then
			foundSecondary = true
		end
	end
	assert(foundSecondary, "Expected Nene multisparrow secondary atlas in anim[7]")

	-- Verify HealthIcon resolves missing icon names to default face without crashing
	local resolvedPath = HealthIcon.resolveIconPath("nene")
	assert(paths.exists(paths.getPath("images/" .. resolvedPath .. ".png"), "file"),
		"HealthIcon fallback path does not exist: " .. tostring(resolvedPath))
end)

check("Cutscenes execute postCreate once, DialogueBox closes idempotently, and Timer.globalManager isolates callback errors visibly", function()
	PlayState.seenCutscene = false
	PlayState.loadSong("senpai", "normal")
	local ps = PlayState(true, {"senpai", "roses"}, "normal")
	game.switchState(ps, true)
	for _ = 1, 240 do
		game.update(1 / 60)
	end

	local boxes = {}
	for _, m in ipairs(ps.members) do
		if m.is and m:is(DialogueBox) then boxes[#boxes + 1] = m end
	end
	assert(#boxes == 1, "Cutscene postCreate must spawn exactly 1 DialogueBox, got " .. tostring(#boxes))

	local dlg = boxes[1]
	dlg:closeDialogue()
	dlg:closeDialogue() -- idempotent second call must not crash
	assert(ps.startedCountdown == true, "Closing cutscene DialogueBox must start song countdown")

	-- Reset pixel camera left by school stage before finishing test
	if ps.stage and ps.stage.script and ps.stage.script.variables.cam then
		game.cameras.remove(ps.stage.script.variables.cam)
	end
	game.camera.pixelPerfect = false
	game.camera.antialiasing = true
	game.camera:resize(game.width, game.height)

	-- Verify Timer.globalManager reports broken callback visibly without crashing or repeating
	local brokenCount, siblingCount = 0, 0
	Timer.wait(0.02, function()
		brokenCount = brokenCount + 1
		error("timer_callback_visible_probe")
	end)
	Timer.wait(0.02, function()
		siblingCount = siblingCount + 1
	end)
	game.update(0.05)
	game.update(0.05)
	assert(brokenCount == 1 and siblingCount == 1,
		"Broken global timer must fail once without blocking sibling timers")
	local report = love.filesystem.read("diagnostics/last-error.txt") or ""
	assert(report:find("timer_callback_visible_probe", 1, true) ~= nil,
		"Broken global timer must be visibly logged to diagnostics/last-error.txt")
	paths.async.stop()
end)

check("B1: Recorder defaults to 1.0x scale, scales pixelPerfect cameras to full frame, and tracks explicit Sound seeks", function()
	assert(ClientPrefs.data.recordingScale == 1.0,
		"Default recordingScale must be 1.0 for faithful live capture")
	assert((ClientPrefs.data.recordingProfileVersion or 0) >= 4,
		"recordingProfileVersion must be >= 4")

	-- Verify Sound._seekSeq increments on both :seek() and .time = ...
	local snd = Sound():load(love.sound.newSoundData(4410, 44100, 16, 2))
	local seq0 = snd._seekSeq or 0
	snd:seek(0.05)
	assert((snd._seekSeq or 0) == seq0 + 1, "Sound:seek() must increment _seekSeq")
	snd.time = 0.02
	assert((snd._seekSeq or 0) == seq0 + 2, "Sound.time assignment must increment _seekSeq")
	snd:destroy()

	-- Verify Week 6 pixelPerfect Camera (213x120, zoom=1) draws at 6x to fill 1280x720 target
	local pixelCam = Camera(0, 0, 213, 120)
	pixelCam.pixelPerfect = true
	pixelCam.__forceComplex = true
	pixelCam:draw()
	assert(pixelCam.canvas ~= nil, "pixelPerfect camera with __forceComplex must allocate canvas")

	local drawnSx, drawnSy
	local origDraw = love.graphics.draw
	love.graphics.draw = function(drawable, x, y, r, sx, sy, ...)
		if drawable == pixelCam.canvas then
			drawnSx, drawnSy = sx, sy
		end
		return origDraw(drawable, x, y, r, sx, sy, ...)
	end
	pixelCam:drawCanvasToTarget(1280, 720)
	love.graphics.draw = origDraw
	pixelCam:destroy()

	assert(drawnSx and math.abs(drawnSx - 6) < 0.05 and math.abs(drawnSy - 6) < 0.05,
		"pixelPerfect 213x120 camera must composite at ~6x onto 1280x720 target, got sx=" .. tostring(drawnSx))

	-- Verify Camera.__forceComplex falls back to non-stencil canvas when stencil8 is unsupported
	local origFormats = love.graphics.getTextureFormats
	love.graphics.getTextureFormats = function()
		return {normal = true, rgba8 = true, stencil8 = false}
	end
	Camera.__init()
	local fallbackCam = Camera(0, 0, 1280, 720)
	fallbackCam.__forceComplex = true
	fallbackCam:draw()
	local hasFallbackCanvas = fallbackCam.canvas ~= nil
	fallbackCam:destroy()
	love.graphics.getTextureFormats = origFormats
	Camera.__init()
	assert(hasFallbackCanvas, "Camera.__forceComplex must allocate canvas even without stencil8 support")
end)

check("B2: Keyboard and controller hotplug, focus flickers, and controls:reset never freeze or drop gameplay bindings", function()
	local mockPad = {
		_connected = true,
		_btn = true,
		isConnected = function(self) return self._connected end,
		isGamepad = function() return true end,
		getAxisCount = function() return 4 end,
		getAxis = function(self)
			if not self._connected then error("Joystick is not connected!", 2) end
			return 0
		end,
		getGamepadAxis = function(self)
			if not self._connected then error("Joystick is not connected!", 2) end
			return 0
		end,
		isDown = function(self)
			if not self._connected then error("Joystick is not connected!", 2) end
			return self._btn
		end,
		isGamepadDown = function(self)
			if not self._connected then error("Joystick is not connected!", 2) end
			return self._btn
		end,
		getHat = function(self)
			if not self._connected then error("Joystick is not connected!", 2) end
			return "c"
		end
	}

	local pressCalled = 0
	local function probePress() pressCalled = pressCalled + 1 end
	controls:bindPress(probePress)

	local cfg = table.clone(ClientPrefs.controls)
	table.insert(cfg.ui_down, "button:dpdown")
	controls:reset({controls = cfg, joystick = mockPad})
	assert(table.find(controls._pressBinds, probePress) ~= nil,
		"controls:reset must preserve active runtime _pressBinds")

	controls:update()
	assert(controls:getActiveDevice() == "joy", "Connected gamepad should become active device")

	mockPad._connected = false
	controls:update()
	assert(controls:getActiveDevice() ~= "joy" and controls.config.joystick == nil,
		"Disconnected joystick must cleanly clear activeDevice without throwing")

	controls:onKeyPress("down", "down", false)
	assert(pressCalled >= 1, "Preserved _pressBinds must still fire after controls:reset and hotplug")

	game.keys.onPressed("left", "left", false)
	assert(game.keys.pressed.LEFT == true, "Expected LEFT marked pressed before focus loss")
	;(require "funkin").releaseStuckInputs(true)
	assert(not game.keys.pressed.LEFT, "releaseStuckInputs must clear stuck held keys on unplug/focus loss")

	controls:unbindPress(probePress)
	controls:reset({controls = table.clone(ClientPrefs.controls)})
end)

check("B3: Receptors and baton release cleanly across dual-key spam, holdTime expiry, cross-device input, and VirtualPad:leave", function()
	local downDuringRelease = {}
	local function onRelProbe(source)
		if source == "left" or source == "a" then
			table.insert(downDuringRelease, {source = source, down = controls:down("note_left")})
		end
	end
	controls:bindRelease(onRelProbe)

	local mockPad = {
		_connected = true,
		_buttons = {},
		isConnected = function(self) return self._connected end,
		isGamepad = function() return true end,
		getAxisCount = function() return 4 end,
		getAxis = function() return 0 end,
		getGamepadAxis = function() return 0 end,
		isDown = function(self, b) return self._buttons[b] == true end,
		isGamepadDown = function(self, b) return self._buttons[b] == true end,
		getHat = function() return "c" end
	}
	local cfg = table.clone(ClientPrefs.controls)
	if not table.find(cfg.note_right, "button:dpright") then
		table.insert(cfg.note_right, "button:dpright")
	end
	controls:reset({controls = cfg, joystick = mockPad})

	-- 1) Dual-key chord on note_left ("left" + "a") via VirtualPad key state
	VirtualPad._press("left", 0)
	controls:onKeyPress("left", "left", false)
	VirtualPad._press("a", 0)
	controls:onKeyPress("a", "a", false)
	VirtualPad._release("left", 0)
	controls:onKeyRelease("left", "left")
	assert(#downDuringRelease == 1 and downDuringRelease[1].down == true,
		"Secondary key 'a' still held: controls:down('note_left') must remain true in onRelease")

	VirtualPad._release("a", 0)
	controls:onKeyRelease("a", "a")
	assert(#downDuringRelease == 2 and downDuringRelease[2].down == false,
		"Last key released: controls:down('note_left') must be false BEFORE _releaseBinds runs")

	-- 2) Cross-device simultaneous hold (gamepad dpright + keyboard left)
	mockPad._buttons.dpright = true
	controls:onGamepadPress(mockPad, "dpright")
	controls:update()
	VirtualPad._press("left", 0)
	controls:onKeyPress("left", "left", false)
	controls:update()
	mockPad._buttons.dpright = false
	controls:onGamepadRelease(mockPad, "dpright")
	assert(not controls:down("note_right"),
		"Releasing gamepad button while keyboard is active must clear note_right.down")
	VirtualPad._release("left", 0)
	controls:onKeyRelease("left", "left")

	-- 3) Receptor confirm holdTime expiry returns to static when key is not held
	local nf = Notefield(0, 0, 4, "default", nil, nil, 1.0)
	local receptor = nf.receptors[1]
	receptor.pressed = false
	receptor:play("confirm", true)
	receptor.holdTime = 0.05
	receptor:update(0.1)
	assert((receptor.animation.curAnim.name or ""):startsWith("static"),
		"Receptor holdTime expiry with pressed=false must return to static, got " .. tostring(receptor.animation.curAnim.name))
	nf:destroy()

	-- 4) VirtualPad:leave() releases active held touch key (e.g. during pause)
	local vpad = VirtualPad("down", 0, 0, 100, 100)
	vpad:enter()
	VirtualPad.press("b3_touch", 50, 50, 1, 0)
	assert(love.keyboard.isDown("down"), "Expected VirtualPad 'down' held after press")
	vpad:leave()
	assert(not love.keyboard.isDown("down"), "VirtualPad:leave() must clear held virtual key")
	vpad:destroy()

	controls:unbindRelease(onRelProbe)
	controls:reset({controls = table.clone(ClientPrefs.controls)})
end)

check("B4: DialogueBox hitboxes, Camera world/screen projection, Mouse/Touch overlaps, and VirtualPad Z-order work across normal/pixel modes and zooms", function()
	local host = State()
	game.switchState(host, true)
	game.update(1 / 60)

	-- 1) Pixel dialogue box: enter -> loop, rejects transparent headroom, accepts visible speech box click
	local pixDlg = DialogueBox("pixel", "default", "senpai")
	host:add(pixDlg)
	for _ = 1, 30 do
		Timer.globalManager:update(1 / 60)
		pixDlg:update(1 / 60)
	end
	assert(pixDlg.boxSpr.animation.curAnim.name == "loop",
		"Pixel DialogueBox must transition from enter to loop")
	assert(not pixDlg:overlapsPoint(640, 200),
		"Pixel DialogueBox must reject transparent headroom above speech box")
	assert(pixDlg:overlapsPoint(640, 560),
		"Pixel DialogueBox must accept clicks inside visible speech box")

	-- 2) Normal dialogue box + zoomed camera (0.5x) + scroll (300, 200)
	local zCam = Camera(0, 0, 1280, 720)
	zCam.scroll:set(300, 200)
	zCam.zoom = 0.5
	zCam:update(0)
	local normDlg = DialogueBox("default", "default", "senpai")
	normDlg.cameras = {zCam}
	host:add(normDlg)
	for _ = 1, 50 do
		Timer.globalManager:update(1 / 60)
		normDlg:update(1 / 60)
	end
	assert(normDlg.boxSpr.animation.curAnim.name == "loop",
		"Normal DialogueBox must transition from enter to loop")
	assert(not normDlg:overlapsPoint(640, 620, zCam),
		"Zoomed 0.5x DialogueBox must reject points outside shrunk screen bounds")
	assert(normDlg:overlapsPoint(640, 450, zCam),
		"Zoomed 0.5x DialogueBox must accept points inside shrunk screen bounds")
	normDlg.text:forceEnd()
	game.mousemoved(640, 450)
	game.mousepressed(640, 450, 1)
	normDlg:update(1 / 60)
	game.mousereleased(640, 450, 1)
	game.mouse.reset()
	assert(normDlg.curDialogue == 2,
		"Mouse click inside zoomed normal DialogueBox must advance curDialogue")

	-- 3) PixelPerfect (213x120) camera projection in Mouse.overlaps
	local pCam = Camera(0, 0, 213, 120)
	pCam.pixelPerfect = true
	local pObj = Graphic(20, 70, 170, 40, Color.WHITE)
	pObj.scrollFactor:set(0, 0)
	pObj.cameras = {pCam}
	game.mousemoved(640, 540)
	assert(Mouse.overlaps(pObj), "Mouse.overlaps must project through pixelPerfect 213x120 camera")
	game.mousemoved(640, 100)
	assert(not Mouse.overlaps(pObj), "Mouse.overlaps must reject points outside pixelPerfect bounds")

	-- 4) VirtualPad reverse Z-order: top-most overlay receives touch over underlying full-screen pad
	local bottomPad = VirtualPad("left", 0, 0, 1280, 720)
	local topPad = VirtualPad("return", 200, 400, 800, 250)
	bottomPad:enter()
	topPad:enter()
	local topHits, bottomHits = 0, 0
	bottomPad.onPress:add(function() bottomHits = bottomHits + 1 end)
	topPad.onPress:add(function() topHits = topHits + 1 end)
	local winW, winH = love.graphics.getDimensions()
	local sc = math.min(winW / game.width, winH / game.height)
	local sx = (winW - sc * game.width) / 2 + 640 * sc
	local sy = (winH - sc * game.height) / 2 + 520 * sc
	VirtualPad.press("b4_z", sx, sy, 1, 0)
	VirtualPad.release("b4_z", sx, sy, 1, 0)
	assert(topHits == 1 and bottomHits == 0,
		"Top-most VirtualPad must receive touch ahead of underlying pad")

	bottomPad:destroy()
	topPad:destroy()
	pixDlg:closeDialogue()
	normDlg:closeDialogue()
	zCam:destroy()
	pCam:destroy()
	paths.async.stop()
end)

check("Recorder Phase 1: native 48kHz ALAC, frame-drop prior-frame hold, muted stem cursor lock, <0 dBFS limiter, and Video._active tracking", function()
	local Mp4Muxer = require "funkin.backend.mp4_muxer"

	-- 1) Verify Video._active weak registry & lifecycle cleanup
	assert(type(Video._active) == "table", "Video._active registry must exist")
	if love.graphics.newVideo then
		local okV, vid = pcall(Video, 0, 0, "stressCutscene", false)
		if okV and vid then
			assert(Video._active[vid] == true, "Created Video must register in Video._active")
			assert(type(vid._sourcePath) == "string" and vid._sourcePath:find("stressCutscene%.ogv") ~= nil,
				"Video._sourcePath must resolve .ogv path for recorder audio capture")
			vid:play()
			assert((vid._playSeq or 0) >= 1, "Video:play() must increment _playSeq")
			vid:destroy()
			assert(Video._active[vid] == nil, "Destroyed Video must be removed from Video._active")
		end
	end

	-- 2) Verify recorder_thread: 48kHz ALAC header, prior-frame duplication across a 5-frame hitch,
	--    muted stem cursor advancement, and stereo soft-limiter (< 0 dBFS, zero clipped samples)
	local sdA = love.sound.newSoundData(4800, 48000, 16, 2)
	local sdB = love.sound.newSoundData(4800, 48000, 16, 2)
	for i = 0, 4799 do
		local s = math.sin(i * 0.25) * 0.98
		sdA:setSample(i, 1, s)
		sdA:setSample(i, 2, s)
		sdB:setSample(i, 1, s)
		sdB:setSample(i, 2, s)
	end

	local tmpMp4 = love.filesystem.getSaveDirectory() .. "/phase1_sync_test.mp4"
	local th = love.thread.newThread("funkin/backend/recorder_thread.lua")
	local cmdName, muxName, stName = "p1_cmd", "p1_mux", "p1_st"
	local cmdCh = love.thread.getChannel(cmdName)
	local muxCh = love.thread.getChannel(muxName)
	local stCh = love.thread.getChannel(stName)
	cmdCh:clear(); muxCh:clear(); stCh:clear()
	th:start(cmdName, muxName, stName)

	cmdCh:push({
		type = "start", session = 77, path = tmpMp4,
		width = 64, height = 64, fps = 60, fourcc = "MJPG",
		recordAudio = true, audioRate = 48000
	})
	local stStart = stCh:demand(3.0)
	assert(stStart and stStart.status == "started", "Expected recorder_thread started")

	local frameA = "FRAME_A_JPEG_BYTES_PAYLOAD"
	local frameB = "FRAME_B_JPEG_BYTES_PAYLOAD_AFTER_DROP"
	-- Frame 0 at t=0.000s (both stems full-scale -> raw sum ~1.96 > 0 dBFS!)
	muxCh:push({
		type = "encoded", session = 77, seq = 1, targetFrame = 0, ptsUs = 0,
		payload = frameA,
		audio = {
			{uid = "stemA", playSeq = 1, seekSeq = 0, soundData = sdA, time = 0, volume = 1.0, pitch = 1.0, looped = true},
			{uid = "stemB", playSeq = 1, seekSeq = 0, soundData = sdB, time = 0, volume = 1.0, pitch = 1.0, looped = true}
		}
	})
	-- Simulate 5 dropped frames (0..5 = 6 frame intervals of frameA held!), frameB arrives at targetFrame = 6
	muxCh:push({
		type = "encoded", session = 77, seq = 2, targetFrame = 6, ptsUs = 100000,
		payload = frameB,
		audio = {
			{uid = "stemA", playSeq = 1, seekSeq = 0, soundData = sdA, time = 0.1, volume = 1.0, pitch = 1.0, looped = true},
			{uid = "stemB", playSeq = 1, seekSeq = 0, soundData = sdB, time = 0.1, volume = 0.0, pitch = 1.0, looped = true}
		}
	})
	cmdCh:push({type = "quit", session = 77, lastSeq = 2, stopFrames = 8})
	local stSaved = stCh:demand(5.0)
	th:wait()
	assert(stSaved and stSaved.status == "saved", "Expected saved MP4 from recorder_thread")
	assert(stSaved.frames == 8, "Expected 8 total video frames (6 held frameA + 2 held frameB), got " .. tostring(stSaved.frames))
	assert(stSaved.audioSamples == 6400, "Expected 8 * 800 = 6400 stereo samples at 48kHz/60fps, got " .. tostring(stSaved.audioSamples))

	local f = assert(io.open(tmpMp4, "rb"), "Expected phase1_sync_test.mp4 on disk")
	local raw = f:read("*a")
	f:close()
	os.remove(tmpMp4)

	-- Verify 48000 Hz big-endian (0x0000BB80) present in ALAC sample entry / mdhd
	assert(raw:find("\0\0\187\128", 1, true) ~= nil, "Expected 48000 Hz (0x0000BB80) in MP4 ALAC metadata")
	-- Verify frameA was duplicated 6 times before frameB (never shifting frameB early to PTS=16.7ms!)
	local countA = 0
	local pos = 1
	while true do
		local found = raw:find(frameA, pos, true)
		if not found then break end
		countA = countA + 1
		pos = found + #frameA
	end
	local firstB = raw:find(frameB, 1, true)
	local lastA = raw:find(frameA, 1, true)
	assert(countA == 6 and firstB ~= nil and lastA < firstB,
		"Expected 6 copies of frameA written prior to frameB across 5-frame drop, got countA=" .. tostring(countA))

	-- Verify uncompressed ALAC payload samples stay strictly below 0 dBFS (no +/-32767 clipping)
	-- Uncompressed ALAC 4096-frame CPE packet starts with 0x20,0x00,0x12,0x00,0x00,0x20 (55-bit header)
	local hdrPos = raw:find("\32\0\18\0\0\32", 1, true)
	assert(hdrPos ~= nil, "Expected uncompressed stereo ALAC 4096-frame packet header")
	local maxSampleAbs = 0
	for sIdx = 0, 1599 do
		local p = hdrPos + 6 + sIdx * 2
		local b0, b1, b2 = raw:byte(p, p + 2)
		local u = ((b0 % 2) * 32768) + (b1 * 128) + math.floor(b2 / 2)
		local signed = (u >= 32768) and (u - 65536) or u
		local a = math.abs(signed)
		if a > maxSampleAbs then maxSampleAbs = a end
	end
	assert(maxSampleAbs > 20000 and maxSampleAbs <= 29500,
		"Expected soft-limited full-scale duet peak around -1.0 dBFS (<=29500, >20000), got " .. tostring(maxSampleAbs))
end)
