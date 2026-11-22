check("high speed constructs only the visible and hittable horizon", function()
	local field = Notefield(0, 0, 4, "default", nil, nil, 640)
	local notes = {}
	for i = 1, 100000 do notes[i] = {t = i, d = i % 4, l = 0} end
	field:makeNotesFromChart(notes)
	local before = love.timer.getTime()
	field:update(1 / 60)
	assert(#field.activeNotes >= 166 and #field.activeNotes < 400)
	assert(field.chartIndex == #field.activeNotes + 1 and #field.chartNotes == 100000)
	print(string.format("GAMEPLAY WINDOW chart=%d sprites=%d horizon=%.4fs update=%.3fms", #notes, #field.activeNotes, field.spawnBuffer, (love.timer.getTime() - before) * 1000))
	field:destroy()
end)

check("spawn horizon covers slow reverse and stationary lanes", function()
	local field = Notefield(0, 0, 4, "default", nil, nil, 10)
	local notes = {}
	for i = 1, 100 do notes[i] = {t = i * 1000, d = i % 4, l = 0} end
	field:makeNotesFromChart(notes)
	field.lanes[1].speed = 0.01
	field.lanes[1].drawSize = 2
	field.lanes[1].drawSizeOffset = 300
	field:update(0)
	local lane = field.lanes[1]
	local expected = (field.drawSize - lane.receptor.y + 300) / 45
	assert(field.spawnBuffer >= expected)
	field.lanes[2].speed = -0.01
	field.lanes[2].drawSizeOffset = -3000
	field:update(0)
	assert(field.spawnBuffer > 50)
	field.lanes[3].speed = 0
	field:update(0)
	assert(#field.activeNotes == #notes and field.chartIndex == #notes + 1)
	field:destroy()
end)

check("dense hits compact once and retain every remaining note in order", function()
	local field = Notefield(0, 0, 4, "default")
	local notes = {}
	for i = 1, 12000 do
		local note = Note(0, i % 4, 0, nil, field.skin)
		field:addNote(note)
		notes[i] = note
	end
	for i, lane in ipairs(field.lanes) do field:__prepareLane(i - 1, lane, 0) end
	local before = love.timer.getTime()
	local hitNotes = field:getNotes(0)
	assert(#hitNotes == #notes)
	for i = 1, #notes, 2 do
		assert(field:removeNote(notes[i]) == notes[i])
		notes[i]:destroy()
	end
	assert(#field:getNotes(0) == 6000)
	field:update(0)
	assert(#field.activeNotes == 6000)
	for i, note in ipairs(field.activeNotes) do assert(note == notes[i * 2]) end
	for _, lane in ipairs(field.lanes) do
		for _, note in ipairs(lane.renderedNotes) do assert(not field.removedNotes[note] and note.group == lane) end
	end
	print(string.format("GAMEPLAY HITS input=%d remaining=%d query_remove_compact=%.3fms", #notes, #field.activeNotes, (love.timer.getTime() - before) * 1000))
	field:destroy()
end)

check("slow and stationary consumed notes remain visible until passed", function()
	local field = Notefield(0, 0, 4, "default", nil, nil, 640)
	field.lanes[1].speed = 0.0001
	field.lanes[2].speed = 0
	local slow = field:addNote(Note(-1, 0, 0, nil, field.skin))
	local still = field:addNote(Note(-100, 1, 0, nil, field.skin))
	slow.wasGoodHit, still.wasGoodHit = true, true
	field:update(0)
	assert(#field.activeNotes == 2)
	field:destroy()
end)

check("dense chart update hit and render frames preserve every playable note", function()
	local field = Notefield(game.width / 2, game.height / 2, 4, "default", nil, nil, 640)
	local notes, samples, hitCount = {}, {}, 0
	for i = 1, 20000 do notes[i] = {t = i / 2, d = i % 4, l = i % 37 == 0 and 200 or 0} end
	field:makeNotesFromChart(notes)
	local camera = Camera()
	local canvas = love.graphics.newCanvas(game.width, game.height)
	for frame = 1, 60 do
		local before = love.timer.getTime()
		field.time = frame / 60
		field:update(1 / 60)
		local hits = field:getNotes(field.time)
		for _, note in ipairs(hits) do
			if note.time <= field.time then
				hitCount = hitCount + 1
				field:removeNote(note)
				note:destroy()
			end
		end
		love.graphics.push("all")
		love.graphics.setCanvas(canvas)
		love.graphics.clear()
		field:__render(camera)
		love.graphics.pop()
		samples[frame] = (love.timer.getTime() - before) * 1000
	end
	assert(hitCount == 2000)
	assert(field.chartIndex > hitCount and field.chartIndex < 3000)
	assert(#field.chartNotes == 20000)
	table.sort(samples)
	print(string.format("GAMEPLAY FRAMES chart=%d hit=%d spawned=%d frame_p50=%.3fms frame_p95=%.3fms", #notes, hitCount, field.chartIndex - 1, samples[30], samples[57]))
	field:destroy()
	camera:destroy()
	canvas:release()
end)

check("dense render departures compact lane arrays without per-note shifts", function()
 local field=Notefield(0,0,4,"default")
 local notes={}
 for i=1,12000 do notes[i]=field:addNote(Note(0,i%4,0,nil,field.skin)) end
 for i,lane in ipairs(field.lanes) do
  field:__prepareLane(i-1,lane,0)
  lane.drawSize,lane.drawSizeOffset=lane._drawSize,lane._drawSizeOffset
 end
 local calls=0
 for _,lane in ipairs(field.lanes) do
  local remove=lane.remove
  lane.remove=function(self,note) calls=calls+1;return remove(self,note) end
 end
 local before=love.timer.getTime()
 for i,lane in ipairs(field.lanes) do field:__prepareLane(i-1,lane,100) end
 for _,lane in ipairs(field.lanes) do
  assert(#lane.renderedNotes==0)
  assert(#lane.members==1 and lane.members[1]==lane.receptor)
 end
 print(string.format("DEPARTURE COST notes=%d removals=%d elapsed=%.3fms",#notes,calls,(love.timer.getTime()-before)*1000))
 assert(calls==0,"render departures shift lane members once per note")
 assert(#field.activeNotes==#notes,"leaving the viewport discarded playable notes")
 print(string.format("RENDER DEPARTURES notes=%d elapsed=%.3fms",#notes,(love.timer.getTime()-before)*1000))
 field:destroy()
end)

check("dense automatic hits retain overdue and interleaved notes", function()
	local field = Notefield(0, 0, 4, "default")
	local overdue = field:addNote(Note(0, 0, 0, nil, field.skin))
	local alreadyHit = field:addNote(Note(0.96, 1, 0, nil, field.skin))
	alreadyHit.wasGoodHit = true
	local current = field:addNote(Note(0.99, 2, 0, nil, field.skin))
	local notes = field:getNotes(1, nil, true)
	assert(#notes == 2 and notes[1] == overdue and notes[2] == current)
	field:destroy()
end)

check("new notes enter the camera queue on the same frame", function()
	local field = Notefield(game.width / 2, game.height / 2, 4, "default")
	local camera = Camera()
	local note = field:addNote(Note(0, 0, 0, nil, field.skin))
	field:_prepareCameraDraw(camera, true)
	local queue = field.lanes[1].__cameraRenderQueue[camera]
	assert(queue and table.find(queue, note))
	field:destroy()
	camera:destroy()
end)

check("visible notes update once per frame", function()
	local field = Notefield(0, 0, 4, "default")
	local note = field:addNote(Note(0, 0, 0, nil, field.skin))
	local updates = 0
	note.update = function() updates = updates + 1 end
	field:__prepareLane(0, field.lanes[1], 0)
	field:update(1 / 60)
	assert(updates == 1, "visible note updated " .. updates .. " times")
	field:destroy()
end)

check("long sustains submit one body strip per note", function()
	local field = Notefield(game.width / 2, game.height / 2, 4, "default")
	local camera = Camera()
	local canvas = love.graphics.newCanvas(game.width, game.height)
	for index = 1, 48 do
		field:addNote(Note(0.01 * index, index % 4, 20, nil, field.skin))
	end
	field.time = 0.5
	love.graphics.push("all")
	love.graphics.setCanvas(canvas)
	field:__render(camera)
	local before = love.graphics.getStats().drawcalls
	local start = love.timer.getTime()
	for _ = 1, 20 do
		field:__render(camera)
		love.graphics.flushBatch()
	end
	local elapsed = (love.timer.getTime() - start) * 1000
	local draws = love.graphics.getStats().drawcalls - before
	love.graphics.pop()
	print(("LONG HOLDS 48 x 20 draws=%d elapsed=%.2fms"):format(draws, elapsed))
	field:destroy()
	camera:destroy()
	canvas:release()
	assert(draws <= 20 * (48 * 2 + 4), "hold bodies submit multiple mesh draws")
end)
