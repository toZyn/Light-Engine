# Light Engine: stability and complex mod support

User goal: modify the engine itself to support complex mods and reduce audio, Android and other OS crashes. Preserve existing native mods and the completed Pibby port; retain graphics quality. Deliver reviewable source changes and runnable builds, with actual test evidence and explicit platform limits.

Architecture: fix resource ownership where objects are created; constrain asynchronous work; persist session/error diagnostics independent of mod assets; add an explicit, documented Lua compatibility layer without changing native script semantics. Native camera cancellation, rotated frames and video lifecycle receive regression tests. No arbitrary Haxe execution or claim of universal Psych compatibility.

Components:
1. Sound owns independent Sources; borrowed cached Sources remain cache-owned. Stop before releasing, handle invalid external references safely, and avoid resuming inactive video playback.
2. Async tasks have bounded concurrency and uploads, structured failures and deterministic shutdown; worker references release after channel transfer. Local loads do not require networking modules.
3. Diagnostics persist checkpoints, full Lua/thread/script errors, OS/renderer information, active mod/state and memory. An unclean-session marker means an interrupted run, not proof of a crash. A low-memory callback records and collects Lua garbage without clearing live textures. Error UI has a fallback without mod assets.
4. Compatibility opt-in provides Psych-style property paths, sprites, timers/tweens, sounds, callbacks and camera/HUD access, with clear unsupported-operation errors and examples. Native scripts keep their existing behavior.
5. Fix camera cancellation, stale render queue entries, rotated actor frames, and slow-frame audio rewind after reproductions.
6. Package engine update/builds and document Android/Desktop installation. Do not claim physical OS tests where unavailable or that native process kills can be caught in Lua.

Validation: real LÖVE 11.5 tests for each reproduced failure, an engine-only native menu/song harness, original Pibby full startup/song/retry tests, asynchronous failure/cancel/restart tests, compatibility example and pixel checks for rendering changes. Android SDK/native runtime availability determines which binaries can actually be built; report limits.

User steering: Desktop parity remains a requirement. Deliver native Windows x64 and Linux x64 portable distributions alongside Android. Add explicit active-addon imports with per-script module caching, nesting/cycle diagnostics and close cleanup; namespace addon assets and reusable utilities rather than relying on global addon override precedence. Existing mod require and WIP global-addon execution remain unchanged.
