-- Run as main.lua of an isolated LÖVE test directory. ENGINE_ROOT names the checkout.
--
-- Psych's globals are written once, when a script is created. Everything that
-- moves during a song -- the playhead, the score, the section flags -- used to
-- stay at those opening values. A mod doing arithmetic on curDecStep raised
-- "attempt to perform arithmetic on a nil value" in its own onStepHit, and the
-- engine had nothing to say about why.
--
-- This drives a real PlayState rather than a hand-built table, because the bug
-- lived in the hand-off between the state and the script: both sides were fine on
-- their own.
local root = os.getenv('ENGINE_ROOT') or '/workspace/Light-Engine-advanced'
package.path = root .. '/?.lua;' .. root .. '/?/init.lua;' .. package.path

function love.load()
 local ok,err=xpcall(function()
  local state=PlayState(false,'bopeebo','normal')
  state:preload()
  require('funkin.backend.paths').async.stop()
  game.switchState(state,true)
  game.update(0)
  local conductor=state.conductor
  assert(conductor,'no conductor')

  -- A script with a compatibility context, the way a Psych mod gets one.
  local script=Script('tests/engine/compat-fixture.lua',false,true,true)
  state.scripts:add(script)
  local ctx=script._psych
  assert(ctx,'script has no compatibility context')

  -- 1. Booleans for "the values exist at all". Before the refresh these were
  --    present but frozen, which is silent; a nil return here would at least have
  --    pointed at the engine.
  local vars=state.psychVariables
  local before={curDecStep=vars.curDecStep,curDecBeat=vars.curDecBeat}

  -- 2. Advancing the conductor must move the values the mod reads.
  local step=conductor.step
  local original=step.f
  step.f=original+7
  conductor.beat.f=conductor.beat.f+1
  ctx:update(0)
  assert(vars.curDecStep~=nil,'curDecStep is nil after a frame')
  assert(vars.curDecStep==step.f,
    ('curDecStep did not follow the conductor: %s vs %s'):format(tostring(vars.curDecStep),tostring(step.f)))
  assert(vars.curDecBeat==conductor.beat.f,'curDecBeat did not follow the conductor')
  assert(vars.curDecStep~=before.curDecStep,'curDecStep did not change')

  -- 3. The same holds through getProperty, which is how Psych scripts read it.
  --    The compatibility functions are installed on the script's own variables,
  --    so that is where a mod finds them.
  local getProperty=script.variables.getProperty
  assert(type(getProperty)=='function','getProperty was not installed on the script')
  assert(getProperty('curDecStep')==step.f,'getProperty(curDecStep) disagrees with the variable')
  step.f=original

  -- 4. Score/misses/rating change per note; they were computed and then published
  --    only to Script:set, where getProperty cannot see them.
  state.score,state.misses,state.songHits,state.combo=1234,3,45,7
  state.ratingPercent,state.ratingName,state.ratingFC=91.5,'Sick!','FC'
  ctx:update(0)
  assert(vars.score==1234,'score variable did not follow the state')
  assert(vars.misses==3,'misses variable did not follow the state')
  assert(getProperty('score')==1234,'getProperty(score) did not follow the state')
  assert(getProperty('rating')==91.5,'getProperty(rating) did not follow the state')
  assert(getProperty('ratingName')=='Sick!','getProperty(ratingName) stale')
  assert(getProperty('ratingFC')=='FC','getProperty(ratingFC) stale')

  -- 5. Section flags belong to a section, so they change when the section does,
  --    not every frame. A mod that sets altAnim expects it to hold.
  local sections=state.psychSections
  assert(sections and #sections>1,'fixture needs more than one section')
  state.psychSectionIndex=2
  sections[2].mustHitSection=true
  sections[2].altAnim=true
  ctx:forward('section')
  assert(vars.mustHitSection==true,'mustHitSection did not follow the section')
  assert(vars.altAnim==true,'altAnim did not follow the section')
  assert(vars.curSection==1,'curSection must be 0-based like Psych, got '..tostring(vars.curSection))
  assert(vars.gfSection==(sections[2].gfSection==true),'gfSection did not follow the section')

  -- 6. A section that turns the flags off must turn them off here too: a refresh
  --    that only ever sets true is worse than none.
  state.psychSectionIndex=1
  sections[1].mustHitSection=false
  sections[1].altAnim=false
  ctx:forward('section')
  assert(vars.mustHitSection==false and vars.altAnim==false,'section flags did not clear')

  -- 7. The refresh must never take the song down, even if a mod broke the state.
  state.conductor=nil
  local survived=pcall(function() ctx:update(0) end)
  assert(survived,'a frame refresh raised with no conductor')

  script:close()
 end,debug.traceback)
 if not ok then print(err) love.event.quit(1) return end
 print('PSYCH GLOBALS REFRESH PASSED:')
 love.event.quit(0)
end
