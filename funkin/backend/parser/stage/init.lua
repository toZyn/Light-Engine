local f = "funkin.backend.parser.stage."

local vslice = require(f .. "vslice")

local nativeStage = {name = "Native"}
function nativeStage.parse(data)
	local stage = Parser.getDummyStage()
	Parser.pset(stage, "name", data.name or "Stage")
	Parser.pset(stage, "cameraZoom", data.cameraZoom or data.defaultCamZoom or data.defaultZoom or data.zoom or 0.9)
	Parser.pset(stage, "props", data.props or data.sprites or {})
	local chars = data.characters or {}
	if data.boyfriend and not chars.bf then chars.bf = {position = data.boyfriend, cameraOffsets = data.camera_boyfriend} end
	if data.opponent and not chars.dad then chars.dad = {position = data.opponent, cameraOffsets = data.camera_opponent} end
	if data.girlfriend and not chars.gf then chars.gf = {position = data.girlfriend, cameraOffsets = data.camera_girlfriend} end
	stage.characters = chars
	stage.hideGirlfriend = data.hide_girlfriend == true
	return stage
end

local StageParse = {}

function StageParse.get(stage)
	local key = "data/stages/" .. stage
	local root = require("funkin.backend.modding.psych").root()
	local path = paths.getPath(key .. ".json")
	if root and path == root .. "stages/" .. stage .. ".json" then
		return paths.getJSON(key, {relaxedObjectSeparators = true})
	end
	return paths.getJSON(key)
end

function StageParse.getParser(data)
	if type(data) ~= "table" then return false end
	if data.version ~= nil then
		return vslice
	end
	return nativeStage
end

return StageParse
