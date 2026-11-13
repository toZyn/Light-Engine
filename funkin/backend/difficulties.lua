local Difficulties = {}

local function normalize(value)
 local out,seen={},{}
 if type(value)=='string' then
  local split={}
  for part in value:gmatch('[^,]+') do split[#split+1]=part end
  value=split
 end
 for _,name in ipairs(type(value)=='table' and value or {}) do
  if type(name)=='string' then
   name=name:gsub('^%s+',''):gsub('%s+$','')
   if name~='' and not seen[name:lower()] then
    seen[name:lower()]=true
    out[#out+1]=name:gsub('^%l',string.upper)
   end
  end
 end
 return out
end

function Difficulties.forSong(song, declared)
 local base='songs/'..paths.formatToSongPath(song)..'/'
 local found,seen={},{}
 local function add(name)
  for _,name in ipairs(normalize({name})) do
   if not seen[name:lower()] then seen[name:lower()]=true;found[#found+1]=name end
  end
 end
 local function json(key)
  local ok,data=pcall(paths.getJSON,key)
  return ok and type(data)=='table' and data or nil
 end
 local generic=false
 local metadata={}
 local function read(key, variant)
  local data=json(key)
  if type(data)~='table' then return end
  if type(data.notes)=='table' and not data.notes.player and not data.notes.enemy and #data.notes==0 then
   for name,notes in pairs(data.notes) do if type(notes)=='table' then add(name) end end
  elseif variant then
   add(variant)
  else
   generic=true
  end
 end
 for _,file in ipairs(paths.getItems(base..'charts','file','json')) do
  local name=file:match('^(.*)%.json$')
  if name and name~='events' and name~='meta' and name~='metadata' then read(base..'charts/'..name,name) end
 end
 local slug=paths.formatToSongPath(song)
 for _,file in ipairs(paths.getItems(base:sub(1,-2),'file','json')) do
  local name=file:match('^(.*)%.json$')
  if name then
   if name=='meta' or name=='metadata' or name:match('^meta%-') or name:find('-metadata',1,true) then
    local data=json(base..name)
    local playData=data and type(data.playData)=='table' and data.playData or data
    for _,diff in ipairs(normalize(playData and playData.difficulties)) do metadata[#metadata+1]=diff end
   end
   local variant=name:match('^chart%-(.+)$')
   if not variant and name:sub(1,#slug+7)==slug..'-chart-' then variant=name:sub(#slug+8) end
   if variant then
    read(base..name,variant)
   elseif name=='chart' or name==slug then
    read(base..name)
   elseif name~='events' and name~='meta' and name~='metadata' and not name:find('metadata',1,true) and not name:match('^meta%-') then
    local data=json(base..name)
    if type(data)=='table' and (data.song or data.notes) then read(base..name,name) end
   end
  end
 end
 if generic then
  local requested=normalize(declared)
  for _,name in ipairs(metadata) do requested[#requested+1]=name end
  if #requested==0 then requested={'Normal'} end
  for _,name in ipairs(requested) do add(name) end
 end
 local order={easy=1,normal=2,hard=3,erect=4,nightmare=5}
 table.sort(found,function(a,b)
  local ar,br=order[a:lower()] or 99,order[b:lower()] or 99
  return ar==br and a:lower()<b:lower() or ar<br
 end)
 return found
end

function Difficulties.forWeek(week, defaults)
 local declared=normalize(week.difficulties)
 local ordered, common={},nil
 for _,entry in ipairs(week.songs or {}) do
  local song=type(entry)=='table' and entry[1] or entry
  if type(song)=='string' and song~='' then
   local diffs=Difficulties.forSong(song,#declared>0 and declared or defaults)
   local available={}
   for _,name in ipairs(diffs) do available[name:lower()]=true end
   if not common then common=available;ordered=diffs else
    for name in pairs(common) do if not available[name] then common[name]=nil end end
   end
  end
 end
 local result,seen={},{}
 for _,list in ipairs({declared,ordered}) do
  for _,name in ipairs(list) do
   local key=name:lower()
   if common and common[key] and not seen[key] then result[#result+1]=name;seen[key]=true end
  end
 end
 return result
end

function Difficulties.color(name, week)
 week=week or {}
 if week.autoDifficultyColor==false then return {1,1,1} end
 local key=name:lower()
 local colors=type(week.difficultyColors)=='table' and week.difficultyColors or {}
 local override=colors[key] or colors[name]
 if type(override)=='table' then
  local scale=(override[1] or 0)>1 or (override[2] or 0)>1 or (override[3] or 0)>1
  scale=scale and 255 or 1
  return {(override[1] or scale)/scale,(override[2] or scale)/scale,(override[3] or scale)/scale}
 end
 local standard={easy={0.3,1,0.3},normal={0.25,0.8,1},hard={1,0.25,0.25},erect={0.7,0.3,1},nightmare={1,0.2,0.65}}
 if standard[key] then return standard[key] end
 local hash=0
 for i=1,#key do hash=(hash*31+key:byte(i))%16777216 end
 local palette={{0.2,0.9,1},{1,0.4,0.75},{1,0.65,0.2},{0.65,0.4,1},{1,0.9,0.2},{0.3,1,0.7},{0.4,0.6,1},{1,0.35,0.4}}
 return palette[hash%#palette+1]
end

return Difficulties
