local pressCount = 0

local function triggerPulse()
	pressCount = pressCount + 1
	Mod.zoom(0.02, 0.035)
	local counter = Mod.get("pulse_counter")
	if counter then
		counter.content = "Pulses: " .. tostring(pressCount)
		counter.alpha = 1
		Mod.tween("pulse_counter", {alpha = 0.75}, 0.25, "quadOut")
	end
end

function postCreate()
	pressCount = 0
	Mod.button("pulse_btn", 20, 92, 168, 36, "Camera Bop [B]", function()
		triggerPulse()
	end, {
		key = "b",
		camera = "hud",
		size = 16
	})

	Mod.text("pulse_counter", "Pulses: 0", 20, 134, {
		size = 16,
		color = "#38BDF8",
		camera = "hud",
		alpha = 0.75,
		scroll = 0
	})
end

function beat(curBeat)
	if curBeat % 4 == 0 and Mod.loadData("bonusBop", false) then
		Mod.zoom(0.01, 0.02)
	end
end

function leave()
	Mod.remove("pulse_btn")
	Mod.remove("pulse_counter")
end
