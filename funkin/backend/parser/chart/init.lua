local f = "funkin.backend.parser.chart."

local vanilla = require(f .. "vanilla")
local codename = require(f .. "codename")
local vslice = require(f .. "vslice")

local ChartParse = {}
local Psych = require "funkin.backend.modding.psych"

function ChartParse.get(song, diff)
	song = paths.formatToSongPath(song)
	local diffKey = type(diff) == "string" and diff:lower() or ""
	local path = "songs/" .. song .. "/"
	local candidates = {}

	local function addFolder(dir)
		if dir and dir ~= "" then
			for _, existing in ipairs(candidates) do
				if existing[2] == path .. dir then return end
			end
			table.insert(candidates, {paths.getPath(path .. dir .. ".json"), path .. dir})
		end
	end

	if diffKey ~= "" then
		addFolder("charts/" .. diffKey)
		addFolder("chart-" .. diffKey)
		addFolder(song .. "-chart-" .. diffKey)
		addFolder(diffKey)
		if diffKey == "nightmare" then
			addFolder("charts/erect")
			addFolder("chart-erect")
			addFolder(song .. "-chart-erect")
		end
	end
	addFolder("chart")
	addFolder(song)

	local foreignKey, foreignFile = Psych.chart(song, diffKey)
	if foreignKey then
		for _, candidate in ipairs(candidates) do
			if candidate[1]:sub(1, 7) ~= "assets/" and paths.exists(candidate[1], "file") then
				local raw, resolved = paths.getJSON(candidate[2])
				return raw, path, resolved or candidate[1]
			end
		end
		return paths.getJSON(foreignKey), path, foreignFile
	end

	for _, p in ipairs(candidates) do
		if paths.exists(p[1], "file") then
			local rawChart, resolvedPath = paths.getJSON(p[2])
			return rawChart, path, resolvedPath or p[1]
		end
	end

	return nil, path, paths.getPath(path .. "chart.json")
end

function ChartParse.getParser(data)
	if type(data) ~= "table" then return vanilla end
	if data.codenameChart then
		return codename
	elseif type(data.song) == "table" or (type(data.format) == "string" and data.format:match("^psych")) then
		return vanilla
	elseif data.version ~= nil or type(data.scrollSpeed) == "table" then
		return vslice
	end
	return vanilla
end

return ChartParse
