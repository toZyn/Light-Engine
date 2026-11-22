function event(params)
	local values = params.v or {}
	local slot = tostring(values[1] or ""):lower():match("^%s*(.-)%s*$")
	local character
	if slot == "bf" or slot == "boyfriend" or slot == "1" then
		character = state.boyfriend
	elseif slot == "gf" or slot == "girlfriend" or slot == "2" then
		character = state.gf
	else
		character = state.dad
	end
	if character then
		local suffix = tostring(values[2] or "")
		character.psychIdleSuffix = suffix ~= "" and suffix or nil
	end
end
