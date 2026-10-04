-- Native Light Engine entry points explicitly forward to Psych-like callbacks.
local compat = Script.createCompatibility(state, script)
compat.callbackNames.event = 'onCompatEvent'

function onCreate()
 makeLuaSprite('compatPanel', nil, 40, 40)
 makeGraphic('compatPanel', 200, 12, 'E8793E')
 addLuaSprite('compatPanel', true)
 if state.camHUD then setObjectCamera('compatPanel', 'hud') end
 setScrollFactor('compatPanel', 0, 0)
 doTweenX('slide', 'compatPanel', 80, .5, 'quadInOut')
 runTimer('pulse', .5, 0)
end

function onTimerCompleted(tag, elapsedLoops, remainingLoops)
 if tag == 'pulse' then
  doTweenAlpha('pulseAlpha', 'compatPanel', elapsedLoops % 2 == 0 and 1 or .4, .4, 'sineInOut')
 end
end

function onBeatHit()
 setProperty('compatPanel.angle', curBeat % 2 == 0 and 0 or 2)
end

function create() compat:forward('create') end
function postCreate() compat:forward('postCreate') end
function update(dt) compat:update(dt) end
function postUpdate(dt) compat:forward('postUpdate', dt) end
function step(value) compat:forward('step', value) end
function beat(value) compat:forward('beat', value) end
-- Song scripts already use onEvent(event); give the forwarded target a distinct name.
function onCompatEvent(name, value1, value2)
 if name == 'Compat Flash' then setProperty('compatPanel.alpha', 1) end
end
function onEvent(event) compat:forward('event', event) end
function leave() compat:dispose() end
