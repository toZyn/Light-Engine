local Globals = {}

function Globals.initializeState(state)
 state.totalPlayed = 0
 state.totalNotesHit = 0
 state.ratingName = '?'
 state.ratingPercent = 0
 state.ratingFC = nil
 state.ratingStuff = {{'You Suck!',.2},{'Shit',.4},{'Bad',.5},{'Bruh',.6},{'Meh',.69},
  {'Nice',.7},{'Good',.8},{'Great',.9},{'Sick!',1},{'Perfect!!',1}}
 state.ratingsData = {}
 for index, name in ipairs({'sick','good','bad','shit'}) do
  local field = name .. 's'
  state[field] = 0
  state.ratingsData[index] = setmetatable({name=name}, {
   __index=function(_, key) if key == 'hits' then return state[field] end end,
   __newindex=function(object, key, value) if key == 'hits' then state[field]=value else rawset(object,key,value) end end
  })
 end
end

local preferenceDefaults = {
 framerate = 60, ghostTapping = true, hideHud = false, timeBarType = 'Time Left',
 scoreZoom = true, cameraZoomOnBeat = true, flashingLights = true, noteOffset = 0,
 healthBarAlpha = 1, noResetButton = false, lowQuality = false, shadersEnabled = true,
 noteSkin = 'Default', splashSkin = 'Psych', splashAlpha = 0.6
}
local preferenceFields = {ghostTapping='ghostTap', cameraZoomOnBeat='camZooms',
 flashingLights='flashingLights', noteOffset='songOffset', noResetButton='noReset', shadersEnabled='shader'}

local function postfix(value, default, separator)
 if value == default then return '' end
 return '-' .. value:match('^%s*(.-)%s*$'):lower():gsub(' ', separator)
end

function Globals.prepare(state, chart)
 local stage = state.stage and state.stage.data or Parser.getStage(chart.stage or 'stage')
 local characters = stage and stage.characters or {}
 for name, entry in pairs({Boyfriend={'bf','BF',770,100}, Opponent={'dad','DAD',100,100}, Girlfriend={'gf','GF',400,130}}) do
  local character = characters[entry[1]]
  local position = character and character.position
  state[entry[2] .. '_X'] = position and position[1] or entry[3]
  state[entry[2] .. '_Y'] = position and position[2] or entry[4]
 end
 local prefs = ClientPrefs.data
 local settings = prefs.gameplaySettings or {}
 state.healthGain = settings.healthgain == nil and 1 or settings.healthgain
 state.healthLoss = settings.healthloss == nil and 1 or settings.healthloss
 state.practiceMode = settings.practice == true
 state.instakillOnMiss = settings.instakill == true
 state.cpuControlled = settings.botplay == nil and prefs.botplayMode == true or settings.botplay == true
 state.guitarHeroSustains = prefs.guitarHeroSustains ~= false
end

