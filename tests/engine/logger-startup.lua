-- Run as main.lua in a temporary LÖVE checkout runner, before game.init().
require 'loxel'
require 'funkin'
local root = os.getenv('ENGINE_ROOT') or '/workspace/Light-Engine-advanced'
local function contains(text, needle) assert(text:find(needle, 1, true), 'missing console message: ' .. needle) end
function love.load()
 local ok, err = xpcall(function()
  love.window.setMode(320, 240, {vsync = 0}); game.width, game.height = 320, 240
  assert(Toast.icons == nil and Toast.font == nil, 'test requires uninitialized Toast UI')
  assert(Toast.showErrors and Toast.showDeprecations, 'UI flags must remain enabled')
  local lines, console = {}, Logger.print
  local function output(text) lines[#lines + 1] = text; console(text) end
  Logger.print = output
  local callbacks = 0
  local result = paths.async.getImage('missing-logger-startup-image', function(data)
   assert(data == nil); callbacks = callbacks + 1
  end)
  assert(result == nil and callbacks == 1, 'missing asset must report its original failure')
  Logger.log('error', 'original startup error')
  Toast.error('direct uninitialized error'); Toast.deprecated('direct uninitialized warning')
  contains(table.concat(lines, '\n'), 'missing-logger-startup-image')
  contains(table.concat(lines, '\n'), 'original startup error')
  assert(#Toast.instances == 0, 'uninitialized UI must not enqueue toasts')
  local savedToast = Toast; Toast = nil
  local standalone = dofile(root .. '/loxel/system/logger.lua')
  assert(type(standalone.print) == 'function', 'logger needs a console before Toast module loads')
  standalone.print = output
  standalone.log('warn', 'logger before Toast module')
  standalone.log('error', 'error before Toast module')
  contains(table.concat(lines, '\n'), 'logger before Toast module')
  contains(table.concat(lines, '\n'), 'error before Toast module')
  Toast = savedToast
  Toast.init(320, 240)
  local first = #Toast.instances
  Logger.log('warn', 'initialized warning toast')
  Logger.log('error', 'initialized error toast')
  assert(#Toast.instances == first + 2, 'initialized logger must keep native UI notifications')
  assert(Toast.instances[first + 1].icon == Toast.icons.deprecated and Toast.instances[first + 2].icon == Toast.icons.error, 'native toast icons must remain unchanged')
  local icons = Toast.icons; Toast.icons = nil
  Logger.log('warn', 'icons unavailable warning'); Logger.log('error', 'icons unavailable error')
  contains(table.concat(lines, '\n'), 'icons unavailable warning')
  contains(table.concat(lines, '\n'), 'icons unavailable error')
  assert(#Toast.instances == first + 2, 'missing icons must leave UI untouched')
  Toast.icons = icons
  Logger.print = console
  paths.async.stop()
  print('LOGGER STARTUP PASSED: real missing asset and errors reach console before Toast init; absent module/icons are guarded; initialized native UI retains both icons')
 end, debug.traceback)
 if not ok then print('LOGGER STARTUP FAIL: ' .. tostring(err)) end
 love.event.quit(ok and 0 or 1)
end
function love.update() end
function love.draw() end
function love.quit() end
function love.errorhandler(message) print(message); return function() return 1 end end
