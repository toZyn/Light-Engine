-- Run as main.lua of an isolated LÖVE test directory.
local root = os.getenv('ENGINE_ROOT') or '/workspace/Light-Engine-advanced'
package.path = root .. '/?.lua;' .. root .. '/?/init.lua;' .. package.path

function love.load()
 local ok,err=xpcall(function()
  print('PROBE: the fixture started')
  error('PROBE: deliberate failure, to prove this suite runs')
 end,debug.traceback)
 if not ok then print(err) love.event.quit(1) return end
 print('PSYCH COMPILED SCRIPT PASSED:')
 love.event.quit(0)
end
