-- Dedicated ISO-BMFF (.mp4) Audio+Video Muxer & Native Audio Feeder Thread
-- In software mode: receives parallel-encoded JPEG/PNG frames in sequence order,
-- mixes active game audio (Inst, Voices, Music, SFX) into 44.1 kHz 16-bit Stereo,
-- and writes a spec-compliant .mp4 container (mp4v + lossless stereo ALAC) off-thread.
-- In Android hardware mode: mixes frame-locked 44.1 kHz Stereo PCM off-thread and
-- feeds `liblightrecorder.so` (`AMediaCodec` AAC + `AMediaMuxer` .mp4).

require "love.filesystem"
require "love.data"
require "love.image"
local hasLoveSound = pcall(require, "love.sound")
local Mp4Muxer = require "funkin.backend.mp4_muxer"

local cmdChannelName, muxChannelName, statusChannelName = ...
local cmdCh = love.thread.getChannel(cmdChannelName or "recorder_cmd")
local muxCh = love.thread.getChannel(muxChannelName or "recorder_mux")
local statusCh = love.thread.getChannel(statusChannelName or "recorder_status")

local okFFI, ffi = pcall(require, "ffi")
local okBit, bit = pcall(require, "bit")
local USE_FFI = okFFI and okBit and ffi ~= nil and bit ~= nil

local nativeLib = nil
if USE_FFI then
	pcall(ffi.cdef, [[
		int lightrecorder_is_available(void);
		int lightrecorder_push_audio_pcm(const int16_t *pcm, int num_stereo_frames);
	]])
	local okLoad, lib = pcall(ffi.load, "lightrecorder")
	if okLoad and lib and lib.lightrecorder_is_available() == 1 then
		nativeLib = lib
	end
end

local AUDIO_RATE = 44100
local AUDIO_CHANNELS = 2
local AUDIO_BLOCK_ALIGN = AUDIO_CHANNELS * 2

local MAX_MIX_SAMPLES = 8192
local mixL = USE_FFI and ffi.new("int32_t[?]", MAX_MIX_SAMPLES) or {}
local mixR = USE_FFI and ffi.new("int32_t[?]", MAX_MIX_SAMPLES) or {}
local pcmOut = USE_FFI and ffi.new("int16_t[?]", MAX_MIX_SAMPLES * 2) or nil

local streamTracks = {}
local sfxTracks = {}

local function releaseChunk(sd)
	if sd and sd.release then
		pcall(sd.release, sd)
	end
end

local function closeAllAudioTracks()
	for k, tr in pairs(streamTracks) do
		releaseChunk(tr.chunk)
		if tr.decoder and tr.decoder.release then
			pcall(tr.decoder.release, tr.decoder)
		end
		streamTracks[k] = nil
	end
	for k in pairs(sfxTracks) do
		sfxTracks[k] = nil
	end
end

local function advanceStreamChunk(tr)
	releaseChunk(tr.chunk)
	tr.chunk = nil
	if not tr.decoder then return false end

	local ok, sd = pcall(tr.decoder.decode, tr.decoder)
	if ok and sd then
		local okCnt, cnt = pcall(sd.getSampleCount, sd)
		if okCnt and cnt and cnt > 0 then
			tr.chunk = sd
			tr.chunkStart = tr.nextChunkStart
			tr.chunkLen = cnt
			tr.nextChunkStart = tr.chunkStart + cnt
			return true
		end
		releaseChunk(sd)
	end
	return false
end

local function seekStreamTrack(tr, timeSec)
	if not tr.decoder then return false end
	timeSec = math.max(0, tonumber(timeSec) or 0)
	releaseChunk(tr.chunk)
	tr.chunk = nil
	pcall(tr.decoder.seek, tr.decoder, timeSec)
	local samplePos = timeSec * tr.rate
	local alignedStart = math.floor(samplePos)
	tr.cursor = samplePos
	tr.chunkStart = alignedStart
	tr.chunkLen = 0
	tr.nextChunkStart = alignedStart
	return advanceStreamChunk(tr)
