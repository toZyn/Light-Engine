-- Original Light Engine error presentation, restored from base 9787da0.
-- Original FNF LÖVE authors; distribution terms remain in LICENSE.md.
-- Report persistence and guarded emergency fallback belong to funkin.throwError.
local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1 + (layer or 1)):gsub("\n[^\n]+$", "")))
end

return function(msg, callerTrace)

	local Diagnostics = require "funkin.backend.diagnostics"
	msg = Diagnostics.sanitize(msg)
	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then return end

	if not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then return end
	end

	local trace = Diagnostics.sanitize(callerTrace or debug.traceback("", 2))

	if utf8 == nil then utf8 = require("utf8") end

	local sanitizedmsg, err = {}, {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	table.insert(err, sanitizedmsg)
	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end

	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		l = l:gsub("stack traceback:", "Traceback\n")
		table.insert(err, l)
	end

	local p = table.concat(err, "\n"):gsub("\t", ""):gsub("%[string \"(.-)\"%]", "%1")
	local fullErrorText = p

	love.graphics.reset()
	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1)
	love.graphics.origin()

	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then love.mouse.setCursor() end
	end
	if love.joystick then
		for i, v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.window then
		love.window.setFullscreen(false)
		love.window.setDisplaySleepEnabled(true)
	end
	if love.audio then love.audio.stop() end
	if love.handlers then love.handlers = nil end

	collectgarbage()
	collectgarbage()

	local interactTxt = ""
	if love.system then
		interactTxt = interactTxt .. "\n\nPress Ctrl+C or tap to copy this error"
	end
	interactTxt = interactTxt .. "\nPress ESC to quit"
	interactTxt = interactTxt .. "\nPress Ctrl+R to restart"

	local menuDesat, funkinLogo, fnfFont18, fnfFont20
	local bgMusic, missSfx

	local function firstPass()
		menuDesat = paths.getImage("menus/menuDesat")
		funkinLogo = paths.getImage("menus/splashscreen/FNFLOVE_logo")
		fnfFont18 = paths.getFont("phantommuff.ttf", 18) or love.graphics.setNewFont(18)
		fnfFont20 = paths.getFont("phantommuff.ttf", 35) or love.graphics.setNewFont(35)

		bgMusic = paths.getMusic("pause/railways", "static")
		missSfx = love.audio.newSource(paths.getSound("gameplay/missnote" .. love.math.random(1, 3)), "static")

		bgMusic:setLooping(true)
		bgMusic:setVolume(0.7)
		bgMusic:play()

		missSfx:setVolume(0.4)
		missSfx:play()
	end

	local dontDraw = false
	local __error__, __align__, focused = "[ ERROR ]", "left"
	local scale1, scale2, gameW, gameH, hgameW, hgameH, retval
	local menuDesatW, menuDesatH, funkinLogoW, funkinLogoH
	local function draw(force)
		if not force and dontDraw then return end

		love.graphics.clear(0, 0, 0)

		hgameW, hgameH = gameW / 2, gameH / 2
		menuDesatW, menuDesatH = menuDesat:getWidth(), menuDesat:getHeight()
		funkinLogoW, funkinLogoH = funkinLogo:getWidth(), funkinLogo:getHeight()

		scale1 = math.max(gameW / menuDesatW, gameH / menuDesatH)
		scale2 = math.max(math.min(gameW, 1600) / funkinLogoW, math.min(gameH, 900) / funkinLogoH) * 0.525

		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.draw(menuDesat, hgameW, hgameH, 0, scale1, scale1, menuDesatW / 2, menuDesatH / 2)
		love.graphics.draw(funkinLogo, (hgameW * 2) - (scale2 * funkinLogoW / 1.8) - 64, hgameH, 0, scale2, scale2, funkinLogoW / 2, funkinLogoH / 2)

		love.graphics.setColor(1, 1, 1)

		love.graphics.setFont(fnfFont20)
		love.graphics.printf(__error__, 40, 40, love.graphics.getWidth() - 80, __align__)

		love.graphics.setFont(fnfFont18)
		love.graphics.printf(p, 40, 110, love.graphics.getWidth() - 80, __align__)

		love.graphics.setFont(fnfFont18)
		love.graphics.printf(interactTxt, 40, love.graphics.getHeight() - 130, love.graphics.getWidth() - 80, __align__)

		love.graphics.present()
	end

	local function copyToClipboard()
		love.system.setClipboardText(fullErrorText)
		p = p .. "\nCopied to clipboard!"
		draw()
	end

	local eventhandlers = {
		quit = function()
			return 1
		end,
		keypressed = function(key)
			if key == "escape" then return 1 end
			if not love.keyboard.isDown("lctrl", "rctrl") then return end
			if love.system and key == "c" then
				copyToClipboard()
			elseif key == "r" then
				return "restart"
			end
		end,
		touchpressed = function()
			local name = love.window.getTitle()
			if #name == 0 or name == "Untitled" then name = "Game" end

			local buttons = {"OK", "Cancel", "Restart"}
			if love.system then buttons[4] = "Copy to clipboard" end

			local pressed = love.window.showMessageBox("Quit " .. name .. "?", "", buttons)
			if pressed == 1 then
				return 1
			elseif pressed == 3 then
				return "restart"
			elseif pressed == 4 then
				copyToClipboard()
			end
		end,
		focus = function(f)
			bgMusic:setVolume(f and 0.7 or 0.3)
		end,
		resize = function(w, h)
			gameW, gameH = w, h
			draw()
		end,
		displayrotated = function(force)
			gameW, gameH = love.graphics.getDimensions()
			draw(force)
		end
	}

	local __step__, name, a, b = "step"
	--[[ if love.system.getDevice() == "Mobile" then
		dontDraw = true

		local first, done = true, false
		return function()
			if first then
				first = false
				return
			end

			love.event.pump()
			for name, a in love.event.poll() do
				if eventhandlers[name] ~= nil then
					retval = eventhandlers[name](a)
					if retval then return retval end
				end
			end

			if not done then
				firstPass()
			end
			eventhandlers.displayrotated(true)

			done = true
			collectgarbage(__step__)
			sleep(0.1)
		end
	end]]

	firstPass()
	eventhandlers.displayrotated(true)

	return function()
		name, a, b = love.event.wait()
		if eventhandlers[name] ~= nil then
			collectgarbage(__step__)
			retval = (eventhandlers[name])(a, b)
			if retval then return retval end
		end
	end
end
