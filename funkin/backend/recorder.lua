local Recorder = {
	active = false,
	autoStarted = false,
	elapsed = 0,
	frames = 0,
	droppedFrames = 0,
	outputPath = nil,
	outputDir = nil,
	lastSavedPath = nil,
	lastError = nil,

	_muxThread = nil,
	_encoderThreads = {},
	_workerCount = 2,
	_cmdCh = nil,
	_encodeCh = nil,
	_muxCh = nil,
	_statusCh = nil,
	_sessionId = 0,
	_nextSeq = 1,

	_canvases = {nil, nil},
	_curSlot = 1,
	_pendingSlot = nil,
	_canvasW = 0,
	_canvasH = 0,
	_targetFps = 60,
	_quality = 88,
	_fourcc = "MJPG",
	_recordAudio = true,

	_startWallTime = nil,
	_pausedAtWallTime = nil,
	_lastScheduledFrame = -1,
	_shouldCaptureFrame = false,
	_forcedCams = {}
}

local QUALITY_MAP = {
	standard = 78,
	high = 88,
	ultra = 95
}

local function sanitizeSegment(name)
	name = tostring(name or "session"):gsub("[%c%s/\\:%*%?\"<>|]+", "-")
	name = name:gsub("%-+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
	if name == "" then name = "session" end
	return name:sub(1, 48)
end

local function align16(n)
	n = math.max(64, math.floor((tonumber(n) or 64) + 8))
	return math.max(64, math.floor(n / 16) * 16)
end

local function ensureOutputDirectory()
	local baseDir
	if Storage and type(Storage.getExternalDir) == "function" then
		local ext = Storage.getExternalDir()
		if type(ext) == "string" and ext ~= "" then
			baseDir = ext .. "/recordings"
			if type(Storage.ensureNativeDir) == "function" then
				pcall(Storage.ensureNativeDir, baseDir)
			end
		end
	end

	if not baseDir then
		pcall(love.filesystem.createDirectory, "recordings")
		local saveDir = love.filesystem.getSaveDirectory()
		baseDir = saveDir .. "/recordings"
		if Storage and type(Storage.ensureNativeDir) == "function" then
			pcall(Storage.ensureNativeDir, baseDir)
		end
	end

	Recorder.outputDir = baseDir
	return baseDir
end

local function computeWorkerCount()
	local cores = 4
	if love.system and type(love.system.getProcessorCount) == "function" then
		local ok, c = pcall(love.system.getProcessorCount)
		if ok and type(c) == "number" and c > 0 then
			cores = c
		end
	end
	return math.max(2, math.min(4, cores - 1))
end

local function ensureThreads()
	if not Recorder._cmdCh then
		Recorder._cmdCh = love.thread.getChannel("recorder_cmd")
		Recorder._encodeCh = love.thread.getChannel("recorder_encode")
		Recorder._muxCh = love.thread.getChannel("recorder_mux")
		Recorder._statusCh = love.thread.getChannel("recorder_status")
	end

	if not Recorder._muxThread or not Recorder._muxThread:isRunning() then
		Recorder._muxThread = love.thread.newThread("funkin/backend/recorder_thread.lua")
		Recorder._muxThread:start("recorder_cmd", "recorder_mux", "recorder_status")
	end

	local targetWorkers = computeWorkerCount()
	Recorder._workerCount = targetWorkers
	for i = 1, targetWorkers do
		local th = Recorder._encoderThreads[i]
		if not th or not th:isRunning() then
			th = love.thread.newThread("funkin/backend/recorder_encoder_thread.lua")
			th:start("recorder_encode", "recorder_mux")
			Recorder._encoderThreads[i] = th
		end
	end
end

local function drainStatusChannel()
	if not Recorder._statusCh then return end
	while true do
		local msg = Recorder._statusCh:pop()
		if not msg then break end
		if msg.status == "saved" then
			Recorder.lastSavedPath = msg.path
		elseif msg.status == "error" then
			Recorder.lastError = msg.error
		end
	end
end

local function releaseCanvases()
	for i = 1, 2 do
		local c = Recorder._canvases[i]
		if c then
			pcall(function() c:release() end)
			Recorder._canvases[i] = nil
		end
	end
	Recorder._pendingSlot = nil
	Recorder._curSlot = 1
	Recorder._canvasW, Recorder._canvasH = 0, 0
end

local function restoreForcedCameras()
	for cam, prevSimple in pairs(Recorder._forcedCams) do
		if cam then
			cam.simple = prevSimple
		end
		Recorder._forcedCams[cam] = nil
	end
end

function Recorder.isFeatureEnabled()
	return ClientPrefs and ClientPrefs.data and ClientPrefs.data.screenRecording == true
end

function Recorder.getCaptureMode()
	local mode = ClientPrefs and ClientPrefs.data and ClientPrefs.data.recordingMode or "gameplay"
	if mode ~= "entire" and mode ~= "gameplay" then
		mode = "gameplay"
	end
	return mode
end

function Recorder.getTargetDimensions()
	local scale = tonumber(ClientPrefs and ClientPrefs.data and ClientPrefs.data.recordingScale) or 0.75
	scale = math.clamp(scale, 0.25, 1.0)
	local baseW = (game and game.width and game.width > 0) and game.width or Project.width
	local baseH = (game and game.height and game.height > 0) and game.height or Project.height
	return align16(baseW * scale), align16(baseH * scale)
end

function Recorder.getCaptureCameras(mode, state, camerasList)
	mode = mode or Recorder.getCaptureMode()
	state = state or (game and game.getState and game.getState() or nil)
	camerasList = camerasList or (game and game.cameras and game.cameras.list or {})

	local selected = {}
	if mode == "gameplay" then
		local isPlay = state ~= nil and (
			(PlayState and state.is and state:is(PlayState))
			or (state.camNotes ~= nil and state.camHUD ~= nil)
		)
		if not isPlay then
			return selected
		end
		if state.paused or state.inCutscene or state.substate ~= nil then
			return selected
		end

		for i = 1, #camerasList do
			local cam = camerasList[i]
			if cam and cam.exists and cam.visible then
				if cam ~= state.camHUD and cam ~= state.camOther then
					selected[#selected + 1] = cam
				end
			end
		end
	else
		for i = 1, #camerasList do
			local cam = camerasList[i]
			if cam and cam.exists and cam.visible then
				selected[#selected + 1] = cam
			end
		end
	end

	return selected
end

local function snapshotActiveAudio()
	if not Recorder._recordAudio then return nil end
	if not game or not game.sound or not game.sound.list or not game.sound.list.members then
		return nil
	end

	local members = game.sound.list.members
	local list = nil
	for i = 1, #members do
		local s = members[i]
		if s and s.exists and s.active and type(s.isPlaying) == "function" and s:isPlaying() then
			local vol = type(s.getActualVolume) == "function" and s:getActualVolume() or (s._volume or 1)
			if vol > 0.0005 then
				local asset = rawget(s, "_asset")
				local isSoundData = false
				if asset and type(asset.typeOf) == "function" then
					local okType, res = pcall(asset.typeOf, asset, "SoundData")
					isSoundData = okType and res == true
				end
				local path = rawget(s, "_sourcePath")
				if not path and asset and paths and paths.audioPaths then
					path = paths.audioPaths[asset]
				end
				if isSoundData or (type(path) == "string" and path ~= "") then
					if not list then list = {} end
					local pitch = type(s.getActualPitch) == "function" and s:getActualPitch() or (s._pitch or 1)
					list[#list + 1] = {
						uid = rawget(s, "_uid") or i,
						playSeq = rawget(s, "_playSeq") or 0,
						path = not isSoundData and path or nil,
						soundData = isSoundData and asset or nil,
						time = s.time or 0,
						volume = vol,
						pitch = pitch,
						looped = s.looped == true
					}
				end
			end
		end
	end
	return list
end

local function ensureCaptureCanvases(w, h)
	if Recorder._canvases[1] and Recorder._canvases[2]
		and Recorder._canvasW == w and Recorder._canvasH == h then
		return true
	end
	releaseCanvases()
	local ok1, c1 = pcall(love.graphics.newCanvas, w, h)
	local ok2, c2 = pcall(love.graphics.newCanvas, w, h)
	if not ok1 or not ok2 or not c1 or not c2 then
		if ok1 and c1 then pcall(function() c1:release() end) end
		if ok2 and c2 then pcall(function() c2:release() end) end
		return false
	end
	c1:setFilter("linear", "linear")
	c2:setFilter("linear", "linear")
	Recorder._canvases[1] = c1
	Recorder._canvases[2] = c2
	Recorder._canvasW, Recorder._canvasH = w, h
	Recorder._curSlot = 1
	Recorder._pendingSlot = nil
	return true
end

local function dispatchPendingSlot(forceFlush)
	local pending = Recorder._pendingSlot
	if not pending then return end
	Recorder._pendingSlot = nil

	local canvas = Recorder._canvases[pending.slot]
	if not canvas then return end

	local maxInFlight = math.max(6, (Recorder._workerCount or 2) * 3)
	if not forceFlush and Recorder._encodeCh and Recorder._encodeCh:getCount() >= maxInFlight then
		Recorder.droppedFrames = Recorder.droppedFrames + 1
		return
	end

	local okImg, imgData = pcall(canvas.newImageData, canvas)
	if not okImg or not imgData then
		return
	end

	local seq = Recorder._nextSeq
	Recorder._nextSeq = seq + 1
	Recorder.frames = Recorder.frames + 1

	Recorder._encodeCh:push({
		type = "encode",
		session = Recorder._sessionId,
		seq = seq,
		targetFrame = pending.targetFrame,
		image = imgData,
		width = Recorder._canvasW,
		height = Recorder._canvasH,
		quality = Recorder._quality,
		fourcc = Recorder._fourcc,
		audio = pending.audio
	})
end

function Recorder.start(tag, autoStarted)
	if not Recorder.isFeatureEnabled() then return false end
	if Recorder.active then return true, Recorder.outputPath end

	ensureThreads()
	drainStatusChannel()

	local outW, outH = Recorder.getTargetDimensions()
	if not ensureCaptureCanvases(outW, outH) then
		Recorder.lastError = "Unable to allocate capture canvases"
		return false, Recorder.lastError
	end

	local fps = math.clamp(tonumber(ClientPrefs.data.recordingFps) or 60, 15, 60)
	local qualKey = tostring(ClientPrefs.data.recordingQuality or "high")
	local quality = QUALITY_MAP[qualKey] or 88
	local recordAudio = ClientPrefs.data.recordingAudio ~= false
	local hasFFI = pcall(require, "ffi") and pcall(require, "bit")
	local fourcc = hasFFI and "MJPG" or "MPNG"

	local dir = ensureOutputDirectory()
	local stamp = os.date("%Y%m%d_%H%M%S")
	local prefix = sanitizeSegment(tag or (Recorder.getCaptureMode() == "gameplay" and "gameplay" or "game"))
	local path = string.format("%s/%s_%s.avi", dir, stamp, prefix)

	Recorder._sessionId = Recorder._sessionId + 1
	Recorder._nextSeq = 1
	Recorder._targetFps = fps
	Recorder._quality = quality
	Recorder._fourcc = fourcc
	Recorder._recordAudio = recordAudio
	Recorder._startWallTime = nil
	Recorder._pausedAtWallTime = nil
	Recorder._lastScheduledFrame = -1
	Recorder._shouldCaptureFrame = false
	Recorder._pendingSlot = nil
	Recorder._curSlot = 1

	Recorder.active = true
	Recorder.autoStarted = autoStarted == true
	Recorder.elapsed = 0
	Recorder.frames = 0
	Recorder.droppedFrames = 0
	Recorder.outputPath = path
	Recorder.lastError = nil

	Recorder._cmdCh:push({
		type = "start",
		session = Recorder._sessionId,
		path = path,
		width = outW,
		height = outH,
		fps = fps,
		fourcc = fourcc,
		recordAudio = recordAudio
	})

	return true, path
end

function Recorder.stop(waitFlush)
	if not Recorder.active then return nil end

	-- Flush final buffered ping-pong canvas frame so zero trailing frames are lost
	if Recorder._pendingSlot then
		pcall(dispatchPendingSlot, true)
	end

	local savedPath = Recorder.outputPath
	local lastSeq = Recorder._nextSeq - 1

	Recorder.active = false
	Recorder.autoStarted = false
	Recorder._shouldCaptureFrame = false
	Recorder._startWallTime = nil
	Recorder._pausedAtWallTime = nil
	Recorder._lastScheduledFrame = -1

	restoreForcedCameras()
	releaseCanvases()

	if Recorder._cmdCh then
		Recorder._cmdCh:push({type = "finish", lastSeq = lastSeq})
		if waitFlush and Recorder._statusCh then
			local msg = Recorder._statusCh:demand(5.0)
			if msg and msg.status == "saved" then
				Recorder.lastSavedPath = msg.path
			elseif msg and msg.status == "error" then
				Recorder.lastError = msg.error
			end
		end
	end

	Recorder.outputPath = nil
	drainStatusChannel()
	return savedPath
end

function Recorder.toggle()
	if not Recorder.isFeatureEnabled() then return false end
	if Recorder.active then
		Recorder.stop(false)
		return false
	end
	return Recorder.start(nil, false)
end

function Recorder.onSongStart(songName)
	if not Recorder.isFeatureEnabled() then return end
	if not (ClientPrefs and ClientPrefs.data and ClientPrefs.data.recordingAutoGameplay) then
		return
	end
	if not Recorder.active then
		Recorder.start(songName or "gameplay", true)
	end
end

function Recorder.onSongEnd()
	if Recorder.active and Recorder.autoStarted then
		Recorder.stop(false)
	end
end

function Recorder.update(dt)
	drainStatusChannel()

	if not Recorder.isFeatureEnabled() then
		if Recorder.active then
			Recorder.stop(false)
		end
		return
	end

	if not Recorder.active then return end

	local cams = Recorder.getCaptureCameras()
	local now = (love.timer and love.timer.getTime and love.timer.getTime()) or os.clock()

	if #cams == 0 then
		if not Recorder._pausedAtWallTime then
			Recorder._pausedAtWallTime = now
		end
		Recorder._shouldCaptureFrame = false
		return
	end

	if Recorder._pausedAtWallTime then
		local pausedDur = math.max(0, now - Recorder._pausedAtWallTime)
		if Recorder._startWallTime then
			Recorder._startWallTime = Recorder._startWallTime + pausedDur
		end
		Recorder._pausedAtWallTime = nil
	end

	if not Recorder._startWallTime then
		Recorder._startWallTime = now
		Recorder._lastScheduledFrame = -1
		Recorder._shouldCaptureFrame = true
		Recorder.elapsed = 0
		return
	end

	local elapsedWall = math.max(0, now - Recorder._startWallTime)
	Recorder.elapsed = elapsedWall
	local targetFrame = math.floor(elapsedWall * Recorder._targetFps)
	if targetFrame > Recorder._lastScheduledFrame then
		Recorder._shouldCaptureFrame = true
	end
end

function Recorder.preDraw()
	if not Recorder.active then return end
	local cams = Recorder.getCaptureCameras()
	if #cams == 0 then
		Recorder._shouldCaptureFrame = false
		return
	end

	-- Keep target cameras in steady FBO mode for the entire recording session
	-- rather than toggling cam.simple back and forth on alternating frames.
	for i = 1, #cams do
		local cam = cams[i]
		if cam and Recorder._forcedCams[cam] == nil then
			Recorder._forcedCams[cam] = cam.simple
			cam.simple = false
		elseif cam and cam.simple ~= false then
			cam.simple = false
		end
	end
end

local function drawRecordingBadge()
	if not Recorder.active then return end
	if not (ClientPrefs and ClientPrefs.data and ClientPrefs.data.recordingIndicator) then
		return
	end

	local sw, sh = love.graphics.getDimensions()
	if sw <= 0 or sh <= 0 then return end

	love.graphics.push("all")
	love.graphics.origin()
	love.graphics.setScissor()
	love.graphics.setShader()
	love.graphics.setBlendMode("alpha")

	local mins = math.floor(Recorder.elapsed / 60)
	local secs = math.floor(Recorder.elapsed % 60)
	local label = string.format("REC %02d:%02d", mins, secs)
	local font = love.graphics.getFont()
	local textW = font and font:getWidth(label) or 76
	local textH = font and font:getHeight() or 16
	local padX, padY = 10, 5
	local dotSpace = 14
	local boxW = textW + padX * 2 + dotSpace
	local boxH = textH + padY * 2
	local boxX = sw - boxW - 14
	local boxY = 12

	love.graphics.setColor(0, 0, 0, 0.58)
	love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 6, 6)

	local pulse = 0.55 + 0.45 * math.abs(math.sin(Recorder.elapsed * 3.5))
	love.graphics.setColor(0.95, 0.18, 0.18, pulse)
	love.graphics.circle("fill", boxX + padX + 4, boxY + boxH * 0.5, 4.5)

	love.graphics.setColor(1, 1, 1, 0.92)
	love.graphics.print(label, boxX + padX + dotSpace, boxY + padY)
	love.graphics.pop()
end

local function compositeCamerasToSlot(cams, slotIdx)
	local outW, outH = Recorder.getTargetDimensions()
	if not ensureCaptureCanvases(outW, outH) then return false end

	local targetCanvas = Recorder._canvases[slotIdx]
	local baseW = (game and game.width and game.width > 0) and game.width or Project.width
	local baseH = (game and game.height and game.height > 0) and game.height or Project.height
	local sx, sy = outW / baseW, outH / baseH

	love.graphics.push("all")
	love.graphics.setCanvas(targetCanvas)
	love.graphics.origin()
	love.graphics.setScissor()
	love.graphics.setShader()
	love.graphics.clear(0, 0, 0, 1)

	local drawnAny = false
	for i = 1, #cams do
		local cam = cams[i]
		local srcCanvas = cam and cam.canvas
		if srcCanvas and (cam.alpha or 1) > 0 then
			drawnAny = true
			local color = cam.color or {1, 1, 1}
			local alpha = cam.alpha or 1
			local rot = math.rad(cam.angle or 0)
			local zoomX = cam.__zoom and cam.__zoom.x or (cam.zoom or 1)
			local zoomY = cam.__zoom and cam.__zoom.y or (cam.zoom or 1)
			local halfW, halfH = cam.width / 2, cam.height / 2
			local shakeX = cam.__shakeX or 0
			local shakeY = cam.__shakeY or 0

			love.graphics.setBlendMode("alpha", "premultiplied")
			if cam.bgColor and cam.bgColor[4] and cam.bgColor[4] > 0 then
				love.graphics.setBlendMode("alpha")
				love.graphics.setColor(
					cam.bgColor[1] or 0,
					cam.bgColor[2] or 0,
					cam.bgColor[3] or 0,
					(cam.bgColor[4] or 1) * alpha
				)
				love.graphics.rectangle(
					"fill",
					(cam.x + shakeX) * sx,
					(cam.y + shakeY) * sy,
					cam.width * sx,
					cam.height * sy
				)
				love.graphics.setBlendMode("alpha", "premultiplied")
			end

			love.graphics.setColor(
				(color[1] or 1) * alpha,
				(color[2] or 1) * alpha,
				(color[3] or 1) * alpha,
				alpha
			)
			love.graphics.draw(
				srcCanvas,
				(cam.x + halfW + shakeX) * sx,
				(cam.y + halfH + shakeY) * sy,
				rot,
				zoomX * sx,
				zoomY * sy,
				halfW,
				halfH
			)
		end
	end

	love.graphics.pop()
	return drawnAny
end

function Recorder.postDraw()
	if not Recorder.active then return end

	if Recorder._shouldCaptureFrame then
		Recorder._shouldCaptureFrame = false
		local cams = Recorder.getCaptureCameras()
		if #cams > 0 then
			local now = (love.timer and love.timer.getTime and love.timer.getTime()) or os.clock()
			if not Recorder._startWallTime then
				Recorder._startWallTime = now
			end
			local targetFrame = math.max(0, math.floor((now - Recorder._startWallTime) * Recorder._targetFps))
			if targetFrame <= Recorder._lastScheduledFrame then
				targetFrame = Recorder._lastScheduledFrame + 1
			end

			-- Delayed ping-pong readback: read the PREVIOUS capture canvas (rendered 16-33ms
			-- ago, GPU already idle on it) BEFORE drawing the current frame into the other slot.
			if Recorder._pendingSlot then
				dispatchPendingSlot(false)
			end

			local slot = Recorder._curSlot
			if compositeCamerasToSlot(cams, slot) then
				Recorder._lastScheduledFrame = targetFrame
				Recorder._pendingSlot = {
					slot = slot,
					targetFrame = targetFrame,
					audio = snapshotActiveAudio()
				}
				Recorder._curSlot = (slot == 1) and 2 or 1
			end
		end
	end

	-- Drawn directly to screen backbuffer AFTER canvas capture, so it never leaks into video
	drawRecordingBadge()
end

function Recorder.shutdown()
	if Recorder.active then
		Recorder.stop(true)
	else
		restoreForcedCameras()
		releaseCanvases()
	end

	if Recorder._encodeCh and #Recorder._encoderThreads > 0 then
		for _ = 1, #Recorder._encoderThreads do
			Recorder._encodeCh:push({type = "quit"})
		end
		for i = 1, #Recorder._encoderThreads do
			local th = Recorder._encoderThreads[i]
			if th and th:isRunning() then
				pcall(function() th:wait() end)
			end
			Recorder._encoderThreads[i] = nil
		end
	end

	if Recorder._muxThread and Recorder._muxThread:isRunning() and Recorder._cmdCh then
		Recorder._cmdCh:push({type = "quit", lastSeq = Recorder._nextSeq - 1})
		pcall(function() Recorder._muxThread:wait() end)
	end
	Recorder._muxThread = nil
end

return Recorder
