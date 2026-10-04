# Engine Stability and Compatibility Implementation Plan

> For agentic workers: use systematic debugging and test-driven-development for each independently owned component. Parallel work is restricted to separate files; integration and full runtime checks are sequential.

**Goal:** Fix demonstrated engine resource/lifecycle failures and provide documented opt-in complex-mod APIs.
**Architecture:** Native fixes at resource creation/ownership boundaries, bounded asynchronous workers, independent diagnostics, explicit script compatibility.
**Tech Stack:** Lua 5.1/LuaJIT, LÖVE 11.5, existing Android packaging.
**Spec:** docs/superpowers/specs/2026-10-02-engine-stability-design.md

## Global constraints
- Preserve native mods and Pibby v6; do not reduce pixels, resolution or animation frame counts.
- Native Linux runtime is available; physical Android, Windows and macOS are not.
- Never clear textures currently referenced by an active state in a low-memory handler.
- No universal Psych/Haxe compatibility or perfect/all-OS claim.

## Review focus
- Same cached audio used by two live Sound objects: independent playback and cache eviction safety.
- Local loading when HTTPS is missing/broken: succeeds; remote errors complete with diagnostics.
- Exit/cache change during async loading: no stale result resurrects old cache or leaks buffers.
- Released GPU objects left in camera queue and rotated actors: no invalid-object access or altered geometry.
- Error screen when graphics/mod assets fail: error saved before UI; fallback needs no mod resources.

## Task 1: audio ownership and video lifecycle
Files: loxel/sound.lua, video implementation, tests/engine/audio.lua.
- [x] Write/run failing real Source/cache/focus tests.
- [x] Fix ownership and released-reference handling; verify independent streams and cleanup.
- [x] Record validation and commit scoped changes.

## Task 2: bounded asynchronous loading
Files: funkin/backend/paths/{async,thread,init}.lua, tests/engine/async.lua.
- [x] Reproduce missing HTTPS, worker failure, ownership leak and cancellation.
- [x] Bound task dispatch/uploads, transfer references explicitly, handle failures, add shutdown/generation isolation.
- [x] Verify failure progress, restart, late-result disposal and commit.

## Task 3: persistent diagnostics and portable error handling
Files: funkin/backend/diagnostics.lua, main.lua, funkin/init.lua, tests/engine/diagnostics.lua.
Interface: Diagnostics.start(), checkpoint(label), report(message,trace), finish().
- [x] Tests for session marker, saved errors, sanitization, low-memory and fallback.
- [x] Record without requiring mod assets; recover error UI and expose paths in docs.
- [x] Verify and commit scoped changes.

## Task 4: explicit Lua compatibility
Files: new funkin/backend/scripts/compat.lua, tests/engine/compat.lua, docs/modding-compatibility.md, examples/compat-mod/.
Interface: Script environment require compatibility, Compat.new(state,script) installs scoped functions; explicit disposal.
- [x] Write/run missing API tests and native regression tests.
- [x] Implement scoped property paths, sprites, tweens/timers, audio, callbacks, camera access and documented unsupported operations.
- [x] Run real example and commit.

## Task 5: render/camera/slow-frame bugs
Files: loxel/camera.lua, loxel/3d/actorsprite.lua, funkin/states/play.lua, tests/engine/render-lifecycle.lua.
- [x] Reproduce cancelled camera movement, stale render queues, rotated frame failure and update-return on slow frame.
- [x] Minimal fixes, pixel/geometry comparisons, appropriate song resync preserved.
- [x] Verify and commit.

## Task 6: integrate, review, package
- [x] Run native engine tests and original Pibby full startup/song/retries against this worktree.
- [x] Fresh review of whole branch; fix substantiated defects with regression tests.
- [ ] Build runnable artifacts, source patch and installation instructions; report exact tested platforms.
- [ ] Upload requested hosts in order and validate remote hash.

## Accepted additional scope
- [x] Native timer/tween mutation regressions, menu audio asset identity, script traceback persistence and startup logger guards.
- [x] Text, scoped camera effects, song timing, precache and weak/cancellable async context requests; native scene example.
- [x] Reusable Linux/Windows checks gate Release; Android version-code validation/override.
- [x] Thirteen native suites on Linux official 11.5 runtime and mobile loader policy passed.

## Additional accepted scope: reusable add-ons and desktop distribution
- [x] Explicit addon-module loader, native Script bindings, isolated exports/cycles/close and examples.
- [x] Active-addon asset utilities with deterministic namespace/cache lifetime.
- [x] Native regression suites for both helpers, independent review.
- [ ] Rebuild reviewed archive and Android/Windows/Linux distributions; verify assets/signature/structure/launch.
