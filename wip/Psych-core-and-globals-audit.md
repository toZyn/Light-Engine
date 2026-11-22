# Core and globals audit

## Current core menu and counter/global verification

| Surface | Current behavior | Verification / remaining gap |
|---|---|---|
| Intro text | Base entries followed by current-mod entries, trimmed and deduplicated; literal `--`; empty combined input returns blank intro with one `[Light extension]` warning | Native synthetic fixture; global mods and Psych executable remain unverified |
| Menu character JSON | Mod-first resolution; Psych `image` and native `sprite`; incomplete data filled from base BF, with one `[Light extension]` warning per path | Native missing/invalid/incomplete JSON and warning-deduplication fixtures; not strict Psych recovery parity |
| Score/miss/hit/combo counters | Zero before script source; Psych miss penalty -10, combo reset 0; CPU/ratingDisabled handling wired | Constructor, rating and native regression checks; complete compiled gameplay/callback timing not certified |
| ratingPercent / ratingName / ratingFC | Native initial 0 / `?` / null; Psych threshold and FC algorithms; stopped hooks preserve overrides; globals published around rating callbacks | 48 original Haxe method cases plus native hook/setter checks; full hxcpp/Psych not executed |
| totalPlayed / totalNotesHit | Zero before script loading; Psych hit/miss accumulation wired; rating hooks receive synchronized counters | Isolated rating algorithm/order and callback integration tested; full compiled gameplay remains unverified |
| scrollSpeed | Initial chart.speed | Constructor tested; event update lifecycle unverified |
| Default strum globals | All 16 names zero in FunkinLua constructor; positions assigned by PlayState.startCountdown after arrow generation and before onCountdownStarted | Psych source and native initialization fixtures; actual rendered positions unverified |
| Constructor globals | 106 source set-call keys are populated, including Function_* strings, settings, difficulty metadata and base character coordinates | Default Linux/English profile compared to original Haxe constructor; additional profiles remain unverified |

The previous interpreter inference that native ratingPercent starts null was incorrect and is removed. `verify_cpp_defaults.py` generates actual Haxe C++, checks Float/Int/Bool/String types and compiles a synthetic zeroed-allocation probe with g++. It supplies a metadata-only haxelib shim for code generation; no hxcpp runtime or compiled Psych game is represented by that shim. The runtime zeroing premise is source-checked in hxcpp v4.3.2 Object.h and Immix.cpp; README records the source links and limitations.

Published HEAD a304cf5893d8897102e6d88af024482eec75af97 was checked in a detached worktree: 36 suites passed, 0 failed; 67 utility + 58 input + 13 file + 9 C++ fields = 147 reference checks, plus one Bool assertion. Five suites referred to the previous selective correction run; 138 excluded the nine C++ fields. The earlier nine interpreter declarations are no longer used as native-default evidence. See wip/VERIFICATION-a304cf5.json for per-suite results. Physical Android, Mali-G57, touch and full mod runs remain unverified.

## Compiled Psych feasibility

A Linux reference build is feasible after installing the runtime/dependencies and materializing the pinned source/assets. It is not currently runnable: the downloaded haxelib binary fails to load libneko.so.2. The executable named neko on PATH is an unrelated streaming server, not the Haxe Neko VM. No working lime or full hxcpp installation was found. Project.xml requires Flixel 5.6.1, flixel-addons 3.2.2, tjson 1.4.0, linc_luajit, hscript-iris 1.1.3, hxvlc 2.0.1, flxanimate, plus Lime/OpenFL dependencies; their full installation/build has not been completed. Direct source download timed out in this environment. Android additionally needs its cross-compilation toolchain, which has not been validated. These are observed setup/network blockers, not a claim that Psych cannot compile.

## Current lot 1 additions and limits

- Globals module now centralizes all constructor set-call keys. Haxe comparison covers 106 keys; base coordinates come from parsed stage data before Lua source execution (not rendered sprite positions or character offsets). Constructor default strums are justified by Psych source/psychlua/FunkinLua.hx:163–167; generated-arrow coordinates replace them in source/states/PlayState.hx:972–980.
- Rating algorithm follows the original RecalculateRating/fullComboFunction, with score/miss/hit/combo publication before onRecalculateRating, rating publication after it, and score callbacks even when calculation is stopped. Tests cover threshold boundaries, clamping, totalPlayed=0, FC/SDCB/Clear and stop handling.
- Exposed setRatingPercent/setRatingName/setRatingFC update state and globals without recalculating. Valid typed values are tested. Missing/wrong-type Lua-to-Haxe coercion is not certified; these API rows remain distinct for that concrete gap.
- Remaining lot-1 verification gaps: full compiled Psych, translations, hidden-week indexing, all custom difficulty metadata, every Function_Stop* control-flow variant, script reload/global mutation profiles, complete note-hit callback ordering and rendering behavior. These are not marked resolved. HUD remains untouched.
- Proposed manual, branch-restricted CI is documented in wip/Psych-reference-workflow-proposal.md. It is not installed or executed; native reference instrumentation is specified but activation remains pending user approval.
- Exact original b3b68ac recovery and the published commit mapping are documented in wip/HISTORY.md; the WIP bundle preserves the original object.

## Non-Psych APIs — pending, no new implementation

loadScript, resizeWindow and ending are not registered Psych 1.0.4 functions. With no mod-defined function, calling them raises an attempt-to-call-nil Lua error. They remain pending and were not implemented. ClientPrefs.windowMove is not a Psych field; reflection returns null/nil for a missing field. The existing Light special case is a separate unresolved difference. No extension contract has been activated for these APIs.
