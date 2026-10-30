function event(params)
	local v = params.v or {}
	state.zoomRate = tonumber(v.rate or v[1]) or 4
	local intensity = tonumber(v.intensity or v[2]) or 1
	state.camZoomIntensity = 1 + 0.015 * intensity
	state.hudZoomIntensity = 0.03 * intensity
end
