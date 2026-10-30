local f = "funkin.backend.parser.character."

local CharacterParser = {}

local love = require(f .. "love")
local vslice = require(f .. "vslice")
local psych = require(f .. "psych")
local codename = require(f .. "codename")

local FALLBACK_CHARS = {
	["bf-dark"] = "bf",
	["gf-dark"] = "gf",
	["spooky-dark"] = "spooky",
	["pico-dark"] = "pico-playable",
	["mom-car"] = "mom",
	["bf-christmas"] = "bf",
	["gf-christmas"] = "gf",
	["parents-christmas"] = "dad",
	["monster-christmas"] = "dad",
	["monster"] = "dad",
	["tankman"] = "dad",
	["tankman-player"] = "bf",
	["pico-speaker"] = "gf",
	["otis-speaker"] = "gf",
	["darnell"] = "dad",
	["nene"] = "gf",
	["nene-dark"] = "gf",
	["bf-holding-gf"] = "bf",
	["bf-holding-gf-dead"] = "bf-dead"
}

local function loadCharData(name)
	if not name or name == "" then return nil end
	if paths.exists(paths.getPath("data/characters/" .. name .. ".xml"), "file") then
		local xml = paths.getXML("data/characters/" .. name)
		if xml and xml.character then return xml.character end
	end
	return paths.getJSON("data/characters/" .. name)
end

function CharacterParser.resolveName(charName)
	if not charName or charName == "" then return "bf" end
	if paths.exists(paths.getPath("data/characters/" .. charName .. ".json"), "file")
		or paths.exists(paths.getPath("data/characters/" .. charName .. ".xml"), "file") then
		return charName
	end
	if FALLBACK_CHARS[charName] then return FALLBACK_CHARS[charName] end
	local stripped = charName:gsub("%-dark$", ""):gsub("%-erect$", "")
	if stripped ~= charName and (
		paths.exists(paths.getPath("data/characters/" .. stripped .. ".json"), "file")
		or paths.exists(paths.getPath("data/characters/" .. stripped .. ".xml"), "file")
	) then
		return stripped
	end
	if charName:endsWith("-dead") then return "bf-dead" end
	return nil
end

function CharacterParser.get(charName)
	local data = loadCharData(charName)
	if data then return data end
	local resolved = CharacterParser.resolveName(charName)
	if resolved and resolved ~= charName then
		return loadCharData(resolved)
	end
	return nil
end

function CharacterParser.getParser(data)
	if data.version ~= nil then
		return vslice
	elseif data.image ~= nil and data.sprite == nil then
		return psych
	elseif data.children ~= nil then
		return codename
	end
	return love
end

return CharacterParser
