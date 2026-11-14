check('loading screen animates supplied artwork while real preparation spans frames',function()
 local target=PlayState(false,'bopeebo','normal')
 local loading=LoadState(target)
 game.switchState(loading,true)
 local ticks,building=0,0
 local labels={}
 local deadline=love.timer.getTime()+30
 while love.timer.getTime()<deadline do
  ticks=ticks+1
  local state=game.getState()
  if state==target and not target._entryTask then break end
  paths.update(1/60)
  game.update(1/60)
  state=game.getState()
  if state==target and target._entryTask then
   building=building+1
   labels[target._entryTask.label]=true
   assert(target._loadingOverlay and not target._loadingOverlay.externalTask.done)
  end
  love.graphics.clear(0,0,0,1);game.draw();love.graphics.present()
  if building==1 then love.graphics.captureScreenshot('streamed-loading.png') end
  love.timer.sleep(.001)
 end
 assert(game.getState()==target and target._postCreated and not target._entryTask,'Gameplay did not finish preparing')
 assert(building>0 and ticks>1,'Preparation blocked the loading loop')
 assert(target.playerNotefield and target.dad and target.boyfriend,'Ready before objects existed')
 for _,script in ipairs(target.scripts.scripts) do assert(next(script.__failedfunc)==nil,'Script failed during staged entry') end
 game.switchState(MainMenuState(),true);game.update(0)
end)
check('loading task exposes real checkpoints and retains contextual failures',function()
 local Loading=require('funkin.backend.loading')
 local count=0
 local task=Loading.new(function()
  for i=1,3 do count=count+1;Loading.checkpoint('Task',i,3) end
 end)
 assert(not task:step(0) and count==1 and task.completed==1)
 assert(not task:step(0) and count==2)
 assert(not task:step(0) and count==3)
 assert(task:step(0) and task.done)
 local bad=Loading.new(function()error('contextual loading failure')end)
 local ok,err=pcall(function()bad:step()end)
 assert(not ok and tostring(err):find('contextual loading failure',1,true))
end)

check('partially constructed gameplay can be left without stale callbacks',function()
 local target=PlayState(false,'bopeebo','normal')
 target._streamedEntry=true
 target._build=function() while true do require('funkin.backend.loading').checkpoint('Waiting') end end
 game.switchState(target,true);game.update(0)
 assert(target._entryTask and target._loadingOverlay)
 game.switchState(MainMenuState(),true);game.update(0)
 assert(not target._entryTask and not target._loadingOverlay and not PlayState.conductor)
end)
