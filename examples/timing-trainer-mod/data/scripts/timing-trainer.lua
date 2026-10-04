local Statistics, importError = tryRequireAddon('judgement-tools-addon', 'statistics')
if importError then return end

local samples, label, misses = Statistics.new(), nil, 0
local function refresh()
	if not label then return end
	local stats = samples:snapshot()
	label.content = ('%d hits | %d misses | mean %+.1f ms | spread %.1f ms'):format(
		stats.count, misses, stats.mean, stats.meanAbsolute)
end

function postCreate()
	label = Text(24, 52, 'Timing trainer')
	if state.camHUD then label.cameras = {state.camHUD} end
	label.scrollFactor:set(0, 0)
	state:add(label)
	refresh()
end

function goodNoteHit(note)
	if note.parent ~= state.playerNotefield or note.sustain then return end
	samples:add((state.playerNotefield.time - note.time) * 1000)
	refresh()
end

function noteMiss(note)
	if note.parent ~= state.playerNotefield then return end
	misses = misses + 1
	refresh()
end

function leave()
	if label then state:remove(label); label:destroy(); label = nil end
end
