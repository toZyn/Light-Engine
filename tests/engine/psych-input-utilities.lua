check('Psych 1.0.4 utility contracts match Haxe execution', function()
 local Utilities = require 'funkin.backend.scripts.psych.utilities'
 local api = {}
 Utilities.install({state = {}, script = {}, _active = function() end}, api)
 Utilities.setRandomSeed(1)
 local cases = (loxreq 'lib.json').decode(assert(love.filesystem.read('tests/fixtures/psych-1.0.4/utilities.json')))
 for i, case in ipairs(cases) do
  local args = {}
  for j, value in ipairs(case.args) do args[j] = value end
  local ok, value = pcall(api[case.name], unpack(args))
  assert(ok ~= case.error, case.name .. ' error contract ' .. i)
  if ok then
   if type(case.value) == 'table' then
    assert(#value == #case.value, case.name .. ' array length ' .. i)
    for j, expected in ipairs(case.value) do assert(value[j] == expected, case.name .. ' array item ' .. i) end
   elseif type(case.value) == 'number' then
    assert(math.abs(value - case.value) < 1e-10, case.name .. ' number ' .. i)
   else assert(value == case.value, case.name .. ' value ' .. i) end
  end
 end
end)

check('Psych input return values and defaults match Haxe execution', function()
 local Input = require 'funkin.backend.scripts.psych.input'
 local api = {}
 Input.install({_active = function() end}, api)
 local savedControls, savedDevices = controls, game.gamepads.devices
 local saved = {}
 for _, source in ipairs({'pressed','justPressed','justReleased'}) do
  saved[source] = game.keys[source]
  game.keys[source] = {A = true, B = false}
 end
 local joystick = {getGamepadAxis = function(_, axis)
  return ({leftx = .75, lefty = -.5, rightx = -.25, righty = .5})[axis]
 end}
 game.gamepads.devices = {[0] = {joystick = joystick, pressed = {A = true}, justPressed = {A = true}, justReleased = {A = true}}}
 controls = {_controls = {note_left = {}, accept = {}},
  pressed = function(_, name) return name == 'note_left' end,
  down = function(_, name) return name == 'note_left' end,
  released = function(_, name) return name == 'note_left' end}
 local ok, err = xpcall(function()
  local cases = (loxreq 'lib.json').decode(assert(love.filesystem.read('tests/fixtures/psych-1.0.4/input.json')))
  for index, case in ipairs(cases) do
   local success, value = pcall(api[case.name], unpack(case.args))
   assert(success ~= case.error, case.name .. ' error ' .. index)
   local expected = case.value
   if expected == (loxreq 'lib.json').null then expected = nil end
   assert(value == expected, case.name .. ' return ' .. index .. ': '..tostring(value)..' vs '..tostring(expected))
  end
 end, debug.traceback)
 controls, game.gamepads.devices = savedControls, savedDevices
 for source, values in pairs(saved) do game.keys[source] = values end
 assert(ok, err)
end)

check('gamepad events keep edges through a frame and separate controllers', function()
 local pads = game.gamepads
 local savedDevices, getJoysticks = pads.devices, love.joystick.getJoysticks
 pads.devices = {}
 local held = {}
 local function joystick(id)
  return {getID=function() return id end,isGamepad=function() return true end,
   isGamepadDown=function(_, name) return held[id..name] == true end,
   getGamepadAxis=function() return 0 end}
 end
 local first, second = joystick(1), joystick(2)
 love.joystick.getJoysticks = function() return {first,second} end
 pads.onPressed(first, 'a')
 pads.onReleased(first, 'a')
 held['2a'] = true
 pads.update()
 local ok, err = pcall(function()
  assert(pads.devices[0].justPressed.A and pads.devices[0].justReleased.A)
  assert(not pads.devices[0].pressed.A and pads.devices[1].pressed.A)
  pads.reset()
  pads.update()
  assert(not next(pads.devices[0].justPressed) and not next(pads.devices[1].justPressed))
  pads.onRemoved(first)
  assert(pads.devices[0] == nil and pads.devices[1])
 end)
 love.joystick.getJoysticks, pads.devices = getJoysticks, savedDevices
 assert(ok, err)
end)

check('Psych file contracts match Haxe execution', function()
 local Files = require 'funkin.backend.scripts.psych.files'
 local api = {}
 Files.install({_active = function() end}, api)
 local originalMods, getPath = Mods.root, paths.getPath
 assert(love.filesystem.createDirectory('psych-files-comparison'))
 local base = love.filesystem.getSaveDirectory() .. '/psych-files-comparison'
 Mods.root = base
 paths.getPath = function(path) return base .. '/' .. path end
 local ok, err = xpcall(function()
  local cases = (loxreq 'lib.json').decode(assert(love.filesystem.read('tests/fixtures/psych-1.0.4/files.json')))
  for index, case in ipairs(cases) do
   local args = {}
   for i, value in ipairs(case.args) do
    args[i] = type(value) == 'string' and value:gsub('/tmp/psych%-files%-comparison', base) or value
   end
   local success, value = pcall(api[case.name], unpack(args))
   assert(success ~= case.error, case.name .. ' error ' .. index .. ': ' .. tostring(value))
   local expected = case.value
   if type(expected) == 'table' then
    table.sort(value)
    assert(table.concat(value,'|') == table.concat(expected,'|'),case.name .. ' array ' .. index)
   else
    if expected == (loxreq 'lib.json').null then expected = nil end
    assert(value == expected, case.name .. ' return '..index..': '..tostring(value)..' vs '..tostring(expected))
   end
  end
 end, debug.traceback)
 Mods.root, paths.getPath = originalMods, getPath
 assert(ok, err)
end)

check('query utilities preserve geometry, pixel values and render state', function()
 local state = Group()
 local script = Script('tests/engine/compat-fixture.lua', false, true, true)
 script._psych = require('funkin.backend.scripts.compat').new(state,script,true)
 local api = script.variables
 local first = api.makeLuaSprite('first', nil, 4, 6)
 local second = api.makeLuaSprite('second', nil, 5, 7)
 api.makeGraphic('first', 4, 4, 'FF0000')
 api.makeGraphic('second', 4, 4, '00FF00')
 assert(api.objectsOverlap('first','second'))
 assert(not api.objectsOverlap('first','first'))
 second.x = 8
 assert(not api.objectsOverlap('first','second'))
 assert(not api.objectsOverlap('missing','first'))
 assert(api.getScreenPositionX('missing') == 0)
 local sx, sy = game.camera.scroll.x, game.camera.scroll.y
 game.camera.scroll:set(3, 4)
 first.scrollFactor:set(.5, 0)
 assert(api.getScreenPositionX('first') == 2.5 and api.getScreenPositionY('first') == 6)
 game.camera.scroll:set(sx, sy)
 local pixels = love.image.newImageData(4,4)
 pixels:mapPixel(function() return 1,0,0,1 end)
 local texture = love.graphics.newImage(pixels)
 first:loadTexture(texture)
 assert(api.getPixelColor('first',0,0) == bit.tobit(0xFFFF0000))
 pixels:release()
 assert(api.getPixelColor('first',4,0) == 0)
 assert(api.getPixelColor('missing',0,0) == bit.tobit(0xFF000000))
 assert(api.stringTrim(' a ') == 'a' and api.keyJustPressed('missing') == false)
 assert(api.keyJustPressed('space') == false)
 state.scripts = {scripts = {script}}
 assert(#api.getRunningScripts() == 1 and api.getRunningScripts()[1] == script.path)
 texture:release()
 script:close()
end)
