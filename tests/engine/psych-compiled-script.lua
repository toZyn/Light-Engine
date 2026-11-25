-- Run by the engine harness (BOOT fixture): the engine is already loaded, so a
-- real PlayState can be built.
--
-- Runs a Psych `.lua`, on disk, through Psych's own compiled layer -- inside a real
-- PlayState -- and calls back into it the way the engine does.
--
-- This is the test that was missing. The binding had been verified against a fake
-- host and a synthetic state, which proved the registry worked and proved nothing
-- about whether a mod could run: FunkinLua.new() reads a live song, and no test had
-- one. Every failure here named a real missing piece -- StringTools.trim receiving
-- nil, PlayState.instance, Paths.image, FlxG.sound, Song, the note-skin postfix,
-- psychlua, FileSystem, MusicBeatState -- and each would have broken a shipped mod
-- the same way.
local SOURCE = [[
function onCreate()
  created = true
  setVarType = type(setVar)
  local ok, err = pcall(function() setVar('createdFlag', 'yes') end)
  setOk, setErr = ok, tostring(err)
  local ok2, value = pcall(function() return getVar('createdFlag') end)
  getOk, getValue = ok2, tostring(value)
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

 -- 1. The constructor saw a live song and registered the script where the engine
 --    looks. When it does not see a song it silently skips the whole song-time half
 --    of its setup, which is the failure that looked like success.
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

 -- 2. Construction finished and left a live script, named by its path.
 assert(psych.lua ~= nil, 'the compiled script has no Lua state')
 assert(psych.callbacks ~= nil, 'the constructor registered no callbacks')
 assert(psych.scriptName == PATH, 'the script name is not the path Psych was given: '
  .. tostring(psych.scriptName))

 -- A script's globals live in its own Lua state, not in this file's environment, so
 -- they are read through the shim's Lua module. The argument list below has to be a
 -- Haxe array ({length = 0}): Psych walks it by .length before calling.
 local shim = require('funkin.backend.scripts.psych.bindings').loadShim(compat)
 assert(shim and shim.scope and shim.scope.Lua, 'the shim exposes no Lua module')
 local Lua = shim.scope.Lua
 local function readGlobal(name)
  return Lua.readglobal(psych.lua, name)
 end
 local function runScript(fn)
  psych:call(fn, {length = 0})
 end

 -- 3. The mod's own code runs.
 runScript('onCreate')
 assert(readGlobal('created') == true, 'onCreate did not run, or its globals were not published')

 -- setVar/getVar is how a mod publishes state for other scripts and for the engine.
 -- It is also the only signal that the helper functions were installed on the script
 -- object: such a script constructs cleanly and then dies on its first helper call.
 -- setVar does not create a global -- it writes to the store getVar reads -- so this
 -- is a round trip, not a global lookup.
 local getter = readGlobal('getVar')
 assert(type(getter) == 'function', 'getVar was not registered on the script')
 local stored = getter('createdFlag')
 assert(stored == 'yes', 'setVar did not reach the store getVar reads, got ' .. tostring(stored))

 -- 4. The section callback exists and reaches the script. Psych raises it from
 --    PlayState:onSectionHit; the engine raised no such signal at all.
 runScript('onSectionHit')
 assert(getter('sections') == 1, 'onSectionHit did not reach the script')

 -- 5. The playhead globals are numbers by the time a mod does arithmetic on them.
 --    This is the original user-visible failure: "attempt to perform arithmetic on a
 --    nil value" inside onStepHit. The refresh runs through the compatibility
 --    context, which is what the engine calls every frame.
 compat:update(0.016)
 assert(type(readGlobal('curDecStep')) == 'number',
  'curDecStep is not published into the script: ' .. tostring(readGlobal('curDecStep')))
 assert(type(readGlobal('curBeat')) == 'number', 'curBeat is not published into the script')

 runScript('onStepHit')
 runScript('onBeatHit')
 assert(getter('beats') == 1, 'onBeatHit did not reach the script')
 assert(readGlobal('fine') ~= nil, 'onStepHit raised, so curDecStep arithmetic is still broken')
end)
