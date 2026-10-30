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
JSON = require "funkin.backend.jsonbuilder"

Conductor = require "funkin.backend.gameplay.conductor"
Highscore = require "funkin.backend.gameplay.highscore"

Script = require "funkin.backend.scripts"
ScriptsHandler = require "funkin.backend.scripts.handler"
GlobalScripts = require "funkin.backend.scripts.global"
require "funkin.backend.scripts.events"

Mods = require "funkin.backend.modding.mods"
Addons = require "funkin.backend.modding.addons"
ModAPI = require "funkin.backend.modding.api"

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
Recorder = require "funkin.backend.recorder"

local TransitionFade = loxreq "transition.transitionfade"
local _lastSurfaceW, _lastSurfaceH = 0, 0

function funkin.load()
	local res, isMobile = math.abs(ClientPrefs.data.resolution),
		love.system.getDevice() == "Mobile"
	Camera.defaultResolution = res

	love.window.setTitle(Project.title)
	love.window.setIcon(love.image.newImageData(Project.icon))

	-- On mobile, resizable=true makes SDL2/LÖVE unlock SCREEN_ORIENTATION_FULL_SENSOR
	-- (allowing Portrait). Keeping resizable=false with landscape dimensions (1280x720)
	-- enforces SCREEN_ORIENTATION_SENSOR_LANDSCAPE while immersive fullscreen stays active.
	love.window.setMode(Project.width * res, Project.height * res, {
		fullscreen = isMobile or ClientPrefs.data.fullscreen,
		fullscreentype = "desktop",
		resizable = not isMobile,
		usedpiscale = false
	})

	game.display.refresh()
	if not isMobile and ClientPrefs.data.monitor then
		game.display.selectMonitor(ClientPrefs.data.monitor)
	end

	if game.save.data.prefs then
		love.FPScap = ClientPrefs.data.fps
		love.vsync = ClientPrefs.data.vsync
		love.autoPause = not isMobile and ClientPrefs.data.autoPause
	else
		love.FPScap = math.max(select(3, love.window.getMode()).refreshrate, love.FPScap)
		ClientPrefs.data.fps = love.FPScap
		ClientPrefs.data.vsync = love.vsync
		ClientPrefs.data.resolution = 1
		love.autoPause = not isMobile and ClientPrefs.data.autoPause
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
	funkin.refreshJoystick()

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
		GlobalScripts.call("preStateEnter", state)
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
	if Timer and Timer.globalManager then
		local RecoverableErrors = require "funkin.backend.recoverable-errors"
		Timer.globalManager.onError = function(message, trace)
			RecoverableErrors.report(message, trace, {source = "timer"})
		end
	end
	_lastSurfaceW, _lastSurfaceH = love.graphics.getDimensions()

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
	Script.addToEnv("Mod", ModAPI)
	GlobalScripts.reload()
end

function funkin.update(dt)
	local sw, sh = love.graphics.getDimensions()
	if sw > 0 and sh > 0 then
		if sw ~= _lastSurfaceW or sh ~= _lastSurfaceH then
			_lastSurfaceW, _lastSurfaceH = sw, sh
			game.resize(sw, sh)
		end
	end

	Storage.update(dt)
	paths.update(dt)

	controls:update()
	Throttle:update(dt)
	Shader.updateTime(dt)
	if Recorder then Recorder.update(dt) end

	if Discord then Discord.update() end
	if controls:pressed("fullscreen") and love.system.getDevice() ~= "Mobile" then
		love.window.setFullscreen(not love.window.getFullscreen())
	end

	GlobalScripts.call("update", dt)
end

function funkin.fullscreen(f)
	ClientPrefs.data.fullscreen = f
end

local function isJoystickConnected(j)
	if not j then return false end
	if j.isConnected then
		local ok, connected = pcall(j.isConnected, j)
		return ok and connected == true
	end
	return true
end

local function isGamepadDevice(j)
	if not isJoystickConnected(j) then return false end
	if j.isGamepad then
		local ok, gp = pcall(j.isGamepad, j)
		if ok and gp then return true end
	end
	return false
end

function funkin.refreshJoystick(preferred)
	if not controls or not controls.config then return end
	local current = controls.config.joystick
	if isGamepadDevice(preferred) then
		controls.config.joystick = preferred
		return
	end
	if isJoystickConnected(current) and (isGamepadDevice(current) or not love.joystick) then
		return
	end
	controls.config.joystick = nil
	if not love.joystick or not love.joystick.getJoysticks then return end
	local ok, sticks = pcall(love.joystick.getJoysticks)
	if not ok or type(sticks) ~= "table" then return end
	local fallback = nil
	for _, j in ipairs(sticks) do
		if isGamepadDevice(j) then
			controls.config.joystick = j
			return
		elseif not fallback and isJoystickConnected(j) then
			-- Only use non-gamepad joysticks if they actually expose axes/buttons
			-- (avoids binding Android keyboard SOURCE_DPAD stubs over keyboard input)
			local okAxes, axes = pcall(function() return j.getAxisCount and j:getAxisCount() or 0 end)
			if okAxes and (axes or 0) >= 2 then
				fallback = j
			end
		end
	end
	if fallback then
		controls.config.joystick = fallback
	elseif isJoystickConnected(preferred) and isGamepadDevice(preferred) then
		controls.config.joystick = preferred
	end
end

function funkin.releaseStuckInputs(forceAllKeys)
	if game and game.keys and game.keys.loveInput and game.keys.loveInput.pressed then
		local toRelease = {}
		for key in pairs(game.keys.loveInput.pressed) do
			local stillDown = false
			if not forceAllKeys and love.keyboard and love.keyboard.isDown then
				local ok, down = pcall(love.keyboard.isDown, key)
				stillDown = ok and down == true
			end
			if not stillDown then
				toRelease[#toRelease + 1] = key
			end
		end
		for _, key in ipairs(toRelease) do
			if controls and controls.onKeyRelease then
				controls:onKeyRelease(key, key)
			end
			if game.keyreleased then
				game.keyreleased(key, key)
			end
		end
		if forceAllKeys and game.keys.releaseAll then
			game.keys.releaseAll()
		end
	end
	if forceAllKeys and controls and controls.releaseAll then
		controls:releaseAll()
	end
end

function funkin.onDeviceRemoved(joystick)
	if controls and controls.config and controls.config.joystick == joystick then
		controls.config.joystick = nil
	end
	funkin.refreshJoystick()
	funkin.releaseStuckInputs(false)
end

function funkin.quit()
	if Recorder then pcall(Recorder.shutdown) end
	if FFT and FFT.stop then pcall(FFT.stop) end
	ClientPrefs.saveData()
	if Discord then Discord.shutdown() end
end

function funkin.throwError(msg, trace)
 local Diagnostics = require "funkin.backend.diagnostics"
 -- Persist the original error before shutdown or error-screen preparation.
 local report = Diagnostics.report(msg, trace or debug.traceback("", 2))
 if Recorder then pcall(Recorder.shutdown) end
 if FFT and FFT.stop then pcall(FFT.stop) end
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
