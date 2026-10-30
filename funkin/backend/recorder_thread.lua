-- Dedicated ISO-BMFF (.mp4) Audio+Video Muxer & Native Audio Feeder Thread
-- In software mode: receives parallel-encoded JPEG/PNG frames in sequence order,
-- mixes active game audio (Inst, Voices, Video cutscenes, Music, SFX) at native
-- 44.1 / 48 kHz 16-bit Stereo with headroom + smooth peak limiting (< 0 dBFS),
-- duplicates prior frames across frame drops so PTS stays locked, and writes a
-- spec-compliant .mp4 container (mp4v + lossless stereo ALAC) off-thread.
-- In Android hardware mode: mixes frame-locked Stereo PCM off-thread and feeds
-- `liblightrecorder.so` (`AMediaCodec` H.264 + AAC-LC + `AMediaMuxer` .mp4).

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

local DEFAULT_AUDIO_RATE = 44100
local MAX_MIX_SAMPLES = 8192

-- Multi-stem headroom (-2.85 dB) + stereo-linked smooth peak limiter ceiling (-1.00 dBFS)
local HEADROOM_GAIN = 0.72
local LIMIT_THRESH = 0.80
local LIMIT_CEIL = 0.89125 -- -1.00 dBFS (max PCM ~29204 << 32767, zero hard clipping)
local LIMIT_KNEE = LIMIT_CEIL - LIMIT_THRESH

local mixL = USE_FFI and ffi.new("double[?]", MAX_MIX_SAMPLES) or {}
local mixR = USE_FFI and ffi.new("double[?]", MAX_MIX_SAMPLES) or {}
local pcmOut = USE_FFI and ffi.new("int16_t[?]", MAX_MIX_SAMPLES * 2) or nil

local streamTracks = {}
local sfxTracks = {}

local function softKneeGain(peak)
	if peak <= LIMIT_THRESH then
		return 1.0
	end
	local x = (peak - LIMIT_THRESH) / LIMIT_KNEE
	-- Rational/tanh soft-knee saturation asymptotically bounded by LIMIT_CEIL
	local e2x = math.exp(-2.0 * math.min(20.0, x))
	local th = (1.0 - e2x) / (1.0 + e2x)
	return (LIMIT_THRESH + LIMIT_KNEE * th) / peak
end

local function hermite4(ym1, y0, y1, y2, frac)
	local c1 = 0.5 * (y1 - ym1)
	local c2 = ym1 - 2.5 * y0 + 2.0 * y1 - 0.5 * y2
	local c3 = 0.5 * (y2 - ym1) + 1.5 * (y0 - y1)
	return ((c3 * frac + c2) * frac + c1) * frac + y0
end

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

local function readChunkFrameNorm(sd, channels, bits, relIdx)
	if relIdx < 0 then relIdx = 0 end
	if USE_FFI and sd.getFFIPointer then
		if bits == 16 then
			local ptr = ffi.cast("const int16_t*", sd:getFFIPointer())
			if channels >= 2 then
				local base = relIdx * channels
				return ptr[base] * (1.0 / 32768.0), ptr[base + 1] * (1.0 / 32768.0)
			else
				local v = ptr[relIdx] * (1.0 / 32768.0)
				return v, v
			end
		elseif bits == 8 then
			local ptr = ffi.cast("const uint8_t*", sd:getFFIPointer())
			local base = relIdx * channels
			local l = (ptr[base] - 128) * (1.0 / 128.0)
			local r = channels >= 2 and ((ptr[base + 1] - 128) * (1.0 / 128.0)) or l
			return l, r
		end
	elseif sd.getSample then
		local l = sd:getSample(relIdx, 1) or 0
		local r = channels >= 2 and (sd:getSample(relIdx, 2) or 0) or l
		return l, r
	end
	return 0, 0
end

local function ensurePeekChunk(tr)
	if not tr.peekChunk then
		tr.peekChunk, tr.peekLen = decodeRawChunk(tr)
	end
	return tr.peekChunk, tr.peekLen or 0
end

