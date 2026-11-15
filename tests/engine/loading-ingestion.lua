local Decoder = require "loxel.lib.json"
local Screen = require "funkin.ui.loadscreen"
local Job = require "funkin.backend.scenejob"

check("deferred song selection presents loading before chart ingestion",function()
 local original=PlayState.loadSong
 local calls=0
 PlayState.loadSong=function() calls=calls+1;return false,"missing fixture" end
 local ok,err=pcall(function()
  local target=PlayState.deferred(false,"missing-fixture","normal")
  assert(calls==0)
  local view=Screen(target)
  view:update(0.016);assert(calls==0)
  view:draw();view:update(0.016);assert(calls==0)
  view:draw();view:update(0.016)
  assert(calls==1 and target._loadFailed)
  view:destroy()
 end)
 PlayState.loadSong=original
 assert(ok,err)
end)

check("JSON decoding can yield and interleave another document without corrupting state",function()
 local source='{"notes":['..string.rep('[1,2,3,"x"],',5000)..'[4,5,6,"y"]],"bpm":120}'
 local pauses=0
 local thread=coroutine.create(function()
  local data=Decoder.decode(source,function()
   pauses=pauses+1
   coroutine.yield()
  end)
  assert(#data.notes==5001 and data.notes[5001][4]=="y" and data.bpm==120)
 end)
 while coroutine.status(thread)~="dead" do
  local ok,err=coroutine.resume(thread);assert(ok,err)
  local nested=Decoder.decode('{"other":[5,6]}')
  assert(nested.other[2]==6)
 end
 assert(pauses>0)
 assert(not pcall(Decoder.decode,'{"bad":'))
 assert(Decoder.decode('{"ok":true}').ok)
end)

check("difficulty projection skips note arrays and preserves declared and bundled names",function()
 local source='{"difficulties":["normal","expert"],"notes":{"normal":[[1,2,"escaped \\\" ] [",0]],"expert":[[2,3,0]]}}'
 local summary=Decoder.decode(source,nil,{skipArrays=true})
 assert(summary.difficulties[2]=="expert")
 assert(#summary.notes.normal==1 and summary.notes.normal[1]==true)
 assert(summary.notes.expert[1]==true)
 assert(#Decoder.decode('{"notes":[]}',nil,{skipArrays=true}).notes==0)
end)

check("chart normalization consumes owned raw records without cloning a second chart",function()
 local parser=require "funkin.backend.parser.chart.vanilla"
 local raw={song={song="Synthetic Dense",bpm=120,player1="bf",player2="dad",gfVersion="gf",stage="stage",notes={{mustHitSection=true,sectionNotes={}}}}}
 for i=1,20000 do raw.song.notes[1].sectionNotes[i]={i, i%8, 0} end
 local parsed=parser.parse(raw,nil,nil,"normal",{consume=true})
 assert(#parsed.notes.player+#parsed.notes.enemy==20000)
 assert(next(raw.song.notes[1].sectionNotes)==nil)
 local input={song={song="Small",bpm=100,notes={{mustHitSection=true,sectionNotes={{0,0,0}}}}}}
 parser.parse(input,nil,nil,"normal")
 assert(input.song.notes[1].sectionNotes[1][1]==0)
end)

check("large unordered charts sort cooperatively without losing equal-time records",function()
 local index=require "funkin.backend.timeindex"
 local notes={}
 for i=1,30000 do notes[i]={t=30001-i,id=i} end
 local job=Job.new(function() index.sort(notes) end)
 while not job.done do job:step() end
 for i,note in ipairs(notes) do assert(note.t==i and note.id==30001-i) end
end)

check("JSON decoder releases completed document ownership",function()
 local weak=setmetatable({},{__mode="v"})
 local function decode() weak[1]=Decoder.decode('{"notes":[[1,2,3],[4,5,6]]}') end
 decode();collectgarbage("collect")
 assert(weak[1]==nil,"decoder retains a completed chart")
end)
