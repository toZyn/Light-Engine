-- Run as main.lua in a temporary LÖVE checkout runner.
--
-- Guards the structural Psych Engine behaviours that mods depend on. Each block
-- here corresponds to a failure seen on real hardware, where a single blocked
-- primitive or one dead callback left an entire song unscripted.
require 'loxel'
require 'funkin'

function love.load()
	local ok, err = xpcall(function()
		love.window.setMode(320, 240, {vsync = 0}); game.width, game.height = 320, 240
		love.filesystem.setIdentity('light-engine-psych-runtime-tests')
		local checked = 0

		-- 1. Psych scripts extend the standard library. `table.new`, `math.clamp`
		--    and `os.clock` shims are everywhere; blocking writes aborted onCreate
		--    with "table new indexing not allowed" before any mod code ran.
		love.filesystem.createDirectory('tests/engine')
		love.filesystem.write('tests/engine/psych-stdlib-ext.lua', [[
function extend()
  table.newField = function() return 'table-ok' end
  math.clampHelper = function(v) return v end
  os.myClock = function() return 1 end
  string.newHelper = function() return 'string-ok' end
  return table.newField(), math.clampHelper(2), os.myClock(), string.newHelper()
end
function readBack()
  return table.newField and math.clampHelper and os.myClock and string.newHelper
end
]])
		local ext = Script('tests/engine/psych-stdlib-ext.lua', true, true, true) -- luacheck: ignore
		ext:call('extend')
		assert(not ext.__failedfunc.extend, 'standard library extension must be allowed like Psych')
		assert(ext:call('readBack') == true, 'extension did not persist across callbacks')
		assert(table.newField and table.newField() == 'table-ok', 'table extension missing')
		assert(math.clampHelper and math.clampHelper(2) == 2, 'math extension missing')
		assert(os.myClock and os.myClock() == 1, 'os extension missing')
		ext:close()
		-- Engine-critical primitives stay reserved so one mod cannot break the rest.
		love.filesystem.write('tests/engine/psych-reserved.lua', [[
function clobber()
  local ok = pcall(function() math.random = function() return 0 end end)
  return math.random ~= nil and ok ~= nil
end
]])
		local reserved = Script('tests/engine/psych-reserved.lua', true, true, true)
		reserved:call('clobber')
		assert(type(math.random) == 'function', 'math.random must stay reserved')
		reserved:close()
		checked = checked + 1
		love.filesystem.remove('tests/engine/psych-stdlib-ext.lua')
		love.filesystem.remove('tests/engine/psych-reserved.lua')

		-- 2. getfenv/setfenv are plain Lua 5.1 reflection. Psych module scripts use
		--    the classic `setfenv(1, mod)` pattern.
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
		checked = checked + 1
		love.filesystem.remove('tests/engine/psych-fenv.lua')

		-- 3. A throwing callback must stay callable. Psych reports the error and
		--    keeps the script alive; permanently disabling it left the stage with
		--    no camera work, no events and no cleanup after one bad frame.
		love.filesystem.write('tests/engine/psych-retry.lua', [[
attempts = 0
function flaky()
  attempts = attempts + 1
  if attempts < 3 then error('transient failure '..attempts) end
  return 'recovered'
end
]])
		local flaky = Script('tests/engine/psych-retry.lua', true, true, true)
		assert(flaky:call('flaky') == nil, 'first call must fail')
		assert(flaky.__failedfunc.flaky, 'first failure must be tracked')
		flaky:call('flaky')
		assert(flaky:call('flaky') == 'recovered', 'callback must recover after transient failure')
		assert(flaky.variables.attempts == 3, 'callback must run on every dispatch like Psych')
		assert(not flaky.__failedfunc.flaky, 'recovered callback must clear its failure mark')
		flaky:close()
		checked = checked + 1
		love.filesystem.remove('tests/engine/psych-retry.lua')

		-- 4. Psych note writes never abort a callback. `note.mustPress = x` and
		--    arbitrary stashed fields are normal onSpawnNote traffic.
		local Notes = require 'funkin.backend.scripts.psych.notes'
		local fakeNote = {time = 1, sustainTime = 0, type = '', skin = {psychTexture = ''}, directions = {z = 0}}
		local proxy = Notes.note(fakeNote, 'playerField', nil)
		local writeOk = pcall(function()
			proxy.mustPress = true
			proxy.someModField = 42
			proxy.alpha = 0.5
		end)
		assert(writeOk, 'note property writes must never raise')
		assert(proxy.someModField == 42, 'stashed note fields must round-trip')
		assert(proxy.alpha == 0.5, 'modelled note fields must still write through')
		checked = checked + 1

		-- 5. A Psych-shader program (standalone `void main` writing gl_FragColor)
		--    must translate to a LÖVE `effect` shader instead of failing validation.
		-- `Shader` is exposed globally by funkin/init.lua
		local psychFrag = [[
#define texture texture2D
void main() {
  gl_FragColor = texture(bitmap, openfl_TextureCoordv);
}
]]
		local sanitized = Shader.sanitizeGLSL(psychFrag)
		assert(sanitized:find('vec4%s+effect%s*%('), 'Psych fragment shader was not translated to effect()')
		assert(not sanitized:find('void%s+main%s*%(%s*%)%s*{'), 'standalone main() survived translation')
		assert(not sanitized:find('#define%s+texture'), 'redefined prelude macro was kept')
		local psychVert = [[
void main() {
  gl_Position = openfl_Matrix * openfl_Position;
}
]]
		local sanitizedVert = Shader.sanitizeGLSL(psychVert)
		assert(sanitizedVert:find('vec4%s+position%s*%('), 'Psych vertex shader was not translated to position()')
		-- A LÖVE-style vertex shader (`#pragma body`, no gl_Position) must not be
		-- rewritten into an effect() shader: it is validated as a vertex program.
		local loveVert = '#pragma header\nvoid main() {\n #pragma body\n}\n'
		local sanitizedLoveVert = Shader.sanitizeGLSL(loveVert)
		assert(sanitizedLoveVert:find('vec4%s+position%s*%('),
			'LÖVE vertex shader without gl_Position was not translated to position()')
		assert(not sanitizedLoveVert:find('vec4%s+effect%s*%('),
			'LÖVE vertex shader was wrongly translated to effect()')
		-- Already-valid LÖVE shaders must be left alone.
		local native = [[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
  return Texel(texture, texture_coords) * color;
}
]]
		assert(Shader.sanitizeGLSL(native) == native, 'native LÖVE shaders must not be rewritten')
		checked = checked + 1

		assert(checked == 5, 'expected five structural checks, ran ' .. checked)
		print('PSYCH RUNTIME PASS: stdlib extension; getfenv/setfenv; callback retry; tolerant note writes; Psych shader translation')
	end, debug.traceback)
	if not ok then print('PSYCH RUNTIME FAIL ' .. err) end
	love.event.quit(ok and 0 or 1)
end
function love.update() end
function love.draw() end
function love.quit() end
function love.errorhandler(err) print(err); return function() return 1 end end
