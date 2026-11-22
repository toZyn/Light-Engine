local function copy(source)
 local result={}
 for key,value in pairs(source) do result[key]=value end
 return result
end

local function atlasFixture()
 local key='synthetic-note-skin'
 love.filesystem.createDirectory('assets/images')
 local image=love.image.newImageData(16,16)
 image:encode('png','assets/images/'..key..'.png');image:release()
 local xml={'<TextureAtlas imagePath="'..key..'.png">'}
 for _,color in ipairs({'purple','blue','green','red'}) do
  xml[#xml+1]='<SubTexture name="'..color..'0" x="0" y="0" width="16" height="16"/>'
 end
 xml[#xml+1]='</TextureAtlas>'
 love.filesystem.write('assets/images/'..key..'.xml',table.concat(xml))
 return key,paths.getSparrowAtlas(key)
end

check('preloaded note atlases do not require a sprite path',function()
 local _,atlas=atlasFixture()
 local base=Skin('default').data
 local skin=copy(base);skin.notes=copy(base.notes)
 skin.notes.sprite=nil;skin.notes.atlas=atlas;skin.notes.animations={{'note','purple0',24,false}}
 skin.psychDisableRgb=true
 local note=Note(1,0,0,'',skin)
 assert(note.direction==0 and note.animation.curAnim)
 note:destroy()
end)

check('failed skin replacement preserves live note direction and previous skin',function()
 local base=Skin('default').data
 local note=Note(1,2,0,'',base)
 local bad=copy(base);bad.notes=copy(base.notes)
 bad.notes.sprite=nil;bad.notes.atlas=nil
 local ok=pcall(note.setSkin,note,bad)
 assert(not ok)
 assert(note.direction==2,'failed replacement cleared direction')
 assert(note.skin==base,'failed replacement committed invalid skin')
 note:destroy()
end)

check('Psych object tags preserve spaces and parentheses through property access',function()
 local state=Group()
 local script={variables={},closed=false,set=function(self,name,value)self.variables[name]=value end,call=function()end}
 local ctx=require('funkin.backend.scripts.compat').new(state,script,true)
 local api=ctx.installed
 api.makeLuaSprite('Upper Bar (Still Strum)',nil,-110,-350)
 api.makeGraphic('Upper Bar (Still Strum)',64,32,'000000')
 api.addLuaSprite('Upper Bar (Still Strum)',false)
 assert(api.getProperty('Upper Bar (Still Strum).y')==-350)
 api.setProperty('Upper Bar (Still Strum).scale.x',.5)
 assert(ctx.objects['Upper Bar (Still Strum)'].scale.x==.5)
 ctx:dispose()
end)

check('Psych object ordering inserts a created sprite before addLuaSprite',function()
 local state=Group();state:add(Sprite())
 local script={variables={},closed=false,set=function(self,k,v)self.variables[k]=v end,call=function()end}
 local ctx=require('funkin.backend.scripts.compat').new(state,script,true)
 local api=ctx.installed
 api.makeLuaSprite('character 1',nil,20,30)
 api.setObjectOrder('character 1',2)
 assert(state.members[#state.members]==ctx.objects['character 1'])
 local count=#state.members;api.addLuaSprite('character 1',true)
 assert(#state.members==count,'addLuaSprite duplicated reordered sprite')
 ctx:dispose()
end)

check('Psych first animation starts and missing prefixes return without aborting script',function()
 local key=atlasFixture()
 local state=Group()
 local script={variables={},closed=false,set=function(self,k,v)self.variables[k]=v end,call=function()end}
 local ctx=require('funkin.backend.scripts.compat').new(state,script,true)
 local api=ctx.installed
 api.makeAnimatedLuaSprite('sprite 1',key)
 assert(api.addAnimationByPrefix('sprite 1','idle','purple',24)==true)
 assert(api.getProperty('sprite 1.animation.curAnim.name')=='idle')
 assert(api.addAnimationByPrefix('sprite 1','missing','absent',24)==true)
 assert(api.getProperty('sprite 1.animation.curAnim.name')=='idle')
 ctx:dispose()
end)
