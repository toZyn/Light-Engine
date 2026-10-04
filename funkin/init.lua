local funkin = {}

if love.system.getOS() == "Windows" then
	WindowDialogue = require "lib.windows.dialogue"
	WindowUtil = require "lib.windows.util"

	local _ogSetMode = love.window.setMode
	function love.window.setMode(...)
		local success = _ogSetMode(...)
		WindowUtil.setDarkMode(true)
		return success
	end
end

local s, Https = pcall(require, "https")
if not s then
	Https = require "lib.https"
end

Storage = require "funkin.backend.storage"
Storage.init()
Storage.installSave(game.save)

paths = require "funkin.backend.paths"
util = require "funkin.util"

ClientPrefs = require "funkin.backend.clientprefs"
Throttle = require "funkin.backend.throttle"
Parser = require "funkin.backend.parser"

Conductor = require "funkin.backend.gameplay.conductor"
Highscore = require "funkin.backend.gameplay.highscore"

Script = require "funkin.backend.scripts"
ScriptsHandler = require "funkin.backend.scripts.handler"
-- GlobalScripts = require "funkin.backend.modding.scripts.global"
require "funkin.backend.scripts.events"

Mods = require "funkin.backend.modding.mods"
Addons = require "funkin.backend.modding.addons"

Discord = require "funkin.backend.discord"

Skin = require "funkin.backend.gameplay.skin"
Receptor = require "funkin.gameplay.receptor"
Note = require "funkin.gameplay.note"
Notefield = require "funkin.gameplay.notefield"

FFT = require "funkin.backend.fft"
Countdown = require "funkin.gameplay.ui.countdown"
HealthIcon = require "funkin.gameplay.ui.healthicon"
HealthBar = require "funkin.gameplay.ui.healthbar"
ProgressArc = require "funkin.gameplay.ui.progressarc"
Judgements = require "funkin.gameplay.ui.judgements"

NoteMods = require "funkin.gameplay.notemods"
Character = require "funkin.gameplay.character"
Stage = require "funkin.gameplay.stage"
DialogueBox = require "funkin.gameplay.ui.dialoguebox"

AtlasText = require "funkin.ui.atlastext"
SpriteButton = require "funkin.ui.spritebutton"
Marquee = require "funkin.ui.marquee"
MenuList = require "funkin.ui.menulist"
Options = require "funkin.ui.options"
Stickers = require "funkin.ui.stickers"
LoadScreen = require "funkin.ui.loadscreen"

StatsCounter = require "funkin.ui.statscounter"

LoadState = require 'funkin.states.load'
CalibrationState = require 'funkin.states.calibration'
CreditsState = require "funkin.states.credits"
TitleState = require "funkin.states.title"
MainMenuState = require "funkin.states.mainmenu"
ModsState = require "funkin.states.mods"
StoryMenuState = require "funkin.states.storymenu"
FreeplayState = require "funkin.states.freeplay"
PlayState = require "funkin.states.play"

PauseSubstate = require "funkin.substates.pause"
GameOverSubstate = require "funkin.substates.gameover"

EditorMenu = require "funkin.ui.editor.editormenu"
CutsceneState = require "funkin.states.editors.cutscene"
CharacterEditor = require "funkin.states.editors.character"
ChartingState = require "funkin.states.editors.charting"
ChartingNote = require "funkin.ui.editor.charting.chartingnote"

Shader = require "funkin.shaders"
RGBShader = require "funkin.shaders.rgb"
Video = require "funkin.backend.video"

local TransitionFade = loxreq "transition.transitionfade"

