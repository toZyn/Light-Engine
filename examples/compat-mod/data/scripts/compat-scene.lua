-- A native scene overlay: text, timed tween and camera fade, with scoped cleanup.
local scene = Script.createCompatibility(state, script)
local pulsed = false

function onCreate()
 makeLuaText('sceneCaption', 'Complex scenes, native Lua', 500, 40, 70)
 setTextSize('sceneCaption', 24)
 setTextColor('sceneCaption', 'E8793E')
 setTextAlignment('sceneCaption', 'left')
 addLuaText('sceneCaption')
 if state.camHUD then
  setObjectCamera('sceneCaption', 'hud')
  cameraFade('hud', '000000', .3, true, true, 'sceneReveal')
 end
 doTweenX('captionSlide', 'sceneCaption', 80, .6, 'quadInOut')
end

function onUpdate(dt)
 setTextString('sceneCaption', ('Song %.1fs'):format(getSongPosition() / 1000))
 if not pulsed and getSongPosition() > 1000 and state.camHUD then
  pulsed = true
  cameraFlash('hud', 'E8793E', .15, false, 'sceneFlash')
 end
end

function onBeatHit()
 doTweenAlpha('captionBeat', 'sceneCaption', curBeat % 2 == 0 and 1 or .65, .2, 'sineInOut')
end

function create() scene:forward('create') end
function postCreate() scene:forward('postCreate') end
function update(dt) scene:update(dt) end
function beat(value) scene:forward('beat', value) end
function leave() scene:dispose() end
