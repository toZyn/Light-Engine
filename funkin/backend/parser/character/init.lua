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
	["pico-christmas"] = "pico-playable",
	["nene-christmas"] = "nene",
	["nene-dark"] = "nene",
	["pico-pixel"] = "bf-pixel",
	["nene-pixel"] = "gf-pixel",
	["pico-holding-nene"] = "bf-holding-gf",
	["tankman-bloody"] = "tankman",
	["otis-speaker"] = "pico-speaker"
}

local function loadRawChar(charName)
	if not charName or charName == "" then return nil end
	if paths.exists(paths.getPath("data/characters/" .. charName .. ".xml"), "file") then
		return paths.getXML("data/characters/" .. charName).character
	end
	return paths.getJSON("data/characters/" .. charName)
end

function CharacterParser.get(charName)
	local raw = loadRawChar(charName)
	if not raw and charName and FALLBACK_CHARS[charName] then
		raw = loadRawChar(FALLBACK_CHARS[charName])
	end
	return raw
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
