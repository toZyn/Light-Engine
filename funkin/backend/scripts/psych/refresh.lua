-- Keeps the Psych globals a script reads in step with the song.
--
-- `globals.initial` writes these values once, when the script is created. That is
-- enough for anything constant, but most of Psych's surface is not: curDecStep and
-- curDecBeat advance every frame, and score/misses/rating change every note. A mod
-- that does `curDecStep * 4` in onStepHit got
--
--   attempt to perform arithmetic on a nil value
--
-- not because the value was missing but because it was written once and never
-- again. The engine reported the symptom in the mod's own line and nothing else.
--
-- Only values that actually move are handled here. Constants are left to
-- `globals.initial`, so this cannot drift into a second source of truth for
-- values that never change.

local Refresh = {}

local function section(state)
	local sections = state.psychSections
	if not sections then return nil end
	local index = state.psychSectionIndex or 1
	return sections[index]
end

--- Writes the values that change per frame.
--
-- Called from Compat:update, i.e. once per frame per script, so it stays to a
-- handful of field writes. Conductor is nil before a song starts in some states.
function Refresh.frame(compat)
	if compat.disposed then return end
	local state = compat.state
	if state == nil then return end
	local value = compat.state.psychVariables
	if value == nil then return end
	local script = compat.script
	if script == nil then return end

	local conductor = state.conductor
	local function publish(key, current)
		value[key] = current
		-- Psych's scripts read these both as variables and through
		-- `Script:set`, and getProperty resolves the latter. Writing both keeps
		-- `curDecStep` and `getProperty("curDecStep")` from disagreeing.
		if script.set then script:set(key, current) end
	end

	if conductor then
		publish("curDecStep", conductor.step and conductor.step.f or 0)
		publish("curDecBeat", conductor.beat and conductor.beat.f or 0)
		-- The integer forms are published by the engine's own step/beat signals,
		-- but only when a step actually fires. A pause or a seek leaves them
		-- stale, and a script reading them in onUpdate would not notice.
		publish("curStep", conductor.step and conductor.step.i or 0)
		publish("curBeat", conductor.beat and conductor.beat.i or 0)
	end

	publish("health", state.health or 0)
	publish("score", state.score or 0)
	publish("misses", state.misses or 0)
	publish("hits", state.songHits or 0)
	publish("combo", state.combo or 0)
	publish("rating", state.ratingPercent or 0)
	publish("ratingName", state.ratingName or "?")
	publish("ratingFC", state.ratingFC or "")
	publish("totalPlayed", state.totalPlayed or 0)
	publish("totalNotesHit", state.totalNotesHit or 0)
	publish("inGameOver", state.isDead == true)
	publish("playbackRate", state.playback or 1)
end

--- Writes the values that only change when the section changes.
--
-- mustHitSection/altAnim/gfSection belong to a section, not to the playhead, so
-- refreshing them per frame would be wrong work: a mod that sets them expects to
-- keep them until the next section.
function Refresh.section(compat)
	local state = compat.state
	if state == nil then return end
	local value = state.psychVariables
	local script = compat.script
	if value == nil or script == nil then return end

	local current = section(state)
	local index = state.psychSectionIndex or 1
	local function publish(key, v)
		value[key] = v
		if script.set then script:set(key, v) end
	end

	-- Psych exposes curSection 0-based; psychSectionIndex is 1-based.
	publish("curSection", index - 1)
	publish("mustHitSection", current and current.mustHitSection == true or false)
	publish("altAnim", current and current.altAnim == true or false)
	publish("gfSection", current and current.gfSection == true or false)
end

return Refresh