function funkin.load()
	local res, isMobile = math.abs(ClientPrefs.data.resolution),
		love.system.getDevice() == "Mobile"
	Camera.defaultResolution = res

	love.window.setTitle(Project.title)
	love.window.setIcon(love.image.newImageData(Project.icon))

	love.window.setMode(Project.width * res, Project.height * res, {
		fullscreen = not isMobile and ClientPrefs.data.fullscreen,
		fullscreentype = "desktop",
		resizable = true,
		usedpiscale = false
	})

	game.display.refresh()
	if not isMobile and ClientPrefs.data.monitor then
		game.display.selectMonitor(ClientPrefs.data.monitor)
	end

	if game.save.data.prefs then
		love.FPScap = ClientPrefs.data.fps
		love.vsync = ClientPrefs.data.vsync
		love.autoPause = ClientPrefs.data.autoPause
	else
		love.FPScap = math.max(select(3, love.window.getMode()).refreshrate, love.FPScap)
		ClientPrefs.data.fps = love.FPScap
		ClientPrefs.data.vsync = love.vsync
		ClientPrefs.data.resolution = 1
	end

	Object.defaultAntialiasing = ClientPrefs.data.antialiasing

	Toast.showPrints = ClientPrefs.data.showToastPrints
	Toast.showErrors = ClientPrefs.data.showToastErrors
	Toast.showDeprecations = ClientPrefs.data.showToastDeprecations

	local config = {controls = table.clone(ClientPrefs.controls)}
	if controls == nil then
		controls = (require "lib.baton").new(config)
	else
		controls:reset(config)
	end

	if Project.bgColor then
		love.graphics.setBackgroundColor(Project.bgColor)
	end

	Mods.reload()
	Addons.reload()
	Storage.refreshWatchList()
	Highscore.load()

	local color = Color.BLACK
	State.defaultTransIn = TransitionFade(0.6, color, "vertical")
	State.defaultTransOut = TransitionFade(0.7, color, "vertical")

	game.onPreStateEnter = function(state)
		-- GlobalScripts.call("preStateEnter", state)
		if paths and not game.getState().persistCache and
			getmetatable(state) ~= getmetatable(game.getState()) then
			paths.clearCache()
			Shader.clear()
		end
	end

	local dimen = love.graphics.getDimensions()
	local SoundTray = require "funkin.ui.soundtray".init(dimen).new()
	game:add(SoundTray)

	game.init(Project, TitleState)

	if ClientPrefs.data.resolution == -1 then
		Camera.defaultResolution = love.graphics.getFixedScale()
		ClientPrefs.data.resolution = Camera.defaultResolution
		for _, camera in ipairs(game.cameras.list) do
			if camera then camera:resize(camera.width, camera.height) end
		end
	end

	game.statsCounter = StatsCounter(18, 18,
		love.graphics.newFont('assets/fonts/consolas.ttf', 14),
		love.graphics.newFont('assets/fonts/consolas.ttf', 18))
	game.statsCounter.showFps = ClientPrefs.data.showFps
	game.statsCounter.showRender = ClientPrefs.data.showRender
	game.statsCounter.showMemory = ClientPrefs.data.showMemory
	game.statsCounter.showDraws = ClientPrefs.data.showDraws
	game:add(game.statsCounter)

	AtlasText.defaultFont = AtlasText.getFont("default", 1)

	if Discord then Discord.init() end

	Script.addToEnv("controls", controls)
	Script.addToEnv("print", print)
	-- GlobalScripts.reload()
end

function funkin.update(dt)
	Storage.update(dt)
	paths.update(dt)

	controls:update()
	Throttle:update(dt)
	Shader.updateTime(dt)

	if Discord then Discord.update() end
	if controls:pressed("fullscreen") then
		love.window.setFullscreen(not love.window.getFullscreen())
	end

	-- GlobalScripts.call("update", dt)
end

function funkin.fullscreen(f)
	ClientPrefs.data.fullscreen = f
end

function funkin.quit()
	ClientPrefs.saveData()
	if Discord then Discord.shutdown() end
end

function funkin.throwError(msg, trace)
 local Diagnostics = require "funkin.backend.diagnostics"
 -- Persist the original error before shutdown or error-screen preparation.
 local report = Diagnostics.report(msg, trace or debug.traceback("", 2))
 if paths and paths.async and paths.async.stop then
  local ok, err = pcall(paths.async.stop)
  if not ok then print("Error-handler async shutdown failed: " .. Diagnostics.sanitize(err)) end
 end
 if type(love.errorhandler_quit) == "function" then pcall(love.errorhandler_quit) end
 local ok, loop = pcall(function()
  return require("funkin.backend.error-screen")(msg, trace)
 end)
 if ok and type(loop) == "function" then return loop end
 -- Missing graphics/base assets must not obscure the original error report.
 if not ok then print("Original error screen unavailable: " .. Diagnostics.sanitize(loop)) end
 return Diagnostics.errorHandler(msg, trace, report)
end

return funkin