local function advanceStreamChunk(tr)
	if tr.chunk and tr.chunkLen and tr.chunkLen > 0 then
		if tr.chunkLen >= 2 then
			tr.tailM2L, tr.tailM2R = readChunkFrameNorm(tr.chunk, tr.channels, tr.bits, tr.chunkLen - 2)
		else
			tr.tailM2L, tr.tailM2R = tr.tailM1L or 0, tr.tailM1R or 0
		end
		tr.tailM1L, tr.tailM1R = readChunkFrameNorm(tr.chunk, tr.channels, tr.bits, tr.chunkLen - 1)
	end
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

local function seekStreamTrack(tr, timeSec, withCrossfade)
	if not tr.decoder then return false end
	if withCrossfade then
		tr.fadeFromL = tr.lastOutL or 0
		tr.fadeFromR = tr.lastOutR or 0
		tr.fadeTotal = 64
		tr.fadePos = 0
	end
	timeSec = math.max(0, tonumber(timeSec) or 0)
	releaseChunk(tr.chunk)
	releaseChunk(tr.peekChunk)
	tr.chunk = nil
	tr.peekChunk, tr.peekLen = nil, 0
	tr.tailM1L, tr.tailM1R = 0, 0
	tr.tailM2L, tr.tailM2R = 0, 0
	pcall(tr.decoder.seek, tr.decoder, timeSec)
	local samplePos = (timeSec <= 0.000001) and 0 or (timeSec * tr.rate)
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
		tailM1L = 0, tailM1R = 0,
		tailM2L = 0, tailM2R = 0,
		lastOutL = 0, lastOutR = 0,
		fadeFromL = 0, fadeFromR = 0,
		fadeTotal = 0, fadePos = 0,
		lastUsedFrame = 0
	}
	local initTime = item.songMasterSec ~= nil and tonumber(item.songMasterSec) or tonumber(item.time) or 0
	initTime = math.max(0, initTime)
	if initTime > 0.002 then
		seekStreamTrack(tr, initTime, false)
	else
		advanceStreamChunk(tr)
		tr.cursor = math.max(0, initTime * rate)
	end
	streamTracks[uid] = tr
	return tr
end

local function sampleStreamAtRel(tr, rel)
	local len = tr.chunkLen
	if rel >= 0 and rel < len then
		return readChunkFrameNorm(tr.chunk, tr.channels, tr.bits, rel)
	elseif rel == -1 then
		return tr.tailM1L, tr.tailM1R
	elseif rel <= -2 then
		return tr.tailM2L, tr.tailM2R
	else
		local over = rel - len
		local pk, pkLen = ensurePeekChunk(tr)
		if pk and pkLen > over then
			return readChunkFrameNorm(pk, tr.channels, tr.bits, over)
		elseif len > 0 then
			return readChunkFrameNorm(tr.chunk, tr.channels, tr.bits, len - 1)
		end
	end
	return 0, 0
end

local function mixSoundDataBuffer(sd, sampleCount, channels, bits, startCursor, step, looped, gain, nSamples)
	local cursor = startCursor
	if gain <= 0.0001 then
		cursor = cursor + nSamples * step
		if looped and sampleCount > 0 then
			cursor = cursor % sampleCount
		end
		return cursor
	end

	local needCubic = math.abs(step - 1.0) > 1e-6
	local baseIdx = USE_FFI and 0 or 1

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
			local l, r
			if not needCubic and frac < 1e-6 then
				l, r = readChunkFrameNorm(sd, channels, bits, idx)
			else
				local i0 = idx - 1
				if i0 < 0 then i0 = looped and (sampleCount - 1) or 0 end
				local i1 = idx
				local i2 = idx + 1
				if i2 >= sampleCount then i2 = looped and (i2 % sampleCount) or (sampleCount - 1) end
				local i3 = idx + 2
				if i3 >= sampleCount then i3 = looped and (i3 % sampleCount) or (sampleCount - 1) end
				local lm1, rm1 = readChunkFrameNorm(sd, channels, bits, i0)
				local l0, r0 = readChunkFrameNorm(sd, channels, bits, i1)
				local l1, r1 = readChunkFrameNorm(sd, channels, bits, i2)
				local l2, r2 = readChunkFrameNorm(sd, channels, bits, i3)
				l = hermite4(lm1, l0, l1, l2, frac)
				r = (channels >= 2) and hermite4(rm1, r0, r1, r2, frac) or l
			end
			local dst = baseIdx + i
			mixL[dst] = (mixL[dst] or 0) + l * gain
			mixR[dst] = (mixR[dst] or 0) + r * gain
		end
		cursor = cursor + step
	end
	return cursor
