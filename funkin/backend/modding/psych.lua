local Psych = {}

function Psych.root()
	if not (ClientPrefs and ClientPrefs.data.engineCompatibility and Mods and Mods.currentMod) then return end
	return Mods.root .. "/" .. Mods.currentMod .. "/"
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
	local events = key:match("^songs/(.+/events%.json)$")
	if events then return "data/" .. events end
	return key:match("^data/(characters/.+)$") or key:match("^data/(stages/.+)$")
end

function Psych.loadScripts(state, handler, song, chart)
	local root = Psych.root()
	if not root then return end
	local loaded = {}
	local function load(file)
		if loaded[file] then return end
		loaded[file] = true
		if not love.filesystem.getInfo(root .. file, "file") then return end
		local script = Script(root .. file, true, false, true, function(instance)
			instance._psych = require("funkin.backend.scripts.compat").new(state, instance)
			instance:set("Function_Continue", Script.Event_Continue)
			instance:set("Function_Stop", Script.Event_Cancel)
		end)
		if not script.closed then handler:add(script) end
	end
	for _, dir in ipairs({"scripts", "data/" .. song}) do
		for _, name in ipairs(love.filesystem.getDirectoryItems(root .. dir)) do
			if name:match("%.lua$") then load(dir .. "/" .. name) end
		end
	end
	local function loadNamed(dir, name)
		if type(name) == "string" and name ~= "" and not name:find("[/\\%z]") then
			load(dir .. "/" .. name .. ".lua")
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
	local key = "data/" .. song .. "/" .. song .. suffix
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
	local dir = root .. "data/" .. song
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
