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

## Coverage

All **222** Lua callbacks of Psych 1.0.4, across every file that registers one:

| File | Callbacks |
|---|---|
| `FunkinLua` | 128 |
| `ExtraFunctions` | 31 |
| `TextFunctions` | 17 |
| `DeprecatedFunctions` | 15 |
| `ShaderFunctions` | 14 |
| `ReflectionFunctions` | 13 |
| `FlxAnimateFunctions` | 4 |
| **Total** | **222** |

`LuaUtils` carries no callbacks of its own; it holds the helpers the others call
(property paths, tween preparation, object lookup) and compiles with them.

## Why `FunkinLua` compiles at all

It is Psych's host class, not a helper: it owns the `lua_State`. Measured before
assuming anything — 1,867 lines, of which **1,550 are callback registrations and
only 25 touch the Lua C API**, all inside five methods (`new`, `call`, `set`,
`stop`, `getBool`).

So the C API surface is a closed list:

```
LuaL.newstate / openlibs / dostring / dofile
Lua.type / getglobal / setglobal / pcall / pop / close / tostring
Convert.toLua / fromLua        <- the Haxe <-> stack boundary
```

Everything the 128 callbacks do is engine work, which is exactly what the externs
declare.

## What the engine must provide

The externs are the contract. In Light Engine each one has to resolve to a real
object: `Paths` to the mod asset resolver, `PlayState` to the play state,
`FlxSprite` to the sprite, and so on. That binding is the remaining work, and it
is a bounded list of classes rather than 222 functions.

## Files

- `PsychBridge.hx` — entry point. `install` narrows the host to a real
  `psychlua.FunkinLua` and calls each `implement`.
- `psychlua/` — types that live in Psych's own package (`ModchartSprite`,
  `DebugLuaText`, `HScript`, …).
- `shaders/` — Psych's error-reporting shader wrapper.
- `tjson/` — the tolerant JSON parser Psych reads data with.

Everything else is one extern class per file, which is what Haxe requires: a type
is only reachable as `Module.Type` when it is declared in `Module.hx`.

## A note on accuracy

Every member here was cross-checked against Psych's own source, not the call
sites. That matters: `moveCamera` takes a `Bool`, `FlxTimer.start` is
`(time, onComplete, loops)`, `FlxTween.color` takes the two colours, and
`Paths.getPath`'s second argument is an asset type. Reading a call site makes all
four look like something else.
