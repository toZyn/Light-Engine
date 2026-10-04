check('native gameplay survives repeated slow frames without music rewind',function()
 ClientPrefs.data.botplayMode=true;ClientPrefs.data.autoPause=false
 local state=PlayState(false,'bopeebo','normal');state:preload();paths.async.stop()
 game.switchState(state,true);game.update(0)
 assert(game.getState()==state,'native PlayState did not enter')
 state.startingSong=false;state.startedCountdown=true;state.skipResync=false;state:playSong(1)
 local seeks,callbacks=0,0;local playSong=state.playSong
 state.playSong=function(self,...) seeks=seeks+1;return playSong(self,...) end
 local timer=Timer(state.timer);timer:start(0.01,function() callbacks=callbacks+1 end)
 for i=1,4 do state:update(0.1) end
 assert(seeks==0,'slow frame restarted/rewound music '..seeks..' times')
 assert(callbacks==1,'slow frames starved gameplay timers')
 assert(game.sound.music.time>=0.99,'music rewound on a slow frame')
 assert(state.playerNotefield and #state.playerNotefield.lanes==4,'native note lanes lost')
 state:pauseSong()
end)
