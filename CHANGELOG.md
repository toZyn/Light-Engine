# Changelog

All notable changes to Light Engine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.4] - 2026-10-30

### Corregido
- **Sincronización A/V exacta, retención de frames caídos, audio de videos `.ogv` y limitador `< 0 dBFS` en el grabador `.mp4`**
  (`funkin/backend/recorder.lua`, `funkin/backend/recorder_thread.lua`,
  `funkin/backend/recorder_encoder_thread.lua`, `funkin/backend/mp4_muxer.lua`,
  `funkin/backend/video.lua`, `android/jni/lightrecorder.c`, `loxel/sound.lua`):
  - Unificado el reloj maestro de captura (`sessionClock` con deltas acumulados de
    `love.update(dt)`) para video y audio tanto en Desktop (`mp4v` + `alac`) como en
    Android (`AMediaCodec` H.264/AAC + `AMediaMuxer`), eliminando el desfase inicial de
    `-46 ms` a `-63 ms` y la deriva de voces de hasta `+315 ms` al fallar notas (≤ `1 ms`
    de offset en inicio, mitad y final incluso en canciones >3 min).
  - Mantenidos en el snapshot de audio los stems temporalmente silenciados (`volume == 0`
    tras fallar notas en `PlayState`) para que sus cursores de decodificación avancen en
    bloqueo de fase sin requerir re-seeks bruscos al recuperar volumen.
  - Corregido el manejo de caídas de FPS (`frame drops`): al omitirse `N` intervalos de
    captura, el muxer ahora duplica el **frame anterior** durante los intervalos omitidos
    (y en Android presenta el `last_frame_rgba` con sus `pts_us` explícitos) en lugar de
    adelantar el frame siguiente `N` ticks antes que el audio.
  - Capturado el audio Vorbis embebido en cutscenes `.ogv` (`Video._active` + decodificación
    streaming), preservada la frecuencia nativa de `44.1 kHz` o `48 kHz` sin remuestreo
    innecesario, y añadido limitador suave de headroom (`-1.0 dBFS` techo, rodilla suave
    desde `-3.0 dBFS`) eliminando el recorte digital (`0.00 dBFS` hard clip) al sumar
    instrumental + voces + SFX.
  - Corregida la velocidad/pitch de audio grabado (`playback`), eliminados los pantallas
    negras en `pixelPerfect` (`6x` composite) y forzada escala nativa `1.0x` por defecto
    con exclusión total de UI en modo `Gameplay only (No UI)`.
