io.stdout:setvbuf("no")

local Diagnostics = require "funkin.backend.diagnostics"
local RecoverableErrors = require "funkin.backend.recoverable-errors"
local funkin
-- Installed before engine imports so initialization errors also reach disk.
function love.errorhandler(msg)
 local trace = debug.traceback("", 2)
 if funkin then return funkin.throwError(msg, trace) end
 return Diagnostics.errorHandler(msg, trace)
end
Diagnostics.start()

require "loxel"
funkin = require "funkin"

function love.load()
 Diagnostics.checkpoint("load:start")
 funkin.load()
 Diagnostics.checkpoint("load:ready")
end

function love.resize(w, h) game.resize(w, h) end

function love.keypressed(key, ...)
	if key == "f5" and not game.getState():is(PlayState) then
		game.resetState(true)
	elseif Project.DEBUG_MODE and love.keyboard.isDown("lctrl", "rctrl") then
		if key == "f4" then error("force crash") end
		if key == "`" then return "restart" end
	end
	controls:onKeyPress(key, ...)
	game.keypressed(key, ...)
end

function love.keyreleased(...)
	controls:onKeyRelease(...)
	game.keyreleased(...)
end

function love.textinput(t) game.textinput(t) end

function love.wheelmoved(...) game.wheelmoved(...) end

function love.mousemoved(...) game.mousemoved(...) end

function love.mousepressed(...) game.mousepressed(...) end

function love.mousereleased(...) game.mousereleased(...) end

function love.touchpressed(...) game.touchpressed(...) end

function love.touchmoved(...) game.touchmoved(...) end

function love.touchreleased(...) game.touchreleased(...) end

function love.update(dt)
	Diagnostics.checkpoint("running")
	RecoverableErrors.update()
	funkin.update(dt)
	game.update(dt)
end

function love.draw() game.draw() end

function love.focus(f)
	if f and Storage then Storage.refreshNow(false) end
	game.focus(f)
end

function love.fullscreen(f, t)
	funkin.fullscreen(f)
	game.fullscreen(f)
end

function love.quit()
	if paths and paths.async then paths.async.stop() end
	funkin.quit()
	game.quit()
 Diagnostics.finish()
end

function love.threaderror(thread, message)
 local text = "Worker thread error: " .. Diagnostics.sanitize(message)
 Diagnostics.report(text, debug.traceback("Thread: " .. tostring(thread), 2))
 error(text, 0)
end

function love.lowmemory()
 Diagnostics.checkpoint("low-memory notification")
 collectgarbage("collect")
end
