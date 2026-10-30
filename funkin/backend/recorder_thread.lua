-- Background worker thread for low-resource AVI (MJPG / MPNG fallback) video encoding.
-- Runs off the main thread so gameplay frame pacing stays smooth.

local cmdChannelName, statusChannelName = ...
local cmdChannel = love.thread.getChannel(cmdChannelName)
local statusChannel = love.thread.getChannel(statusChannelName)

pcall(require, "love.image")
pcall(require, "love.data")
pcall(require, "love.timer")

local okFFI, ffi = pcall(require, "ffi")
local okBit, bit = pcall(require, "bit")
local canMJPG = okFFI and okBit and ffi ~= nil and bit ~= nil

local band, bor, lshift, rshift, arshift
if canMJPG then
	band, bor, lshift, rshift, arshift = bit.band, bit.bor, bit.lshift, bit.rshift, bit.arshift
end

-- Standard JPEG zigzag order (0-indexed into 8x8 block)
local ZIGZAG = {
	 0,  1,  8, 16,  9,  2,  3, 10,
	17, 24, 32, 25, 18, 11,  4,  5,
	12, 19, 26, 33, 40, 48, 41, 34,
	27, 20, 13,  6,  7, 14, 21, 28,
	35, 42, 49, 56, 57, 50, 43, 36,
	29, 22, 15, 23, 30, 37, 44, 51,
	58, 59, 52, 45, 38, 31, 39, 46,
	53, 60, 61, 54, 47, 55, 62, 63
}

-- Base Annex K quantization tables (quality ~80)
local BASE_QTY = {
	16, 11, 10, 16,  24,  40,  51,  61,
	12, 12, 14, 19,  26,  58,  60,  55,
	14, 13, 16, 24,  40,  57,  69,  56,
	14, 17, 22, 29,  51,  87,  80,  62,
	18, 22, 37, 56,  68, 109, 103,  77,
	24, 35, 55, 64,  81, 104, 113,  92,
	49, 64, 78, 87, 103, 121, 120, 101,
	72, 92, 95, 98, 112, 100, 103,  99
}

local BASE_QTC = {
	17, 18, 24, 47, 99, 99, 99, 99,
	18, 21, 26, 66, 99, 99, 99, 99,
	24, 26, 56, 99, 99, 99, 99, 99,
	47, 66, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99
}

-- Standard Annex K Huffman tables
local BITS_DC_Y = {0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0}
local VAL_DC_Y  = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

local BITS_DC_C = {0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0}
local VAL_DC_C  = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

