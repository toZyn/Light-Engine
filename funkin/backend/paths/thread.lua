require 'love.image'
require 'love.sound'
require 'love.audio'
require 'love.timer'
local taskName, resultName, cancelName = ...
local tasks, results, cancel = love.thread.getChannel(taskName), love.thread.getChannel(resultName), love.thread.getChannel(cancelName)
local function release(data) if type(data) == 'userdata' then pcall(function() data:release() end) end end
local function isUrl(path) return path:sub(1, 7) == 'http://' or path:sub(1, 8) == 'https://' end
local transport
local function getHTTPS()
 if transport then return transport end
 local messages = {}
 for _, name in ipairs({'https', 'lib.https'}) do
  local ok, module = pcall(require, name)
  if ok and type(module) == 'table' and type(module.request) == 'function' then transport = module; return module end
  messages[#messages + 1] = name .. ': ' .. (ok and 'module must provide a request function' or tostring(module))
 end
 error('HTTPS transport unavailable: ' .. table.concat(messages, '; '), 0)
end
local function request(path)
 local code, body = getHTTPS().request(path)
 assert(code == 200, 'HTTPS request failed: HTTP ' .. tostring(code))
 assert(type(body) == 'string', 'HTTPS request returned no response body')
 return body
end
local function load(kind, path)
 if kind == 'text' then assert(isUrl(path), 'Text loading requires URL'); return request(path) end
 local filedata
 local ok, data = xpcall(function()
  local input = path
  if isUrl(path) then
   local extension = path:match('%.([%w]+)$') or (kind == 'image' and 'png' or 'ogg')
   filedata = love.filesystem.newFileData(request(path), 'remote.' .. extension)
   input = filedata
  end
  if kind == 'image' then
   if not isUrl(path) and path:match('%.([^%.]+)$') ~= 'png' then return love.image.newCompressedData(input) end
   return love.image.newImageData(input)
  elseif kind == 'sound' then return love.sound.newSoundData(input)
  elseif kind == 'audio' then return love.audio.newSource(input, 'stream') end
  error('unknown asset type ' .. tostring(kind))
 end, debug.traceback)
 release(filedata)
 if not ok then error(data, 0) end
 return data
end
while true do
 local task = tasks:demand()
 if task == 'exit' then break end
 if not cancel:peek() then
  local kind, path, id, generation = unpack(task)
  local ok, data = xpcall(function() return load(kind, path) end, function(message)
   return {kind = 'worker', path = path, message = tostring(message), traceback = debug.traceback('', 2), generation = generation}
  end)
  if not cancel:peek() then results:push({ok, data, id, kind, path, generation}) end
  -- Channel push retains the native object. Release the worker userdata after
  -- transfer (or cancellation), so it does not keep decoded buffers alive.
  if ok then release(data) end
 end
end
collectgarbage('collect')
