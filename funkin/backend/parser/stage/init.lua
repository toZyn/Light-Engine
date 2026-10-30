local f = "funkin.backend.parser.stage."

local vslice = require(f .. "vslice")

local nativeStage = {name = "Native"}
function nativeStage.parse(data)
	local stage = Parser.getDummyStage()
	Parser.pset(stage, "name", data.name or "Stage")
	Parser.pset(stage, "cameraZoom", data.cameraZoom or data.defaultCamZoom or data.zoom or 0.9)
	Parser.pset(stage, "props", data.props or data.sprites or {})
	local chars = data.characters or {}
	if data.boyfriend and not chars.bf then chars.bf = {position = data.boyfriend, cameraOffsets = data.camera_boyfriend} end
	if data.opponent and not chars.dad then chars.dad = {position = data.opponent, cameraOffsets = data.camera_opponent} end
	if data.girlfriend and not chars.gf then chars.gf = {position = data.girlfriend, cameraOffsets = data.camera_girlfriend} end
	stage.characters = chars
	return stage
end

local StageParse = {}

function StageParse.get(stage)
	return paths.getJSON("data/stages/" .. stage)
end

function StageParse.getParser(data)
	if type(data) ~= "table" then return false end
	if data.version ~= nil then
		return vslice
	end
	return nativeStage
end

return StageParse