end

local function mixStreamTrack(tr, item, gain, nSamples, checkDrift, curFrameIdx, outRate)
	tr.lastUsedFrame = curFrameIdx
	local pitch = math.max(0.1, math.min(4.0, tonumber(item.pitch) or 1.0))
	local step = (tr.rate * pitch) / outRate
	local curPlaySeq = item.playSeq or 0
	local curSeekSeq = item.seekSeq or 0

	if item.songMasterSec ~= nil then
		-- Active PlayState song stem (Inst / Voices): keep sample-locked to PlayState.conductor.time
		-- across startup OpenAL latency adjustments, misses (gain == 0), and explicit seeks.
		tr.playSeq = curPlaySeq
		tr.seekSeq = curSeekSeq
		if checkDrift then
			local masterSec = math.max(0, tonumber(item.songMasterSec) or 0)
			local driftSec = math.abs((tr.cursor / tr.rate) - masterSec)
			if driftSec > 0.014 then
				seekStreamTrack(tr, masterSec, gain > 0.0001)
			end
		end
	else
		if tr.playSeq ~= curPlaySeq or tr.seekSeq ~= curSeekSeq then
			tr.playSeq = curPlaySeq
			tr.seekSeq = curSeekSeq
			local targetTime = math.max(0, tonumber(item.time) or 0)
			local curTime = tr.cursor / tr.rate
			if (targetTime <= 0.02 and curTime > 0.06) or math.abs(curTime - targetTime) > 0.12 then
				seekStreamTrack(tr, targetTime, gain > 0.0001)
			end
		elseif checkDrift and item.time ~= nil then
			local targetTime = math.max(0, tonumber(item.time) or 0)
			local driftSec = math.abs((tr.cursor / tr.rate) - targetTime)
			if driftSec > 0.12 then
				seekStreamTrack(tr, targetTime, gain > 0.0001)
			end
		end
	end

	-- Muted stream (e.g. Voices-bf while missed note sets volume=0): advance cursor & decoder
	-- chunks in exact lockstep without adding samples into the mix bus.
	if gain <= 0.0001 and tr.fadePos >= tr.fadeTotal then
		tr.cursor = tr.cursor + nSamples * step
		local targetIdx = math.floor(tr.cursor)
		while not tr.chunk or targetIdx >= (tr.chunkStart + tr.chunkLen) do
			if not advanceStreamChunk(tr) then
				if item.looped and seekStreamTrack(tr, 0, false) then
					targetIdx = math.floor(tr.cursor)
				else
					break
				end
			end
		end
		tr.lastOutL, tr.lastOutR = 0, 0
		return
	end

	local needCubic = math.abs(step - 1.0) > 1e-6
	local baseIdx = USE_FFI and 0 or 1

	for i = 0, nSamples - 1 do
		local idx = math.floor(tr.cursor)
		while not tr.chunk or idx >= (tr.chunkStart + tr.chunkLen) do
			if not advanceStreamChunk(tr) then
				if item.looped and seekStreamTrack(tr, 0, false) then
					idx = math.floor(tr.cursor)
				else
					tr.lastOutL, tr.lastOutR = 0, 0
					return
				end
			end
		end

		local rel = idx - tr.chunkStart
		local l, r = 0, 0
		if rel >= 0 and rel < tr.chunkLen then
			local frac = tr.cursor - idx
			if not needCubic and frac < 1e-6 then
				l, r = readChunkFrameNorm(tr.chunk, tr.channels, tr.bits, rel)
			else
				local lm1, rm1 = sampleStreamAtRel(tr, rel - 1)
				local l0, r0 = sampleStreamAtRel(tr, rel)
				local l1, r1 = sampleStreamAtRel(tr, rel + 1)
				local l2, r2 = sampleStreamAtRel(tr, rel + 2)
				l = hermite4(lm1, l0, l1, l2, frac)
				r = (tr.channels >= 2) and hermite4(rm1, r0, r1, r2, frac) or l
			end
		end

		local outL = l * gain
		local outR = r * gain
		if tr.fadePos < tr.fadeTotal then
			local alpha = tr.fadePos / tr.fadeTotal
			outL = tr.fadeFromL * (1.0 - alpha) + outL * alpha
			outR = tr.fadeFromR * (1.0 - alpha) + outR * alpha
			tr.fadePos = tr.fadePos + 1
		end
		tr.lastOutL, tr.lastOutR = outL, outR

		local dst = baseIdx + i
		mixL[dst] = (mixL[dst] or 0) + outL
		mixR[dst] = (mixR[dst] or 0) + outR
		tr.cursor = tr.cursor + step
	end
