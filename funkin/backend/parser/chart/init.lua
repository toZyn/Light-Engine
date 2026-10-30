local f = "funkin.backend.parser.chart."

local vanilla = require(f .. "vanilla")
local codename = require(f .. "codename")
local vslice = require(f .. "vslice")

local ChartParse = {}

function ChartParse.get(song, diff)
	song = paths.formatToSongPath(song)
	diff = diff and diff:lower() or "normal"

	local path = "songs/" .. song .. "/"
	local function getFolder(dir)
		return {paths.getPath(path .. dir .. ".json"), path .. dir}
	end

	local candidates = {
		getFolder("charts/" .. diff),
		getFolder("chart-" .. diff),
		getFolder(song .. "-chart-" .. diff),
		getFolder(diff)
	}
	if diff == "nightmare" then
		table.insert(candidates, getFolder("charts/erect"))
		table.insert(candidates, getFolder("chart-erect"))
	end
	table.insert(candidates, getFolder("chart"))

	for _, p in ipairs(candidates) do
		if paths.exists(p[1], "file") then
			return paths.getJSON(p[2]), path
		end
	end
end

function ChartParse.getParser(data)
	if data.codenameChart then
		return codename
	elseif not data.version then
		return vanilla
	end
	return vslice
end

return ChartParse
