check('cancelled scripted camera leaves follow and tween intact',function()
 local s=setmetatable({camTarget={},cameraOffset=Point(),camFollow=Point(31,47),
  scripts={event=function(_,_,event) event:cancel();return event end}},PlayState)
 s:cameraMovement(100,200)
 assert(s.camFollow.x==31 and s.camFollow.y==47,'cancelled camera movement changed follow position')
end)
check('destroyed sprites never render from a stale camera queue',function()
 local c=Camera();local sprite=Sprite(0,0,Sprite.defaultTexture)
 c.__renderQueue[1]=sprite;sprite:destroy();c:renderObjects()
 assert(next(c.__renderQueue)==nil,'stale queue not cleared');c:destroy()
end)
check('rotated ActorSprite frame draws without undefined rotation',function()
 local texture=love.graphics.newImage(love.image.newImageData(32,32))
 local frames=Sprite.getFramesFromSparrow(texture,'<TextureAtlas><SubTexture name="test0" x="0" y="0" width="12" height="20" frameWidth="20" frameHeight="12" rotated="true"/></TextureAtlas>')
 local a=ActorSprite(0,0,0);a:setFrames(frames);a.animation:add('test',{0},0,false);a.animation:play('test')
 local canvas=love.graphics.newCanvas(64,64);love.graphics.push('all');love.graphics.setCanvas(canvas);love.graphics.clear();local camera=Camera();local ok,err=pcall(a.__render,a,camera);love.graphics.pop();camera:destroy();assert(ok,err)
 a:destroy();frames:destroy();texture:release();canvas:release()
end)

check('ActorSprite rotated atlas preserves Sprite pixels and frame texture',function()
 local data=love.image.newImageData(32,32)
 for y=0,31 do for x=0,31 do data:setPixel(x,y,(x%3)/2,(y%5)/4,((x+y)%7)/6,1) end end
 local texture=love.graphics.newImage(data);data:release()
 local fallback=love.graphics.newImage(love.image.newImageData(8,8))
 local frames=Sprite.getFramesFromSparrow(texture,'<TextureAtlas><SubTexture name="test0" x="4" y="5" width="12" height="20" frameX="-2" frameY="-3" frameWidth="24" frameHeight="18" rotated="true"/></TextureAtlas>')
 local sprite=Sprite(16,17);sprite:setFrames(frames);sprite.animation:add('test',{0},0,false);sprite.animation:play('test')
 local actor=ActorSprite(16,17,0);actor:setFrames(frames);actor.animation:add('test',{0},0,false);actor.animation:play('test');actor.texture=fallback
 local camera=Camera();local c=love.graphics.newCanvas(80,80)
 local function render(o)
  love.graphics.push('all');love.graphics.setCanvas(c);love.graphics.clear(0,0,0,0);love.graphics.setColor(1,1,1,1)
  local ok,err=pcall(o.__render,o,camera);love.graphics.pop();assert(ok,err)
  return c:newImageData()
 end
 for _,flip in ipairs({{false,false},{true,false},{false,true},{true,true}}) do
  sprite.flipX,sprite.flipY=unpack(flip);actor.flipX,actor.flipY=unpack(flip)
  local a,b=render(sprite),render(actor);local mismatch=0
  for y=0,79 do for x=0,79 do local r,g,bl,al=a:getPixel(x,y);local rr,gg,bb,aa=b:getPixel(x,y)
   if math.abs(r-rr)>1/255 or math.abs(g-gg)>1/255 or math.abs(bl-bb)>1/255 or math.abs(al-aa)>1/255 then mismatch=mismatch+1 end
  end end
  a:release();b:release();assert(mismatch==0,'rotated frame pixels differ: '..mismatch)
 end
 sprite:destroy();actor:destroy();frames:destroy();camera:destroy();texture:release();fallback:release();c:release()
end)
