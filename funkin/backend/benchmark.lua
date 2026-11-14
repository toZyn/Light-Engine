local Benchmark={}
local active
local function memory()
 local stats=love.graphics.getStats()
 local rss
 local file=io.open("/proc/self/status","r")
 if file then local text=file:read("*a");file:close();rss=tonumber(text:match("VmRSS:%s*(%d+)"));if rss then rss=rss*1024 end end
 return collectgarbage("count")*1024,stats.texturememory or 0,rss
end
function Benchmark.start(metadata)
 active={schema=1,metadata=metadata or {},frames=0,histogram={},totalMs=0,maxMs=0,peakLuaBytes=0,peakTextureBytes=0,sampledPeakRssBytes=nil,started=love.timer.getTime(),lastSample=0}
 local renderer,version,vendor,device=love.graphics.getRendererInfo()
 active.metadata.device=active.metadata.device or {os=love.system.getOS(),renderer=renderer,version=version,vendor=vendor,gpu=device}
 active.metadata.width,active.metadata.height=love.graphics.getDimensions()
 active.metadata.engine=Project and Project.version or "unknown"
 return active
end
function Benchmark.content(id)
 if active and type(id)=="string" and id~="" then active.metadata.contentId=id end
end
function Benchmark.loaded()
 if active then active.loadMs=(love.timer.getTime()-active.started)*1000 end
end
function Benchmark.frame(dt)
 if not active or type(dt)~="number" or dt<=0 or dt~=dt or dt==math.huge then return end
 local ms=dt*1000
 active.frames=active.frames+1;active.totalMs=active.totalMs+ms;active.maxMs=math.max(active.maxMs,ms)
 local bucket=math.min(10000,math.ceil(ms*10))
 active.histogram[bucket]=(active.histogram[bucket] or 0)+1
 if active.lastSample==0 or love.timer.getTime()-active.lastSample>=.25 then
  active.lastSample=love.timer.getTime()
  local lua,texture,rss=memory()
  active.peakLuaBytes=math.max(active.peakLuaBytes,lua)
  active.peakTextureBytes=math.max(active.peakTextureBytes,texture)
  if rss then active.sampledPeakRssBytes=math.max(active.sampledPeakRssBytes or 0,rss) end
 end
end
function Benchmark.finish()
 if not active then return end
 local result=active;active=nil
 result.meanFrameMs=result.frames>0 and result.totalMs/result.frames or 0
 local function percentile(p)
  local target=math.ceil(result.frames*p);local count=0
  for i=0,10000 do count=count+(result.histogram[i] or 0);if count>=target then return i/10 end end
  return 0
 end
 result.p50Ms,result.p95Ms,result.p99Ms=percentile(.5),percentile(.95),percentile(.99)
 result.histogram=nil;result.started=nil;result.lastSample=nil
 love.filesystem.createDirectory("benchmarks")
 local path="benchmarks/"..os.date("%Y%m%d-%H%M%S").."-"..love.timer.getTime()..".json"
 local ok,err=love.filesystem.write(path,(loxreq "lib.json").encode(result))
 if not ok then require("funkin.backend.recoverable-errors").report("Benchmark export failed: "..tostring(err),nil,{source="benchmark"}) end
 return result,path
end
function Benchmark.running()return active~=nil end
return Benchmark
