local originalPaths, originalLove = paths, love
local originalHTTPS, originalFallback = package.loaded.https, package.loaded["lib.https"]
local check = check or function(name, fn)
 local ok, err = pcall(fn)
 if not ok then error(name .. ': ' .. tostring(err)) end
 print('PASS ' .. name)
end
check('statistics and turn timeline', function()
 local Info = require 'funkin.gameplay.information'
 local info = Info.new({{t=1000},{t=2000,l=2000},{t=7000}}, {{t=3000},{t=5000}})
 assert(info:turnText(0,1):find('Player in 1.0s',1,true))
 assert(info:turnText(1,1):find('Player turn',1,true))
 assert(info:turnText(3,1):find('Both playing',1,true))
 assert(info:turnText(4.7,1):find('Opponent in 0.3s',1,true))
 assert(info:turnText(8,1)=='No notes remaining')
 assert(info:turnText(0,2):find('Player in 0.5s',1,true))
 info:hit(0.7, 0.020, false)
 info:hit(1, -0.010, false)
 assert(math.abs(info:accuracy(1)-170/3)<0.001)
 info:tap();info:tap();info:update(0.5)
 assert(info.ips==2 and info.peakIps==2)
 info:update(0.6);assert(info.ips==0)
 local state={score=100,misses=1,combo=2,health=1,sicks=1,goods=1,bads=0,shits=0,playback=1}
 assert(info:format(state,'Simple',0)=='Score: 100')
 local summary=info:format(state,'Informative',0)
 assert(summary:find('Accuracy: 56.67%%') and not summary:find('IPS'))
 local full=info:format(state,'Full',0)
 assert(full:find('Sick: 1',1,true) and full:find('IPS:',1,true) and full:find('Mean offset:',1,true))
end)
local records={}
paths={
 formatToSongPath=function(s)return s:lower():gsub(' ','-')end,
 getPath=function(s)return s end,
 exists=function(s)return records[s]~=nil end,
 getJSON=function(s)return records[s..'.json']end,
 getItems=function(dir)
  local out={}
  for path in pairs(records) do
   local leaf=path:match('^'..dir..'/([^/]+)$')
   if leaf then out[#out+1]=leaf end
  end
  return out
 end
}
check('week discovers common variants and ignores metadata files',function()
 local D=require 'funkin.backend.difficulties'
 records={['songs/one/charts/normal.json']={},['songs/one/charts/insane.json']={},['songs/one/charts/events.json']={},['songs/two/chart.json']={notes={normal={},insane={},hard={}}}}
 local diffs=D.forWeek({songs={'one','two'}},{'Easy','Normal','Hard'})
 assert(table.concat(diffs,',')=='Normal,Insane',table.concat(diffs,','))
 records['songs/two/chart.json']={notes={normal={}}}
 assert(table.concat(D.forWeek({songs={'one','two'}},{}),',')=='Normal')
 records={['songs/one/chart.json']={song={notes={}}},['songs/one/meta.json']={difficulties={'Expert'}}}
 assert(table.concat(D.forWeek({songs={'one'}},{'Normal'}),',')=='Normal,Expert')
 records={['songs/one/chart.json']={song={notes={}}}}
 assert(table.concat(D.forWeek({songs={'one'},difficulties='Normal, Expert'},{}),',')=='Normal,Expert')
end)
check('difficulty colors support mod opt-out and overrides',function()
 local D=require 'funkin.backend.difficulties'
 local white=D.color('insane',{autoDifficultyColor=false})
 assert(white[1]==1 and white[2]==1 and white[3]==1)
 local a,b=D.color('Insane',{}),D.color('insane',{})
 assert(a[1]==b[1] and a[2]==b[2] and a[3]==b[3])
 local override=D.color('expert',{difficultyColors={expert={255,0,64}}})
 assert(override[1]==1 and override[2]==0 and override[3]==64/255)
end)
check('optional avatars skip unavailable HTTPS and finish callbacks',function()
 local calls=0
 package.loaded.https=true
 package.loaded['lib.https']={available=false}
 paths.async={getImage=function()calls=calls+1 end}
 local Icons=require 'funkin.ui.credits.remoteicon'
 local callback=false
 assert(Icons.load('https://example.invalid/avatar.png',function(image,url,err)
  assert(image==nil and url=='https://example.invalid/avatar.png' and err)
  callback=true
 end)==false)
 assert(callback and calls==0)
end)
check('native HTTPS loader executes its initializer',function()
 local loadlib=package.loadlib
 love={system={getOS=function()return 'Linux'end},filesystem={getInfo=function()return true end,getRealDirectory=function()return '/runtime'end}}
 local called=false
 package.loadlib=function(path,symbol)
  assert(path=='/runtime/lib/linux/https.so' and symbol=='luaopen_https')
  return function()called=true;return {request=function()return 200,'body'end}end
 end
 local module=dofile('lib/https.lua')
 package.loadlib=loadlib
 assert(called and type(module.request)=='function')
end)

paths, love = originalPaths, originalLove
package.loaded.https, package.loaded["lib.https"] = originalHTTPS, originalFallback
package.loaded["funkin.ui.credits.remoteicon"] = nil

if originalLove then
 check('bundled Story Mode weeks retain playable difficulties',function()
  local D=require 'funkin.backend.difficulties'
  for _,name in ipairs({'tutorial','week1','week2','week3','week4','week5','week6','week7','weekend1'}) do
   local week=paths.getJSON('data/weeks/weeks/'..name)
   local diffs=D.forWeek(week,{'Easy','Normal','Hard'})
   assert(#diffs>0,name..' has no difficulties')
   print(name..': '..table.concat(diffs,', '))
  end
 end)
 check('Story Mode generates a fitted FNFont label and keeps mod images',function()
  local state=StoryMenuState()
  state.weeksData={{file='test-difficulty',difficulties={'Expert Plus'},locked=false}}
  state.weekList={curSelected=1}
  state.leftArrow={x=0,width=50,y=100}
  state.rightArrow={x=376}
  state.sprDifficulty=Sprite()
  state.txtDifficulty=Text(0,0,'',paths.getFont('vcr.ttf',44))
  StoryMenuState.curDifficulty=1
  state:changeDifficulty()
  assert(state.txtDifficulty.visible and not state.sprDifficulty.visible)
  assert(state.txtDifficulty.font==paths.getFont('difficulty.ttf',44))
  assert(state.txtDifficulty:getWidth()*state.txtDifficulty.scale.x<=280.01)
  state.weeksData[1].difficulties={'Hard'}
  state:changeDifficulty()
  assert(state.sprDifficulty.visible and not state.txtDifficulty.visible)
  assert(state.sprDifficulty.texture==paths.getImage('menus/storymenu/difficulties/hard'))
  Tween.cancelTweensOf(state.txtDifficulty)
  Tween.cancelTweensOf(state.sprDifficulty)
 end)
 check('Gameplay information switches modes on the live HUD',function()
  local state=game.getState()
  if not state or not state.information then
   state=PlayState(false,'bopeebo','normal')
   state:preload()
   paths.async.stop()
   game.switchState(state,true)
   game.update(0)
  end
  local saved=ClientPrefs.data.gameplayInformation
  state.information:hit(1,0.01,false)
  state.sicks,state.score,state.misses=1,350,1
  for _,mode in ipairs({'Simple','Informative','Full'}) do
   ClientPrefs.data.gameplayInformation=mode
   state:onSettingChange('gameplay','gameplayInformation')
   assert(state.scoreText.content:find('Score: 350',1,true))
   assert((state.scoreText.content:find('Accuracy:',1,true)~=nil)==(mode~='Simple'))
   assert(state.informationText.visible==(mode=='Full'))
   assert(state.informationText.cameras[1]==state.camHUD)
   if mode=='Full' then
    assert(state.informationText.content:find('Sick: 1',1,true))
    assert(state.informationText.content:find('IPS:',1,true))
   end
  end
  ClientPrefs.data.gameplayInformation=saved
  state:pauseSong()
 end)
end
