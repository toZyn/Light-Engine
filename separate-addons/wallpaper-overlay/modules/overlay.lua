-- Explicit import only. Never reads wallpaper or changes windows on load.
local Toolkit = {}

function Toolkit.new(bridge)
 local closed, overlay, wallpaperConsent = false, false, false
 local layers = {}
 local owner, closeListener = script, nil
 local api = {}
 local function fail(message)
  message = '[Wallpaper Overlay] '..tostring(message)
  if type(reportRecoverableError)=='function' then pcall(reportRecoverableError,message) end
  return nil,message
 end
 local function ask(message)
  if not (love.window and love.window.showMessageBox) then return false end
  local ok,result=pcall(love.window.showMessageBox,'Wallpaper & Overlay',message,
   { 'Allow', 'Deny', escapebutton=2 },'info',true)
  return ok and result==1
 end
 local function call(name,...)
  if not bridge or type(bridge[name])~='function' then return nil,'native '..name..' backend unavailable' end
  local ok,value,err=pcall(bridge[name],...)
  if not ok then return nil,tostring(value) end
  return value,err
 end
 function api.capabilities()
  local caps=call('capabilities')
  return {imageBackground=true,overlay=type(caps)=='table' and caps.overlay==true or false,
   wallpaper=type(caps)=='table' and caps.wallpaper==true or false}
 end
 function api.requestOverlay(options)
  if closed then return fail('closed') end
  if not api.capabilities().overlay then return fail('native overlay backend unavailable on this runtime') end
  if overlay then
   if call('hasPermission','overlay')==true then return true end
   api.stopOverlay()
   return fail('OS overlay permission revoked')
  end
  if not ask('Allow this mod to display over other applications? The system must also grant permission. You can revoke access in system settings.') then
   return fail('permission denied')
  end
  if call('hasPermission','overlay')~=true then
   local requested,err=call('requestPermission','overlay')
   if requested~=true then return fail(err or 'OS permission request denied') end
   -- Opening Android Settings is NOT a permission grant. Caller may retry
   -- after returning; permission is checked every time before activation.
   if call('hasPermission','overlay')~=true then return nil,'OS permission pending; retry after returning from Settings' end
  end
  local enabled,err=call('beginOverlay',options or {})
  if enabled~=true then return fail(err or 'native overlay activation failed') end
  overlay=true
  return true
 end
 function api.stopOverlay()
  if not overlay then return true end
  local stopped,err=call('endOverlay')
  if stopped~=true then return fail(err or 'native overlay cleanup failed') end
  overlay=false
  return true
 end
 function api.getWallpaper()
  if closed then return fail('closed') end
  if not api.capabilities().wallpaper then return fail('native wallpaper backend unavailable; use a user-provided image') end
  if not wallpaperConsent then
   if not ask('Allow this mod to read your current wallpaper image? Nothing is uploaded by this add-on.') then return fail('permission denied') end
   wallpaperConsent=true
  end
  local image,err=call('getWallpaper')
  if not image then return fail(err or 'wallpaper access denied by OS') end
  return image
 end
 function api.createBackground(image,scene)
  if closed then return fail('closed') end
  if not ask('Allow this mod to display the supplied image as its game background?') then return fail('permission denied') end
  if not image or type(image.typeOf)~='function' or not image:typeOf('Image') then return fail('background must be a LÖVE Image') end
  if not scene or type(scene.insert)~='function' or type(scene.remove)~='function' then return fail('background needs a native scene Group') end
  local sprite=Sprite(0,0,image)
  sprite.scrollFactor:set()
  -- Render the original texture; no compression, copies or resampling files.
  local function layout()
   local scale=math.max(game.width/image:getWidth(),game.height/image:getHeight())
   sprite.scale:set(scale,scale)
   sprite.x=(game.width-image:getWidth()*scale)/2
   sprite.y=(game.height-image:getHeight()*scale)/2
  end
  layout()
  sprite.update=function(_,dt) layout() end
  scene:insert(1,sprite)
  layers[#layers+1]={sprite=sprite,scene=scene}
  return sprite
 end
 function api.close()
  local stopped,err=api.stopOverlay()
  for i=#layers,1,-1 do
   local item=layers[i]
   item.scene:remove(item.sprite);item.sprite:destroy();layers[i]=nil
  end
  wallpaperConsent=false;closed=true
  if stopped and owner and not owner.closed and closeListener then
   owner.closeCallback:remove(closeListener)
  end
  if stopped then bridge=nil;owner=nil;closeListener=nil end
  return stopped,err
 end
 if owner and owner.closeCallback then
  closeListener=function()api.close()end
  owner.closeCallback:add(closeListener)
 end
 return api
end

return Toolkit
