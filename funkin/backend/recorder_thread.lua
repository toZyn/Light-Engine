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
		releaseChunk(tr.peekChunk)
		if tr.decoder and tr.decoder.release then
			pcall(tr.decoder.release, tr.decoder)
		end
		streamTracks[k] = nil
	end
	for k in pairs(sfxTracks) do
		sfxTracks[k] = nil
	end
end

local function decodeRawChunk(tr)
	if not tr.decoder then return nil, 0 end
	local ok, sd = pcall(tr.decoder.decode, tr.decoder)
	if ok and sd then
		local okCnt, cnt = pcall(sd.getSampleCount, sd)
		if okCnt and cnt and cnt > 0 then
			return sd, cnt
		end
		releaseChunk(sd)
	end
	return nil, 0
end

local function ensurePeekChunk(tr)
	if not tr.peekChunk then
		tr.peekChunk, tr.peekLen = decodeRawChunk(tr)
	end
	return tr.peekChunk, tr.peekLen or 0
end

local function advanceStreamChunk(tr)
	releaseChunk(tr.chunk)
	tr.chunk = nil
	local sd, cnt
	if tr.peekChunk then
		sd, cnt = tr.peekChunk, tr.peekLen or 0
		tr.peekChunk, tr.peekLen = nil, 0
	else
		sd, cnt = decodeRawChunk(tr)
	end
	if sd and cnt > 0 then
		tr.chunk = sd
		tr.chunkStart = tr.nextChunkStart
		tr.chunkLen = cnt
		tr.nextChunkStart = tr.chunkStart + cnt
		return true
	end
	if sd then releaseChunk(sd) end
	return false
end

local function seekStreamTrack(tr, timeSec)
	if not tr.decoder then return false end
	timeSec = math.max(0, tonumber(timeSec) or 0)
	releaseChunk(tr.chunk)
	releaseChunk(tr.peekChunk)
	tr.chunk = nil
	tr.peekChunk, tr.peekLen = nil, 0
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
		releaseChunk(tr.peekChunk)
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
		seekSeq = item.seekSeq or 0,
		cursor = 0,
		chunk = nil,
		peekChunk = nil,
		peekLen = 0,
		chunkStart = 0,
		chunkLen = 0,
		nextChunkStart = 0,
		lastUsedFrame = 0
	}
	if (tonumber(item.time) or 0) > 0.02 then
		seekStreamTrack(tr, item.time)
	else
		advanceStreamChunk(tr)
		tr.cursor = math.max(0, (tonumber(item.time) or 0) * rate)
	end
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
						local frac = cursor - idx
						local idx1 = idx + 1
						if idx1 >= sampleCount then
							idx1 = looped and 0 or idx
						end
						local b0 = idx * channels
						local b1 = idx1 * channels
						local l = ptr[b0] + (ptr[b1] - ptr[b0]) * frac
						local r = ptr[b0 + 1] + (ptr[b1 + 1] - ptr[b0 + 1]) * frac
						mixL[i] = mixL[i] + math.floor(l * volQ8 + 0.5)
						mixR[i] = mixR[i] + math.floor(r * volQ8 + 0.5)
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
						local frac = cursor - idx
						local idx1 = idx + 1
						if idx1 >= sampleCount then
							idx1 = looped and 0 or idx
						end
						local s = math.floor((ptr[idx] + (ptr[idx1] - ptr[idx]) * frac) * volQ8 + 0.5)
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
				local frac = cursor - idx
				local idx1 = idx + 1
				if idx1 >= sampleCount then
					idx1 = looped and 0 or idx
				end
				local l0 = sd:getSample(idx, 1) or 0
				local l1 = sd:getSample(idx1, 1) or l0
				local l = (l0 + (l1 - l0) * frac) * 32767 * volQ8
				local r = l
				if channels >= 2 then
					local r0 = sd:getSample(idx, 2) or 0
					local r1 = sd:getSample(idx1, 2) or r0
					r = (r0 + (r1 - r0) * frac) * 32767 * volQ8
				end
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
	local curPlaySeq = item.playSeq or 0
	local curSeekSeq = item.seekSeq or 0

	if tr.playSeq ~= curPlaySeq or tr.seekSeq ~= curSeekSeq then
		tr.playSeq = curPlaySeq
		tr.seekSeq = curSeekSeq
		local targetTime = math.max(0, tonumber(item.time) or 0)
		local curTime = tr.cursor / tr.rate
		-- Re-seek on genuine restart (to ~0s) or real seek (>250ms), ignoring PlayState:resyncSong() 9-60ms OpenAL micro-nudges
		if (targetTime <= 0.03 and curTime > 0.08) or math.abs(curTime - targetTime) > 0.25 then
			seekStreamTrack(tr, targetTime)
		end
	elseif checkDrift and item.time ~= nil then
		-- OpenAL Source:tell() advances in 46-93ms hardware buffer blocks; only re-seek
		-- on genuine large desync (> 350ms), never on normal mixer buffer granularity.
		local expected = math.max(0, (tonumber(item.time) or 0) * tr.rate)
		local driftSec = math.abs(tr.cursor - expected) / tr.rate
		if driftSec > 0.35 then
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
				local frac = tr.cursor - idx
				local l0 = tr.chunk:getSample(rel, 1) or 0
				local r0 = channels >= 2 and (tr.chunk:getSample(rel, 2) or 0) or l0
				local l1, r1 = l0, r0
				if rel + 1 < tr.chunkLen then
					l1 = tr.chunk:getSample(rel + 1, 1) or l0
					r1 = channels >= 2 and (tr.chunk:getSample(rel + 1, 2) or r0) or l1
				else
					local pk, pkLen = ensurePeekChunk(tr)
					if pk and pkLen > 0 and pk.getSample then
						l1 = pk:getSample(0, 1) or l0
						r1 = channels >= 2 and (pk:getSample(0, 2) or r0) or l1
					end
				end
				mixL[i] = (mixL[i] or 0) + (l0 + (l1 - l0) * frac) * 32767 * volQ8
				mixR[i] = (mixR[i] or 0) + (r0 + (r1 - r0) * frac) * 32767 * volQ8
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
			local frac = tr.cursor - idx
			if bits == 16 then
				local ptr = ffi.cast("const int16_t*", tr.chunk:getFFIPointer())
				if channels >= 2 then
					local base = rel * channels
					local l0, r0 = ptr[base], ptr[base + 1]
					local l1, r1 = l0, r0
					if rel + 1 < tr.chunkLen then
						l1, r1 = ptr[base + channels], ptr[base + channels + 1]
					else
						local pk, pkLen = ensurePeekChunk(tr)
						if pk and pkLen > 0 then
							local pkp = ffi.cast("const int16_t*", pk:getFFIPointer())
							l1, r1 = pkp[0], pkp[1]
						end
					end
					mixL[i] = mixL[i] + math.floor((l0 + (l1 - l0) * frac) * volQ8 + 0.5)
					mixR[i] = mixR[i] + math.floor((r0 + (r1 - r0) * frac) * volQ8 + 0.5)
				else
					local s0 = ptr[rel]
					local s1 = s0
					if rel + 1 < tr.chunkLen then
						s1 = ptr[rel + 1]
					else
						local pk, pkLen = ensurePeekChunk(tr)
						if pk and pkLen > 0 then
							local pkp = ffi.cast("const int16_t*", pk:getFFIPointer())
							s1 = pkp[0]
						end
					end
					local s = math.floor((s0 + (s1 - s0) * frac) * volQ8 + 0.5)
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
						if not tr or tr.playSeq ~= (item.playSeq or 0) or tr.seekSeq ~= (item.seekSeq or 0) then
							tr = {
								playSeq = item.playSeq or 0,
								seekSeq = item.seekSeq or 0,
								cursor = math.max(0, (tonumber(item.time) or 0) * rate),
								lastUsedFrame = curFrameIdx
							}
							sfxTracks[uid] = tr
						else
							tr.lastUsedFrame = curFrameIdx
							if checkDrift and item.time ~= nil then
								local expected = math.max(0, (tonumber(item.time) or 0) * rate)
								if math.abs(tr.cursor - expected) / rate > 0.35 then
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
				releaseChunk(tr.peekChunk)
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

