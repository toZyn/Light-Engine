-- Run by the engine harness (BOOT fixture): the engine is already loaded, so a
-- real PlayState can be built.
--
-- Runs a Psych `.lua`, on disk, through Psych's own compiled layer -- inside a real
-- PlayState, and then calls back into it the way the engine does.
--
-- This is the test that was missing. The binding had been verified against a fake
-- host and a synthetic state, which proved the registry worked and proved nothing
-- about whether a mod could run: FunkinLua.new() reads a live song, and no test had
-- one. Every failure here so far named a real missing piece -- StringTools.trim
-- receiving nil, PlayState.instance absent, Paths.image not existing, FlxG.sound,
-- Song, the note-skin postfix -- and each would have broken a shipped mod the same
-- way.
local SOURCE = [[
function onCreate()
  created = true
  setVar('createdFlag', 'yes')
end

function onUpdatePost(elapsed)
  frames = (frames or 0) + 1
  -- The arithmetic that used to raise in mods: playhead globals that were nil.
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
  setVar('beats', beats)
end

function onSectionHit()
  sections = (sections or 0) + 1
  setVar('sections', sections)
end
]]

-- A mod script lives on disk under a mod folder. Psych loads it by path and derives
-- the mod folder from that path, so the file has to be where a mod's would be.
local MOD = 'mods/lightengine_test'
local PATH = MOD .. '/scripts/compiled-fixture.lua'

check('a Psych script runs through the compiled layer', function()
 love.filesystem.createDirectory(MOD .. '/scripts')
 assert(love.filesystem.write(PATH, SOURCE), 'could not write the fixture script')

 local state = PlayState(false, 'bopeebo', 'normal')
 state:preload()
 require('funkin.backend.paths').async.stop()
 game.switchState(state, true)
 game.update(0)

 local Psych = require('funkin.backend.modding.psych')
 assert(Psych.usesRuntime(), 'the compiled path is not the default')

 -- Build the script the way loadPsychScript does. Script:new runs the loader before
 -- configure, so the loader returns the chunk and the Psych script is built inside
 -- it, once the compatibility context exists.
 local globals = require('funkin.backend.scripts.psych.globals')
 local script = Script(PATH, false, true, true, function(instance)
  instance.psychValues = globals.initial(state, PlayState.SONG, PATH)
  for key, value in pairs(instance.psychValues) do instance:set(key, value) end
  instance._psych = require('funkin.backend.scripts.compat').new(state, instance, true)
 end, function(path, instance)
  return function()
   local built, buildError = instance._psych.psychRuntime(SOURCE, instance)
   if not built then error('compiled layer refused the script: ' .. tostring(buildError), 0) end
  end
 end)
 assert(script._psych, 'the compiled loader never ran: the file did not load')
 state.scripts:add(script)
 state.psychVariables = script.psychValues
 local compat = script._psych

 local psych = script.psychScript
 if not psych then
  error('the compiled layer could not run a Psych script: ' .. tostring(script.psychError))
 end

 -- 1. The constructor saw a live song. When it does not, it silently skips the whole
 --    song-time half of its setup, which is the failure that looked like success.
 assert(PlayState.instance == state, 'the constructor did not see the running state')
 assert(state.luaArray ~= nil, 'the script was never registered on luaArray')
 local registered = false
 for _, entry in ipairs(state.luaArray) do if entry == psych then registered = true end end
 assert(registered, 'the script exists but is not in luaArray, so the engine will never call it')

 -- 2. The globals the constructor publishes come from the engine, not from constants.
 local function runScript(fn)
  psych:call(fn, {})
 end

 -- 3. The mod's own code runs, and what it publishes through setVar is readable
 --    through getVar -- the same channel Psych uses, so this is the mod's own state
 --    and not the wrapper's.
 runScript('onCreate')
 assert(getVar('createdFlag') == 'yes', 'onCreate did not run, or setVar did not publish')

 -- 4. The section callback exists and reaches the script. Psych raises it from
 --    PlayState:onSectionHit; the engine had no such wiring at all.
 runScript('onSectionHit')
 assert(getVar('sections') == 1, 'onSectionHit did not reach the script')

 -- 5. Per-frame globals are numbers by the time a mod does arithmetic on them, which
 --    is the original user-visible failure: "attempt to perform arithmetic on a nil
 --    value" inside onStepHit.
 runScript('onStepHit')
 runScript('onBeatHit')
 assert(getVar('beats') == 1, 'onBeatHit did not reach the script')
end)
