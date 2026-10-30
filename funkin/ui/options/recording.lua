local Settings = require "funkin.ui.options.settings"

local captureModes = {"gameplay", "entire"}
local captureLabels = {
	gameplay = "Gameplay only (No UI)",
	entire = "Entire game"
}

local scales = {0.5, 0.75, 1.0}
local scaleLabels = {
	[0.5] = "50% (Low resource)",
	[0.75] = "75% (Balanced)",
	[1.0] = "100% (Native)"
}

local fpsValues = {24, 30, 60}

local function nearestIndex(list, val)
	local bestIdx, bestDist = 1, math.huge
	for i, item in ipairs(list) do
		local d = math.abs(item - (tonumber(val) or list[1]))
		if d < bestDist then
			bestIdx, bestDist = i, d
		end
	end
	return bestIdx
end

local data = {
	{"CAPTURE"},
	{"recordingMode", "Capture mode", "string", captureModes, function(value)
		return captureLabels[value] or "Gameplay only (No UI)"
	end},
	{"recordingAutoGameplay", "Auto-record gameplay", "boolean"},

	{"PERFORMANCE"},
	{"recordingScale", "Resolution scale", "number", function(add)
		local idx = nearestIndex(scales, ClientPrefs.data.recordingScale)
		local nextIdx = math.clamp(idx + add, 1, #scales)
		ClientPrefs.data.recordingScale = scales[nextIdx]
	end, function(value)
		local idx = nearestIndex(scales, value)
		return scaleLabels[scales[idx]]
	end},
	{"recordingFps", "Frame rate", "number", function(add)
		local idx = nearestIndex(fpsValues, ClientPrefs.data.recordingFps)
		local nextIdx = math.clamp(idx + add, 1, #fpsValues)
		ClientPrefs.data.recordingFps = fpsValues[nextIdx]
	end, function(value)
		local idx = nearestIndex(fpsValues, value)
		return tostring(fpsValues[idx]) .. " FPS"
	end},
	{"recordingIndicator", "Show REC indicator", "boolean"},

	{"SESSION"},
	{"recordingToggleNow", "Start / Stop recording now (F9)", function(optionsUI)
		if optionsUI then optionsUI.changingOption = false end
		if Recorder then
			Recorder.toggle()
		end
	end}
}

local Recording = Settings:base("Recording", data)
return Recording