end

local function getOrCreateStreamTrack(item)
	if not hasLoveSound or not love.sound or not item.path then return nil end
	local uid = item.uid or item.path
	local tr = streamTracks[uid]
	if tr and tr.path == item.path and tr.decoder then
		return tr
	end
	if tr then
		releaseChunk(tr.chunk)
		if tr.decoder and tr.decoder.release then
			pcall(tr.decoder.release, tr.decoder)
		end
		streamTracks[uid] = nil
	end

	local okDec, dec = pcall(love.sound.newDecoder, item.path, 4096)
	if not okDec or not dec then
		return nil
	end

	local okMeta, rate, ch, bits = pcall(function()
		return dec:getSampleRate(), dec:getChannelCount(), dec:getBitDepth()
	end)
	if not okMeta or not rate or rate <= 0 then
		pcall(dec.release, dec)
		return nil
	end

	tr = {
		uid = uid,
		path = item.path,
		decoder = dec,
		rate = rate,
		channels = ch or 2,
		bits = bits or 16,
		playSeq = item.playSeq or 0,
		cursor = 0,
		chunk = nil,
		chunkStart = 0,
		chunkLen = 0,
		nextChunkStart = 0,
		lastUsedFrame = 0
	}
	seekStreamTrack(tr, item.time or 0)
	streamTracks[uid] = tr
	return tr
end

local function mixSoundDataBuffer(sd, sampleCount, channels, bits, startCursor, step, looped, volQ8, nSamples)
	local cursor = startCursor
	if USE_FFI and sd.getFFIPointer then
		if bits == 16 then
			local ptr = ffi.cast("const int16_t*", sd:getFFIPointer())
			if channels >= 2 then
				for i = 0, nSamples - 1 do
					local idx = math.floor(cursor)
					if idx >= sampleCount then
						if looped and sampleCount > 0 then
							cursor = cursor % sampleCount
							idx = math.floor(cursor)
						else
							break
						end
					end
					if idx >= 0 then
						local base = idx * channels
						mixL[i] = mixL[i] + ptr[base] * volQ8
						mixR[i] = mixR[i] + ptr[base + 1] * volQ8
					end
					cursor = cursor + step
				end
			else
				for i = 0, nSamples - 1 do
					local idx = math.floor(cursor)
					if idx >= sampleCount then
						if looped and sampleCount > 0 then
							cursor = cursor % sampleCount
							idx = math.floor(cursor)
						else
							break
						end
					end
					if idx >= 0 then
						local s = ptr[idx] * volQ8
						mixL[i] = mixL[i] + s
						mixR[i] = mixR[i] + s
					end
					cursor = cursor + step
				end
			end
		elseif bits == 8 then
			local ptr = ffi.cast("const uint8_t*", sd:getFFIPointer())
			for i = 0, nSamples - 1 do
				local idx = math.floor(cursor)
				if idx >= sampleCount then
					if looped and sampleCount > 0 then
						cursor = cursor % sampleCount
						idx = math.floor(cursor)
					else
						break
					end
				end
				if idx >= 0 then
					local base = idx * channels
					local l = (ptr[base] - 128) * 256 * volQ8
					local r = channels >= 2 and ((ptr[base + 1] - 128) * 256 * volQ8) or l
					mixL[i] = mixL[i] + l
					mixR[i] = mixR[i] + r
				end
				cursor = cursor + step
			end
		end
	elseif sd.getSample then
		for i = 1, nSamples do
			local idx = math.floor(cursor)
			if idx >= sampleCount then
				if looped and sampleCount > 0 then
					cursor = cursor % sampleCount
					idx = math.floor(cursor)
				else
					break
				end
			end
			if idx >= 0 then
				local l = (sd:getSample(idx, 1) or 0) * 32767 * volQ8
				local r = channels >= 2 and ((sd:getSample(idx, 2) or 0) * 32767 * volQ8) or l
				mixL[i] = (mixL[i] or 0) + l
				mixR[i] = (mixR[i] or 0) + r
			end
			cursor = cursor + step
		end
	end
	return cursor
