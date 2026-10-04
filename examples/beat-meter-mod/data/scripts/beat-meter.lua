local Beat, importError = tryRequireAddon('tempo-tools-addon', 'beat')
if importError then return end

local label, detach

function postCreate()
	if not state.conductor then return end
	label = Text(24, 24, 'Beat meter')
	if state.camHUD then label.cameras = {state.camHUD} end
	label.scrollFactor:set(0, 0)
	state:add(label)
	detach = Beat.subscribe(state.conductor, function() label.alpha = 1 end)
end

function update()
	if not label then return end
	local phase, beat = Beat.phase(state.conductor, state.conductor.time)
	label.content = ('Beat %d | %.0f BPM'):format(beat + 1, state.conductor.bpm)
	label.alpha = 1 - phase * 0.4
end

function leave()
	if detach then detach(); detach = nil end
	if label then state:remove(label); label:destroy(); label = nil end
end
