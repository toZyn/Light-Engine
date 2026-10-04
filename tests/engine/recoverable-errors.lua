-- Run as main.lua in a temporary LÖVE checkout runner.
require 'loxel'
require 'funkin'
local function contains(text, needle) assert(text and text:find(needle, 1, true), 'missing original error: ' .. needle) end
-- Windows clipboard text uses CRLF; report files retain their original bytes.
local function clipboardText() return love.system.getClipboardText():gsub('\r\n', '\n') end
function love.load()
 local ok, err = xpcall(function()
  love.window.setMode(320, 240, {vsync = 0}); game.width, game.height = 320, 240
  love.filesystem.setIdentity('light-engine-recoverable-error-tests')
  local R = require 'funkin.backend.recoverable-errors'
  assert(not Toast.font, 'fixture must start before Toast initialization')
  local clock, nativeTime = 100, love.timer.getTime
  love.timer.getTime = function() return clock end
  local first = R.report('original optional error ' .. string.char(255), 'full original trace\nlast original frame', {source = 'optional-module'})
  assert(first.persisted and first.copied and first.queued and not first.duplicate)
  contains(love.filesystem.read('diagnostics/last-error.txt'), 'full original trace\nlast original frame')
  contains(clipboardText(), 'full original trace\nlast original frame')
  contains(first.report, '\\xFF')
  local saved = love.filesystem.read('diagnostics/last-error.txt')
  for i = 1, 100 do assert(R.report('original optional error ' .. string.char(255), 'full original trace\nlast original frame', {source = 'optional-module'}).duplicate) end
  assert(love.filesystem.read('diagnostics/last-error.txt') == saved, 'duplicates must not replace original diagnostics')
  assert(R.getStats().pending == 1 and R.getStats().deduplicated == 100, 'error flood must deduplicate queued notifications')
  Toast.init(320, 240)
  local before = #Toast.instances
  R.update()
  assert(#Toast.instances == before + 1 and R.getStats().pending == 0, 'queued startup error must use the existing Toast UI')
  for i = 1, 30 do R.report('distinct optional error ' .. i, 'trace ' .. i, {source = 'flood'}) end
  assert(R.getStats().pending <= 8 and R.getStats().dropped > 0, 'unique notification floods must have bounded backlog')
  assert(#Toast.instances == before + 1, 'notifications must respect global rate limit')
  assert(R.getStats().copied == 1, 'automatic clipboard writes must be rate limited')
  clock = clock + 2.1; R.update()
  assert(#Toast.instances == before + 2, 'only one queued notification may flush per interval')
  contains(love.system.getClipboardText(), 'distinct optional error 30')
  contains(love.system.getClipboardText(), 'trace 30')
  local nativeClipboard = love.system.setClipboardText
  love.system.setClipboardText = function() error('clipboard provider unavailable') end
  clock = clock + 2.1
  local clipboardFailure = R.report('original survives clipboard failure', 'clipboard original trace')
  assert(clipboardFailure.persisted and not clipboardFailure.copied)
  contains(love.filesystem.read('diagnostics/last-error.txt'), 'clipboard original trace')
  assert(R.getStats().clipboardFailures == 1)
  love.system.setClipboardText = nativeClipboard
  local nativeToast = Toast.error
  Toast.error = function() error('notification UI unavailable') end
  clock = clock + 2.1; R.update()
  assert(R.getStats().notificationFailures > 0, 'optional UI failure must be observable')
  contains(love.filesystem.read('diagnostics/last-error.txt'), 'clipboard original trace')
  Toast.error = nativeToast
  love.filesystem.createDirectory('tests/engine')
  love.filesystem.write('tests/engine/recoverable-native.lua', [[
function missingAddon() return requireAddon('missing-optional-addon', 'helper') end
function explicitReport() return reportRecoverableError('mod chose safe fallback', 'mod fallback trace') end
function healthy() healthyCalls=(healthyCalls or 0)+1; return 2 end
]])
  local script = Script('tests/engine/recoverable-native.lua', true, true, true)
  assert(not script.closed)
  script:call('missingAddon')
  assert(script.__failedfunc.missingAddon and not script.closed, 'missing addon must preserve native isolated-callback behavior')
  contains(love.filesystem.read('diagnostics/last-error.txt'), 'missing-optional-addon')
  contains(love.filesystem.read('diagnostics/last-error.txt'), 'recoverable-native.lua')
  assert(script:call('healthy') == 2, 'unrelated native callbacks must keep working')
  local explicit = script:call('explicitReport')
  assert(type(explicit) == 'table' and explicit.persisted, 'mods need explicit reportable-error API')
  contains(love.filesystem.read('diagnostics/last-error.txt'), 'mod fallback trace')
  local alias = script.variables.reportRecoverableError
  script:close()
  local closed, closedError = pcall(alias, 'too late')
  assert(not closed); contains(tostring(closedError), 'closed script')
  clock = clock + 2.1
  love.system.setClipboardText = function() return false end
  local refused = R.report('backend explicitly declined clipboard', 'declined original trace')
  assert(not refused.copied and R.getStats().clipboardFailures == 2, 'false clipboard return must count as failure')
  love.system.setClipboardText = nativeClipboard
  clock = clock + 2.1; R.update()
  contains(love.system.getClipboardText(), 'declined original trace')
  local Save = assert(love.filesystem.load('loxel/util/save.lua'))()
  local nativeDevice = love.system.getDevice
  local obstruction = 'recoverable-save-obstruction'
  assert(love.filesystem.write(obstruction, 'not a directory'))
  Save.path = love.filesystem.getSaveDirectory() .. '/' .. obstruction
  Save.data = {scores = {retained = 123}}
  love.system.getDevice = function() return 'Desktop' end
  local savedOK, saveError = Save.bind('save-probe')
  love.system.getDevice = nativeDevice
  love.filesystem.remove(obstruction)
  assert(savedOK == false and type(saveError) == 'string' and Save.data.scores.retained == 123, 'known save failure must keep return/data semantics')
  contains(love.filesystem.read('diagnostics/last-error.txt'), 'recoverable-save-obstruction')
  contains(love.filesystem.read('diagnostics/last-error.txt'), 'Could not write save file')
  love.timer.getTime = nativeTime
  require('funkin.backend.diagnostics').finish()
  print('RECOVERABLE ERRORS PASSED: original reports/clipboard, startup Toast queue, duplicate/rate/backlog bounds, clipboard/UI failures, missing addon isolation, healthy callback and explicit scoped API')
 end, debug.traceback)
 if not ok then print('RECOVERABLE ERRORS FAIL: ' .. tostring(err)) end
 love.event.quit(ok and 0 or 1)
end
function love.update() end
function love.draw() end
function love.quit() end
function love.errorhandler(message) print(message); return function() return 1 end end
