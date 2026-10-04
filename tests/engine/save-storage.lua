check('denied desktop save does not crash or discard in-memory scores', function()
 local getDevice = love.system.getDevice
 local marker = 'save-directory-obstruction'
 assert(love.filesystem.write(marker, 'this is a file, not a directory'))
 local Save = assert(love.filesystem.load('loxel/util/save.lua'))()
 Save.path = love.filesystem.getSaveDirectory() .. '/' .. marker
 Save.data = {scores = {probe = 123}}
 love.system.getDevice = function() return 'Desktop' end
 local ok, success, message = pcall(Save.bind, 'funkin')
 love.system.getDevice = getDevice
 love.filesystem.remove(marker)
 assert(ok, 'denied desktop storage must not crash: ' .. tostring(success))
 assert(success == false and type(message) == 'string', 'save failure must be returned to the caller')
 assert(Save.data.scores.probe == 123, 'failed persistence must keep the live scores')
end)

check('external saves validate write and close results before noting success', function()
 local nativeOpen = io.open
 local reporter = require('funkin.backend.recoverable-errors')
 local nativeReport = reporter.report
 local ok, failure = xpcall(function()
  for _, mode in ipairs({'write-nil', 'write-throw', 'close-nil', 'close-throw', 'success'}) do
   local Storage = assert(love.filesystem.load('funkin/backend/storage.lua'))()
   local fallback, noted, closed, report = 0, 0, 0, nil
   local live = {scores = {probe = 456}}
   local save = {data = live, init = function() end, bind = function()
    fallback = fallback + 1; return false, 'fallback failed'
   end}
   Storage.available, Storage.savePath = true, '/external-save-probe'
   Storage.installSave(save)
   Storage.noteSaveWrite = function() noted = noted + 1 end
   reporter.report = function(message, trace, options)
    report = message
    return nativeReport(message, trace, options)
   end
   io.open = function(path, access)
    assert(path == '/external-save-probe/funkin.lox' and access == 'wb')
    return {
     write = function(self, encoded)
      local decoded = require('loxel.lib.json').decode(love.data.decode('string', 'hex', encoded))
      assert(decoded.scores.probe == 456)
      if mode == 'write-nil' then return nil, 'write denied' end
      if mode == 'write-throw' then error('write raised') end
      return self
     end,
     close = function()
      closed = closed + 1
      if mode == 'close-nil' then return nil, 'close denied' end
      if mode == 'close-throw' then error('close raised') end
      return true
     end
    }
   end
   local safe, result, message = pcall(save.bind, 'funkin')
   assert(safe, mode .. ' must not raise: ' .. tostring(result))
   assert(closed == 1, mode .. ' must attempt to close exactly once')
   assert(save.data == live and live.scores.probe == 456)
   if mode == 'success' then
    assert(result == true and fallback == 0 and noted == 1 and not report, 'successful external save must return true')
   else
    assert(result == false and message == 'fallback failed' and fallback == 1 and noted == 0, mode .. ' must preserve fallback results')
    assert(report and report:find('/external-save-probe/funkin.lox', 1, true), mode .. ' must report the actual external filename')
    assert(love.filesystem.read('diagnostics/last-error.txt'):find('/external-save-probe/funkin.lox', 1, true))
   end
  end
  local Storage = assert(love.filesystem.load('funkin/backend/storage.lua'))()
  local fallback = 0
  local save = {data = {}, init = function() end, bind = function() fallback = fallback + 1 end}
  save.data.cycle = save.data
  Storage.available, Storage.savePath = true, '/external-save-probe'
  Storage.installSave(save)
  io.open = function() error('encoding failure must occur before opening the save') end
  local encoded, encodeError = pcall(save.bind, 'funkin')
  assert(not encoded and tostring(encodeError):find('circular', 1, true) and fallback == 0, 'programmer encoding errors must remain errors')
 end, debug.traceback)
 io.open, reporter.report = nativeOpen, nativeReport
 assert(ok, failure)
end)

check('corrupt native saves keep live defaults and close desktop readers', function()
 local getDevice, nativeOpen, nativeRead = love.system.getDevice, io.open, love.filesystem.read
 local ok, failure = xpcall(function()
  local function encode(text) return love.data.encode('string', 'hex', text) end
  for _, device in ipairs({'Desktop', 'Mobile'}) do
   for _, sample in ipairs({{payload = 'invalid hex!'}, {payload = encode('{"bad":')}, {payload = encode('42')},
     {payload = encode('{"scores":{"probe":321}}'), valid = true}}) do
    local payload = sample.payload
    local Save = assert(love.filesystem.load('loxel/util/save.lua'))()
    local live, closed = {scores = {probe = 789}}, 0
    Save.data = live
    love.system.getDevice = function() return device end
    io.open = function(path, access)
     assert(path:find('/corrupt-probe.lox', 1, true) and access == 'rb')
     return {read = function() return payload end, close = function() closed = closed + 1; return true end}
    end
    love.filesystem.read = function(path, ...)
     if path == 'corrupt-probe.lox' then return payload end
     return nativeRead(path, ...)
    end
    local safe, message = pcall(Save.init, 'corrupt-probe')
    assert(safe, device .. ' corrupt save must not raise: ' .. tostring(message))
    assert(Save.initialized)
    if sample.valid then
     assert(Save.data ~= live and Save.data.scores.probe == 321, 'valid saved tables must replace defaults')
    else
     assert(Save.data == live and live.scores.probe == 789, 'corrupt save must preserve live defaults')
    end
    assert(closed == (device == 'Desktop' and 1 or 0), 'desktop reader must close even when decoding fails')
    if not sample.valid then
     local report = nativeRead('diagnostics/last-error.txt')
     assert(report and report:find('corrupt-probe.lox', 1, true), 'corrupt save diagnostic needs the original filename')
    end
   end
  end
 end, debug.traceback)
 love.system.getDevice, io.open, love.filesystem.read = getDevice, nativeOpen, nativeRead
 assert(ok, failure)
end)

