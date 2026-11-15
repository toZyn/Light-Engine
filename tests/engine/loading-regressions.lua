local Screen=require 'funkin.ui.loadscreen'
local Job=require 'funkin.backend.scenejob'

check('loading work waits for a drawn frame and advances once per draw',function()
 local calls=0
 local view=Screen({preload=function()
  calls=calls+1;Job.checkpoint('first')
  calls=calls+1;Job.checkpoint('second')
  calls=calls+1
 end})
 view:update(0.016)
 assert(calls==0,'preload ran before the first loading frame')
 view:draw();view:update(0.016);assert(calls==1)
 for _=1,10 do view:update(0.001) end
 assert(calls==1,'multiple preparation steps ran before the next rendered frame')
 view:draw();view:update(0.016);assert(calls==2)
 view:draw();view:update(0.016);assert(calls==3)
 view:destroy()
end)

check('handoff retains the loading view until the actual state switch and skips a second transition',function()
 local owner=State()
 local target=PlayState(false,'bopeebo','normal')
 local view=Screen(target);owner:add(view)
 view:handoff(owner)
 assert(table.find(owner.members,view),'handoff removed the view before switching states')
 assert(target._loadingView==view and target.skipTransIn,'handoff will expose another fade or gameplay frame')
 owner:remove(view);view:destroy()
end)

check('noncentered receptors fit both sides even with mobile middlescroll spacing saved',function()
 local saved=table.clone(ClientPrefs.data)
 ClientPrefs.data.middleScroll=false;ClientPrefs.data.downScroll=false
 ClientPrefs.data.splitReceptors=true;ClientPrefs.data.splitWidth=900;ClientPrefs.data.noteWidth=190
 local state=PlayState(false,'bopeebo','normal');state:preload();paths.async.stop()
 game.switchState(state,true);game.update(0)
 local field=state.playerNotefield
 assert(field.x+field.width<=game.width,'mobile middlescroll spacing pushes player receptors off screen')
 assert(field.width==448,'noncentered layout must use the native two-sided spacing')
 ClientPrefs.data.middleScroll=true;state:onSettingChange('gameplay','middleScroll')
 assert(state.playerNotefield.width==900 and state.middleScroll)
 ClientPrefs.data.downScroll=true;state:onSettingChange('gameplay','downScroll')
 assert(state.playerNotefield.downscroll and state.downScroll)
 ClientPrefs.data=saved
 game.switchState(FreeplayState(),true);game.update(0)
end)

check('explicit mod layout requirements survive postCreate without altering user preferences',function()
 local saved=table.clone(ClientPrefs.data)
 local root,mod=Mods.root,Mods.currentMod
 Mods.root='loading-regression-mods';Mods.currentMod='required-layout'
 local directory=Mods.root..'/'..Mods.currentMod..'/data/scripts'
 assert(love.filesystem.createDirectory(directory))
 assert(love.filesystem.write(directory..'/layout.lua',[[
function postCreate()
 state.middleScroll=true
 state.downScroll=true
 state:positionNotefields()
 state.playerNotefield.x=137
 state.playerNotefield.downscroll=true
 state.playerNotefield.canSpawnSplash=false
end
]]))
 ClientPrefs.data.middleScroll=false;ClientPrefs.data.downScroll=false
 local state=PlayState(false,'bopeebo','normal');state:preload();paths.async.stop()
 game.switchState(state,true);game.update(0)
 assert(state.middleScroll and state.downScroll and state.playerNotefield.x==137,'engine overwrote the mod requirement')
 assert(state.playerNotefield.downscroll and not state.playerNotefield.canSpawnSplash)
 assert(not ClientPrefs.data.middleScroll and not ClientPrefs.data.downScroll,'mod requirements changed saved user preferences')
 Mods.root,Mods.currentMod=root,mod;ClientPrefs.data=saved
 game.switchState(FreeplayState(),true);game.update(0)
end)

check('Zyn credits use the requested description and YouTube handle',function()
 local zyn=CreditsState.defaultData[1].credits[1]
 assert(zyn.description=='Independent Light Engine developer, teenager, and current owner of Light Engine\n\nGreetings! - Zyn')
 local youtube
 for _,social in ipairs(zyn.social) do if social.name:lower()=='youtube' then youtube=social.text end end
 assert(youtube=='@Chatger')
end)

