-- Explicit PNG delivery to a separately installed companion. This module never
-- captures the game/window/wallpaper and never starts work merely on import.
local type,tostring,pcall,pairs,ipairs = type,tostring,pcall,pairs,ipairs
local system,data,thread,timer = love.system,love.data,love.thread,love.timer
local math,string,table = math,string,table
local NativeTimer,filesystem,resourcePaths,readAddon=Timer,love.filesystem,paths,readAddonText
local random=love.math.random
local shared=game.__screenOverlayTransport
if not shared then shared={sessions={}};game.__screenOverlayTransport=shared end
local Toolkit = {}
local sequence = 0
local function percent(text) return (text:gsub('[^%w%-._~]',function(c)return string.format('%%%02X',c:byte())end)) end
local function relative(path)
 if type(path)~='string' or path=='' or path:find('^/') or path:find('[\\:%c]') then return nil,'image requires a relative path without traversal' end
 local parts={}
 for part in path:gmatch('[^/]+')do
  if part=='..' then return nil,'image requires a relative path without traversal' end
  if part~='.' then parts[#parts+1]=part end
 end
 if #parts==0 then return nil,'image requires a relative path' end
 return table.concat(parts,'/')
end
local function bigEndian(bytes,offset)
 local a,b,c,d=bytes:byte(offset,offset+3);return ((a*256+b)*256+c)*256+d
end
local function validate(bytes,limit)
 if type(bytes)~='string' then return nil,'PNG input must be original file bytes' end
 if #bytes>limit then return nil,'original PNG exceeds '..(limit==262144 and '256 KiB Android' or '8 MiB desktop')..' limit; choose a smaller source PNG (no compression is performed)' end
 if #bytes<33 or bytes:sub(1,8)~='\137PNG\r\n\26\n' or bytes:sub(13,16)~='IHDR' or bigEndian(bytes,9)~=13 then return nil,'input must have a valid PNG signature and IHDR header' end
 local width,height=bigEndian(bytes,17),bigEndian(bytes,21)
 if width<1 or height<1 or width>4096 or height>4096 or width*height>16000000 then return nil,'PNG dimensions must be at most 4096 each and 16 million pixels' end
 return true,width,height
end
local function geometry(options,sourceWidth,sourceHeight)
 options=options or {}
 if type(options)~='table' then return nil,'image geometry must be a table' end
 local result={}
 for _,key in ipairs({'x','y','width','height'})do
  local value=options[key]
  if value~=nil then
   if type(value)~='number' or value~=value or value%1~=0 or ((key=='x' or key=='y') and math.abs(value)>100000) or ((key=='width' or key=='height') and (value<1 or value>4096))then return nil,key..((key=='width' or key=='height') and ' must be an integer between 1 and 4096' or ' must be an integer between -100000 and 100000') end
  end
 end
 local width,height=options.width or sourceWidth,options.height or sourceHeight
 if options.width and not options.height then height=math.max(1,math.floor(sourceHeight*width/sourceWidth+.5))end
 if options.height and not options.width then width=math.max(1,math.floor(sourceWidth*height/sourceHeight+.5))end
 if width>4096 or height>4096 then return nil,'aspect-preserving overlay size exceeds 4096' end
 for _,key in ipairs({'x','y','width','height'})do
  local value=key=='width' and width or key=='height' and height or options[key] or 0
  result[#result+1]=key..'='..string.format('%.0f',value)
 end
 return table.concat(result,'&')
end
local workerCode=[[-- One sequential worker per live session; no Script objects cross threads.
require 'love.timer'
local taskName,resultName,cancelName,token,pairBody=...
local tasks,results,cancel=love.thread.getChannel(taskName),love.thread.getChannel(resultName),love.thread.getChannel(cancelName)
local completed,failure=xpcall(function()
local ok,http=pcall(require,'socket.http')
local loaded,socket=pcall(require,'socket')
local got,ltn12=pcall(require,'ltn12')
if not ok or not loaded or not got then
 results:push({fatal=true,error='Desktop HTTP transport is unavailable in this LÖVE runtime'});tasks:clear();return
end
http.TIMEOUT=3
local function connection()
 local client=assert(socket.tcp())
 local deadline=love.timer.getTime()+3
 local blockTimeout=3
 local proxy={}
 local function prepare()
  local remaining=deadline-love.timer.getTime()
  if remaining<=0 then return nil,'timeout'end
  client:settimeout(math.min(blockTimeout,remaining),'b')
  client:settimeout(remaining,'t')
  return 1
 end
 function proxy:settimeout(value)
  blockTimeout=value and value>=0 and value or 3
  return prepare()
 end
 function proxy:connect(...)
  local ok,message=prepare();if not ok then return nil,message end
  return client:connect(...)
 end
 function proxy:send(...)
  local ok,message=prepare();if not ok then return nil,message end
  return client:send(...)
 end
 function proxy:receive(...)
  local ok,message=prepare();if not ok then return nil,message end
  return client:receive(...)
 end
 function proxy:getfd()return client:getfd()end
 function proxy:dirty()return client:dirty()end
 function proxy:close()return client:close()end
 return proxy
end
local function request(task)
 local output,size={},0
 local _,code,_,reason=http.request{
  url='http://127.0.0.1:51874'..(task.route or '/image')..(task.query~='' and '?'..task.query or ''),method=task.method,
  headers={Authorization='Bearer '..token,['Content-Type']=task.route=='/connect' and 'application/json' or 'image/png',['Content-Length']=tostring(#(task.bytes or '')),Connection='close'},
  source=ltn12.source.string(task.bytes or ''),redirect=false,
  sink=function(chunk,err)
   if chunk then size=size+#chunk;if size>65536 then return nil,'Companion response exceeded 64 KiB'end;output[#output+1]=chunk end
   return 1
  end,
  create=connection
 }
 return tonumber(code),table.concat(output),reason or code
end
local paired=false
while true do
 local task=tasks:demand()
 if task.method~='POST' or not cancel:peek()then
  local started=love.timer.getTime()
  local code,body,reason
  repeat
   local connecting=task.method=='POST' and not paired
   local wireTask=connecting and {route='/connect',method='POST',bytes=pairBody,query=''}or task
   local success,a,b,c=pcall(request,wireTask)
   if success then code,body,reason=a,b,c else code,body,reason=nil,'',a end
   if connecting and code and code>=200 and code<300 and body:find('"granted"%s*:%s*true')then
    paired=true;connecting=false
    if cancel:peek()or tasks:peek()then break end
    success,a,b,c=pcall(request,task)
    if success then code,body,reason=a,b,c else code,body,reason=nil,'',a end
   end
   local pending=((connecting and code and code>=200 and code<300)or code==403)and body:find('"pending"%s*:%s*true')
   local startup=code==nil and love.timer.getTime()-started<3
   if not pending and not startup then break end
   if task.close or cancel:peek() or tasks:peek() or love.timer.getTime()-started>=30 then break end
   local untilTime=love.timer.getTime()+.5
   repeat love.timer.sleep(.025)until love.timer.getTime()>=untilTime or cancel:peek() or tasks:peek()
  until cancel:peek() or tasks:peek()
  if not cancel:peek()then
   local accepted=code and code>=200 and code<300 and (task.method=='DELETE' or (paired and body:find('"accepted"%s*:%s*true')))
   local response={requestId=task.id,status=accepted and 'accepted' or 'failed',httpStatus=code}
   if not accepted then response.error='Companion delivery failed: '..tostring(code or reason or 'unreachable')..' '..body end
   results:clear();results:push(response)
  end
 end
 if task.close then break end
end
end,debug.traceback)
if not completed and not cancel:peek()then
 results:clear();results:push({fatal=true,error='Companion worker failed: '..tostring(failure)})
end
if cancel:peek()then results:clear()end
tasks:clear();cancel:clear()
]]
local function reap()
 for i=#shared.sessions,1,-1 do
  local session=shared.sessions[i]
  if not session.worker:isRunning()then
   session.tasks:clear();session.results:clear();session.cancel:clear();table.remove(shared.sessions,i)
  end
 end
end
local function retire(session)
 session.closing=true
 if shared.retireTimer then return end
 local cleanup=NativeTimer()
 shared.retireTimer=cleanup
 cleanup:start(.05,function()
  reap()
  for _,entry in ipairs(shared.sessions)do if entry.closing then return end end
  cleanup.onComplete=nil;cleanup:cancel();shared.retireTimer=nil
 end,0)
end

function Toolkit.new(options)
 options=options or {}
 local report=reportRecoverableError
 local function fail(message)
  message='[Screen Overlay] '..tostring(message)
  if type(report)=='function' then pcall(report,message) end
  return nil,message
 end
 if type(options)~='table' or (options.label~=nil and type(options.label)~='string') then return fail('label options must contain a string') end
 local label=options.label or 'Light Engine PNG overlay'
 if #label>80 or label:find('%c')then return fail('label must have at most 80 bytes and no control bytes') end
 sequence=sequence+1
 local entropy={tostring(timer.getTime()),tostring({}),tostring(sequence)}
 for i=1,32 do entropy[#entropy+1]=string.char(random(0,255))end
 local token=data.encode('string','hex',data.hash('sha256',table.concat(entropy)))
 local pairBody='{"token":"'..token..'","label":"'..label:gsub('[\\"]',function(c)return '\\'..c end)..'"}'

 local android=system.getOS()=='Android'
 local closed,issued,requestId=false,false,0
 local api={}
 local status={status='idle',transport=android and 'android' or 'desktop'}
 local closeListener,pollTimer,session
 local owner=script
 local function request(action)
  requestId=requestId+1
  status={requestId=requestId,status='pending',transport=android and 'android' or 'desktop',action=action}
  return {requestId=requestId,status='pending',transport=status.transport,action=action}
 end
 local function launch(uri)
  local ok,result=pcall(system.openURL,uri)
  if not ok or result~=true then return fail('companion is not installed or its URL handler could not open') end
  return true
 end
 local function poll()
  if closed or not session then return end
  local result=session.results:pop()
  local workerError=session.worker:getError()
  if workerError then result={fatal=true,error=workerError}end
  if result and (result.fatal or result.requestId==requestId)then
   status={requestId=requestId,status=result.status or 'failed',transport='desktop',httpStatus=result.httpStatus,message=result.error}
   if result.error then fail(result.error)end
   if result.fatal and pollTimer then pollTimer.onComplete=nil;pollTimer:cancel();pollTimer=nil end
  end
  reap()
 end
 local function ensureWorker()
  if session then
   if not session.worker:isRunning()then return fail('desktop transport worker stopped; close this session and create another')end
   return true
  end
  reap()
  if #shared.sessions>=2 then return fail('desktop transport is busy (two live sessions); close another session and retry')end
  local prefix='screen_overlay_'..token..'_'
  session={tasks=thread.getChannel(prefix..'tasks'),results=thread.getChannel(prefix..'results'),cancel=thread.getChannel(prefix..'cancel')}
  session.tasks:clear();session.results:clear();session.cancel:clear()
  session.worker=thread.newThread(workerCode)
  local ok,message=pcall(session.worker.start,session.worker,prefix..'tasks',prefix..'results',prefix..'cancel',token,pairBody)
  if not ok then session=nil;return fail(message)end
  shared.sessions[#shared.sessions+1]=session
  pollTimer=NativeTimer();pollTimer:start(.05,poll,0)
  return true
 end
 local function queue(method,bytes,query,closing,route)
  local result=request(method=='POST' and 'show' or 'hide')
  session.tasks:clear()
  session.tasks:push({method=method,bytes=bytes,query=query or '',id=requestId,close=closing or false,route=route})
  return result
 end
 function api.showPng(bytes,position)
  if closed then return fail('closed') end
  local valid,width,height=validate(bytes,android and 262144 or 8388608);if not valid then return fail(width)end
  local query,message=geometry(position,width,height);if not query then return fail(message)end
  if not android then
   local ok,error=ensureWorker();if not ok then return nil,error end
   if not issued then
    ok,error=launch('lightengine-overlay://connect?token='..token..'&label='..percent(label))
    if not ok then api.close();return nil,error end
    issued=true
   end
   return queue('POST',bytes,query)
  end
  local encoded=data.encode('string','base64',bytes):gsub('+','-'):gsub('/','_'):gsub('=',''):gsub('%s','')
  local uri='lightengine-overlay://show?token='..token..'&image='..encoded..'&label='..percent(label)
  if query~='' then uri=uri..'&'..query end
  local ok,error=launch(uri);if not ok then return nil,error end
  issued=true
  return request('show')
 end
 function api.showAddonImage(id,path,position)
  if closed then return fail('closed') end
  local normalized,message=relative(path);if not normalized then return fail(message)end
  local ok,bytes=pcall(readAddon,id,normalized);if not ok then return fail(bytes)end
  return api.showPng(bytes,position)
 end
 function api.showModImage(path,position)
  if closed then return fail('closed') end
  local normalized,message=relative(path);if not normalized then return fail(message)end
  local resolved=resourcePaths.getPath(normalized,true,false)
  local bytes,error=filesystem.read(resolved);if not bytes then return fail(error or 'mod image is missing')end
  return api.showPng(bytes,position)
 end
 function api.hide()
  if closed then return fail('closed')end
  if not issued then return request('hide')end
  if not android then return queue('DELETE',nil,'')end
  local ok,error=launch('lightengine-overlay://hide?token='..token);if not ok then return nil,error end
  return request('hide')
 end
 function api.getStatus()
  local result={};for key,value in pairs(status)do result[key]=value end;return result
 end
 function api.close()
  if closed then return true end
  local result,message
  if not android and session then
   session.cancel:push(true);session.results:clear()
   if session.worker:isRunning()then result=queue('DELETE',nil,'',true,'/connect')else result=true;session.tasks:clear()end
   retire(session)
  else result,message=api.hide()end
  if pollTimer then pollTimer.onComplete=nil;pollTimer:cancel();pollTimer=nil end
  session=nil
  closed=true;status={status='closed',transport=status.transport}
  if owner and not owner.closed and closeListener then owner.closeCallback:remove(closeListener)end
  owner,closeListener,report=nil,nil,nil
  return result~=nil,message
 end
 if owner and owner.closeCallback then closeListener=function()api.close()end;owner.closeCallback:add(closeListener)end
 return api
end
return Toolkit
