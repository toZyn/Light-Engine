-- Guards the structural Psych Engine behaviours that mods depend on.
--
-- Each check corresponds to a failure seen on real hardware, where a blocked
-- primitive or one dead callback left an entire song unscripted. These run
-- through the suite runner's `check()`, so a failure reports its full message.

check('Psych scripts may extend the standard library', function()
	-- `table.new`, `math.clamp` and `os.clock` shims are everywhere in Psych mods.
	-- Blocking writes aborted onCreate with "table new indexing not allowed"
	-- before the mod ran a single line of its own code.
	love.filesystem.createDirectory('tests/engine')
	love.filesystem.write('tests/engine/psych-stdlib-ext.lua', [[
function extend()
  table.newField = function() return 'table-ok' end
  math.clampHelper = function(v) return v end
  os.myClock = function() return 1 end
  string.newHelper = function() return 'string-ok' end
end
function readBack()
  return table.newField ~= nil and math.clampHelper ~= nil
    and os.myClock ~= nil and string.newHelper ~= nil
end
]])
	local ext = Script('tests/engine/psych-stdlib-ext.lua', true, true, true)
	ext:call('extend')
	assert(not ext.__failedfunc.extend, 'standard library extension must be allowed like Psych')
	assert(ext:call('readBack') == true, 'extension did not persist across callbacks')
	assert(table.newField and table.newField() == 'table-ok', 'table extension missing')
	assert(math.clampHelper and math.clampHelper(2) == 2, 'math extension missing')
	assert(os.myClock and os.myClock() == 1, 'os extension missing')
	assert(string.newHelper and string.newHelper() == 'string-ok', 'string extension missing')
	ext:close()
	love.filesystem.remove('tests/engine/psych-stdlib-ext.lua')

	-- Engine-critical primitives stay reserved so one mod cannot break the rest.
	love.filesystem.write('tests/engine/psych-reserved.lua',
		'function clobber() math.random = function() return 0 end end\n')
	local reserved = Script('tests/engine/psych-reserved.lua', true, true, true)
	reserved:call('clobber')
	assert(type(math.random) == 'function', 'math.random must stay reserved')
	reserved:close()
	love.filesystem.remove('tests/engine/psych-reserved.lua')
end)

check('getfenv and setfenv are reachable from scripts', function()
	-- LÖVE's LuaJIT is built with LUA52COMPAT, so these 5.1 globals are absent.
	-- They were also in the blocklist, so the sandbox answered with a denial
	-- function and Psych module scripts failed with "setfenv not allowed".
	love.filesystem.write('tests/engine/psych-fenv.lua', [[
function inspect()
  local level = getfenv(1)
  local explicit = getfenv(function() return 1 end)
  local returned = setfenv(function() return 1 end, {marker = true}) ~= nil
  return type(level) == 'table' and type(explicit) == 'table' and returned
end
]])
	local fenv = Script('tests/engine/psych-fenv.lua', true, true, true)
	assert(fenv:call('inspect') == true, 'getfenv/setfenv must be callable from a script')
	assert(not fenv.__failedfunc.inspect, 'getfenv/setfenv must not be blocked')
	fenv:close()
	love.filesystem.remove('tests/engine/psych-fenv.lua')
end)

check('a throwing callback stays callable and recovers', function()
	-- Psych reports the Lua error and keeps dispatching. Permanently disabling the
	-- callback turned one bad frame into a stage with no camera work, no events
	-- and no cleanup, which is the "mod loads but does nothing" report.
	love.filesystem.write('tests/engine/psych-retry.lua', [[
attempts = 0
function flaky()
  attempts = attempts + 1
  if attempts < 3 then error('transient failure '..attempts) end
  return 'recovered'
end
]])
	local flaky = Script('tests/engine/psych-retry.lua', true, true, true)
	flaky:call('flaky')   -- attempt 1 throws
	flaky:call('flaky')   -- attempt 2 throws
	assert(flaky.variables.attempts == 2, 'a failed callback must be dispatched again, like Psych')
	assert(flaky:call('flaky') == 'recovered', 'callback must recover once the transient failure clears')
	assert(flaky.variables.attempts == 3, 'callback must run on every dispatch')
	assert(not flaky.__failedfunc.flaky, 'recovered callback must clear its failure mark')
	flaky:close()
	love.filesystem.remove('tests/engine/psych-retry.lua')
end)