end

local function renderAudioPcm(s, audioList, nSamples, checkDrift, curFrameIdx)
	if nSamples <= 0 then return nil, 0 end
	if nSamples > MAX_MIX_SAMPLES then nSamples = MAX_MIX_SAMPLES end
	local outRate = s.audioRate or DEFAULT_AUDIO_RATE

	if USE_FFI then
		ffi.fill(mixL, nSamples * 8, 0)
		ffi.fill(mixR, nSamples * 8, 0)
	else
		for i = 1, nSamples do
			mixL[i] = 0
			mixR[i] = 0
		end
	end

	if type(audioList) == "table" then
		for sIdx = 1, #audioList do
			local item = audioList[sIdx]
			if item then
				local vol = math.max(0, math.min(2.0, tonumber(item.volume) or 0))
				local gain = vol * HEADROOM_GAIN
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
								if math.abs(tr.cursor - expected) / rate > 0.12 then
									tr.cursor = expected
								end
							end
						end
						local pitch = math.max(0.1, math.min(4.0, tonumber(item.pitch) or 1.0))
						local step = (rate * pitch) / outRate
						tr.cursor = mixSoundDataBuffer(
							sd, sampleCount, ch or 1, bits or 16,
							tr.cursor, step, item.looped == true, gain, nSamples
						)
					end
				elseif item.path then
					local tr = getOrCreateStreamTrack(item)
					if tr then
						mixStreamTrack(tr, item, gain, nSamples, checkDrift, curFrameIdx, outRate)
					end
				end
			end
		end
	end

	if curFrameIdx % 600 == 0 then
		for k, tr in pairs(streamTracks) do
			if (curFrameIdx - (tr.lastUsedFrame or 0)) > 600 then
				releaseChunk(tr.chunk)
				releaseChunk(tr.peekChunk)
				if tr.decoder and tr.decoder.release then
					pcall(tr.decoder.release, tr.decoder)
				end
				streamTracks[k] = nil
			end
		end
		for k, tr in pairs(sfxTracks) do
			if (curFrameIdx - (tr.lastUsedFrame or 0)) > 600 then
				sfxTracks[k] = nil
			end
		end
	end

	local envGain = s.limiterGain or 1.0
	local relCoef = s.limiterRelCoef or math.exp(-1.0 / (0.085 * outRate))

	if USE_FFI then
		for i = 0, nSamples - 1 do
			local l = mixL[i]
			local r = mixR[i]
			local absL = l < 0 and -l or l
			local absR = r < 0 and -r or r
			local peak = absL > absR and absL or absR

			local reqGain = softKneeGain(peak)
			if reqGain < envGain then
				envGain = reqGain
			else
				envGain = reqGain + (envGain - reqGain) * relCoef
			end

			local outL = l * envGain
			local outR = r * envGain
			if outL > LIMIT_CEIL then outL = LIMIT_CEIL elseif outL < -LIMIT_CEIL then outL = -LIMIT_CEIL end
			if outR > LIMIT_CEIL then outR = LIMIT_CEIL elseif outR < -LIMIT_CEIL then outR = -LIMIT_CEIL end

			pcmOut[i * 2] = math.floor(outL * 32767.0 + (outL >= 0 and 0.5 or -0.5))
			pcmOut[i * 2 + 1] = math.floor(outR * 32767.0 + (outR >= 0 and 0.5 or -0.5))
		end
		s.limiterGain = envGain
		return pcmOut, nSamples
	end

	local parts = {}
	for i = 1, nSamples do
		local l = mixL[i] or 0
		local r = mixR[i] or 0
		local absL = l < 0 and -l or l
		local absR = r < 0 and -r or r
		local peak = absL > absR and absL or absR

		local reqGain = softKneeGain(peak)
		if reqGain < envGain then
			envGain = reqGain
		else
			envGain = reqGain + (envGain - reqGain) * relCoef
		end

		local outL = l * envGain
		local outR = r * envGain
		if outL > LIMIT_CEIL then outL = LIMIT_CEIL elseif outL < -LIMIT_CEIL then outL = -LIMIT_CEIL end
		if outR > LIMIT_CEIL then outR = LIMIT_CEIL elseif outR < -LIMIT_CEIL then outR = -LIMIT_CEIL end

		local il = math.floor(outL * 32767.0 + (outL >= 0 and 0.5 or -0.5))
		local ir = math.floor(outR * 32767.0 + (outR >= 0 and 0.5 or -0.5))
		if il < 0 then il = 65536 + il end
		if ir < 0 then ir = 65536 + ir end
		parts[i] = string.char(il % 256, math.floor(il / 256) % 256, ir % 256, math.floor(ir / 256) % 256)
	end
	s.limiterGain = envGain
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
	local targetSamples = math.floor((endFrameIdx * s.audioRate) / s.fps + 0.5)
	local remaining = targetSamples - s.totalAudioSamples
	if remaining <= 0 then return end

	local firstChunk = true
	while remaining > 0 do
		local batch = math.min(remaining, MAX_MIX_SAMPLES)
		local pcmBuf, count = renderAudioPcm(s, audioList, batch, checkDrift and firstChunk, endFrameIdx)
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

