-- Stateless Multi-Core Fixed-Point MJPEG Worker Thread for Light Engine Recorder
-- Compresses raw RGBA ImageData frames into baseline 4:2:0 JPEG ByteData off-thread
-- using a flat-loop integer AAN DCT + integer RGB->YCbCr pipeline (zero closures, zero GC churn).

require "love.data"
require "love.image"

local encodeChannelName, muxChannelName = ...
local encodeCh = love.thread.getChannel(encodeChannelName or "recorder_encode")
local muxCh = love.thread.getChannel(muxChannelName or "recorder_mux")

local okFFI, ffi = pcall(require, "ffi")
local okBit, bit = pcall(require, "bit")
local USE_FAST_MJPG = okFFI and okBit and ffi ~= nil and bit ~= nil

local band, bor, lshift, rshift, arshift
if USE_FAST_MJPG then
	band, bor = bit.band, bit.bor
	lshift, rshift, arshift = bit.lshift, bit.rshift, bit.arshift
end

local STD_LUMA_QUANT = {
	16, 11, 10, 16, 24,  40,  51,  61,
	12, 12, 14, 19, 26,  58,  60,  55,
	14, 13, 16, 24, 40,  57,  69,  56,
	14, 17, 22, 29, 51,  87,  80,  62,
	18, 22, 37, 56, 68, 109, 103,  77,
	24, 35, 55, 64, 81, 104, 113,  92,
	49, 64, 78, 87, 103, 121, 120, 101,
	72, 92, 95, 98, 112, 100, 103,  99
}

local STD_CHROMA_QUANT = {
	17, 18, 24, 47, 99, 99, 99, 99,
	18, 21, 26, 66, 99, 99, 99, 99,
	24, 26, 56, 99, 99, 99, 99, 99,
	47, 66, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99
}

local ZIGZAG = {
	 0,  1,  5,  6, 14, 15, 27, 28,
	 2,  4,  7, 13, 16, 26, 29, 42,
	 3,  8, 12, 17, 25, 30, 41, 43,
	 9, 11, 18, 24, 31, 40, 44, 53,
	10, 19, 23, 32, 39, 45, 52, 54,
	20, 22, 33, 38, 46, 51, 55, 60,
	21, 34, 37, 47, 50, 56, 59, 61,
	35, 36, 48, 49, 57, 58, 62, 63
}

local AAN_SCALE = {
	1.0, 1.387039845, 1.306562965, 1.175875602,
	1.0, 0.785694958, 0.541196100, 0.275899379
}

local BITS_DC_LUMA = {0, 0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0}
local VAL_DC_LUMA = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

local BITS_DC_CHROMA = {0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0}
local VAL_DC_CHROMA = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

local BITS_AC_LUMA = {0, 0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d}
local VAL_AC_LUMA = {
	0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12,
	0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
	0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08,
	0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0,
	0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0a, 0x16,
	0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28,
	0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
	0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
	0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
	0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
	0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79,
	0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
	0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98,
	0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
	0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6,
	0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5,
	0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4,
	0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2,
	0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea,
	0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
	0xf9, 0xfa
}

local BITS_AC_CHROMA = {0, 0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77}
local VAL_AC_CHROMA = {
	0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21,
	0x31, 0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71,
	0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91,
	0xa1, 0xb1, 0xc1, 0x09, 0x23, 0x33, 0x52, 0xf0,
	0x15, 0x62, 0x72, 0xd1, 0x0a, 0x16, 0x24, 0x34,
	0xe1, 0x25, 0xf1, 0x17, 0x18, 0x19, 0x1a, 0x26,
	0x27, 0x28, 0x29, 0x2a, 0x35, 0x36, 0x37, 0x38,
	0x39, 0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
	0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
	0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68,
	0x69, 0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78,
	0x79, 0x7a, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
	0x88, 0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96,
	0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5,
	0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4,
	0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3,
	0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2,
	0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda,
	0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9,
	0xea, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
	0xf9, 0xfa
}

local fdtblY, fdtblUV, zzArr
local ydcC, ydcL, udcC, udcL, yacC, yacL, uacC, uacL
local bitcodeC, bitcodeL
local blk, zzOut
local outBuf, outBufCap = nil, 0
local jpegHdrPtr, jpegHdrLen = nil, 0
local cfgW, cfgH, cfgQuality = 0, 0, 0

