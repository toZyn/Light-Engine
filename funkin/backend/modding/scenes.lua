local Scenes={}
Scenes.__index=Scenes
local function report(message)
 require("funkin.backend.recoverable-errors").report(message,nil,{source="scene-assets"})
end
function Scenes.validate(data)
 if type(data)~="table" or type(data.scenes)~="table" then return nil,"Expected a scenes array" end
 if data.shaders~=nil and type(data.shaders)~="table" then return nil,"Expected a shaders array" end
 for _,shader in ipairs(data.shaders or {}) do if type(shader)~="string" or shader=="" then return nil,"Invalid shader name" end end
 local names={}
 for index,scene in ipairs(data.scenes) do
  if type(scene)~="table" then return nil,"Invalid scene at "..index end
  if type(scene.name)~="string" or scene.name=="" or names[scene.name] then return nil,"Invalid or duplicate scene name at "..index end
  names[scene.name]=true
  for _,field in ipairs({"assets","characters"}) do
   if scene[field]~=nil and type(scene[field])~="table" then return nil,"Expected "..field.." array: "..scene.name end
  end
  if type(scene.start)~="number" or scene.start<0 or scene.start~=scene.start then return nil,"Invalid scene start: "..scene.name end
  if scene.finish~=nil and (type(scene.finish)~="number" or scene.finish<=scene.start) then return nil,"Invalid scene finish: "..scene.name end
  if scene.lead~=nil and (type(scene.lead)~="number" or scene.lead<0) then return nil,"Invalid scene lead: "..scene.name end
  for _,asset in ipairs(scene.assets or {}) do
   if type(asset)~="table" or (asset[1]~="image" and asset[1]~="atlas" and asset[1]~="animate") or type(asset[2])~="string" or asset[2]=="" then return nil,"Invalid asset: "..scene.name end
  end
  for _,name in ipairs(scene.characters or {}) do if type(name)~="string" or name=="" then return nil,"Invalid character: "..scene.name end end
 end
 return true
end
function Scenes.new(data)
 local ok,err=Scenes.validate(data)
 if not ok then report(err);return nil,err end
 local self=setmetatable({scenes={},resources={},closed=false,lastTime=0},Scenes)
 for _,description in ipairs(data.scenes) do
  local scene={description=description,assets={},objects={},pending=0,status="idle"}
  local seen={}
  local function add(kind,key)
   local id=kind..":"..key
   if seen[id] then return end
   seen[id]=true
   scene.assets[#scene.assets+1]=id
   self.resources[id]=self.resources[id] or {kind=kind,key=key,refs=0}
  end
  for _,asset in ipairs(description.assets or {}) do add(asset[1],asset[2]) end
  for _,name in ipairs(description.characters or {}) do
   local character=Parser.getCharacter(name)
   if character and character.sprite then
    if paths.exists(paths.getPath("images/"..character.sprite.."/Animation.json"),"file") then
     add("animate",character.sprite)
    else
     add("atlas",character.sprite)
     for _,anim in ipairs(character.animations or {}) do
      local extra=anim[7] or anim.assetPath or anim.image
      if type(extra)=="string" and extra~="" then add("atlas",extra) end
     end
    end
    if HealthIcon and HealthIcon.resolveIconPath then add("image",HealthIcon.resolveIconPath(character.icon or "face")) end
   end
  end
  self.scenes[description.name]=scene
 end
 return self
end
function Scenes:_evict(resource)
 if resource.refs>0 or not resource.value then return end
 for _,other in pairs(self.resources) do
  if other~=resource and other.refs>0 and (other.value==resource.value or other.texture==resource.value or (resource.texture and other.value==resource.texture) or (resource.texture and other.texture==resource.texture)) then return end
 end
 for _,cache in ipairs({paths.atlases,paths.images,paths.animate_atlases}) do
  for key,value in pairs(cache) do
   if (value==resource.value or value==resource.texture) and not resource.borrowed[value] and not paths.isPersistant(key) then cache[key]=nil end
  end
 end
 resource.value=nil;resource.texture=nil
 collectgarbage("step",64)
end
function Scenes:prepare(name)
 local scene=assert(self.scenes[name],"Unknown scene "..tostring(name))
 if self.closed or scene.status~="idle" then return scene.status end
 scene.status="loading";scene.pending=#scene.assets
 for _,id in ipairs(scene.assets) do
  local resource=self.resources[id]
  resource.refs=resource.refs+1
  if resource.value then scene.pending=scene.pending-1
  else
   resource.borrowed=resource.borrowed or setmetatable({}, {__mode="k"})
   for _,cache in ipairs({paths.images,paths.atlases}) do for _,value in pairs(cache) do resource.borrowed[value]=true end end
   local callback=function(value,err)
    resource.value=value
    resource.texture=resource.kind=="atlas" and value and value.texture or nil
    if scene.status=="loading" then
     scene.pending=scene.pending-1
     if not value then scene.error=tostring(err or "Missing asset "..resource.key);report(scene.error) end
     if scene.pending==0 then scene.status=scene.error and "failed" or "ready" end
    end
    if self.closed or scene.status=="released" then self:_evict(resource) end
   end
   local loader=resource.kind=="atlas" and paths.async.getAtlas or resource.kind=="animate" and paths.async.getAnimateAtlas or paths.async.getImage
   loader(resource.key,callback)
  end
 end
 if scene.pending==0 then scene.status=scene.error and "failed" or "ready" end
 return scene.status
end
function Scenes:track(name,object,owner)
 local scene=assert(self.scenes[name],"Unknown scene "..tostring(name))
 assert(not self.closed and scene.status~="released","Scene already released")
 if not owner and game and game.getState then
  local state=game.getState()
  if state and state.members and table.find(state.members,object) then owner=state
  elseif state and state.stage and state.stage.members and table.find(state.stage.members,object) then owner=state.stage end
 end
 scene.objects[#scene.objects+1]={object=object,owner=owner or object.parent}
 return object
end
function Scenes:release(name)
 local scene=assert(self.scenes[name],"Unknown scene "..tostring(name))
 if scene.status=="released" then return end
 local acquired=scene.status~="idle"
 scene.status="released"
 for _,entry in ipairs(scene.objects) do
  local object=entry.object
  if entry.owner and entry.owner.remove then entry.owner:remove(object) end
  if object.destroy then object:destroy() end
 end
 scene.objects={}
 if acquired then for _,id in ipairs(scene.assets) do
  local resource=self.resources[id];resource.refs=math.max(0,resource.refs-1)
 end end
 for _,resource in pairs(self.resources) do self:_evict(resource) end
end
function Scenes:update(time)
 if self.closed then return end
 self.lastTime=time
 for name,scene in pairs(self.scenes) do
  local d=scene.description
  if d.finish and time>=d.finish then self:release(name)
  elseif time>=math.max(0,d.start-(d.lead or 3)) then self:prepare(name) end
 end
end
function Scenes:dispose()
 if self.closed then return end
 self.closed=true
 for name in pairs(self.scenes) do self:release(name) end
end
return Scenes
