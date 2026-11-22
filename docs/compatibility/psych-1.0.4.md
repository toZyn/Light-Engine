# Psych Engine 1.0.4 compatibility

Light Engine 0.7.0 includes compatibility improvements for Psych Engine 1.0.4 mods. Compatibility remains partial; this version does not claim to execute every Psych mod unchanged.

## Included behavior

- Lua keyboard/controller queries, strings, random helpers, file helpers and script enumeration.
- Constructor globals, PlayState score/miss/hit counters and stage base character coordinates.
- Rating thresholds, full-combo labels, rating overrides and scoring callback synchronization.
- Deprecated calls report through `luaDebugMode`/`luaDeprecatedWarnings`, and
  invalid calls warn and continue instead of aborting the script.
- Selected note/strum properties, texture changes, arrow skins, section callbacks, sprites, cameras, tweens and HScript bindings.
- The full 223-callback Lua surface registered by Psych 1.0.4, with alias-aware
  property reads and writes for sprites, characters, animation controllers and text.
- Psych HUD contract: `timeBar`/`timeTxt`/`timeBarBG` map to a native time bar, and `scoreTxt`/`botplayTxt` map to native PlayState text (or a Psych stand-in when a state has none) so `updateScoreText` and `setProperty("scoreTxt.text", …)` work.
- Missing menu asset recovery. Recovery beyond Psych behavior is identified by `[Light extension]` in the log.

The runtime still uses the existing compatibility setting and mod detection. API availability depends on the detected layout and script initialization.

## Validation

The implementation was checked with 36 native LÖVE 11.5 suites, 106 constructor-global comparisons, 48 rating cases, 67 utility cases, 58 input cases, 13 file cases and nine native-field checks, plus a Bool assertion. Synthetic fixtures are stored under tests/; third-party reference excerpts retain their licenses and attribution.

The 0.7.0 API surface was additionally exercised through a Lua harness that boots the engine with LÖVE stubs: every registered callback was checked for presence, and scripted scenarios covered reflection, instances, groups, tweens, timers, text, HUD, save data and note-skin selection.

These checks execute isolated Psych Haxe source and a C++ zeroed-allocation probe. They do not run a complete compiled Psych executable. Complete-mod playback, physical Android touch, external storage behavior and Mali-G57 rendering have not been validated for this release.

## Remaining differences

- Complete HaxeFlixel/OpenFL class and reflection coverage, group layering and script lifecycle parity are not established. The Psych HUD is limited to the time bar, score text and botplay text; other Psych HUD objects are not recreated.
- Some argument coercion, custom difficulty metadata, translations and callback-stop variants remain unverified.
- Video playback on this runtime requires supported native video assets; MP4 compatibility is not complete.
- Random stream ownership, controller mapping, path resolution and spatial queries can differ from Psych.
- loadScript, resizeWindow and ending are not standard Psych 1.0.4 functions and have not been added as compatibility APIs.

Use diagnostics to identify unsupported APIs and retain the engine version when reporting behavior differences.
