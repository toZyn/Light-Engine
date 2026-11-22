check('Psych counters and globals exist before script source and onCreate', function()
 local Globals = require 'funkin.backend.scripts.psych.globals'
 local state = {score=0,misses=0,songHits=0,combo=0}
 Globals.initializeState(state)
 local json = loxreq 'lib.json'
 local reference = json.decode(assert(love.filesystem.read('tests/fixtures/psych-1.0.4/initialization.json')))
 for name, expected in pairs(reference) do
  local native = ({songScore='score',songMisses='misses'})[name] or name
  if expected == json.null then expected = nil end
  assert(state[native] == expected, name .. ' initialization mismatch')
 end
 assert(state.totalPlayed == 0 and state.totalNotesHit == 0)
 assert(state.ratingName == '?' and state.ratingPercent == 0 and state.ratingFC == nil)
 local values = Globals.initial(state, {speed=2.5})
 assert(values.score == 0 and values.misses == 0 and values.hits == 0 and values.combo == 0)
 assert(values.scrollSpeed == 2.5 and values.startedCountdown == false)
 for _, label in ipairs({'Player','Opponent'}) do
  for index=0,3 do
   assert(values['default'..label..'StrumX'..index] == 0)
   assert(values['default'..label..'StrumY'..index] == 0)
  end
 end
 local file = 'psych-global-initialization-fixture.lua'
 assert(love.filesystem.write(file, 'assert(score==0 and misses==0 and hits==0 and ratingName=="?")\nfunction onCreate() assert(scrollSpeed==2.5 and defaultPlayerStrumX0==0) end'))
 local ok, err = xpcall(function()
  local script = Script(file, true, false, true, function(instance)
   for key,value in pairs(values) do instance:set(key,value) end
  end)
  assert(not script.closed)
  script:call('onCreate')
  script:close()
 end,debug.traceback)
 love.filesystem.remove(file)
 assert(ok,err)
end)

check('onCreate reads PlayState counters and preserves zero strum defaults', function()
 local Globals = require 'funkin.backend.scripts.psych.globals'
 local state = Group()
 state.score,state.misses,state.songHits,state.combo = 0,0,0,0
 Globals.initializeState(state)
 local observed = {}
 local script = {closed=false,variables=Globals.initial(state,{speed=1}),set=function(self,key,value) self.variables[key]=value end,
  hasCallback=function() return true end,call=function(self,name)
   if name == 'onCreate' or name == 'onCreatePost' then
    assert(self._psych.installed.getProperty('songMisses') == 0)
    assert(self._psych.installed.getProperty('songScore') == 0)
    assert(self._psych.installed.getProperty('songHits') == 0)
    assert(self.variables.defaultPlayerStrumX0 == 0)
    observed[name] = true
   end
  end}
 script._psych = require('funkin.backend.scripts.compat').new(state,script,true)
 local handler = (require 'funkin.backend.scripts.handler')()
 handler:add(script)
 handler:call('create')
 handler:call('postCreate')
 assert(observed.onCreate and observed.onCreatePost)
end)

