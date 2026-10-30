local f = "funkin.backend.parser.chart."

local vanilla = require(f .. "vanilla")
local codename = require(f .. "codename")
local vslice = require(f .. "vslice")

local ChartParse = {}

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
	elseif type(data.song) == "table" then
		return vanilla
	elseif data.version ~= nil or type(data.scrollSpeed) == "table" then
		return vslice
	end
	return vanilla
end

return ChartParse
