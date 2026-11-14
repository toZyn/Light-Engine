local B = {active=false,hooked=true}
local started,readyAt,frames,context,memory,lastMemory,lastFrame
local function clock() return love.timer.getTime() end
local function measure()
 memory.lua_peak_bytes=math.max(memory.lua_peak_bytes,collectgarbage('count')*1024)
 local stats=love.graphics.getStats()
 memory.texture_peak_bytes=math.max(memory.texture_peak_bytes,stats.texturememory or 0)
 if clock()-(lastMemory or -1)>0.25 then
  lastMemory=clock()
  local file=io.open('/proc/self/status','r')
  if file then
   local text=file:read('*a');file:close()
   local rss=tonumber(text:match('VmRSS:%s*(%d+)'))
   if rss then memory.process_rss_peak_bytes=math.max(memory.process_rss_peak_bytes or 0,rss*1024) end
  end
 end
end

function B.start(options)
 if B.active then return false end
 options=options or {}
 started,readyAt,frames,lastMemory,lastFrame=clock(),nil,{},nil,nil
 local renderer,version,vendor,device=love.graphics.getRendererInfo()
 local width,height=love.graphics.getDimensions()
 local prefs={}
 for k,v in pairs(ClientPrefs.data) do if type(v)~='table' then prefs[k]=v end end
 prefs.performanceCapture=nil
 context={run=options.run or 'manual',content=options.content or 'unverified',device=options.device or device,
  os=love.system.getOS(),renderer=renderer,driver=version,vendor=vendor,love=table.concat({love.getVersion()},'.'),
  width=width,height=height,logical_width=game.width,logical_height=game.height,
  engine=Project.version,prefs=prefs,song=options.song or (PlayState.SONG and PlayState.SONG.song),
  difficulty=options.difficulty or PlayState.songDifficulty,cache=options.cache or 'unspecified'}
 memory={lua_peak_bytes=0,texture_peak_bytes=0}
 B.active=true;measure()
 return true
end

function B.ready()
 if B.active and not readyAt then readyAt=clock();lastFrame=nil end
end

function B.update()
 if B.active then measure() end
end

function B.frame()
 if not B.active or not readyAt then return end
 local now=clock()
 if lastFrame then B.sample(now-lastFrame) end
 lastFrame=now
end

function B.sample(dt)
 if not B.active then return end
 measure()
 if readyAt and dt>0 then
  frames[#frames+1]=dt*1000
  if #frames>=120000 then B.finish() end
 end
end

function B.finish(writeFile)
 if not B.active then return nil end
 measure()
 local sorted,sum={},0
 for i,value in ipairs(frames) do sorted[i]=value;sum=sum+value end
 table.sort(sorted)
 local function percentile(p) return sorted[math.max(1,math.ceil(#sorted*p))] or 0 end
 local report={schema=1,context=context,loading_seconds=readyAt and readyAt-started or nil,
  completed=readyAt~=nil,capture_seconds=clock()-started,memory=memory,
  frames={count=#frames,mean_ms=#frames>0 and sum/#frames or 0,p50_ms=percentile(0.5),
   p95_ms=percentile(0.95),p99_ms=percentile(0.99),max_ms=sorted[#sorted] or 0,durations_ms=frames}}
 B.active=false
 if writeFile~=false then
  love.filesystem.createDirectory('benchmarks')
  local path='benchmarks/'..os.date('%Y%m%d-%H%M%S')..'-'..tostring(context.run):gsub('[^%w%-_]','_')..'.json'
  local ok,err=love.filesystem.write(path,JSON.encode(report,true))
  if ok then
   report.path=love.filesystem.getSaveDirectory()..'/'..path
   print('BENCHMARK '..report.path)
  else
   report.write_error=tostring(err)
   if Logger then Logger.log('warn','Benchmark export failed: '..tostring(err)) end
  end
 end
 B.last=report
 return report
end

return B
