-- Run as the main.lua of an isolated LÖVE test directory. ENGINE_ROOT names the checkout.
local root = os.getenv('ENGINE_ROOT') or '/workspace/Light-Engine-advanced'
package.path = root .. '/?.lua;' .. root .. '/?/init.lua;' .. package.path
local function contains(text, needle)
 assert(text and text:find(needle, 1, true), 'missing diagnostic text: ' .. needle)
end
local function test()
 -- Also exercise missing-context startup in runners using a default window.
 if love.window then love.window.close() end
 love.filesystem.setIdentity('light-engine-diagnostics-tests')
 for _, name in ipairs({'session.active', 'engine.log', 'engine.previous.log', 'last-error.txt'}) do
  love.filesystem.remove('diagnostics/' .. name)
 end
 local D = require 'funkin.backend.diagnostics'
 D.start()
 assert(love.filesystem.getInfo('diagnostics/session.active'), 'startup must leave a session marker')
 D.checkpoint('song: blueballed')
 contains(love.filesystem.read('diagnostics/session.active'), 'song: blueballed')
 local clean = package.loaded['funkin.backend.diagnostics']
 package.loaded['funkin.backend.diagnostics'] = nil
 D = require 'funkin.backend.diagnostics'
 D.start()
 contains(love.filesystem.read('diagnostics/engine.log'), 'Previous session interrupted')
 contains(love.filesystem.read('diagnostics/engine.log'), 'song: blueballed')
 local log = love.filesystem.read('diagnostics/engine.log')
 D.start() -- repeated starts in one session must not mislabel a crash
 assert(love.filesystem.read('diagnostics/engine.log') == log, 'start must be idempotent')
 D.report('bad byte ' .. string.char(255), 'full traceback\nlast frame')
 local saved = love.filesystem.read('diagnostics/last-error.txt')
 contains(saved, 'full traceback\nlast frame')
 contains(saved, '\\xFF')
 for _, invalid in ipairs({string.char(192, 175), string.char(237, 160, 128), string.char(244, 144, 128, 128), string.char(226, 130)}) do
  local escaped = D.sanitize(invalid)
  assert(require('utf8').len(escaped), 'malformed multi-byte sequence must be sanitized')
  contains(escaped, '\\x')
 end
 assert(D.sanitize('café Ω') == 'café Ω', 'valid UTF-8 must survive')
 D.checkpoint('steady')
 log = love.filesystem.read('diagnostics/engine.log')
 D.checkpoint('steady')
 assert(love.filesystem.read('diagnostics/engine.log') == log, 'same checkpoint must be throttled')
 assert(require('utf8').len(saved), 'saved display text must be valid UTF-8')
 -- Storage denial must not replace the actual gameplay error or prevent
 -- startup/checkpoints/normal shutdown. Test both native-style nil returns
 -- and raised I/O errors; no Android external-storage permission is needed.
 local originalWrite, originalAppend, originalMkdir = love.filesystem.write, love.filesystem.append, love.filesystem.createDirectory
 for _, raised in ipairs({false, true}) do
  D.finish()
  local function denied()
   if raised then error('permission denied: read-only storage') end
   return nil, 'permission denied: read-only storage'
  end
  love.filesystem.write, love.filesystem.append, love.filesystem.createDirectory = denied, denied, denied
  local storageOK, storageError = xpcall(function()
   D.start(); D.checkpoint('end-song storage-denied probe')
   local report = D.report('original end-song failure', 'original gameplay traceback')
   contains(report, 'original end-song failure'); contains(report, 'original gameplay traceback')
   contains(report, 'report could not be saved')
   assert(not report:find('\nReport:', 1, true), 'failed storage must not advertise a nonexistent saved report')
   local loop = D.errorHandler('original end-song failure', 'original gameplay traceback', report)
   assert(type(loop) == 'function', 'storage denial must leave the error handler usable')
   love.event.clear(); love.event.push('keypressed', 'escape')
   assert(loop() == 1, 'storage denial must not prevent exit from the error screen')
   D.finish()
  end, debug.traceback)
  love.filesystem.write, love.filesystem.append, love.filesystem.createDirectory = originalWrite, originalAppend, originalMkdir
  assert(storageOK, storageError)
 end
 -- Real filesystem obstruction: diagnostics exists as a regular file.
 D.finish()
 for _, name in ipairs({'session.active','engine.log','engine.previous.log','last-error.txt'}) do love.filesystem.remove('diagnostics/' .. name) end
 assert(love.filesystem.remove('diagnostics'))
 assert(love.filesystem.write('diagnostics', 'not a directory'))
 D.start(); D.checkpoint('blocked-directory probe')
 local obstruction = D.report('original blocked-directory error', 'preserved trace')
 contains(obstruction, 'original blocked-directory error'); contains(obstruction, 'report could not be saved')
 D.finish()
 assert(love.filesystem.remove('diagnostics'))
 D.start()
 -- Match engine conf.lua: diagnostics have run without a window/context.
 require('love.window')
 assert(love.window.setMode(800, 600))
 local originalGraphics = love.graphics
 local oldPaths = paths
 paths = {async = {stop = function() error('shutdown asset failure') end}, getImage = function() error('mod asset failure') end}
 local file = assert(io.open(root .. '/funkin/init.lua', 'r')); local source = file:read('*a'); file:close()
 local handlerSource = assert(source:match('(function funkin%.throwError.-)\nreturn funkin'))
 local throw = assert(loadstring('local funkin = {}\n' .. handlerSource .. '\nreturn funkin.throwError'))()
 local loop = throw('missing mod image ' .. string.char(255))
 assert(type(loop) == 'function', 'asset-independent fallback must return an error loop')
 contains(love.filesystem.read('diagnostics/last-error.txt'), 'missing mod image')
 love.event.clear()
 love.event.push('keypressed', 'r')
 assert(loop() == 'restart', 'error screen must restart by keyboard')
 love.event.push('keypressed', 'c')
 loop()
 contains(love.system.getClipboardText(), 'missing mod image')
 love.event.push('keypressed', 'escape')
 assert(loop() == 1, 'error screen must quit by keyboard')
 loop = throw('touch fallback')
 love.event.clear()
 local _, height = love.graphics.getDimensions()
 love.event.push('touchpressed', 'test', love.graphics.getWidth() * 0.5, height - 20)
 assert(loop() == 'restart', 'error screen must restart by touch')
 love.event.push('touchpressed', 'test', love.graphics.getWidth() * 0.9, height - 20)
 assert(loop() == 1, 'error screen must quit by touch')
 love.event.push('touchpressed', 'test', love.graphics.getWidth() * 0.1, height - 20)
 loop()
 contains(love.system.getClipboardText(), 'touch fallback')
 love.graphics = nil -- report must survive missing graphics entirely
 loop = throw('no graphics')
 contains(love.filesystem.read('diagnostics/last-error.txt'), 'no graphics')
 assert(type(loop) == 'function')
 love.graphics = originalGraphics
 local oldSetMode = love.window.setMode
 love.window.close()
 love.window.setMode = function() return false end
 loop = throw('window creation failed')
 assert(type(loop) == 'function', 'failed native-window creation needs an event-only fallback')
 contains(love.filesystem.read('diagnostics/last-error.txt'), 'window creation failed')
 love.window.setMode = oldSetMode
 assert(love.window.setMode(800, 600))
 paths = oldPaths
 -- Main hooks are tested without initializing mods or loading assets.
  local oldGame, oldFunkin = game, package.loaded.funkin
 local oldLoxel, oldPreload = package.loaded.loxel, package.preload.loxel
 game = nil
 package.loaded.loxel = nil
 package.preload.loxel = function() error('startup loader broke') end
 local startupOK, startupError = pcall(dofile, root .. '/main.lua')
 assert(not startupOK, 'startup dependency failure must propagate')
 assert(type(love.errorhandler(startupError)) == 'function', 'startup error needs early fallback')
 contains(love.filesystem.read('diagnostics/last-error.txt'), 'startup loader broke')
 package.preload.loxel = oldPreload
 game = {quit = function() end, getState = function() return nil end}
 package.loaded.loxel = true
 package.loaded.funkin = {quit = function() end, throwError = throw}
 local collections = 0
 local oldGC = collectgarbage
 collectgarbage = function(mode) if mode == 'collect' then collections = collections + 1 end; return oldGC(mode) end
 dofile(root .. '/main.lua')
 local live = love.graphics.newImage(love.image.newImageData(2, 2))
 love.lowmemory()
 assert(collections > 0, 'low-memory callback must collect Lua garbage')
 assert(live:getWidth() == 2, 'low-memory callback must leave live textures usable')
 local worker = love.thread.newThread([[error('worker boom: real thread')
]])
 worker:start(); worker:wait()
 local workerError = assert(worker:getError(), 'real worker must fail')
 local ok, err = pcall(love.threaderror, worker, workerError)
 assert(not ok, 'worker failure must propagate')
 contains(tostring(err), 'worker boom')
 contains(love.filesystem.read('diagnostics/last-error.txt'), 'worker boom')
 collectgarbage = oldGC
 love.quit()
 assert(not love.filesystem.getInfo('diagnostics/session.active'), 'normal quit removes marker')
 package.loaded.funkin = oldFunkin; package.loaded.loxel = oldLoxel; game = oldGame
 love.event.clear() -- the deliberately failed worker also queued a threaderror event
 package.loaded['funkin.backend.diagnostics'] = clean
 print('DIAGNOSTICS PASSED: markers, reentrancy, full errors, invalid UTF-8, missing assets/graphics, keyboard/touch, thread errors and low-memory live texture')
end
function love.load()
 local ok, err = xpcall(test, debug.traceback)
 if not ok then print('DIAGNOSTICS FAIL: ' .. tostring(err)) end
 love.quit = nil -- main.lua hooks above must not run again after test cleanup
 love.errorhandler = function(msg) print(msg); return function() return 1 end end
 love.event.quit(ok and 0 or 1)
end
function love.errorhandler(msg) print(msg); return function() return 1 end end
