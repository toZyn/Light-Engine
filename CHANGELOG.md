# Changelog

All notable changes to Light Engine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.16-advanced.8] - 2026-10-04

### Fixed
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