- **Restauración de niveles base, Week 6 (`thorns`), hitboxes táctiles, audio y editores (PR #12 / PR #13)**:
  - Restaurados los niveles y personajes base (`REG-LEVELS`) exactamente a la referencia
    estable `v0.2.2`, eliminado el bloqueo en `thorns` (`CRIT-THORNS`), corregida la
    proyección mundo/pantalla de `DialogueBox` y controles táctiles/mouse (`B4`), aislado el
    guardado de editores en `saves/ > mods/ > assets/` (`B5`), unificada la pausa en teclado,
    gamepad y botón táctil (`B6`), y endurecida la salida limpia en Android (`GameActivity`
    re-entry) y el manejo de errores visibles en `TimerManager`.
- **Crashes de audio, calibración, Game Over, Pausa, Notefield y Story Mode (Fase 2)**:
  - `SoundManager.load/play/loadMusic/playMusic` ahora maneja activos `nil` de forma segura
    sin lanzar `attempt to index a nil value`, y `CalibrationState` carga la pista real
    `chartEditorLoop` con volumen normalizado (`musicVolume / 100`).
  - Añadido alias `music/gameOverend-pixel.ogg -> music/gameOverEnd-pixel.ogg` para evitar
    el crash al reintentar en Week 6 (`senpai`, `roses`, `thorns`) en sistemas sensibles a
    mayúsculas (Linux y Android), precargado `AnimateAtlas` en `PlayState:tryGameOver()` sin
    falsos avisos `image not found`, evitado el softlock si falta el JSON de muerte, y añadido
    fallback automático a `bf-dead` en `Character` cuando el sprite de un personaje `-dead`
    no existe en disco (como `bf-holding-gf-dead`).
  - Protegido `PauseSubstate` cuando `pauseMusic` es `"none"` o apunta a una pista ausente
    (con fallback a `railways`), protegido el acceso a `PlayState.SONG` y cancelados los
    temporizadores de transición de música al cerrar el menú de pausa.
  - Protegidos `Notefield:getNotes/seekTo/update/__render` tras `Notefield:destroy()` y
    `ScriptsHandler` tras `ScriptsHandler:close()`.
  - Reiniciado `PlayState.storyScore = 0` al iniciar o completar una semana en `Story Mode`
    para evitar que la puntuación de semanas previas se acumule en semanas posteriores.
  - Generado icono de carga procedural `54x54` de respaldo en `CreditsState` (`UserList`),
    eliminando los 13 avisos `image not found: menus/credits/icons/loading` y corrigiendo el
    colapso de altura de tarjetas cuando no hay conexión HTTPS.
  - Migradas las llamadas obsoletas de Loxel (`setScrollFactor`, `addAnim*`, `play`, `finish`)
    en menús, opciones, cutscenes y clases auxiliares (`backgroundgirls`, `tankmengroup`), y
    corregido el orden de argumentos de `animation:addByIndices` en `Stage`.

### Cambiado
- **Perfil de grabación por defecto (`recordingProfileVersion = 4`)**: resolución nativa
  `1.0x`, `60 FPS`, calidad `high` y captura de audio activada por defecto; la pestaña de
  opciones de grabación permanece íntegramente en inglés y solo aparece cuando
  `Screen Recording` está habilitado.

### Añadido
- **Nuevas suites y casos de regresión en `tests/engine/recorder-and-fixes.lua`**:
  cobertura automatizada para ALAC estéreo nativo a `48 kHz`, retención del frame previo ante
  caídas de FPS, avance de cursores en stems silenciados, limitador `< 0 dBFS`, seguimiento de
  `Video._active`, `SoundManager` ante activos `nil`, `CalibrationState`, alias de Game Over
  pixel, fallback de `bf-holding-gf-dead`, `PauseSubstate`, `Notefield:destroy()`,
  `ScriptsHandler:close()`, `PlayState.storyScore` y `CreditsState`.

### Conocido
- Los scripts base de escenarios en `assets/data/stages/*.lua` mantienen llamadas heredadas a
  helpers deprecados de Loxel (`setScrollFactor`, `addAnimByPrefix`, `play`, `finish`) que
  emiten avisos `[WARN]` en consola sin afectar la jugabilidad; se conservan intactos por
  política de inmutabilidad de niveles base respecto a `v0.2.2`.
- `assets/data/characters/bf-holding-gf-dead.json` referencia el atlas ausente
  `characters/bfHoldingGF-DEAD`; el motor mitiga esto automáticamente en tiempo de ejecución
  recurriendo a `bf-dead` con animación y música de Game Over completas.

## [0.2.3] - 2026-10-30

### Fixed
- **Fluid `.mp4` Screen Recorder with stereo audio & guaranteed match/manual saving**
  (`android/jni/lightrecorder.c`, `funkin/backend/mp4_muxer.lua`,
  `funkin/backend/recorder.lua`, `funkin/backend/recorder_thread.lua`,
  `funkin/backend/storage.lua`, `.github/workflows/release.yml`):
  - Switched all screen recordings to ISO-BMFF **`.mp4`** video with synchronized
    44.1 kHz Stereo audio (`liblightrecorder.so` on Android using OpenGL ES 3.0
    triple-buffered `GL_PIXEL_PACK_BUFFER` zero-stall async DMA readback +
    hardware `AMediaCodec` H.264/AAC + `AMediaMuxer`; pure-LuaJIT ISO-BMFF
    `mp4v` + lossless stereo `alac` muxer on Desktop and universal fallback).
  - Fixed recordings failing to save or appearing missing: `Storage.getRecordingsDir()`
    now writes to gallery-visible `Movies/LightEngine` on Android (and
    `Videos/LightEngine` / `recordings` on Desktop), `Recorder.onSongEnd()` and
    `Recorder.toggle()` flush synchronously (`Recorder.stop(true)`) even when
    armed manually before entering a song, and `waitForSessionFlush` waits for
    terminal session completion instead of returning early on `"started"`.
- **Editors crashes & full mobile/keyboard usability**
  (`loxel/sound.lua`, `loxel/init.lua`, `loxel/ui/{inputtextbox,numericstepper,dropdown}.lua`,
  `funkin/ui/editor/editormenu.lua`, `funkin/states/editors/{charting,character,cutscene}.lua`,
  `funkin/states/play.lua`):
  - Fixed `charting.lua:1209: attempt to call method 'seek' (a nil value)` by
    adding LÖVE `Source`-compatible `:seek`, `:tell`, `:getDuration`,
    `:setVolume`, `:setPitch`, and `:setLooping` methods to Loxel `Sound`.
  - Fixed `play.lua:471: bad argument #1 to 'ipairs' (table expected, got nil)`
    when switching directly from editors into `PlayState` by auto-running
    `PlayState:preload()` in `enter()` and supporting numeric `startPos` in
    `PlayState:new(false, startMs)`.
  - Synced `game.mouse.onMoved(x, y)` inside `mousepressed`/`mousereleased` so
    first-tap mobile touches hit buttons/tabs accurately, wired Android soft
    keyboard + `TextInput` into `UIInputTextBox` and `UINumericStepper`, added
    touch drag-scrolling to `UIDropDown`, fixed `CutsceneState:applyPositionsToActors`
    `_baseOffset` math, and added touch transport/zoom/exit buttons across
    `EditorMenu`, `ChartingState`, `CharacterEditor`, and `CutsceneState`.
- **Animation & character script crashes**
  (`loxel/animation/instance.lua`, `funkin/gameplay/character.lua`,
  `assets/data/events/{playanimation,hey}.lua`, `funkin/backend/scripts/compat.lua`,
  `assets/data/characters/{nene,darnell-blazin,pico-blazin}.lua`):
  - Fixed `loxel/animation/instance.lua:20` boolean comparison crash, coerced
    legacy 3-arg `:playAnim` calls safely, guarded nil `curAnim` in character
    scripts, and added safe `bf-dead`/`bf` fallbacks for missing `-dead`
    character sprites.
- **External USB/Bluetooth keyboard, startup black screen & error-screen fixes**
  (`android/AndroidManifest.xml`, `android/StoragePermissionActivity.java`,
  `loxel/init.lua`, `loxel/input/keyboard.lua`, `loxel/virtualpad.lua`,
  `lib/baton.lua`, `funkin/init.lua`, `funkin/backend/{clientprefs,error-screen,diagnostics}.lua`):
  - Removed `USB_DEVICE_ATTACHED` activity hijacking and expanded `configChanges`
    so connecting a physical/Bluetooth keyboard never recreates `GameActivity`;
    hardened `Keyboard`, `VirtualPad`, `baton`, and `PlayState` for unknown
    keys, `acback`/`kpenter`, key-repeat suppression, vararg `isDown`, and
    simultaneous touch + keyboard input.
  - Eliminated mobile portrait/black-screen startup deadlocks by disabling
    mobile `autoPause` spin-waiting, waiting for landscape display metrics in
    `StoragePermissionActivity`, and removing mid-frame `love.window.updateMode`
    GL context destruction on Android.
  - Flushed queued gameplay touches (`love.event.clear`) on error screen entry
    and guarded audio/focus redraws so errors stay visible instead of
    backgrounding or prompting quit immediately.
- **Stage & character positioning across all weeks**
  (`funkin/gameplay/{stage,character}.lua`, `funkin/backend/parser/**`,
  `assets/data/stages/*.lua`):
  - Fixed `AnimateAtlas` world-space `getMidpoint` and `VSlice` anchoring,
    preserved `Point` instances across all stage scripts (`stage`, `spooky`,
    `philly`, `limo`, `mall-evil`, `tank`, `test`), fixed Week 6 widescreen
    pixel camera sizing & `gf-pixel` scaling, and resolved V-Slice `erect` /
    `nightmare` metadata, `STAGE_MAP`, and `"pico" -> "pico-playable"`.

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
