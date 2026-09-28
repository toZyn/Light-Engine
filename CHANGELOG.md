# Changelog

All notable changes to Light Engine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
