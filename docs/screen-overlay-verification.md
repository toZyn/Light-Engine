# Image-overlay verification and limits

The new `screen-overlay` addon implements the clarified image-above-other-apps request. The existing advanced.3 engine keeps its shared window/viewport/input adaptation, addon imports, recoverable errors and original fatal-error UI. This change does not alter the game archive or original mod assets.

The standalone Android companion is `com.zyn.lightengine.overlay`, version 1 / 1.0, min API 26, target API 35. It was compiled from the Java and manifest source snapshot recorded in the adjacent APK build JSON, converted by D8, aligned, signed, and independently verified. Its APK contains no native game libraries or `game.love`. Pure JVM validation exercises 37 protocol, unchanged-PNG, consent/permission-state, token, cancellation/generation and rotation-geometry checks. These are logic/build checks; actual Android Settings, WindowManager and foreground service behavior still require device/emulator testing.

The desktop companion uses real PySide6 Qt XCB widgets, explicit consent and paired loopback requests. Tests cover exact original PNG bytes and decoded RGBA pixels, native window flags/geometry/close controls, coexistence with another native window, HTTP-to-GUI delivery, denial, canceled prompts, session release, failed decoding, absolute deadlines and shutdown. Slow-drip request and failed replacement regressions were reproduced before their fixes. Installer tests include actual Linux GIO URI launching with literal special characters in paths. Synthetic smaller-monitor bounds exercise fitting logic; they do not establish physical multi-monitor placement.

The native engine suite uses official LÖVE 11.5 under Linux Xvfb with null audio. Tests isolate released audio sources, render lifecycle, timing, saves, original error UI, addon module scope, resize/input transforms and recoverable errors. The new addon fixture uses actual LÖVE threads and HTTP sockets with original PNG bytes, pending consent, bounded queued work, parent closure, token release and deliberately slow response headers.

Support and limits:

- Android original PNG transport: 256 KiB; one user-approved image with genuine overlay permission, × and foreground Stop control.
- Windows/Linux X11 original PNG transport: 8 MiB; one topmost transparent overlay with native consent. The desktop companion needs a stable Python/PySide6 installation and explicit protocol registration.
- Images: each source axis at most 4096 pixels, at most 16 million pixels. Size limits reject the original image rather than recompressing or downsampling it. Native windows fit the available display; the original PNG and decoded source dimensions remain intact.
- No wallpaper reads or game-background rendering. Importing/enabling the addon does not display an image; the mod calls its API explicitly.
- Android URI launch remains `pending`: it cannot prove acceptance or visibility from Lua. Desktop `accepted` means queued, not compositor visibility.
- OS/window-manager policies can hide or restrict overlays. Wayland and macOS are unsupported by the separate desktop companion. Engine split-screen availability also depends on the device/system.
- Physical Redmi Note 12, Android emulator, Windows GUI and physical multi-monitor tests were unavailable. Do not infer those results from a signed APK or Linux virtual display tests.

Release downloads are compared byte-for-byte with local artifacts and APK signatures/ZIP integrity are checked. A hosting page is never accepted as a successful APK/ZIP download.

Fresh final results (2026-10-03, Linux):

| Check | Result |
| --- | --- |
| Official LÖVE 11.5 engine suites | 21/21, every process exit 0 |
| Android JVM request/consent policy | 37 checks passed |
| Desktop policy/HTTP/deadline | 16 tests passed |
| Desktop URI installer | 4 tests passed |
| Real Qt XCB GUI | 12 tests passed |
| Actual LÖVE thread → Qt consent/image/release | Passed; visible original PNG, empty grants/pending/owner afterward |
| Binary Android resize-manifest fixture | 3 tests passed |
| Android companion build | Signed v2/v3, aligned, ZIP integrity and source snapshot hashes verified |
| Workflows/whitespace | actionlint and git diff --check passed |

Independent review reproduced the blockers, then replayed the final 32 desktop tests and found no remaining critical/important findings. Logs in the source kit document the exact results; they are not physical-device benchmarks.
