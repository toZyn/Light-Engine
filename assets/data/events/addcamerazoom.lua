function event(params)
	local v = params.v or {}
	local gameAdd = tonumber(v.game or v.cam or v[1]) or 0.015
	local hudAdd = tonumber(v.hud or v[2]) or 0.03
	if params.psych then
		if game.camera.zoom >= 1.35 then return end
		game.camera.zoom = game.camera.zoom + gameAdd
	else
		state.camZoomMult = (state.camZoomMult or 1) + gameAdd
	end
	if state.camHUD then
		state.camHUD.zoom = (state.camHUD.zoom or 1) + hudAdd
	end
end
