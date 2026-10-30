function event(params)
	local v = params.v or {}
	-- Supports Psych ("intensity, duration" in v[1], v[2]) or structured {gameIntensity, gameDuration, hudIntensity, hudDuration}
	if type(v[1]) == "string" and v[1]:find(",") then
		local gi, gd = v[1]:match("^%s*([%d%.]+)%s*,%s*([%d%.]+)")
		gi, gd = tonumber(gi) or 0, tonumber(gd) or 0
		if gi > 0 and gd > 0 and game.camera then game.camera:shake(gi, gd, nil, true) end
		if type(v[2]) == "string" and v[2]:find(",") then
			local hi, hd = v[2]:match("^%s*([%d%.]+)%s*,%s*([%d%.]+)")
			hi, hd = tonumber(hi) or 0, tonumber(hd) or 0
			if hi > 0 and hd > 0 and state.camHUD then state.camHUD:shake(hi, hd, nil, true) end
		end
		return
	end
	local intensity = tonumber(v.intensity or v[1]) or 0.01
	local duration = tonumber(v.duration or v[2]) or 0.25
	local camName = tostring(v.camera or v[3] or "both"):lower()
	if (camName == "both" or camName == "game" or camName == "camgame") and game.camera then
		game.camera:shake(intensity, duration, nil, true)
	end
	if (camName == "both" or camName == "hud" or camName == "camhud") and state.camHUD then
		state.camHUD:shake(intensity * 0.5, duration, nil, true)
	end
end
