local Scenes=require('funkin.backend.modding.scenes')
check('scene manifests reject duplicate names and malformed assets',function()
 assert(not Scenes.validate({scenes={{name='a',start=0},{name='a',start=1}}}))
 assert(not Scenes.validate({scenes={{name='a',start=0,finish=-1}}}))
 assert(not Scenes.validate({scenes={{name='a',start=0,assets='invalid'}}}))
 assert(Scenes.validate({scenes={{name='a',start=0,assets={{'atlas','characters/bf'}}}}}))
end)
check('scene prefetch retires owned objects and evicts shared textures only after the last scene',function()
 local original=paths.async.getImage
 local callbacks={}
 paths.async.getImage=function(key,callback)callbacks[#callbacks+1]=callback;return true end
 local manager=assert(Scenes.new({scenes={{name='a',start=3,finish=6,assets={{'image','scene-test'}}},{name='b',start=5,finish=8,assets={{'image','scene-test'}}}}}))
 manager:update(0);assert(manager.scenes.a.status=='loading')
 local image=love.graphics.newImage(love.image.newImageData(2,2))
 paths.images['scene-test.png']=image
 callbacks[1](image)
 manager:update(2);assert(manager.scenes.b.status=='ready')
 local destroyed=false
 manager:track('a',{destroy=function()destroyed=true end})
 manager:update(6)
 assert(destroyed and paths.images['scene-test.png']==image)
 manager:update(8)
 assert(paths.images['scene-test.png']==nil)
 assert(image:getWidth()==2,'A texture still held by external objects was released')
 manager:dispose();image:release();paths.async.getImage=original
end)
check('late scene callbacks cannot resurrect a disposed scene',function()
 local original=paths.async.getImage
 local callback
 paths.async.getImage=function(_,cb)callback=cb;return true end
 local manager=assert(Scenes.new({scenes={{name='late',start=0,assets={{'image','late'}}}}}))
 manager:update(0);manager:dispose()
 local image=love.graphics.newImage(love.image.newImageData(2,2));paths.images['late.png']=image
 callback(image)
 assert(manager.scenes.late.status=='released' and paths.images['late.png']==nil)
 image:release();paths.async.getImage=original
end)
check('scripts can read and iterate preferences but cannot save or overwrite them',function()
 local old=ClientPrefs.data.downScroll
 assert(love.filesystem.write('preference-test.lua',[[
 ClientPrefs.data.downScroll=not ClientPrefs.data.downScroll
 ClientPrefs.controls.note_left[1]='key:x'
 local seen=false
 for key in pairs(ClientPrefs.data) do if key=='downScroll' then seen=true end end
 assert(seen)
 assert(ClientPrefs.saveData()==false)
 function readPreference() return ClientPrefs.data.downScroll end
 ]]))
 local bind=ClientPrefs.controls.note_left[1]
 local script=Script('preference-test.lua',true,true,true)
 assert(not script.closed and script.chunk)
 assert(ClientPrefs.data.downScroll==old and ClientPrefs.controls.note_left[1]==bind)
 ClientPrefs.data.downScroll=not old
 assert(script:call('readPreference')==not old)
 script:close();ClientPrefs.data.downScroll=old;love.filesystem.remove('preference-test.lua')
end)
check('prepared shaders validate GLES and are consumed without a gameplay compilation',function()
 local code='vec4 effect(vec4 tint, Image image, vec2 uv, vec2 pixel){return Texel(image,uv)*tint;}'
 local original=love.graphics.newShader;local calls=0
 love.graphics.newShader=function(...)calls=calls+1;return original(...)end
 assert(Shader.prepare({code})[code]);assert(calls==1)
 local shader=Shader(code);assert(shader:get() and calls==1)
 assert(Shader.prepare({code,code})[code] and calls==3)
 local a,b=Shader(code),Shader(code)
 assert(a:get()~=b:get() and calls==3,'Instances share a mutable program or compile during use')
 a:destroy();b:destroy();shader:destroy();love.graphics.newShader=original
 local invalid='uniform float amount; vec4 effect(vec4 c, Image t, vec2 u, vec2 p){if(amount<=0)return c;return Texel(t,u);}'
 assert(Shader.prepare({invalid})[invalid]==false)
 local broken=Shader(invalid);assert(broken:get()==nil)
 local enabled=ClientPrefs.data.shader;ClientPrefs.data.shader=false
 assert(Shader(code):get()==nil);ClientPrefs.data.shader=enabled
end)
check('benchmark exports measured timings and bounded frame percentiles',function()
 local Benchmark=require('funkin.backend.benchmark')
 Benchmark.start({contentId='fixture',preferences={}});Benchmark.loaded()
 for i=1,100 do Benchmark.frame(i==100 and .05 or .016) end
 local result,path=Benchmark.finish()
 assert(result.frames==100 and result.p95Ms==16 and result.maxMs==50)
 assert(result.peakLuaBytes>0 and result.loadMs>=0)
 assert(love.filesystem.getInfo(path,'file'))
 love.filesystem.remove(path)
end)
