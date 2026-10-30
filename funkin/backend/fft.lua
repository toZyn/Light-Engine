local thread = [[
local inputChannel = love.thread.getChannel("fft_input")
local outputChannel = love.thread.getChannel("fft_output")

local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_sqrt = math.sqrt
local math_cos = math.cos
local math_sin = math.sin
local math_pi = math.pi
local math_log = math.log
local math_exp = math.exp
local math_log10 = math.log10
local table_insert = table.insert

local numBars = 7
local minDb = -65
local maxDb = -25
local minFreq = 60
local maxFreq = 22000
local sampleRate = 44100

local function simpleFFT(samples)
	local n = #samples
	if n <= 1 then return samples end

	local even, odd = {}, {}
	for i = 1, n, 2 do
		table_insert(even, samples[i])
		if samples[i+1] then
			table_insert(odd, samples[i+1])
		end
	end

	local evenFFT = simpleFFT(even)
	local oddFFT = simpleFFT(odd)
	local result = {}

	for i = 1, math_floor(n/2) do
		local t = oddFFT[i] or {0, 0}
		local angle = -2 * math_pi * (i-1) / n
		local tReal = t[1] * math_cos(angle) - t[2] * math_sin(angle)
		local tImag = t[1] * math_sin(angle) + t[2] * math_cos(angle)

		local e = evenFFT[i] or {0, 0}
		result[i] = {e[1] + tReal, e[2] + tImag}
		result[i + math_floor(n/2)] = {e[1] - tReal, e[2] - tImag}
	end

	return result
end

local function processAudioData(samples)
	local n = #samples
	local paddedSamples = {}

	local size = 1
	while size < n do size = size * 2 end

	for i = 1, size do
		paddedSamples[i] = {samples[i] or 0, 0}
	end

	local spectrum = simpleFFT(paddedSamples)
	local magnitudes = {}

	for i = 1, math_floor(size/2) do
		local real, imag = spectrum[i][1], spectrum[i][2]
		magnitudes[i] = math_sqrt(real*real + imag*imag) / size
	end

	local nyquist = sampleRate / 2
	local binSize = nyquist / #magnitudes
	local maxFreqClamped = math_min(nyquist, maxFreq)

	local logMinFreq = math_log(minFreq)
	local logMaxFreq = math_log(maxFreqClamped)

	local bars = {}

	for i = 1, numBars do
		local normalizedStart = (i - 1) / numBars
		local normalizedEnd = (i) / numBars

		local logFreqStart = logMinFreq + normalizedStart * (logMaxFreq - logMinFreq)
		local logFreqEnd = logMinFreq + normalizedEnd * (logMaxFreq - logMinFreq)

		local freqStart = math_exp(logFreqStart)
		local freqEnd = math_exp(logFreqEnd)

		local startBin = math_max(1, math_floor(freqStart / binSize) + 1)
		local endBin = math_min(#magnitudes, math_floor(freqEnd / binSize) + 1)

		if startBin > endBin then
			endBin = startBin
		end

		local sum = 0
		local count = 0
		for j = startBin, endBin do
			if magnitudes[j] then
				sum = sum + magnitudes[j]
				count = count + 1
			end
		end

		local amplitude = count > 0 and (sum / count) or 0

		if amplitude > 0 then
			local db = 20 * math_log10(amplitude)
			db = math_max(minDb, math_min(maxDb, db))
			local normalizedDb = math.pow((db - minDb) / (maxDb - minDb), 0.5)
			bars[i] = math_max(0, math_min(1, normalizedDb))
		else
			bars[i] = 0
		end
	end

	return bars
end

local sleep = require("love.timer").sleep

while true do
	local data = inputChannel:demand()

	if data.type == "quit" then
		break
	elseif data.type == "init" then
		numBars = data.numBars
		minDb = data.minDb
		maxDb = data.maxDb
		minFreq = data.minFreq
		maxFreq = data.maxFreq
		sampleRate = data.sampleRate
	elseif data.type == "process" then
		local bars = processAudioData(data.samples)
		outputChannel:push({
			type = "result",
			bars = bars
		})
	else
		sleep(0.001)
	end
end
]]

local fftThread = love.thread.newThread(thread)
local inputChannel = love.thread.getChannel("fft_input")
local outputChannel = love.thread.getChannel("fft_output")

local FFT = Classic:extend()

local function safeIsPlaying(src)
	if not src then return false, false end
	if type(src) == "table" then
		if src.exists == false or src.active == false then return true, false end
		if type(src.isPlaying) == "function" then
			local ok, playing = pcall(src.isPlaying, src)
			if ok then return true, playing == true end
			return false, false
		end
		src = rawget(src, "_source")
		if not src then return true, false end
	end
	local ok, playing = pcall(src.isPlaying, src)
	if not ok then return false, false end
	return true, playing == true
end

local function safeTell(src)
	if not src then return false, 0 end
	if type(src) == "table" then
		if type(src.get_time) == "function" then
			local ok, pos = pcall(src.get_time, src)
			if ok and type(pos) == "number" then return true, pos end
		end
		src = rawget(src, "_source")
		if not src then return true, 0 end
	end
	local ok, pos = pcall(src.tell, src)
	if not ok or type(pos) ~= "number" then return false, 0 end
	return true, pos
end

function FFT.stop()
	if fftThread and fftThread:isRunning() then
		inputChannel:push({type = "quit"})
		pcall(function() fftThread:wait() end)
	end
	while outputChannel:pop() do end
end

function FFT:new(numBars, audioFile, externalSource)
	self.numBars = numBars or 7
	self.bars = {}
	self.smoothBars = {}
	self.fftSize = 2048
	self.playbackPos = 0
	self.externalSource = externalSource
	self.smoothingFactor = 20

	self.minDb = -65
	self.maxDb = -25
	self.minFreq = 60
	self.maxFreq = 22000

	local path = paths.getPath(audioFile)
	local okSound, soundData = false, nil
	if path and paths.exists(path, "file") then
		okSound, soundData = pcall(love.sound.newSoundData, path)
	end
	self.audioData = okSound and soundData or nil

	for i = 1, self.numBars do
		self.bars[i] = 0
		self.smoothBars[i] = 0
	end

	self.processing = false
	if not self.audioData then return end

	if not fftThread:isRunning() then
		fftThread:start()
	end

	local okRate, rate = pcall(self.audioData.getSampleRate, self.audioData)
	local initData = {
		type = "init",
		numBars = self.numBars,
		minDb = self.minDb,
		maxDb = self.maxDb,
		minFreq = self.minFreq,
		maxFreq = self.maxFreq,
		sampleRate = (okRate and rate) or 44100
	}
	inputChannel:push(initData)
end

function FFT:update(dt)
	local validSrc, isPlaying = safeIsPlaying(self.externalSource)
	if not validSrc then
		self.externalSource = nil
		isPlaying = false
	end

	local result = outputChannel:pop()
	if result and result.type == "result" then
		self.bars = result.bars
		self.processing = false
	end

	if isPlaying then
		local okTell, pos = safeTell(self.externalSource)
		if not okTell then
			self.externalSource = nil
			self.playbackPos = 0
			self.processing = false
			return
		end
		self.playbackPos = pos

		local currentTime = love.timer.getTime()
		if not self.processing then
			self:requestFFTCalculation()
			self.lastRequestTime = currentTime
		end
	else
		for i = 1, self.numBars do
			self.bars[i] = 0
		end
		self.playbackPos = 0
		self.processing = false
	end
end

function FFT:requestFFTCalculation()
	if not self.audioData or self.processing then
		return
	end

	local okMeta, sampleRate, sampleCount, channels = pcall(function()
		return self.audioData:getSampleRate(),
			self.audioData:getSampleCount(),
			self.audioData:getChannelCount()
	end)
	if not okMeta or not sampleRate or not sampleCount then
		self.audioData = nil
		return
	end

	local sampleStart = math.floor(self.playbackPos * sampleRate)
	local samples = {}
	local isStereo = (channels or 1) >= 2

	local okSamples = pcall(function()
		for i = 0, self.fftSize - 1 do
			local sampleIndex = sampleStart + i
			if sampleIndex >= 0 and sampleIndex < sampleCount then
				if isStereo then
					local l = self.audioData:getSample(sampleIndex, 1) or 0
					local r = self.audioData:getSample(sampleIndex, 2) or 0
					samples[i + 1] = (l + r) * 0.5
				else
					samples[i + 1] = self.audioData:getSample(sampleIndex) or 0
				end
			else
				samples[i + 1] = 0
			end
		end
	end)
	if not okSamples then
		self.audioData = nil
		return
	end

	inputChannel:push({
		type = "process",
		samples = samples
	})
	self.processing = true
end

function FFT:destroy()
	self.externalSource = nil
	if self.audioData and self.audioData.release then
		pcall(self.audioData.release, self.audioData)
	end
	self.audioData = nil
	self.processing = false
end

function FFT:getBars()
	return self.bars
end

function FFT:getBar(index, raw)
	return self.bars[index] or 0
end

function FFT.close()
	inputChannel:push({type = "quit"})
	fftThread:wait()
	fftThread = nil
end

return FFT
