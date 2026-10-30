local Recorder = {
	active = false,
	autoStarted = false,
	pendingCapture = false,
	outputPath = nil,
	lastSavedPath = nil,
	elapsed = 0,
	framesSent = 0,
	droppedPending = 0,
	MAX_QUEUED_FRAMES = 4,
	_accum = 0,
	_canvas = nil,
	_canvasW = 0,
	_canvasH = 0,
	_savedSimple = {},
	_targetCameras = {},
	_thread = nil,
	_cmdChannel = nil,
	_statusChannel = nil,
	_badgeFont = nil
}

local function isMobileDevice()
	return (love.system.getDevice and love.system.getDevice() == "Mobile")
		or love.system.getOS() == "Android"
		or love.system.getOS() == "iOS"
end

local function ensureDir(path)
	if not path or path == "" then return false end
	if love.system.getOS() == "Windows" then
		local winPath = path:gsub("/", "\\")
		os.execute('if not exist "' .. winPath .. '" mkdir "' .. winPath .. '" >nul 2>nul')
	else
		os.execute('mkdir -p "' .. path .. '" 2>/dev/null')
	end
	local probe = path .. "/.rec_write_probe"
	local f = io.open(probe, "wb")
	if not f then return false end
	f:close()
	os.remove(probe)
	return true
end

