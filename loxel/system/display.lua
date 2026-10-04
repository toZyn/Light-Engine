-- LÖVE exposes one native window. Monitor indices are live OS enumeration indices.
local Display = {}
local nativeFullscreen = love.window.setFullscreen
local windowedWidth, windowedHeight

local function desktop()
	return love.system.getDevice() ~= "Mobile"
end

local function positive(value)
	return type(value) == "number" and value > 0 and value < math.huge
end

local function apply(fn, ...)
	local ok, result = pcall(fn, ...)
	if not ok then return false, tostring(result) end
	if result == false then return false, "The operating system rejected the window change." end
	return true
end

function Display.getMonitors()
	local monitors = {}
	for i = 1, love.window.getDisplayCount() do
		local width, height = love.window.getDesktopDimensions(i)
		monitors[i] = {index = i, name = love.window.getDisplayName(i), width = width, height = height}
	end
	return monitors
end

function Display.getMonitor()
	local _, _, flags = love.window.getMode()
	local index = flags.display or 1
	if index < 1 or index > love.window.getDisplayCount() then return 1 end
	return index
end

function Display.refresh()
	Display.width, Display.height = love.graphics.getDimensions()
	Display.monitor = Display.getMonitor()
	Display.fullscreen = love.window.getFullscreen()
	return Display
end

function Display.selectMonitor(index)
	if not desktop() then return false, "Monitor selection is controlled by the mobile operating system." end
	if type(index) ~= "number" or index ~= math.floor(index) or index < 1 or index > love.window.getDisplayCount() then
		return false, "The requested monitor is unavailable."
	end
	local width, height, flags = love.window.getMode()
	if flags.display == index then Display.refresh(); return true end
	local x, y = love.window.getPosition()
	local function restore(reason)
		local restored, restoreError = apply(love.window.updateMode, width, height, flags)
		if restored then restored, restoreError = apply(love.window.setPosition, x, y, flags.display) end
		Display.refresh()
		if not restored then reason = reason .. " Previous window restoration failed: " .. tostring(restoreError) end
		return false, reason
	end
	local targetWidth = flags.fullscreen and windowedWidth or width
	local targetHeight = flags.fullscreen and windowedHeight or height
	local ok, err = apply(love.window.updateMode, targetWidth or width, targetHeight or height, {display = index, centered = true})
	if not ok then return restore(err) end
	if not flags.fullscreen then
		local dw, dh = love.window.getDesktopDimensions(index)
		ok, err = apply(love.window.setPosition, math.max(0, math.floor((dw - width) / 2)), math.max(0, math.floor((dh - height) / 2)), index)
		if not ok then return restore(err) end
	end
	Display.refresh()
	if Display.monitor ~= index then return restore("The operating system did not move the window to the requested monitor.") end
	return true
end

function Display.setFullscreen(enabled, kind)
	if not desktop() then return false, "Fullscreen is controlled by the mobile operating system." end
	if type(enabled) ~= "boolean" or (kind ~= nil and kind ~= "desktop" and kind ~= "exclusive") then
		return false, "Expected a fullscreen boolean and desktop or exclusive mode."
	end
	local previous, previousKind = love.window.getFullscreen()
	kind = kind or "desktop"
	if previous == enabled and (not enabled or previousKind == kind) then Display.refresh(); return true end
	if not previous then windowedWidth, windowedHeight = love.window.getMode() end
	local ok, err = apply(nativeFullscreen, enabled, kind)
	if not ok then return false, err end
	if not enabled and windowedWidth then
		ok, err = apply(love.window.updateMode, windowedWidth, windowedHeight)
	end
	Display.refresh()
	if love.handlers.fullscreen then
		love.handlers.fullscreen(Display.fullscreen, select(2, love.window.getFullscreen()))
	elseif love.fullscreen then
		love.fullscreen(Display.fullscreen, select(2, love.window.getFullscreen()))
	end
	if not ok then return false, err end
	return true
end

-- Explicit desktop window sizing never changes camera resolution or mobile window bounds.
function Display.resizeWindow(width, height)
	if not desktop() then return false, "Window size is controlled by the mobile operating system." end
	if not positive(width) or not positive(height) then return false, "Window dimensions must be positive finite numbers." end
	if love.window.getFullscreen() then return false, "Leave fullscreen before resizing the window." end
	local dw, dh = love.window.getDesktopDimensions(Display.getMonitor())
	local fit = math.min(1, dw / width, dh / height)
	local ok, err = apply(love.window.updateMode, math.max(1, math.floor(width * fit)), math.max(1, math.floor(height * fit)))
	if not ok then return false, err end
	windowedWidth, windowedHeight = love.window.getMode()
	Display.refresh()
	return true
end

function Display.getViewport()
	local width, height = love.graphics.getDimensions()
	local gw, gh = game.width, game.height
	if not positive(gw) or not positive(gh) or width <= 0 or height <= 0 then return nil end
	local scale = math.min(width / gw, height / gh)
	return {x = (width - scale * gw) / 2, y = (height - scale * gh) / 2,
		width = scale * gw, height = scale * gh, scale = scale}
end

function Display.windowToGame(x, y)
	local view = Display.getViewport()
	if not view then return nil, nil end
	return (x - view.x) / view.scale, (y - view.y) / view.scale
end

function Display.gameToWindow(x, y)
	local view = Display.getViewport()
	if not view then return nil, nil end
	return view.x + x * view.scale, view.y + y * view.scale
end

return Display