check('mobile save returns I/O failures instead of raising', function()
 local getDevice, write = love.system.getDevice, love.filesystem.write
 local Save = assert(love.filesystem.load('loxel/util/save.lua'))()
 Save.data = {probe = true}
 love.system.getDevice = function() return 'Mobile' end
 for _, raised in ipairs({false, true}) do
  love.filesystem.write = function()
   if raised then error('permission denied') end
   return nil, 'permission denied'
  end
  local ok, success, message = pcall(Save.bind, 'funkin')
  love.filesystem.write = write
  if not ok or success ~= false then
   love.system.getDevice = getDevice
   error('mobile I/O failure must return false instead of throwing: ' .. tostring(success))
  end
  assert(message:find('permission denied', 1, true))
 end
 love.system.getDevice = getDevice
end)

check('successful save retains the existing hex-JSON format', function()
 local getDevice = love.system.getDevice
 local Save = assert(love.filesystem.load('loxel/util/save.lua'))()
 Save.data = {probe = 42}
 love.system.getDevice = function() return 'Mobile' end
 local ok, result = pcall(Save.bind, 'save-format-probe')
 love.system.getDevice = getDevice
 assert(ok and result == true)
 local encoded = assert(love.filesystem.read('save-format-probe.lox'))
 local data = require('loxel.lib.json').decode(love.data.decode('string', 'hex', encoded))
 assert(data.probe == 42)
 love.filesystem.remove('save-format-probe.lox')
 Save.path = love.filesystem.getSaveDirectory()
 love.system.getDevice = function() return 'Desktop' end
 ok, result = pcall(Save.bind, 'desktop-save-format-probe')
 love.system.getDevice = getDevice
 assert(ok and result == true)
 encoded = assert(love.filesystem.read('desktop-save-format-probe.lox'))
 data = require('loxel.lib.json').decode(love.data.decode('string', 'hex', encoded))
 assert(data.probe == 42)
 love.filesystem.remove('desktop-save-format-probe.lox')
end)

check('Android gallery exclusion is scoped, non-destructive and nonfatal', function()
 local originals = {open = io.open, execute = os.execute, remove = os.remove,
  getenv = os.getenv, getOS = love.system.getOS, mount = love.filesystem.mount,
  getInfo = love.filesystem.getInfo}
 local ok, failure = xpcall(function()
  for _, scenario in ipairs({'create', 'existing', 'denied', 'raised', 'close-failed', 'desktop'}) do
   local android = scenario ~= 'desktop'
   local root = android and '/gallery-probe/Android/media/' .. Project.package
    or '/gallery-probe/' .. Project.company .. '/' .. Project.file
   local marker, attempts = scenario == 'existing' and 'keep existing bytes' or nil, 0
   love.system.getOS = function() return android and 'Android' or 'Linux' end
   os.getenv = function() return '/gallery-probe' end
   os.execute = function(command)
    if android and (command:find(root .. '/mods', 1, true)
     or command:find(root .. '/addons', 1, true) or command:find(root .. '/saves', 1, true)) then
     assert(attempts == 1, '.nomedia must be attempted before creating content folders')
    end
    return true
   end
   os.remove = function() return true end
   love.filesystem.mount = function(path) assert(path == root); return true end
   love.filesystem.getInfo = function() return {type = 'directory'} end
   io.open = function(path, access)
    if path:match('/%.fnf%-love%-write%-test$') then
     if android and path ~= root .. '/.fnf-love-write-test' then
      assert(attempts == 1, '.nomedia must be attempted before preparing content folders')
     end
     return {close = function() return true end}
    end
    assert(android and path == root .. '/.nomedia', 'only the selected Android app root may get a marker')
    attempts = attempts + 1
    assert(access == 'ab', 'append mode must preserve existing marker contents')
    if scenario == 'denied' then return nil, 'permission denied' end
    if scenario == 'raised' then error('permission denied') end
    marker = marker or ''
    return {close = function()
     if scenario == 'close-failed' then return nil, 'close failed' end
     return true
    end}
   end
   local Storage = assert(love.filesystem.load('funkin/backend/storage.lua'))()
   Storage.init(); Storage.init()
   assert(Storage.available and Storage.mounted, 'gallery exclusion failure must not disable mods')
   assert(attempts == (android and 1 or 0), 'Android marker must be attempted once; desktop needs no marker')
   if scenario == 'existing' then assert(marker == 'keep existing bytes') end
   if scenario == 'create' then assert(marker == '', 'new marker must be empty') end
  end
 end, debug.traceback)
 io.open, os.execute, os.remove, os.getenv = originals.open, originals.execute, originals.remove, originals.getenv
 love.system.getOS, love.filesystem.mount, love.filesystem.getInfo = originals.getOS, originals.mount, originals.getInfo
 assert(ok, failure)
end)
