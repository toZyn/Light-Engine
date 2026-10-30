# Changelog

All notable changes to Light Engine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.2] - 2026-10-30

### Fixed
- **FFT / ABot `Cannot use object after it has been released` crash**
  (`funkin/backend/fft.lua`, `assets/data/classes/abot.lua`, `main.lua`,
  `funkin/init.lua`): `ABot` now binds `FFT` to the persistent Loxel `Sound`
  wrapper (`game.sound.music`) rather than raw `game.sound.music._source`
  userdata (which is released when `PlayState:startSong()` loads `Inst.ogg`),
  guards `isPlaying`/`tell` and mono/stereo `SoundData` reads with `pcall`,
  fixes `normalizedDb` scaling, and shuts down `fftThread` cleanly via
  `FFT.stop()`.
- **Android re-entry immediate exit / kick-out**
  (`android/StoragePermissionActivity.java`, `android/AndroidManifest.xml`,
  `funkin/backend/error-screen.lua`): Added `Application` lifecycle tracking for
  `GameActivity` so cached Linux processes with torn-down `liblove.so` /
  `libopenal.so` / `PhysFS` static singletons exit cleanly once `onDestroy()`
  finishes, while alive backgrounded sessions resume smoothly via
  `FLAG_ACTIVITY_REORDER_TO_FRONT`. Locked `resizeableActivity="false"` for
  strict `sensorLandscape` enforcement and guarded `setFullscreen(false)` in the
  error screen on mobile.
- **Screen Recorder audio sync, fluidity, visual quality & container integrity**
  (`funkin/backend/recorder.lua`, `funkin/backend/recorder_encoder_thread.lua`,
  `funkin/backend/recorder_thread.lua`, `funkin/ui/options/recording.lua`,
  `loxel/sound.lua`, `funkin/backend/paths/init.lua`,
  `funkin/backend/paths/async.lua`):
  - Added real-time 44.1 kHz 16-bit Stereo PCM game audio capture & mixing
    (`01wb` / `WAVE_FORMAT_PCM`) across streamed `Inst`/`Voices`/music and
    in-memory `SoundData` SFX with automatic drift resynchronization, vocal-miss
    muting, and playback-pitch resampling.
  - Replaced same-frame synchronous GPU readback and per-frame camera FBO
    toggling with 2-canvas ping-pong delayed readback, steady camera FBO mode,
    16-pixel aligned dimensions, and monotonic wall-clock frame pacing.
  - Added a multi-core fixed-point integer AAN DCT MJPEG worker pool (`5.4x`
    faster per core, `2-4` parallel workers) with high-quality defaults (`75%`
    HD `960x544`, `60 FPS`, `High` JPEG 88) and English **Record game audio** /
    **Video quality** controls.
  - Eliminated corrupt recordings by fixing `idx1` `movi`-relative chunk offsets
    (`4 + moviDataBytes`), replacing 0-byte drop chunks with valid JPEG frame
    duplication, and periodically checkpointing RIFF/AVI headers on disk.

## [0.2.1] - 2026-10-30

### Added
- **Low-resource Screen Recording** (`funkin/backend/recorder.lua`,
  `funkin/backend/recorder_thread.lua`, `funkin/ui/options/recording.lua`):
  English **Screen recording** toggle in **Options -> Display** that dynamically
  unlocks a dedicated **Recording** tab when enabled and hides it when disabled.
  Supports **Gameplay only (No UI)** (captures only the stage/match and arrows
  with `camHUD` and `camOther` excluded) and **Entire game**, configurable
  resolution scale (`50%`/`75%`/`100%`), frame rate (`24`/`30`/`60 FPS`),
  auto-record gameplay, `F9` hotkey, and off-thread RIFF AVI (`MJPG`/`MPNG`)
  encoding with bounded queue drop-frames to prevent lag or memory spikes.

### Fixed
- **Android / Mobile horizontal orientation & automatic landscape adaptation**:
  Enforced `sensorLandscape` on `StoragePermissionActivity` and `GameActivity`
  (`AndroidManifest.xml`, `StoragePermissionActivity.java`,
  `gradle.properties.example`), prevented LÖVE/SDL2 `resizable=true` from
  unlocking portrait orientation on mobile in `funkin.load()`, and added
  automatic surface-dimension resize detection plus `Transition` bounds updates
  so delayed Android surface rotations adapt `game.width` immediately.
