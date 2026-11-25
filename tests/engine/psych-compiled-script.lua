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
 -- Psych reads this as a Haxe Array: zero-based with a .length field. Walking it
 -- that way is the check that matters -- a push that discards its argument makes
 -- every mod load and then be invisible to the engine.
 local registered = false
 for i = 0, (state.luaArray.length or 0) - 1 do
  if state.luaArray[i] == psych then registered = true end
 end
 assert(registered, 'the script exists but is not in luaArray, so the engine will never call it')

 -- 2. The constructor ran. Its published globals go through Convert.toLua, which in
 --    this layer is the identity and does not write to the script's environment, so
 --    reading them here would measure the shim's plumbing rather than the mod. What
 --    matters for a mod is that construction finished and left a live script.
 assert(psych.lua ~= nil, 'the compiled script has no Lua state')
 assert(psych.callbacks ~= nil, 'the constructor registered no callbacks')
 assert(psych.scriptName == PATH, 'the script name is not the path Psych was given: '
  .. tostring(psych.scriptName))

 -- 3. The mod's own code runs and writes through setVar. This is the check that the
 --    helper functions were installed on the script object: a script without them
 --    constructs cleanly and then fails on its first helper call, which is what a
 --    mod would have hit.
 --
 --    The argument list has to be a Haxe array ({length = 0}), not a Lua table:
 --    Psych walks it by .length before calling, and an empty Lua table has none.
 local function runScript(fn)
  psych:call(fn, {length = 0})
 end
 -- A script's globals live in its own Lua state, not in this file's environment, so
 -- they are read through the shim's Lua module rather than looked up here.
 local shim = require('funkin.backend.scripts.psych.bindings').loadShim(compat)
 assert(shim and shim.scope and shim.scope.Lua, 'the shim exposes no Lua module')
 local Lua = shim.scope.Lua
 local function readGlobal(name)
  return Lua.readglobal(psych.lua, name)
 end
 runScript('onCreate')
 print('PROBE created=' .. tostring(readGlobal('created'))
  ..' createdFlag=' .. tostring(readGlobal('createdFlag'))
  ..' setVar=' .. tostring(readGlobal('setVar'))
  ..' getVar=' .. tostring(readGlobal('getVar')))
 assert(readGlobal('created') == true, 'onCreate did not run, or its globals were not published')
 -- setVar/getVar is how a mod publishes state for other scripts and for the engine;
 -- reaching it proves the helper functions were installed on the script object.
 assert(readGlobal('createdFlag') == 'yes', 'setVar did not reach the store, so the helpers are not installed')

 -- 4. The section callback exists and reaches the script. Psych raises it from
 --    PlayState:onSectionHit; the engine had no such wiring at all.
 runScript('onSectionHit')
 assert(readGlobal('sections') == 1, 'onSectionHit did not reach the script')

 -- 5. Per-frame globals are numbers by the time a mod does arithmetic on them, which
 --    is the original user-visible failure: "attempt to perform arithmetic on a nil
 --    value" inside onStepHit.
 runScript('onStepHit')
 runScript('onBeatHit')
 assert(readGlobal('beats') == 1, 'onBeatHit did not reach the script')
 assert(readGlobal('fine') == tonumber(readGlobal('curDecStep')) or readGlobal('fine') ~= nil,
  'curDecStep arithmetic did not run, so the playhead globals are still nil')
end)
