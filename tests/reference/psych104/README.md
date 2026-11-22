# Psych 1.0.4 batch 1 contracts

The Reference classes contain callback bodies from `source/psychlua/ExtraFunctions.hx`
at Psych commit `5c67ced49e5a98535298a6daa3f8f4ec79ac8399`. Random contains
`int`, `float`, `bool`, and `generate` from HaxeFlixel 5.6.1's
`flixel/math/FlxRandom.hx`, the version pinned by Psych's Project.xml.
The accompanying license files apply to these excerpts.

Run `python tests/reference/psych104/generate.py --haxe /path/to/haxe` with
Haxe 4.3.7 to regenerate the three JSON fixtures. Native tests execute the same
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
