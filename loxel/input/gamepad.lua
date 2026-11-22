local Gamepad = {devices = {}}
local buttons = {
	A = "a", B = "b", X = "x", Y = "y", BACK = "back", START = "start", GUIDE = "guide",
	LEFT_SHOULDER = "leftshoulder", RIGHT_SHOULDER = "rightshoulder",
	LEFT_STICK_CLICK = "leftstick", RIGHT_STICK_CLICK = "rightstick",
	DPAD_UP = "dpup", DPAD_DOWN = "dpdown", DPAD_LEFT = "dpleft", DPAD_RIGHT = "dpright"
}

local function device(joystick)
	local id = joystick:getID() - 1
	local entry = Gamepad.devices[id]
	if not entry or entry.joystick ~= joystick then
		entry = {joystick = joystick, pressed = {}, justPressed = {}, justReleased = {}}
		Gamepad.devices[id] = entry
	end
	return entry
end

local function set(entry, name, pressed)
	if pressed == (entry.pressed[name] == true) then return end
	entry.pressed[name] = pressed or nil
	entry[pressed and "justPressed" or "justReleased"][name] = true
end

function Gamepad.onPressed(joystick, button)
	local entry = device(joystick)
	for name, key in pairs(buttons) do if key == button then set(entry, name, true) end end
end

function Gamepad.onReleased(joystick, button)
	local entry = device(joystick)
	for name, key in pairs(buttons) do if key == button then set(entry, name, false) end end
end

function Gamepad.onRemoved(joystick)
	for id, entry in pairs(Gamepad.devices) do
		if entry.joystick == joystick then Gamepad.devices[id] = nil end
	end
end

function Gamepad.update()
	local connected = {}
	for _, joystick in ipairs(love.joystick.getJoysticks()) do
		if joystick:isGamepad() then
			local entry = device(joystick)
			connected[joystick] = true
			for name, key in pairs(buttons) do set(entry, name, joystick:isGamepadDown(key)) end
			for _, side in ipairs({"left", "right"}) do
				local x, y = joystick:getGamepadAxis(side .. "x"), joystick:getGamepadAxis(side .. "y")
				local prefix = side:upper() .. "_STICK_DIGITAL_"
				set(entry, prefix .. "LEFT", x < -0.5)
				set(entry, prefix .. "RIGHT", x > 0.5)
				set(entry, prefix .. "UP", y < -0.5)
				set(entry, prefix .. "DOWN", y > 0.5)
				set(entry, side:upper() .. "_TRIGGER", joystick:getGamepadAxis("trigger" .. side) > 0.5)
			end
		end
	end
	for id, entry in pairs(Gamepad.devices) do
		if not connected[entry.joystick] then Gamepad.devices[id] = nil end
	end
end

function Gamepad.reset()
	for _, entry in pairs(Gamepad.devices) do
		table.clear(entry.justPressed)
		table.clear(entry.justReleased)
	end
end

return Gamepad
