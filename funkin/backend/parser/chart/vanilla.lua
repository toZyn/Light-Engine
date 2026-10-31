local vanilla = {name = "Vanilla/Psych"}

local function getFromMeta(data, tbl)
	Parser.pset(tbl, "song", data.songName or data.song or data.name)
	Parser.pset(tbl, "stage", data.stage)
	local metaSkin = type(data.skin) == "table" and (data.skin.skin or data.skin.name) or data.skin
	Parser.pset(tbl, "skin", metaSkin)

	Parser.pset(tbl, "difficulties", data.difficulties)

	local char = data.characters or data
	Parser.pset(tbl, "player1", char.player)
	Parser.pset(tbl, "player2", char.opponent)
	Parser.pset(tbl, "gfVersion", char.girlfriend)
end

local function appendPsychEvents(rawEvents, events, seen)
	if type(rawEvents) ~= "table" then return end
	local list = rawEvents
	if #list == 0 then
		if type(list.song) == "table" and type(list.song.events) == "table" then
			list = list.song.events
		elseif type(list.events) == "table" then
			list = list.events
		end
	end
	if type(list) ~= "table" then return end

	for _, e in ipairs(list) do
		if type(e) == "table" then
			local etime = tonumber(e[1]) or 0
			if type(e[2]) == "table" then
				for _, i in ipairs(e[2]) do
					if type(i) == "table" and i[1] ~= nil then
						local eevent = tostring(i[1])
						local v1, v2 = i[2], i[3]
						local sig = string.format("%.4f|%s|%s|%s", etime, eevent, tostring(v1 or ""), tostring(v2 or ""))
						if not seen[sig] then
							seen[sig] = true
							table.insert(events, {
								t = etime,
								e = eevent,
								v = {v1, v2},
								psych = true
							})
						end
					end
				end
			elseif type(e[2]) == "string" then
				local eevent = e[2]
				local v1, v2 = e[3], e[4]
				local sig = string.format("%.4f|%s|%s|%s", etime, eevent, tostring(v1 or ""), tostring(v2 or ""))
				if not seen[sig] then
					seen[sig] = true
					table.insert(events, {
						t = etime,
						e = eevent,
						v = {v1, v2},
						psych = true
					})
				end
			end
		end
	end
end

