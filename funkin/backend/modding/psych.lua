local Psych = {}
local detected = {}

function Psych.clearDetection()
	detected = {}
end

local function detect(root)
	local fs = love.filesystem
	for _, week in ipairs(fs.getDirectoryItems(root .. "weeks")) do
		if week:match("%.json$") and fs.getInfo(root .. "weeks/" .. week, "file") then
			return true
		end
	end

	for _, song in ipairs(fs.getDirectoryItems(root .. "data")) do
		local dir = root .. "data/" .. song .. "/"
		for _, file in ipairs(fs.getDirectoryItems(dir)) do
			local slug = song:lower()
			local prefix = file:sub(1, #slug + 1)
			if (file == slug .. ".json" or (prefix == slug .. "-" and file:match("%.json$")))
				and fs.getInfo(dir .. file, "file") then
				return true
			end
		end
	end
	return false
end

function Psych.root()
	if not (ClientPrefs and ClientPrefs.data.engineCompatibility and Mods and Mods.currentMod) then return end
	local root = Mods.root .. "/" .. Mods.currentMod .. "/"
	if detected[root] == nil then detected[root] = detect(root) end
	if detected[root] then return root end
end

local function songDirectory(root, song)
	local dir = root .. "data/"
	if love.filesystem.getInfo(dir .. song, "directory") then return song end
	for _, name in ipairs(love.filesystem.getDirectoryItems(dir)) do
		if name:lower() == song then return name end
	end
	return song
end

function Psych.alias(key)
	if key == "data/weekList.txt" then return "weeks/weekList.txt" end
	if key == "data/weeks/weeks" then return "weeks" end
	if key == "data/weeks/characters" then return "images/menucharacters" end
	local week = key:match("^data/weeks/weeks/(.+)$")
	if week then return "weeks/" .. week end
	local character = key:match("^data/weeks/characters/(.+)$")
	if character then return "images/menucharacters/" .. character end
	local banner = key:match("^images/menus/storymenu/weeks/(.+)$")
	if banner then return "images/storymenu/" .. banner end
	local slug, resource = key:match("^songs/([^/]+)/(.+)$")
	if slug and resource ~= "events.json" then
		local root = Psych.root()
		if root then
			for _, name in ipairs(love.filesystem.getDirectoryItems(root .. "songs")) do
				if name:lower() == slug then return "songs/" .. name .. "/" .. resource end
			end
		end
	end
	local song = key:match("^songs/(.+)/events%.json$")
	if song then
		local root = Psych.root()
		return "data/" .. (root and songDirectory(root, song) or song) .. "/events.json"
	end
	return key:match("^data/(characters/.+)$") or key:match("^data/(stages/.+)$")
end

local function loadHScript(path, script)
	local source, err = love.filesystem.read(path)
	if not source then return nil, err end
	return function() script.hscriptCall, script.hscriptHas = script._psych.loadHScript(source) end
end

function Psych.loadScripts(state, handler, song, chart)
	local root = Psych.root()
	if not root then return end
	local globals = require 'funkin.backend.scripts.psych.globals'
	globals.prepare(state, chart)
	state.psychLoadedSongPath = song
	local _, chartPath = Psych.chart(song, PlayState.songDifficulty)
	state.psychChartPath = chartPath
	local loaded, loading = {}, {}
	local conductor = state.conductor
	local bpm = chart.bpm or (conductor and conductor.bpm) or 100
	local function load(file)
		local current = loaded[file]
		if current and not current.closed then return current, false end
		if loading[file] or not love.filesystem.getInfo(root .. file, "file") then return end
		loading[file] = true
		local script = Script(root .. file, true, false, true, function(instance)
			instance.psychRegistry = loaded
			instance.psychLoadScript = load
			instance.psychValues = globals.initial(state, chart, root .. file)
			for key, value in pairs(instance.psychValues) do instance:set(key, value) end
			instance._psych = require("funkin.backend.scripts.compat").new(state, instance, true)
		end, file:match("%.hx$") and loadHScript or nil)
		loading[file] = nil
		if script.closed then return end
		loaded[file] = script
		handler:add(script)
		return script, true
	end
	for _, dir in ipairs({"scripts", "data/" .. songDirectory(root, song)}) do
		for _, name in ipairs(love.filesystem.getDirectoryItems(root .. dir)) do
			if name:match("%.lua$") or name:match("%.hx$") then load(dir .. "/" .. name) end
		end
	end
	local function loadNamed(dir, name)
		if type(name) == "string" and name ~= "" and not name:find("[/\\%z]") then
			load(dir .. "/" .. name .. ".lua")
			load(dir .. "/" .. name .. ".hx")
		end
	end
	loadNamed("stages", chart.stage)
	for _, event in ipairs(chart.events or {}) do
		loadNamed("custom_events", event.e)
	end
	if not love.filesystem.getInfo(root .. "custom_notetypes", "directory") then return end
	local SceneJob = require "funkin.backend.scenejob"
	local seenTypes = {}
	for _, notes in pairs(chart.notes or {}) do
		for index, note in ipairs(notes) do
			if note.k and not seenTypes[note.k] then
				seenTypes[note.k] = true
				loadNamed("custom_notetypes", note.k)
			end
			if index % 8192 == 0 then
				SceneJob.poll("Finding compatibility scripts")
			end
		end
	end
end

function Psych.chart(song, difficulty)
	local root = Psych.root()
	if not root then return end
	local suffix = difficulty ~= "" and difficulty ~= "normal" and "-" .. difficulty or ""
	local key = "data/" .. songDirectory(root, song) .. "/" .. song .. suffix
	local file = root .. key .. ".json"
	if love.filesystem.getInfo(file, "file") then return key, file end
	if suffix == "" then
		key = key .. "-normal"
		file = root .. key .. ".json"
		if love.filesystem.getInfo(file, "file") then return key, file end
	end
end

function Psych.difficulties(song)
	local result = {}
	local root = Psych.root()
	if not root then return result end
	local dir = root .. "data/" .. songDirectory(root, song)
	for _, file in ipairs(love.filesystem.getDirectoryItems(dir)) do
		local name = file:match("^(.+)%.json$")
		if name == song or name == song .. "-normal" then
			result[#result + 1] = "Normal"
		elseif name and name:sub(1, #song + 1) == song .. "-" then
			result[#result + 1] = name:sub(#song + 2)
		end
	end
	return result
end

return Psych
