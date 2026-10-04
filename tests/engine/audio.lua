-- Run as main.lua in a disposable LÖVE runner containing this checkout.
-- Uses real engine classes/cache and real LÖVE Sources/Video, without menus.
io.stdout:setvbuf('no')
require 'loxel'
Mods = {root = 'mods'}
Addons = {root = 'addons', all = {}}
paths = require 'funkin.backend.paths'
Video = require 'funkin.backend.video'

local tests, sounds, sources, videos = {}, {}, {}, {}
local function test(name, run) tests[#tests + 1] = {name, run} end
local function sound(asset)
 local s = Sound(); sounds[#sounds + 1] = s
 return s:load(asset)
end
local function source()
 local s = love.audio.newSource('assets/music/pause/railways.ogg', 'stream')
 sources[#sources + 1] = s
 return s
end
local function video(looped)
 local drawable = love.graphics.newVideo('assets/videos/ughCutscene.ogv')
 videos[#videos + 1] = drawable
 local s = drawable:getSource(); sources[#sources + 1] = s
 return Video(0, 0, drawable, false, false, looped)
end
local function released(s) return not pcall(s.isPlaying, s) end

test('cached Source remains playable after paths.clearCache', function()
 local cached = paths.getMusic('pause/railways')
 local s = sound(cached):play(0.5, true)
 paths.clearCache()
 assert(s.looped and s:isPlaying(), 'cache eviction invalidated Sound playback')
 assert(released(cached), 'test cache did not evict its original Source')
end)

test('Sounds sharing one Source have independent controls', function()
 local cached = source()
 local a, b = sound(cached), sound(cached)
 a:play(0.25, true, 0.75); b:play(0.75, false, 1.25)
 a:pause()
 assert(b:isPlaying(), 'pausing one Sound paused the other')
 assert(math.abs(a._source:getVolume() - 0.25) < 0.001, 'volume was shared')
 assert(math.abs(a._source:getPitch() - 0.75) < 0.001, 'pitch was shared')
 assert(a.looped and not b.looped, 'loop state was shared')
 a.time = 5; b.time = 2
 assert(math.abs(a.time - 5) < 0.1 and math.abs(b.time - 2) < 0.1, 'seek positions were shared')
 assert(not cached:isPlaying(), 'cache-owned original entered the audio pool')
 a:destroy()
 assert(b:isPlaying(), 'destroying one Sound stopped the other')
end)

test('cleanup stops and releases owned Source but preserves cache original', function()
 local cached = source()
 local s = sound(cached):play(1, true)
 local owned = s._source
 local before = love.audio.getActiveSourceCount()
 s:destroy(); s:destroy()
 assert(love.audio.getActiveSourceCount() == before - 1, 'owned playback survived cleanup')
 assert(released(owned), 'owned Source was not released')
 assert(not released(cached), 'borrowed cache original was released')
end)

test('SoundData creates an independently owned Source', function()
 local data = love.sound.newSoundData(44100, 44100, 16, 1)
 local a, b = sound(data), sound(data)
 data:release()
 a:play(1, true); b:play(1, true)
 local owned = a._source
 a:destroy()
 assert(released(owned), 'SoundData Source was not released')
 assert(b:isPlaying(), 'SoundData Sources shared playback')
end)

test('released external references cannot crash access or cleanup', function()
 local s = sound(source()):play(1, true)
 local complete = 0
 s.onComplete = function() complete = complete + 1 end
 s._source:release()
 s:update(1/60)
 assert(complete == 0, 'external release was mistaken for natural completion')
 assert(not s:isPlaying(), 'released Sound reported playing')
 assert(s.duration == -1 and s.time == 0 and not s.looped, 'released getters lack defaults')
 s.time = 0; s.volume = 0.5; s.pitch = 1; s.looped = true
 s:play(); s:update(1/60); s:onFocus(false); s:onFocus(true)
 s:destroy(); s:destroy()
end)

test('explicit false disables looping and remains a false property', function()
 local s = sound(source()):play(1, true)
 s.looped = false
 assert(s.looped == false and not s._source:isLooping(), 'explicit false did not disable looping')
end)

test('genuine Source argument errors remain visible', function()
 local s = sound(source())
 assert(not pcall(function() s.pitch = 0 end), 'invalid Source pitch was silently accepted')
end)

test('invalid load errors remain visible', function()
 local s = source(); s:release()
 assert(not pcall(function() sound(s) end), 'released Source load was silently accepted')
 assert(not pcall(function() sound({}) end), 'invalid asset load was silently accepted')
end)

test('Sound focus resumes active playback and respects explicit stop', function()
 local s = sound(source()):play(1, true)
 s:onFocus(false); assert(not s:isPlaying(), 'focus loss did not pause')
 s:onFocus(true); assert(s:isPlaying(), 'focus gain did not resume')
 s:onFocus(false); s:stop(); s:onFocus(true)
 assert(not s:isPlaying(), 'focus gain resumed explicitly stopped Sound')
end)

test('Video reports duration rather than current playback position', function()
 local v = video()
 assert(v:getDuration() == v.__source:getDuration(), 'Video duration is playback position')
 v:destroy()
end)

test('Video focus does not start dormant playback', function()
 local v = video()
 v:focus(false); v:focus(true)
 assert(not v.video:isPlaying(), 'focus gain started dormant Video')
 v:destroy()
end)

test('Video focus preserves manual pause and resumes active playback', function()
 local v = video()
 v:play(); v:pause(); v:focus(false); v:focus(true)
 assert(not v.video:isPlaying(), 'focus gain resumed manually paused Video')
 v:play(); v:focus(false)
 assert(not v.video:isPlaying(), 'focus loss did not pause Video')
 v:focus(true); assert(v.video:isPlaying(), 'focus gain did not resume Video')
 v:focus(false); v:pause(); v:focus(true)
 assert(not v.video:isPlaying(), 'explicit pause while unfocused was ignored')
 v:destroy()
end)

test('dormant and paused looped Videos do not start in update', function()
 local v = video(true)
 v:update(1/60)
 assert(not v.video:isPlaying(), 'update started dormant looping Video')
 v:play(); v:pause(); v:update(1/60)
 assert(not v.video:isPlaying(), 'update restarted paused looping Video')
 v:destroy()
end)

test('destroyed Video stops audio without requiring mod disposal', function()
 local v = video()
 local drawable, audio = v.video, v.__source
 v:play(); assert(audio:isPlaying(), 'video fixture audio did not play')
 v:destroy(); v:destroy()
 assert(not audio:isPlaying(), 'destroyed Video audio remains in playback pool')
 assert(not drawable:isPlaying(), 'destroyed Video drawable remains playing')
 v:focus(true); v:update(1/60)
end)

test('nonplaying started Video completes once', function()
 local v = video()
 local complete = 0
 v.onComplete = function() complete = complete + 1 end
 v:play(); v.video:pause()
 v:update(1/60); v:update(1/60)
 assert(complete == 1, 'Video completion callback repeated')
 v:destroy()
end)

if love.filesystem.getInfo('mods/pibby-rescripted/data/classes/pibbyaudio.lua') then
test('Pibby cache eviction hook does not duplicate engine-owned music', function()
 package.path = package.path .. ';mods/pibby-rescripted/data/classes/?.lua'
 require('pibbyaudio').install(false)
 local music = game.sound.playMusic(paths.getMusic('pause/railways'), 1, true)
 local owned, count = music._source, love.audio.getActiveSourceCount()
 paths.clearCache()
 assert(music._source == owned, 'Pibby hook created an unnecessary second clone')
 assert(music:isPlaying(), 'Pibby hook stopped menu music')
 assert(love.audio.getActiveSourceCount() == count, 'cache eviction orphaned duplicate music')
 music:destroy()
end)
else print('SKIP: external Pibby hook integration (mod not installed)') end

local function cleanup()
 for _, s in ipairs(sounds) do pcall(s.destroy, s) end
 for _, v in ipairs(videos) do pcall(v.pause, v); pcall(v.release, v) end
 for _, s in ipairs(sources) do pcall(s.stop, s); pcall(s.release, s) end
 sounds, sources, videos = {}, {}, {}
end

function love.run()
 local failed = 0
 for _, t in ipairs(tests) do
  local ok, err = xpcall(t[2], debug.traceback)
  print((ok and 'PASS: ' or 'FAIL: ') .. t[1])
  if not ok then failed = failed + 1; print(err) end
  cleanup()
 end
 print(('AUDIO TESTS: %d passed, %d failed'):format(#tests - failed, failed))
 return function() return failed == 0 and 0 or 1 end
end