end

local function mixStreamTrack(tr, item, volQ8, nSamples, checkDrift, curFrameIdx)
	tr.lastUsedFrame = curFrameIdx
	local pitch = math.max(0.1, math.min(4.0, tonumber(item.pitch) or 1.0))
	local step = (tr.rate * pitch) / AUDIO_RATE

	if tr.playSeq ~= (item.playSeq or 0) then
		tr.playSeq = item.playSeq or 0
		seekStreamTrack(tr, item.time or 0)
	elseif checkDrift and item.time ~= nil then
		local expected = math.max(0, (tonumber(item.time) or 0) * tr.rate)
		local driftSec = math.abs(tr.cursor - expected) / tr.rate
		if driftSec > 0.055 then
			seekStreamTrack(tr, item.time)
		end
	end

	local channels = tr.channels
	local bits = tr.bits

	if not USE_FFI then
		for i = 1, nSamples do
			local idx = math.floor(tr.cursor)
			while not tr.chunk or idx >= (tr.chunkStart + tr.chunkLen) do
				if not advanceStreamChunk(tr) then
					if item.looped and seekStreamTrack(tr, 0) then
						idx = math.floor(tr.cursor)
					else
						return
					end
				end
			end
			local rel = idx - tr.chunkStart
			if rel >= 0 and rel < tr.chunkLen and tr.chunk.getSample then
				local l = (tr.chunk:getSample(rel, 1) or 0) * 32767 * volQ8
				local r = channels >= 2 and ((tr.chunk:getSample(rel, 2) or 0) * 32767 * volQ8) or l
				mixL[i] = (mixL[i] or 0) + l
				mixR[i] = (mixR[i] or 0) + r
			end
			tr.cursor = tr.cursor + step
		end
		return
	end

	for i = 0, nSamples - 1 do
		local idx = math.floor(tr.cursor)
		while not tr.chunk or idx >= (tr.chunkStart + tr.chunkLen) do
			if not advanceStreamChunk(tr) then
				if item.looped then
					if not seekStreamTrack(tr, 0) then
						return
					end
					idx = math.floor(tr.cursor)
				else
					return
				end
			end
		end

		local rel = idx - tr.chunkStart
		if rel >= 0 and rel < tr.chunkLen then
			if bits == 16 then
				local ptr = ffi.cast("const int16_t*", tr.chunk:getFFIPointer())
				if channels >= 2 then
					local base = rel * channels
					mixL[i] = mixL[i] + ptr[base] * volQ8
					mixR[i] = mixR[i] + ptr[base + 1] * volQ8
				else
					local s = ptr[rel] * volQ8
					mixL[i] = mixL[i] + s
					mixR[i] = mixR[i] + s
				end
			elseif bits == 8 then
				local ptr = ffi.cast("const uint8_t*", tr.chunk:getFFIPointer())
				local base = rel * channels
				local l = (ptr[base] - 128) * 256 * volQ8
				local r = channels >= 2 and ((ptr[base + 1] - 128) * 256 * volQ8) or l
				mixL[i] = mixL[i] + l
				mixR[i] = mixR[i] + r
			end
		end
		tr.cursor = tr.cursor + step
	end
end

