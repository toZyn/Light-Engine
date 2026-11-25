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
check('variant file info can omit size and modification time', function()
 local savedLove = love
 love = {filesystem = {getInfo = function() return {type = 'file'} end}}
 records = {['songs/one/charts/expert.json'] = {}}
 local ok, result = pcall(require('funkin.backend.difficulties').forSong, 'one')
 love = savedLove
 assert(ok and #result == 1 and result[1] == 'Expert', tostring(result))
end)
check('Psych layout resolves only for the active mod with compatibility enabled', function()
 local savedLove, savedMods, savedPrefs = love, Mods, ClientPrefs
 local root = 'mods/fixture/'
 local dir = root .. 'data/hello'
 love = {filesystem = {
  getDirectoryItems = function(path)
   if path == root .. 'data' then return {'hello'} end
   if path == dir or path == dir .. '/' then return {'hello.json', 'hello-hard.json', 'events.json'} end
   return {}
  end,
  getInfo = function(path)
   if path == dir .. '/hello.json' or path == dir .. '/hello-hard.json' then return {type = 'file'} end
  end
 }}
 Mods = {root = 'mods', currentMod = 'fixture'}
 ClientPrefs = {data = {engineCompatibility = false}}
 local Psych = require 'funkin.backend.modding.psych'
 local disabled = Psych.chart('hello', 'normal')
 ClientPrefs.data.engineCompatibility = true
 local key, file = Psych.chart('hello', 'normal')
 local variants = Psych.difficulties('hello')
 local alias = Psych.alias('songs/hello/events.json')
 love, Mods, ClientPrefs = savedLove, savedMods, savedPrefs
 assert(disabled == nil and native == nil and key == 'data/hello/hello' and file == dir .. '/hello.json')
 assert(table.concat(variants, ',') == 'Normal,hard' and alias == 'data/hello/events.json')
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
   assert(state.informationText.cameras[1]==state.camOther)
   if mode=='Full' then
    assert(state.informationText.content:find('Sick: 1',1,true))
    assert(state.informationText.content:find('IPS:',1,true))
   end
  end
  ClientPrefs.data.gameplayInformation=saved
  state:pauseSong()
 end)
end

if originalLove then
 check('Story Mode loads no song charts before selecting a week',function()
  local state=StoryMenuState();state.weeksData={}
  local calls=0;local original=paths.getJSON
  paths.getJSON=function(key)
   if key:find('songs/',1,true)==1 then calls=calls+1 end
   return original(key)
  end
  state:loadWeeks();paths.getJSON=original
  assert(#state.weeksData>0 and calls==0,'menu eagerly decoded '..calls..' song charts')
 end)
 check('difficulty indexes reuse decoding and invalidate safely',function()
  local D=require 'funkin.backend.difficulties'
  D.clearCache()
  local calls=0;local original=paths.getJSON
  paths.getJSON=function(key)calls=calls+1;return original(key)end
  local first=D.forSong('bopeebo',{'Easy','Normal','Hard'})
  calls=0
  local second=D.forSong('bopeebo',{'Easy','Normal','Hard'})
  local cached=calls;paths.getJSON=original
  assert(table.concat(first,',')==table.concat(second,',') and cached==0)
  D.clearCache();calls=0
  paths.getJSON=function(key)calls=calls+1;return original(key)end
  D.forSong('bopeebo',{'Easy','Normal','Hard'});paths.getJSON=original
  assert(calls>0,'reload reused a stale index')
 end)
 check('Full HUD docks beside health bar outside the receptor edge',function()
  local state=PlayState(false,'bopeebo','normal')
  state:preload();paths.async.stop();game.switchState(state,true);game.update(0)
  local saved=ClientPrefs.data.gameplayInformation
  ClientPrefs.data.gameplayInformation='Full'
  for _,downscroll in ipairs({false,true}) do
   state.downScroll=downscroll;state.healthBar.y=game.height*(downscroll and 0.1 or 0.9)
   state:positionText();state:updateInformation()
   local panel=assert(state.informationBackground)
   assert(table.find(state.members,panel)<table.find(state.members,state.scoreText),'backdrop covers score')
   assert(panel.visible and panel.x>=0 and panel.x+panel.width<=game.width)
   assert(panel.y>=0 and panel.y+panel.height<=game.height)
   assert(downscroll and panel.y>=state.healthBar.y or not downscroll and panel.y+panel.height<=state.healthBar.y)
   assert(state.informationText.cameras[1]==state.camOther)
  end
  ClientPrefs.data.gameplayInformation='Simple';state:updateInformation()
  assert(not state.informationBackground.visible and not state.informationText.visible)
  ClientPrefs.data.gameplayInformation=saved;state:pauseSong()
 end)
end

check('rolling inputs remain bounded and unsorted notes remain intact',function()
 local Info=require 'funkin.gameplay.information'
 local notes={{t=3000,l=2000},{t=1000},{t=2000}}
 local info=Info.new(notes,{{t=4000}})
 assert(notes[1].t==3000 and notes[2].t==1000)
 assert(info:turnText(4,1)=='Both playing')
 for i=1,10000 do info:update(0.01);info:tap() end
 assert(info.ips>=99 and info.ips<=101 and #info.taps<=256)
 info:update(2);assert(info.ips==0)
end)

if originalLove then
 check('Psych chart layout and scoped Lua callbacks work through the engine', function()
  local root, name, song = Mods.root, Mods.currentMod, 'compat-layout-fixture'
  local enabled = ClientPrefs.data.engineCompatibility
  local dir = 'fixture-mods/psych/data/' .. song
  assert(love.filesystem.createDirectory(dir))
  assert(love.filesystem.createDirectory('fixture-mods/psych/shaders'))
  assert(love.filesystem.write('fixture-mods/psych/shaders/tint.frag', [[
#pragma header
uniform float amount;
void main() {
 vec4 pixel = flixel_texture2D(bitmap, openfl_TextureCoordv);
 gl_FragColor = vec4(pixel.rgb * amount, pixel.a);
}
]]))
  assert(love.filesystem.write('fixture-mods/psych/shaders/tint.vert', [[
#pragma header
void main() {
 #pragma body
}
]]))
  assert(love.filesystem.write(dir .. '/' .. song .. '-hard.json',
   '{"song":{"song":"compat-layout-fixture","bpm":100,"speed":1,"notes":[{"mustHitSection":true,"sectionNotes":[[250,0,0]]}]}}'))
  assert(love.filesystem.write(dir .. '/events.json', '{"events":[[300,[["Test","one","two"]]]]}'))
  assert(love.filesystem.write(dir .. '/dialogue.json', '{"dialogue":[{"text":"Hola, café"}]}'))
  assert(love.filesystem.createDirectory('fixture-mods/psych/videos'))
  assert(love.filesystem.write('fixture-mods/psych/videos/mp4-only.mp4', 'fixture'))
  assert(love.filesystem.write('fixture-mods/psych/videos/corrupt.ogv', 'fixture'))
  assert(love.filesystem.createDirectory('fixture-mods/psych/extra'))
  assert(love.filesystem.write('fixture-mods/psych/extra/helper.lua', [[
function onCreate() loads = (loads or 0) + 1 end
function sum(a, b) return a + b end
]]))
  assert(love.filesystem.write(dir .. '/accompany.lua', [[
function onCreate()
 assert(type(makeLuaSprite) == "function")
 created = true
 haxeNumber = runHaxeCode('function addTo(value:Int) { return value + base; } return addTo(2);', {base=40})
 haxeNext = runHaxeFunction('addTo', {3})
 haxeImportBlocked = not pcall(runHaxeCode, 'import sys.FileSystem; return FileSystem.exists(".");')
 haxeBudgetStopped = not pcall(runHaxeCode, 'while (true) {}')
 makeLuaSprite('shaderTarget', '', 0, 0)
 makeGraphic('shaderTarget', 8, 8, 'FFFFFF')
 initLuaShader('tint')
 assert(setSpriteShader('shaderTarget', 'tint'))
 setShaderFloat('shaderTarget', 'amount', 0.5)
end
function onEvent(name, a, b)
 lastEvent = name .. ":" .. a .. ":" .. b
 local x = getPropertyFromGroup('playerStrums', 0, 'x')
 noteTweenX('receptor', 4, x + 20, 0.25, 'linear')
end
function onEventPushed(name, a, b, time)
 pushedTime = time
end
function eventEarlyTrigger(name, a, b, time)
 if name == 'Test' then return 40 end
end
function onCountdownTick(counter)
 countdownCounter = counter
end
function onNextDialogue(line)
 dialogueLine = line
end
function onSkipDialogue(line)
 dialogueSkipped = line
end
function goodNoteHitPre(index)
 setPropertyFromGroup('notes', index, 'noAnimation', true)
 return Function_Stop
end
function onCustomSubstateCreate(name)
 assert(insertToCustomSubstate('shaderTarget'))
 customOpened = name
end
function onCustomSubstateUpdate(name, dt)
 customTime = dt
end
function onCustomSubstateDestroy(name)
 customClosed = name
end
]]))
  assert(love.filesystem.write(dir .. '/effect.hx', [[
import flixel.FlxG;
import states.PlayState;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.filters.ShaderFilter;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
var tile:FlxSprite;
function onCreate() {
 tile = new FlxSprite(24, 16).makeGraphic(10, 12, 0xFF00FF);
 game.add(tile);
 var camera = new FlxCamera(0, 0, 16, 16);
 camera.bgColor = 0;
 FlxG.cameras.add(camera, false);
 tile.cameras = [camera];
 var pos = new FlxPoint(1, 2).add(3, 4);
 setVar("point", FlxMath.bound(pos.x, 0, 3));
 var label = new FlxText(10, 20, 128, "HScript", 24);
 var group = new FlxTypedGroup();
 game.add(group);
 group.add(label);
 group.forEach(function(member) { member.x += 1; });
 setVar("groupSize", group.members.length);
 FlxG.camera.zoom = 1.25;
 var first = game.createRuntimeShader("tint");
 var second = game.createRuntimeShader("tint");
 first.setFloat("amount", 0.5);
 second.setFloat("amount", 0.5);
 game.camOther.setFilters([new ShaderFilter(first), new ShaderFilter(second)]);
 game.health = 1.2;
 PlayState.SONG.arrowSkin = "note-style";
 addMisses(2);
 setVar("hscriptArrowSkin", PlayState.SONG.arrowSkin);
 setVar("hscriptMisses", getMisses());
 var timer = new FlxTimer();
 timer.start(0.1, function(t) { setVar("timerLoops", t.elapsedLoops); }, 2);
}
function onEvent(name:String, a:String, b:String) {
 FlxG.camera.zoom = name == "Test" ? 1.5 : 1;
 tile.x += 8;
 setVar("compatBeat", curBeat);
 FlxTween.tween(tile, {x: 56}, 0.25, {ease: FlxEase.linear, onComplete: function(t) {
  setVar("tweenFinished", t.finished);
 }});
}
]]))
  Mods.root, Mods.currentMod = 'fixture-mods', 'psych'
  ClientPrefs.data.engineCompatibility = true
  Parser.clearCache(false)
  local ok, err = xpcall(function()
   local chart = assert(Parser.getChart(song, 'Hard', {strict = true}))
   assert(chart.notes.player[1].t == 250)
   local event = chart.events[#chart.events]
   assert(event.t == 300 and event.e == 'Test')
   local scripts, state = ScriptsHandler(), State()
   state.scripts = scripts
   state.camOther = Camera(0, 0, 8, 8)
   state.camOther:resize(8, 8, 1, 1, true)
   state.playerNotefield = Notefield(0, 0, 4, "default")
   state.enemyNotefield = Notefield(0, 0, 4, "default")
   local player = state.playerNotefield
   local note = player:addNote(Note(0.25, 0, 0, nil, player.skin))
   state:add(player)
   state:add(state.enemyNotefield)
   game.switchState(state, true)
   game.update(0)
   require('funkin.backend.modding.psych').loadScripts(state, scripts, song, chart)
   assert(#scripts.scripts == 2 and scripts.scripts[1]._psych and scripts.scripts[2]._psych)
   state.health = 1
   local zoom = game.camera.zoom
   local members = #state.members
   scripts:call('create')
   assert(#state.members == members + 2)
   assert(state.members[members + 1].x == 24 and state.members[members + 2].members[1].content == 'HScript')
   local customCam = state.members[members + 1].cameras[1]
   assert(table.find(game.cameras.list, customCam) and customCam.bgColor[4] == 0)
   assert(game.camera.zoom == 1.25 and state.psychVariables.groupSize == 1 and state.psychVariables.point == 3)
   assert(state.psychVariables.hscriptArrowSkin == 'note-style' and state.psychVariables.hscriptMisses == 2)
   assert(state.members[members + 2].members[1].x == 11)
   scripts:set('curBeat', 18)
   local x = player.receptors[1].x
   assert(scripts:preparePsychEvent(event) and event.t == 260)
   state.countdown = {data = {true}, doCountdown = function() end}
   PlayState.doCountdown(state, 1)
   scripts:call('onEvent', event)
   assert(game.camera.zoom == 1.5 and state.members[members + 1].x == 32)
   game.camera.zoom = zoom
   local vars = scripts.scripts[1].variables
   print('PROBE created=' .. tostring(vars.created) .. ' lastEvent=' .. tostring(vars.lastEvent)
    .. ' psych=' .. tostring(scripts.scripts[1].psychScript ~= nil)
    .. ' err=' .. tostring(scripts.scripts[1].psychError)
    .. ' nscripts=' .. tostring(#scripts.scripts))
   assert(vars.created and vars.lastEvent == 'Test:one:two')
   assert(vars.pushedTime == 300 and vars.countdownCounter == 0)
   assert(vars.addLuaScript('extra/helper'))
   assert(vars.isRunning('extra/helper.lua'))
   assert(vars.callScript('extra/helper', 'sum', {4, 5}) == 9)
   assert(vars.getGlobalFromScript('extra/helper', 'loads') == 1)
   assert(not vars.addLuaScript('extra/helper.lua'))
   assert(vars.removeLuaScript('extra/helper'))
   assert(not vars.isRunning('extra/helper'))
   local object = scripts.scripts[1]._psych.objects.shaderTarget
   local canvas = love.graphics.newCanvas(8, 8)
   love.graphics.push('all')
   love.graphics.setCanvas(canvas)
   love.graphics.clear()
   love.graphics.setShader(object.shader)
   love.graphics.draw(object.texture)
   love.graphics.pop()
   local data = canvas:newImageData()
   local red, green, blue, alpha = data:getPixel(4, 4)
   assert(math.abs(red - 0.5) < 0.01 and green == red and blue == red and alpha == 1)
   data:release()
   love.graphics.push('all')
   love.graphics.setCanvas(state.camOther.canvas)
   love.graphics.clear(1, 1, 1, 1)
   love.graphics.setCanvas(canvas)
   love.graphics.clear()
   assert(state.camOther:drawCanvasToTarget(game.width, game.height))
   love.graphics.pop()
   local filtered = canvas:newImageData()
   assert(math.abs(filtered:getPixel(4, 4) - 0.25) < 0.01)
   filtered:release()
   canvas:release()
   assert(vars.haxeNumber == 42 and vars.haxeNext == 43 and vars.haxeBudgetStopped and vars.haxeImportBlocked)
   assert(state.psychVariables.compatBeat == 18 and state.health == 1.2)
   scripts:call('update', 0.125)
   assert(state.psychVariables.timerLoops == 1 and state.members[members + 1].x == 44)
   scripts:call('update', 0.125)
   assert(state.psychVariables.timerLoops == 2 and state.members[members + 1].x == 56)
   assert(state.psychVariables.tweenFinished and player.receptors[1].x == x + 20)
   local hit = scripts:event('onNoteHit', Events.NoteHit(player, note))
   assert(hit.cancelled and note.noAnimation)
   assert(vars.openCustomSubstate('overlay'))
   assert(vars.customOpened == 'overlay' and state.substate.members[1] == object)
   state.substate:update(0.125)
   assert(vars.customTime == 0.125)
   assert(vars.closeCustomSubstate() and vars.customClosed == 'overlay' and not state.substate)
   local originalSong = PlayState.SONG
   PlayState.SONG = chart
   local opened = vars.startDialogue('dialogue')
   PlayState.SONG = originalSong
   assert(opened and vars.dialogueLine == 1 and state.psychCutscene)
   state.psychCutscene:update(0)
   controls:onKeyPress('return')
   controls:onKeyRelease('return')
   controls:update()
   state.psychCutscene:update(0)
   assert(vars.dialogueSkipped == 1)
   controls:update()
   controls:onKeyPress('return')
   controls:onKeyRelease('return')
   controls:update()
   state.psychCutscene:update(0)
   controls:update()
   assert(not state.psychCutscene)
   assert(not vars.startVideo('mp4-only'))
   assert(not vars.startVideo('corrupt'))
   assert(not state.videoCutscene and not state.psychCutscene)
   assert(vars.startVideo('ughCutscene', false, true, true, false))
   local video = state.videoCutscene
   assert(video.video and video.looped and not video.video:isPlaying())
   assert(not state.psychCutscene)
   video:play()
   assert(video.video:isPlaying())
   video.onComplete()
   assert(not state.videoCutscene and not state.psychCutscene)
   assert(vars.startVideo('ughCutscene'))
   assert(state.psychCutscene.video)
   scripts:close()
   assert(not state.psychCutscene)
   assert(not state.camOther.shader and not state.camOther.psychFilterBuffers)
   assert(not table.find(game.cameras.list, customCam))
   state.camOther:destroy()
   assert(#state.members == members)
  end, debug.traceback)
  Mods.root, Mods.currentMod = root, name
  ClientPrefs.data.engineCompatibility = enabled
  Parser.clearCache(false)
  assert(ok, err)
 end)
end
