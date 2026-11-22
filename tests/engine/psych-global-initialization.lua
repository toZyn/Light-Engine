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
