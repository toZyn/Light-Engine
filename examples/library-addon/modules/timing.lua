local Timing = {}
local function positive(value,name)
 if type(value)~='number' or value~=value or value<=0 or value==math.huge then error(name..' must be a finite positive number',2) end
 return value
end
function Timing.beatMillis(bpm) return 60000/positive(bpm,'BPM') end
function Timing.barMillis(bpm,beatsPerBar) return Timing.beatMillis(bpm)*positive(beatsPerBar or 4,'beats per bar') end
function Timing.seconds(milliseconds) return milliseconds/1000 end
return Timing
