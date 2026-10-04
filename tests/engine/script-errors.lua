-- Run as main.lua in a temporary LÖVE checkout runner.
require 'loxel'
require 'funkin'
local function contains(text,needle) assert(text and text:find(needle,1,true),'missing diagnostic: '..needle) end
function love.load()
 local ok,err=xpcall(function()
  -- Diagnostics must be usable even when main.lua has not imported it.
  package.loaded['funkin.backend.diagnostics']=nil
  love.filesystem.setIdentity('light-engine-script-error-tests')
  love.filesystem.createDirectory('tests/engine')
  love.filesystem.remove('diagnostics/last-error.txt')
  love.filesystem.write('tests/engine/fail-chunk.lua',[[
local function missingDependency()
 local dependency=require('script-error-missing-dependency')
end
missingDependency()
]])
  local broken=Script('tests/engine/fail-chunk.lua',true,true,true)
  assert(broken.closed,'failed chunk remained open')
  local saved=love.filesystem.read('diagnostics/last-error.txt')
  contains(saved,'tests/engine/fail-chunk.lua')
  contains(saved,'missingDependency')
  contains(saved,'script-error-missing-dependency')
  contains(saved,'stack traceback:')
  love.filesystem.write('tests/engine/fail-callback.lua',[[
calls=0
local function deepest(value)
 error('nested callback boom '..tostring(value))
end
local function middle(value) deepest(value) end
function explode(value) calls=calls+1; middle(value) end
function healthy(value,tail) healthyValue=value; healthyTail=tail; return 2 end
]])
  local script=Script('tests/engine/fail-callback.lua',true,true,true)
  assert(not script.closed)
  local notified=0
  script.errorCallback:add(function(callback) assert(callback=='explode'); notified=notified+1 end)
  script:call('explode',17)
  assert(not script.closed and script.__failedfunc.explode and notified==1,'native callback isolation/notification changed')
  saved=love.filesystem.read('diagnostics/last-error.txt')
  contains(saved,'nested callback boom 17'); contains(saved,'fail-callback.lua'); contains(saved,'deepest'); contains(saved,'middle')
  script:call('explode',99)
  assert(script.variables.calls==1 and notified==1,'failed callback executed twice')
  assert(love.filesystem.read('diagnostics/last-error.txt')==saved,'isolated callback rewrote diagnostic')
  assert(script:call('healthy',nil,'tail')==2 and script.variables.healthyTail=='tail','healthy callback return/nil args changed')
  script:close()
  require('funkin.backend.diagnostics').finish()
  print('SCRIPT DIAGNOSTICS PASS: native chunk dependency failure/full traceback; nested callback traceback; isolation/notification; healthy nil args and return value')
 end,debug.traceback)
 if not ok then print('SCRIPT DIAGNOSTICS FAIL '..err) end
 love.event.quit(ok and 0 or 1)
end
function love.update() end
function love.draw() end
function love.quit() end
function love.errorhandler(err) print(err);return function()return 1 end end
