local Information = {}
Information.__index = Information

local function timeline(notes)
 local intervals = {}
 for _, note in ipairs(notes or {}) do
  local start = (tonumber(note.t) or 0) / 1000
  intervals[#intervals + 1] = {start, start + math.max((tonumber(note.l) or 0) / 1000, 0.2)}
 end
 table.sort(intervals, function(a,b) return a[1] < b[1] end)
 local merged = {}
 for _, interval in ipairs(intervals) do
  local last = merged[#merged]
  if last and interval[1] <= last[2] + 0.35 then
   last[2] = math.max(last[2], interval[2])
  else
   merged[#merged + 1] = interval
  end
 end
 return merged
end

local function activity(intervals, time)
 local lo, hi = 1, #intervals
 while lo <= hi do
  local mid = math.floor((lo + hi) / 2)
  if intervals[mid][2] <= time then lo = mid + 1 else hi = mid - 1 end
 end
 local interval = intervals[lo]
 if interval then
  if interval[1] <= time then return true, interval[2] end
  return false, interval[1]
 end
 return false
end

function Information.new(player, opponent)
 return setmetatable({player=timeline(player),opponent=timeline(opponent),clock=0,
  taps={},hits={},ips=0,nps=0,peakIps=0,peakNps=0,totalHits=0,weight=0,
  meanOffset=0,meanAbsolute=0,lastOffset=0,peakCombo=0,timingSamples=0},Information)
end

function Information:tap()
 self.taps[#self.taps+1] = self.clock
 self.ips = #self.taps
 self.peakIps = math.max(self.peakIps,self.ips)
end

function Information:hit(weight, offset, bot)
 self.totalHits = self.totalHits + 1
 self.weight = self.weight + (weight or 0)
 if not bot then
  self.lastOffset = offset * 1000
  self.timingSamples = self.timingSamples + 1
  local n = self.timingSamples
  self.meanOffset = self.meanOffset + (self.lastOffset-self.meanOffset)/n
  self.meanAbsolute = self.meanAbsolute + (math.abs(self.lastOffset)-self.meanAbsolute)/n
 end
 self.hits[#self.hits+1] = self.clock
 self.nps = #self.hits
 self.peakNps = math.max(self.peakNps,self.nps)
end

function Information:update(dt)
 self.clock = self.clock + math.max(dt,0)
 for _, queue in ipairs({self.taps,self.hits}) do
  local expired = 0
  while queue[expired+1] and queue[expired+1] <= self.clock-1 do expired=expired+1 end
  if expired>0 then
   for i=expired+1,#queue do queue[i-expired]=queue[i] end
   for i=#queue,#queue-expired+1,-1 do queue[i]=nil end
  end
 end
 self.ips,self.nps = #self.taps,#self.hits
end

function Information:accuracy(misses)
 local count = self.totalHits + (misses or 0)
 return count>0 and math.max(0,math.min(100,self.weight/count*100)) or 100
end

function Information:turnText(time, speed)
 speed = math.max(tonumber(speed) or 1,0.1)
 local player, pNext = activity(self.player,time)
 local opponent, oNext = activity(self.opponent,time)
 local function countdown(label,nextTime)
  return nextTime and string.format('%s in %.1fs',label,math.max(0,nextTime-time)/speed) or (label..': finished')
 end
 if player and opponent then return 'Both playing' end
 if player then return 'Player turn | '..countdown('Opponent',oNext) end
 if opponent then return 'Opponent turn | '..countdown('Player',pNext) end
 if not pNext and not oNext then return 'No notes remaining' end
 return 'Break | '..countdown('Player',pNext)..' | '..countdown('Opponent',oNext)
end

function Information:format(state, mode, time)
 local score = 'Score: '..tostring(math.floor(state.score or 0))
 if mode=='Simple' then return score end
 local summary = string.format('%s | Misses: %d | Accuracy: %.2f%%',score,state.misses or 0,self:accuracy(state.misses))
 if mode~='Full' then return summary end
 self.peakCombo=math.max(self.peakCombo,math.max(state.combo or 0,0))
 return table.concat({summary,
  string.format('Hits: %d | Combo: %d | Max combo: %d',self.totalHits,math.max(state.combo or 0,0),self.peakCombo),
  string.format('Sick: %d | Good: %d | Bad: %d | Shit: %d',state.sicks or 0,state.goods or 0,state.bads or 0,state.shits or 0),
  string.format('IPS: %d (Peak: %d) | NPS: %d (Peak: %d)',self.ips,self.peakIps,self.nps,self.peakNps),
  string.format('Health: %.1f%% | Speed: %.2fx%s',(state.health or 0)*50,state.playback or 1,state.usedBotPlay and ' | Botplay used' or ''),
  string.format('Offset: %+.1f ms | Mean offset: %+.1f ms | Mean error: %.1f ms',self.lastOffset,self.meanOffset,self.meanAbsolute),
  self:turnText(time,state.playback)},'\n')
end

return Information
