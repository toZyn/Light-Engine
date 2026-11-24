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
"""
import pathlib
import subprocess
import sys
import tempfile
import textwrap

HARNESS = textwrap.dedent("""\
    package.path = './?.lua;' .. package.path
    local Bindings = require('funkin.backend.scripts.psych.bindings')

    -- Load the shim through the engine's own loader, not a copy of it. A harness
    -- that reimplements the loader tests the harness: the first version set its
    -- own environment and the compiled layer could not see setmetatable.
    local compat = {{}}
    compat.psychShimSourceFor = function()
      return assert(io.open('{shim}', 'r')):read('*a')
    end
    local shim = Bindings.loadShim(compat)
    assert(shim, 'the shim did not load')

    -- install() registers the six helper classes. It needs no song, because
    -- those classes only use a FunkinLua object.
    local state = shim.state()
    local host = {{lua = state, callbacks = {{}}, customFunctions = {{}}}}
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

    -- One name per helper class, each taken from that class's own source. A
    -- regression in a specific callback should fail as itself, not as a count.
    for _, name in ipairs({{{names}}}) do
      assert(registered[name], name .. ' not registered by install')
    end
    print('SHIM RAN OK')
""")

# Names that install() is responsible for. makeLuaSprite, playSound, callScript
# and loadGraphic are registered in FunkinLua.new(), so they cannot appear here.
REQUIRED = "'setProperty', 'getProperty', 'makeLuaText', 'keyboardPressed', " \
           "'musicFadeIn', 'getShaderFloat'"


def main(candidates):
    if len(candidates) != 1:
        print("usage: check_psych_shim.py <compiled-shim.lua>", file=sys.stderr)
        return 2
    shim = pathlib.Path(candidates[0])
    if not shim.is_file():
        print(f"::error title=shim missing::{shim} was not produced", file=sys.stderr)
        return 1

    source = HARNESS.replace("{shim}", str(shim)).replace("{names}", REQUIRED)
    with tempfile.TemporaryDirectory() as tmp:
        harness = pathlib.Path(tmp) / "harness.lua"
        harness.write_text(source)
        result = subprocess.run(
            ["lua5.1", str(harness)], text=True, capture_output=True,
            cwd=pathlib.Path(__file__).resolve().parents[1])

    sys.stdout.write(result.stdout)
    if result.returncode == 0:
        return 0

    sys.stderr.write(result.stderr)
    # The last line of a Lua error is often just "[C]: ?" and names nothing.
    lines = [line for line in result.stderr.splitlines() if line.strip()]
    for start in range(0, min(len(lines), 12), 4):
        print("::error title=shim trace {}::{}".format(
            start, " / ".join(lines[start:start + 4])[:1200]))
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
