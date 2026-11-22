# Core and globals audit

## Current core menu and counter/global verification

| Surface | Current behavior | Verification / remaining gap |
|---|---|---|
| Intro text | Base entries followed by current-mod entries, trimmed and deduplicated; literal `--`; empty combined input returns blank intro with one `[Light extension]` warning | Native synthetic fixture; global mods and Psych executable remain unverified |
| Menu character JSON | Mod-first resolution; Psych `image` and native `sprite`; incomplete data filled from base BF, with one `[Light extension]` warning per path | Native missing/invalid/incomplete JSON and warning-deduplication fixtures; not strict Psych recovery parity |
| Score/miss/hit/combo counters | Zero before script source execution and onCreate | Nine original declarations; native Lua getter/lifecycle checks. Full scoring/callback behavior remains distinct |
| ratingPercent / ratingName / ratingFC | Native C++ target: 0 / `?` / null before rating recalculation | Haxe C++ generation verifies field types; compiled C++ zeroed-allocation probe; full hxcpp/Psych execution not performed |
| totalPlayed / totalNotesHit | Zero before script loading | Initialization verified; accumulation/rating lifecycle remain distinct |
| scrollSpeed | Initial chart.speed | Constructor tested; event update lifecycle unverified |
| Default strum globals | All 16 names zero in FunkinLua constructor; positions assigned by PlayState.startCountdown after arrow generation and before onCountdownStarted | Psych source and native initialization fixtures; actual rendered positions unverified |
| Gameplay globals | Constructor inserts curDecBeat/Step, health multipliers, playback, bot/practice/instakill/sustain flags | Nondefault settings and complete lifecycle remain unverified |

The previous interpreter inference that native ratingPercent starts null was incorrect and is removed. `verify_cpp_defaults.py` generates actual Haxe C++, checks Float/Int/Bool/String types and compiles a synthetic zeroed-allocation probe with g++. It supplies a metadata-only haxelib shim for code generation; no hxcpp runtime or compiled Psych game is represented by that shim. The runtime zeroing premise is source-checked in hxcpp v4.3.2 Object.h and Immix.cpp; README records the source links and limitations.

Current executed checks: five native suites (global initialization, menu asset fallbacks, menu regressions, gameplay flow, syntax); 138 callback reference cases; nine-field C++ probe plus Bool. Earlier 36-suite execution predates the native-default/warning corrections and is historical evidence, not a rerun of those changes. Physical Android, Mali-G57, touch and full mod runs remain unverified.

## Compiled Psych feasibility

A Linux reference build is feasible after installing the runtime/dependencies and materializing the pinned source/assets. It is not currently runnable: the downloaded haxelib binary fails to load libneko.so.2. The executable named neko on PATH is an unrelated streaming server, not the Haxe Neko VM. No working lime or full hxcpp installation was found. Project.xml requires Flixel 5.6.1, flixel-addons 3.2.2, tjson 1.4.0, linc_luajit, hscript-iris 1.1.3, hxvlc 2.0.1, flxanimate, plus Lime/OpenFL dependencies; their full installation/build has not been completed. Direct source download timed out in this environment. Android additionally needs its cross-compilation toolchain, which has not been validated. These are observed setup/network blockers, not a claim that Psych cannot compile.

## Non-Psych APIs — pending, no new implementation

loadScript, resizeWindow and ending are not registered Psych 1.0.4 functions. With no mod-defined function, calling them raises an attempt-to-call-nil Lua error. They remain pending and were not implemented. ClientPrefs.windowMove is not a Psych field; reflection returns null/nil for a missing field. The existing Light special case is a separate unresolved difference. No extension contract has been activated for these APIs.