- **OpenGL ES 3.0 shader & Weekend 1 / Week 6 fixes**: Fixed `S0023` precision
  qualifier conflicts in `rain.frag` and `wiggle.frag`, added GLSL ES source
  sanitization and safe compilation fallback in `Shader`, fixed `PlayState`
  `93%` `LoadScreen` stall by detecting `images/<sprite>/Animation.json` for
  `AnimateAtlas` characters and preloading `ABot`, silenced optional vocal/icon
  preload probes, added `icons/icon-*` fallback in `HealthIcon`, and fixed
  `phillyStreets.lua`, `puddlething.lua`, `abot.lua`, `darnell-blazin.lua`,
  `pico-blazin.lua`, `tankmengroup.lua`, `dialoguebox.lua`, and `guns.lua`.

## [0.2.0] - 2026-10-30

### Added
- Rebuilt **Chart Editor** (`ChartingState`) around the native `PlayState.SONG`
  schema with viewport-culled timeline rendering, 9 interactive tracks (events +
  enemy + player), `1/4`–`1/64` quantization, note types, mouse/keyboard sustain
  resizing, undo/redo (`Ctrl+Z`/`Ctrl+Y`), section copy/paste/swap/mirror,
  hitsounds, metronome, `0.25x`–`2.0x` playback speed, instant playtesting, and
  lossless cross-platform JSON export (`Ctrl+S`).
- Completed **Character Editor** **Animations** tab (create/update/delete
  animations, XML prefixes, frame indices, FPS, loop, live offsets), ghost /
  onion-skin reference (`G`), and cross-platform JSON export.
- Rebuilt **Stage & Cutscene Editor** (`CutsceneState`) with stage inspection,
  camera keyframe capture, live preview (`P`), and JSON export.
- Rebuilt **Editor Menu** (`EditorMenu`) with shortcuts from Main Menu (`7`/`8`),
  Freeplay (`7`), and Gameplay (`7`/`8`).
- Global **`Mod` Lua API** (`funkin/backend/modding/api.lua`) for sprites,
  graphics, text, tweens, timers, sounds, camera flash/shake/zoom, character
  swaps, chart events, persistent mod data, and mod template generation.
- Mod template scaffolder both in-game (`N` in `ModsState`, `Create New Mod` in
  `EditorMenu`) and via CLI (`tools/create_mod.py`), plus Spanish modding and
  editor documentation (`docs/crear-mods.md`).
- Automatic Freeplay discovery of standalone `songs/<song>/` folders without
  requiring a `week.json`, `pack.json` / `pack.png` metadata fallback, simple
  native JSON stages, `.ogg`/`.wav`/`.mp3` audio fallback, auto-loaded
  `data/notetypes/<type>.lua` scripts, and 5 additional built-in chart events
  (`Add Camera Zoom`, `Change Character`, `Camera Flash`, `Screen Shake`, `Hey!`).
- Release workflow now publishes the standalone `.love` archive, a modding kit
  (`Light-Engine-<version>-modding-kit.zip`), bundled docs/tools/examples inside
  portable desktop archives, and automatic version revision tags when merging to
  `main` over an already-published version.

### Fixed
- Overhauled all 10 `loxel/ui` widgets (`UIGrid`, `UIButton`, `UICheckbox`,
  `UISlider`, `UIInputTextBox`, `UINumericStepper`, `UIDropDown`, `UITabMenu`,
  `UINavbar`, `UIWindow`) for batched rendering, container/camera coordinate
  propagation, clipboard shortcuts, float rounding, and dropdown input priority.
- Eliminated redundant per-frame `texture:setFilter` calls in `Sprite`, `Note`,
  and `Text`, per-frame table allocations in `Camera:shake` and `Text:__render`,
  `Color.fromHSL` saturation-zero bug, and shared multi-atlas `Quad`
  double-release in `Frame:destroy()`.
