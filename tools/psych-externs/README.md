# Psych externs

`extern` declarations for the outside world that Psych Engine's own Lua layer
(`source/psychlua/*.hx`) talks to. Nothing here is an implementation: every class
maps to something Light Engine already owns, so compiling Psych's source produces
Lua that calls into this engine.

## Why this exists

Reimplementing Psych's Lua functions by hand means reinterpreting them, and the
reinterpretations are where the bugs come from. Compiling Psych's actual source
means the behaviour *is* Psych's.

This route is already proven in this repository: `psych/runtime.lua` is Haxe
4.3.7 output running on LuaJIT.

## What it covers today

| Files compiled | Callbacks |
|---|---|
| `TextFunctions` | 17 |
| `ExtraFunctions` | 31 |
| `ReflectionFunctions` | 13 |
| `ShaderFunctions` | 14 |
| `DeprecatedFunctions` | 15 |
| `FlxAnimateFunctions` | 4 |
| **Total** | **94** |

That is 94 of Psych 1.0.4's 222 Lua callbacks. The remaining **128 live in
`FunkinLua.hx`**, which is not a helper file: it is the class that owns the
`lua_State` and calls the Lua C API directly.

Measured: 123 of those 128 do not touch the C API at all — they are plain
registrations of engine operations. Only a small minority need real Lua-stack
work.

## What the engine must provide

The externs are the contract. In Light Engine each one has to resolve to a real
object: `Paths` to the mod asset resolver, `PlayState` to the play state,
`FlxSprite` to the sprite, and so on. That binding is the remaining work, and it
is a bounded list — about 60 classes, not 222 functions.

## Files

- `PsychBridge.hx` — entry point. `install` hands Psych's registrations a host
  object and calls each `implement`.
- `psychlua/` — types that live in Psych's own `psychlua` package
  (`ModchartSprite`, `ModchartText`, `ModchartAnimateSprite`).
- `shaders/` — Psych's error-reporting shader wrapper.
- `tjson/` — the tolerant JSON parser Psych reads data with.

Everything else is one extern class per file, which is what Haxe requires: a type
is only reachable as `Module.Type` when it is declared in `Module.hx`.