check('Psych note proxies accept writes they cannot model', function()
	-- `setPropertyFromGroup(..., "mustPress", ...)` killed onSpawnNote and
	-- onUpdatePost before this: the proxy raised on any unmodelled write.
	local Notes = require 'funkin.backend.scripts.psych.notes'
	local fakeNote = {time = 1, sustainTime = 0, type = '', skin = {psychTexture = ''}, directions = {z = 0}}
	local proxy = Notes.note(fakeNote, 'playerField', nil)
	local wrote = pcall(function()
		proxy.mustPress = true
		proxy.someModField = 42
		proxy.alpha = 0.5
	end)
	assert(wrote, 'note property writes must never raise')
	assert(proxy.someModField == 42, 'stashed note fields must round-trip')
	assert(proxy.alpha == 0.5, 'modelled note fields must still write through')
end)

check('note fields mods do arithmetic with are never nil', function()
	-- Reading `note.speed` or `note.angle` and adding to it raised "attempt to
	-- perform arithmetic on a nil value" inside healthy onSpawnNote handlers.
	local Notes = require 'funkin.backend.scripts.psych.notes'
	local fakeNote = {time = 1, sustainTime = 0, type = '', speed = 1,
		skin = {psychTexture = ''}, directions = {z = 0}}
	local proxy = Notes.note(fakeNote, 'playerField', nil)
	for _, key in ipairs({'speed', 'angle', 'offsetX', 'offsetY', 'column', 'hits', 'misses',
		'scaleX', 'scaleY', 'hitHealth', 'missHealth'}) do
		local value = proxy[key]
		assert(type(value) == 'number', 'note.' .. key .. ' must be numeric, got ' .. type(value))
	end
	assert(proxy.speed == 1 and proxy.scaleX == 1, 'scale/speed defaults must match Psych')
	assert(proxy.hitCausesMiss == false and proxy.noMissAnimation == false,
		'boolean note defaults must match Psych')
end)

check('a skin reload never clears the note direction', function()
	-- Note:setSkin used to blank `direction` for the length of the reload and
	-- restore it afterwards. A note whose direction was already gone, or a
	-- reload that raised, kept nil for good: the sprite was rebuilt in the wrong
	-- lane (the arrows that render skewed) and the notefield update then died on
	-- `note.direction + 1`.
	local Note = require 'funkin.gameplay.note'
	local note = setmetatable({direction = 2, skin = {}, sustainSegments = 1}, Note)
	note.play = function() end
	note.setDirection = function(self, value) self.direction = value end
	note.loadSkinData = function() end
	Note.setSkin(note, {skin = 'test'})
	assert(note.direction == 2, 'setSkin must preserve direction, got ' .. tostring(note.direction))

	-- Even a reload that raises must not strand the note without a direction.
	local broken = setmetatable({direction = 1, skin = {}}, Note)
	broken.play = function() end
	broken.loadSkinData = function() error('skin asset missing') end
	pcall(Note.setSkin, broken, {skin = 'broken'})
	assert(broken.direction == 1, 'a failed reload must not clear direction')

	-- Receptor:setSkin carried the identical defect, which is why the strum line
	-- looked skewed as well.
	local Receptor = require 'funkin.gameplay.receptor'
	local receptor = setmetatable({direction = 3, skin = {}}, Receptor)
	receptor.play = function() end
	receptor.setDirection = function(self, value) self.direction = value end
	Receptor.setSkin(receptor, {receptors = true, skin = 'test'})
	assert(receptor.direction == 3, 'Receptor:setSkin must preserve direction, got '
		.. tostring(receptor.direction))
end)