function Globals.initial(state, chart, scriptName)
 local conductor = state.conductor
 local bpm = chart.bpm or (conductor and conductor.bpm) or 100
 local section = chart.sections and chart.sections[(state.psychSectionIndex or 1)]
 local values = {
  songName=chart.song, songPath=chart.song and paths.formatToSongPath(chart.song),
  bpm=chart.bpm, curBpm=conductor and conductor.bpm or bpm,
  crochet=conductor and conductor.crotchet or 60000/bpm,
  stepCrochet=conductor and conductor.stepCrotchet or 15000/bpm,
  songLength=(game.sound.music and game.sound.music.duration or 0)*1000,
  curStage=chart.stage, curStep=conductor and conductor.step.i or 0,
  curBeat=conductor and conductor.beat.i or 0, curSection=(state.psychSectionIndex or 1)-1,
  mustHitSection=section and section.mustHitSection == true or false,
  altAnim=section and section.altAnim == true or false, gfSection=section and section.gfSection == true or false,
  isStoryMode=PlayState.storyMode, screenWidth=game.width, screenHeight=game.height,
  score = state.score, misses = state.misses, hits = state.songHits, combo = state.combo,
  rating = state.ratingPercent, ratingName = state.ratingName, ratingFC = state.ratingFC,
  totalPlayed = state.totalPlayed, totalNotesHit = state.totalNotesHit,
  scrollSpeed = chart.speed, startedCountdown = false,
  curDecBeat = state.conductor and state.conductor.beat.f or 0,
  curDecStep = state.conductor and state.conductor.step.f or 0,
  healthGainMult = state.healthGain or 1, healthLossMult = state.healthLoss or 1,
  playbackRate = state.playback or 1, inGameOver = state.isDead == true,
  botPlay = state.cpuControlled == true,
  practice = state.practiceMode == true, instakillOnMiss = state.instakillOnMiss == true,
  guitarHeroSustains = state.guitarHeroSustains == true,
  Function_Stop = '##PSYCHLUA_FUNCTIONSTOP', Function_Continue = '##PSYCHLUA_FUNCTIONCONTINUE',
  Function_StopLua = '##PSYCHLUA_FUNCTIONSTOPLUA', Function_StopHScript = '##PSYCHLUA_FUNCTIONSTOPHSCRIPT',
  Function_StopAll = '##PSYCHLUA_FUNCTIONSTOPALL', luaDebugMode = false, luaDeprecatedWarnings = true,
  version = '1.0.4', scriptName = scriptName or '',
  modFolder = Mods.currentMod, currentModDirectory = Mods.currentMod or '',
  loadedSongName = PlayState.psychLoadedSongName or chart.song,
  loadedSongPath = state.psychLoadedSongPath or (chart.song and chart.song:lower():gsub(' ', '-')),
  chartPath = state.psychChartPath,
  seenCutscene = PlayState.seenCutscene, hasVocals = chart.needsVoices,
  deaths = GameOverSubstate.deaths or 0
 }
 for key, default in pairs(preferenceDefaults) do
  local value = ClientPrefs.data[preferenceFields[key] or key]
  if value == nil then value = default end
  values[key] = value
 end
 values.downscroll = ClientPrefs.data.downScroll
 values.middlescroll = ClientPrefs.data.middleScroll
 values.noteSkinPostfix = postfix(values.noteSkin, 'Default', '_')
 values.splashSkinPostfix = postfix(values.splashSkin, 'Psych', '-')
 local os = love.system.getOS():lower()
 values.buildTarget = os == 'os x' and 'mac' or os
 local difficulty = PlayState.songDifficulty or 'normal'
 local list = state.psychDifficultyList or PlayState.psychDifficultyList or {'Easy', 'Normal', 'Hard'}
 values.difficulty = 0
 values.difficultyName = 'Normal'
 for index, name in ipairs(list) do
  if name:lower() == difficulty:lower() then values.difficulty = index - 1; values.difficultyName = name; break end
 end
 values.difficultyNameTranslation = values.difficultyName
 values.difficultyPath = values.difficultyName:lower() == 'normal' and '' or '-' .. values.difficultyName:lower():gsub(' ', '-')
 values.weekRaw = PlayState.psychWeekIndex or 0
 values.week = PlayState.storyWeek ~= '' and PlayState.storyWeek or nil
 for _, label in ipairs({'Player', 'Opponent'}) do
  for index = 0, 3 do
   values['default' .. label .. 'StrumX' .. index] = 0
   values['default' .. label .. 'StrumY' .. index] = 0
  end
 end
 for name, prefix in pairs({Boyfriend='BF',Opponent='DAD',Girlfriend='GF'}) do
  values['default' .. name .. 'X'] = state[prefix .. '_X']
  values['default' .. name .. 'Y'] = state[prefix .. '_Y']
 end
 values.boyfriendName = state.boyfriend and state.boyfriend.char or chart.player1
 values.dadName = state.dad and state.dad.char or chart.player2
 values.gfName = state.gf and state.gf.char or chart.gfVersion
 return values
end

return Globals