- Fixed `Notefield:update` early return that throttled active note/modifier
  updates to 10 FPS, added `Notefield:seekTo`, fixed 3D sustain shader reference,
  fixed `PlayState` `startPos` units, $O(1)$ event cursor, `nfTime` hit accuracy,
  `JSONBuilder` RFC 8259 string escaping, `vanilla.lua` `timeChanges` sorting,
  and menu `Throttle` cleanup.

Android version code: 200.

## [0.1.16-advanced.8] - 2026-10-04

### Fixed
- Destroyed menu-repeat controls are removed and safely recycled.
- Desktop overlay HTTP timeouts end the request without a second retry.
- Menu navigation consumes a quick direction tap once, including presses that
  end before an update. Held keys retain the existing repeat delay.
- Portrait windows retain the full logical game viewport and letterbox it,
  keeping menus and gameplay visible when Android rotates the device.

Android version code: 124.

## [0.1.16-advanced.7] - 2026-10-04

### Fixed
- Quick keyboard taps now retain both press and release events until the next
  update, so menu and pause actions are not lost between frames.
- Release archives exclude downloaded build icons and nested editor settings.

Android version code: 123.

## [0.1.16-advanced.6] - 2026-10-04

### Added
- Shared window resizing, input transforms, desktop monitor controls and
  Android split-screen support where the operating system permits it.
- Scoped addon imports, reusable modules and assets, dependency checks and
  recoverable notices for missing addons without closing the engine.
- Recoverable script-error notices, clipboard reports and guarded diagnostic
  writes, while retaining the original fatal error screen.
- Zyn / toZyn credits with the locally bundled GitHub avatar.
- A separate optional screen-overlay addon with Android permission/consent
  handling and Windows/Linux X11 companions. It is not integrated into the game.
- Native regression gates and portable Windows/Linux/Android release packaging.

### Fixed
- Audio source lifetimes, playback ownership and menu music cleanup.
- Timer/tween callback mutation, cancelled camera movement, destroyed render
  entries, false property values and slow-frame gameplay timing.
- Bounded async asset loading, cancellation, worker errors and video completion.
- Denied/corrupt save handling that preserves live progress and reports failures.
- Android APK assets load directly without copying the entire game archive into
  app-private cache; original resource bytes are preserved.
- Android storage creation now attempts `.nomedia` immediately after the app
  folder, before `mods`, `addons` and `saves`, in both Java and Lua. Existing
  marker contents are preserved and failure does not block gameplay.

Comparison with official 0.1.16: [release comparison](docs/release-comparison.md).
All original `assets/` and `art/` files retain their bytes; only the new credit
avatar is added. Native OS/driver crashes remain outside Lua recovery. Physical
Redmi, Windows and multi-monitor validation is not claimed. The overlay desktop
companion does not support macOS or Wayland. Full native Android builds use
version code 122; previously distributed repacked APKs are not this release.

## [0.1.16-advanced.1] - 2026-10-02

### Added
- Scoped opt-in Lua mod helpers for properties, sprites/animations, layering,
  timers/tweens, tagged audio, text, camera effects and asset preparation.
- Persistent engine, worker and script errors with full Lua traces and a
  built-in-font error screen independent of mod assets.
- Native regression suites and release gates for Linux and Windows; mobile
  loader policy checked on Linux. Android version code supports explicit overrides.

### Fixed
- Cached audio Source lifetime, independent playback, menu music identity,
  focus-resume behavior, video completion and destruction.
- Callback mutation crashes in native timers and tweens, inherited false
  property values, cancelled camera movement and destroyed render queue entries.
- Rotated ActorSprite atlas frames and per-frame texture selection.
- Slow gameplay frames no longer rewind music or starve gameplay updates.
- Bounded/cancellable async decoding and uploads, structured failures,
  streamed URL Sources, channel buffer ownership and AnimateLibrary async loading.

Runtime assets retain their original bytes and quality. Physical Android,
Windows and macOS validation is still required; native OS/driver crashes are
outside the Lua recovery boundary. See docs/engine-stability.md.

## [0.1.16] - 2026-09-28

### Fixed
- Restored the FNF title logo and the animated `logoBumpin` atlas, which had been
  replaced by a 1x1 placeholder frame
- Week 6 (`Senpai`, `Roses`, `Thorns`) had no dialogue files, so the cutscenes
  opened an empty text box
