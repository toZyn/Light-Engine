local vslice = {name = "V-Slice"}

local STAGE_MAP = {
	mainStage = "stage",
	mainStageErect = "stage",
	spookyMansion = "spooky",
	spookyMansionErect = "spooky",
	phillyTrain = "philly",
	phillyTrainErect = "philly",
	phillyStreetsErect = "phillyStreets",
	limoRide = "limo",
	limoRideErect = "limo",
	mallXmas = "mall",
	mallXmasErect = "mall",
	mallEvil = "mall-evil",
	mallEvilErect = "mall-evil",
	school = "school",
	schoolErect = "school",
	schoolEvil = "school-evil",
	schoolEvilErect = "school-evil",
	tankmanBattlefield = "tank",
	tankmanBattlefieldErect = "tank"
}

local function normalizeNoteStyle(style)
	if style == "funkin" or style == nil or style == "" then
		return "default"
	elseif style == "pixel" then
		return "default-pixel"
	end
	return style
end

local function validateTimeChanges(tc)
	if tc == nil then return nil end
	if type(tc) ~= "table" then
		error("field 'timeChanges' must be a list of tempo entries", 0)
	end
	for idx, entry in ipairs(tc) do
		if type(entry) ~= "table" or tonumber(entry.bpm) == nil then
			error(string.format("field 'timeChanges[%d].bpm' must be a number", idx), 0)
		end
	end
	return tc
end

local function updateFromMeta(chart, meta)
	if meta == nil then return end
	if type(meta) ~= "table" or #meta > 0 then
		error("metadata root must be a JSON object", 0)
	end

	local info = meta.playData
	if info ~= nil and type(info) ~= "table" then
		error("field 'playData' must be a table (got " .. type(info) .. ")", 0)
	end

	-- Accept either native V-Slice metadata (playData table) or Light-Engine flat metadata
	local hasFlatFields = type(meta.stage) == "string"
		or type(meta.characters) == "table"
		or type(meta.skin) == "string"
		or tonumber(meta.bpm) ~= nil
	if info == nil and not hasFlatFields then
		error("field 'playData' is missing or invalid in V-Slice metadata", 0)
	end

	local rawStage = (info and info.stage) or meta.stage
	if rawStage ~= nil and type(rawStage) ~= "string" then
		error("field 'playData.stage' must be a string", 0)
	end
	Parser.pset(chart, "stage", STAGE_MAP[rawStage] or rawStage)

	local rawStyle = (info and info.noteStyle) or meta.skin
	if type(rawStyle) == "table" then
		rawStyle = rawStyle.skin or rawStyle.name or "default"
	end
	if rawStyle ~= nil and type(rawStyle) ~= "string" then
		error("field 'playData.noteStyle' must be a string", 0)
	end
	Parser.pset(chart, "skin", normalizeNoteStyle(rawStyle))

	local diffs = (info and info.difficulties) or meta.difficulties
	if diffs ~= nil and type(diffs) ~= "table" then
		error("field 'playData.difficulties' must be a list", 0)
	end
	Parser.pset(chart, "difficulties", diffs)

	local tc = validateTimeChanges(meta.timeChanges)
	if not tc and tonumber(meta.bpm) then
		tc = {Parser.newTimeChange(0, tonumber(meta.bpm), nil, 4, 4)}
	end
	if tc then
		Parser.pset(chart, "timeChanges", tc)
	end

	local chars = (info and info.characters) or meta.characters
	if chars ~= nil then
		if type(chars) ~= "table" then
			error("field 'playData.characters' must be a table", 0)
		end
		local player1 = chars.player
		if player1 == "pico" and paths.exists(paths.getPath("data/characters/pico-playable.json"), "file") then
			player1 = "pico-playable"
		end
		Parser.pset(chart, "player1", player1)
		Parser.pset(chart, "player2", chars.opponent)
		Parser.pset(chart, "gfVersion", chars.girlfriend)
	end
end

local function processNotes(notes)
	local dad, bf = {}, {}
	for idx, raw in ipairs(notes) do
		if type(raw) ~= "table" then
			error(string.format("field 'notes[%d]' must be an object", idx), 0)
		end
		local dVal = tonumber(raw.d)
		if dVal == nil then
			error(string.format("field 'notes[%d].d' must be numeric", idx), 0)
		end
		local n = table.clone(raw)
		local isPlayer = not (dVal > 3)
		n.d = dVal % 4
		n.k = n.k == "mom" and "alt" or n.k
		table.insert(isPlayer and bf or dad, n)
	end

	return {enemy = dad, player = bf}
end

function vslice.parse(data, events, meta, diff)
	if type(data) ~= "table" then
		error("chart root must be a JSON object", 0)
	end
	if data.notes ~= nil and type(data.notes) ~= "table" then
		error("field 'notes' must be a table", 0)
	end
	if data.scrollSpeed ~= nil and type(data.scrollSpeed) ~= "table" and tonumber(data.scrollSpeed) == nil then
		error("field 'scrollSpeed' must be a table or number", 0)
	end

	local chart = Parser.getDummyChart()
	updateFromMeta(chart, meta)

	local diffKey = type(diff) == "string" and diff:lower() or "normal"
	local scrollspeed = data.scrollSpeed
	if type(scrollspeed) == "table" then
		chart.speed = tonumber(scrollspeed[diffKey]
			or (diffKey == "nightmare" and scrollspeed.erect)
			or scrollspeed.default or scrollspeed.normal) or 1
	elseif tonumber(scrollspeed) then
		chart.speed = tonumber(scrollspeed)
	end

	local notesTbl = data.notes
	local diffnotes = nil
	if type(notesTbl) == "table" then
		diffnotes = notesTbl[diffKey]
		if not diffnotes and diffKey == "nightmare" then
			diffnotes = notesTbl.erect
		end
		if not diffnotes then
			diffnotes = notesTbl.normal or notesTbl.default
		end
		if diffnotes ~= nil and type(diffnotes) ~= "table" then
			error("field 'notes." .. diffKey .. "' must be a list", 0)
		end
	end

	chart.notes = diffnotes and processNotes(diffnotes) or {enemy = {}, player = {}}
	chart.events = table.clone(events or data.events or {})

	return chart
end

return vslice
