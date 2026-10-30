local zoomTween

function event(params)
	local v = params.v or {}
	local zoom = tonumber(v.zoom or v[1]) or 1
	local durationSteps = tonumber(v.duration)
	local durationSec = (v.duration == nil and v[2] ~= nil) and tonumber(v[2]) or nil
	local mode = v.mode or "stage"
	local ease = v.ease or "linear"

	local targetZoom = (mode == "direct") and zoom or ((state.stage and state.stage.camZoom or 1) * zoom)
	if zoomTween then zoomTween:cancel(); zoomTween = nil end

	local dur = 0
	if durationSec then
		dur = math.max(0, durationSec)
	elseif durationSteps and durationSteps > 0 and PlayState.conductor then
		dur = (PlayState.conductor.stepCrotchet / 1000) * durationSteps
	end

	if dur <= 0 or ease == "INSTANT" then
		state.camZoom = targetZoom
	else
		zoomTween = state.tween:tween(
			state,
			{camZoom = targetZoom},
			dur,
			{ease = Ease[ease] or Ease.linear, onComplete = function() zoomTween = nil end}
		)
	end
end