-- Flushes the active interval [s.pendingFrameIdx, nextRelFrame):
-- 1. Writes s.pendingVideoBytes for `gap = nextRelFrame - s.pendingFrameIdx` frames,
--    duplicating the previous frame across frame drops so CFR/VFR players hold the
--    previous image until the exact PTS of the new frame (never shifting video early!).
-- 2. Synthesizes audio for the exact same [s.pendingFrameIdx, nextRelFrame) interval
--    using s.pendingAudio (the audio snapshot taken at s.pendingFrameIdx).
local function flushIntervalToFrame(s, nextRelFrame)
	if not s.hasStartedTimeline then return end
	local gap = math.max(1, nextRelFrame - s.pendingFrameIdx)

	if s.nativeMode then
		s.writtenFrames = s.writtenFrames + gap
		emitAudioUpToFrame(s, s.writtenFrames, s.pendingAudio, true)
		s.pendingFrameIdx = nextRelFrame
		return
	end

	local videoBytes = s.pendingVideoBytes
	if not videoBytes or not s.muxer then return end

	local maxDuplicates = 60
	if gap <= maxDuplicates then
		for _ = 1, gap do
			s.muxer:writeVideoFrame(videoBytes, 1000)
		end
	else
		for _ = 1, maxDuplicates - 1 do
			s.muxer:writeVideoFrame(videoBytes, 1000)
		end
		s.muxer:writeVideoFrame(videoBytes, (gap - (maxDuplicates - 1)) * 1000)
	end

	s.writtenFrames = s.writtenFrames + gap
	emitAudioUpToFrame(s, s.writtenFrames, s.pendingAudio, true)
	s.pendingFrameIdx = nextRelFrame
end

