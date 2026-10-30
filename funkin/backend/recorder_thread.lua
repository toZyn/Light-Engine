-- Dedicated RIFF AVI Audio+Video Muxer Thread for Light Engine Recorder
-- Receives parallel-encoded MJPG/MPNG frames in sequence order, mixes active game
-- audio streams (Inst, Voices, Music, SFX) into 44.1 kHz 16-bit Stereo PCM (01wb),
-- and writes a spec-compliant interleaved RIFF AVI container off the main thread.

require "love.filesystem"
require "love.data"
require "love.image"
local hasLoveSound = pcall(require, "love.sound")

local cmdChannelName, muxChannelName, statusChannelName = ...
local cmdCh = love.thread.getChannel(cmdChannelName or "recorder_cmd")
local muxCh = love.thread.getChannel(muxChannelName or "recorder_mux")
local statusCh = love.thread.getChannel(statusChannelName or "recorder_status")

local okFFI, ffi = pcall(require, "ffi")
local okBit, bit = pcall(require, "bit")
local USE_FFI = okFFI and okBit and ffi ~= nil and bit ~= nil

local AUDIO_RATE = 44100
local AUDIO_CHANNELS = 2
local AUDIO_BITS = 16
local AUDIO_BLOCK_ALIGN = AUDIO_CHANNELS * (AUDIO_BITS / 8) -- 4 bytes per stereo frame
local AUDIO_BYTES_PER_SEC = AUDIO_RATE * AUDIO_BLOCK_ALIGN   -- 176400 bytes/sec

local function u16(n)
	n = math.floor(n or 0) % 65536
	local b1 = n % 256
	local b2 = math.floor(n / 256) % 256
	return string.char(b1, b2)
end

local function u32(n)
	n = math.floor(n or 0)
	if n < 0 then n = 4294967296 + n end
	n = n % 4294967296
	local b1 = n % 256
	local b2 = math.floor(n / 256) % 256
	local b3 = math.floor(n / 65536) % 256
	local b4 = math.floor(n / 16777216) % 256
	return string.char(b1, b2, b3, b4)
end

local i32 = u32

local function chunk(fourcc, payload)
	local len = #payload
	if len % 2 == 1 then
		return fourcc .. u32(len) .. payload .. "\0"
	end
	return fourcc .. u32(len) .. payload
end

local function listChunk(listType, body)
	local payload = listType .. body
	local len = #payload
	if len % 2 == 1 then
		return "LIST" .. u32(len) .. payload .. "\0"
	end
	return "LIST" .. u32(len) .. payload
end

local function buildHeader(width, height, fps, fourcc, totalFrames, maxFrameSize, recordAudio, totalAudioSamples)
	local usecPerFrame = math.max(1, math.floor(1000000 / math.max(1, fps) + 0.5))
	local suggestedBuf = math.max(maxFrameSize or 0, width * height * 3)
	local maxBytesPerSec = math.max(suggestedBuf * math.max(1, fps), 1048576)
	local streamCount = recordAudio and 2 or 1
	-- AVIF_HASINDEX (0x10) | AVIF_ISINTERLEAVED (0x100)
	local aviFlags = recordAudio and 0x110 or 0x10

	local avih = table.concat({
		u32(usecPerFrame),
		u32(maxBytesPerSec),
		u32(0),
		u32(aviFlags),
		u32(totalFrames),
		u32(0),
		u32(streamCount),
		u32(suggestedBuf),
		u32(width),
		u32(height),
		u32(0), u32(0), u32(0), u32(0)
	})

	local vStrh = table.concat({
		"vids",
		fourcc,
		u32(0),
		u16(0), u16(0),
		u32(0),
		u32(1000),
		u32(math.floor(fps * 1000 + 0.5)),
		u32(0),
		u32(totalFrames),
		u32(suggestedBuf),
		u32(10000),
		u32(0),
		u16(0), u16(0), u16(width), u16(height)
	})

	local vStrf = table.concat({
		u32(40),
		i32(width),
		i32(height),
		u16(1),
		u16(24),
		fourcc,
		u32(width * height * 3),
		i32(0), i32(0), u32(0), u32(0)
	})

	local strls = listChunk("strl", chunk("strh", vStrh) .. chunk("strf", vStrf))

	if recordAudio then
		local aStrh = table.concat({
			"auds",
			u32(1), -- WAVE_FORMAT_PCM
			u32(0),
			u16(0), u16(0),
			u32(0),
			u32(AUDIO_BLOCK_ALIGN),
			u32(AUDIO_BYTES_PER_SEC),
			u32(0),
			u32(totalAudioSamples or 0),
			u32(16384),
			u32(0xFFFFFFFF),
			u32(AUDIO_BLOCK_ALIGN),
			u16(0), u16(0), u16(0), u16(0)
		})

		-- WAVEFORMATEX (18 bytes)
		local aStrf = table.concat({
			u16(1),                 -- wFormatTag = WAVE_FORMAT_PCM
			u16(AUDIO_CHANNELS),    -- nChannels = 2
			u32(AUDIO_RATE),        -- nSamplesPerSec = 44100
			u32(AUDIO_BYTES_PER_SEC),
			u16(AUDIO_BLOCK_ALIGN), -- nBlockAlign = 4
			u16(AUDIO_BITS),        -- wBitsPerSample = 16
			u16(0)                  -- cbSize = 0
		})

		strls = strls .. listChunk("strl", chunk("strh", aStrh) .. chunk("strf", aStrf))
	end

	local hdrl = listChunk("hdrl", chunk("avih", avih) .. strls)
	return "RIFF" .. u32(0) .. "AVI " .. hdrl
