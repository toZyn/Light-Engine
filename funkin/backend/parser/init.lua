local chart = require "funkin.backend.parser.chart"
local character = require "funkin.backend.parser.character"
local stage = require "funkin.backend.parser.stage"
local RecoverableErrors = require "funkin.backend.recoverable-errors"

local Parser = {chart = chart, character = character, lastError = nil}

local weak = {__mode = "k"}
local weakValue = {__mode = "kv"}

local chartCache = setmetatable({}, weakValue)
local characterCache = setmetatable({}, weakValue)
local stageCache = setmetatable({}, weakValue)
local metaCache = setmetatable({}, weakValue)

function Parser.sortByTime(a, b)
	if a and b then
		return a.t < b.t
	end
	return false
end

function Parser.pset(tbl, key, v) if v ~= nil then tbl[key] = v end end

local function getCacheKey(...) return table.concat({...}, "@") end

local function cleanErrorMessage(rawErr)
	local s = tostring(rawErr or "invalid data")
	s = s:gsub("^[^\n]-:%d+:%s*", "")
	return s
end

local function reportChartParseError(songName, filePath, reason, trace)
	local clean = cleanErrorMessage(reason)
	local pathInfo = (type(filePath) == "string" and filePath ~= "") and filePath or ("songs/" .. tostring(songName))
	local msg
	if clean:find(pathInfo, 1, true) == 1 then
		msg = string.format('[Chart Error] Song "%s" (%s)', tostring(songName), clean)
	else
		msg = string.format('[Chart Error] Song "%s" (%s): %s', tostring(songName), pathInfo, clean)
	end
	Parser.lastError = msg
	Logger.log("error", msg)
	if RecoverableErrors and RecoverableErrors.report then
		RecoverableErrors.report(msg, trace, {source = "chart-parser", song = songName, path = pathInfo})
	end
	return msg
end

local function resolveSongMetaData(songSlug, diff)
	local base = "songs/" .. songSlug .. "/"
	local diffKey = type(diff) == "string" and diff:lower() or ""
	local candidates = {}

	local function addKey(rel)
		if rel and rel ~= "" and not table.find(candidates, rel) then
			table.insert(candidates, rel)
		end
	end

	if diffKey ~= "" then
		addKey("meta-" .. diffKey)
		addKey(songSlug .. "-metadata-" .. diffKey)
		if diffKey == "nightmare" then
			addKey("meta-erect")
			addKey(songSlug .. "-metadata-erect")
		end
	end
	addKey("meta")
	addKey("metadata")

	for _, rel in ipairs(candidates) do
		local fullKey = base .. rel
		local resolved = paths.getPath(fullKey .. ".json")
		if paths.exists(resolved, "file") then
			local metaTbl, metaPath = paths.getJSON(fullKey)
			-- If a flat Light-Engine override lacks timeChanges, inherit tempo map from base assets if present
			if type(metaTbl) == "table" and metaTbl.timeChanges == nil and metaTbl.bpm == nil then
				local rawBasePath = "assets/" .. base .. "meta.json"
				if resolved ~= rawBasePath and paths.exists(rawBasePath, "file") then
					local okBase, baseMeta = pcall(function()
						return require("loxel.lib.json").decode(love.filesystem.read(rawBasePath))
					end)
					if okBase and type(baseMeta) == "table" and type(baseMeta.timeChanges) == "table" then
						metaTbl = table.clone(metaTbl)
						metaTbl.timeChanges = baseMeta.timeChanges
					end
				end
			end
			return metaTbl, metaPath or resolved
		end
	end

	return nil, paths.getPath(base .. "meta.json")
end

