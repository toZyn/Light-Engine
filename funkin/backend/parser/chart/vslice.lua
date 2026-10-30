local vslice = {name = "V-Slice"}

local STAGE_MAP = {
	mainStage = "stage",
	mainStageErect = "stage",
	spookyMansion = "spooky",
	spookyMansionErect = "spooky",
	phillyTrain = "philly",
	phillyTrainErect = "philly",
	limoRide = "limo",
	limoRideErect = "limo",
	mallXmas = "mall",
	mallXmasErect = "mall",
	mallEvil = "mall-evil",
	schoolErect = "school",
	schoolPico = "school",
	schoolEvil = "school-evil",
	schoolEvilErect = "school-evil",
	tankmanBattlefield = "tank",
	tankmanBattlefieldErect = "tank",
	phillyStreetsErect = "phillyStreets"
}

local function updateFromMeta(chart, meta)
	if not meta then return end

	assert(meta.playData ~= nil, "Not a valid V-Slice metadata")
	local info = meta.playData

	Parser.pset(chart, "song", meta.songName or meta.song)

	local rawStage = info.stage
	Parser.pset(chart, "stage", (rawStage and STAGE_MAP[rawStage]) or rawStage)

	local notestyle = info.noteStyle == "funkin" and
		"default" or info.noteStyle == "pixel" and "default-pixel"
		or info.noteStyle
	Parser.pset(chart, "skin", notestyle)
	Parser.pset(chart, "difficulties", info.difficulties)
	Parser.pset(chart, "timeChanges", meta.timeChanges)
	if meta.timeChanges and meta.timeChanges[1] and meta.timeChanges[1].bpm then
		Parser.pset(chart, "bpm", meta.timeChanges[1].bpm)
	end

	local chars = info.characters or {}
	local p1 = chars.player
	if p1 == "pico" then p1 = "pico-playable" end
	Parser.pset(chart, "player1", p1)
	Parser.pset(chart, "player2", chars.opponent)
	Parser.pset(chart, "gfVersion", chars.girlfriend)
end

local function processNotes(notes)
	local dad, bf = {}, {}
	for _, n in ipairs(notes) do
		local rawD = tonumber(n.d or 0) or 0
		local isPlayer = not (rawD > 3)
		local kind = n.k == "mom" and "alt" or n.k
		table.insert(isPlayer and bf or dad, {
			t = n.t,
			d = rawD % 4,
			l = n.l or 0,
			k = kind,
			gf = n.gf
		})
	end

	return {enemy = dad, player = bf}
end

function vslice.parse(data, events, meta, diff)
	local chart = Parser.getDummyChart()
	local scrollspeed = data.scrollSpeed
	local notes = data.notes
	local chartEvents = data.events or events

	updateFromMeta(chart, meta)

	if scrollspeed and diff then
		local d = diff:lower()
		chart.speed = scrollspeed[d]
			or (d == "nightmare" and scrollspeed.erect)
			or scrollspeed.default
			or 1
	end

	local diffKey = diff and diff:lower() or "normal"
	local diffnotes = notes and (notes[diffKey] or (diffKey == "normal" and (notes.hard or notes.easy))) or nil
	chart.notes = diffnotes and processNotes(diffnotes) or {enemy = {}, player = {}}
	chart.events = chartEvents and table.clone(chartEvents) or {}

	return chart
end

return vslice
