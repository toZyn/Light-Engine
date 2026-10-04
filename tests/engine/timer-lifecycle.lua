-- Standalone main.lua fixture using actual engine Timer/Tween managers.
io.stdout:setvbuf('no')
require 'loxel'
local tests = {}
local function test(name, run) tests[#tests + 1] = {name, run} end
local function timer(manager, callback, loops)
 local t = Timer(manager); t:start(.1, callback, loops or 1); return t
end

test('timer callback clears its manager without nil access or sibling completion', function()
 local m, sibling, clearing = TimerManager(), 0, 0
 timer(m, function() sibling = sibling + 1 end)
 timer(m, function() clearing = clearing + 1; m:clear(); m:clear() end)
 m:update(.1); m:update(.1)
 assert(clearing == 1 and sibling == 0 and #m.instances == 0, 'clear allowed another callback')
end)

test('timer callback cancels earlier entries without updating itself twice', function()
 local m, firstCount, lastCount, middleCount = TimerManager(), 0, 0, 0
 local first = timer(m, function() firstCount = firstCount + 1 end)
 timer(m, function() middleCount = middleCount + 1 end)
 timer(m, function() lastCount = lastCount + 1; first:cancel() end, 3)
 m:update(.1)
 assert(firstCount == 0 and middleCount == 1 and lastCount == 1, 'mutation repeated or resurrected a timer')
end)

test('timer created after callback clear starts on the next manager tick', function()
 local m, created = TimerManager(), 0
 timer(m, function() error('cleared sibling ran') end)
 timer(m, function()
  m:clear()
  timer(m, function() created = created + 1 end)
 end)
 m:update(.1)
 assert(created == 0 and #m.instances == 1, 'new timer ran during its creation tick')
 m:update(.1); assert(created == 1, 'new timer did not run on next tick')
end)

test('timer callback recursive manager update cannot repeat the current callback', function()
 local m, calls = TimerManager(), 0
 timer(m, function() calls = calls + 1; if calls < 3 then m:update(.1) end end, 0)
 m:update(.1)
 assert(calls == 1, 'recursive update repeated callback')
 m:update(.1); assert(calls == 2, 'recursive update left manager stuck')
 m:clear()
end)

test('removed and explicitly reinserted timer waits for next tick', function()
 local m, calls = TimerManager(), 0
 local pending = timer(m, function() calls = calls + 1 end)
 timer(m, function()
  pending:cancel()
  pending:start(.1, function() calls = calls + 1 end)
  m:insert(pending)
 end)
 m:update(.1); assert(calls == 0, 'reinserted timer advanced during removal tick')
 m:update(.1); assert(calls == 1, 'reinserted timer did not advance next tick')
end)

test('timer errors propagate and do not leave manager updating forever', function()
 local m, survivorCount = TimerManager(), 0
 timer(m, function() survivorCount = survivorCount + 1 end)
 local broken
 broken = timer(m, function() broken:cancel(); error('timer callback failure') end)
 local ok, err = pcall(m.update, m, .1)
 assert(not ok and tostring(err):find('timer callback failure', 1, true), 'callback error was hidden')
 m:update(.1); assert(survivorCount == 1, 'manager remained stuck after error')
end)

test('timer zero dt and time scale preserve existing timing', function()
 local m, count = TimerManager(2), 0
 timer(m, function() count = count + 1 end)
 m:update(0); assert(count == 0)
 m:update(.05); assert(count == 1)
end)

test('tween completion can clear its manager without nil access', function()
 local m, sibling, clearing = Tween(), 0, 0
 m:tween({x = 0}, {x = 1}, .1, {onComplete = function() sibling = sibling + 1 end})
 m:tween({x = 0}, {x = 1}, .1, {onComplete = function() clearing = clearing + 1; m:clear(); m:clear() end})
 m:update(.1); m:update(.1)
 assert(sibling == 0 and clearing == 1 and #m.instances == 0, 'clear allowed another tween callback')
end)

test('tween callback cancellation cannot update the current tween twice', function()
 local m, firstCount, lastCount, middleCount = Tween(), 0, 0, 0
 local first = m:tween({x = 0}, {x = 1}, .1, {onComplete = function() firstCount = firstCount + 1 end})
 m:tween({x = 0}, {x = 1}, .1, {onComplete = function() middleCount = middleCount + 1 end})
 m:tween({x = 0}, {x = 1}, .1, {type = 'looping', onComplete = function() lastCount = lastCount + 1; first:cancel() end})
 m:update(.1)
 assert(firstCount == 0 and middleCount == 1 and lastCount == 1, 'mutation repeated or resurrected a tween')
 m:clear()
end)

test('tween created after callback clear starts on next manager tick', function()
 local m, created = Tween(), 0
 m:tween({x = 0}, {x = 1}, .1, {onComplete = function() error('cleared tween ran') end})
 m:tween({x = 0}, {x = 1}, .1, {onComplete = function()
  m:clear()
  m:tween({x = 0}, {x = 1}, .1, {onComplete = function() created = created + 1 end})
 end})
 m:update(.1)
 assert(created == 0 and #m.instances == 1, 'new tween ran during its creation tick')
 m:update(.1); assert(created == 1, 'new tween did not run on next tick')
end)

test('tween callback recursive manager update cannot complete twice', function()
 local m, count = Tween(), 0
 m:tween({x = 0}, {x = 1}, .1, {type = 'looping', onComplete = function()
  count = count + 1; if count < 3 then m:update(.1) end
 end})
 m:update(.1); assert(count == 1, 'recursive update repeated tween completion')
 m:update(.1); assert(count == 2, 'manager remained stuck')
 m:clear()
end)

test('tween onStart cancellation does not modify properties or call completion', function()
 local m, object, count = Tween(), {x = 0}, 0
 m:tween(object, {x = 1}, .1, {onStart = function(t) t:cancel() end,
  onComplete = function() count = count + 1 end})
 m:update(.1)
 assert(object.x == 0 and count == 0 and #m.instances == 0, 'canceled tween continued updating')
end)

test('tween onUpdate disposal does not call completion', function()
 local m, count = Tween(), 0
 m:tween({x = 0}, {x = 1}, .1, {onUpdate = function() m:clear() end,
  onComplete = function() count = count + 1 end})
 m:update(.1)
 assert(count == 0 and #m.instances == 0, 'disposed tween called completion')
end)

test('tween errors propagate and manager can recover', function()
 local m, survived = Tween(), 0
 m:tween({x = 0}, {x = 1}, .1, {onComplete = function() survived = survived + 1 end})
 m:tween({x = 0}, {x = 1}, .1, {onComplete = function() error('tween callback failure') end})
 local ok, err = pcall(m.update, m, .1)
 assert(not ok and tostring(err):find('tween callback failure', 1, true), 'callback error was hidden')
 m:update(.1); assert(survived == 1, 'manager remained stuck after callback error')
end)

test('tween clear preserves persistent entries and zero dt timing', function()
 local m, object, count = Tween(), {x = 0}, 0
 m:tween(object, {x = 1}, .1, {persist = true, onComplete = function() count = count + 1 end})
 m:tween({x = 0}, {x = 1}, .1)
 m:clear(); assert(#m.instances == 1)
 m:update(0); assert(object.x == 0 and count == 0)
 m.timeScale = 2; m:update(.05); assert(object.x == 1 and count == 1)
end)

function love.run()
 local failed = 0
 for _, t in ipairs(tests) do
  local ok, err = xpcall(t[2], debug.traceback)
  print((ok and 'PASS: ' or 'FAIL: ') .. t[1])
  if not ok then failed = failed + 1; print(err) end
 end
 print(('TIMER/TWEEN TESTS: %d passed, %d failed'):format(#tests - failed, failed))
 return function() return failed == 0 and 0 or 1 end
end
