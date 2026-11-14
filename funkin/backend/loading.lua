local Loading={}
Loading.__index=Loading
local current
function Loading.new(callback)
 return setmetatable({thread=coroutine.create(callback),label="Preparing",done=false},Loading)
end
function Loading.checkpoint(label,completed,total)
 if current and coroutine.running()==current.thread then
  current.label,current.completed,current.total=label,completed,total
  coroutine.yield()
 end
end
function Loading:step(budget)
 if self.done then return true end
 local deadline=love.timer.getTime()+(budget or .004)
 repeat
  current=self
  local ok,err=coroutine.resume(self.thread)
  current=nil
  if not ok then error(debug.traceback(self.thread,tostring(err)),0) end
  if coroutine.status(self.thread)=="dead" then self.done=true;return true end
 until love.timer.getTime()>=deadline
 return false
end
return Loading