function Recorder.getOutputDirectory()
	local candidates = {}
	if love.system.getOS() == "Android" then
		local ext = os.getenv("EXTERNAL_STORAGE")
		if ext and ext ~= "" then
			candidates[#candidates + 1] = ext .. "/Movies/LightEngine"
		end
		candidates[#candidates + 1] = "/storage/emulated/0/Movies/LightEngine"
		candidates[#candidates + 1] = "/sdcard/Movies/LightEngine"
	end
	if Storage and Storage.available and Storage.root then
		candidates[#candidates + 1] = Storage.root .. "/recordings"
	end
	if love.filesystem and love.filesystem.getSaveDirectory then
		local saveDir = love.filesystem.getSaveDirectory()
		if saveDir and saveDir ~= "" then
			pcall(love.filesystem.createDirectory, "recordings")
			candidates[#candidates + 1] = saveDir .. "/recordings"
		end
	end
	for _, dir in ipairs(candidates) do
		if ensureDir(dir) then return dir end
	end
	return candidates[#candidates] or "."
end

function Recorder.isFeatureEnabled()
	return ClientPrefs and ClientPrefs.data and ClientPrefs.data.screenRecording == true or false
end

function Recorder.getTargetDimensions()
	local scale = (ClientPrefs and ClientPrefs.data and tonumber(ClientPrefs.data.recordingScale))
		or (isMobileDevice() and 0.5 or 0.75)
	scale = math.clamp(scale, 0.25, 1.0)
	local baseW = (game and game.width and game.width > 0) and game.width or 1280
	local baseH = (game and game.height and game.height > 0) and game.height or 720
	-- Round to multiples of 8 (min 160x96) for clean MCU alignment & low GPU readback cost
	local outW = math.max(160, math.floor((baseW * scale + 4) / 8) * 8)
	local outH = math.max(96, math.floor((baseH * scale + 4) / 8) * 8)
	return outW, outH
end

function Recorder.isGameplayStateActive(state)
	state = state or (game and game.getState and game.getState())
	if not state then return false end
	local isPlay = (PlayState and state.is and state:is(PlayState))
		or (state.camNotes ~= nil and state.camHUD ~= nil)
	if not isPlay then return false end
	if state.paused or state.inCutscene or state.substate ~= nil then return false end
	return true
end

function Recorder.getCaptureCameras(mode, state, cameraList)
	mode = mode or (ClientPrefs and ClientPrefs.data and ClientPrefs.data.recordingMode) or "gameplay"
	state = state or (game and game.getState and game.getState())
	cameraList = cameraList or (game and game.cameras and game.cameras.list) or {}

	local selected = {}
	if mode == "gameplay" then
		if not Recorder.isGameplayStateActive(state) then
			return selected
		end
		-- Capture ONLY stage/match cameras + note/arrow camera (camNotes).
		-- Strictly exclude camHUD (healthbar, icons, score, judgements, timebar)
		-- and camOther (virtual pad buttons, pause overlay, loading screen).
		for _, cam in ipairs(cameraList) do
			if cam and cam.visible and cam.exists
				and cam ~= state.camHUD and cam ~= state.camOther then
				selected[#selected + 1] = cam
			end
		end
	else
		for _, cam in ipairs(cameraList) do
			if cam and cam.visible and cam.exists then
				selected[#selected + 1] = cam
			end
		end
	end
	return selected
end

local function ensureWorker()
	if Recorder._thread and Recorder._thread:isRunning() then
		return true
	end
	local code = love.filesystem.read("funkin/backend/recorder_thread.lua")
	if not code then return false, "recorder_thread.lua not found" end

	Recorder._cmdChannel = Recorder._cmdChannel or love.thread.getChannel("light_recorder_cmd")
	Recorder._statusChannel = Recorder._statusChannel or love.thread.getChannel("light_recorder_status")
	Recorder._cmdChannel:clear()

	local thread = love.thread.newThread(code)
	thread:start("light_recorder_cmd", "light_recorder_status")
	Recorder._thread = thread
	return true
end

local function releaseCanvas()
	if Recorder._canvas then
		pcall(function() Recorder._canvas:release() end)
		Recorder._canvas = nil
	end
	Recorder._canvasW, Recorder._canvasH = 0, 0
end

local function ensureCanvas(w, h)
	if Recorder._canvas and Recorder._canvasW == w and Recorder._canvasH == h then
		return Recorder._canvas
	end
	releaseCanvas()
	Recorder._canvas = love.graphics.newCanvas(w, h)
	Recorder._canvas:setFilter("linear", "linear")
	Recorder._canvasW, Recorder._canvasH = w, h
	return Recorder._canvas
end

function Recorder.start(autoTag)
	if not Recorder.isFeatureEnabled() then
		return false, "Enable Screen recording in Display options first"
	end
	if Recorder.active then
		return true, Recorder.outputPath
	end

	local ok, err = ensureWorker()
	if not ok then
		if Toast then Toast.error("Recorder error: " .. tostring(err)) end
		return false, err
	end

	local outW, outH = Recorder.getTargetDimensions()
	local fps = math.clamp(tonumber(ClientPrefs.data.recordingFps) or 30, 15, 60)
	local dir = Recorder.getOutputDirectory()
	local stamp = os.date("%Y%m%d_%H%M%S")
	local prefix = autoTag and (paths and paths.formatToSongPath(autoTag) .. "_") or "session_"
	local filePath = dir .. "/rec_" .. prefix .. stamp .. ".avi"

	ensureCanvas(outW, outH)

	Recorder.active = true
	Recorder.autoStarted = autoTag ~= nil
	Recorder.pendingCapture = false
	Recorder.outputPath = filePath
	Recorder.elapsed = 0
	Recorder.framesSent = 0
	Recorder.droppedPending = 0
	Recorder._accum = 0

	Recorder._cmdChannel:push({
		cmd = "start",
		path = filePath,
		width = outW,
		height = outH,
		fps = fps,
		quality = isMobileDevice() and 72 or 80
	})

	if Toast and not Recorder.autoStarted then
		Toast.info(string.format("Recording started (%dx%d @ %dfps)", outW, outH, fps))
	end
	return true, filePath
end

function Recorder.stop(silent)
	if not Recorder.active then return false end
	Recorder.active = false
	Recorder.autoStarted = false
	Recorder.pendingCapture = false
	Recorder.droppedPending = 0
	Recorder._accum = 0

	for cam, prevSimple in pairs(Recorder._savedSimple) do
		if cam then cam.simple = prevSimple end
		Recorder._savedSimple[cam] = nil
	end
	table.clear(Recorder._targetCameras)

	if Recorder._cmdChannel then
		Recorder._cmdChannel:push({cmd = "stop"})
	end
	releaseCanvas()

	if Toast and not silent then
		Toast.info("Finalizing recording...")
	end
	return true
end

function Recorder.toggle()
	if Recorder.active then
		return Recorder.stop(false)
	end
	return Recorder.start(nil)
end

function Recorder.onSongStart(songName)
	if not Recorder.isFeatureEnabled() then return end
	if ClientPrefs.data.recordingAutoGameplay and not Recorder.active then
		Recorder.start(songName or "gameplay")
	end
end

function Recorder.onSongEnd()
	if Recorder.active and Recorder.autoStarted then
		Recorder.stop(false)
	end
end

function Recorder.pollStatus()
	if not Recorder._statusChannel then return end
	while true do
		local msg = Recorder._statusChannel:pop()
		if not msg then break end
		if msg.type == "saved" then
			Recorder.lastSavedPath = msg.path
			if Toast and (msg.frames or 0) > 0 then
				Toast.info("Saved recording: " .. tostring(msg.path))
			end
		elseif msg.type == "error" then
			Recorder.active = false
			Recorder.pendingCapture = false
			if Toast then Toast.error(tostring(msg.message)) end
		end
	end
end

function Recorder.update(dt)
	Recorder.pollStatus()

	if not Recorder.isFeatureEnabled() then
		if Recorder.active then Recorder.stop(true) end
		return
	end
	if not Recorder.active then return end

	local mode = ClientPrefs.data.recordingMode or "gameplay"
	if mode == "gameplay" and not Recorder.isGameplayStateActive() then
		-- Idle with zero CPU/GPU cost while paused, in cutscenes, or in menus
		Recorder.pendingCapture = false
		return
	end

	local clampedDt = math.min(dt or 0, 0.25)
	Recorder.elapsed = Recorder.elapsed + clampedDt
	Recorder._accum = Recorder._accum + clampedDt

	local fps = math.clamp(tonumber(ClientPrefs.data.recordingFps) or 30, 15, 60)
	local interval = 1 / fps
	if Recorder._accum >= interval then
		local steps = math.floor(Recorder._accum / interval)
		Recorder._accum = Recorder._accum - steps * interval

		local queued = Recorder._cmdChannel and Recorder._cmdChannel:getCount() or 0
		if queued >= Recorder.MAX_QUEUED_FRAMES then
			-- Worker queue full: drop readback so memory & FPS stay completely flat
			Recorder.droppedPending = Recorder.droppedPending + steps
			Recorder.pendingCapture = false
		else
			if steps > 1 then
				Recorder.droppedPending = Recorder.droppedPending + (steps - 1)
			end
			Recorder.pendingCapture = true
		end
	end
end

function Recorder.preDraw()
	if not Recorder.active or not Recorder.pendingCapture then return end

	local mode = ClientPrefs.data.recordingMode or "gameplay"
	local cams = Recorder.getCaptureCameras(mode)
	table.clear(Recorder._targetCameras)

	if #cams == 0 then
		Recorder.pendingCapture = false
		return
	end

	-- Temporarily switch only the captured cameras to canvas-backed complex mode
	-- for THIS single capture tick so game.draw() populates cam.canvas with zero
	-- duplicate sprite/atlas/shader rendering.
	for i, cam in ipairs(cams) do
		Recorder._targetCameras[i] = cam
		if Recorder._savedSimple[cam] == nil then
			Recorder._savedSimple[cam] = cam.simple
		end
		cam.simple = false
	end
end

local function restoreCameraModes()
	for cam, prevSimple in pairs(Recorder._savedSimple) do
		if cam then cam.simple = prevSimple end
		Recorder._savedSimple[cam] = nil
	end
end

local function drawIndicator()
	if not Recorder.active or not ClientPrefs.data.recordingIndicator then return end
	local grap = love.graphics
	local prevFont = grap.getFont()
	local r, g, b, a = grap.getColor()
	local blend, alphaMode = grap.getBlendMode()

	if not Recorder._badgeFont then
		local ok, f = pcall(grap.newFont, "assets/fonts/consolas.ttf", 14)
		Recorder._badgeFont = ok and f or grap.newFont(14)
	end

	local mins = math.floor(Recorder.elapsed / 60)
	local secs = math.floor(Recorder.elapsed % 60)
	local modeTag = (ClientPrefs.data.recordingMode == "gameplay") and "GAME" or "ALL"
	local label = string.format("REC %02d:%02d [%s]", mins, secs, modeTag)

	local winW = grap.getWidth()
	local boxW = Recorder._badgeFont:getWidth(label) + 28
	local boxH = 24
	local bx = math.max(8, winW - boxW - 14)
	local by = 12

	grap.push("all")
	grap.origin()
	grap.setScissor()
	grap.setShader()
	grap.setBlendMode("alpha")
	grap.setColor(0, 0, 0, 0.65)
	grap.rectangle("fill", bx, by, boxW, boxH, 6, 6)

	local pulse = 0.55 + 0.45 * math.abs(math.sin(Recorder.elapsed * 3.5))
	grap.setColor(1, 0.18, 0.18, pulse)
	grap.circle("fill", bx + 11, by + boxH / 2, 5)

	grap.setFont(Recorder._badgeFont)
	grap.setColor(1, 1, 1, 0.95)
	grap.print(label, bx + 20, by + 4)
	grap.pop()

	grap.setFont(prevFont)
	grap.setColor(r, g, b, a)
	grap.setBlendMode(blend, alphaMode)
end

function Recorder.postDraw()
	if Recorder.active and Recorder.pendingCapture then
		Recorder.pendingCapture = false
		local cams = Recorder._targetCameras

		if #cams > 0 and Recorder._cmdChannel then
			local outW, outH = Recorder._canvasW, Recorder._canvasH
			if outW <= 0 or outH <= 0 then
				outW, outH = Recorder.getTargetDimensions()
			end
			local captureCanvas = ensureCanvas(outW, outH)
			local grap = love.graphics
			local prevCanvas = grap.getCanvas()
			local prevShader = grap.getShader()
			local r, g, b, a = grap.getColor()
			local blend, alphaMode = grap.getBlendMode()
			local scx, scy, scw, sch = grap.getScissor()

			local gameW = math.max(1, game.width or 1280)
			local gameH = math.max(1, game.height or 720)
			local scaleX = outW / gameW
			local scaleY = outH / gameH

			grap.push()
			grap.origin()
			grap.setScissor()
			grap.setCanvas(captureCanvas)
			local bg = Project.bgColor or {0, 0, 0, 1}
			grap.clear(bg[1] or 0, bg[2] or 0, bg[3] or 0, 1)

			grap.scale(scaleX, scaleY)
			for i = 1, #cams do
				local cam = cams[i]
				if cam.canvas and cam.visible and cam.exists and cam.alpha > 0 then
					local cw, ch = cam.width, cam.height
					local resX = cam.pixelPerfect and 1 or (cam.__resolutionX or 1)
					local resY = cam.pixelPerfect and 1 or (cam.__resolutionY or 1)
					local sx = cam.scale.x / resX
					local sy = cam.scale.y / resY
					local w2, h2 = cw / 2, ch / 2
					local alpha = cam.alpha
					local col = cam.color or {1, 1, 1}

					grap.setShader(cam.shader)
					grap.setBlendMode("alpha", "premultiplied")
					grap.setColor(col[1] * alpha, col[2] * alpha, col[3] * alpha, alpha)
					local drawX = cam.clipCam and (w2 + cam.x) or w2
					local drawY = cam.clipCam and (h2 + cam.y) or h2
					grap.draw(cam.canvas, drawX, drawY, math.rad(cam.rotation or 0),
						sx, sy, w2 * resX, h2 * resY)
				end
			end
			grap.pop()

			grap.setCanvas(prevCanvas)
			grap.setShader(prevShader)
			grap.setColor(r, g, b, a)
			grap.setBlendMode(blend, alphaMode)
			grap.setScissor(scx, scy, scw, sch)

			local okImg, imgData = pcall(function() return captureCanvas:newImageData() end)
			if okImg and imgData then
				Recorder._cmdChannel:push({
					cmd = "frame",
					image = imgData,
					dropped = Recorder.droppedPending
				})
				Recorder.droppedPending = 0
				Recorder.framesSent = Recorder.framesSent + 1
			end
		end

		table.clear(Recorder._targetCameras)
		restoreCameraModes()
	else
		restoreCameraModes()
	end

	drawIndicator()
end

function Recorder.shutdown()
	if Recorder.active then
		Recorder.stop(true)
	end
	if Recorder._thread and Recorder._thread:isRunning() and Recorder._cmdChannel then
		Recorder._cmdChannel:push({cmd = "quit"})
		pcall(function() Recorder._thread:wait() end)
	end
	Recorder.pollStatus()
	releaseCanvas()
end

return Recorder