function Parser.getChart(name, diff, opts)
	local rawName = tostring(name or "unknown")
	name = paths.formatToSongPath(rawName)
	diff = diff and diff:lower() or "normal"
	local strict = type(opts) == "table" and opts.strict == true

	local cacheKey = getCacheKey(name, diff)

	if chartCache[cacheKey] then
		Parser.lastError = nil
		return chartCache[cacheKey]
	end

	local okChart, data, path, chartFilePath = xpcall(function()
		return chart.get(name, diff)
	end, debug.traceback)
	if not okChart then
		local firstLine, trace = tostring(data):match("^([^\n]+)\n?(.*)")
		local msg = reportChartParseError(rawName, "songs/" .. name .. "/chart.json", firstLine or data, trace)
		return nil, msg
	end

	if data then
		local parser = chart.getParser(data)

		local okMeta, meta, metaFilePath = xpcall(function()
			return resolveSongMetaData(name, diff)
		end, debug.traceback)
		if not okMeta then
			local firstLine, trace = tostring(meta):match("^([^\n]+)\n?(.*)")
			local msg = reportChartParseError(rawName, path .. "meta.json", firstLine or meta, trace)
			return nil, msg
		end

		local okEvents, events = xpcall(function()
			return paths.getJSON(path .. "events")
		end, debug.traceback)
		if not okEvents then
			local firstLine, trace = tostring(events):match("^([^\n]+)\n?(.*)")
			local msg = reportChartParseError(rawName, path .. "events.json", firstLine or events, trace)
			return nil, msg
		end

		local okParse, parsedOrErr = xpcall(function()
			return parser.parse(data, events, meta, diff)
		end, debug.traceback)
		if not okParse then
			local firstLine, trace = tostring(parsedOrErr):match("^([^\n]+)\n?(.*)")
			local reason = firstLine or tostring(parsedOrErr)
			local isMetaErr = reason:find("meta", 1, true)
				or reason:find("playData", 1, true)
				or reason:find("timeChanges", 1, true)
			local failingPath = isMetaErr and (metaFilePath or (path .. "meta.json"))
				or (chartFilePath or (path .. "chart.json"))
			local msg = reportChartParseError(rawName, failingPath, reason, trace)
			return nil, msg
		end

		data = parsedOrErr
		data.metadata = Parser.getMeta(name)

		if data.player1 then data.player1 = character.resolveName(data.player1) or data.player1 end
		if data.player2 then data.player2 = character.resolveName(data.player2) or data.player2 end
		if data.gfVersion then data.gfVersion = character.resolveName(data.gfVersion) or data.gfVersion end

		table.sort(data.notes.enemy, Parser.sortByTime)
		table.sort(data.notes.player, Parser.sortByTime)
		table.sort(data.events, Parser.sortByTime)

		if data.song == nil then data.song = name end

		chartCache[cacheKey] = data
		Parser.lastError = nil

		Logger.log("debug", "[ PARSER ] Chart \"" .. (data.song or "unknown") ..
			"\" parsed as " .. (parser.name or "unknown"))
		return data
	else
		if strict then
			local msg = reportChartParseError(rawName, chartFilePath or ("songs/" .. name .. "/chart.json"),
				"chart file not found")
			return nil, msg
		end
		Logger.log("warn", "[ PARSER ] Chart not found for " .. name .. ", generated a dummy one")
		local dummy = Parser.getDummyChart(name, true)
		dummy.metadata = Parser.getMeta(name)
		chartCache[cacheKey] = dummy
		return dummy
	end
end

function Parser.getDummyChart(name, dummyData)
	return {
		song = name and paths.formatToSongPath(name) or nil,
		bpm = 100,
		speed = 1,

		difficulties = {"Easy", "Normal", "Hard"},

		player1 = dummyData and "bf" or nil,
		player2 = dummyData and "dad" or nil,
		gfVersion = dummyData and "gf" or nil,

		stage = dummyData and "stage" or nil,
		skin = dummyData and "default" or nil,

		events = {},
		notes = {player = {}, enemy = {}}
	}
end

function Parser.newTimeChange(time, bpm, beats, n, d)
	return {
		t = time,
		b = beats,
		bpm = bpm,
		n = n or 4,
		d = d or 4
	}
end

