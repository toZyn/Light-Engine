-- Explicit addon namespaces. Never use paths.getPath or addon/mod precedence.
local Assets = {}
local json = require 'loxel.lib.json'
local function fail(id, path, message)
 error('Addon assets [' .. tostring(id) .. '] ' .. tostring(path) .. ': ' .. tostring(message), 3)
end
local function normalize(id, relative)
 if type(id) ~= 'string' or id == '' or id == '.' or id == '..'
  or id:find('[/\\:%z\1-\31\127]') then
  fail(id, relative, 'addon ID must be a directory segment without separators, colons or control bytes')
 end
 if type(relative) ~= 'string' or relative == '' or relative:sub(1, 1) == '/'
  or relative:find('[\\:%z\1-\31\127]') then
  fail(id, relative, 'relative path must be nonempty and cannot be absolute, contain backslashes, colons or control bytes')
 end
 local segments = {}
 for segment in relative:gmatch('[^/]+') do
  if segment == '..' then fail(id, relative, 'relative path cannot contain traversal segments') end
  if segment ~= '.' then segments[#segments + 1] = segment end
 end
 if #segments == 0 then fail(id, relative, 'relative path must name a file or directory') end
 return table.concat(segments, '/')
end
function Assets.getPath(id, relative)
 local normalized = normalize(id, relative)
 if not Addons or type(Addons.root) ~= 'string' or type(Addons.all) ~= 'table' then
  fail(id, normalized, 'addon registry is not initialized')
 end
 local entry
 for _, addon in ipairs(Addons.all) do if addon.path == id then entry = addon; break end end
 if not entry then fail(id, normalized, 'unknown addon ID') end
 if entry.active ~= true then fail(id, normalized, 'addon is inactive') end
 return Addons.root:gsub('/+$', '') .. '/' .. id .. '/' .. normalized
end
local function requireFile(id, path)
 local info = love.filesystem.getInfo(path)
 if not info or info.type ~= 'file' then fail(id, path, 'file not found') end
end
function Assets.readText(id, relative)
 local path = Assets.getPath(id, relative)
 requireFile(id, path)
 local ok, text, message = pcall(love.filesystem.read, path)
 if not ok then fail(id, path, text) end
 if not text then fail(id, path, message or 'file could not be read') end
 return text
end
function Assets.readJSON(id, relative)
 local path = Assets.getPath(id, relative)
 local text = Assets.readText(id, relative)
 local ok, decoded = pcall(json.decode, text)
 if not ok then fail(id, path, 'invalid JSON: ' .. tostring(decoded)) end
 return decoded
end
local function cached(id, relative, category, expected, create, cacheSuffix)
 local path = Assets.getPath(id, relative)
 if not paths or type(paths[category]) ~= 'table' then fail(id, path, 'engine asset cache is not initialized') end
 local cache, key = paths[category], path .. (cacheSuffix or '')
 local object = cache[key]
 if object then
  local ok, matches = pcall(object.typeOf, object, expected)
  if not ok or not matches then fail(id, path, 'cached resource must have type ' .. expected) end
  return object
 end
 requireFile(id, path)
 local ok, result = pcall(create, path)
 if not ok then fail(id, path, result) end
 cache[key] = result
 return result
end
function Assets.image(id, key)
 key = normalize(id, key)
 return cached(id, 'images/' .. key .. '.png', 'images', 'Image', love.graphics.newImage)
end
function Assets.sound(id, key)
 key = normalize(id, key)
 return cached(id, 'sounds/' .. key .. '.ogg', 'audio', 'SoundData', love.sound.newSoundData)
end
function Assets.music(id, key)
 key = normalize(id, key)
 return cached(id, 'music/' .. key .. '.ogg', 'audio', 'Source', function(path) return love.audio.newSource(path, 'stream') end)
end
function Assets.font(id, key, size)
 key = normalize(id, key)
 size = size or 12
 if type(size) ~= 'number' or size <= 0 or size == math.huge or size ~= size or size % 1 ~= 0 then
  fail(id, key, 'font size must be a positive finite integer')
 end
 return cached(id, 'fonts/' .. key, 'fonts', 'Font', function(path) return love.graphics.newFont(path, size, 'light') end, '_' .. size)
end
local bindings = {
 getAddonPath = 'getPath', readAddonText = 'readText', readAddonJSON = 'readJSON',
 getAddonImage = 'image', getAddonSound = 'sound', getAddonMusic = 'music', getAddonFont = 'font'
}
function Assets.bind(script)
 local reference = setmetatable({script}, {__mode = 'v'})
 for alias, method in pairs(bindings) do
  script:set(alias, function(...)
   local owner = reference[1]
   if not owner or owner.closed then error('Addon assets cannot be used by a closed script', 2) end
   return Assets[method](...)
  end)
 end
end
return Assets
