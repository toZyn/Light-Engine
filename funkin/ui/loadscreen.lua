local SceneJob = require "funkin.backend.scenejob"
local LoadScreen = SpriteGroup:extend("LoadScreen")

function LoadScreen:new(nextState)
 LoadScreen.super.new(self)
 self.scrollFactor:set(0,0)
 self.time,self.progress,self.phase=0,0,'Preparing'
 self.drawSerial,self.workSerial=0,0
 self:attach()
 self.nextState=nextState
 if nextState and nextState.enterScene then
  paths.beginScene()
 end
 self.backdrop=Graphic(0,0,game.width,game.height,Color.BLACK)
 self:add(self.backdrop)
 local names={'bfgang','erectsampler','fnfonmobile','heybabe','momitsmrbeast','picogang','picoupdate','rememberweek8iscoming'}
 local image=paths.getImage('loading/artwork/'..names[love.math.random(#names)])
 if image then
  self.art=Sprite(0,0,image)
  local scale=math.max(game.width/image:getWidth(),game.height/image:getHeight())
  self.art.scale:set(scale,scale);self.art:updateHitbox();self.art:screenCenter()
  self:add(self.art)
 end
 self.shade=Graphic(0,game.height-145,game.width,145,Color.BLACK)
 self.shade.alpha=0.7;self:add(self.shade)
 local runner=love.math.random(2)==1 and 'bf' or 'gf'
 if love.math.random(20)==1 then runner='secret/bfsticker' end
 self.runner=Sprite(game.width-245,game.height-270)
 self.runner:setFrames(paths.getSparrowAtlas('loading/'..runner))
 self.runner.animation:addByPrefix('run','run',24,true);self.runner.animation:play('run')
 self.runner.scale:set(0.3,0.3);self.runner:updateHitbox();self.runner.antialiasing=false;self:add(self.runner)
 self.mic=Sprite(game.width-245,game.height-100,paths.getImage('loading/mic-stand'))
 self.mic.scale:set(0.3,0.3);self.mic:updateHitbox();self:add(self.mic)
 self.letters={}
 for i=1,7 do
  local letter=Text(32+(i-1)*43,game.height-115,('LOADING'):sub(i,i),paths.getFont('Loading.ttf',56),Color.WHITE)
  letter.outline.width=2;self.letters[i]=letter;self:add(letter)
 end
 self.status=Text(34,game.height-42,'Preparing',paths.getFont('vcr.ttf',18),Color.WHITE)
 self:add(self.status)
 if nextState then
  self.preloadJob=SceneJob.new(function()
   if nextState.preload then nextState:preload() end
  end)
 end
end

function LoadScreen:isReady()
 return self.preloadJob and self.preloadJob.done and paths.async.getProgress()==1
end

function LoadScreen:attach()
 if self._handoffOwner then
  table.delete(self._handoffOwner.members,self)
  self._handoffOwner=nil
 end
 if not self.camera or not table.find(game.cameras.list,self.camera) then
  self.camera=game.cameras.add(Camera(),false)
 end
 self.cameras={self.camera}
end

function LoadScreen:advance(job)
 if self.drawSerial<=self.workSerial then return false end
 self.workSerial=self.drawSerial
 job:step()
 return true
end

function LoadScreen:hasPresentedWork()
 return self.drawSerial>self.workSerial
end

function LoadScreen:draw()
 if self.camera then
  table.delete(game.cameras.list,self.camera)
  table.insert(game.cameras.list,self.camera)
 end
 LoadScreen.super.draw(self)
 self.drawSerial=self.drawSerial+1
end

function LoadScreen:handoff(owner)
 local target=self.nextState
 if target.enterScene then
  target._incrementalLoad=true
  target._loadingView=self
  target.skipTransIn=true
  target.retainOnSwitch={[self]=true}
  self._handoffOwner=owner
 end
 return target
end

function LoadScreen:cancel()
 if self.preloadJob then self.preloadJob:cancel() end
end

function LoadScreen:resize()
 self.backdrop.width,self.backdrop.height=game.width,game.height
 self.shade.width,self.shade.y=game.width,game.height-145
 self.runner:setPosition(game.width-245,game.height-270)
 self.mic:setPosition(game.width-245,game.height-100)
 self.status.y=game.height-42
 if self.art then
  local scale=math.max(game.width/self.art.texture:getWidth(),game.height/self.art.texture:getHeight())
  self.art.scale:set(scale,scale);self.art:updateHitbox();self.art:screenCenter()
 end
end

function LoadScreen:update(dt)
 self.time=self.time+dt
 if self.preloadJob and not self.preloadJob.done then self:advance(self.preloadJob) end
 local stats=paths.async.getStats()
 if self.stageProgress then
  self.progress=self.stageProgress
 elseif self.preloadJob and self.preloadJob.done then
  self.progress=0.25+paths.async.getProgress()*0.25
  self.phase='Decoding and uploading assets'
 else
  self.progress=(self.preloadJob and self.preloadJob.progress or 0)*0.25
  self.phase=self.preloadJob and self.preloadJob.phase or self.phase
 end
 local percent=self.progress==1 and 100 or math.floor(self.progress*100)
 self.status.content=string.format('%s  %d%%  |  Assets %d/%d%s',self.phase,percent,stats.completed,stats.queued,
  stats.failed>0 and ('  |  Failed: '..stats.failed) or '')
 for i,letter in ipairs(self.letters) do
  local t=(self.time-(i-1)*0.12)%1.29
  letter.y=game.height-115-(t<0.3 and math.sin(t/0.3*math.pi)*28 or 0)
 end
 LoadScreen.super.update(self,dt)
end

function LoadScreen:destroy()
 self:cancel()
 if self.camera and table.find(game.cameras.list,self.camera) then game.cameras.remove(self.camera) end
 self.camera=nil
 self._handoffOwner=nil
 LoadScreen.super.destroy(self)
end

return LoadScreen
