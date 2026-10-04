-- Run as main.lua in a temporary LÖVE checkout runner.
require 'loxel'
require 'funkin'
function love.load()
 local ok,err=xpcall(function()
  love.window.setMode(320,240,{vsync=0}); game.width,game.height=320,240
  util.playMenuMusic(false)
  local music=game.sound.music
  local first=music._source
  music.time=1; music.volume=.33
  assert(music:isPlaying(),'native menu music did not start')
  util.playMenuMusic(true)
  assert(music._source==first,'repeated playMenuMusic replaced the owned Source')
  assert(math.abs(music.time-1)<.1,'repeated playMenuMusic reset the position')
  assert(math.abs(music.volume-.33)<.001,'repeated playMenuMusic reset the volume/fade')
  assert(music._asset==paths.getMusic('freakyMenu'),'loaded asset identity missing')
  local asset=paths.getMusic('pause/railways')
  game.sound.playMusic(asset,.5,true)
  local second=music._source
  assert(second~=first and music._asset==asset,'new asset did not replace playback identity')
  assert(not pcall(first.isPlaying,first),'replacing asset retained old owned Source')
  music.time=2
  paths.clearCache()
  assert(not pcall(asset.isPlaying,asset),'test did not evict cached original')
  assert(music:isPlaying() and math.abs(music.time-2)<.1,'cache eviction stopped owned playback')
  util.playMenuMusic(false)
  assert(music._source~=second and music._asset==paths.getMusic('freakyMenu'),'switching back to menu did not replace asset')
  music:cleanup()
  assert(music._asset==nil and music._source==nil,'cleanup retained loaded asset identity')
  game.sound.destroy(true)
  print('MENU AUDIO PASS: repeated menu calls preserve Source/time/volume; new assets switch; cache eviction preserves owned playback; cleanup clears identity')
 end,debug.traceback)
 if not ok then print('MENU AUDIO FAIL '..err) end
 love.event.quit(ok and 0 or 1)
end
function love.update() end
function love.draw() end
function love.quit() end
function love.errorhandler(err) print(err); return function() return 1 end end
