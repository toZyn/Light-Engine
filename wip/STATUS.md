# Work status

| Batch | Local commit | Published commit | Verification | Not verified / remaining |
|---|---|---|---|---|
| Lua input/utilities | b3b68ac | 44241ec | Haxe callback references and native tests | Full compiled Psych; physical input; documented behavior differences remain |
| Core menu assets | 44b7449 | 5733096 | Missing/empty text, missing/incomplete JSON fixtures; menu/syntax suites | Exact original failing input unavailable; global-mod text merge absent; Light recovery differs from Psych |
| Counter/global initialization | 0665ade | 60cb9bc | 36 Light suites; 147 reference cases including nine Haxe interpreter declarations | Superseded native-default inference; see correction below. Full globals, character coordinates and rating lifecycle remain open |

No full Psych executable has been built. No Android device/Mali/touch verification has been performed. HUD work is not authorized yet. The current reference harness compiles isolated Haxe declarations/callback bodies; it is not the full engine.

Published commits reproduce the corresponding local trees with different metadata/hashes. The backup branch starts from the published counter/global tree. main and the PR #22 branch are not changed.

Backup preparation: reference excerpt legal notices and README updated in a separate engine/test commit; no mod payloads added.

## Native-default and menu-extension correction

Engine/test commit: 251956a78838dd8c1bac5ae584cb4b5485817a21. Haxe C++ generated types and a compiled zeroed-allocation probe give Float 0, Int 0, Bool false; ratingPercent corrected to 0. This is not a full hxcpp or Psych executable. Strum constructor zeros retained after source review; coordinates assigned in startCountdown. Menu recovery warnings deduplicate by path. Five targeted native suites passed; 138 callback reference cases and nine C++ fields plus Bool passed. Full Psych build blocked by libneko/haxelib and missing validated dependencies/toolchain; Android and whole-mod runs unverified. HUD not started.
