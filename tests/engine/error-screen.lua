check('original error presentation and controls with persistent reports', function()
 local original = {draw = love.graphics.draw, quit = love.errorhandler_quit,
  handlers = love.handlers, keys = love.keyboard.isDown, dialog = love.window.showMessageBox, wait = love.event.wait}
 local images, dialogCalls = {}, 0
 love.errorhandler_quit = function() end -- keep the harness alive after the intentional error
 love.graphics.draw = function(image, ...)
  images[image] = true
  return original.draw(image, ...)
 end
 local ok, err = xpcall(function()
  local background = paths.getImage('menus/menuDesat')
  local logo = paths.getImage('menus/splashscreen/FNFLOVE_logo')
  local loop = require('funkin').throwError('original presentation probe', 'original caller trace')
  assert(type(loop) == 'function')
  assert(images[background] and images[logo], 'error screen must draw the original background and logo')
  local report = love.filesystem.read('diagnostics/last-error.txt')
  assert(report:find('original presentation probe', 1, true))
  assert(report:find('original caller trace', 1, true))
  local font = paths.getFont('phantommuff.ttf', 18)
  assert(love.graphics.getFont() == font, 'error screen must retain the original font')
  -- Native event.wait blocks in SDL; exercise the same handler using LÖVE's
  -- injected test event queue, without requiring physical keyboard input.
  love.event.wait = function()
   for name, a, b in love.event.poll() do return name, a, b end
   error('missing injected error-screen event')
  end
  love.keyboard.isDown = function(...) return true end
  love.event.clear(); love.event.push('keypressed', 'c')
  loop()
  assert(love.system.getClipboardText():find('original presentation probe', 1, true))
  love.event.clear(); love.event.push('keypressed', 'r')
  assert(loop() == 'restart', 'original Ctrl+R restart must work')
  love.window.showMessageBox = function(title, message, buttons)
   dialogCalls = dialogCalls + 1
   assert(buttons[3] == 'Restart' and buttons[4] == 'Copy to clipboard')
   return 3
  end
  love.event.clear(); love.event.push('touchpressed', 'probe', 100, 100)
  assert(loop() == 'restart' and dialogCalls == 1, 'touch must use the original native dialog')
  love.event.clear(); love.event.push('keypressed', 'escape')
  assert(loop() == 1, 'original Escape quit must work')
 end, debug.traceback)
 love.graphics.draw, love.errorhandler_quit = original.draw, original.quit
 love.handlers, love.keyboard.isDown, love.window.showMessageBox = original.handlers, original.keys, original.dialog
 love.event.wait = original.wait
 love.event.clear(); love.audio.stop()
 assert(ok, err)
end)
