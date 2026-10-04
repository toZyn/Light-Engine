io.stdout:setvbuf('no')
function love.errorhandler(e) print(tostring(e)..'\n'..debug.traceback());return function()return 1 end end
function love.quit()end
require 'loxel'
require 'funkin'
function love.load()
 local ok,err=xpcall(function()
  love.window.setMode(320,240,{vsync=0});game.width,game.height=320,240
  local module=assert(love.filesystem.load('separate-addons/wallpaper-overlay/modules/overlay.lua'))()
  local notices={};local original=love.window.showMessageBox
  local accept=false
  love.window.showMessageBox=function(title,message,buttons) notices[#notices+1]=message;return accept and 1 or 2 end
  local api=module.new()
  local allowed,message=api.requestOverlay()
  assert(not allowed and message:find('native',1,true),'stock runtime falsely advertised native overlay')
  local image=love.graphics.newImage(love.image.newImageData(64,32))
  local scene=Group()
  local layer,denied=api.createBackground(image,scene)
  assert(layer==nil and denied:find('denied',1,true) and #scene.members==0,'denied background changed scene')
  accept=true
  layer=assert(api.createBackground(image,scene))
  assert(#scene.members==1 and layer.texture==image,'background copied or replaced source artwork')
  api.close();assert(#scene.members==0,'addon cleanup left its background in scene')
  local granted=false;local started=0;local stopped=0;local requested=0
  local bridge={capabilities=function()return {overlay=true,wallpaper=true}end,
   hasPermission=function()return granted end,requestPermission=function()requested=requested+1;return true end,
   beginOverlay=function()started=started+1;return true end,endOverlay=function()stopped=stopped+1;return true end,
   getWallpaper=function()return image end}
  api=module.new(bridge)
  local pending=api.requestOverlay();assert(not pending and requested==1 and started==0,'settings intent confused with OS grant')
  granted=true;assert(api.requestOverlay() and started==1)
  assert(api.getWallpaper()==image)
  granted=false;local revoked,why=api.requestOverlay();assert(not revoked and why:find('revoked',1,true) and stopped==1,'cached overlay ignored OS permission revocation')
  api.close();assert(stopped==1)
  assert(not api.requestOverlay(),'closed addon reopened native overlay')
  script={closeCallback=Signal(),closed=false}
  for i=1,20 do local temporary=module.new(bridge);temporary.close() end
  assert(#script.closeCallback.listeners==0,'explicit close retained addon listener/backend')
  script=nil
  love.window.showMessageBox=original;image:release()
  print('OVERLAY ADDON PASSED: denial, exact-image layer, cleanup and native permission contract');love.event.quit(0)
 end,debug.traceback)
 if not ok then print(err);love.event.quit(1) end
end