function Parser.getMeta(name)
	local cacheKey = paths.formatToSongPath(name)

	if metaCache[cacheKey] then return metaCache[cacheKey] end

	local format = paths.formatToSongPath
	local meta = {
		song = format(name),
		displayName = name,
		charter = "unknown",
		composer = "unknown",

		icon = HealthIcon.defaultIcon,
		color = Color.WHITE,
		difficulties = {"easy", "normal", "hard"}
	}

	local songSlug = format(name)
	local okMeta, data = pcall(paths.getJSON, "songs/" .. songSlug .. "/meta")
	if not okMeta then
		Logger.log("error", string.format('[ PARSER ] Invalid metadata in "%s": %s',
			tostring(name), cleanErrorMessage(data)))
		return meta
	end
	if type(data) ~= "table" or #data > 0 then
		if data ~= nil then
			Logger.log("error", string.format('[ PARSER ] Invalid metadata root in "songs/%s/meta.json": expected object',
				songSlug))
		end
		metaCache[cacheKey] = meta
		return meta
	end
	setmetatable(data, weakValue)

	local function get(key, def)
		local playData = type(data.playData) == "table" and data.playData or {}
		local info
		if type(key) == "table" then
			for i = 1, #key do
				local k = key[i]
				info = playData[k] ~= nil and playData[k] or
					data[k] ~= nil and data[k]
				if info then
					break
				end
			end
		else
			info = playData[key] ~= nil and playData[key] or
				data[key] ~= nil and data[key]
		end
		return info or def
	end

	meta.displayName = tostring(get({"displayName", "songName", "song", "name"}, meta.displayName))
	meta.icon = tostring(get("icon", meta.icon))
	local rawDiffs = get("difficulties", meta.difficulties)
	if type(rawDiffs) == "table" and #rawDiffs > 0 then
		local normalized = {}
		for _, difficulty in ipairs(rawDiffs) do
			if type(difficulty) == "string" and difficulty ~= "" then
				local cap = (difficulty:gsub("^%l", string.upper))
				table.insert(normalized, cap)
			end
		end
		if #normalized > 0 then meta.difficulties = normalized end
	end

	-- Discover Erect / Pico / BF difficulty variants when present alongside base meta.json
	local function appendDiff(d)
		for _, existing in ipairs(meta.difficulties) do
			if existing:lower() == d:lower() then return end
		end
		local cap = (d:gsub("^%l", string.upper))
		table.insert(meta.difficulties, cap)
	end
	if paths.exists(paths.getPath("songs/" .. songSlug .. "/meta-erect.json"), "file") then
		local okE, erectMeta = pcall(paths.getJSON, "songs/" .. songSlug .. "/meta-erect")
		local eDiffs = okE and type(erectMeta) == "table"
			and type(erectMeta.playData) == "table"
			and erectMeta.playData.difficulties
		if type(eDiffs) == "table" then
			for _, d in ipairs(eDiffs) do
				if type(d) == "string" then appendDiff(d) end
			end
		end
	end
	for _, variant in ipairs({"pico", "bf"}) do
		if paths.exists(paths.getPath("songs/" .. songSlug .. "/" .. songSlug .. "-chart-" .. variant .. ".json"), "file") then
			appendDiff(variant)
		end
	end

	meta.charter = get("charter", meta.charter)
	meta.composer = get({"composer", "artist"}, meta.composer)

	local rawColor = get("color", nil)
	if rawColor then
		switch(type(rawColor), {
			["string"] = function()
				if not rawColor:startsWith("#") then
					rawColor = "0x" .. rawColor
				else
					rawColor = rawColor:gsub("#", "0x")
				end
				meta.color = Color.fromHEX(tonumber(rawColor))
			end,
			["number"] = function() meta.color = Color.fromHEX(rawColor) end,
			["table"]  = function() meta.color = Color.convert(rawColor) end
		})
	end
	if data.version ~= nil and data.songName then
		switch(data.songName:lower(), {
			[{"bopeebo", "fresh", "dadbattle"}] = function() meta.icon = "dad" end,
			[{"south", "spookeez"}] = function() meta.icon = "spooky" end,
			[{"pico", "philly nice", "blammed"}] = function() meta.icon = "pico" end,
			[{"satin panties", "high", "m.i.l.f"}] = function() meta.icon = "mom" end,
			[{"cocoa", "eggnog"}] = function() meta.icon = "parents" end,
			[{"ugh", "guns", "stress"}] = function() meta.icon = "tankman" end,
			[{"darnell", "lit up", "2hot", "blazin"}] = function() meta.icon = "darnell" end,
			[{"monster", "winter horrorland"}] = function() meta.icon = "monster" end,
			["senpai"] = function() meta.icon = "senpai-pixel" end,
			["roses"] = function() meta.icon = "senpai-angry-pixel" end,
			["thorns"] = function() meta.icon = "spirit-pixel" end,
			["tutorial"] = function() meta.icon = "gf" end,
		})
	end

	metaCache[cacheKey] = meta
	return meta
end

function Parser.getCharacter(name)
	if characterCache[name] then
		return characterCache[name].data, characterCache[name].parser
	end

	local data = character.get(name)
	if not data then data = character.get("bf") end
	local parser = character.getParser(data)

	local parsed = parser.parse(data, name)

	characterCache[name] = {data = parsed, parser = parser.name}

	return parsed, parser.name
end

function Parser.getDummyChar(name)
	return {
		animations = {},
		voice_suffix = name or "",

		position = {0, 0},
		camera_points = {0, 0},
		sing_duration = 4,
		dance_beats = nil,

		flip_x = false,
		icon = HealthIcon.defaultIcon,
		sprite = nil,
		antialiasing = true,
		scale = 1
	}
end

function Parser.getStage(name)
	if stageCache[name] then return stageCache[name] end

	local data = stage.get(name)
	if not data then return false end

	local parsed = stage.getParser(data)
	if parsed then
		parsed = parsed.parse(data)
		stageCache[name] = parsed
	end
	return parsed
end

function Parser.getDummyStage()
	return {
		name = "Stage",
		cameraZoom = 1.0,
		props = {},
		characters = {}
	}
end

function Parser.clearCache()
	chartCache = setmetatable({}, weakValue)
	characterCache = setmetatable({}, weakValue)
	stageCache = setmetatable({}, weakValue)
	metaCache = setmetatable({}, weakValue)
	collectgarbage("collect")
end

return Parser
