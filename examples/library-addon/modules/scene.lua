-- Imports share the caller Script's addon cache; no automatic global effects.
local Timing=requireAddon('library-addon','timing')
local Scene={timing=Timing}
function Scene.caption(tag,title,options)
 options=options or {}
 makeLuaText(tag,title,options.width or 500,options.x or 40,options.y or 60)
 setTextSize(tag,options.size or 24)
 setTextColor(tag,options.color or 'E8793E')
 addLuaText(tag)
 if state.camHUD then setObjectCamera(tag,'hud') end
 return tag
end
function Scene.reveal(camera,seconds)
 return cameraFade(camera,'000000',seconds or .3,true,true)
end
return Scene
