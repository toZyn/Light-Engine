function event(params)
	local v = params.v or {}
	local target = tostring(v.target or v[1] or "both"):lower()
	local now = PlayState.conductor and PlayState.conductor.time or 0
	if (target == "both" or target == "bf" or target == "0" or target == "") and state.boyfriend then
		local anim = state.boyfriend:hasAnim("hey") and "hey" or (state.boyfriend:hasAnim("cheer") and "cheer" or nil)
		if anim then
			state.boyfriend:playAnim(anim, true, true)
			state.boyfriend.lastHit = now
		end
	end
	if (target == "both" or target == "gf" or target == "2" or target == "") and state.gf then
		local anim = state.gf:hasAnim("cheer") and "cheer" or (state.gf:hasAnim("hey") and "hey" or nil)
		if anim then
			state.gf:playAnim(anim, true, true)
			state.gf.lastHit = now
		end
	end
end
