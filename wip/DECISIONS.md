# Pending decisions

- loadScript, resizeWindow and ending are not registered Psych 1.0.4 functions. No implementation or alias is authorized. Strict Psych calls fail when the mod has not defined the function.
- ClientPrefs.windowMove is not a Psych field. Keep this outside the Psych compatibility inventory; the existing Light special case needs a separate decision.
- No HUD work until explicit user confirmation.
- Core incomplete-data recovery is a Light extension, not Psych behavior; one diagnostic per recovery path is now emitted.

# Fixed scope

All 223 inventoried Lua functions and all exposed globals, callbacks, properties, reflection classes and HScript remain in scope. The corpus is not a boundary. Full compiled-engine comparison is required before claiming parity; inability to compile must be documented with observed blockers.
