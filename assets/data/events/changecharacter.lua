function event(params)
	local v = params.v or {}
	local slot = v.slot or v.target or v[1] or "dad"
	local newChar = v.character or v.char or v[2]
	if newChar and newChar ~= "" and state.swapCharacter then
		state:swapCharacter(slot, tostring(newChar))
	end
end
