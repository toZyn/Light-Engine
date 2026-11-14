local Scene = {}
local Job = require 'funkin.backend.scenejob'
local kinds={image=true,sound=true,audio=true,inst=true,voices=true,animate=true}
local slots={bf='bf',boyfriend='bf',player='bf',player1='bf',['0']='bf',gf='gf',girlfriend='gf',gfversion='gf',['2']='gf',dad='dad',opponent='dad',player2='dad',['1']='dad'}

function Scene.slot(slot)
 return slots[tostring(slot or 'dad'):lower()] or 'dad'
end

function Scene.validate(data)
 local errors={}
 if type(data)~='table' then return false,{'scene must be an object'} end
 for _,key in ipairs({'assets','shaders','characters'}) do
  local list=data[key]
  if list~=nil and type(list)~='table' then errors[#errors+1]=key..' must be an array'
  else
   local array=true
   for k in pairs(list or {}) do
    if type(k)~='number' or k<1 or k%1~=0 or k>#list then array=false end
   end
   if not array then errors[#errors+1]=key..' must be an array' end
   for i,item in ipairs(list or {}) do
    local valid
    if key=='assets' then valid=type(item)=='table' and kinds[item[1]] and type(item[2])=='string' and item[2]~=''
    elseif key=='shaders' then valid=type(item)=='string' and item~=''
    else valid=type(item)=='table' and type(item.character)=='string' and item.character~='' and slots[tostring(item.slot or 'dad'):lower()]~=nil end
    if not valid then errors[#errors+1]=key..'['..i..'] is invalid' end
   end
  end
 end
 return #errors==0,errors
end

function Scene.characters(events,definition)
 local list,seen={},{}
 local function add(slot,name)
  if type(name)~='string' or name=='' then return end
  slot=Scene.slot(slot)
  local key=slot..':'..name
  if not seen[key] then seen[key]=true;list[#list+1]={slot=slot,character=name} end
 end
 for _,entry in ipairs((definition or {}).characters or {}) do add(entry.slot,entry.character) end
 for _,event in ipairs(events or {}) do
  if tostring(event.e):lower():gsub('[%s%-%_]','')=='changecharacter' then
   local v=event.v or {}
   if type(v)=='table' then add(v.slot or v.target or v[1],v.character or v.char or v[2]) end
  end
 end
 return list
end

local function characterAssets(name)
 local data=Parser.getCharacter(name)
 if not data or not data.sprite then return end
 local sprite=data.sprite
 local animate=paths.exists(paths.getPath('images/'..sprite..'/Animation.json'),'file')
 paths.async.loadBatch({{animate and 'animate' or 'image',sprite,nil,true}})
 for _,anim in ipairs(data.animations or {}) do
  local atlas=anim[7] or anim.assetPath or anim.image
  if type(atlas)=='string' and atlas~='' then paths.async.getImage(atlas,nil,true) end
 end
 if HealthIcon and HealthIcon.resolveIconPath then
  paths.async.getImage(HealthIcon.resolveIconPath(data.icon or 'face'),nil,true)
 end
end

function Scene.preload(state)
 local key='songs/'..paths.formatToSongPath(PlayState.SONG.song)..'/scene'
 local definition={}
 if paths.exists(paths.getPath(key..'.json'),'file') then
  definition=paths.getJSON(key)
  local valid,errors=Scene.validate(definition)
  if not valid then error(key..'.json: '..table.concat(errors,'; '),0) end
 end
 state.sceneDefinition=definition
 state.sceneCharacters=Scene.characters(PlayState.SONG.events,definition)
 paths.async.loadBatch(definition.assets or {})
 for _,entry in ipairs(state.sceneCharacters) do
  Job.checkpoint('Assets: '..entry.character)
  characterAssets(entry.character)
 end
 local shaders={}
 for _,name in ipairs(definition.shaders or {}) do shaders[name]=math.max(shaders[name] or 0,1) end
 local stageFile=paths.getPath('data/stages/'..tostring(PlayState.SONG.stage)..'.lua')
 if paths.exists(stageFile,'file') then
  local source=love.filesystem.read(stageFile) or ''
  for name in source:gmatch('Shader%s*%(%s*["\']([^"\']+)["\']') do shaders[name]=(shaders[name] or 0)+1 end
 end
 local names={};for name in pairs(shaders) do names[#names+1]=name end;table.sort(names)
 for _,name in ipairs(names) do Shader.prepare(name,shaders[name]) end
end

function Scene.prepareCharacters(state)
 state._preparedCharacters={}
 for i,entry in ipairs(state.sceneCharacters or {}) do
  Job.checkpoint('Preparing character: '..entry.character,0.85)
  local char=Character(0,0,entry.character,entry.slot=='bf',true)
  char._sceneBasePosition={char.x,char.y}
  state._preparedCharacters[entry.slot..':'..entry.character]=char
 end
end

function Scene.disposeCharacters(state)
 for _,char in pairs(state._preparedCharacters or {}) do
  if char.script then char.script:close() end
  char:destroy()
 end
 state._preparedCharacters=nil
end

return Scene
