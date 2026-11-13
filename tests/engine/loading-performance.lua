check('pause music changes schedule and cancel timers without a numeric self',function()
 local manager=Timer.globalManager;Timer.globalManager=TimerManager()
 local saved=ClientPrefs.data.pauseMusic
 ClientPrefs.data.pauseMusic='breakfast'
 local loaded=0
 local pause=setmetatable({parent={onSettingChange=function()end},curPauseMusic='railways',music={fade=function()end}}, {__index=PauseSubstate})
 pause.loadMusic=function(self)loaded=loaded+1;self.curPauseMusic=ClientPrefs.data.pauseMusic end
 pause:onSettingChange('gameplay','pauseMusic')
 assert(pause.activeTimer and pause.activeTimer.active)
 pause:onSettingChange('gameplay','pauseMusic')
 assert(#Timer.globalManager.instances==1)
 pause.music=nil
 Timer.globalManager:update(1);Timer.globalManager:update(0.8)
 assert(loaded==1)
 pause.curPauseMusic='railways';pause:onSettingChange('gameplay','pauseMusic')
 pause._closed=true;Timer.globalManager:update(1)
 assert(loaded==1)
 Timer.globalManager:clear();Timer.globalManager=manager;ClientPrefs.data.pauseMusic=saved
end)
check('atlas font descriptors decode once and per-instance scales stay independent',function()
 paths.contentRevision=(paths.contentRevision or 0)+1
 local original=paths.getJSON;local calls=0
 paths.getJSON=function(key)calls=calls+1;return original(key)end
 local a=AtlasText.getFont('bold',1);local first=calls
 local b=AtlasText.getFont('bold',2)
 paths.getJSON=original
 assert(first==1 and calls==1,'font descriptor decoded repeatedly')
 assert(a~=b and b.scale==a.scale*2 and a.glyphs~=b.glyphs)
 local original=b.offsets[1];a.offsets[1]=999;assert(b.offsets[1]==original)
end)
check('prefix indexes reuse sorted frames without sharing mutable animation lists',function()
 local atlas=paths.getSparrowAtlas('fonts/'..AtlasText.getFont('bold').name)
 assert(type(atlas.getFramesByPrefix)=='function')
 local prefix=atlas.frames[1].name:gsub('%d+$','')
 local a,b=Sprite(),Sprite();a:setFrames(atlas);b:setFrames(atlas)
 a.animation:addByPrefix('one',prefix);b.animation:addByPrefix('two',prefix)
 local first,second=a.animation:get('one'),b.animation:get('two')
 assert(first and second and first.frames~=second.frames and first.frames[1]==second.frames[1])
 local cached=atlas:getFramesByPrefix(prefix)
 assert(cached==atlas:getFramesByPrefix(prefix))
 local n=#cached;atlas:add(cached[1]);assert(#atlas:getFramesByPrefix(prefix)==n+1)
 table.remove(atlas.frames);atlas._prefixFrames=nil
end)
check('all duplicate and distinct scripts still execute with dynamic callbacks',function()
 local path='performance-script.lua'
 assert(love.filesystem.write(path,'function update() calls = (calls or 0) + 1; return Event_Continue end'))
 local handler=ScriptsHandler()
 for i=1,80 do handler:add(Script(path,true,true,true)) end
 for i=1,20 do handler:call('update',0.016);handler:call('missing') end
 for _,script in ipairs(handler.scripts)do assert(script.variables.calls==20)end
 local script=handler.scripts[1];script:set('missing',function()return Script.Event_Cancel end)
 assert(handler:call('missing')==Script.Event_Cancel)
 handler:close();love.filesystem.remove(path)
end)

check('preload batch schedules every distinct resource once',function()
 local async=paths.async
 local image,animate=async.getImage,async.getAnimateAtlas
 local images,atlases=0,0
 async.getImage=function()images=images+1 end
 async.getAnimateAtlas=function()atlases=atlases+1 end
 async.loadBatch({{'image','same'},{'image','same'},{'image','different'},{'animate','rig'},{'animate','rig'}})
 async.getImage,async.getAnimateAtlas=image,animate
 assert(images==2 and atlases==1)
end)