check('sprites resolve across the contexts of one state', function()
	-- Psych shares one tag namespace per state, so a counter built in one script
	-- is routinely updated from another. Lookups that answered nil made the
	-- update silently do nothing: `slpCounter` stayed frozen on screen and the
	-- compatibility layer logged 255 "sprite tag is not owned" warnings a song.
	local Compat = require 'funkin.backend.scripts.compat'
	-- Compat.new validates its arguments against native types, so these have to be
	-- a real Group and a real loaded Script, not tables.
	local state = Group()
	state.camHUD, state.camOther = Camera(), Camera()
	game.camera = Camera()
	local first = Compat.new(state, Script('tests/engine/compat-fixture.lua', false, true, true), true)
	local second = Compat.new(state, Script('tests/engine/compat-fixture.lua', false, true, true), true)
	local sprite = first:_sprite('slpCounter', nil, 0, 0, false)
	assert(sprite, 'first context must create the sprite')
	local found = second:_owned('slpCounter')
	assert(found == sprite, 'a sibling context must resolve the shared tag')
	second:_remove('slpCounter', true)
	assert(first.objects.slpCounter == nil, 'removal must hit the context that owns the tag')
	second:dispose()
	first:dispose()
	assert(#state.compatContexts == 0, 'disposing must unregister the context')
end)

check('every Psych 1.0.4 Lua function is defined', function()
	-- The expected list is read from Psych's own source (source/psychlua/*.hx,
	-- every `add_callback` name). A function missing here raises
	-- "attempt to call a nil value" and aborts whichever callback used it, which
	-- is how a mod dies half way through a song with nothing obviously wrong.
	local expected = require 'tests.engine.psych-api-surface'
	local state = Group()
	state.camHUD, state.camOther = Camera(), Camera()
	game.camera = Camera()
	local Compat = require 'funkin.backend.scripts.compat'
	local script = Script('tests/engine/compat-fixture.lua', false, true, true)
	-- Constructing a psych context installs the whole Lua surface onto its own api
	-- table, which is exactly what a mod sees, so diffing that is authoritative.
	Compat.new(state, script, true)
	-- Every entry point is mirrored onto the script's variables, which is the
	-- table the mod itself reads a global from.
	local missing = {}
	for _, name in ipairs(expected) do
		if rawget(script.variables, name) == nil then missing[#missing + 1] = name end
	end
	assert(#missing == 0, 'missing Psych functions: ' .. table.concat(missing, ', '))
end)

check('Psych shaders are translated to LÖVE entry points', function()
	-- Mods ship standalone `void main()` programs that write gl_FragColor and
	-- sample `bitmap`. LÖVE needs effect()/position(), so every one of them failed
	-- on Android with
	--   bad argument #2 to 'validateShader' (missing 'position' or 'effect' function?)
	local psychFrag = '#define texture texture2D\n'
		.. 'void main() {\n  gl_FragColor = texture(bitmap, openfl_TextureCoordv);\n}\n'
	local sanitized = Shader.sanitizeGLSL(psychFrag, false)
	assert(sanitized:find('vec4%s+effect%s*%('), 'Psych fragment shader was not translated to effect()')
	assert(not sanitized:find('void%s+main%s*%(%s*%)%s*{'), 'standalone main() survived translation')
	assert(not sanitized:find('#define%s+texture'), 'redefined prelude macro was kept')
	-- `bitmap` must be in scope inside the moved body, otherwise the driver reports
	-- "ERROR: 'bitmap' : undeclared identifier".
	assert(sanitized:find('psychMain%s*%(%s*Image%s+bitmap%s*%)'),
		'translated body cannot see the sampled image as `bitmap`')
	assert(sanitized:find('psychMain%s*%(%s*bitmap%s*%)'),
		'translated effect() does not forward bitmap to the Psych body')

	local psychVert = 'void main() {\n  gl_Position = openfl_Matrix * openfl_Position;\n}\n'
	assert(Shader.sanitizeGLSL(psychVert, true):find('vec4%s+position%s*%('),
		'Psych vertex shader was not translated to position()')

	-- A LÖVE-style vertex shader has no gl_Position; it must not become effect().
	local loveVert = '#pragma header\nvoid main() {\n #pragma body\n}\n'
	local sanitizedLoveVert = Shader.sanitizeGLSL(loveVert)
	assert(sanitizedLoveVert:find('vec4%s+position%s*%('),
		'LÖVE vertex shader without gl_Position was not translated to position()')
	assert(not sanitizedLoveVert:find('vec4%s+effect%s*%('),
		'LÖVE vertex shader was wrongly translated to effect()')

	-- Already-valid LÖVE shaders must be left alone.
	local native = 'vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {\n'
		.. '  return Texel(texture, texture_coords) * color;\n}\n'
	assert(Shader.sanitizeGLSL(native) == native, 'native LÖVE shaders must not be rewritten')
end)

check('the initLuaShader translator scopes bitmap too', function()
	-- psych/shaders.lua carries its own copy of the rewrite; keeping them in sync
	-- matters because initLuaShader is the path Psych mods use most.
	local source = love.filesystem.read('funkin/backend/scripts/psych/shaders.lua') or ''
	assert(source:find('psychMain%s*%(%s*Image%s+bitmap%s*%)'),
		'initLuaShader translator does not pass bitmap into the Psych body')
	assert(source:find('psychMain%s*%(%s*bitmap%s*%)'),
		'initLuaShader translator does not forward bitmap')
end)
