local Globals = {}

function Globals.initializeState(state)
 state.totalPlayed = 0
 state.totalNotesHit = 0
 state.ratingName = '?'
 state.ratingPercent = nil
 state.ratingFC = nil
end

function Globals.initial(state, chart)
 local values = {
  score = state.score, misses = state.misses, hits = state.songHits, combo = state.combo,
  rating = state.ratingPercent, ratingName = state.ratingName, ratingFC = state.ratingFC,
  totalPlayed = state.totalPlayed, totalNotesHit = state.totalNotesHit,
  scrollSpeed = chart.speed, startedCountdown = false,
  curDecBeat = 0, curDecStep = 0,
  healthGainMult = state.healthGain or 1, healthLossMult = state.healthLoss or 1,
  playbackRate = state.playback or 1, inGameOver = state.isDead == true,
  botPlay = state.playerNotefield and state.playerNotefield.bot or ClientPrefs.data.botplayMode == true,
  practice = state.practiceMode == true, instakillOnMiss = state.instakillOnMiss == true,
  guitarHeroSustains = state.guitarHeroSustains == true
 }
 for _, label in ipairs({'Player', 'Opponent'}) do
  for index = 0, 3 do
   values['default' .. label .. 'StrumX' .. index] = 0
   values['default' .. label .. 'StrumY' .. index] = 0
  end
 end
 return values
end

return Globals
