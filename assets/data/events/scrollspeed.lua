local tweens = {}
local baseSpeed

local function cancelTweens()
	for nf, tw in pairs(tweens) do
		if tw then tw:cancel() end
		tweens[nf] = nil
	end
end

function event(params)
	local v = params.v or {}
	if not baseSpeed then
		baseSpeed = (PlayState.SONG and PlayState.SONG.speed) or 1
	end

	-- Support V-Slice {scroll, duration, ease, absolute} and Psych {mult, duration}
	local scroll = tonumber(v.scroll or v[1]) or 1
	local durationSteps = tonumber(v.duration)
	local durationSec = (v.duration == nil and v[2] ~= nil) and tonumber(v[2]) or nil
	local ease = v.ease or "linear"
	local absolute = v.absolute

	local targetSpeed = absolute and scroll or (baseSpeed * scroll)
	cancelTweens()

	local dur = 0
	if durationSec then
		dur = math.max(0, durationSec)
	elseif durationSteps and durationSteps > 0 and PlayState.conductor then
		dur = (PlayState.conductor.stepCrotchet / 1000) * durationSteps
	end

	if dur <= 0 or ease == "INSTANT" then
		for _, notefield in ipairs(state.notefields) do
			notefield.speed = targetSpeed
		end
	else
		local easeFn = Ease[ease] or Ease.linear
		for _, notefield in ipairs(state.notefields) do
			tweens[notefield] = state.tween:tween(
				notefield,
				{speed = targetSpeed},
				dur,
				{
					ease = easeFn,
					onComplete = function() tweens[notefield] = nil end
				}
			)
		end
	end
end