end

-- Real-time 44.1 kHz Stereo 16-bit PCM Mixer
local MAX_MIX_SAMPLES = 8192
local mixL = USE_FFI and ffi.new("int32_t[?]", MAX_MIX_SAMPLES) or nil
local mixR = USE_FFI and ffi.new("int32_t[?]", MAX_MIX_SAMPLES) or nil
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
	if USE_FFI then
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

	if not USE_FFI then
		tr.cursor = tr.cursor + step * nSamples
		return
	end

	local channels = tr.channels
	local bits = tr.bits

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

local function renderAudioChunk(audioList, nSamples, checkDrift, curFrameIdx)
	if nSamples <= 0 then return "" end
	if nSamples > MAX_MIX_SAMPLES then nSamples = MAX_MIX_SAMPLES end

	if not USE_FFI then
		return string.rep("\0", nSamples * AUDIO_BLOCK_ALIGN)
	end

	ffi.fill(mixL, nSamples * 4, 0)
	ffi.fill(mixR, nSamples * 4, 0)

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

	-- Periodically prune idle decoders/SFX cursors that haven't played in >300 frames
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

	local rshift = bit.arshift
	for i = 0, nSamples - 1 do
		local l = rshift(mixL[i], 8)
		local r = rshift(mixR[i], 8)
		if l > 32767 then l = 32767 elseif l < -32768 then l = -32768 end
		if r > 32767 then r = 32767 elseif r < -32768 then r = -32768 end
		pcmOut[i * 2] = l
		pcmOut[i * 2 + 1] = r
	end

	return ffi.string(pcmOut, nSamples * AUDIO_BLOCK_ALIGN)
end

-- Active AVI Muxer Session State
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

local function flushHeaderCheckpoint(s)
	if not s or not s.file or s.writtenFrames <= 0 then return end
	local curPos = s.file:seek()
	if not curPos then return end
	local header = buildHeader(
		s.width, s.height, s.fps, s.fourcc,
		s.writtenFrames, s.maxFrameSize, s.recordAudio, s.totalAudioSamples
	)
	local riffSize = math.max(0, curPos - 8)
	s.file:seek("set", 0)
	s.file:write(header)
	s.file:seek("set", 4)
	s.file:write(u32(riffSize))
	s.file:seek("set", s.moviListSizeOffset)
	s.file:write(u32(s.moviDataBytes + 4))
	s.file:seek("set", curPos)
	s.file:flush()
end

local function appendRawChunk(s, fourcc, dataBytes, flags)
	local len = #dataBytes
	local n = #s.idxFourcc + 1
	s.idxFourcc[n] = fourcc
	s.idxFlags[n] = flags or 0x10
	-- Offset in AVIOLDINDEX (idx1) is relative to the start of the "movi" FourCC,
	-- so the very first chunk immediately following "movi" begins at offset 4.
	s.idxOffsets[n] = 4 + s.moviDataBytes
	s.idxSizes[n] = len

	s.file:write(fourcc)
	s.file:write(u32(len))
	s.file:write(dataBytes)
	local pad = len % 2
	if pad == 1 then
		s.file:write("\0")
	end
	s.moviDataBytes = s.moviDataBytes + 8 + len + pad
end

