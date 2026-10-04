# Advanced.3 verification

Internal engine version 0.1.16-advanced.3; native workflow Android version code119.

- Twenty registered native suites passed with official Linux LÖVE11.5 under Xvfb: `/workspace/runtime/advanced3-final-all/`.
- Display suite:11/11, exact rendered placement, camera resolution and pointer/touch mapping. Independent two-X11-screen fixture detects2 displays but SDL rejects moving its existing window to screen2; the manager reports failure and restores its old mode. This is not proof of physical-monitor migration or hotplug.
- Three binary Android manifest patch tests passed, and four portable desktop packager tests passed. actionlint and diff checks passed.
- Full actual mod integration exercised boot, menus, credits with embedded Zyn avatar, warning, gameplay, five scenes, pause/resume and end/return. Software graphics/audio-null performance is not a phone benchmark.
- Packed game ZIP integrity passed. All971 original artwork/resource files match the original engine byte-for-byte; only the new toZyn avatar was added. The optional addon is absent from the engine archive.
- Android APK repack replaces embedded game.love and enables the existing GameActivity resizeableActivity boolean. Other manifest content, Java and native libraries are retained. The Android wrapper still has the original manifest version0.1.16/code116; the included full-native-build workflow uses code119. No claim of local JNI rebuild or physical Android testing.
- The original fatal error screen remains. Only isolated script, addon, display-option and known storage failures use recoverable notifications/clipboard. Arbitrary damaged engine state or native OS kills cannot be safely resumed by Lua.
- The optional Wallpaper & Overlay Toolkit is a separate ZIP. Consent-based in-game image backgrounds work. Actual OS overlays and automatic wallpaper retrieval need a native bridge **not supplied here**. Stock LÖVE returns an unsupported recoverable error for these capabilities.

Physical Android, Windows, macOS, iOS, real monitor hotplug and actual native overlays remain unverified. GitHub workflows were edited locally and syntax-checked; repository publishing was not performed.
