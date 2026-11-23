-- Guards the structural Psych Engine behaviours that mods depend on.
--
-- Each check corresponds to a failure seen on real hardware, where a blocked
-- primitive or one dead callback left an entire song unscripted. These run
-- through the suite runner's `check()`, so a failure reports its full message.

local outcome = {}
local function note(name, ok, err)
	outcome[#outcome + 1] = (ok and 'ok   ' or 'FAIL ') .. name ..
		(ok and '' or (': ' .. tostring(err)))
end

check('Psych scripts may extend the standard library', function()
	local ok, err = pcall(function()
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
	note('stdlib-extension', ok, err)
	if not ok then error(err, 0) end
end)

print('SUMMARY ' .. table.concat(outcome, ' || '))

check('getfenv and setfenv work inside scripts', function()
	local ok, err = pcall(function()
	-- They sat in the dofile/loadstring blocklist, so the classic
	-- `setfenv(1, module)` pattern failed with "setfenv not allowed".
	love.filesystem.write('tests/engine/psych-fenv.lua', [[
function modulePattern()
  local mod = {}
  setfenv(1, mod)
  exported = 'set via fenv'
  setfenv(1, getfenv(0))
  return true
end
]])
	local fenv = Script('tests/engine/psych-fenv.lua', true, true, true)
	assert(fenv:call('modulePattern') == true, 'setfenv module pattern must work')
	assert(not fenv.__failedfunc.modulePattern, 'getfenv/setfenv must not be blocked')
	fenv:close()
	love.filesystem.remove('tests/engine/psych-fenv.lua')
	end)
	note('fenv', ok, err)
	if not ok then error(err, 0) end
end)

print('SUMMARY ' .. table.concat(outcome, ' || '))

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
