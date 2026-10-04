# Android assets remain inside the application

The Android package now uses LÖVE 11.5a's official direct-asset layout: `assets/main.lua`, `assets/conf.lua`, `assets/project.lua` and the rest of the runtime. The native AAsset archiver reads them from the installed APK. There is no nested `assets/game.love` for GameActivity to copy to its private cache.

Investigation of the previous delivered APK confirmed that its resources were already included in `assets/game.love`. Its unchanged GameActivity DEX copies that complete archive to Android `getCacheDir()/game.love` during startup. This is app-private cache, not an extraction of every image/music file into shared storage. The inspected Lua storage backend and Android launcher create `mods`, `addons` and `saves` under `Android/media/com.zyn.lightengine`; they do not export original assets.

## Gallery indexing of external mods

Android can index images and audio in that shared folder. The shared storage backend and Android launcher now create `.nomedia` immediately after creating the app content root, before preparing `mods`, `addons` or `saves`. The marker covers those subfolders without hiding other apps' media. Existing marker contents are preserved; inability to create or close it is logged and does not disable mods or stop the game. Windows/Linux do not receive this Android marker. No mod image, audio file or save is changed, moved or deleted. The previously distributed advanced.5 APK creates its marker later, before mounting; this ordering correction in Java requires a native rebuild through the release workflow.

For an already installed version, create an empty file named exactly `.nomedia` (without `.txt`) in `/storage/emulated/0/Android/media/com.zyn.lightengine/`. Existing gallery entries may remain cached until the gallery or Android refreshes its media index. Restarting the device may help, but immediate disappearance cannot be guaranteed for every gallery app. Mods remain accessible in a file manager. The small gallery-fix ZIP contains only `com.zyn.lightengine/.nomedia`: extract it into `Android/media`, not into `mods`.

Reference: [LÖVE Android 11.5a packaging](https://github.com/love2d/love-android/tree/11.5a), README's embed option 1. LÖVE 11.5 `Filesystem::setSource` and `android::checkFusedGame` provide the `assets/main.lua` → native AAsset virtual-archive branch.

The repacker and native workflow use the same asset layout. PNG/audio/video files retain their original bytes; already-compressed media is stored in the APK without another ZIP compression layer to permit direct seeking. Other runtime files may use lossless ZIP compression. Windows/Linux runtime archives remain unchanged apart from the engine version. Mods/add-ons remain separate user content; no existing user files are removed or migrated by this change.

Updating the APK does not automatically remove an old private `game.love` cache file. After installing the update, Android Settings → Apps → Light Engine → Storage → **Clear cache / Borrar caché** removes that obsolete cache. Do not select **Clear data / Borrar datos**, which resets application data. Clearing cache does not remove the installed APK or saved progress in the engine's saves folder.

Verification:

- All 1,173 runtime files in the signed APK match their source archive byte for byte; no `assets/game.love` or duplicate APK entries.
- All 380 original DEX, JNI, Android resources and resource-table entries match the base APK. The original signing certificate and 16 KiB native ZIP alignment are verified.
- Three direct-asset staging/repacking regressions and three Android resize-manifest tests pass; malformed/traversal inputs fail before staging.
- All 21 native engine suites pass using official LÖVE 11.5 under Linux Xvfb. The actual engine starts, creates its state and reads resources from a staged direct-asset tree. That Linux test does not exercise Android's AAsset implementation.
- The prepared runtime version is `0.1.16-advanced.6`; the full native GitHub build uses version code 122. Previously distributed repacked APKs retain the original wrapper metadata `0.1.16` / 116 and are not this new native release.
- Storage regressions cover Android marker creation, preservation of an existing marker, denied/throwing opens, failed closes, continued mod availability, and absence of a marker on desktop. These are Linux-hosted Android storage simulations, not a physical gallery test.
- Physical Android boot remains untested. No claim of device-specific results or cleanup of an unidentified public folder is made.
