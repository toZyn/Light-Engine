local Job = {}
Job.__index = Job
local current

function Job.new(work)
 return setmetatable({thread=coroutine.create(work),phase='Preparing',progress=0,done=false},Job)
end

function Job.checkpoint(phase, progress)
 if not current or coroutine.running() ~= current.thread then return end
 current.phase = phase or current.phase
 current.progress = math.max(current.progress, math.min(0.999, progress or current.progress))
 coroutine.yield()
end

function Job:step()
 if self.done or self.cancelled then return end
 local previous=current
 current=self
 local ok,err=coroutine.resume(self.thread)
 current=previous
 if not ok then
  self.error='Scene preparation failed ['..self.phase..']: '..tostring(err)..'\n'..debug.traceback(self.thread)
  error(self.error,0)
 end
 if coroutine.status(self.thread)=='dead' then
  self.done,self.progress,self.phase=true,1,'Ready'
  self.thread=nil
 end
end

function Job:cancel()
 self.cancelled=true
 self.thread=nil
end

return Job