local function getStuff(data, eventData, inlineEvents, bpm, psych)
	local dad, bf, events, timeChanges, sectionChanges =
		{}, {}, {}, {}, {}

	local time, steps, total, add, focus, lastFocus = 0, 0, 0
	table.insert(timeChanges, Parser.newTimeChange(0, bpm))
	timeChanges[1].stepCrotchet, timeChanges[1].id =
		((60 / bpm) * 1000) / 4, 0
	local lastSectionBeats = 0

	local seenEvents = {}
	appendPsychEvents(eventData, events, seenEvents)
	if inlineEvents and inlineEvents ~= eventData then
		appendPsychEvents(inlineEvents, events, seenEvents)
	end

	for i, s in ipairs(data) do
		if s.sectionNotes then
			for _, n in ipairs(s.sectionNotes) do
				local kind = n[4]
				local column, gf = n[2], kind == "gf" or kind == "GF Sing"
				local hit = psych or s.mustHitSection
				if column > 3 then hit = not hit end
				if kind == true or kind == 1 or kind == "Alt Animation" or (not hit and s.altAnim) then
					kind = "alt"
				elseif gf or type(kind) ~= "string" then
					kind = nil
				end

				local newNote = {
					t = n[1],
					d = column % 4,
					l = n[3],
					k = kind,
					gf = gf or s.gfSection
				}
				table.insert(hit and bf or dad, newNote)
			end

			focus = s.gfSection and 2 or (s.mustHitSection and 0 or 1)
			if focus ~= lastFocus then
				table.insert(events, {
					t = time,
					e = "FocusCamera",
					v = focus
				})
				lastFocus = focus
			end
			if s.changeBPM and s.bpm ~= nil and s.bpm ~= bpm then
				bpm, total = s.bpm, total + 1

				local timeChange = Parser.newTimeChange(time or 0, bpm)
				timeChange.step = steps
				timeChange.stepCrotchet = ((60 / bpm) * 1000) / 4
				timeChange.id = total

				if #sectionChanges > 0 then
					timeChange.n, timeChange.d =
						sectionChanges[#sectionChanges].n, sectionChanges[#sectionChanges].d
				end

				table.insert(timeChanges, timeChange)
			end

			add = s.sectionBeats and s.sectionBeats * 4 or 16
			steps = steps + add
			local stepCrotchet = timeChanges[#timeChanges].stepCrotchet
			time = time + stepCrotchet * add
		end
	end

	if #timeChanges > 1 then table.sort(timeChanges, Parser.sortByTime) end

	return {enemy = dad, player = bf}, events, timeChanges
end

function vanilla.parse(data, events, meta, diff)
	if type(data) ~= "table" then
		error("chart root must be a JSON object", 0)
	end
	local baseData = data.song
	if baseData ~= nil and type(baseData) ~= "table" and type(baseData) ~= "string" then
		error("field 'song' must be a table or string", 0)
	end
	data = table.clone(type(baseData) == "table" and baseData or data)

	local diffKey = type(diff) == "string" and diff:lower() or "normal"
	if type(data.speed) == "table" then
		data.speed = tonumber(data.speed[diffKey] or data.speed.normal or data.speed.default) or 1
	elseif data.speed ~= nil then
		data.speed = tonumber(data.speed) or 1
	end
	if data.stage == nil and type(data.stageDefault) == "string" then
		data.stage = data.stageDefault
	end

	local chart = Parser.getDummyChart()

	Parser.pset(chart, "song", data.song)

	if meta then getFromMeta(meta, chart) end

	Parser.pset(chart, "bpm", data.bpm)
	Parser.pset(chart, "speed", data.speed)

	local rawSkin = type(data.skin) == "table" and (data.skin.skin or data.skin.name) or data.skin
	Parser.pset(chart, "stage", data.stage)
	Parser.pset(chart, "skin", rawSkin)

	Parser.pset(chart, "player1", data.player1)
	Parser.pset(chart, "player2", data.player2)
	Parser.pset(chart, "gfVersion", data.gfVersion)

	local song = paths.formatToSongPath(chart.song)
	if not chart.stage then
		switch(song, {
			["test"] = function() chart.stage = "test" end,
			[{"spookeez", "south", "monster"}] = function() chart.stage = "spooky" end,
			[{"pico", "philly-nice", "blammed"}] = function() chart.stage = "philly" end,
			[{"satin-panties", "high", "milf"}] = function() chart.stage = "limo" end,
			[{"cocoa", "eggnog"}] = function() chart.stage = "mall" end,
			["winter-horrorland"] = function() chart.stage = "mall-evil" end,
			[{"senpai", "roses"}] = function() chart.stage = "school" end,
			["thorns"] = function() chart.stage = "school-evil" end,
			[{"ugh", "guns", "stress"}] = function() chart.stage = "tank" end,
			default = function() chart.stage = "stage" end
		})
	end
	if not chart.skin then
		switch(chart.stage, {
			[{"school", "school-evil"}] = function() chart.skin = "default-pixel" end,
			default = function() chart.skin = "default" end
		})
	end
	if not chart.gfVersion then
		switch(chart.stage, {
			["limo"] = function() chart.gfVersion = "gf-car" end,
			[{"mall", "mall-evil"}] = function() chart.gfVersion = "gf-christmas" end,
			[{"school", "school-evil"}] = function() chart.gfVersion = "gf-pixel" end,
			["tank"] = function()
				chart.gfVersion = song == "stress" and "pico-speaker" or "gf-tankmen"
			end,
			default = function() chart.gfVersion = "gf" end
		})
	end

	local rawNotes = data.notes
	if rawNotes ~= nil and type(rawNotes) ~= "table" then
		error("field 'notes' must be a table", 0)
	end
	if type(rawNotes) == "table" and #rawNotes == 0 and next(rawNotes) ~= nil then
		local picked = rawNotes[diffKey] or rawNotes.normal or rawNotes.default
		if type(picked) ~= "table" then
			for _, v in pairs(rawNotes) do
				if type(v) == "table" then
					picked = v
					break
				end
			end
		end
		rawNotes = picked
	end

	if rawNotes then
		chart.notes, chart.events, chart.timeChanges =
			getStuff(rawNotes, events, data.events, chart.bpm,
				data.format and data.format:startsWith("psych"))
	end

	return chart
end

return vanilla
