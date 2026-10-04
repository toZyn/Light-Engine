-- Run as main.lua in an isolated LÖVE directory, with ENGINE_ROOT naming checkout.
local root = os.getenv('ENGINE_ROOT') or '/workspace/Light-Engine-advanced'
package.path = root .. '/?.lua;' .. root .. '/?/init.lua;' .. package.path
local function contains(text, part) assert(tostring(text):find(part, 1, true), tostring(text)) end
local function test()
 love.filesystem.setIdentity('light-engine-async-tests')
 local workerFile = assert(io.open(root .. '/funkin/backend/paths/thread.lua', 'r'))
 local workerCode = workerFile:read('*a'); workerFile:close()
 love.filesystem.createDirectory('funkin/backend/paths')
 love.filesystem.write('funkin/backend/paths/thread.lua', workerCode)
 dofile(root .. '/loxel/lib/override.lua')
 if os.getenv('ASYNC_MOBILE') == '1' then love.system.getDevice = function() return 'Mobile' end end
 local logLines = {}
 Logger = dofile(root .. '/loxel/system/logger.lua')
 Logger.print = function(text) logLines[#logLines + 1] = text end
 Toast = {showDeprecations = false}
 love.filesystem.write('https.lua', 'return true') -- valid require result, unusable transport
 local image = love.image.newImageData(2, 2)
 image:encode('png', 'async-processor.png')
 for i = 1, 16 do image:encode('png', 'async-image-' .. i .. '.png') end
 image:release()
 local function le(n, length)
  local bytes = {}; for i = 1, length do bytes[i] = string.char(n % 256); n = math.floor(n / 256) end
  return table.concat(bytes)
 end
 local wav = 'RIFF' .. le(36 + 256, 4) .. 'WAVEfmt ' .. le(16, 4) .. le(1, 2) .. le(1, 2)
  .. le(8000, 4) .. le(16000, 4) .. le(2, 2) .. le(16, 2) .. 'data' .. le(256, 4) .. string.rep('\0', 256)
 love.filesystem.write('async-sound.wav', wav)
 paths = {images = {}, audio = {}, atlases = {}, animate_atlases = {}, compressedSupport = {}, getPath = function(k) return k end,
  exists = function(k) return love.filesystem.getInfo(k) ~= nil end}
 local A = require 'funkin.backend.paths.async'; paths.async = A
 local callbacks = 0
 for i = 1, 16 do A.queueTask('image', 'async-image-' .. i .. '.png', function(data, err)
  assert(data and data:getWidth() == 2, tostring(err)); callbacks = callbacks + 1
 end) end
 assert(type(A.getStats) == 'function', 'async must expose bounded-dispatch stats')
 local stats = A.getStats()
 local expectedWorkers = os.getenv('ASYNC_MOBILE') == '1' and 2 or 4
 assert(stats.maxWorkers == expectedWorkers, 'platform worker cap mismatch')
 assert(stats.workers <= expectedWorkers and stats.inFlight <= expectedWorkers, 'worker and dispatched buffers must be bounded')
 local deadline = love.timer.getTime() + 8
 local function pump(untilDone)
  while not untilDone() do
   assert(love.timer.getTime() < deadline, 'async test stalled')
   local before = callbacks; A.update(0.016)
   assert(callbacks - before <= A.getStats().maxUploads, 'image uploads must be limited per tick')
   love.timer.sleep(0.002)
  end
 end
 pump(function() return callbacks == 16 end)
 assert(A.getProgress() == 1, 'local loads with broken HTTPS must finish')
 local duplicateFinished = false
 local cachedDuplicate = paths.images['async-image-9.png']
 A.queueTask('image', 'async-image-9.png')
 A.queueTask('image', 'async-image-9.png', function(data) assert(data == cachedDuplicate); duplicateFinished = true end)
 assert(A.getStats().queued == 1, 'tasks without callbacks must still deduplicate')
 pump(function() return duplicateFinished end)
 local errors = 0
 A.queueTask('text', 'https://transport.invalid/test', function(data, err) assert(not data); contains(err, 'HTTPS'); errors = errors + 1 end)
 A.queueTask('image', 'missing.png', function(data, err) assert(not data and err); errors = errors + 1 end)
 pump(function() return errors == 2 end)
 assert(A.getProgress() == 1 and A.getStats().failed == 2, 'failed tasks must complete progress')
 assert(#logLines >= 2, 'worker failures must reach the real Logger')
 assert(type(A.getStats().lastError) == 'table', 'failure diagnostics must be structured')
 local newImage = love.graphics.newImage
 love.graphics.newImage = function() error('GPU upload test failure') end
 local processorError
 A.queueTask('image', 'async-processor.png', function(data, err) assert(not data); processorError = err end)
 pump(function() return processorError ~= nil end)
 love.graphics.newImage = newImage
 contains(processorError, 'GPU upload test failure')
 assert(A.getStats().lastError.kind == 'processor' and A.getProgress() == 1, 'processor failure must complete progress')
 A.stop()
 -- Restart workers with a real deterministic HTTP mock; no network required.
 love.filesystem.write('https.lua', [[return {request = function(url)
 if url:find('slow', 1, true) then love.thread.getChannel('async_test_requests'):push(true); love.timer.sleep(0.2) end
 if url:find('audio', 1, true) then return 200, love.filesystem.read('async-sound.wav') end
 return 200, love.filesystem.read('async-image-1.png')
 end}]])
 local audio
 A.queueTask('audio', 'https://mock.invalid/audio.wav', function(data, err) assert(data, tostring(err)); audio = data end)
 pump(function() return audio ~= nil end)
 assert(audio:typeOf('Source') and audio:getChannelCount() == 1, 'remote streamed audio must return a usable Source')
 local slowCallbacks = 0
 local requests = love.thread.getChannel('async_test_requests'); requests:clear()
 for i = 1, expectedWorkers do A.queueTask('image', 'https://mock.invalid/slow' .. i .. '.png', function() slowCallbacks = slowCallbacks + 1 end) end
 while requests:getCount() < expectedWorkers do
  assert(love.timer.getTime() < deadline, 'slow HTTP workers did not start')
  -- Retiring workers can temporarily consume slots; update must observe their
  -- exit and dispatch the queued requests before waiting on this barrier.
  A.update(0.016)
  love.timer.sleep(0.002)
 end
 assert(slowCallbacks == 0, 'requests must still be blocked at cancellation')
 local stopStart = love.timer.getTime(); A.stop()
 assert(love.timer.getTime() - stopStart < 0.15, 'stop must not wait for blocked HTTP workers')
 local slowRestart = false
 A.queueTask('image', 'async-image-1.png', function(data) assert(data); slowRestart = true end)
 local capped = A.getStats()
 assert(capped.workers + capped.retiringWorkers <= expectedWorkers, 'restarts must not exceed global worker cap')
 pump(function() return slowRestart end)
 assert(slowCallbacks == 0, 'late HTTP results must not call cancelled callbacks')
 local cancelled = 0
 for i = 1, 16 do A.queueTask('image', 'async-image-' .. i .. '.png', function() cancelled = cancelled + 1 end) end
 A.stop()
 assert(A.getProgress() == 1 and A.getStats().inFlight == 0, 'stop must reset progress and callbacks')
 local restarted = false
 A.queueTask('image', 'async-image-1.png', function(data) assert(data); restarted = true end)
 pump(function() return restarted end)
 assert(cancelled == 0, 'cancelled callbacks must never reappear after restart')
 local callbackError
 A.queueTask('image', 'async-image-2.png', function() error('callback boom') end)
 while not callbackError do
  assert(love.timer.getTime() < deadline, 'callback failure stalled')
  local ok, err = pcall(A.update, 0.016); if not ok then callbackError = err end
  love.timer.sleep(0.002)
 end
 contains(callbackError, 'callback boom'); contains(callbackError, 'async-image-2.png')
 assert(A.getProgress() == 1, 'fatal callback still completes bookkeeping')
 -- Exercise the actual paths.clearCache integration, not a test substitute.
 local cachedImages, cachedAudio = paths.images, paths.audio
 local oldLoxreq, oldMods, oldAddons = loxreq, Mods, Addons
 local oldAnimate = package.loaded['funkin.backend.animatelibrary']
 loxreq = function(name) if name == 'lib.json' then return dofile(root .. '/loxel/lib/json.lua') end; return {} end
 Mods, Addons = {root = 'mods'}, {root = 'addons', all = {}}
 package.loaded['funkin.backend.animatelibrary'] = {}
 paths = require 'funkin.backend.paths'
 paths.images, paths.audio = cachedImages, cachedAudio
 local cacheCallback = 0
 A.queueTask('image', 'async-image-3.png', function() cacheCallback = cacheCallback + 1 end)
 local oldImage = paths.images['async-image-1.png']
 paths.clearCache()
 assert(not next(paths.images) and not next(paths.audio), 'clearCache must release caches')
 assert(not pcall(oldImage.getWidth, oldImage), 'clearCache must release old cached image')
 local afterClear = false
 A.queueTask('image', 'async-image-1.png', function(data) assert(data); afterClear = true end)
 pump(function() return afterClear end)
 assert(cacheCallback == 0, 'clearCache must cancel before releasing callback targets')
 local oldClassic, oldBasic = Classic, Basic
 Classic = dofile(root .. '/loxel/lib/classic.lua')
 Basic = dofile(root .. '/loxel/basic.lua')
 loxreq = function(name) return dofile(root .. '/loxel/' .. name:gsub('%.', '/') .. '.lua') end
 love.filesystem.createDirectory('assets/images/async-atlas')
 love.filesystem.write('assets/images/async-atlas/Animation.json', '{"ANIMATION":{"TIMELINE":{"LAYERS":[]}},"SYMBOL_DICTIONARY":{"Symbols":[]}}')
 love.filesystem.write('assets/images/async-atlas/spritemap.json', '{"ATLAS":{"SPRITES":[]}}')
 local atlasImage = love.image.newImageData(2, 2)
 atlasImage:encode('png', 'assets/images/async-atlas/spritemap.png'); atlasImage:release()
 package.loaded['funkin.backend.animatelibrary'] = nil
 local loadedAtlas
 A.getAnimateAtlas('async-atlas', function(atlas) loadedAtlas = atlas end)
 pump(function() return loadedAtlas ~= nil end)
 assert(loadedAtlas.loaded and #loadedAtlas.spritemaps == 1 and loadedAtlas.spritemaps[1].texture:getWidth() == 2, 'real AnimateLibrary async callback must load its texture')
 Classic, Basic = oldClassic, oldBasic
 loxreq, Mods, Addons = oldLoxreq, oldMods, oldAddons
 package.loaded['funkin.backend.animatelibrary'] = oldAnimate
 A.stop()
 for _, value in pairs(paths.images) do value:release() end
 for _, value in pairs(paths.audio) do value:release() end
 love.event.clear()
 print('ASYNC PASSED: bounded workers/uploads, broken HTTPS local loads, failures/progress, remote Source, stop/restart, cache clear, AnimateLibrary and contextual callback errors')
end
function love.load()
 local ok, err = xpcall(test, debug.traceback)
 if not ok then print('ASYNC FAIL: ' .. tostring(err)) end
 love.event.quit(ok and 0 or 1)
end
function love.errorhandler(message) print(message); return function() return 1 end end
