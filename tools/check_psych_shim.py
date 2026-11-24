#!/usr/bin/env python3
"""Run the compiled Psych shim against the engine's bridge.

Compiling proves Psych's source is expressible in Lua. This proves the result
actually runs: the shim is loaded the way the engine loads it, its callbacks are
registered through the bridge, and the ones that belong to the helper classes are
checked by name.

Usage: tools/check_psych_shim.py build/psych-lua/psych-lua.lua

Lives here rather than inline in the workflow because the harness is a multi-line
Python program with its own Lua source: embedding it in a `run:` block made the
workflow fail actionlint, which surfaced as an unrelated CI job dying at step 5.

Runs the Lua in-process through lupa (a wheel, so installing takes seconds) rather
than shelling out to a lua binary, which would need apt on the runner -- and
apt-get update there exceeded the job's whole time budget.
"""
import pathlib
import sys

# Names that install() is responsible for, one per helper class. makeLuaSprite,
# playSound, callScript and loadGraphic are registered in FunkinLua.new(), so
# they cannot appear here.
REQUIRED = ["setProperty", "getProperty", "makeLuaText", "keyboardPressed",
            "musicFadeIn", "getShaderFloat"]

HARNESS = """
package.path = './?.lua;' .. package.path
local Bindings = require('funkin.backend.scripts.psych.bindings')

-- Load the shim through the engine's own loader, not a copy of it. A harness that
-- reimplements the loader tests the harness: the first version set its own
-- environment, and the compiled layer could not see setmetatable.
local compat = {}
compat.psychShimSourceFor = function()
  return assert(io.open(SHIM_PATH, 'r')):read('*a')
end
local shim = Bindings.loadShim(compat)
assert(shim, 'the shim did not load')

-- install() registers the six helper classes. It needs no song, because those
-- classes only use a FunkinLua object.
local state = shim.state()
local host = {lua = state, callbacks = {}, customFunctions = {}}
host.addLocalCallback = function(_, name, fn)
  shim.scope.Lua_helper.add_callback(state, name, fn)
end
host.initLuaShader = function() return false end

shim.install(host)

local registered = shim.bridge.registryFor(state).callbacks
local count = 0
for _ in pairs(registered) do count = count + 1 end
print('install registered ' .. count .. ' callbacks')
assert(count >= 90, 'helper surface incomplete: ' .. count)

-- A regression in one callback should fail as itself, not as a count.
for _, name in ipairs(NAMES) do
  assert(registered[name], name .. ' not registered by install')
end
print('SHIM RAN OK')
"""


def lua_value(text):
    return '"%s"' % text.replace("\\", "\\\\").replace('"', '\\"')


def main(candidates):
    if len(candidates) != 1:
        print("usage: check_psych_shim.py <compiled-shim.lua>", file=sys.stderr)
        return 2
    shim = pathlib.Path(candidates[0])
    if not shim.is_file():
        print(f"::error title=shim missing::{shim} was not produced", file=sys.stderr)
        return 1

    try:
        from lupa import LuaRuntime
    except ImportError:
        print("::error title=lupa missing::pip install lupa did not take",
              file=sys.stderr)
        return 1

    names = "{" + ", ".join(lua_value(name) for name in REQUIRED) + "}"
    source = (HARNESS.replace("SHIM_PATH", lua_value(str(shim)))
                    .replace("NAMES", names))

    runtime = LuaRuntime(unpack_returned_tuples=True)
    try:
        runtime.execute(source)
    except Exception as error:  # lupa raises LuaError carrying the traceback
        message = str(error)
        print(message, file=sys.stderr)
        # The last line of a Lua error is often just "[C]: ?" and names nothing,
        # so the first frames are what says where it broke.
        lines = [line for line in message.splitlines() if line.strip()]
        for start in range(0, min(len(lines), 8), 4):
            print("::error title=shim trace {}::{}".format(
                start, " / ".join(lines[start:start + 4])[:1200]))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
