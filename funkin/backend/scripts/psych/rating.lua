local Rating = {}

function Rating.recalculate(state)
 local scripts = state.scripts
 local function publish(name, value)
  if scripts then scripts:set(name, value) end
 end
 for _, entry in ipairs({{'score','score'},{'misses','misses'},{'hits','songHits'},{'combo','combo'}}) do
  publish(entry[1], state[entry[2]])
 end
 local stopped = scripts and scripts:call('onRecalculateRating') == Script.Event_Cancel
 if not stopped then
  state.ratingName = '?'
  if state.totalPlayed ~= 0 then
   state.ratingPercent = math.min(1, math.max(0, state.totalNotesHit / state.totalPlayed))
   local ratings = state.ratingStuff
   state.ratingName = ratings[#ratings][1]
   if state.ratingPercent < 1 then
    for index = 1, #ratings - 1 do
     if state.ratingPercent < ratings[index][2] then
      state.ratingName = ratings[index][1]
      break
     end
    end
   end
  end
  state.ratingFC = ''
  local data = state.ratingsData
  if state.misses == 0 then
   if data[3].hits > 0 or data[4].hits > 0 then state.ratingFC = 'FC'
   elseif data[2].hits > 0 then state.ratingFC = 'GFC'
   elseif data[1].hits > 0 then state.ratingFC = 'SFC' end
  elseif state.misses < 10 then state.ratingFC = 'SDCB'
  else state.ratingFC = 'Clear' end
 end
 for _, entry in ipairs({{'rating','ratingPercent'},{'ratingName','ratingName'},{'ratingFC','ratingFC'},
  {'totalPlayed','totalPlayed'},{'totalNotesHit','totalNotesHit'}}) do
  publish(entry[1], state[entry[2]])
 end
end

return Rating
