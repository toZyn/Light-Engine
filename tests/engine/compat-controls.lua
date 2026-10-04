-- Run as main.lua in a temporary LÖVE checkout runner.
require 'loxel'
require 'funkin'
local function raises(fn,word)
 local ok,err=pcall(fn);assert(not ok and tostring(err):find(word,1,true),tostring(err))
end
function love.load()
 local ok,err=xpcall(function()
  love.window.setMode(320,240,{vsync=0});game.width,game.height=320,240
  love.filesystem.createDirectory('assets/images')
  local image=love.image.newImageData(2,2);image:encode('png','assets/images/test-controls.png');image:release()
  local state=Group();state.camHUD=Camera();game.camera=Camera()
  require('loxel.lib.gamestate').stack[1]=state
  state.conductor=require('funkin.backend.gameplay.conductor')();state.conductor:forceBPM(123);state.conductor.beat.f=3.5
  local script=Script('tests/engine/compat-fixture.lua',false,true,true)
  local ctx=Script.createCompatibility(state,script);local f=script.variables
  assert(type(f.makeLuaText)=='function','missing scoped text/camera/timing/asset controls')
  local globalFont=love.graphics.getFont()
  f.makeLuaText('label','Hello',180,10,12);f.addLuaText('label');f.setObjectCamera('label','hud')
  local label=ctx.objects.label;local ownedFont=label.font
  assert(label:is(Text) and label.font~=globalFont and label.limit==180 and label.cameras[1]==state.camHUD)
  f.setTextString('label','A longer message');f.setTextSize('label',28);f.setTextColor('label','E8793E');f.setTextAlignment('label','center')
  assert(label.content=='A longer message' and label.font:getHeight()>16 and label.alignment=='center')
  assert(not pcall(ownedFont.getHeight,ownedFont),'replaced owned font was retained')
  raises(function() f.setTextSize('label',0) end,'positive')
  raises(function() f.setTextAlignment('label','diagonal') end,'alignment')
  f.makeLuaSprite('sprite');raises(function() f.setTextString('sprite','bad') end,'Text')
  f.setTextFont('label','vcr.ttf')
  local cachedFont=paths.getFont('vcr.ttf',28);assert(label.font==cachedFont)
  f.setTextSize('label',20);local font20=paths.getFont('vcr.ttf',20);assert(label.font==font20)
  assert(love.graphics.getFont()==globalFont,'text API changed the global font')
  local canvas=love.graphics.newCanvas(320,240)
  love.graphics.push('all');love.graphics.setCanvas(canvas);love.graphics.clear();label:__render(state.camHUD);love.graphics.pop();canvas:release()
  f.doTweenAlpha('textFade','label',.4,.1);ctx:update(.2);assert(label.alpha==.4)
  f.removeLuaText('label',false);assert(#state.members==0 and label.exists and label.font==font20)
  f.addLuaText('label');f.removeLuaText('label');assert(not ctx.objects.label and pcall(font20.getHeight,font20))
  assert(f.getSongPosition()==0 and f.getSongBpm()==123 and f.getSongBeat()==3.5)
  game.sound.playMusic(paths.getMusic('freakyMenu'),.2,true);game.sound.music.time=2
  assert(math.abs(f.getSongPosition()-2000)<100)
  local completions={}
  script:set('onCameraEffectCompleted',function(tag,camera,kind)
   completions[#completions+1]={tag,camera,kind}
   if tag=='firstFade' then f.cameraFade('hud','000000',.1,true,true,'secondFade') end
  end)
  assert(f.cameraShake('hud',.01,.1,false,'xy','shake'))
  assert(not f.cameraShake('hud',.02,.1,false,'xy','ignored'))
  assert(f.cameraFlash('hud','FFFFFF',.1,true,'flash'))
  assert(f.cameraFade('hud','000000',.1,true,false,'firstFade'))
  state.camHUD:update(.2);ctx:update(.01)
  assert(#completions==3 and state.camHUD.__fadeDuration>0,'camera completion restarted effect was lost')
  state.camHUD:update(.2);ctx:update(.01);assert(#completions==4 and completions[4][1]=='secondFade')
  raises(function() f.cameraShake('hud',-1,.1) end,'nonnegative')
  raises(function() f.cameraFlash('hud','bad',.1) end,'hexadecimal')
  state.camOther=Sprite();raises(function() f.cameraFlash('other','FFFFFF',.1) end,'Camera')
  local cachedImage=f.precacheImage('test-controls');assert(cachedImage==paths.getImage('test-controls'))
  assert(f.precacheSound('scrollMenu')==paths.getSound('scrollMenu'))
  assert(f.precacheMusic('freakyMenu')==paths.getMusic('freakyMenu'))
  local loaded={}
  script:set('onAssetFailure',function(tag,kind,key,resource,errorMessage)
   assert(tag=='missingRequest' and resource==nil and type(errorMessage)=='string');script:set('assetFailure',true)
  end)
  f.requestAsset('image','missing-controls-image','missingRequest','onAssetFailure')
  assert(f.assetFailure and next(script.__failedfunc)==nil,'missing asset did not report a scoped failure')
  script:set('onAssetLoaded',function(tag,kind,key,resource,errorMessage)
   assert(resource and not errorMessage);loaded[#loaded+1]=tag
  end)
  paths.images[paths.getPath('images/test-controls.png')]=nil -- Force real worker decoding.
  f.requestAsset('image','test-controls','imageRequest')
  local deadline=love.timer.getTime()+4
  while #loaded==0 do assert(love.timer.getTime()<deadline);paths.async.update(.01);love.timer.sleep(.002) end
  assert(loaded[1]=='imageRequest')
  f.requestAsset('image','test-controls','cachedRequest')
  assert(loaded[2]=='cachedRequest','cached resource request did not complete immediately')
  paths.images[paths.getPath('images/test-controls.png')]=nil
  f.requestAsset('image','test-controls','cancelRequest');f.cancelAssetRequest('cancelRequest')
  paths.async.stop() -- The old generation must not revive its request callbacks.
  f.requestAsset('image','test-controls','newGeneration')
  while #loaded<3 do assert(love.timer.getTime()<deadline);paths.async.update(.01);love.timer.sleep(.002) end
  assert(loaded[3]=='newGeneration' and #loaded==3,'cancelled/old-generation callback reappeared')
  paths.images[paths.getPath('images/test-controls.png')]=nil
  local disposedCalls=0
  script:set('onAssetLoaded',function() disposedCalls=disposedCalls+1 end)
  f.requestAsset('image','test-controls','disposeRequest')
  f.makeLuaText('cleanup','Owned default font',0,0,0);f.addLuaText('cleanup');local cleanupFont=ctx.objects.cleanup.font
  f.cameraFlash('hud','FFFFFF',10,true,'ownFlash')
  f.cameraShake('hud',.01,10,true,'xy','ownShake')
  f.cameraFade('hud','000000',10,true,false,'ownFade')
  local otherCallback=function() end
  state.camHUD:flash(Color.WHITE,5,otherCallback,true) -- Another owner replaced our flash.
  ctx:dispose()
  assert(state.camHUD.__flashComplete==otherCallback and state.camHUD.__flashAlpha==1,'disposal cancelled another camera owner')
  assert(state.camHUD.__shakeDuration==0 and state.camHUD.__fadeDuration==0,'owned camera effects survived disposal')
  assert(not pcall(cleanupFont.getHeight,cleanupFont) and pcall(cachedFont.getHeight,cachedFont),'font ownership cleanup incorrect')
  local destroyedCamera=Camera();state.camOther=destroyedCamera
  local function disposedContext()
   local abandonedScript=Script('tests/engine/compat-fixture.lua',false,true,true)
   local abandoned=Script.createCompatibility(state,abandonedScript)
   abandonedScript.variables.requestAsset('image','test-controls','abandoned')
   abandonedScript.variables.cameraFlash('other','FFFFFF',5,true,'destroyedCamera')
   destroyedCamera:destroy()
   abandoned:dispose();abandonedScript:close()
   assert(destroyedCamera.__flashComplete==nil,'destroyed camera retained owned completion closure')
   return setmetatable({abandoned},{__mode='v'})
  end
  -- End the allocating stack frame before checking reachability; LuaJIT may
  -- retain registers from a lexical block until its enclosing function returns.
  local weakContext=disposedContext()
  collectgarbage('collect')
  assert(weakContext[1]==nil,'pending callback retained a disposed context/state')
  while paths.async.getProgress()<1 do assert(love.timer.getTime()<deadline);paths.async.update(.01);love.timer.sleep(.002) end
  assert(disposedCalls==0,'late async resource reached disposed/cancelled context')
  assert(#state.members==0 and ctx.objects.cleanup==nil)
  assert(rawget(script.variables,'makeLuaText')==nil and rawget(script.variables,'requestAsset')==nil,'new controls were not restored on dispose')
  script:close();game.sound.destroy(true);paths.async.stop()
  local example=Script('examples/compat-mod/data/scripts/compat-scene.lua',false,true,true)
  assert(example.chunk and not example.closed,'controls scene example failed to load')
  example:call('create');example:call('update',.2);example:call('postCreate');example:call('beat',4);example:call('leave')
  assert(next(example.__failedfunc)==nil,'controls scene example failed callback');example:close()
  print('COMPAT CONTROLS PASS: real Text/render/fonts/ownership; native Camera effects/restart/scoped disposal; song time/BPM/beat; cached precache/real async/cancel/dispose; native scene example')
 end,debug.traceback)
 if not ok then print('COMPAT CONTROLS FAIL '..err) end
 love.event.quit(ok and 0 or 1)
end
function love.update() end
function love.draw() end
function love.quit() end
function love.errorhandler(err) print(err);return function()return 1 end end