check('loading state transfers live artwork across teardown and presents readiness before gameplay',function()
 local target=PlayState(false,'bopeebo','normal')
 local owner=LoadState(target)
 game.switchState(owner,true);game.update(0)
 local view=owner.load
 local deadline=love.timer.getTime()+10
 while not owner._loaded do
  assert(love.timer.getTime()<deadline,'loading-state preparation stalled')
  owner:draw();paths.update(0.016);game.update(0.016)
  love.timer.sleep(0.001)
 end
 assert(table.find(owner.members,view),'outgoing loading frame was detached')
 game.update(0)
 assert(game.getState()==target and target._loadingView==view and view.exists)
 assert(view.camera==target._loadingCamera and table.find(game.cameras.list,view.camera))
 assert(view.art.texture:getWidth()>0 and target.skipTransIn)
 local frames=0
 while target._prepareJob and not target._prepareJob.done do
  target:draw();game.update(0.016);frames=frames+1
  assert(frames<300,'incremental scene did not finish')
 end
 assert(target._loadingView==view and view.progress==1,'ready view disappeared before being drawn')
 target:playSong(0.5)
 assert(target._pendingSongStart and not game.sound.music:isPlaying(),'audio started under loading artwork')
 for _=1,5 do game.update(0.001) end
 assert(target._prepareJob,'ready view must remain until its frame is drawn')
 target:draw();game.update(0.016)
 assert(target._prepareJob and view.exiting,"ready view skipped its exit transition")
 for _=1,30 do target:draw();game.update(0.016) end
 assert(not target._prepareJob and not target._loadingView)
 assert(not target._pendingSongStart and game.sound.music:isPlaying(),'deferred audio did not start after the fade')
 game.switchState(FreeplayState(),true);game.update(0)
end)

check('pause restart retains its loading view across parent and substate teardown',function()
 local state=PlayState(false,'bopeebo','normal');state:preload();paths.async.stop()
 game.switchState(state,true);game.update(0)
 local pause=PauseSubstate();state:openSubstate(pause);pause:resetState()
 local view=pause.load
 assert(view.camera and view.cameras[1]==view.camera)
 local deadline=love.timer.getTime()+10
 while game.getState()==state do
  assert(love.timer.getTime()<deadline,'pause restart stalled')
  pause:draw();paths.update(0.016);game.update(0.016);love.timer.sleep(0.001)
 end
 local target=game.getState()
 assert(target._loadingView==view and view.exists and view.art.texture:getWidth()>0)
 local n=0
 while target._prepareJob do
  target:draw();game.update(0.016);n=n+1;assert(n<300)
 end
 assert(not target._loadingView)
 game.switchState(FreeplayState(),true);game.update(0)
end)

check('loading transitions retain intermediate opacity and wait for the final drawn frame',function()
 local view=Screen()
 assert(view.camera.alpha==0)
 view:update(0.11)
 assert(view.camera.alpha>0 and view.camera.alpha<1)
 view:update(0.11)
 assert(view.camera.alpha==1)
 view:beginExit();view:update(0.15)
 assert(view.camera.alpha>0 and view.camera.alpha<1)
 assert(not view:isExitComplete())
 view:update(0.15)
 assert(view.camera.alpha==0 and not view:isExitComplete())
 view:draw();assert(view:isExitComplete())
 view:destroy()
end)

check('note graphics preparation warms all directions without spawning chart notes or callbacks',function()
 local field=Notefield(0,0,4,'default')
 local callbacks=0
 field.state={scripts={call=function() callbacks=callbacks+1 end}}
 field:makeNotesFromChart({{t=0,d=0,l=0},{t=100,d=1,l=100}})
 local job=Job.new(function() field:prepareGraphics(game.camera) end)
 local steps=0
 while not job.done do job:step();steps=steps+1 end
 assert(steps==5 and callbacks==0)
 assert(#field.activeNotes==0 and field.chartIndex==1 and #field.chartNotes==2)
 for _,lane in ipairs(field.lanes) do assert(#lane.members==1 and lane.members[1]==lane.receptor) end
 field:destroy()
end)

check('prepared note colors reuse palettes and observe live palette edits',function()
 local skin=paths.getSkin('default').data
 local first=Note(0,0,0,nil,skin)
 local original=Color.fromString
 local conversions=0
 Color.fromString=function(...) conversions=conversions+1;return original(...) end
 local second=Note(0,0,0,nil,skin)
 Color.fromString=original
 assert(conversions==0 and first.shader==second.shader)
 local color=skin.notes.colors[1]
 local saved=color[1]
 color[1]='#112233'
 local changed=Note(0,0,0,nil,skin)
 color[1]=saved
 assert(changed.shader~=first.shader,'prepared palette ignored a live color change')
 first:destroy();second:destroy();changed:destroy()
end)
