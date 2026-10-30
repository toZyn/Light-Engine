-- Pure LuaJIT / Lua ISO-BMFF (.mp4) Video + Lossless Stereo Audio Muxer
-- Writes spec-compliant ISO Base Media File Format (.mp4) containers with:
--   * Video track: MPEG-4 Visual `mp4v` (ObjectTypeIndication 0x6C JPEG or 0x6D PNG)
--   * Audio track: Apple Lossless `alac` (44.1 kHz 16-bit Stereo, bit-exact verbatim frames)
-- Zero external binaries required; supports >4 GiB files automatically via `co64`.

local Mp4Muxer = {}
Mp4Muxer.__index = Mp4Muxer

local okFFI, ffi = pcall(require, "ffi")
local okBit, bit = pcall(require, "bit")
local USE_FFI = okFFI and okBit and ffi ~= nil and bit ~= nil

local AUDIO_RATE = 44100
local AUDIO_CHANNELS = 2
local AUDIO_BITS = 16
local MAX_ALAC_SAMPLES = 4096

local alacScratch = USE_FFI and ffi.new("uint8_t[?]", 8 + MAX_ALAC_SAMPLES * 4 + 16) or nil

local function u8(n)
	return string.char(math.floor(n or 0) % 256)
end

local function u16be(n)
	n = math.floor(n or 0) % 65536
	return string.char(math.floor(n / 256) % 256, n % 256)
end

local function u24be(n)
	n = math.floor(n or 0) % 16777216
	return string.char(
		math.floor(n / 65536) % 256,
		math.floor(n / 256) % 256,
		n % 256
	)
end

local function u32be(n)
	n = math.floor(n or 0)
	if n < 0 then n = 4294967296 + n end
	n = n % 4294967296
	return string.char(
		math.floor(n / 16777216) % 256,
		math.floor(n / 65536) % 256,
		math.floor(n / 256) % 256,
		n % 256
	)
end

local function u64be(n)
	n = math.max(0, math.floor(n or 0))
	local hi = math.floor(n / 4294967296)
	local lo = n - hi * 4294967296
	return u32be(hi) .. u32be(lo)
end