- `DialogueBox` applied the wrong variable to animation offsets, overwrote
  `animation.onFinish` instead of registering a listener, tried to play an
  `enter` animation on the static hand sprite, and inserted empty lines as
  dialogue entries
- Cutscene scripts `ugh` and `guns` assigned `tankman` as a global, so the
  sprite was `nil` inside their timed callbacks and the cutscene crashed
- The character editor crashed on startup because `ui.UITabMenu` was never
  implemented or exported; it is now available in `loxel/ui/tabmenu.lua`
- The character editor now exposes the animation offsets, position, sprite and
  JSON flags, applies offset edits to the live animation, and keeps them when
  saving the character JSON
- `PlayState` only called `postCreate` on the final cutscene, so every earlier
  cutscene never finished setting itself up
- `Skin:get` tried to load `default-pixel/healthBar`, which does not exist, and
  logged a null-value warning before falling back to the `default` skin

## [0.1.15] - 2026-09-28

### Fixed
- `project.lua` was missing a comma, so the game could not be loaded at all
- Release workflow uploads every binary (Windows, Linux, Android) together with
  `CHANGELOG.md` to the GitHub release
- Release notes come from this file instead of a generated `release_body.md`
- `game.love` again contains the Lua sources, assets and `lib/`; the previous
  archives shipped no code, which made every binary fail to start
- Linux builds use the official LÖVE 11.5 AppImage as the runtime, since 11.5
  does not publish a `linux-x86_64.tar.gz`
- Android APKs are signed with a stable keystore instead of a throwaway debug
  key, so updates install over older versions
- Binaries use `art/logo.png` as their icon instead of the 16x16
  `art/icon.png` (Windows executable, Android launcher, AppImage and desktop entry)

### Added
- Windows builds for x64 and x86
- Linux portable tarball and AppImage builds
- One Android APK per ABI (`arm64-v8a`, `armeabi-v7a`) plus a universal APK
- `SHA256SUMS.txt` attached to every release
- `tools/make_game_love.py`, which builds the game archive for every platform

## [0.1.6] - 2024-XX-XX

### Changed
- Fixed GitHub Actions workflow for all platforms
- Windows: Fixed love.exe path detection
- Linux: Updated to use LÖVE 12.0 AppImage
- Android: Fixed Gradle caching

## [0.1.4] - 2024-XX-XX

### Changed
- Removed external changelog-reader-action dependency
- Changelog now generated from git log automatically

## [0.1.3] - 2024-XX-XX

### Added
- GitHub Actions release workflow with fixed YAML syntax
- Automated builds for Android, Windows, and Linux
- Release artifacts attached to GitHub Releases

## [0.1.2] - 2024-XX-XX

### Added
- GitHub Actions release workflow
- Automated builds for Android, Windows, and Linux
- Release artifacts attached to GitHub Releases

## [0.1.1] - 2024-XX-XX

### Changed
- Version bump to 0.1.1

## [0.1.0] - 2024-01-XX

### Added
- Initial release of Light Engine
- Rebranded from FNF LOVE to Light Engine
- New package name: `com.zyn.lightengine`
- Custom app icon from art/icon.png
- New Light Engine logo on splash screen and title screen
- Updated credits:
  - Zyn as Owner Actual
  - FNF Love Team as Base Engine Team
- Cross-platform storage support (Windows, Linux, macOS, Android)
  - Automatic creation of mods/addons/saves folders
  - Uses `%APPDATA%` on Windows, `$HOME` on Linux/macOS
- Fixed Week 6 dialogue issue (Senpai, Roses, Thorns)
  - Graceful handling of missing dialogue.txt files
- Android build system updated with new branding
- Windows and Linux build support via GitHub Actions

### Changed
- App title: "Friday Night Funkin' Light Engine" → "Light Engine"
- Window title and package name updated
- Error screen logo updated to new Light Engine logo
- Title screen logo (logoBumpin) updated to new logo
- Android application ID changed from `fr.stilic.fnflove` to `com.zyn.lightengine`
- Updated Android manifest and gradle properties
- Updated build scripts for new naming convention

### Fixed
- Storage initialization on desktop platforms
- DialogueBox crash when dialogue.txt is missing
- Directory creation with proper permissions on Windows/Linux