check('Psych rating thresholds full combo and callback ordering match original Haxe methods', function()
 local json = loxreq 'lib.json'
 local cases = json.decode(assert(love.filesystem.read('tests/fixtures/psych-1.0.4/rating.json')))
 local Globals = require 'funkin.backend.scripts.psych.globals'
 local Rating = require 'funkin.backend.scripts.psych.rating'
 for index, case in ipairs(cases) do
  local state = {score=0,misses=case.input.misses,songHits=0,combo=0}
  Globals.initializeState(state)
  state.totalPlayed,state.totalNotesHit=case.input.played,case.input.hit
  for i,hits in ipairs(case.input.hits) do state.ratingsData[i].hits=hits end
  local events = {}
  state.scripts = {set=function(_,name,value) events[#events+1]={kind='set',name=name,value=value == nil and json.null or value} end,
   call=function(_,name) events[#events+1]={kind='call',name=name};return case.input.stop and Script.Event_Cancel or Script.Event_Continue end}
  assert(Rating.recalculate(state) == nil)
  assert(state.ratingName == case.ratingName and state.ratingPercent == case.ratingPercent, 'rating case '..index)
  local fc=case.ratingFC;if fc == json.null then fc=nil end
  assert(state.ratingFC == fc, 'FC case '..index)
  assert(#events == #case.events)
  for i,event in ipairs(events) do
   local expected=case.events[i]
   assert(event.kind==expected.kind and event.name==expected.name and event.value==expected.value, 'event '..i..' case '..index)
  end
 end
end)

check('stage base coordinates initialize globals without character offsets', function()
 local Globals = require 'funkin.backend.scripts.psych.globals'
 local state = {stage={data={characters={bf={position={123,456}},dad={position={-50,60}},gf={position={700,800}}}}}}
 Globals.prepare(state,{stage='fixture'})
 local values=Globals.initial(state,{speed=1,player1='bf-fixture',player2='dad-fixture',gfVersion='gf-fixture'})
 assert(values.defaultBoyfriendX==123 and values.defaultBoyfriendY==456)
 assert(values.defaultOpponentX==-50 and values.defaultOpponentY==60)
 assert(values.defaultGirlfriendX==700 and values.defaultGirlfriendY==800)
 assert(values.boyfriendName=='bf-fixture' and values.dadName=='dad-fixture' and values.gfName=='gf-fixture')
 assert(values.Function_Stop=='##PSYCHLUA_FUNCTIONSTOP' and values.luaDebugMode==false)
 assert(values.ghostTapping==ClientPrefs.data.ghostTap and values.noteSkinPostfix=='')
 assert(values.version=='1.0.4' and type(values.difficulty)=='number')
end)

check('all 106 Psych constructor globals match the original Haxe set calls', function()
 local Globals = require 'funkin.backend.scripts.psych.globals'
 local json = loxreq 'lib.json'
 local expected=json.decode(assert(love.filesystem.read('tests/fixtures/psych-1.0.4/globals.json')))
 local previous={prefs=ClientPrefs.data,mod=Mods.currentMod,music=game.sound.music,width=game.width,height=game.height,deaths=GameOverSubstate.deaths}
 local fields={'storyMode','songDifficulty','storyWeek','seenCutscene','psychWeekIndex','psychLoadedSongName','psychDifficultyList'}
 local saved={};for _,key in ipairs(fields) do saved[key]=PlayState[key] end
 local os=love.system.getOS
 local ok,err=xpcall(function()
  ClientPrefs.data={downScroll=false,middleScroll=false,ghostTap=true,flashingLights=true,lowQuality=false,shader=true,songOffset=0}
  Mods.currentMod='fixture';GameOverSubstate.deaths=3
  game.width,game.height=1280,720;game.sound.music={duration=4.096}
  love.system.getOS=function() return 'Linux' end
  PlayState.storyMode,PlayState.songDifficulty,PlayState.storyWeek=true,'normal','fixture-week'
  PlayState.seenCutscene,PlayState.psychWeekIndex,PlayState.psychLoadedSongName=false,2,'test-song'
  PlayState.psychDifficultyList=nil
  local chart={song='Test Song',stage='fixture',speed=2.5,bpm=120,needsVoices=true,player1='bf-fixture',player2='dad-fixture',gfVersion='gf-fixture',sections={{mustHitSection=true,altAnim=false,gfSection=true}}}
  local state={score=0,misses=0,songHits=0,combo=0,psychChartPath='mods/fixture/data/test-song/test-song.json',conductor={bpm=120,crotchet=500,stepCrotchet=125,step={i=7,f=7.5},beat={i=2,f=1.875}},stage={data={characters={bf={position={123,456}},dad={position={-50,60}},gf={position={700,800}}}}}}
  Globals.initializeState(state);Globals.prepare(state,chart)
  local actual=Globals.initial(state,chart,'synthetic.lua')
  local count=0
  for name,value in pairs(expected) do
   count=count+1
   if value==json.null then value=nil end
   assert(actual[name]==value,name..': '..tostring(actual[name])..' vs '..tostring(value))
  end
  assert(count==105, 'non-null constructor entries '..count)
  assert(actual.ratingFC==nil)
 end,debug.traceback)
 ClientPrefs.data,Mods.currentMod,game.sound.music=previous.prefs,previous.mod,previous.music
 game.width,game.height,GameOverSubstate.deaths=previous.width,previous.height,previous.deaths
 love.system.getOS=os
 for _,key in ipairs(fields) do PlayState[key]=saved[key] end
 assert(ok,err)
end)

check('stopped rating hooks retain overrides and still reach score callbacks', function()
 local Globals=require 'funkin.backend.scripts.psych.globals'
 for _, stopScore in ipairs({false,true}) do
  local state=Group();state.score,state.misses,state.songHits,state.combo=70,2,3,4
  Globals.initializeState(state);state.stage={psych=true}
  local names={};local updates=0
  state.updateInformation=function() updates=updates+1 end
  local script={closed=false,variables={},set=function(self,key,value) self.variables[key]=value end,hasCallback=function() return true end}
  script.call=function(self,name)
   names[#names+1]=name
   if name=='onRecalculateRating' then
    assert(self.variables.score==70 and self.variables.misses==2 and self.variables.hits==3 and self.variables.combo==4)
    state.ratingName,state.ratingPercent,state.ratingFC='Override',.42,'Custom'
    return '##PSYCHLUA_FUNCTIONSTOP'
   elseif name=='preUpdateScore' and stopScore then return '##PSYCHLUA_FUNCTIONSTOP' end
  end
  script._psych={state=state,callbackNames={}}
  state.scripts=ScriptsHandler();state.scripts:add(script)
  PlayState.recalculateRating(state)
  assert(state.ratingName=='Override' and state.ratingPercent==.42 and state.ratingFC=='Custom')
  assert(script.variables.rating==.42 and script.variables.ratingName=='Override' and script.variables.ratingFC=='Custom')
  assert(names[1]=='onRecalculateRating' and names[2]=='preUpdateScore')
  assert(updates==(stopScore and 0 or 1))
  assert(#names==(stopScore and 2 or 3))
 end
end)

check('rating setters publish state and globals without recalculating', function()
 local state=Group();local values={}
 state.scripts={set=function(_,name,value) values[name]=value end}
 local api={};require('funkin.backend.scripts.psych.gameplay').install({state=state,script={},_active=function() end},api)
 assert(api.setRatingPercent(.42)==nil and state.ratingPercent==.42 and values.rating==.42)
 assert(api.setRatingName('Custom')==nil and state.ratingName=='Custom' and values.ratingName=='Custom')
 assert(api.setRatingFC('FC')==nil and state.ratingFC=='FC' and values.ratingFC=='FC')
end)
