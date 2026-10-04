-- Engine-owned diagnostics: never resolve paths through a mod or the asset cache.
local Diagnostics = {}
local directory, marker = 'diagnostics', 'diagnostics/session.active'
local started, reporting, lastCheckpoint, lastLabel = false, false, -math.huge, nil
local logLimit = 256 * 1024

local function safe(fn, ...)
 if type(fn) ~= 'function' then return nil end
 local ok, result, b, c, d = pcall(fn, ...)
 if ok then return result, b, c, d end
 return nil, result
end
local function stringify(value)
 local ok, text = pcall(tostring, value)
 return ok and text or '<unprintable error>'
end

-- Preserve every invalid byte as an escape; gmatch(utf8.charpattern) alone
-- accepts some malformed sequences which LÖVE's text renderer then rejects.
function Diagnostics.sanitize(value)
 local text, output, index = stringify(value), {}, 1
 while index <= #text do
  local byte = text:byte(index)
  local length = byte < 128 and 1 or (byte >= 194 and byte <= 223 and 2
   or (byte >= 224 and byte <= 239 and 3 or (byte >= 240 and byte <= 244 and 4 or 0)))
  local valid = length > 0 and index + length - 1 <= #text
  for offset = 1, length - 1 do
   local nextByte = text:byte(index + offset)
   if not nextByte or nextByte < 128 or nextByte > 191 then valid = false end
  end
  local second = text:byte(index + 1)
  if length == 3 and ((byte == 224 and (second or 0) < 160) or (byte == 237 and (second or 255) > 159)) then valid = false end
  if length == 4 and ((byte == 240 and (second or 0) < 144) or (byte == 244 and (second or 255) > 143)) then valid = false end
  if valid then
   output[#output + 1] = text:sub(index, index + length - 1)
   index = index + length
  else
   output[#output + 1] = string.format('\\x%02X', byte)
   index = index + 1
  end
 end
 return table.concat(output)
end
local function now()
 return safe(love.timer and love.timer.getTime) or os.time()
end
local function write(path, text)
 local ok, err = safe(love.filesystem.write, path, text)
 if not ok then print('Diagnostics write failed: ' .. path .. ': ' .. stringify(err)) end
 return ok
end
local function append(text)
 local info = safe(love.filesystem.getInfo, directory .. '/engine.log')
 if info and info.size >= logLimit then
  local previous = safe(love.filesystem.read, directory .. '/engine.log')
  if previous then write(directory .. '/engine.previous.log', previous) end
  write(directory .. '/engine.log', '')
 end
 local ok = safe(love.filesystem.append, directory .. '/engine.log', text .. '\n')
 if not ok then print('Diagnostics append failed: ' .. text) end
end
local function context(label)
 -- These queries enter the native renderer and can segfault before a
 -- graphics context exists; pcall cannot protect that startup state.
 local graphicsReady = love.window and safe(love.window.isOpen)
  and love.graphics and safe(love.graphics.isActive)
 local renderer, version, vendor, device = safe(graphicsReady and love.graphics.getRendererInfo)
 local stats = safe(graphicsReady and love.graphics.getStats) or {}
 local major, minor, revision, codename = safe(love.getVersion)
 local state = safe(game and game.getState)
 local stateName = state and (safe(function() return state.__name or state.name end) or stringify(state)) or 'none'
 return string.format('%s checkpoint=%s OS=%s LOVE=%s.%s.%s (%s) renderer=%s/%s/%s/%s mod=%s state=%s luaKB=%.1f textureBytes=%s',
  os.date('!%Y-%m-%dT%H:%M:%SZ'), Diagnostics.sanitize(label),
  Diagnostics.sanitize(safe(love.system and love.system.getOS) or 'unknown'),
  stringify(major), stringify(minor), stringify(revision), stringify(codename),
  Diagnostics.sanitize(renderer), Diagnostics.sanitize(version), Diagnostics.sanitize(vendor), Diagnostics.sanitize(device),
  Diagnostics.sanitize(Mods and Mods.currentMod or 'native'), Diagnostics.sanitize(stateName),
  safe(collectgarbage, 'count') or 0, stringify(stats.texturememory or 'unknown'))
end
function Diagnostics.start()
 if started then return end
 started = true
 safe(love.filesystem.createDirectory, directory)
 local previous = safe(love.filesystem.read, marker)
 if previous then
  append('Previous session interrupted (unclean shutdown; not proof of a crash):\n' .. Diagnostics.sanitize(previous))
 end
 Diagnostics.checkpoint('startup')
end
function Diagnostics.checkpoint(label)
 if not started then Diagnostics.start() end
 local time = now()
 label = stringify(label or 'running')
 if label == lastLabel and time - lastCheckpoint < 5 then return end
 lastLabel, lastCheckpoint = label, time
 local line = context(label)
 write(marker, line .. '\n')
 append(line)
end
function Diagnostics.report(message, trace)
 if reporting then return Diagnostics.sanitize(message) end
 reporting = true
 if not started then Diagnostics.start() end
 local text = context('error') .. '\n\n' .. Diagnostics.sanitize(message) .. '\n\n'
  .. Diagnostics.sanitize(trace or debug.traceback('', 2)) .. '\n'
 local saved = write(directory .. '/last-error.txt', text)
 append(text)
 write(marker, context('error') .. '\n')
 reporting = false
 local location = safe(love.filesystem.getSaveDirectory) or '<save directory unavailable>'
 if saved then return text .. '\nReport: ' .. location .. '/' .. directory .. '/last-error.txt' end
 return text .. '\nWARNING: report could not be saved; see console output.'
end
function Diagnostics.finish()
 if not started then return end
 append(context('clean shutdown'))
 safe(love.filesystem.remove, marker)
 started = false
 lastCheckpoint, lastLabel = -math.huge, nil
end

-- Built-in font and solid colors only. Even startup/graphics failures retain
-- the report and an event loop; no image, music, mod font or live cache access.
function Diagnostics.errorHandler(message, trace, savedReport)
 local text = savedReport or Diagnostics.report(message, trace)
 print(text)
 local graphics, drawable = love.graphics, false
 if graphics and love.window then
  if not safe(love.window.isOpen) then safe(love.window.setMode, 800, 600) end
  if safe(love.window.isOpen) and safe(graphics.isActive) then
   local ok = pcall(function()
    graphics.reset(); graphics.setCanvas(); graphics.origin()
    graphics.setFont(graphics.newFont(14))
   end)
   drawable = ok
  end
 end
 safe(love.mouse and love.mouse.setVisible, true)
 safe(love.mouse and love.mouse.setGrabbed, false)
 safe(love.mouse and love.mouse.setRelativeMode, false)
 safe(love.audio and love.audio.stop)
 local copied = false
 local function action(which)
  if which == 1 then
   if love.system and love.system.setClipboardText then copied = pcall(love.system.setClipboardText, text) end
  elseif which == 2 then return 'restart'
  elseif which == 3 then return 1 end
 end
 local function draw()
  if not drawable then return end
  local ok, err = pcall(function()
   local width, height = graphics.getDimensions()
   graphics.clear(0.08, 0.08, 0.1)
   graphics.setColor(1, 1, 1)
   graphics.printf('ENGINE ERROR\n\n' .. text, 16, 16, math.max(1, width - 32))
   graphics.setColor(0.12, 0.12, 0.16)
   graphics.rectangle('fill', 0, height - 68, width, 68)
   graphics.setColor(1, 1, 1)
   graphics.printf('Copy (C)                 Restart (R)                 Quit (Esc)\nTap the corresponding third below.' .. (copied and ' Copied!' or ''), 12, height - 60, math.max(1, width - 24), 'center')
   graphics.present()
  end)
  if not ok then
   drawable = false
   append('Error screen rendering unavailable: ' .. Diagnostics.sanitize(err))
  end
 end
 draw()
 return function()
  if not love.event then return 1 end
  love.event.pump()
  for name, a, b, c in love.event.poll() do
   if name == 'quit' then return 1 end
   local result
   if name == 'keypressed' then
    if a == 'escape' then return 1 end
    if a == 'r' then return 'restart' end
    if a == 'c' then action(1) end
   elseif name == 'touchpressed' or name == 'mousepressed' then
    local x, y = name == 'touchpressed' and b or a, name == 'touchpressed' and c or b
    local width, height = safe(drawable and graphics.getDimensions)
    if width and height and y >= height - 68 then
     result = action(math.min(3, math.max(1, math.floor(x / math.max(1, width / 3)) + 1)))
    end
   end
   if result then return result end
  end
  draw()
  safe(love.timer and love.timer.sleep, 0.05)
 end
end
return Diagnostics
