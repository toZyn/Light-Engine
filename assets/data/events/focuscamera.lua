local moveTween

function event(params)
	local v = params.v
	local charId = v
	local ox, oy, duration, ease = 0, 0, 0, nil
	if type(v) == "table" then
		charId = v.char ~= nil and v.char or v[1]
		ox = tonumber(v.x or v[2]) or 0
		oy = tonumber(v.y or v[3]) or 0
		duration = tonumber(v.duration or v[4]) or 0
		ease = v.ease or v[5]
	end

	local target
	if charId == 0 or charId == "0" or charId == "bf" or charId == "boyfriend" then
		target = state.boyfriend
	elseif charId == 1 or charId == "1" or charId == "dad" or charId == "opponent" then
		target = state.dad
	elseif charId == 2 or charId == "2" or charId == "gf" or charId == "girlfriend" then
		target = state.gf
	end

	if target then
		state.camTarget = target
	end

	if moveTween then moveTween:cancel(); moveTween = nil end

	if target then
		local cx, cy = state:getCameraPosition(target)
		cx, cy = cx + ox, cy + oy
		if duration > 0 and ease and ease ~= "CLASSIC" and ease ~= "INSTANT" and PlayState.conductor then
			local sec = (PlayState.conductor.stepCrotchet / 1000) * duration
			game.camera:follow(state.camFollow, nil)
			moveTween = state.tween:tween(state.camFollow, {x = cx, y = cy}, sec, {
				ease = Ease[ease] or Ease.quadOut,
				onComplete = function()
					moveTween = nil
					game.camera:follow(state.camFollow, nil, 2.4 * state.camSpeed)
				end
			})
		elseif ease == "INSTANT" then
			state.camFollow:set(cx, cy)
			game.camera:snapToTarget()
		else
			state:cameraMovement(cx, cy)
		end
	elseif ox ~= 0 or oy ~= 0 then
		state:cameraMovement(ox, oy)
	end
end
