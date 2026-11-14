local Loading=require "funkin.backend.loading"
local LoadScreen=SpriteGroup:extend("LoadScreen")
local lastRunner=1
local artwork={"bfgang","erectsampler","fnfonmobile","heybabe","momitsmrbeast","picogang","picoupdate","rememberweek8iscoming","blank"}
function LoadScreen:new(nextState,style)
 LoadScreen.super.new(self)
 self.nextState=nextState
 self.time=0
 self.style=style or {art=ClientPrefs.data.loadingArtwork=="Custom" and ("custom_artwork/placeholder"..love.math.random(3)) or "artwork/"..artwork[love.math.random(#artwork)],disabled=ClientPrefs.data.loadingArtwork=="Disable"}
 if not self.style.runner then
  lastRunner=3-lastRunner
  self.style.runner=love.math.random(20)==1 and "secret/bfsticker" or lastRunner==1 and "bf" or "gf"
 end
 self.camera=game.cameras.add(Camera(),false)
 self.camera.bgColor={0,0,0,1}
 self.cameras={self.camera}
 local background
 if not self.style.disabled then background=paths.getImage("loading/"..self.style.art) end
 self.background=Sprite(0,0,background);self.background.visible=not self.style.disabled;self:add(self.background)
 self.mic=Sprite(1000,620,paths.getImage("loading/mic-stand"));self.mic.scale:set(.3,.3);self.mic:updateHitbox();self:add(self.mic)
 self.runner=Sprite(self.style.runner=="gf" and 1020 or 1000,self.style.runner=="gf" and 400 or 445)
 self.runner:setFrames(paths.getAtlas("loading/"..self.style.runner))
 self.runner.animation:addByPrefix("run","run",24,true);self.runner.animation:play("run")
 self.runner.antialiasing=false;self.mic.antialiasing=false
 self.runner.scale:set(.3,.3);self.runner:updateHitbox();self:add(self.runner)
 self.letters={}
 for i=1,10 do
  local letter=i<=7 and ("LOADING"):sub(i,i) or "."
  local x=i<=7 and 40+(i-1)*52 or 40+7*52+(i-8)*22
  local text=Text(x,640,letter,paths.getFont(i<=7 and "Loading.ttf" or "LoadingDot.ttf",64),Color.WHITE)
  self.letters[i]=text;self:add(text)
 end
 self.status=Text(40,610,"Preparing",paths.getFont("vcr.ttf",16),Color.WHITE);self:add(self.status)
 self:resize()
 if nextState and nextState.preload then self.task=Loading.new(function()nextState:preload()end) end
end
function LoadScreen:resize()
 self.layoutWidth,self.layoutHeight=game.width,game.height
 local cover=math.max(game.width/self.background:getFrameWidth(),game.height/self.background:getFrameHeight())*1.02
 self.background.scale:set(cover,cover)
 self.background:updateHitbox();self.background.x=(game.width-self.background.width)/2;self.background.y=(game.height-self.background.height)/2
 self.runner.x=game.width-(self.style.runner=="gf" and 260 or 280)
 self.mic.x=game.width-280
 self.runner.y=(self.style.runner=="gf" and 400 or 445)+(game.height-720)
 self.mic.y=620+(game.height-720)
 self.status.y=game.height-110
 self.camera:resize(game.width,game.height,1,1,true)
end
function LoadScreen:isReady()
 return (not self.task or self.task.done) and paths.async.getProgress()==1
end
function LoadScreen:update(dt)
 if self.layoutWidth~=game.width or self.layoutHeight~=game.height then self:resize() end
 self.time=self.time+dt
 if self.task then self.task:step() end
 local task=self.externalTask or self.task
 local stats=paths.async.getStats()
 if task and not task.done then
  self.status.content=task.label..(task.completed and (" "..task.completed.."/"..tostring(task.total or "?")) or "")
 elseif not self:isReady() then self.status.content="Loading assets "..stats.completed.."/"..stats.queued
 else self.status.content=self.nextState and "Assets ready" or "Ready" end
 for i,text in ipairs(self.letters) do
  text.y=game.height-80
  if i<=7 then
   local t=self.time%1.29-(i-1)*.12
   if t>=0 and t<.12 then text.y=text.y-28*(1-(1-t/.12)^2)
   elseif t>=.12 and t<.30 then text.y=text.y-28*(1-((t-.12)/.18)^2) end
  else text.alpha=(i-8)<math.floor(self.time/.5)%4 and 1 or 0 end
 end
 LoadScreen.super.update(self,dt)
end
function LoadScreen:draw()
 if game.cameras.list[#game.cameras.list]~=self.camera then table.delete(game.cameras.list,self.camera);table.insert(game.cameras.list,self.camera) end
 LoadScreen.super.draw(self)
end
function LoadScreen:destroy()
 if self.camera and table.find(game.cameras.list,self.camera) then game.cameras.remove(self.camera) end
 self.camera=nil
 LoadScreen.super.destroy(self)
end
return LoadScreen
