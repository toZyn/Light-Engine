# Psych 1.0.4 batch 1 contracts

The Reference classes contain callback bodies from `source/psychlua/ExtraFunctions.hx`
at Psych commit `5c67ced49e5a98535298a6daa3f8f4ec79ac8399`. Random contains
`int`, `float`, `bool`, and `generate` from HaxeFlixel 5.6.1's
`flixel/math/FlxRandom.hx`, the version pinned by Psych's Project.xml.
The accompanying license files apply to these excerpts.

Run `python tests/reference/psych104/generate.py --haxe /path/to/haxe` with
Haxe 4.3.7 to regenerate the four JSON fixtures. Native tests execute the same
calls through Light's installed Lua API and compare results and errors.

The harness supplies keyboard, controller, controls, Paths and trace providers.
It executes Psych's callback bodies, Haxe StringTools, Haxe native file operations
and the FlxRandom generator. It does not run Psych or HaxeFlixel's input backend.
Input fixtures use controller 0, no controller 8, a held and released A button,
and fixed stick values. Native tests separately exercise LÖVE controller events.
Fixtures cover defaults, missing resources, exclusion lists, case sensitivity,
UTF-8 strings, disconnected IDs, and a null string error.

File fixtures use `/tmp/psych-files-comparison`; tests replace that prefix with
an isolated directory below LÖVE's save directory. Directory contents are sorted
for comparison because neither engine promises directory enumeration order.
The test removes its files and does not write to user mod files.

The batch does not test physical Android input, Android external-storage
permissions, Windows controller IDs, or Mali GPU pixel readback. Geometry queries
are integration tests, without an executing Flixel collision reference; their
inventory entries remain `distinta` with their differences recorded.

ReferenceInitialization contains unchanged PlayState field declarations in a synthetic wrapper. Reference, ReferenceInput and ReferenceFiles adapt callback registration and replace engine services with synthetic providers. Legal provenance headers identify these modifications. Psych 1.0.4 includes LICENSE (Apache-2.0) and no NOTICE file at its repository root. No mod scripts or mod assets are used by this harness.

## Native field defaults

Run `python tests/reference/psych104/verify_cpp_defaults.py --haxe /path/to/haxe --check`.
This generates C++ with the actual Haxe compiler, checks emitted Float/Int/Bool/String types, and compiles a C++17 probe for zeroed allocation and the original explicit initializers. The temporary haxelib shim provides metadata for code generation only; it does not supply hxcpp or fake a successful engine build. The native initialization JSON is produced by this probe, not Haxe --interp. ReferenceInitialization remains the source declaration inventory.

The allocation premise is verified against hxcpp v4.3.2: include/hx/Object.h routes object allocation to InternalNew/ImmixAllocator; src/hx/gc/Immix.cpp uses ZERO_MEM (memset(ptr,0,n)), clears recycled allocation ranges, and clears large allocations. Sources: https://github.com/HaxeFoundation/hxcpp/blob/v4.3.2/include/hx/Object.h and https://github.com/HaxeFoundation/hxcpp/blob/v4.3.2/src/hx/gc/Immix.cpp . A zeroed Float is 0, Int is 0, Bool is false; String retains its null state unless explicitly initialized. This probe does not execute hxcpp's allocator or a compiled Psych game.

Psych initialization evidence: source/psychlua/FunkinLua.hx initializes all defaultPlayerStrumX/Y0–3 and defaultOpponentStrumX/Y0–3 to 0 in its constructor. source/states/PlayState.hx:956–987 assigns generated-arrow positions inside startCountdown after onStartCountdown accepts the countdown, before onCountdownStarted. The globals are therefore zero, not nil, in an initial script's onCreate.