local BITS_AC_Y = {0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d}
local VAL_AC_Y  = {
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

local BITS_AC_C = {0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77}
local VAL_AC_C  = {
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

local AAN_SCALES = {
	1.0, 1.387039845, 1.306562965, 1.175875602,
	1.0, 0.785694958, 0.541196100, 0.275899379
}

local mjpgState

local function initMJPG(quality)
	if not canMJPG then return nil end
	quality = math.max(10, math.min(95, quality or 78))
	local scale = quality < 50 and math.floor(5000 / quality) or (200 - quality * 2)

	local dqtY = ffi.new("uint8_t[64]")
	local dqtC = ffi.new("uint8_t[64]")
	local fdtblY = ffi.new("float[64]")
	local fdtblC = ffi.new("float[64]")
	local zz = ffi.new("int32_t[64]")

	for i = 0, 63 do
		zz[i] = ZIGZAG[i + 1]
		local qy = math.floor((BASE_QTY[i + 1] * scale + 50) / 100)
		local qc = math.floor((BASE_QTC[i + 1] * scale + 50) / 100)
		qy = math.max(1, math.min(255, qy))
		qc = math.max(1, math.min(255, qc))
		dqtY[zz[i]] = qy -- Wait: DQT marker stores in zigzag order!
		dqtC[zz[i]] = qc
	end
	-- Wait: BASE_QTY is ALREADY in raster 8x8 order; DQT segment expects zigzag order:
	-- zigzag[k] gives raster index for zigzag position k!
	for k = 0, 63 do
		local rasterIdx = zz[k]
		local qy = math.floor((BASE_QTY[rasterIdx + 1] * scale + 50) / 100)
		local qc = math.floor((BASE_QTC[rasterIdx + 1] * scale + 50) / 100)
		qy = math.max(1, math.min(255, qy))
		qc = math.max(1, math.min(255, qc))
		dqtY[k] = qy
		dqtC[k] = qc
		local row = math.floor(rasterIdx / 8) + 1
		local col = (rasterIdx % 8) + 1
		fdtblY[rasterIdx] = 1.0 / (qy * AAN_SCALES[row] * AAN_SCALES[col] * 8.0)
		fdtblC[rasterIdx] = 1.0 / (qc * AAN_SCALES[row] * AAN_SCALES[col] * 8.0)
	end

	local function buildHuff(bits, vals)
		local codeTab = ffi.new("uint16_t[256]")
		local lenTab  = ffi.new("uint8_t[256]")
		local code = 0
		local idx = 1
		for length = 1, 16 do
			local count = bits[length]
			for _ = 1, count do
				local sym = vals[idx]
				codeTab[sym] = code
				lenTab[sym] = length
				code = code + 1
				idx = idx + 1
			end
			code = lshift(code, 1)
		end
		return codeTab, lenTab
	end

	local dcYCode, dcYLen = buildHuff(BITS_DC_Y, VAL_DC_Y)
	local dcCCode, dcCLen = buildHuff(BITS_DC_C, VAL_DC_C)
	local acYCode, acYLen = buildHuff(BITS_AC_Y, VAL_AC_Y)
	local acCCode, acCLen = buildHuff(BITS_AC_C, VAL_AC_C)

	-- Magnitude category & bitcode lookup for [-2047..2047] (offset +2048)
	local catLen = ffi.new("uint8_t[4096]")
	local catCode = ffi.new("uint16_t[4096]")
	for v = -2047, 2047 do
		local av = v < 0 and -v or v
		local nbits = 0
		local tmp = av
		while tmp > 0 do
			nbits = nbits + 1
			tmp = rshift(tmp, 1)
		end
		catLen[v + 2048] = nbits
		catCode[v + 2048] = v >= 0 and v or (v + lshift(1, nbits) - 1)
	end

	return {
		dqtY = dqtY, dqtC = dqtC,
		fdtblY = fdtblY, fdtblC = fdtblC,
		zz = zz,
		dcYCode = dcYCode, dcYLen = dcYLen,
		dcCCode = dcCCode, dcCLen = dcCLen,
		acYCode = acYCode, acYLen = acYLen,
		acCCode = acCCode, acCLen = acCLen,
		catLen = catLen, catCode = catCode,
		block = ffi.new("float[64]"),
		du = ffi.new("int32_t[64]"),
		cbBlock = ffi.new("float[64]"),
		crBlock = ffi.new("float[64]"),
		outBuf = nil,
		outCap = 0
	}
end

local function writeHeaderMJPG(buf, width, height, st)
	local p = 0
	local function wb(b) buf[p] = b; p = p + 1 end
	local function ww(w) buf[p] = band(rshift(w, 8), 0xFF); buf[p + 1] = band(w, 0xFF); p = p + 2 end
	local function warr(t, n) for i = 1, n do wb(t[i]) end end

	-- SOI
	wb(0xFF); wb(0xD8)
	-- APP0 JFIF
	wb(0xFF); wb(0xE0); ww(16)
	wb(0x4A); wb(0x46); wb(0x49); wb(0x46); wb(0x00) -- "JFIF\0"
	wb(1); wb(1); wb(0); ww(1); ww(1); wb(0); wb(0)

	-- DQT (both tables in single segment: length = 2 + 65 + 65 = 132)
	wb(0xFF); wb(0xDB); ww(132)
	wb(0)
	for i = 0, 63 do wb(st.dqtY[i]) end
	wb(1)
	for i = 0, 63 do wb(st.dqtC[i]) end

	-- SOF0 (Baseline DCT, 4:2:0)
	wb(0xFF); wb(0xC0); ww(17)
	wb(8); ww(height); ww(width); wb(3)
	wb(1); wb(0x22); wb(0) -- Y:  2x2 sampling, DQT 0
	wb(2); wb(0x11); wb(1) -- Cb: 1x1 sampling, DQT 1
	wb(3); wb(0x11); wb(1) -- Cr: 1x1 sampling, DQT 1

	-- DHT (all 4 tables in single segment)
	local dhtLen = 2 + (1 + 16 + #VAL_DC_Y) + (1 + 16 + #VAL_AC_Y)
		+ (1 + 16 + #VAL_DC_C) + (1 + 16 + #VAL_AC_C)
	wb(0xFF); wb(0xC4); ww(dhtLen)
	wb(0x00); warr(BITS_DC_Y, 16); warr(VAL_DC_Y, #VAL_DC_Y)
	wb(0x10); warr(BITS_AC_Y, 16); warr(VAL_AC_Y, #VAL_AC_Y)
	wb(0x01); warr(BITS_DC_C, 16); warr(VAL_DC_C, #VAL_DC_C)
	wb(0x11); warr(BITS_AC_C, 16); warr(VAL_AC_C, #VAL_AC_C)

	-- SOS
	wb(0xFF); wb(0xDA); ww(12)
	wb(3)
	wb(1); wb(0x00)
	wb(2); wb(0x11)
	wb(3); wb(0x11)
	wb(0); wb(63); wb(0)

	return p
end

local function fdctAndQuant(data, fdtbl, zz, du)
	-- Rows
	for i = 0, 56, 8 do
		local d0, d1, d2, d3 = data[i], data[i + 1], data[i + 2], data[i + 3]
		local d4, d5, d6, d7 = data[i + 4], data[i + 5], data[i + 6], data[i + 7]
		local tmp0, tmp7 = d0 + d7, d0 - d7
		local tmp1, tmp6 = d1 + d6, d1 - d6
		local tmp2, tmp5 = d2 + d5, d2 - d5
		local tmp3, tmp4 = d3 + d4, d3 - d4

		local tmp10, tmp13 = tmp0 + tmp3, tmp0 - tmp3
		local tmp11, tmp12 = tmp1 + tmp2, tmp1 - tmp2

		data[i]     = tmp10 + tmp11
		data[i + 4] = tmp10 - tmp11

		local z1 = (tmp12 + tmp13) * 0.707106781
		data[i + 2] = tmp13 + z1
		data[i + 6] = tmp13 - z1

		tmp10 = tmp4 + tmp5
		tmp11 = tmp5 + tmp6
		tmp12 = tmp6 + tmp7

		local z5 = (tmp10 - tmp12) * 0.382683433
		local z2 = 0.541196100 * tmp10 + z5
		local z4 = 1.306562965 * tmp12 + z5
		local z3 = tmp11 * 0.707106781

		local z11, z13 = tmp7 + z3, tmp7 - z3
		data[i + 5] = z13 + z2
		data[i + 3] = z13 - z2
		data[i + 1] = z11 + z4
		data[i + 7] = z11 - z4
	end

	-- Columns
	for i = 0, 7 do
		local d0, d1, d2, d3 = data[i], data[i + 8], data[i + 16], data[i + 24]
		local d4, d5, d6, d7 = data[i + 32], data[i + 40], data[i + 48], data[i + 56]
		local tmp0, tmp7 = d0 + d7, d0 - d7
		local tmp1, tmp6 = d1 + d6, d1 - d6
		local tmp2, tmp5 = d2 + d5, d2 - d5
		local tmp3, tmp4 = d3 + d4, d3 - d4

		local tmp10, tmp13 = tmp0 + tmp3, tmp0 - tmp3
		local tmp11, tmp12 = tmp1 + tmp2, tmp1 - tmp2

		data[i]      = tmp10 + tmp11
		data[i + 32] = tmp10 - tmp11

		local z1 = (tmp12 + tmp13) * 0.707106781
		data[i + 16] = tmp13 + z1
		data[i + 48] = tmp13 - z1

		tmp10 = tmp4 + tmp5
		tmp11 = tmp5 + tmp6
		tmp12 = tmp6 + tmp7

		local z5 = (tmp10 - tmp12) * 0.382683433
		local z2 = 0.541196100 * tmp10 + z5
		local z4 = 1.306562965 * tmp12 + z5
		local z3 = tmp11 * 0.707106781

		local z11, z13 = tmp7 + z3, tmp7 - z3
		data[i + 40] = z13 + z2
		data[i + 24] = z13 - z2
		data[i + 8]  = z11 + z4
		data[i + 56] = z11 - z4
	end

	for k = 0, 63 do
		local rIdx = zz[k]
		local v = data[rIdx] * fdtbl[rIdx]
		du[k] = v >= 0 and math.floor(v + 0.5) or -math.floor(-v + 0.5)
	end
end

local function encodeFrameMJPG(st, rgbaPtr, width, height)
	local needed = width * height * 2 + 4096
	if st.outCap < needed then
		st.outBuf = ffi.new("uint8_t[?]", needed)
		st.outCap = needed
	end
	local out = st.outBuf
	local pos = writeHeaderMJPG(out, width, height, st)

	local bitBuf = 0
	local bitCnt = 0

	local function putBits(code, len)
		bitBuf = bor(lshift(bitBuf, len), code)
		bitCnt = bitCnt + len
		while bitCnt >= 8 do
			bitCnt = bitCnt - 8
			local b = band(rshift(bitBuf, bitCnt), 0xFF)
			out[pos] = b
			pos = pos + 1
			if b == 0xFF then
				out[pos] = 0x00
				pos = pos + 1
			end
		end
		bitBuf = band(bitBuf, lshift(1, bitCnt) - 1)
	end

	local catLen, catCode = st.catLen, st.catCode
	local zz, du = st.zz, st.du

	local function encodeDU(block, fdtbl, prevDC, dcCode, dcLen, acCode, acLen)
		fdctAndQuant(block, fdtbl, zz, du)
		local dc = du[0]
		local diff = dc - prevDC
		if diff == 0 then
			putBits(dcCode[0], dcLen[0])
		else
			if diff < -2047 then diff = -2047 elseif diff > 2047 then diff = 2047 end
			local idx = diff + 2048
			local nbits = catLen[idx]
			putBits(dcCode[nbits], dcLen[nbits])
			putBits(catCode[idx], nbits)
		end

		local end0 = 63
		while end0 > 0 and du[end0] == 0 do
			end0 = end0 - 1
		end
		if end0 == 0 then
			putBits(acCode[0x00], acLen[0x00])
			return dc
		end

		local i = 1
		while i <= end0 do
			local startPos = i
			while du[i] == 0 and i <= end0 do
				i = i + 1
			end
			local nrZeroes = i - startPos
			while nrZeroes >= 16 do
				putBits(acCode[0xF0], acLen[0xF0])
				nrZeroes = nrZeroes - 16
			end
			local ac = du[i]
			if ac < -1023 then ac = -1023 elseif ac > 1023 then ac = 1023 end
			local idx = ac + 2048
			local nbits = catLen[idx]
			local sym = bor(lshift(nrZeroes, 4), nbits)
			putBits(acCode[sym], acLen[sym])
			putBits(catCode[idx], nbits)
			i = i + 1
		end
		if end0 ~= 63 then
			putBits(acCode[0x00], acLen[0x00])
		end
		return dc
	end

	local yBlock, cbBlock, crBlock = st.block, st.cbBlock, st.crBlock
	local fdtblY, fdtblC = st.fdtblY, st.fdtblC
	local dcYCode, dcYLen = st.dcYCode, st.dcYLen
	local acYCode, acYLen = st.acYCode, st.acYLen
	local dcCCode, dcCLen = st.dcCCode, st.dcCLen
	local acCCode, acCLen = st.acCCode, st.acCLen

	local dcY, dcCb, dcCr = 0, 0, 0
	local maxX, maxY = width - 1, height - 1
	local stride = width * 4

	for mcuY = 0, maxY, 16 do
		for mcuX = 0, maxX, 16 do
			-- 4 Y blocks (TL, TR, BL, BR) + accumulate 2x2 subsampled Cb/Cr
			for by = 0, 1 do
				local baseY = mcuY + by * 8
				local cRowBase = by * 32
				for bx = 0, 1 do
					local baseX = mcuX + bx * 8
					local cColBase = cRowBase + bx * 4

					for py = 0, 7, 2 do
						local y0 = baseY + py
						local y1 = y0 + 1
						if y0 > maxY then y0 = maxY end
						if y1 > maxY then y1 = maxY end
						local row0 = y0 * stride
						local row1 = y1 * stride
						local bRow0 = py * 8
						local bRow1 = bRow0 + 8
						local cIdx = cColBase + rshift(py, 1) * 8

						for px = 0, 7, 2 do
							local x0 = baseX + px
							local x1 = x0 + 1
							if x0 > maxX then x0 = maxX end
							if x1 > maxX then x1 = maxX end

							local o00 = row0 + x0 * 4
							local o01 = row0 + x1 * 4
							local o10 = row1 + x0 * 4
							local o11 = row1 + x1 * 4

							local r00, g00, b00 = rgbaPtr[o00], rgbaPtr[o00 + 1], rgbaPtr[o00 + 2]
							local r01, g01, b01 = rgbaPtr[o01], rgbaPtr[o01 + 1], rgbaPtr[o01 + 2]
							local r10, g10, b10 = rgbaPtr[o10], rgbaPtr[o10 + 1], rgbaPtr[o10 + 2]
							local r11, g11, b11 = rgbaPtr[o11], rgbaPtr[o11 + 1], rgbaPtr[o11 + 2]

							yBlock[bRow0 + px]     = 0.299 * r00 + 0.587 * g00 + 0.114 * b00 - 128.0
							yBlock[bRow0 + px + 1] = 0.299 * r01 + 0.587 * g01 + 0.114 * b01 - 128.0
							yBlock[bRow1 + px]     = 0.299 * r10 + 0.587 * g10 + 0.114 * b10 - 128.0
							yBlock[bRow1 + px + 1] = 0.299 * r11 + 0.587 * g11 + 0.114 * b11 - 128.0

							local rAvg = (r00 + r01 + r10 + r11) * 0.25
							local gAvg = (g00 + g01 + g10 + g11) * 0.25
							local bAvg = (b00 + b01 + b10 + b11) * 0.25
							local ci = cIdx + rshift(px, 1)
							cbBlock[ci] = -0.168736 * rAvg - 0.331264 * gAvg + 0.5 * bAvg
							crBlock[ci] =  0.5 * rAvg - 0.418688 * gAvg - 0.081312 * bAvg
						end
					end

					dcY = encodeDU(yBlock, fdtblY, dcY, dcYCode, dcYLen, acYCode, acYLen)
				end
			end

			dcCb = encodeDU(cbBlock, fdtblC, dcCb, dcCCode, dcCLen, acCCode, acCLen)
			dcCr = encodeDU(crBlock, fdtblC, dcCr, dcCCode, dcCLen, acCCode, acCLen)
		end
	end

	-- Pad remaining bits with 1s before EOI
	if bitCnt > 0 then
		local padLen = 8 - bitCnt
		putBits(lshift(1, padLen) - 1, padLen)
	end

	out[pos] = 0xFF
	out[pos + 1] = 0xD9
	pos = pos + 2

	return ffi.string(out, pos)
end

-- Little-endian binary helpers for RIFF AVI container
local function u16(v)
	v = math.floor(v or 0) % 65536
	return string.char(v % 256, math.floor(v / 256) % 256)
end

local function u32(v)
	v = math.floor(v or 0)
	if v < 0 then v = v + 4294967296 end
	local b0 = v % 256; v = math.floor(v / 256)
	local b1 = v % 256; v = math.floor(v / 256)
	local b2 = v % 256; v = math.floor(v / 256)
	local b3 = v % 256
	return string.char(b0, b1, b2, b3)
end

local function buildAviHeader(width, height, fps, totalFrames, maxBytes, moviPayloadSize, fourcc)
	local microSecPerFrame = math.floor(1000000 / math.max(1, fps) + 0.5)
	local suggestedBuf = math.max(maxBytes or 0, width * height)

	local avihPayload = table.concat({
		u32(microSecPerFrame),      -- dwMicroSecPerFrame
		u32(suggestedBuf * fps),    -- dwMaxBytesPerSec
		u32(0),                     -- dwPaddingGranularity
		u32(0x10 + 0x100),          -- dwFlags: AVIF_HASINDEX | AVIF_ISINTERLEAVED
		u32(totalFrames),           -- dwTotalFrames
		u32(0),                     -- dwInitialFrames
		u32(1),                     -- dwStreams
		u32(suggestedBuf),          -- dwSuggestedBufferSize
		u32(width),                 -- dwWidth
		u32(height),                -- dwHeight
		u32(0), u32(0), u32(0), u32(0)
	})
	local avihChunk = "avih" .. u32(#avihPayload) .. avihPayload

	local strhPayload = table.concat({
		"vids",                     -- fccType
		fourcc,                     -- fccHandler ("MJPG" or "MPNG")
		u32(0),                     -- dwFlags
		u16(0), u16(0),             -- wPriority, wLanguage
		u32(0),                     -- dwInitialFrames
		u32(1),                     -- dwScale
		u32(fps),                   -- dwRate
		u32(0),                     -- dwStart
		u32(totalFrames),           -- dwLength
		u32(suggestedBuf),          -- dwSuggestedBufferSize
		u32(8500),                  -- dwQuality
		u32(0),                     -- dwSampleSize
		u16(0), u16(0), u16(width), u16(height) -- rcFrame
	})
	local strhChunk = "strh" .. u32(#strhPayload) .. strhPayload

	-- BITMAPINFOHEADER (40 bytes)
	local strfPayload = table.concat({
		u32(40),                    -- biSize
		u32(width),                 -- biWidth
		u32(height),                -- biHeight
		u16(1),                     -- biPlanes
		u16(24),                    -- biBitCount
		fourcc,                     -- biCompression
		u32(width * height * 3),    -- biSizeImage
		u32(0), u32(0), u32(0), u32(0)
	})
	local strfChunk = "strf" .. u32(#strfPayload) .. strfPayload

	local strlBody = "strl" .. strhChunk .. strfChunk
	local strlList = "LIST" .. u32(#strlBody) .. strlBody

	local hdrlBody = "hdrl" .. avihChunk .. strlList
	local hdrlList = "LIST" .. u32(#hdrlBody) .. hdrlBody

	local moviHeader = "LIST" .. u32(4 + moviPayloadSize) .. "movi"
	return hdrlList .. moviHeader
end

local session = nil

local function closeSession(aborted)
	if not session then return end
	local s = session
	session = nil

	local ok, err = pcall(function()
		-- Write idx1 chunk at end of movi
		s.file:write("idx1", u32(#s.idxEntries * 16))
		if #s.idxEntries > 0 then
			s.file:write(table.concat(s.idxEntries))
		end
		local fileSize = s.file:seek()
		local riffBodySize = math.max(0, fileSize - 8)

		-- Rewrite RIFF size & finalized hdrl/movi header at offset 0
		s.file:seek("set", 0)
		local hdr = buildAviHeader(
			s.width, s.height, s.fps, s.totalFrames, s.maxChunkSize, s.moviBytes, s.fourcc
		)
		s.file:write("RIFF", u32(riffBodySize), "AVI ", hdr)
		s.file:flush()
		s.file:close()
	end)

	if not ok then
		pcall(function() s.file:close() end)
		statusChannel:push({type = "error", message = "Failed to finalize recording: " .. tostring(err)})
	else
		statusChannel:push({
			type = "saved",
			path = s.path,
			frames = s.totalFrames,
			aborted = aborted or false
		})
	end
end

local function writeChunk(payload)
	if not session then return end
	local chunkLen = #payload
	local pad = (chunkLen % 2 == 1) and "\0" or ""
	local offsetFromMovi = session.moviOffset -- offset relative to 'movi' tag (standard AVI idx1)

	session.file:write("00dc", u32(chunkLen), payload, pad)

	local flags = chunkLen > 0 and 0x10 or 0x00 -- AVIIF_KEYFRAME
	session.idxEntries[#session.idxEntries + 1] = "00dc" .. u32(flags) .. u32(offsetFromMovi) .. u32(chunkLen)

	local written = 8 + chunkLen + #pad
	session.moviBytes = session.moviBytes + written
	session.moviOffset = session.moviOffset + written
	session.totalFrames = session.totalFrames + 1
	if chunkLen > session.maxChunkSize then
		session.maxChunkSize = chunkLen
	end
end

while true do
	local msg = cmdChannel:demand()
	if type(msg) == "table" then
		if msg.cmd == "start" then
			if session then closeSession(true) end
			local f, openErr = io.open(msg.path, "w+b")
			if not f then
				statusChannel:push({type = "error", message = "Cannot open recording file: " .. tostring(openErr)})
			else
				local useMJPG = canMJPG and (msg.codec ~= "MPNG")
				if useMJPG and not mjpgState then
					mjpgState = initMJPG(msg.quality or 78)
				end
				local fourcc = (useMJPG and mjpgState) and "MJPG" or "MPNG"
				local placeholderHdr = buildAviHeader(msg.width, msg.height, msg.fps, 0, 0, 0, fourcc)
				f:write("RIFF", u32(0), "AVI ", placeholderHdr)
				session = {
					file = f,
					path = msg.path,
					width = msg.width,
					height = msg.height,
					fps = msg.fps,
					fourcc = fourcc,
					totalFrames = 0,
					maxChunkSize = 0,
					moviBytes = 0,
					moviOffset = 4, -- right after 'movi' 4-byte list type
					idxEntries = {}
				}
				statusChannel:push({type = "started", path = msg.path, codec = fourcc})
			end
		elseif msg.cmd == "frame" then
			local img = msg.image
			local repeatPrev = tonumber(msg.dropped) or 0
			if session and img then
				-- Emit 0-byte drop chunks first so audio/tempo duration stays locked to wall time
				for _ = 1, math.min(repeatPrev, 30) do
					if session.totalFrames > 0 then writeChunk("") end
				end

				local okEnc, payload = pcall(function()
					if session.fourcc == "MJPG" and mjpgState and img.getFFIPointer then
						local ptr = ffi.cast("uint8_t*", img:getFFIPointer())
						return encodeFrameMJPG(mjpgState, ptr, session.width, session.height)
					else
						local fd = img:encode("png")
						local s = fd:getString()
						if fd.release then fd:release() end
						return s
					end
				end)
				if okEnc and type(payload) == "string" then
					writeChunk(payload)
				end
			end
			if img and type(img) == "userdata" and img.release then
				pcall(function() img:release() end)
			end
		elseif msg.cmd == "stop" then
			closeSession(false)
		elseif msg.cmd == "quit" then
			closeSession(false)
			break
		end
	elseif msg == "quit" then
		closeSession(false)
		break
	end
end