local function renderAudioPcm(audioList, nSamples, checkDrift, curFrameIdx)
	if nSamples <= 0 then return nil, 0 end
	if nSamples > MAX_MIX_SAMPLES then nSamples = MAX_MIX_SAMPLES end

	if USE_FFI then
		ffi.fill(mixL, nSamples * 4, 0)
		ffi.fill(mixR, nSamples * 4, 0)
	else
		for i = 1, nSamples do
			mixL[i] = 0
			mixR[i] = 0
		end
	end

	if type(audioList) == "table" then
		for sIdx = 1, #audioList do
			local item = audioList[sIdx]
			local vol = tonumber(item and item.volume) or 0
			if vol > 0.0005 then
				local volQ8 = math.floor(math.min(2.0, vol) * 256 + 0.5)
				if item.soundData then
					local sd = item.soundData
					local okMeta, rate, sampleCount, ch, bits = pcall(function()
						return sd:getSampleRate(), sd:getSampleCount(), sd:getChannelCount(), sd:getBitDepth()
					end)
					if okMeta and rate and rate > 0 and sampleCount and sampleCount > 0 then
						local uid = item.uid or tostring(sd)
						local tr = sfxTracks[uid]
						if not tr or tr.playSeq ~= (item.playSeq or 0) then
							tr = {
								playSeq = item.playSeq or 0,
								cursor = math.max(0, (tonumber(item.time) or 0) * rate),
								lastUsedFrame = curFrameIdx
							}
							sfxTracks[uid] = tr
						else
							tr.lastUsedFrame = curFrameIdx
							if checkDrift and item.time ~= nil then
								local expected = math.max(0, (tonumber(item.time) or 0) * rate)
								if math.abs(tr.cursor - expected) / rate > 0.075 then
									tr.cursor = expected
								end
							end
						end
						local pitch = math.max(0.1, math.min(4.0, tonumber(item.pitch) or 1.0))
						local step = (rate * pitch) / AUDIO_RATE
						tr.cursor = mixSoundDataBuffer(
							sd, sampleCount, ch or 1, bits or 16,
							tr.cursor, step, item.looped == true, volQ8, nSamples
						)
					end
				elseif item.path then
					local tr = getOrCreateStreamTrack(item)
					if tr then
						mixStreamTrack(tr, item, volQ8, nSamples, checkDrift, curFrameIdx)
					end
				end
			end
		end
	end

	if curFrameIdx % 300 == 0 then
		for k, tr in pairs(streamTracks) do
			if (curFrameIdx - (tr.lastUsedFrame or 0)) > 300 then
				releaseChunk(tr.chunk)
				if tr.decoder and tr.decoder.release then
					pcall(tr.decoder.release, tr.decoder)
				end
				streamTracks[k] = nil
			end
		end
		for k, tr in pairs(sfxTracks) do
			if (curFrameIdx - (tr.lastUsedFrame or 0)) > 300 then
				sfxTracks[k] = nil
			end
		end
	end

	if USE_FFI then
		local rshift = bit.arshift
		for i = 0, nSamples - 1 do
			local l = rshift(mixL[i], 8)
			local r = rshift(mixR[i], 8)
			if l > 32767 then l = 32767 elseif l < -32768 then l = -32768 end
			if r > 32767 then r = 32767 elseif r < -32768 then r = -32768 end
			pcmOut[i * 2] = l
			pcmOut[i * 2 + 1] = r
		end
		return pcmOut, nSamples
	end

	local parts = {}
	for i = 1, nSamples do
		local l = math.floor((mixL[i] or 0) / 256)
		local r = math.floor((mixR[i] or 0) / 256)
		if l > 32767 then l = 32767 elseif l < -32768 then l = -32768 end
		if r > 32767 then r = 32767 elseif r < -32768 then r = -32768 end
		if l < 0 then l = 65536 + l end
		if r < 0 then r = 65536 + r end
		parts[i] = string.char(l % 256, math.floor(l / 256) % 256, r % 256, math.floor(r / 256) % 256)
	end
	return table.concat(parts), nSamples
end

local session = nil

local function extractPayloadBytes(payload)
	if not payload then return nil end
	local bytes
	if type(payload) == "string" then
		bytes = payload
	else
		local ok, str = pcall(function()
			if USE_FFI and payload.getFFIPointer and payload.getSize then
				return ffi.string(payload:getFFIPointer(), payload:getSize())
			elseif payload.getString then
				return payload:getString()
			end
			return nil
		end)
		pcall(function() payload:release() end)
		if ok then bytes = str end
	end
	if bytes and #bytes > 0 then
		return bytes
	end
	return nil