local function emitOneMuxedFrame(s, videoBytes, audioList, checkDrift)
	if not s or not s.file or not videoBytes or #videoBytes == 0 then return end

	if #videoBytes > s.maxFrameSize then
		s.maxFrameSize = #videoBytes
	end
	appendRawChunk(s, "00dc", videoBytes, 0x10)

	local frameIdx = s.writtenFrames
	s.writtenFrames = frameIdx + 1

	if s.recordAudio then
		local outStart = math.floor((frameIdx * AUDIO_RATE) / s.fps)
		local outEnd = math.floor(((frameIdx + 1) * AUDIO_RATE) / s.fps)
		local neededSamples = outEnd - outStart
		if neededSamples > 0 then
			local pcmBytes = renderAudioChunk(audioList, neededSamples, checkDrift, frameIdx)
			appendRawChunk(s, "01wb", pcmBytes, 0x10)
			s.totalAudioSamples = s.totalAudioSamples + neededSamples
		end
	end

	if s.writtenFrames % 60 == 0 then
		pcall(flushHeaderCheckpoint, s)
	end
end

local function processOrderedPacket(s, pkt)
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
	if type(msg) ~= "table" or msg.type ~= "encoded" then return end
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

	if not s.file then return end

	if s.writtenFrames <= 0 then
		s.file:close()
		pcall(os.remove, s.path)
		statusCh:push({status = "empty", path = s.path})
		return
	end

	local idxParts = {}
	for i = 1, #s.idxFourcc do
		idxParts[i] = s.idxFourcc[i] .. u32(s.idxFlags[i]) .. u32(s.idxOffsets[i]) .. u32(s.idxSizes[i])
	end
	local idxBody = table.concat(idxParts)
	s.file:write("idx1")
	s.file:write(u32(#idxBody))
	s.file:write(idxBody)

	local fileEnd = s.file:seek()
	local riffSize = math.max(0, fileEnd - 8)
	local finalHeader = buildHeader(
		s.width, s.height, s.fps, s.fourcc,
		s.writtenFrames, s.maxFrameSize, s.recordAudio, s.totalAudioSamples
	)

	s.file:seek("set", 0)
	s.file:write(finalHeader)
	s.file:seek("set", 4)
	s.file:write(u32(riffSize))
	s.file:seek("set", s.moviListSizeOffset)
	s.file:write(u32(s.moviDataBytes + 4))
	s.file:flush()
	s.file:close()

	statusCh:push({
		status = "saved",
		frames = s.writtenFrames,
		audioSamples = s.totalAudioSamples,
		path = s.path
	})
end

local function startSession(cmd)
	finalizeSession()
	closeAllAudioTracks()

	local f, err = io.open(cmd.path, "wb")
	if not f then
		statusCh:push({status = "error", error = tostring(err), path = cmd.path})
		return
	end

	local width = math.max(16, math.floor(tonumber(cmd.width) or 640))
	local height = math.max(16, math.floor(tonumber(cmd.height) or 360))
	local fps = math.max(1, math.floor(tonumber(cmd.fps) or 60))
	local fourcc = (cmd.fourcc == "MPNG") and "MPNG" or "MJPG"
	local recordAudio = (cmd.recordAudio ~= false) and hasLoveSound

	local header = buildHeader(width, height, fps, fourcc, 0, 0, recordAudio, 0)
	f:write(header)
	local moviListPos = f:seek()
	local moviListSizeOffset = moviListPos + 4
	f:write("LIST" .. u32(4) .. "movi")
	f:flush()

	session = {
		id = cmd.session or 1,
		file = f,
		path = cmd.path,
		width = width,
		height = height,
		fps = fps,
		fourcc = fourcc,
		recordAudio = recordAudio,
		moviListSizeOffset = moviListSizeOffset,
		moviDataBytes = 0,
		writtenFrames = 0,
		totalAudioSamples = 0,
		maxFrameSize = 0,
		lastVideoBytes = nil,
		nextSeq = 1,
		pending = {},
		idxFourcc = {},
		idxFlags = {},
		idxOffsets = {},
		idxSizes = {}
	}

	statusCh:push({status = "started", path = cmd.path, session = session.id})
end

local function finishUpToSeq(lastSeq)
	if not session then return end
	lastSeq = tonumber(lastSeq) or 0
	local deadline = os.clock() + 8.0
	while session and session.nextSeq <= lastSeq do
		local msg = muxCh:demand(0.1)
		if msg then
			handleMuxMessage(msg)
		elseif os.clock() >= deadline then
			-- Drain any higher out-of-order packets if a worker dropped a frame
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
