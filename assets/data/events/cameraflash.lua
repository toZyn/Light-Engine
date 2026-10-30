function event(params)
	local v = params.v or {}
	local camName = tostring(v.camera or v[1] or "hud"):lower()
	local colorRaw = v.color or v[2] or "#FFFFFF"
	local duration = tonumber(v.duration or v[3]) or 0.5
	local cam = (camName == "game" or camName == "camgame") and game.camera or state.camHUD
	if not cam then return end
	local col = Color.WHITE
	if type(colorRaw) == "string" and colorRaw ~= "" then
		local ok, parsed = pcall(Color.fromString, colorRaw)
		if ok and parsed then col = parsed end
	elseif type(colorRaw) == "table" then
		col = colorRaw
	end
	cam:flash(col, math.max(0.01, duration), nil, true)
end