end

local function emitAudioForFrame(s, frameIdx, audioList, checkDrift)
	if not s.recordAudio then return end
	local outStart = math.floor((frameIdx * AUDIO_RATE) / s.fps)
	local outEnd = math.floor(((frameIdx + 1) * AUDIO_RATE) / s.fps)
	local neededSamples = outEnd - outStart
	if neededSamples <= 0 then return end

	local pcmBuf, count = renderAudioPcm(audioList, neededSamples, checkDrift, frameIdx)
	if not pcmBuf or count <= 0 then return end

	if s.nativeMode then
		if nativeLib and USE_FFI and type(pcmBuf) == "cdata" then
			nativeLib.lightrecorder_push_audio_pcm(pcmBuf, count)
			s.totalAudioSamples = s.totalAudioSamples + count
		end
	elseif s.muxer then
		s.muxer:writeAudioPcm(pcmBuf, count)
		s.totalAudioSamples = s.totalAudioSamples + count
	end
end

local function emitOneMuxedFrame(s, videoBytes, audioList, checkDrift)
	if not s or not s.muxer or not videoBytes or #videoBytes == 0 then return end

	s.muxer:writeVideoFrame(videoBytes, 1000)
	local frameIdx = s.writtenFrames
	s.writtenFrames = frameIdx + 1
	emitAudioForFrame(s, frameIdx, audioList, checkDrift)
end

local function processOrderedPacket(s, pkt)
	if s.nativeMode then
		local targetFrame = tonumber(pkt.targetFrame) or s.writtenFrames
		if targetFrame > s.writtenFrames and s.writtenFrames > 0 then
			local gap = math.min(targetFrame - s.writtenFrames, 6)
			for _ = 1, gap do
				local frameIdx = s.writtenFrames
				s.writtenFrames = frameIdx + 1
				emitAudioForFrame(s, frameIdx, pkt.audio, false)
			end
		end
		local frameIdx = s.writtenFrames
		s.writtenFrames = frameIdx + 1
		emitAudioForFrame(s, frameIdx, pkt.audio, true)
		return
	end

	local videoBytes = extractPayloadBytes(pkt.payload) or s.lastVideoBytes
	if not videoBytes or #videoBytes == 0 then
		return
	end

	local targetFrame = tonumber(pkt.targetFrame) or s.writtenFrames
	if targetFrame > s.writtenFrames and s.lastVideoBytes ~= nil then
		local gap = math.min(targetFrame - s.writtenFrames, 6)
		for _ = 1, gap do
			emitOneMuxedFrame(s, s.lastVideoBytes, pkt.audio, false)
		end
	end

	s.lastVideoBytes = videoBytes
	emitOneMuxedFrame(s, videoBytes, pkt.audio, true)
end

local function drainReadyOrderedPackets(s)
	if not s then return end
	while true do
		local pkt = s.pending[s.nextSeq]
		if not pkt then break end
		s.pending[s.nextSeq] = nil
		s.nextSeq = s.nextSeq + 1
		processOrderedPacket(s, pkt)
	end
end

local function handleMuxMessage(msg)
	if type(msg) ~= "table" or (msg.type ~= "encoded" and msg.type ~= "native_audio") then
		return
	end
	if not session or msg.session ~= session.id then
		if msg.payload and type(msg.payload) ~= "string" then
			pcall(function() msg.payload:release() end)
		end
		return
	end
	local seq = tonumber(msg.seq) or 0
	if seq < session.nextSeq then
		if msg.payload and type(msg.payload) ~= "string" then
			pcall(function() msg.payload:release() end)
		end
		return
	end
	session.pending[seq] = msg
	drainReadyOrderedPackets(session)
