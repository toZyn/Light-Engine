local TimeIndex = require "funkin.backend.timeindex"

check("time index agrees with a full scan including crossing sustains and duplicate times", function()
	local notes = {}
	for i = 1, 1200 do notes[i] = {t = math.floor(i / 3) * 10, l = i % 17 == 0 and 3000 or 0} end
	local index = TimeIndex.new(notes)
	for first = -100, 5000, 137 do
		local expected, actual = {}, {}
		for i, n in ipairs(notes) do
			if n.t <= first + 70 and n.t + n.l >= first then expected[#expected + 1] = i end
		end
		for i in index:each(first, first + 70) do actual[#actual + 1] = i end
		assert(#expected == #actual)
		for i = 1, #expected do assert(expected[i] == actual[i]) end
	end
	assert(TimeIndex.lowerBound({}, 1) == 1)
	assert(TimeIndex.lowerBound(notes, 10) == 3)
	assert(TimeIndex.new({}):each(0, 100)() == nil)
	local sorted = TimeIndex.sort({{t = 4}, {t = 1}, {t = 2}})
	assert(sorted[1].t == 1 and sorted[3].t == 4)
	assert(TimeIndex.sort(sorted) == sorted)
end)

check("two million chart records retain exact seek and visible-range results", function()
	local count, notes = 2000000, {}
	local start = love.timer.getTime()
	for i = 1, count do notes[i] = {t = i * 10, d = i % 4, l = i == 1 and count * 10 or 0} end
	local built = love.timer.getTime()
	local index = TimeIndex.new(notes)
	local indexed = love.timer.getTime()
	local samples = {}
	for q = 1, 200 do
		local first = (q * 7919 % (count - 100)) * 10
		local before = love.timer.getTime()
		local seen = 0
		for _, n in index:each(first, first + 500) do
			assert(n.t <= first + 500 and n.t + n.l >= first)
			seen = seen + 1
		end
		assert(seen == 52)
		samples[q] = (love.timer.getTime() - before) * 1000
	end
	table.sort(samples)
	local scanStart = love.timer.getTime()
	local matched = 0
	for _, n in ipairs(notes) do
		if n.t <= 10000500 and n.t + n.l >= 10000000 then matched = matched + 1 end
	end
	local scanMs = (love.timer.getTime() - scanStart) * 1000
	assert(matched == 52)
	assert(TimeIndex.lowerBound(notes, 15000000) == 1500000)
	local field = Notefield(0, 0, 4, "default")
	field:makeNotesFromChart(notes)
	field:seekTo(15000)
	assert(field.chartIndex == 1500000 and #field.activeNotes == 0)
	field:update(1 / 60)
	assert(#field.activeNotes == 201 and field.chartIndex == 1500201)
	assert(#field.chartNotes == count)
	field:destroy()
	print(string.format("DENSE BENCH records=%d generate=%.2fms index=%.2fms query_p50=%.4fms query_p95=%.4fms scan=%.2fms lua_heap=%.2fMiB",
		count, (built - start) * 1000, (indexed - built) * 1000, samples[100], samples[190], scanMs, collectgarbage("count") / 1024))
end)

check("editor time index invalidates after sustain changes, undo and redo", function()
	PlayState.loadSong("bopeebo", "normal")
	local editor = ChartingState()
	game.switchState(editor, true)
	game.update(1 / 60)
	editor.song.notes.player = {{t = 0, d = 0, l = 0}, {t = 1000, d = 1, l = 0}}
	local list = editor.song.notes.player
	assert(editor:getTimeIndex(list):each(500, 600)() == nil)
	editor.selectedNote = list[1]
	editor:adjustSelectedSustain(8)
	assert(editor:getTimeIndex(list):each(500, 600)() == 1)
	editor:undo()
	assert(editor:getTimeIndex(editor.song.notes.player):each(500, 600)() == nil)
	editor:redo()
	assert(editor:getTimeIndex(editor.song.notes.player):each(500, 600)() == 1)
end)

check("consumed-note compaction preserves order and detaches lane membership", function()
	local field = Notefield(0, 0, 4, "default")
	local first = Note(-10, 0, 0, nil, field.skin)
	local second = Note(-9, 1, 0, nil, field.skin)
	local third = Note(1, 2, 0, nil, field.skin)
	first.tooLate, second.tooLate = true, true
	field:addNote(first); field:addNote(second); field:addNote(third)
	field.lastSustain = first
	field:update(1 / 60)
	assert(#field.activeNotes == 1 and field.activeNotes[1] == third)
	assert(field.lastSustain == nil)
	first:destroy(); second:destroy(); field:destroy()
end)
