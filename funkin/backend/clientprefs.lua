local ClientPrefs = {}

local desktop = game.system.device == "Desktop"
ClientPrefs.data = {
	-- controls
	asyncInput = false,
	virtualControls = true,

	-- gameplay
	autoPause = desktop,
	downScroll = false,
	middleScroll = false,
	ghostTap = true,
	noteSplash = true,
	backgroundDim = 0,
	flashingLights = true,
	botplayMode = false,
	playback = 1,
	gameOverInfos = true,

	-- gameplay - notes
	splitReceptors = not desktop,
	splitWidth = desktop and 448 or 900,
	noteWidth = desktop and 112 or 190,

	-- audio
	pauseMusic = "railways",
	hitSound = 0,
	songOffset = 0,
	menuMusicVolume = 80,
	musicVolume = 100,
	vocalVolume = 100,
	sfxVolume = 80,

	-- display
	fps = 0,
	antialiasing = true,
	lowQuality = false,
	shader = true,
	fullscreen = false,
	resolution = 1,
	vsync = true,
	margin = desktop and 0 or 76,

	-- screen recording
	screenRecording = false,
	recordingMode = "gameplay",
	recordingAutoGameplay = true,
	recordingAudio = true,
	recordingQuality = "high",
	recordingScale = 1.0,
	recordingFps = 60,
	recordingIndicator = true,
	recordingProfileVersion = 0,

	-- stats
	showFps = false,
	showRender = false,
	showMemory = false,
	showDraws = false,

	-- toast messages
	showToastErrors = true,
	showToastDeprecations = true,
	showToastPrints = false,
}

ClientPrefs.controls = {
	note_left = {"key:a", "key:left", "button:dpleft"},
	note_down = {"key:s", "key:down", "button:dpdown"},
	note_up = {"key:w", "key:up", "button:dpup"},
	note_right = {"key:d", "key:right", "button:dpright"},

	ui_left = {"key:a", "key:left", "button:dpleft"},
	ui_down = {"key:s", "key:down", "button:dpdown"},
	ui_up = {"key:w", "key:up", "button:dpup"},
	ui_right = {"key:d", "key:right", "button:dpright"},

	volume_down = {"key:-", "key:kp-"},
	volume_up = {"key:+", "key:kp+", "key:="},
	volume_mute = {"key:0", "key:kp0"},

	reset = {"key:r", "button:y"},
	accept = {"key:z", "key:space", "key:return", "key:kpenter", "button:a"},
	back = {"key:x", "key:backspace", "key:escape", "key:acback", "button:b", "button:back"},
	pause = {"key:p", "key:return", "key:escape", "key:acback", "button:start"},

	fullscreen = {"key:f11"},
	pick_mods = {"key:tab"},

	debug_1 = {"key:7"},
	debug_2 = {"key:6"},
}

function ClientPrefs.saveData()
	ClientPrefs.data.fullscreen = love.window.getFullscreen()

	game.save.data.prefs = ClientPrefs.data
	game.save.data.controls = ClientPrefs.controls

	game.save.bind("funkin")
end

-- load save on start
game.save.init("funkin")
pcall(table.merge, ClientPrefs.data, game.save.data.prefs)
pcall(table.merge, ClientPrefs.controls, game.save.data.controls)

if (tonumber(ClientPrefs.data.recordingProfileVersion) or 0) < 4 then
	ClientPrefs.data.recordingAudio = true
	ClientPrefs.data.recordingQuality = "high"
	ClientPrefs.data.recordingScale = 1.0
	ClientPrefs.data.recordingFps = 60
	if not desktop then
		ClientPrefs.data.autoPause = false
	end
	ClientPrefs.data.recordingProfileVersion = 4
end

local function ensureControlBind(list, bind)
	if type(list) == "table" and not table.find(list, bind) then
		table.insert(list, bind)
	end
end

function ClientPrefs.ensureDefaultBinds(ctrlTbl)
	if type(ctrlTbl) ~= "table" then return end
	ensureControlBind(ctrlTbl.note_left, "button:dpleft")
	ensureControlBind(ctrlTbl.note_down, "button:dpdown")
	ensureControlBind(ctrlTbl.note_up, "button:dpup")
	ensureControlBind(ctrlTbl.note_right, "button:dpright")
	ensureControlBind(ctrlTbl.ui_left, "button:dpleft")
	ensureControlBind(ctrlTbl.ui_down, "button:dpdown")
	ensureControlBind(ctrlTbl.ui_up, "button:dpup")
	ensureControlBind(ctrlTbl.ui_right, "button:dpright")
	ensureControlBind(ctrlTbl.reset, "button:y")
	ensureControlBind(ctrlTbl.accept, "key:kpenter")
	ensureControlBind(ctrlTbl.accept, "button:a")
	ensureControlBind(ctrlTbl.back, "key:acback")
	ensureControlBind(ctrlTbl.back, "button:b")
	ensureControlBind(ctrlTbl.back, "button:back")
	ensureControlBind(ctrlTbl.pause, "key:acback")
	ensureControlBind(ctrlTbl.pause, "button:start")
end

ClientPrefs.ensureDefaultBinds(ClientPrefs.controls)

return ClientPrefs
