check('scene preparation yields once per step and reaches completion only on return', function()
 local Job = require 'funkin.backend.scenejob'
 local events = {}
 local job = Job.new(function()
  events[#events+1]='start';Job.checkpoint('Characters', 0.4)
  events[#events+1]='characters';Job.checkpoint('Notes', 0.8)
  events[#events+1]='notes'
 end)
 assert(not job.done and job.progress==0)
 job:step();assert(#events==1 and job.phase=='Characters' and job.progress==0.4 and not job.done)
 job:step();assert(#events==2 and job.progress==0.8 and not job.done)
 job:step();assert(#events==3 and job.done and job.progress==1)
 job:step();assert(#events==3)
 Job.checkpoint('synchronous callers remain supported', 0.5)
end)
check('cancelled preparation never resumes and errors retain phase and traceback', function()
 local Job = require 'funkin.backend.scenejob'
 local called=false
 local job=Job.new(function() Job.checkpoint('Uploads', 0.3);called=true end)
 job:step();job:cancel();job:step();assert(not called and job.cancelled and not job.done)
 local bad=Job.new(function()Job.checkpoint('Stage props',0.5);error('broken prop')end)
 bad:step();local ok,err=pcall(bad.step,bad)
 assert(not ok and tostring(err):find('Stage props',1,true) and tostring(err):find('broken prop',1,true))
 assert(tostring(err):find('stack traceback',1,true))
end)
check('loading view defers work until first update and does not invent completion',function()
 local Screen=require 'funkin.ui.loadscreen'
 local calls=0
 local target={preload=function()calls=calls+1 end}
 local view=Screen(target)
 assert(calls==0,'preload blocks before the loading screen can be drawn')
 view:update(0.016)
 assert(calls==1 and view.progress<1)
 assert(view.runner:isOnScreen(game.camera),'loading runner is outside the viewport')
 view:destroy()
end)
check('native song preparation spans frames and finalizes before gameplay',function()
 local state=PlayState(false,'bopeebo','normal')
 state._incrementalLoad=true
 state:preload();paths.async.stop()
 game.switchState(state,true);game.update(0)
 assert(state._prepareJob and not state._postCreated,'scene construction blocked the state switch')
 local frames=0
 while state._prepareJob and frames<300 do game.update(0.016);frames=frames+1 end
 assert(frames>3 and not state._prepareJob and state._postCreated,'scene did not finish')
 assert(state.playerNotefield and state.stage.boyfriend and state.startedCountdown)
 game.switchState(FreeplayState(),true);game.update(0)
end)
check('prepared shader instances are independent and invalid shaders fail once with context',function()
 local old=ClientPrefs.data.shader;ClientPrefs.data.shader=true
 assert(Shader.prepare('wave',2))
 local a,b=Shader('wave'),Shader('wave')
 assert(a:get() and b:get() and a:get()~=b:get(),'prepared uniforms are shared')
 a:set('time',3);b:set('time',9);assert(a.uniforms.time==3 and b.uniforms.time==9)
 local ok,err=Shader.prepare('definitely invalid shader source',1)
 assert(not ok and tostring(err):find('definitely invalid shader source',1,true))
 a:destroy();b:destroy();ClientPrefs.data.shader=old
end)
check('disabled effects and spacing preferences survive mod creation',function()
 local saved=table.clone(ClientPrefs.data)
 ClientPrefs.data.downScroll=true;ClientPrefs.data.middleScroll=false
 ClientPrefs.data.splitReceptors=true;ClientPrefs.data.splitWidth=600;ClientPrefs.data.noteWidth=90
 ClientPrefs.data.flashingLights=false;ClientPrefs.data.shader=false
 local s=PlayState(false,'bopeebo','normal');s:preload();paths.async.stop()
 game.switchState(s,true);game.update(0)
 s.scripts:call('postCreate');s:applyPlayerPreferences()
 assert(s.playerNotefield.downscroll and s.playerNotefield.width==600)
 local cam=Camera();cam:flash(Color.WHITE,1);assert(cam.__flashDuration==0)
 local shader=Shader('wave');assert(not shader:get());shader:destroy();cam:destroy()
 ClientPrefs.data=saved
 game.switchState(FreeplayState(),true);game.update(0)
end)
check('scene declarations discover character changes and reject malformed manifests',function()
 local Scene=require 'funkin.backend.scene'
 local entries=Scene.characters({{e='Change Character',v={'dad','pico'}},{e='changecharacter',v={slot='bf',character='bf'}}},{characters={{slot='gf',character='gf'}}})
 assert(#entries==3 and entries[1].character=='gf' and entries[2].character=='pico')
 local ok,errors=Scene.validate({assets={{'unknown','x'}},shaders={false}})
 assert(not ok and #errors==2)
 assert(Scene.validate({assets={{'image','stages/stage/stageback'}},shaders={'wave'},characters={{slot='dad',character='pico'}}}))
end)
check('scene cache pruning preserves retained atlas dependencies and releases previous images',function()
 local stale=love.graphics.newImage(love.image.newImageData(1,1))
 local live=paths.getImage('menus/loadicon')
 paths.images['scene-old.png']=stale
 paths.beginScene()
 paths.getImage('menus/loadicon')
 paths.finishScene()
 assert(paths.images['scene-old.png']==nil)
 assert(paths.getImage('menus/loadicon')==live)
 assert(not pcall(stale.getWidth,stale),'stale GPU allocation was retained')
end)
check('benchmark captures phases, measured frames and separate memory peaks',function()
 local B=require 'funkin.backend.benchmark'
 B.start({run='test',content='fixture',device='test-device'})
 B.sample(0.01);B.ready();B.sample(0.02);B.sample(0.03)
 local report=B.finish(false)
 assert(report.loading_seconds>=0 and report.frames.count==2)
 assert(math.abs(report.frames.mean_ms-25)<0.001 and report.frames.max_ms==30)
 assert(report.memory.lua_peak_bytes>0 and report.memory.texture_peak_bytes>=0)
 assert(report.context.content=='fixture' and report.context.device=='test-device')
 assert(not B.active)
end)
check('scene manifests reject object-shaped arrays',function()
 local Scene=require 'funkin.backend.scene'
 assert(not Scene.validate({assets={unexpected={'image','x'}}}))
end)
check('pruning a secondary atlas never destroys frames borrowed by a retained atlas',function()
 local Collection=loxreq 'animation.frame.collection'
 local Frame=loxreq 'animation.frame'
 local texture=love.graphics.newImage(love.image.newImageData(4,4))
 local a,b=Collection(texture),Collection(texture)
 local shared=Frame('shared',0,0,2,2,4,4);shared.texture=texture
 b:add(shared);a:addCollection(b)
 paths.images['shared-test.png']=texture
 paths.atlases['shared-primary']=a;paths.atlases['shared-secondary']=b
 paths.beginScene();paths.touch(paths.atlases,'shared-primary');paths.finishScene()
 assert(shared.quad and pcall(shared.quad.getViewport,shared.quad),'retained shared frame was destroyed')
 assert(paths.images['shared-test.png']==texture)
end)
check('repeated prepared character swaps preserve position and camera offsets',function()
 local Scene=require 'funkin.backend.scene'
 local state=PlayState(false,'bopeebo','normal');PlayState.SONG.player2='pico';state:preload();paths.async.stop()
 game.switchState(state,true);game.update(0)
 local initial=state.dad
 local x,y=initial.x,initial.y
 state.sceneCharacters={{slot='dad',character='dad'}};Scene.prepareCharacters(state)
 state.stage.dadCam:set(123,45)
 local first=state:swapCharacter('dad','dad')
 local cx,cy=first.cameraPosition.x,first.cameraPosition.y
 state:swapCharacter('dad',initial.char)
 assert(state.dad.x==x and state.dad.y==y,'initial position changed after swapping back')
 local again=state:swapCharacter('dad','dad')
 assert(again==first and again.cameraPosition.x==cx and again.cameraPosition.y==cy,'camera offsets accumulated')
 game.switchState(FreeplayState(),true);game.update(0)
end)
check('partial entry tolerates input, focus, resize and leaving before completion',function()
 local state=PlayState(false,'bopeebo','normal');state:preload();paths.async.stop()
 state._incrementalLoad=true
 game.switchState(state,true);game.update(0)
 for i=1,3 do game.update(0.016) end
 local job=assert(state._prepareJob)
 state:focus(false);state:resize(1280,720)
 state:onKeyPress('a','key',nil,false,love.timer.getTime())
 state:onKeyRelease('a','key',nil,love.timer.getTime())
 game.switchState(FreeplayState(),true);game.update(0)
 assert(job.cancelled and not state._prepareJob)
end)
check('built-in shader sources validate against GLES',function()
 for _,name in ipairs({'wave','rain','csb','wiggle'}) do
  local code=assert(love.filesystem.read('assets/shaders/'..name..'.frag'))
  local valid,message=love.graphics.validateShader(true,Shader.sanitizeGLSL(code))
  assert(valid,name..': '..tostring(message))
 end
end)
check('disabled flashes preserve callback timing without recursive immediate execution',function()
 local saved=ClientPrefs.data.flashingLights;ClientPrefs.data.flashingLights=false
 local camera=Camera();local calls=0
 camera:flash(Color.WHITE,0.1,function()calls=calls+1 end)
 assert(calls==0)
 camera:update(0.05);assert(calls==0 and camera.__flashAlpha==0)
 camera:update(0.06);assert(calls==1 and camera.__flashAlpha==0)
 camera:update(0.2);assert(calls==1)
 camera:destroy();ClientPrefs.data.flashingLights=saved
end)
