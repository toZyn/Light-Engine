# Core and globals audit

## Core menu asset batch — 2026-11-22

| Surface | Light location | Verified behavior | Difference from Psych 1.0.4 |
|---|---|---|---|
| Title intro text | funkin/backend/menuassets.lua:3; funkin/states/title.lua:92 | Base entries then current mod entries, trimmed and deduplicated; literal `--` delimiter; empty mod retains base entries | Only current mod and base, not all global mod directories. Both sources empty returns two empty strings instead of failing selection. |
| Week menu character | funkin/backend/menuassets.lua:31; funkin/ui/storymenu/character.lua:23 | Mod first then base path; Psych `image` uses `menucharacters/`; native `sprite` retains native directory | Missing/invalid fields recover from base BF. Psych MenuCharacter does not validate incomplete JSON and can fail after parsing; this recovery is explicitly requested Light behavior. |

Source comparison: Psych tag `1.0.4`, commit `5c67ced49e5a98535298a6daa3f8f4ec79ac8399`: `TitleState.getIntroTextShit`, `Mods.mergeAllTextsNamed`, `CoolUtil.listFromString`, `MenuCharacter.changeCharacter`.
The uploaded three ZIPs contain neither introText.txt nor menu-character JSON. The exact offending input is not available; empty intro text and missing sprite/image are reproduced fixtures, not an attribution to a specific mod file.
Validation: native LÖVE 11.5 `menu-asset-fallbacks` (2 checks), `menu-regressions`, `syntax` pass. Full compiled Psych differential execution and Android touch/render verification have not been performed.

## Counter/global initialization batch — 2026-11-22

`funkin/backend/scripts/psych/globals.lua` initializes state before script loading and inserts constructor globals before executing Lua source. `handler.lua` no longer reads strum positions during onCreate/onCreatePost; positions are captured at countdownStarted.

| Rows affected | Initialization result | Remaining difference |
|---|---|---|
| score, misses, hits, combo; PlayState.songScore/songMisses/songHits/combo | Zero at script source execution and onCreate; native getProperty aliases tested | Full mutation/callback timing and scoring differential execution remain unverified. |
| rating, ratingName, ratingFC; PlayState.ratingPercent/ratingName/ratingFC | Original declarations compiled with Haxe interpreter: null, `?`, null | Native C++ defaults and complete RecalculateRating lifecycle are not verified; do not treat these rows as resolved. |
| totalPlayed, totalNotesHit; corresponding PlayState fields | Zero before source execution | Hit/miss accumulation still differs; not resolved. |
| scrollSpeed | Initial value comes from chart.speed | Event-driven updates not verified. |
| defaultPlayerStrumX/Y0–3, defaultOpponentStrumX/Y0–3 | Loop creates all 16 names with zero before source execution; no onCreatePost overwrite | Actual countdown positions and late-loaded-script differential execution remain unverified. |
| curDecBeat, curDecStep, healthGainMult, healthLossMult, playbackRate, inGameOver, botPlay, practice, instakillOnMiss, guitarHeroSustains | Constructor values now inserted | Nondefault gameplay settings and native reference execution remain unverified. |

Automated reference: `tests/reference/psych104/ReferenceInitialization.hx` contains nine unchanged field declarations from Psych 1.0.4 PlayState. `generate.py --check` executes this reference plus prior utility/input/file references. This is not a compiled Psych game executable. Native LÖVE checks cover script source initialization and handler onCreate/onCreatePost dispatch. The family remains open: full globals, character coordinates, rating lifecycle and requested compiled-engine differentials are pending.

## Non-Psych extension decision (not implemented in this batch)

`loadScript`, `resizeWindow`, and `ending` are not registered Psych 1.0.4 functions. Without a mod-defined function, a Lua call raises an attempt-to-call-nil error. `ClientPrefs.windowMove` is not a Psych ClientPrefs field; class reflection returns null/nil for this absent field. Proposed separate optional extension contract: namespaced `LightExtensions.loadScript/resizeWindow`, documented return/error contracts, no implicit aliasing of `ending` or unknown properties. Awaiting user decision; existing non-Psych behavior has not been changed.
