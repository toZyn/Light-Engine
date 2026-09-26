# Changelog

All notable changes to Light Engine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
