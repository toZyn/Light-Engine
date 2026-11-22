local Input = {}
local controlsMap = {
	left = "note_left", down = "note_down", up = "note_up", right = "note_right",
	accept = "accept", back = "back", pause = "pause", reset = "reset",
	ui_left = "ui_left", ui_down = "ui_down", ui_up = "ui_up", ui_right = "ui_right"
}

function Input.install(compat, api)
	for suffix, source in pairs({JustPressed = "justPressed", Pressed = "pressed", Released = "justReleased"}) do
		api["keyboard" .. suffix] = function(name)
			compat:_active()
			if name == "ANY" or game.keys.keys[name] then return game.keys[source][name] == true end
			return nil
		end
		api["key" .. suffix] = function(name)
			compat:_active()
			name = (name or ""):lower():match("^%s*(.-)%s*$")
			local control = controlsMap[name] or (controls._controls[name] and name)
			if not control then return false end
			local method = source == "justPressed" and "pressed" or source == "pressed" and "down" or "released"
			return controls[method](controls, control)
		end
		local gamepadName = suffix == "JustPressed" and "JustPressed" or suffix
		api["gamepad" .. gamepadName] = function(id, name)
			compat:_active()
			local entry = game.gamepads.devices[tonumber(id)]
			return entry ~= nil and entry[source][name] == true
		end
		api["anyGamepad" .. gamepadName] = function(name)
			compat:_active()
			for _, entry in pairs(game.gamepads.devices) do if entry[source][name] then return true end end
			return false
		end
	end
	for _, axis in ipairs({"X", "Y"}) do
		api["gamepadAnalog" .. axis] = function(id, leftStick)
			compat:_active()
			local entry = game.gamepads.devices[tonumber(id)]
			if not entry then return 0 end
			local key = (leftStick == false and "right" or "left") .. axis:lower()
			local value = entry.joystick:getGamepadAxis(key)
			return math.abs(value) > 0.15 and value or 0
		end
	end
end

return Input
