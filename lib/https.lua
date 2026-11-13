if not love.system then require 'love.system' end

local OS = love.system.getOS()
local directories = {Windows = 'windows', Linux = 'linux', ['OS X'] = 'osx'}
local directory = directories[OS]
if directory and type(package.loadlib) == 'function' then
 local path = 'lib/' .. directory .. (OS == 'Windows' and '/https.dll' or '/https.so')
 if love.filesystem.getInfo(path, 'file') then
  local root = love.filesystem.getRealDirectory(path)
  local ok, initializer = pcall(package.loadlib, root and (root .. '/' .. path) or path, 'luaopen_https')
  if ok and type(initializer) == 'function' then
   local loaded, module = pcall(initializer)
   if loaded and type(module) == 'table' and type(module.request) == 'function' then return module end
  end
 end
end
return {available = false}
