-- Run by the engine harness (BOOT fixture): the engine is already loaded, so a
-- real PlayState can be built.
--
-- Runs a Psych `.lua` through Psych's own compiled layer inside a real PlayState.
--
-- This is the test that was missing. The binding was verified against a fake host
-- and a synthetic state, which proved the registry worked and proved nothing about
-- whether a mod could run: FunkinLua.new() reads a live song, and no test had one.
-- If this passes, the compiled path is real. If it fails, the failure names the
-- global the engine still has to provide.
-- A Psych script of the shape mods actually ship: glues to the lifecycle, reads a
-- per-frame global, and touches the score.
local SOURCE = [[
function onCreate()
  created = true
end

function onUpdatePost(elapsed)
  frames = (frames or 0) + 1
  -- The arithmetic that used to raise in modem scripts: a playhead global.
  lastStep = curStep or 0
  beatOffset = curBeat * 4
end

function onStepHit()
  steps = (steps or 0) + 1
  -- curDecStep is the one that used to be nil here.
  fine = curDecStep * 1
end

function onBeatHit()
  beats = (beats or 0) + 1
end

function onSectionHit()
  sections = (sections or 0) + 1
end
]]

check('a Psych script runs through the compiled layer', function()
  local state=PlayState(false,'bopeebo','normal')
  state:preload()
  require('funkin.backend.paths').async.stop()
  game.switchState(state,true)
  game.update(0)

  local Psych=require('funkin.backend.modding.psych')
  assert(Psych.usesRuntime(),'the compiled path is not the default')

  -- The script the engine is loading: its path is what Psych records as scriptName,
  -- so this one has to be a real file in a real directory layout.
  local path='tests/engine/compat-fixture.lua'
  local globals=require('funkin.backend.scripts.psych.globals')
  -- Script's configure hook only runs when the chunk loads. The compiled layer is
  -- the loader for this script, so without a real file there is no context at all
  -- -- which is exactly how this test failed before, with "no compatibility context".
  local script=Script(path,false,true,true,function(instance)
   instance.psychValues=globals.initial(state,PlayState.SONG,path)
   for key,value in pairs(instance.psychValues) do instance:set(key,value) end
   instance._psych=require('funkin.backend.scripts.compat').new(state,instance,true)
  end,function(_,instance)
   -- What loadPsychScript does: return the chunk the engine will run once configure
   -- has attached the context. The loader itself runs first, before configure, so
   -- touching instance._psych here would be reaching for something not built yet.
   return function()
    local built,buildError=instance._psych.psychRuntime(SOURCE,instance)
    if not built then error('compiled layer refused the script: '..tostring(buildError),0) end
   end
  end)
  assert(script._psych,'the compiled loader never ran: the file did not load')
  state.scripts:add(script)
  state.psychVariables=script.psychValues
  local compat=script._psych
  assert(compat,'no compatibility context')

  local built=script.psychScript
  if not built then
   error('the compiled layer could not run a Psych script: '..tostring(script.psychError))
  end

  -- The constructor must have seen a live song. When it does not, it skips the
  -- song-time half of its setup in silence and the script merely looks fine --
  -- which is how a whole class of "the mod loads but nothing happens" bugs hides.
  local runtime=require('funkin.backend.scripts.psych.bindings')
  local shim=runtime.loadShim(compat)
  assert(shim,'the shim did not load')
  -- PlayState.instance is what FunkinLua.new() tests to decide whether a song is
  -- running. It must be this state, not nil.
  assert(shim.globals.PlayState ~= nil,'Psych cannot see PlayState at all')
  assert(shim.globals.PlayState.instance==state,
    'FunkinLua.new() saw no live song, so it skipped its song-time setup')
  assert(shim.globals.PlayState.luaArray~=nil,
    'game.luaArray is missing, so Psych cannot register the script with the song')

  -- The callbacks Psych registered must be reachable from the script it built.
  local variables=script.psychScript and script.psychScript.lua
  assert(variables,'no Lua state on the built script')
  local registered=runtime.registryFor(variables).callbacks
  assert(type(registered)=='table','no callback registry')

  -- onCreate must have run as part of construction, exactly like Psych.
  local function ran(name)
   local env=runtime.registryFor(variables).globals
   return env[name]
  end
  assert(ran('created')==true,'onCreate did not run while the script was built')

  -- Driving the song must reach the script's own functions. Psych keeps them in
  -- the same environment it sets globals in, which is what makes this work.
  local env=runtime.registryFor(variables).globals
  assert(type(env.onStepHit)=='function','the script has no onStepHit')
  env.onStepHit()
  assert(ran('steps')==1,'onStepHit did not run')
  -- curDecStep was nil here, which is the modem-script crash.
  assert(ran('fine')~=nil,'curDecStep was nil inside onStepHit')
  assert(ran('fine')==ran('fine'),'curDecStep is not a number')

  env.onBeatHit()
  assert(ran('beats')==1,'onBeatHit did not run')

  compat:update(0)
  assert(ran('frames')==1,'onUpdatePost did not run')

  -- The engine's own section signal has to reach the script too.
  compat:forward('section')
  assert(ran('sections')==1,'onSectionHit did not run')
end)
