-- Run as main.lua in a temporary LÖVE checkout runner.
require 'loxel'
require 'funkin'
local function contains(text, needle) assert(text and text:find(needle, 1, true), 'missing context: ' .. needle) end
local function raises(fn, needle)
 local ok, err = pcall(fn); assert(not ok, 'operation should fail'); contains(tostring(err), needle)
end
function love.load()
 local ok, err = xpcall(function()
  love.window.setMode(320, 240, {vsync = 0}); game.width, game.height = 320, 240
  local Assets = require 'funkin.backend.modding.addonassets'
  Addons.root, Addons.all = 'addon-assets-fixtures', {{path = 'alpha', active = true}, {path = 'beta', active = true}, {path = 'Library Tools.v1', active = true}, {path = 'مكتبة', active = true}}
  Mods.root, Mods.currentMod = 'mod-assets-fixtures', 'override'
  local soundBytes = assert(love.filesystem.read('assets/sounds/scrollMenu.ogg'))
  local fontBytes = assert(love.filesystem.read('assets/fonts/vcr.ttf'))
  for index, id in ipairs({'alpha', 'beta', 'Library Tools.v1', 'مكتبة'}) do
   local base = Addons.root .. '/' .. id
   for _, folder in ipairs({'images/nested', 'sounds', 'music', 'fonts', 'data'}) do love.filesystem.createDirectory(base .. '/' .. folder) end
   local image = love.image.newImageData(index + 1, 2)
   image:encode('png', base .. '/images/nested/shared.png'); image:release()
   love.filesystem.write(base .. '/sounds/shared.ogg', soundBytes)
   love.filesystem.write(base .. '/music/shared.ogg', soundBytes)
   love.filesystem.write(base .. '/fonts/shared.ttf', fontBytes)
   love.filesystem.write(base .. '/data/shared.txt', id)
   love.filesystem.write(base .. '/data/shared.json', '{"owner":"' .. id .. '","count":2}')
  end
  love.filesystem.createDirectory(Mods.root .. '/override/images/nested')
  local override = love.image.newImageData(11, 2)
  override:encode('png', Mods.root .. '/override/images/nested/shared.png'); override:release()
  local originalGetPath = paths.getPath
  paths.getPath = function() error('global asset precedence must not be used') end
  assert(Assets.getPath('alpha', './data//shared.txt') == Addons.root .. '/alpha/data/shared.txt')
  assert(Assets.readText('alpha', 'data/shared.txt') == 'alpha' and Assets.readJSON('beta', 'data/shared.json').owner == 'beta')
  assert(Assets.readText('Library Tools.v1', 'data/shared.txt') == 'Library Tools.v1')
  assert(Assets.readText('مكتبة', 'data/shared.txt') == 'مكتبة')
  assert(Assets.image('Library Tools.v1', 'nested/shared'):getWidth() == 4 and Assets.image('مكتبة', 'nested/shared'):getWidth() == 5, 'existing spaced/dotted/Unicode addon names must remain supported')
  raises(function() Assets.getPath('library Tools.v1', 'data/shared.txt') end, 'unknown')
  local alpha = Assets.image('alpha', 'nested/shared'); local beta = Assets.image('beta', 'nested/shared')
  assert(alpha ~= beta and alpha:getWidth() == 2 and beta:getWidth() == 3, 'addon IDs must separate same-name assets from mod overrides')
  assert(Assets.image('alpha', './nested//shared') == alpha, 'normalized paths must share cache')
  assert(paths.images[Addons.root .. '/alpha/images/nested/shared.png'] == alpha, 'image cache key must be the actual addon path')
  local data = Assets.sound('alpha', 'shared'); local music = Assets.music('alpha', 'shared')
  assert(data:typeOf('SoundData') and music:typeOf('Source'), 'sound/music helpers must return native typed resources')
  assert(Assets.sound('alpha', 'shared') == data and Assets.music('alpha', 'shared') == music)
  local font = Assets.font('alpha', 'shared.ttf', 16); local larger = Assets.font('alpha', 'shared.ttf', 28)
  assert(font ~= larger and font:getHeight() < larger:getHeight() and font:getWidth('ABC') > 0)
  assert(Assets.font('alpha', 'shared.ttf', 16) == font)
  local imageCacheKey = Addons.root .. '/alpha/images/nested/shared.png'
  paths.images[imageCacheKey] = data
  raises(function() Assets.image('alpha', 'nested/shared') end, 'type Image')
  assert(data:getSampleCount() > 0, 'typed cache rejection must not release borrowed resources')
  paths.images[imageCacheKey] = alpha
  paths.getPath = originalGetPath
  for _, invalid in ipairs({'../alpha', '/alpha', 'alpha/beta', 'alpha\\beta', 'alpha:beta', '.', '..', 'alpha' .. string.char(10)}) do raises(function() Assets.getPath(invalid, 'data/shared.txt') end, 'addon ID') end
  for _, invalid in ipairs({'../shared.txt', 'data/../shared.txt', '/data/shared.txt', 'C:/data/shared.txt', 'data\\shared.txt', ''}) do raises(function() Assets.getPath('alpha', invalid) end, 'relative path') end
  raises(function() Assets.font('alpha', 'shared.ttf', 0) end, 'font size')
  raises(function() Assets.image('alpha', 'missing') end, 'addon-assets-fixtures/alpha/images/missing.png')
  raises(function() Assets.readText('unknown', 'data/shared.txt') end, 'unknown')
  Addons.all[2].active = false
  raises(function() Assets.image('beta', 'nested/shared') end, 'inactive')
  assert(beta:getWidth() == 3, 'disabling an addon must not release borrowed assets')
  Addons.all[2].active = true
  Addons.all[1].active = false
  raises(function() Assets.font('alpha', 'shared.ttf', 16) end, 'inactive')
  raises(function() Assets.music('alpha', 'shared') end, 'inactive')
  raises(function() Assets.readJSON('alpha', 'data/shared.json') end, 'inactive')
  assert(font:getHeight() > 0 and music:getChannelCount() > 0, 'disable must preserve borrowed fonts and Sources')
  Addons.all[1].active = true
  love.filesystem.write(Addons.root .. '/alpha/data/broken.json', '{broken')
  love.filesystem.createDirectory('tests/engine')
  love.filesystem.write('tests/engine/addon-assets-script.lua', [[
function brokenJSON() return readAddonJSON('alpha', 'data/broken.json') end
]])
  local script = Script('tests/engine/addon-assets-script.lua', true, true, true)
  assert(not script.closed); Assets.bind(script)
  local held = script.variables.getAddonImage
  assert(held('alpha', 'nested/shared') == alpha)
  script:call('brokenJSON')
  assert(script.__failedfunc.brokenJSON, 'JSON errors must reach native Script callback isolation')
  local report = love.filesystem.read('diagnostics/last-error.txt')
  contains(report, 'addon-assets-fixtures/alpha/data/broken.json'); contains(report, 'addon-assets-script.lua'); contains(report, 'stack traceback:')
  script:close(); raises(function() held('alpha', 'nested/shared') end, 'closed script')
  local function abandonedBinding()
   local abandoned = Script('tests/engine/addon-assets-script.lua', true, true, true)
   Assets.bind(abandoned)
   local helper = abandoned.variables.getAddonImage
   local weak = setmetatable({abandoned}, {__mode = 'v'})
   abandoned:close()
   return helper, weak
  end
  local orphanedHelper, weakScript = abandonedBinding()
  collectgarbage('collect'); collectgarbage('collect')
  assert(weakScript[1] == nil, 'retained asset helper must not keep closed scripts alive')
  raises(function() orphanedHelper('alpha', 'nested/shared') end, 'closed script')
  local sound1, sound2 = Sound(), Sound(); sound1:load(music); sound2:load(music)
  sound1:play(.3, true); sound2:play(.7, true)
  assert(sound1._source ~= sound2._source and sound1._source ~= music and sound2._source ~= music, 'playback must own independent Sources')
  sound1:cleanup(); assert(sound2:isPlaying() and pcall(music.getChannelCount, music), 'cleanup must preserve borrowed cache and second sound')
  paths.clearCache()
  assert(sound2:isPlaying(), 'cache eviction must preserve owned playback Source')
  assert(not pcall(alpha.getWidth, alpha), 'real cache clear must release addon images')
  assert(not pcall(font.getHeight, font), 'real cache clear must release addon fonts')
  sound2:cleanup()
  require('funkin.backend.diagnostics').finish()
  print('ADDON ASSETS PASSED: exact active IDs, same-name isolation, normalization/rejection, typed native caches, Script JSON diagnostics, closed bindings and independent audio lifetime')
 end, debug.traceback)
 if not ok then print('ADDON ASSETS FAIL: ' .. tostring(err)) end
 love.event.quit(ok and 0 or 1)
end
function love.update() end
function love.draw() end
function love.quit() end
function love.errorhandler(message) print(message); return function() return 1 end end