local function box(fourcc, payload)
	payload = payload or ""
	return u32be(8 + #payload) .. fourcc .. payload
end

local function fullbox(fourcc, version, flags, payload)
	payload = payload or ""
	return box(fourcc, u8(version or 0) .. u24be(flags or 0) .. payload)
end

local function mp4Descr(tag, body)
	local len = #body
	-- 4-byte expandable length encoding (ISO/IEC 14496-1)
	local b1 = 0x80 + (math.floor(len / 2097152) % 128)
	local b2 = 0x80 + (math.floor(len / 16384) % 128)
	local b3 = 0x80 + (math.floor(len / 128) % 128)
	local b4 = len % 128
	return string.char(tag, b1, b2, b3, b4) .. body
end

local function encodeAlacPacket(pcmSource, sampleOffset, numFrames)
	if numFrames <= 0 then return nil end
	if USE_FFI and type(pcmSource) == "cdata" then
		local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift
		local src = ffi.cast("const uint16_t*", pcmSource) + (sampleOffset * 2)
		local out = alacScratch
		-- 23-bit header: ID_CPE(1)<<20 | tag(0)<<16 | unused(0)<<4 | has_size(1)<<3 | uncomp(0)<<1 | verbatim(1) = 0x100009
		out[0] = 0x20
		out[1] = 0x00
		out[2] = bor(0x12, band(rshift(numFrames, 31), 1))
		out[3] = band(rshift(numFrames, 23), 0xFF)
		out[4] = band(rshift(numFrames, 15), 0xFF)
		out[5] = band(rshift(numFrames, 7), 0xFF)

		local bitBuf = band(numFrames, 0x7F) -- 7 bits remaining
		local pos = 6
		local count = numFrames * 2
		for i = 0, count - 1 do
			local s = src[i] -- uint16 host (little-endian on ARM/x86) = signed 16-bit value & 0xFFFF
			bitBuf = bor(lshift(bitBuf, 16), s)
			out[pos] = band(rshift(bitBuf, 15), 0xFF)
			out[pos + 1] = band(rshift(bitBuf, 7), 0xFF)
			pos = pos + 2
			bitBuf = band(bitBuf, 0x7F)
		end

		-- Append ID_END = 7 (3 bits) -> 10 bits total, pad with 6 zero bits
		bitBuf = bor(lshift(bitBuf, 3), 7)
		out[pos] = band(rshift(bitBuf, 2), 0xFF)
		out[pos + 1] = band(lshift(bitBuf, 6), 0xFF)
		return ffi.string(out, pos + 2)
	end

	-- Pure-Lua fallback for binary string S16LE input
	local pcmStr = tostring(pcmSource)
	local parts = {
		string.char(
			0x20,
			0x00,
			0x12,
			math.floor(numFrames / 8388608) % 256,
			math.floor(numFrames / 32768) % 256,
			math.floor(numFrames / 128) % 256
		)
	}
	local bitBuf = numFrames % 128
	local baseByte = sampleOffset * 4
	for i = 1, numFrames * 2 do
		local idx = baseByte + (i - 1) * 2 + 1
		local lo = pcmStr:byte(idx) or 0
		local hi = pcmStr:byte(idx + 1) or 0
		local s = hi * 256 + lo
		bitBuf = bitBuf * 65536 + s
		local b1 = math.floor(bitBuf / 32768) % 256
		local b2 = math.floor(bitBuf / 128) % 256
		parts[#parts + 1] = string.char(b1, b2)
		bitBuf = bitBuf % 128
	end
	bitBuf = bitBuf * 8 + 7
	parts[#parts + 1] = string.char(math.floor(bitBuf / 4) % 256, (bitBuf % 4) * 64)
	return table.concat(parts)
end

local function buildStts(durations)
	local entries = {}
	local curDur, curCount = nil, 0
	for i = 1, #durations do
		local d = durations[i]
		if d == curDur then
			curCount = curCount + 1
		else
			if curDur ~= nil then
				entries[#entries + 1] = u32be(curCount) .. u32be(curDur)
			end
			curDur = d
			curCount = 1
		end
	end
	if curDur ~= nil then
		entries[#entries + 1] = u32be(curCount) .. u32be(curDur)
	end
	return fullbox("stts", 0, 0, u32be(#entries) .. table.concat(entries))
end

local function buildStsz(sizes)
	local parts = {u32be(0), u32be(#sizes)}
	for i = 1, #sizes do
		parts[i + 2] = u32be(sizes[i])
	end
	return fullbox("stsz", 0, 0, table.concat(parts))
end

local function buildChunkOffsets(offsets, use64)
	if use64 then
		local parts = {u32be(#offsets)}
		for i = 1, #offsets do
			parts[i + 1] = u64be(offsets[i])
		end
		return fullbox("co64", 0, 0, table.concat(parts))
	end
	local parts = {u32be(#offsets)}
	for i = 1, #offsets do
		parts[i + 1] = u32be(offsets[i])
	end
	return fullbox("stco", 0, 0, table.concat(parts))
end

local function buildMatrixIdentity()
	return table.concat({
		u32be(0x00010000), u32be(0), u32be(0),
		u32be(0), u32be(0x00010000), u32be(0),
		u32be(0), u32be(0), u32be(0x40000000)
	})
end

local function buildVideoTrak(trackId, width, height, timescale, totalDuration, movieTimescale, objectType, sizes, offsets, durations, use64, maxBitrate, avgBitrate)
	local movieDuration = math.max(1, math.floor((totalDuration / math.max(1, timescale)) * movieTimescale + 0.5))

	local tkhd = fullbox("tkhd", 0, 0x000003, table.concat({
		u32be(0), u32be(0),
		u32be(trackId),
		u32be(0),
		u32be(movieDuration),
		u32be(0), u32be(0),
		u16be(0), u16be(0),
		u16be(0), u16be(0),
		buildMatrixIdentity(),
		u32be(width * 65536),
		u32be(height * 65536)
	}))

	local mdhd = fullbox("mdhd", 0, 0, table.concat({
		u32be(0), u32be(0),
		u32be(timescale),
		u32be(totalDuration),
		u16be(0x55C4), -- 'und'
		u16be(0)
	}))

	local hdlr = fullbox("hdlr", 0, 0, table.concat({
		u32be(0),
		"vide",
		u32be(0), u32be(0), u32be(0),
		"LightEngine Video\0"
	}))

	local vmhd = fullbox("vmhd", 0, 1, u16be(0) .. u16be(0) .. u16be(0) .. u16be(0))
	local dref = fullbox("dref", 0, 0, u32be(1) .. fullbox("url ", 0, 1, ""))
	local dinf = box("dinf", dref)

	-- ES_Descriptor for MPEG-4 Visual wrapping JPEG (0x6C) or PNG (0x6D)
	local decConfig = mp4Descr(0x04, table.concat({
		u8(objectType or 0x6C),
		u8(0x11), -- visual stream (0x04 << 2) | 1
		u24be(math.min(16777215, width * height * 3)),
		u32be(maxBitrate or 20000000),
		u32be(avgBitrate or 8000000)
	}))
	local slConfig = mp4Descr(0x06, u8(0x02))
	local esDescr = mp4Descr(0x03, u16be(1) .. u8(0) .. decConfig .. slConfig)
	local esds = fullbox("esds", 0, 0, esDescr)

	local compressorName = "\11LightEngine" .. string.rep("\0", 20) -- 32-byte Pascal string
	local mp4v = box("mp4v", table.concat({
		string.rep("\0", 6),
		u16be(1),
		u16be(0), u16be(0),
		u32be(0), u32be(0), u32be(0),
		u16be(width),
		u16be(height),
		u32be(0x00480000),
		u32be(0x00480000),
		u32be(0),
		u16be(1),
		compressorName,
		u16be(0x0018),
		u16be(0xFFFF),
		esds
	}))

	local stsd = fullbox("stsd", 0, 0, u32be(1) .. mp4v)
	local stsc = fullbox("stsc", 0, 0, u32be(1) .. u32be(1) .. u32be(1) .. u32be(1))
	local stbl = box("stbl", table.concat({
		stsd,
		buildStts(durations),
		stsc,
		buildStsz(sizes),
		buildChunkOffsets(offsets, use64)
	}))

	local minf = box("minf", vmhd .. dinf .. stbl)
	local mdia = box("mdia", mdhd .. hdlr .. minf)
	local elst = fullbox("elst", 0, 0, u32be(1) .. u32be(movieDuration) .. u32be(0) .. u16be(1) .. u16be(0))
	local edts = box("edts", elst)
	return box("trak", tkhd .. edts .. mdia)
end

local function buildAudioTrak(trackId, totalSamples, movieTimescale, sizes, offsets, durations, use64, maxFrameBytes, audioRate)
	local rate = math.max(8000, math.floor(tonumber(audioRate) or AUDIO_RATE))
	local movieDuration = math.max(1, math.floor((totalSamples / rate) * movieTimescale + 0.5))

	local tkhd = fullbox("tkhd", 0, 0x000003, table.concat({
		u32be(0), u32be(0),
		u32be(trackId),
		u32be(0),
		u32be(movieDuration),
		u32be(0), u32be(0),
		u16be(0), u16be(0),
		u16be(0x0100), -- audio volume 1.0
		u16be(0),
		buildMatrixIdentity(),
		u32be(0),
		u32be(0)
	}))

	local mdhd = fullbox("mdhd", 0, 0, table.concat({
		u32be(0), u32be(0),
		u32be(rate),
		u32be(totalSamples),
		u16be(0x55C4),
		u16be(0)
	}))

	local hdlr = fullbox("hdlr", 0, 0, table.concat({
		u32be(0),
		"soun",
		u32be(0), u32be(0), u32be(0),
		"LightEngine Audio\0"
	}))

	local smhd = fullbox("smhd", 0, 0, u16be(0) .. u16be(0))
	local dref = fullbox("dref", 0, 0, u32be(1) .. fullbox("url ", 0, 1, ""))
	local dinf = box("dinf", dref)

	local alacConfig = fullbox("alac", 0, 0, table.concat({
		u32be(MAX_ALAC_SAMPLES),
		u8(0),
		u8(AUDIO_BITS),
		u8(40), u8(10), u8(14),
		u8(AUDIO_CHANNELS),
		u16be(255),
		u32be(math.max(maxFrameBytes or 16400, 16400)),
		u32be(rate * AUDIO_CHANNELS * AUDIO_BITS),
		u32be(rate)
	}))

	local alacEntry = box("alac", table.concat({
		string.rep("\0", 6),
		u16be(1),
		u32be(0), u32be(0),
		u16be(AUDIO_CHANNELS),
		u16be(AUDIO_BITS),
		u16be(0), u16be(0),
		u32be(rate * 65536),
		alacConfig
	}))

	local stsd = fullbox("stsd", 0, 0, u32be(1) .. alacEntry)
	local stsc = fullbox("stsc", 0, 0, u32be(1) .. u32be(1) .. u32be(1) .. u32be(1))
	local stbl = box("stbl", table.concat({
		stsd,
		buildStts(durations),
		stsc,
		buildStsz(sizes),
		buildChunkOffsets(offsets, use64)
	}))

	local minf = box("minf", smhd .. dinf .. stbl)
	local mdia = box("mdia", mdhd .. hdlr .. minf)
	local elst = fullbox("elst", 0, 0, u32be(1) .. u32be(movieDuration) .. u32be(0) .. u16be(1) .. u16be(0))
	local edts = box("edts", elst)
	return box("trak", tkhd .. edts .. mdia)
end

function Mp4Muxer.open(path, width, height, fps, recordAudio, objectType, audioRate)
	local f, err = io.open(path, "wb")
	if not f then
		return nil, err
	end

	local ftyp = box("ftyp", "isom" .. u32be(0x00000200) .. "isomiso2mp41M4A ") -- 32 bytes
	f:write(ftyp)
	-- Reserve 8-byte `free` box at offset 32 + 8-byte `mdat` header at offset 40
	-- so <4 GiB files use universal 32-bit `mdat`, while >4 GiB seamlessly upgrades
	-- bytes 32..47 to a 16-byte 64-bit largesize `mdat` without shifting media data.
	local freePos = f:seek()
	f:write(u32be(8) .. "free")
	local mdatPos = f:seek()
	f:write(u32be(0) .. "mdat")
	f:flush()

	local timescale = math.max(1000, math.floor((tonumber(fps) or 60) * 1000 + 0.5))
	local resolvedAudioRate = math.max(8000, math.floor(tonumber(audioRate) or AUDIO_RATE))
	local self = setmetatable({
		file = f,
		path = path,
		width = math.max(16, math.floor(tonumber(width) or 640)),
		height = math.max(16, math.floor(tonumber(height) or 360)),
		fps = math.max(1, tonumber(fps) or 60),
		timescale = timescale,
		defaultFrameTicks = 1000,
		recordAudio = recordAudio == true,
		objectType = objectType or 0x6C,
		audioRate = resolvedAudioRate,

		freePos = freePos,
		mdatPos = mdatPos,
		videoBytesTotal = 0,
		maxVideoFrameSize = 0,
		vOffsets = {},
		vSizes = {},
		vDurations = {},
		totalVideoTicks = 0,

		aOffsets = {},
		aSizes = {},
		aDurations = {},
		totalAudioSamples = 0,
		maxAudioPacketBytes = 0,
		closed = false
	}, Mp4Muxer)

	return self
end

function Mp4Muxer:writeVideoFrame(encodedBytes, durationTicks)
	if self.closed or not self.file or type(encodedBytes) ~= "string" or #encodedBytes == 0 then
		return false
	end
	local offset = self.file:seek()
	local sz = #encodedBytes
	local ticks = math.max(1, math.floor(tonumber(durationTicks) or self.defaultFrameTicks))

	self.file:write(encodedBytes)
	local idx = #self.vSizes + 1
	self.vOffsets[idx] = offset
	self.vSizes[idx] = sz
	self.vDurations[idx] = ticks
	self.totalVideoTicks = self.totalVideoTicks + ticks
	self.videoBytesTotal = self.videoBytesTotal + sz
	if sz > self.maxVideoFrameSize then
		self.maxVideoFrameSize = sz
	end
	return true
end

function Mp4Muxer:writeAudioPcm(pcmSource, numStereoFrames)
	if self.closed or not self.file or not self.recordAudio then
		return false
	end
	numStereoFrames = math.floor(tonumber(numStereoFrames) or 0)
	if numStereoFrames <= 0 then return true end

	local offsetFrames = 0
	while offsetFrames < numStereoFrames do
		local chunkFrames = math.min(MAX_ALAC_SAMPLES, numStereoFrames - offsetFrames)
		local pkt = encodeAlacPacket(pcmSource, offsetFrames, chunkFrames)
		if pkt and #pkt > 0 then
			local fileOffset = self.file:seek()
			self.file:write(pkt)
			local idx = #self.aSizes + 1
			self.aOffsets[idx] = fileOffset
			self.aSizes[idx] = #pkt
			self.aDurations[idx] = chunkFrames
			self.totalAudioSamples = self.totalAudioSamples + chunkFrames
			if #pkt > self.maxAudioPacketBytes then
				self.maxAudioPacketBytes = #pkt
			end
		end
		offsetFrames = offsetFrames + chunkFrames
	end
	return true
end

function Mp4Muxer:close()
	if self.closed then return false end
	self.closed = true

	local f = self.file
	self.file = nil
	if not f then return false end

	if #self.vSizes == 0 then
		f:close()
		pcall(os.remove, self.path)
		return false, "empty"
	end

	local mdatEnd = f:seek()
	local use64 = (mdatEnd > 0xFFFFFFFF)

	local movieTimescale = 1000
	local videoSec = math.max(0.001, self.totalVideoTicks / self.timescale)
	local audioSec = (#self.aSizes > 0) and (self.totalAudioSamples / self.audioRate) or 0
	local maxSec = math.max(videoSec, audioSec)
	local movieDuration = math.max(1, math.floor(maxSec * movieTimescale + 0.5))

	local avgBitrate = math.max(64000, math.floor((self.videoBytesTotal * 8) / videoSec))
	local maxBitrate = math.max(avgBitrate, math.floor(self.maxVideoFrameSize * 8 * self.fps))

	local nextTrackId = 2
	local traks = {
		buildVideoTrak(
			1, self.width, self.height, self.timescale, self.totalVideoTicks,
			movieTimescale, self.objectType, self.vSizes, self.vOffsets, self.vDurations,
			use64, maxBitrate, avgBitrate
		)
	}
	if self.recordAudio and #self.aSizes > 0 and self.totalAudioSamples > 0 then
		traks[#traks + 1] = buildAudioTrak(
			2, self.totalAudioSamples, movieTimescale,
			self.aSizes, self.aOffsets, self.aDurations, use64, self.maxAudioPacketBytes,
			self.audioRate
		)
		nextTrackId = 3
	end

	local mvhd = fullbox("mvhd", 0, 0, table.concat({
		u32be(0), u32be(0),
		u32be(movieTimescale),
		u32be(movieDuration),
		u32be(0x00010000), -- rate 1.0
		u16be(0x0100),     -- volume 1.0
		string.rep("\0", 10),
		buildMatrixIdentity(),
		string.rep("\0", 24),
		u32be(nextTrackId)
	}))

	local moov = box("moov", mvhd .. table.concat(traks))
	f:write(moov)

	if use64 then
		f:seek("set", self.freePos)
		f:write(u32be(1) .. "mdat" .. u64be(mdatEnd - self.freePos))
	else
		f:seek("set", self.mdatPos)
		f:write(u32be(mdatEnd - self.mdatPos))
	end

	f:flush()
	f:close()
	return true, #self.vSizes, self.totalAudioSamples
end

return Mp4Muxer