local function processOrderedPacket(s, pkt)
	local rawTarget = math.max(0, math.floor(tonumber(pkt.targetFrame) or 0))

	if pkt.type == "native_audio" then
		if not s.hasStartedTimeline then
			s.frameOrigin = rawTarget
			s.pendingFrameIdx = 0
			s.pendingAudio = pkt.audio
			s.hasStartedTimeline = true
			return
		end
		local relFrame = math.max(s.pendingFrameIdx + 1, rawTarget - s.frameOrigin)
		flushIntervalToFrame(s, relFrame)
		s.pendingAudio = pkt.audio
		return
	end

	if pkt.type == "drop" then
		if not s.hasStartedTimeline then
			return
		end
		local relFrame = math.max(s.pendingFrameIdx + 1, rawTarget - s.frameOrigin)
		flushIntervalToFrame(s, relFrame)
		s.pendingAudio = pkt.audio
		return
	end

	local videoBytes = extractPayloadBytes(pkt.payload) or s.pendingVideoBytes
	if not videoBytes or #videoBytes == 0 then
		return
	end

	if not s.hasStartedTimeline then
		s.frameOrigin = rawTarget
		s.pendingFrameIdx = 0
		s.pendingVideoBytes = videoBytes
		s.pendingAudio = pkt.audio
		s.hasStartedTimeline = true
		return
	end

	local relFrame = math.max(s.pendingFrameIdx + 1, rawTarget - s.frameOrigin)
	flushIntervalToFrame(s, relFrame)
	s.pendingVideoBytes = videoBytes
	s.pendingAudio = pkt.audio
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
	if type(msg) ~= "table"
		or (msg.type ~= "encoded" and msg.type ~= "native_audio" and msg.type ~= "drop") then
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

local function finalizeSession(stopFrames)
	if not session then return end
	local s = session
	session = nil

	if s.hasStartedTimeline then
		local endRel = s.pendingFrameIdx + 1
		if stopFrames ~= nil then
			local candidate = math.floor(tonumber(stopFrames) or 0) - s.frameOrigin
			if candidate > endRel then
				endRel = candidate
			end
		end
		flushIntervalToFrame(s, endRel)
	end

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
	finalizeSession(nil)
	closeAllAudioTracks()

	local width = math.max(16, math.floor(tonumber(cmd.width) or 640))
	local height = math.max(16, math.floor(tonumber(cmd.height) or 360))
	local fps = math.max(1, math.floor(tonumber(cmd.fps) or 60))
	local recordAudio = (cmd.recordAudio ~= false) and hasLoveSound
	local nativeMode = cmd.nativeMode == true
	local audioRate = (tonumber(cmd.audioRate) == 48000) and 48000 or DEFAULT_AUDIO_RATE

	local muxer = nil
	if not nativeMode then
		local objectType = (cmd.fourcc == "MPNG") and 0x6D or 0x6C
		local err
		muxer, err = Mp4Muxer.open(cmd.path, width, height, fps, recordAudio, objectType, audioRate)
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
		audioRate = audioRate,
		recordAudio = recordAudio,
		limiterGain = 1.0,
		limiterRelCoef = math.exp(-1.0 / (0.085 * audioRate)),
		hasStartedTimeline = false,
		frameOrigin = 0,
		pendingFrameIdx = 0,
		pendingVideoBytes = nil,
		pendingAudio = nil,
		writtenFrames = 0,
		totalAudioSamples = 0,
		nextSeq = 1,
		pending = {}
	}

	statusCh:push({status = "started", path = cmd.path, session = session.id})
end

local function finishUpToSeq(lastSeq, stopFrames)
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
	finalizeSession(stopFrames)
end

while true do
	local cmd = session and cmdCh:pop() or cmdCh:demand(0.05)
	if type(cmd) == "table" then
		if cmd.type == "start" then
			startSession(cmd)
		elseif cmd.type == "finish" or cmd.type == "stop" then
			finishUpToSeq(cmd.lastSeq, cmd.stopFrames)
		elseif cmd.type == "quit" then
			finishUpToSeq(cmd.lastSeq, cmd.stopFrames)
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
