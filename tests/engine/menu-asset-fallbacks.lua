check('intro texts merge base and mod without dropping literal separators', function()
 local assets = require 'funkin.backend.menuassets'
 local oldRead, oldPath, oldMods, oldCurrent = love.filesystem.read, paths.getPath, paths.getMods, Mods.currentMod
 local values = {base='base--text\nrepeat--entry\n', mod=' repeat--entry\r\nmod--entry\na-b--c-d\n'}
 local ok, err = xpcall(function()
  paths.getPath = function() return 'base' end
  paths.getMods = function() return 'mod' end
  Mods.currentMod = 'fixture'
  love.filesystem.read = function(path) return values[path] end
  local lines = assets.introLines()
  assert(#lines == 4 and lines[1][1] == 'base' and lines[3][1] == 'mod')
  assert(lines[4][1] == 'a-b' and lines[4][2] == 'c-d')
  values.mod = ''
  assert(#assets.introLines() == 2)
  values.mod = nil
  assert(#assets.introLines() == 2)
  values.base = ''
  assert(#assets.introLines() == 0)
 end, debug.traceback)
 love.filesystem.read, paths.getPath, paths.getMods, Mods.currentMod = oldRead, oldPath, oldMods, oldCurrent
 assert(ok, err)
end)

check('menu characters accept Psych image and recover missing or incomplete JSON', function()
 local assets = require 'funkin.backend.menuassets'
 local oldRead, oldPath = love.filesystem.read, paths.getPath
 local defaults = assert(oldRead('assets/data/weeks/characters/bf.json'))
 local value
 local ok, err = xpcall(function()
  paths.getPath = function(_, allowMods) return allowMods == false and 'base' or 'mod' end
  love.filesystem.read = function(path) return path == 'base' and defaults or value end
  for _, source in ipairs({'{}', '{', '{"position":[null,"bad"],"scale":null}'}) do
   value = source
   local data, directory, fallback = assets.character('test')
   assert(data.sprite == 'bf' and data.scale == .8 and data.position[1] == 60 and data.position[2] == 10)
   assert(fallback and directory == 'menus/storymenu/characters/')
  end
  value = nil
  assert(assets.character('missing').sprite == 'bf')
  value = '{"image":"custom","position":[1,2],"scale":1,"idle_anim":"idle"}'
  local data, directory, fallback = assets.character('test')
  assert(data.sprite == 'custom' and directory == 'menucharacters/' and not fallback)
 end, debug.traceback)
 love.filesystem.read, paths.getPath = oldRead, oldPath
 assert(ok, err)
end)

check('Light recovery extensions emit one warning per recovery path', function()
 local assets = assert(love.filesystem.load('funkin/backend/menuassets.lua'))()
 local read, path, log = love.filesystem.read, paths.getPath, Logger.log
 local defaults = assert(read('assets/data/weeks/characters/bf.json'))
 local warnings = {}
 local ok, err = xpcall(function()
  paths.getPath = function(_, allowMods) return allowMods == false and 'base' or 'incomplete-fixture' end
  love.filesystem.read = function(file) return file == 'base' and defaults or '{}' end
  Logger.log = function(level, message)
   assert(level == 'warn' and message:find('[Light extension]', 1, true))
   warnings[#warnings + 1] = message
  end
  assets.character('incomplete')
  assets.character('incomplete')
  assert(#warnings == 1)
  love.filesystem.read = function() return '' end
  assets.introLines()
  assets.introLines()
  assert(#warnings == 2)
 end, debug.traceback)
 love.filesystem.read, paths.getPath, Logger.log = read, path, log
 assert(ok, err)
end)