end

local function finalizeSession()
	if not session then return end
	local s = session
	session = nil

	for _, pkt in pairs(s.pending) do
		if pkt and pkt.payload and type(pkt.payload) ~= "string" then
			pcall(function() pkt.payload:release() end)
		end
	end
	s.pending = {}
	closeAllAudioTracks()

	if s.nativeMode then
		statusCh:push({
			status = "audio_flushed",
			session = s.id,
			frames = s.writtenFrames,
			audioSamples = s.totalAudioSamples,
			path = s.path
		})
		return
	end

	if not s.muxer then return end

	local ok, framesOrReason, audioSamples = s.muxer:close()
	if not ok then
		statusCh:push({
			status = framesOrReason == "empty" and "empty" or "error",
			error = tostring(framesOrReason),
			session = s.id,
			path = s.path
		})
		return
	end

	statusCh:push({
		status = "saved",
		session = s.id,
		frames = framesOrReason,
		audioSamples = audioSamples or s.totalAudioSamples,
		path = s.path
	})
end

local function startSession(cmd)
	finalizeSession()
	closeAllAudioTracks()

	local width = math.max(16, math.floor(tonumber(cmd.width) or 640))
	local height = math.max(16, math.floor(tonumber(cmd.height) or 360))
	local fps = math.max(1, math.floor(tonumber(cmd.fps) or 60))
	local recordAudio = (cmd.recordAudio ~= false) and hasLoveSound
	local nativeMode = cmd.nativeMode == true

	local muxer = nil
	if not nativeMode then
		local objectType = (cmd.fourcc == "MPNG") and 0x6D or 0x6C
		local err
		muxer, err = Mp4Muxer.open(cmd.path, width, height, fps, recordAudio, objectType)
		if not muxer then
			statusCh:push({
				status = "error",
				session = cmd.session or 1,
				error = tostring(err),
				path = cmd.path
			})
			return
		end
	end

	session = {
		id = cmd.session or 1,
		muxer = muxer,
		nativeMode = nativeMode,
		path = cmd.path,
		width = width,
		height = height,
		fps = fps,
		recordAudio = recordAudio,
		writtenFrames = 0,
		totalAudioSamples = 0,
		lastVideoBytes = nil,
		nextSeq = 1,
		pending = {}
	}

	statusCh:push({status = "started", path = cmd.path, session = session.id})
end

local function finishUpToSeq(lastSeq)
	if not session then return end
	lastSeq = tonumber(lastSeq) or 0
	local deadline = os.clock() + 10.0
	while session and session.nextSeq <= lastSeq do
		local msg = muxCh:demand(0.1)
		if msg then
			handleMuxMessage(msg)
		elseif os.clock() >= deadline then
			local maxSeen = lastSeq
			for k in pairs(session.pending) do
				if k > maxSeen then maxSeen = k end
			end
			while session.nextSeq <= maxSeen do
				local pkt = session.pending[session.nextSeq]
				if pkt then
					session.pending[session.nextSeq] = nil
					processOrderedPacket(session, pkt)
				end
				session.nextSeq = session.nextSeq + 1
			end
			break
		end
	end
	finalizeSession()
end

while true do
	local cmd = session and cmdCh:pop() or cmdCh:demand(0.05)
	if type(cmd) == "table" then
		if cmd.type == "start" then
			startSession(cmd)
		elseif cmd.type == "finish" or cmd.type == "stop" then
			finishUpToSeq(cmd.lastSeq)
		elseif cmd.type == "quit" then
			finishUpToSeq(cmd.lastSeq)
			break
		end
	end

	if session then
		local drained = false
		while session do
			local muxMsg = muxCh:pop()
			if not muxMsg then break end
			drained = true
			handleMuxMessage(muxMsg)
		end
		if not drained then
			local muxMsg = muxCh:demand(0.005)
			if muxMsg then
				handleMuxMessage(muxMsg)
			end
		end
	end
end
