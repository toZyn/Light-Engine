local function resolveTarget(raw)
	if raw == nil then return state.dad end
	local s = tostring(raw):lower()
	if s == "bf" or s == "boyfriend" or s == "player" or s == "0" or s == "player1" then
		return state.boyfriend
	elseif s == "gf" or s == "girlfriend" or s == "2" or s == "gfversion" then
		return state.gf
	elseif s == "dad" or s == "opponent" or s == "enemy" or s == "1" or s == "player2" then
		return state.dad
	end
	return state[raw]
end

function event(e)
	local v = e.v or {}
	local anim = v.anim
	local targetName = v.target
	local force = v.force
	if anim == nil then
		-- Psych-style [1]=anim, [2]=target
		anim = v[1]
		targetName = v[2]
		force = v[3]
	end
	if force == nil then force = true end

	local target = resolveTarget(targetName)
	if not target or not anim or anim == "" then return end

	if target.playAnim then
		target:playAnim(tostring(anim), force, nil, true)
		if PlayState.conductor then
			target.lastHit = PlayState.conductor.time
		end
	elseif target.play then
		target:play(tostring(anim), force)
	end
end