if USE_FAST_MJPG then
	fdtblY = ffi.new("int32_t[64]")
	fdtblUV = ffi.new("int32_t[64]")
	zzArr = ffi.new("uint8_t[64]")
	ydcC, ydcL = ffi.new("uint16_t[16]"), ffi.new("uint8_t[16]")
	udcC, udcL = ffi.new("uint16_t[16]"), ffi.new("uint8_t[16]")
	yacC, yacL = ffi.new("uint16_t[256]"), ffi.new("uint8_t[256]")
	uacC, uacL = ffi.new("uint16_t[256]"), ffi.new("uint8_t[256]")
	bitcodeC = ffi.new("uint16_t[65535]")
	bitcodeL = ffi.new("uint8_t[65535]")
	blk = ffi.new("int32_t[64]")
	zzOut = ffi.new("int32_t[64]")

	for i = 0, 63 do
		zzArr[i] = ZIGZAG[i + 1]
	end

	local function buildHuff(nrcodes, stdTab, codeOut, lenOut)
		local code = 0
		local pos = 1
		for k = 1, 16 do
			for _ = 1, nrcodes[k + 1] do
				local sym = stdTab[pos]
				codeOut[sym] = code
				lenOut[sym] = k
				pos = pos + 1
				code = code + 1
			end
			code = code * 2
		end
	end

	buildHuff(BITS_DC_LUMA, VAL_DC_LUMA, ydcC, ydcL)
	buildHuff(BITS_DC_CHROMA, VAL_DC_CHROMA, udcC, udcL)
	buildHuff(BITS_AC_LUMA, VAL_AC_LUMA, yacC, yacL)
	buildHuff(BITS_AC_CHROMA, VAL_AC_CHROMA, uacC, uacL)

	local lower, upper = 1, 2
	for cat = 1, 15 do
		for nr = lower, upper - 1 do
			bitcodeC[32767 + nr] = nr
			bitcodeL[32767 + nr] = cat
		end
		for nrneg = -(upper - 1), -lower do
			bitcodeC[32767 + nrneg] = upper - 1 + nrneg
			bitcodeL[32767 + nrneg] = cat
		end
		lower = lower * 2
		upper = upper * 2
	end
end

