-- Standalone native LÖVE fixture; the window and cameras are real engine objects.
io.stdout:setvbuf('no')
require 'loxel'
local passed, failed = 0, 0
local function check(name, fn)
 local ok, err = xpcall(fn, debug.traceback)
 if ok then passed=passed+1; print('PASS '..name)
 else failed=failed+1; print('FAIL '..name..': '..err) end
end
local function mode(w,h)
 assert(love.window.setMode(w,h,{fullscreen=false,resizable=true,usedpiscale=false}))
 game.width,game.height=1280,720
end
local function near(a,b) assert(math.abs(a-b)<.001, tostring(a)..' ~= '..tostring(b)) end
function love.load()
 check('portrait adaptive resize retains a usable game viewport',function()
  mode(360,640);Project.adaptableWidth=true
  game.resize(360,640)
  assert(game.width==Project.width and game.height==Project.height,'portrait orientation cropped the logical game screen')
  local view=game.display.getViewport()
  near(view.width,360);near(view.height,202.5)
  local x,y=game.display.gameToWindow(640,360)
  near(x,180);near(y,320)
  Project.adaptableWidth=false
 end)
 check('adaptive OS resize preserves native size and project configuration',function()
  mode(640,480); local original=Project.width; Project.adaptableWidth=true
  game.resize(640,480)
  local w,h=love.graphics.getDimensions(); assert(w==640 and h==480,'resize changed the native window')
  assert(game.width==960 and game.height==720,'adaptive viewport not updated')
  assert(Project.width==original,'resize overwrote project configuration')
  Project.adaptableWidth=false
 end)
 check('zero size notification cannot poison the logical viewport',function()
  mode(640,480); Project.adaptableWidth=true; game.resize(0,0);game.resize(0/0,480);game.resize(640,math.huge)
  assert(game.width==1280 and game.height==720,'zero size corrupted viewport')
  Project.adaptableWidth=false
 end)
 check('fixed viewport retains camera canvas and render quality on window resize',function()
  mode(640,480); Project.adaptableWidth=false
  local c=Camera(0,0,1280,720); local canvas=c.canvas; local quality=c.resolutionX
  game.cameras.add(c); assert(love.window.updateMode(800,400)); game.resize(800,400)
  assert(game.width==1280 and game.height==720 and c.canvas==canvas and c.resolutionX==quality)
  game.cameras.remove(c)
 end)
 check('adaptive viewport resizes only cameras covering the logical screen',function()
  mode(640,480); Project.adaptableWidth=true
  local full=Camera(0,0,1280,720);local custom=Camera(0,0,320,240)
  game.cameras.add(full);game.cameras.add(custom);local quality=full.resolutionX;local canvas=custom.canvas
  game.resize(640,480)
  assert(full.width==960 and full.height==720 and full.resolutionX==quality,'screen camera not adapted')
  assert(custom.width==320 and custom.height==240 and custom.canvas==canvas,'custom viewport was resized')
  game.cameras.remove(full);game.cameras.remove(custom);Project.adaptableWidth=false
 end)
 check('native monitor list and invalid selection do not change the window',function()
  mode(640,480);local displays=game.display.getMonitors()
  assert(#displays==love.window.getDisplayCount() and #displays>=1)
  print('NATIVE MONITORS: '..#displays)
  for i,d in ipairs(displays) do assert(d.index==i and d.width>0 and d.height>0 and type(d.name)=='string') end
  local w,h,flags=love.window.getMode()
  for _,i in ipairs({0,-1,#displays+1,1.5}) do local ok,err=game.display.selectMonitor(i);assert(not ok and type(err)=='string') end
  local ww,hh,ff=love.window.getMode();assert(w==ww and h==hh and flags.display==ff.display)
  local original=game.display.getMonitor()
  for i=1,#displays do
   local previous=game.display.getMonitor()
   local success,reason=game.display.selectMonitor(i)
   if success then assert(game.display.getMonitor()==i,'native monitor did not change')
   else
    assert(type(reason)=='string' and game.display.getMonitor()==previous,'rejection lost previous monitor')
    print('NATIVE MONITOR REJECTED: '..i..': '..reason)
   end
   local ww,hh=love.graphics.getDimensions();assert(ww==640 and hh==480,'monitor selection resized a window')
  end
  assert(game.display.selectMonitor(original))
 end)
 check('native positioning errors return a reason and restoration errors cannot escape',function()
  mode(640,480)
  local count,dimensions,position=love.window.getDisplayCount,love.window.getDesktopDimensions,love.window.setPosition
  local calls=0
  -- Boundary fault injection supplements real display operations above. It is
  -- not a simulation of successful physical monitor migration or hotplug.
  love.window.getDisplayCount=function() return 2 end
  love.window.getDesktopDimensions=function() return dimensions(1) end
  love.window.setPosition=function() calls=calls+1;error('injected native positioning rejection') end
  local ok,err=xpcall(function()
   local success,reason=game.display.selectMonitor(2)
   assert(not success and reason:find('injected native positioning rejection',1,true),'position error was lost')
   assert(reason:find('Previous window restoration failed',1,true),'restoration error was lost')
   assert(calls==2,'native position was not attempted during change and restoration')
   local w,h=love.graphics.getDimensions();assert(w==640 and h==480)
  end,debug.traceback)
  love.window.getDisplayCount,love.window.getDesktopDimensions,love.window.setPosition=count,dimensions,position
  assert(ok,err)
 end)
 check('explicit desktop resize fits the monitor without changing logical resolution or quality',function()
  mode(640,480);Project.adaptableWidth=false;local quality=Camera.defaultResolution
  assert(game.display.resizeWindow(800,450));game.resize(love.graphics.getDimensions())
  local w,h=love.graphics.getDimensions();assert(w==800 and h==450)
  assert(game.width==1280 and game.height==720 and Camera.defaultResolution==quality)
  assert(not game.display.resizeWindow(0,480));assert(not game.display.resizeWindow(0/0,480))
  local dw,dh=love.window.getDesktopDimensions(game.display.getMonitor())
  assert(game.display.resizeWindow(dw*2,dh*2));w,h=love.graphics.getDimensions();assert(w==dw and h==dh)
 end)
 check('rendered pixels retain scene aspect and letterboxing across native window sizes',function()
  mode(640,480);Project.adaptableWidth=false
  local c=Camera(0,0,1280,720);c.bgColor={1,0,0,1};game.cameras.add(c);game.bound:add(game.cameras)
  local graphic=Graphic(540,310,200,100,{0,0,1,1})
  local originalCanvas=c.canvas
  for _,size in ipairs({{640,480},{960,540}}) do
   assert(love.window.updateMode(size[1],size[2]));game.resize(size[1],size[2])
   local target=love.graphics.newCanvas(size[1],size[2]);love.graphics.push('all');love.graphics.setCanvas(target)
   love.graphics.clear(0,0,0,1);c.__renderQueue[1]=graphic;game.draw();love.graphics.pop()
   local pixels=target:newImageData();local v=game.display.getViewport()
   local r,g,b=pixels:getPixel(math.floor(v.x+v.width/2),math.floor(v.y+v.height/2));assert(b>.99 and r<.01 and g<.01,'center graphic lost color')
   r,g,b=pixels:getPixel(math.floor(v.x+v.width*.1),math.floor(v.y+v.height*.1));assert(r>.99 and g<.01 and b<.01,'scene aspect/position changed')
   if v.y>=1 then r,g,b=pixels:getPixel(1,1);assert(r<.01 and g<.01 and b<.01,'letterbox was filled') end
   local x,y=game.display.gameToWindow(550,320);r,g,b=pixels:getPixel(math.floor(x),math.floor(y));assert(b>.99,'graphic bounds changed')
   assert(c.canvas==originalCanvas,'OS resize reallocated camera quality')
   pixels:release();target:release()
  end
  game.bound:remove(game.cameras,false);game.cameras.remove(c);graphic:destroy()
 end)
 check('fullscreen roundtrip restores window size without changing camera quality',function()
  mode(640,480);local quality=Camera.defaultResolution;local notifications=0
  love.fullscreen=function(f) notifications=notifications+1;assert(f==love.window.getFullscreen()) end
  assert(game.display.setFullscreen(true,'desktop'));assert(love.window.getFullscreen())
  local original=game.display.getMonitor()
  for i=1,#game.display.getMonitors() do
   local previous=game.display.getMonitor()
   local success,reason=game.display.selectMonitor(i)
   if success then assert(game.display.getMonitor()==i)
   else assert(type(reason)=='string' and game.display.getMonitor()==previous) end
   assert(love.window.getFullscreen(),'monitor switch lost fullscreen')
  end
  assert(game.display.selectMonitor(original))
  assert(game.display.setFullscreen(false));assert(not love.window.getFullscreen())
  local w,h=love.graphics.getDimensions();assert(w==640 and h==480,'fullscreen lost windowed size')
  assert(Camera.defaultResolution==quality and notifications==2)
 end)
 check('letterbox conversion agrees with actual mouse touch and virtual pad input',function()
  mode(640,480);Project.adaptableWidth=false;game.resize(640,480)
  local x,y=game.display.gameToWindow(640,360);near(x,320);near(y,240)
  local gx,gy=game.display.windowToGame(x,y);near(gx,640);near(gy,360)
  game.mouse.onMoved(x,y);near(game.mouse.x,gx);near(game.mouse.y,gy)
  game.touch.onPressed('display-touch',x,y,0,0,1)
  local found=false;for _,t in pairs(game.touch.touches) do if t.id=='display-touch' then near(t.x,gx);near(t.y,gy);found=true end end
  assert(found);game.touch.onReleased('display-touch',x,y,0,0,1)
  local px,py=VirtualPad.remap(x,y);near(px,gx);near(py,gy)
  local v=game.display.getViewport();near(v.scale,.5);near(v.x,0);near(v.y,60)
 end)
 check('mobile policy permits OS resize but rejects desktop fullscreen requests',function()
  mode(640,480);local original=love.system.getDevice;love.system.getDevice=function() return 'Mobile' end
  local ok,err=xpcall(function()
   local success,message=game.display.setFullscreen(true);assert(not success and type(message)=='string')
   assert(not game.display.selectMonitor(1));assert(not game.display.resizeWindow(800,600))
   assert(not love.window.getFullscreen());Project.adaptableWidth=false;game.resize(640,480)
   assert(game.width==1280 and game.height==720)
  end,debug.traceback)
  love.system.getDevice=original;assert(ok,err)
 end)
 print('DISPLAY PASSED: '..passed..' passed, '..failed..' failed');love.event.quit(failed==0 and 0 or 1)
end
function love.resize(w,h) game.resize(w,h) end
function love.update() end
function love.draw() end
function love.quit() end
function love.errorhandler(e) print('DISPLAY HARNESS ERROR: '..tostring(e)..'\n'..debug.traceback());return function() return 1 end end
