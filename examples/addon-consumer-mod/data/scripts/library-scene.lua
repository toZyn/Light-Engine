-- Enable the library-addon addon before selecting this native mod.
local ready=checkAddonDependencies({{id='library-addon',module='scene'}})
if not ready then return end -- Report the dependency and omit this scene's callbacks.
local Scene=require('addon:library-addon/scene')
local compat=Script.createCompatibility(state,script)
function onCreate()
 Scene.caption('libraryCaption','Reusable addon modules',{x=40,y=90})
 if state.camHUD then Scene.reveal('hud',.3) end
 doTweenX('librarySlide','libraryCaption',80,.4,'quadInOut')
end
function onUpdate(dt)
 setTextString('libraryCaption',('Song %.1fs'):format(Scene.timing.seconds(getSongPosition())))
end
function onBeatHit()
 doTweenAlpha('libraryBeat','libraryCaption',curBeat%2==0 and 1 or .6,.2)
end
function create() compat:forward('create') end
function update(dt) compat:update(dt) end
function beat(value) compat:forward('beat',value) end
function leave() compat:dispose() end