local function configureEncoder(width, height, quality)
	if not USE_FAST_MJPG then return end
	quality = math.max(1, math.min(100, math.floor(tonumber(quality) or 85)))
	if cfgW == width and cfgH == height and cfgQuality == quality and jpegHdrPtr ~= nil then
		return
	end
	cfgW, cfgH, cfgQuality = width, height, quality

	local sf = quality < 50 and math.floor(5000 / quality) or (200 - quality * 2)
	local yQt, uvQt = {}, {}
	for i = 1, 64 do
		local yq = math.floor((STD_LUMA_QUANT[i] * sf + 50) / 100)
		local uvq = math.floor((STD_CHROMA_QUANT[i] * sf + 50) / 100)
		if yq < 1 then yq = 1 elseif yq > 255 then yq = 255 end
		if uvq < 1 then uvq = 1 elseif uvq > 255 then uvq = 255 end
		yQt[ZIGZAG[i] + 1] = yq
		uvQt[ZIGZAG[i] + 1] = uvq
	end

	local idx = 1
	for row = 1, 8 do
		for col = 1, 8 do
			local denomY = STD_LUMA_QUANT[idx]
			local sy = math.floor((STD_LUMA_QUANT[idx] * sf + 50) / 100)
			if sy < 1 then sy = 1 elseif sy > 255 then sy = 255 end
			local suv = math.floor((STD_CHROMA_QUANT[idx] * sf + 50) / 100)
			if suv < 1 then suv = 1 elseif suv > 255 then suv = 255 end
			denomY = sy * AAN_SCALE[row] * AAN_SCALE[col] * 8.0
			local denomUV = suv * AAN_SCALE[row] * AAN_SCALE[col] * 8.0
			fdtblY[idx - 1] = math.floor((65536.0 / denomY) + 0.5)
			fdtblUV[idx - 1] = math.floor((65536.0 / denomUV) + 0.5)
			idx = idx + 1
		end
	end

	local h = {}
	local function addByte(b) h[#h + 1] = string.char(b) end
	local function addWord(w)
		h[#h + 1] = string.char(math.floor(w / 256) % 256, w % 256)
	end
	local function addHuffTable(htId, bits, vals)
		addWord(0xFFC4)
		addWord(2 + 1 + 16 + #vals)
		addByte(htId)
		for i = 2, 17 do addByte(bits[i]) end
		for i = 1, #vals do addByte(vals[i]) end
	end

	addWord(0xFFD8)
	addWord(0xFFE0); addWord(16)
	h[#h + 1] = "JFIF\0\1\1\0\0\1\0\1\0\0"

	addWord(0xFFDB); addWord(132)
	addByte(0)
	for i = 1, 64 do addByte(yQt[i]) end
	addByte(1)
	for i = 1, 64 do addByte(uvQt[i]) end

	addWord(0xFFC0); addWord(17)
	addByte(8); addWord(height); addWord(width); addByte(3)
	addByte(1); addByte(0x22); addByte(0)
	addByte(2); addByte(0x11); addByte(1)
	addByte(3); addByte(0x11); addByte(1)

	addHuffTable(0x00, BITS_DC_LUMA, VAL_DC_LUMA)
	addHuffTable(0x10, BITS_AC_LUMA, VAL_AC_LUMA)
	addHuffTable(0x01, BITS_DC_CHROMA, VAL_DC_CHROMA)
	addHuffTable(0x11, BITS_AC_CHROMA, VAL_AC_CHROMA)

	addWord(0xFFDA); addWord(12)
	addByte(3)
	addByte(1); addByte(0x00)
	addByte(2); addByte(0x11)
	addByte(3); addByte(0x11)
	addByte(0); addByte(63); addByte(0)

	local hdrStr = table.concat(h)
	jpegHdrLen = #hdrStr
	jpegHdrPtr = ffi.new("uint8_t[?]", jpegHdrLen)
	ffi.copy(jpegHdrPtr, hdrStr, jpegHdrLen)

	local needed = width * height * 2 + 16384
	if needed > outBufCap then
		outBufCap = needed
		outBuf = ffi.new("uint8_t[?]", outBufCap)
	end
end

local function dctAndEmitBlock(fdtbl, dcPrev, dcC, dcL, acC, acL, pos, bitBuf, bitCnt)
	for r = 0, 56, 8 do
		local s0, s1, s2, s3 = blk[r], blk[r + 1], blk[r + 2], blk[r + 3]
		local s4, s5, s6, s7 = blk[r + 4], blk[r + 5], blk[r + 6], blk[r + 7]
		local t0, t7 = s0 + s7, s0 - s7
		local t1, t6 = s1 + s6, s1 - s6
		local t2, t5 = s2 + s5, s2 - s5
		local t3, t4 = s3 + s4, s3 - s4

		local t10, t13 = t0 + t3, t0 - t3
		local t11, t12 = t1 + t2, t1 - t2

		blk[r] = t10 + t11
		blk[r + 4] = t10 - t11

		local z1 = arshift((t12 + t13) * 181, 8)
		blk[r + 2] = t13 + z1
		blk[r + 6] = t13 - z1

		local p10 = t4 + t5
		local p11 = t5 + t6
		local p12 = t6 + t7

		local z5 = arshift((p10 - p12) * 98, 8)
		local z2 = arshift(p10 * 139, 8) + z5
		local z4 = arshift(p12 * 334, 8) + z5
		local z3 = arshift(p11 * 181, 8)

		local z11, z13 = t7 + z3, t7 - z3
		blk[r + 5] = z13 + z2
		blk[r + 3] = z13 - z2
		blk[r + 1] = z11 + z4
		blk[r + 7] = z11 - z4
	end

	for c = 0, 7 do
		local s0, s1, s2, s3 = blk[c], blk[c + 8], blk[c + 16], blk[c + 24]
		local s4, s5, s6, s7 = blk[c + 32], blk[c + 40], blk[c + 48], blk[c + 56]
		local t0, t7 = s0 + s7, s0 - s7
		local t1, t6 = s1 + s6, s1 - s6
		local t2, t5 = s2 + s5, s2 - s5
		local t3, t4 = s3 + s4, s3 - s4

		local t10, t13 = t0 + t3, t0 - t3
		local t11, t12 = t1 + t2, t1 - t2

		blk[c] = t10 + t11
		blk[c + 32] = t10 - t11

		local z1 = arshift((t12 + t13) * 181, 8)
		blk[c + 16] = t13 + z1
		blk[c + 48] = t13 - z1

		local p10 = t4 + t5
		local p11 = t5 + t6
		local p12 = t6 + t7

		local z5 = arshift((p10 - p12) * 98, 8)
		local z2 = arshift(p10 * 139, 8) + z5
		local z4 = arshift(p12 * 334, 8) + z5
		local z3 = arshift(p11 * 181, 8)

		local z11, z13 = t7 + z3, t7 - z3
		blk[c + 40] = z13 + z2
		blk[c + 24] = z13 - z2
		blk[c + 8] = z11 + z4
		blk[c + 56] = z11 - z4
	end

	for i = 0, 63 do
		local v = blk[i]
		local q = fdtbl[i]
		if v >= 0 then
			zzOut[zzArr[i]] = rshift(v * q + 32768, 16)
		else
			zzOut[zzArr[i]] = -rshift((-v) * q + 32768, 16)
		end
	end

	local dc = zzOut[0]
	local diff = dc - dcPrev
	dcPrev = dc

	if diff == 0 then
		local l = dcL[0]
		bitBuf = bor(lshift(bitBuf, l), dcC[0])
		bitCnt = bitCnt + l
	else
		local idx = 32767 + diff
		local cat = bitcodeL[idx]
		local hl = dcL[cat]
		bitBuf = bor(lshift(bitBuf, hl), dcC[cat])
		bitCnt = bitCnt + hl
		while bitCnt >= 8 do
			bitCnt = bitCnt - 8
			local b = band(rshift(bitBuf, bitCnt), 0xFF)
			outBuf[pos] = b; pos = pos + 1
			if b == 0xFF then outBuf[pos] = 0; pos = pos + 1 end
		end
		bitBuf = bor(lshift(bitBuf, cat), bitcodeC[idx])
		bitCnt = bitCnt + cat
	end
	while bitCnt >= 8 do
		bitCnt = bitCnt - 8
		local b = band(rshift(bitBuf, bitCnt), 0xFF)
		outBuf[pos] = b; pos = pos + 1
		if b == 0xFF then outBuf[pos] = 0; pos = pos + 1 end
	end

	local end0 = 63
	while end0 > 0 and zzOut[end0] == 0 do
		end0 = end0 - 1
	end

	if end0 == 0 then
		local l = acL[0]
		bitBuf = bor(lshift(bitBuf, l), acC[0])
		bitCnt = bitCnt + l
		while bitCnt >= 8 do
			bitCnt = bitCnt - 8
			local b = band(rshift(bitBuf, bitCnt), 0xFF)
			outBuf[pos] = b; pos = pos + 1
			if b == 0xFF then outBuf[pos] = 0; pos = pos + 1 end
		end
		return dcPrev, pos, bitBuf, bitCnt
	end

	local i = 1
	while i <= end0 do
		local start = i
		while zzOut[i] == 0 and i <= end0 do
			i = i + 1
		end
		local nrzeroes = i - start
		while nrzeroes >= 16 do
			local l16 = acL[0xF0]
			bitBuf = bor(lshift(bitBuf, l16), acC[0xF0])
			bitCnt = bitCnt + l16
			while bitCnt >= 8 do
				bitCnt = bitCnt - 8
				local b = band(rshift(bitBuf, bitCnt), 0xFF)
				outBuf[pos] = b; pos = pos + 1
				if b == 0xFF then outBuf[pos] = 0; pos = pos + 1 end
			end
			nrzeroes = nrzeroes - 16
		end

		local idx = 32767 + zzOut[i]
		local cat = bitcodeL[idx]
		local sym = nrzeroes * 16 + cat
		local hl = acL[sym]
		bitBuf = bor(lshift(bitBuf, hl), acC[sym])
		bitCnt = bitCnt + hl
		while bitCnt >= 8 do
			bitCnt = bitCnt - 8
			local b = band(rshift(bitBuf, bitCnt), 0xFF)
			outBuf[pos] = b; pos = pos + 1
			if b == 0xFF then outBuf[pos] = 0; pos = pos + 1 end
		end

		bitBuf = bor(lshift(bitBuf, cat), bitcodeC[idx])
		bitCnt = bitCnt + cat
		while bitCnt >= 8 do
			bitCnt = bitCnt - 8
			local b = band(rshift(bitBuf, bitCnt), 0xFF)
			outBuf[pos] = b; pos = pos + 1
			if b == 0xFF then outBuf[pos] = 0; pos = pos + 1 end
		end
		i = i + 1
	end

	if end0 ~= 63 then
		local l = acL[0]
		bitBuf = bor(lshift(bitBuf, l), acC[0])
		bitCnt = bitCnt + l
		while bitCnt >= 8 do
			bitCnt = bitCnt - 8
			local b = band(rshift(bitBuf, bitCnt), 0xFF)
			outBuf[pos] = b; pos = pos + 1
			if b == 0xFF then outBuf[pos] = 0; pos = pos + 1 end
		end
	end

	return dcPrev, pos, bitBuf, bitCnt
end

local function loadLuma8x8Fast(rgba, stride, bx, by)
	local rowPtr = by * stride + bx * 4
	local k = 0
	for _ = 0, 7 do
		local p = rowPtr
		for _ = 0, 7 do
			blk[k] = rshift(77 * rgba[p] + 150 * rgba[p + 1] + 29 * rgba[p + 2], 8) - 128
			k = k + 1
			p = p + 4
		end
		rowPtr = rowPtr + stride
	end
end

local function loadLuma8x8Clamped(rgba, w, h, stride, bx, by)
	local k = 0
	for dy = 0, 7 do
		local py = by + dy
		if py >= h then py = h - 1 end
		local rowBase = py * stride
		for dx = 0, 7 do
			local px = bx + dx
			if px >= w then px = w - 1 end
			local p = rowBase + px * 4
			blk[k] = rshift(77 * rgba[p] + 150 * rgba[p + 1] + 29 * rgba[p + 2], 8) - 128
			k = k + 1
		end
	end
end

local uTmp = USE_FAST_MJPG and ffi.new("int32_t[64]") or nil
local vTmp = USE_FAST_MJPG and ffi.new("int32_t[64]") or nil

local function loadChroma8x8Fast(rgba, stride, mx, my)
	local row0 = my * stride + mx * 4
	local row1 = row0 + stride
	local step = stride * 2
	local k = 0
	for _ = 0, 7 do
		local p0, p1 = row0, row1
		for _ = 0, 7 do
			local r = rgba[p0] + rgba[p0 + 4] + rgba[p1] + rgba[p1 + 4]
			local g = rgba[p0 + 1] + rgba[p0 + 5] + rgba[p1 + 1] + rgba[p1 + 5]
			local b = rgba[p0 + 2] + rgba[p0 + 6] + rgba[p1 + 2] + rgba[p1 + 6]
			uTmp[k] = arshift(-43 * r - 85 * g + 128 * b, 10)
			vTmp[k] = arshift(128 * r - 107 * g - 21 * b, 10)
			k = k + 1
			p0 = p0 + 8
			p1 = p1 + 8
		end
		row0 = row0 + step
		row1 = row1 + step
	end
end

local function loadChroma8x8Clamped(rgba, w, h, stride, mx, my)
	local k = 0
	for cy = 0, 7 do
		local y0 = my + cy * 2
		local y1 = y0 + 1
		if y0 >= h then y0 = h - 1 end
		if y1 >= h then y1 = h - 1 end
		local rb0, rb1 = y0 * stride, y1 * stride
		for cx = 0, 7 do
			local x0 = mx + cx * 2
			local x1 = x0 + 1
			if x0 >= w then x0 = w - 1 end
			if x1 >= w then x1 = w - 1 end
			local p00, p01 = rb0 + x0 * 4, rb0 + x1 * 4
			local p10, p11 = rb1 + x0 * 4, rb1 + x1 * 4
			local r = rgba[p00] + rgba[p01] + rgba[p10] + rgba[p11]
			local g = rgba[p00 + 1] + rgba[p01 + 1] + rgba[p10 + 1] + rgba[p11 + 1]
			local b = rgba[p00 + 2] + rgba[p01 + 2] + rgba[p10 + 2] + rgba[p11 + 2]
			uTmp[k] = arshift(-43 * r - 85 * g + 128 * b, 10)
			vTmp[k] = arshift(128 * r - 107 * g - 21 * b, 10)
			k = k + 1
		end
	end
end

local function encodeFrameMJPG(imageData, width, height, quality)
	configureEncoder(width, height, quality)
	local rgba = ffi.cast("const uint8_t*", imageData:getFFIPointer())
	local stride = width * 4

	ffi.copy(outBuf, jpegHdrPtr, jpegHdrLen)
	local pos = jpegHdrLen
	local bitBuf, bitCnt = 0, 0
	local dcY, dcU, dcV = 0, 0, 0

	for my = 0, height - 1, 16 do
		local fastY = (my + 15) < height
		for mx = 0, width - 1, 16 do
			if fastY and (mx + 15) < width then
				loadLuma8x8Fast(rgba, stride, mx, my)
				dcY, pos, bitBuf, bitCnt = dctAndEmitBlock(fdtblY, dcY, ydcC, ydcL, yacC, yacL, pos, bitBuf, bitCnt)
				loadLuma8x8Fast(rgba, stride, mx + 8, my)
				dcY, pos, bitBuf, bitCnt = dctAndEmitBlock(fdtblY, dcY, ydcC, ydcL, yacC, yacL, pos, bitBuf, bitCnt)
				loadLuma8x8Fast(rgba, stride, mx, my + 8)
				dcY, pos, bitBuf, bitCnt = dctAndEmitBlock(fdtblY, dcY, ydcC, ydcL, yacC, yacL, pos, bitBuf, bitCnt)
				loadLuma8x8Fast(rgba, stride, mx + 8, my + 8)
				dcY, pos, bitBuf, bitCnt = dctAndEmitBlock(fdtblY, dcY, ydcC, ydcL, yacC, yacL, pos, bitBuf, bitCnt)
				loadChroma8x8Fast(rgba, stride, mx, my)
			else
				loadLuma8x8Clamped(rgba, width, height, stride, mx, my)
				dcY, pos, bitBuf, bitCnt = dctAndEmitBlock(fdtblY, dcY, ydcC, ydcL, yacC, yacL, pos, bitBuf, bitCnt)
				loadLuma8x8Clamped(rgba, width, height, stride, mx + 8, my)
				dcY, pos, bitBuf, bitCnt = dctAndEmitBlock(fdtblY, dcY, ydcC, ydcL, yacC, yacL, pos, bitBuf, bitCnt)
				loadLuma8x8Clamped(rgba, width, height, stride, mx, my + 8)
				dcY, pos, bitBuf, bitCnt = dctAndEmitBlock(fdtblY, dcY, ydcC, ydcL, yacC, yacL, pos, bitBuf, bitCnt)
				loadLuma8x8Clamped(rgba, width, height, stride, mx + 8, my + 8)
				dcY, pos, bitBuf, bitCnt = dctAndEmitBlock(fdtblY, dcY, ydcC, ydcL, yacC, yacL, pos, bitBuf, bitCnt)
				loadChroma8x8Clamped(rgba, width, height, stride, mx, my)
			end

			ffi.copy(blk, uTmp, 256)
			dcU, pos, bitBuf, bitCnt = dctAndEmitBlock(fdtblUV, dcU, udcC, udcL, uacC, uacL, pos, bitBuf, bitCnt)

			ffi.copy(blk, vTmp, 256)
			dcV, pos, bitBuf, bitCnt = dctAndEmitBlock(fdtblUV, dcV, udcC, udcL, uacC, uacL, pos, bitBuf, bitCnt)
		end
	end

	if bitCnt > 0 then
		local pad = 8 - bitCnt
		bitBuf = bor(lshift(bitBuf, pad), lshift(1, pad) - 1)
		local b = band(bitBuf, 0xFF)
		outBuf[pos] = b; pos = pos + 1
		if b == 0xFF then outBuf[pos] = 0; pos = pos + 1 end
	end

	outBuf[pos] = 0xFF
	outBuf[pos + 1] = 0xD9
	local totalLen = pos + 2

	local byteData = love.data.newByteData(totalLen)
	ffi.copy(byteData:getFFIPointer(), outBuf, totalLen)
	return byteData
end

while true do
	local job = encodeCh:demand()
	if type(job) == "table" then
		if job.type == "quit" then
			break
		elseif job.type == "encode" then
			local img = job.image
			local encodedData
			if img then
				local ok, res = pcall(function()
					if USE_FAST_MJPG and job.fourcc ~= "MPNG" then
						return encodeFrameMJPG(img, job.width, job.height, job.quality)
					else
						return img:encode("png")
					end
				end)
				pcall(function() img:release() end)
				if ok then encodedData = res end
			end
			muxCh:push({
				type = "encoded",
				session = job.session,
				seq = job.seq,
				targetFrame = job.targetFrame,
				payload = encodedData,
				audio = job.audio
			})
		end
	end
end
