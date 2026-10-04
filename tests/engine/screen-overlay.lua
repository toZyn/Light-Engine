-- A real native Script imports the separately installed addon; URLs are captured
-- here to verify wire bytes without opening an operating-system application.
io.stdout:setvbuf('no')
require 'loxel'
require 'funkin'
local function file(path,bytes) assert(love.filesystem.createDirectory(path:match('^(.*)/[^/]+$')));assert(love.filesystem.write(path,bytes)) end
local function contains(value,part)assert(tostring(value):find(part,1,true),tostring(value))end
local task
local function waitFor(check,seconds)
 local limit=love.timer.getTime()+(seconds or 5)
 while not check()do assert(love.timer.getTime()<limit,'desktop transport fixture timed out');coroutine.yield()end
end
function love.load()
 love.autoPause=false
 task=coroutine.create(function()
  local source=assert(love.filesystem.read('separate-addons/screen-overlay/modules/overlay.lua'),'missing separate PNG overlay module')
  Addons.root='screen-overlay-fixture';Addons.all={{path='screen-overlay',active=true}}
  file(Addons.root..'/screen-overlay/modules/overlay.lua',source)
  require('loxel.lib.gamestate').stack[1]=Group()
  local parent=Script('tests/engine/compat-fixture.lua',false,true,true)
  local module=parent.variables.requireAddon('screen-overlay','overlay')
  local data=love.image.newImageData(3,2);local encoded=data:encode('png');local png=encoded:getString();encoded:release();data:release()
  file(Addons.root..'/screen-overlay/images/picture.png',png)
  local modPixels=love.image.newImageData(4,2);local modFile=modPixels:encode('png');local modPNG=modFile:getString();modFile:release();modPixels:release()
  Mods.root='screen-mod-fixture';Mods.currentMod='consumer';file(Mods.root..'/consumer/images/picture.png',modPNG)
  file(Addons.root..'/screen-overlay/images/addon-only.png',png)
  local originalOS,originalURL=love.system.getOS,love.system.openURL
  love.system.getOS=function()return 'Android'end
  local urls={};local allowed=true
  love.system.openURL=function(uri)urls[#urls+1]=uri;return allowed end
  local listeners=#parent.closeCallback.listeners
  local api=module.new({label='Original PNG & consent'})
  local request=assert(api.showPng(png,{x=-20,y=30,width=300,height=200}))
  assert(request.status=='pending','URI launch claimed visible overlay')
  local uri=urls[#urls];contains(uri,'lightengine-overlay://show?');contains(uri,'x=-20');contains(uri,'label=Original%20PNG%20%26%20consent')
  local token=uri:match('token=([%x]+)');assert(#token==64)
  local wire=uri:match('image=([%w_-]+)');assert(wire and not wire:find('[=+/]'))
  wire=wire:gsub('-','+'):gsub('_','/');wire=wire..string.rep('=',(4-#wire%4)%4)
  assert(love.data.decode('string','base64',wire)==png,'Android protocol changed original PNG bytes')
  assert(api.showPng(png));local defaultURI=urls[#urls];contains(defaultURI,'x=0');contains(defaultURI,'y=0');contains(defaultURI,'width=3');contains(defaultURI,'height=2')
  assert(api.showPng(png,{width=9}));contains(urls[#urls],'width=9');contains(urls[#urls],'height=6')
  assert(api.showPng(png,{height=8}));contains(urls[#urls],'width=12');contains(urls[#urls],'height=8')
  local badLabel,labelError=module.new({label=string.rep('L',81)});assert(not badLabel);contains(labelError,'80')
  assert(api.showAddonImage('screen-overlay','images/picture.png'))
  assert(api.showModImage('images/picture.png'));local modWire=urls[#urls]:match('image=([%w_-]+)'):gsub('-','+'):gsub('_','/');modWire=modWire..string.rep('=',(4-#modWire%4)%4);assert(love.data.decode('string','base64',modWire)==modPNG,'mod image resolved another addon image')
  local absent,absentError=api.showModImage('images/addon-only.png');assert(not absent and absentError,'mod helper resolved addon-only resource')
  local none,error=api.showModImage('../escape.png');assert(not none);contains(error,'relative')
  local before=#urls;none,error=api.showPng(png..string.rep('x',256*1024));assert(not none and #urls==before);contains(error,'256')
  none,error=api.showPng('not a PNG');assert(not none);contains(error,'PNG')
  local function u32(n)return string.char(math.floor(n/16777216)%256,math.floor(n/65536)%256,math.floor(n/256)%256,n%256)end
  local giant=png:sub(1,16)..u32(4097)..u32(2)..png:sub(25)
  none,error=api.showPng(giant);assert(not none);contains(error,'4096')
  giant=png:sub(1,16)..u32(4001)..u32(4001)..png:sub(25)
  none,error=api.showPng(giant);assert(not none);contains(error,'16 million')
  none,error=api.showPng(png,{width=0});assert(not none);contains(error,'width')
  allowed=false;none,error=api.showPng(png);assert(not none);contains(error,'companion')
  allowed=true;assert(api.hide().status=='pending');contains(urls[#urls],'//hide?token='..token)
  assert(api.close());assert(#parent.closeCallback.listeners==listeners,'explicit close leaked addon callback')
  none,error=api.showPng(png);assert(not none);contains(error,'closed')
  for i=1,20 do local item=module.new();assert(item.close())end
  assert(#parent.closeCallback.listeners==listeners,'repeated close leaked addon callback')
  local second=module.new();assert(second.showPng(png));local secondToken=urls[#urls]:match('token=([%x]+)');assert(secondToken~=token,'session token reused')
  parent:close();contains(urls[#urls],'//hide?token='..secondToken)
  love.system.getOS,love.system.openURL=originalOS,originalURL
  local desktopParent=Script('tests/engine/compat-fixture.lua',false,true,true)
  local desktopModule=desktopParent.variables.requireAddon('screen-overlay','overlay')
  local serverCode=[[-- real loopback HTTP peer
local socket=require 'socket'
local log=love.thread.getChannel('screen_overlay_wire')
local server=assert(socket.bind('127.0.0.1',51874));server:settimeout(.05);log:push({ready=true})
local pendingSent=false;local pairedTokens={}
local stop=love.thread.getChannel('screen_overlay_server_stop')
while not stop:peek()do
 local client=server:accept()
 if client then
  client:settimeout(3)
  local line=client:receive('*l');local headers={}
  while true do local header=client:receive('*l');if not header or header==''then break end;local key,value=header:match('^([^:]+):%s*(.*)$');if key then headers[key:lower()]=value end end
  local bytes=tonumber(headers['content-length'])or 0;local body=bytes>0 and assert(client:receive(bytes))or ''
  log:push({line=line,headers=headers,body=body})
  if line:find('width=444',1,true)then socket.sleep(.15)end
  local response='{"accepted":true,"displayed":false}';local status='202 Accepted'
  if line:find('POST /connect',1,true)then pairedTokens[body:match('"token":"([%x]+)"')]=true;response='{"granted":true,"pending":false}';status='200 OK'
  elseif not pairedTokens[(headers.authorization or ''):match('Bearer ([%x]+)')]then response='{"error":"unsolicited","pending":false}';status='403 Forbidden'end
  if line:find('width=777',1,true) and not pendingSent then pendingSent=true;response='{"error":"Pair consent pending","pending":true}';status='403 Forbidden' end
  if line:find('width=666',1,true)then response='{"error":"denied","pending":false}';status='403 Forbidden' end
  if line:find('width=888',1,true)then
   client:send('HTTP/1.1 '..status..'\r\n')
   for i=1,6 do client:send('X-Slow: '..i..'\r\n');socket.sleep(.65)end
   client:send('Content-Length: '..#response..'\r\nConnection: close\r\n\r\n'..response)
  else client:send('HTTP/1.1 '..status..'\r\nContent-Length: '..#response..'\r\nConnection: close\r\n\r\n'..response)end
  client:close()
 end
end
server:close()
]]
  local wire=love.thread.getChannel('screen_overlay_wire');wire:clear()
  local stop=love.thread.getChannel('screen_overlay_server_stop');stop:clear()
  local server=love.thread.newThread(serverCode);server:start()
  waitFor(function()return wire:peek()or server:getError()end);assert(not server:getError(),server:getError());assert(wire:pop().ready)
  local captured={};local desktopURLs={}
  love.system.openURL=function(uri)desktopURLs[#desktopURLs+1]=uri;return true end
  local function drain()while wire:peek()do captured[#captured+1]=wire:pop()end end
  local desktop=desktopModule.new({label='Desktop original PNG'})
  local timers=#Timer.globalManager.instances
  local oversized,tooLarge=desktop.showPng(png..string.rep('x',8*1024*1024));assert(not oversized);contains(tooLarge,'8 MiB');assert(#desktopURLs==0)
  local latest=assert(desktop.showPng(png,{width=300}));desktop.showPng(png,{width=222});latest=assert(desktop.showPng(png,{width=333}))
  assert(latest.status=='pending');contains(desktopURLs[1],'//connect?token=')
  waitFor(function()drain();return desktop.getStatus().status=='accepted'or desktop.getStatus().status=='failed'end)
  assert(desktop.getStatus().status=='accepted',desktop.getStatus().message)
  assert(desktop.getStatus().requestId==latest.requestId,'obsolete response changed latest status')
  assert(#captured>=1)
  for _,record in ipairs(captured)do if record.line:find('/image',1,true)then assert(record.body==png,'desktop HTTP changed original PNG bytes');contains(record.headers.authorization,'Bearer ');assert(not record.line:find('width=222',1,true),'middle pending image was not replaced')end end
  assert(captured[#captured].line:find('width=333',1,true),'latest image did not reach companion')
  assert(desktop.showPng(png,{width=444}))
  waitFor(function()drain();return captured[#captured].line:find('width=444',1,true)end)
  assert(desktop.close());assert(#Timer.globalManager.instances<=timers+1,'closed desktop session retained polling timer')
  waitFor(function()drain();return captured[#captured].line:find('DELETE /connect',1,true)end)
  assert(desktop.getStatus().status=='closed','late worker response updated a closed API')
  local consent=desktopModule.new();assert(consent.showPng(png,{width=777}))
  waitFor(function()drain();return consent.getStatus().status=='accepted'end)
  local pendingCount=0;for _,record in ipairs(captured)do if record.line:find('width=777',1,true)then pendingCount=pendingCount+1 end end
  assert(pendingCount==2,'pending consent was not retried exactly once before acceptance')
  assert(consent.showPng(png,{width=666}))
  waitFor(function()drain();return consent.getStatus().status=='failed'end);contains(consent.getStatus().message,'403')
  assert(consent.close())
  local capA,capB,capC=desktopModule.new(),desktopModule.new(),desktopModule.new()
  waitFor(function()return not game.__screenOverlayTransport.sessions[1]or not game.__screenOverlayTransport.sessions[1].worker:isRunning()end)
  assert(capA.showPng(png));assert(capB.showPng(png))
  local busy,busyMessage=capC.showPng(png);assert(not busy);contains(busyMessage,'two live sessions')
  assert(capA.close());assert(capB.close());assert(capC.close())
  waitFor(function()
   for _,session in ipairs(game.__screenOverlayTransport.sessions)do if session.worker:isRunning()then return false end end
   return true
  end)
  assert(#game.__screenOverlayTransport.sessions==0,'completed closed workers retained by shared registry without future requests')
  local slow=desktopModule.new();local slowStart=love.timer.getTime();assert(slow.showPng(png,{width=888}))
  waitFor(function()return slow.getStatus().status=='failed'or slow.getStatus().status=='accepted'end)
  assert(slow.getStatus().status=='failed','slow headers bypassed absolute HTTP deadline')
  assert(love.timer.getTime()-slowStart<3.6,'absolute HTTP deadline exceeded 3 seconds plus scheduling')
  assert(slow.close());waitFor(function()return #game.__screenOverlayTransport.sessions==0 end)
  local failureSource=source:gsub('http.TIMEOUT=3',"error('expected desktop worker startup failure');http.TIMEOUT=3",1)
  file(Addons.root..'/screen-overlay-failure/modules/overlay.lua',failureSource)
  Addons.all[#Addons.all+1]={path='screen-overlay-failure',active=true}
  local failureModule=desktopParent.variables.requireAddon('screen-overlay-failure','overlay')
  local faults=0;local previousThreadError=love.threaderror
  love.threaderror=function()faults=faults+1 end
  local failed=failureModule.new();local timerCount=#Timer.globalManager.instances;assert(failed.showPng(png))
  waitFor(function()return faults>0 or failed.getStatus().status=='failed'end)
  assert(faults==0,'isolated companion worker startup error reached engine threaderror')
  assert(#Timer.globalManager.instances==timerCount,'failed transport kept polling/reporting forever')
  assert(failed.close());love.threaderror=previousThreadError
  desktopParent:close();love.system.openURL=originalURL;stop:push(true)
  waitFor(function()return not server:isRunning()end);assert(not server:getError(),server:getError())
  paths.async.stop()
  print('SCREEN OVERLAY PASSED: original Android URI and desktop HTTP bytes; latest queue; pending delivery; bounds; missing companion; scoped cleanup')
  love.event.quit(0)
 end)
end
function love.update(dt)
 Timer.globalManager:update(dt)
 if task and coroutine.status(task)~='dead'then
  local ok,err=coroutine.resume(task);if not ok then love.thread.getChannel('screen_overlay_server_stop'):push(true);print('SCREEN OVERLAY FAIL '..tostring(err)..'\n'..debug.traceback(task));love.event.quit(1)end
 end
end
function love.quit()end
function love.errorhandler(err)print(err);return function()return 1 end end

function love.draw()end