local function emitAudioUpToFrame(s, endFrameIdx, audioList, checkDrift)
	if not s.recordAudio then return end
	local targetSamples = math.floor((endFrameIdx * AUDIO_RATE) / s.fps)
	local remaining = targetSamples - s.totalAudioSamples
	if remaining <= 0 then return end
	-- Guard against extreme multi-second OS suspend while preserving full hitch continuity up to 1.5s
	local maxCatchup = math.floor(AUDIO_RATE * 1.5)
	if remaining > maxCatchup then
		remaining = maxCatchup
	end

	local firstChunk = true
	while remaining > 0 do
		local batch = math.min(remaining, MAX_MIX_SAMPLES)
		local pcmBuf, count = renderAudioPcm(audioList, batch, checkDrift and firstChunk, endFrameIdx)
		firstChunk = false
		if not pcmBuf or count <= 0 then break end

		if s.nativeMode then
			if nativeLib and USE_FFI and type(pcmBuf) == "cdata" then
				nativeLib.lightrecorder_push_audio_pcm(pcmBuf, count)
				s.totalAudioSamples = s.totalAudioSamples + count
			else
				break
			end
		elseif s.muxer then
			s.muxer:writeAudioPcm(pcmBuf, count)
			s.totalAudioSamples = s.totalAudioSamples + count
		else
			break
		end
		remaining = remaining - count
	end
end

local function processOrderedPacket(s, pkt)
	local targetFrame = math.max(s.writtenFrames, tonumber(pkt.targetFrame) or s.writtenFrames)
	local deltaFrames = math.max(1, math.min((targetFrame - s.writtenFrames) + 1, math.max(15, s.fps * 2)))

	if s.nativeMode then
		s.writtenFrames = s.writtenFrames + deltaFrames
		emitAudioUpToFrame(s, s.writtenFrames, pkt.audio, true)
		return
	end

	local videoBytes = extractPayloadBytes(pkt.payload) or s.lastVideoBytes
	if not videoBytes or #videoBytes == 0 then
		return
	end

	s.lastVideoBytes = videoBytes
	if s.muxer then
		s.muxer:writeVideoFrame(videoBytes, deltaFrames * 1000)
		s.writtenFrames = s.writtenFrames + deltaFrames
		emitAudioUpToFrame(s, s.writtenFrames, pkt.audio, true)
	end
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
