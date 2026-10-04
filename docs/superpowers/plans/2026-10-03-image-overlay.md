# Image overlay implementation plan

Goal: implement the clarified image overlay as a separate addon and real companion apps, without wallpaper/game background features.

- [x] Android: Java request validation+consent/session tests; exported URI activity; real OS permission; specialUse foreground service, single bounded decoder, draggable PNG and close/notification; compile/sign/validate APK.
- [x] Lua: scoped addon imports, original PNG validation/readers, Android pending intent transport, desktop bounded asynchronous HTTP transport, errors reported recoverably, close/listener/worker lifecycle tests.
- [x] Desktop: paired token-only loopback protocol and Qt translucent window, native consent; explicit URI installer, Wayland unsupported path; HTTP and native GUI tests.
- [x] Integration: register native addon tests, update release workflow to publish optional companion/addon separately, package ZIP and source, verify public downloads and native engine regression suite.

Verification completed: native LÖVE 11.5 21/21 suites; JVM 37 checks; desktop 32 tests; actual Qt/LÖVE original-PNG delivery and complete release; signed/aligned separate APK. Independent review found no remaining critical/important issues. Physical Android/Windows runtime tests remain unperformed, as documented. Distribution integrity is verified before final delivery.
