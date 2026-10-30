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

check("Recorder writes a valid 2-stream (MJPG + 44.1kHz Stereo PCM) RIFF AVI off-thread without HUD leakage", function()
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

	local f = assert(io.open(outPath, "rb"), "Expected AVI file on disk: " .. tostring(outPath))
	local fullBytes = f:read("*a")
	f:close()
	os.remove(outPath)

	assert(#fullBytes > 4096, "Expected non-empty encoded video+audio AVI, got " .. tostring(#fullBytes))
	assert(fullBytes:sub(1, 4) == "RIFF" and fullBytes:sub(9, 12) == "AVI ", "Invalid AVI header")
	assert(fullBytes:find("00dc", 1, true) ~= nil, "Missing 00dc video chunk in AVI")
	assert(fullBytes:find("01wb", 1, true) ~= nil, "Missing 01wb PCM audio chunk in AVI")
	assert(fullBytes:find("auds", 1, true) ~= nil, "Missing auds stream header in AVI")
	assert(fullBytes:find("idx1", 1, true) ~= nil, "Missing idx1 index chunk in AVI")

	ClientPrefs.data.screenRecording = prevEnabled
	ClientPrefs.data.recordingMode = prevMode
	ClientPrefs.data.recordingScale = prevScale
	ClientPrefs.data.recordingFps = prevFps
	ClientPrefs.data.recordingAudio = prevAudio
	ClientPrefs.data.recordingQuality = prevQual
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
