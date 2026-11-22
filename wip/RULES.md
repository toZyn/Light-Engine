# Compatibility work rules

Target: all Psych Engine 1.0.4 APIs, including Lua, globals, callbacks, reflection classes, HScript and exposed objects/properties. The attached corpus prioritizes work and regression tests; it does not limit scope.

Read the pinned Psych source before changing each family. Match names, types, defaults, returns, errors, initialization and lifecycle. Do not modify mods. Use synthetic fixtures in the repository. Keep non-Psych functions separate and pending approval.

Work one family at a time with separate engine and documentation commits, automatic source-reference comparisons, updated audit rows, and explicit unverified items. Do not describe interpreter-only tests as a compiled Psych game differential. Verify C++ field defaults for the native target. Do not advance to HUD until the user confirms.

Current order: core missing-data crashes; PlayState counters and initial globals; HUD; reflection; notes/strums; text; sprites/cameras/character groups; tweens/timers; events/callbacks; remaining APIs.

No unrelated UI/options or workarounds. Psych detection must eventually be automatic. Report each batch in at most ten lines. Never mark differing behavior resolved. Physical Android tests require an explicit disclosure when not executed.

Never commit external/mods, archives, uploaded scripts, mod assets or screenshots. Local exclusions belong in .git/info/exclude, not the repository .gitignore. Before publication inspect tracked files and the staged diff for secrets and mod payloads. Preserve upstream licenses and attribution for reference excerpts.
