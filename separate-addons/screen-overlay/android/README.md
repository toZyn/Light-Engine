# Android image overlay companion

This standalone native companion displays one PNG above the home screen and other apps. It does not render the game or replace the wallpaper. The engine addon sends the original PNG bytes through a custom URI. The companion keeps them in memory and decodes them without creating a rewritten image file.

Install the companion APK and use the `screen-overlay` addon from the game. For every image, the companion asks **Show this image?**. If Android's **Display over other apps** permission is absent, it opens the real permission settings after that image's approval. Grant permission, then return to the companion. Declining permission or cancelling approval shows no image. Existing permission never bypasses the next image's approval.

The image can be dragged when **Allow dragging the image** is checked. Its **×** and the foreground notification's **Stop** control remove it. The window contains only the image and close control, remains transparent around them, and does not take keyboard focus or block the whole display. Android may hide foreground notifications according to notification settings; the close control remains available. Revoking overlay permission stops the service. The service does not restart itself after termination.

## Protocol

```text
lightengine-overlay://show?token=<64 hex>&image=<URL-safe unpadded base64 PNG>&x=<integer>&y=<integer>&width=<integer>&height=<integer>&label=<URL-encoded text>
lightengine-overlay://hide?token=<same 64 hex>
```

All show fields are required. Tokens accept 64 hexadecimal characters and normalize case. PNGs are limited to 256 KiB of original bytes, dimensions from 1 to 4096, and at most 16,000,000 pixels. The PNG signature, IHDR bounds/checksum and canonical base64 are validated before consent. The Android bitmap decoder independently checks bounds and image type before decoding. Display width/height are 1–4096 physical pixels; the actual window is clamped to the screen. Coordinates range from −100000 to 100000 and are clamped when displayed. Labels contain at most 80 UTF-16 code units and no control characters.

Duplicate fields, extra fields, fragments, paths, ports, user information, invalid tokens and non-PNG payloads are rejected. Error messages do not print the original URI, base64 or token. A hide request must match the current or pending image token. It cancels pending consent/permission as well as decoding and active display, so a later grant cannot revive that request. An incorrect token cannot cancel another image's pending approval. The activity uses `singleTask` so hide reaches the existing consent flow while Settings is above it.

The exported activity is the only external entry point. The service is private. The manifest requests only `SYSTEM_ALERT_WINDOW`, `FOREGROUND_SERVICE`, and `FOREGROUND_SERVICE_SPECIAL_USE`. It needs no storage, media, accessibility or Internet permission. The special-use foreground service declares its user-approved image-overlay purpose for Android 14+. Minimum Android is 8.0/API 26; target SDK is 35.

## Ownership and decoding

One decoder thread has a queue of at most one pending task. Replacing or hiding an image cancels old generations and removes cancelled queued work. Bounds and pixel decoding run off the main thread. Decoding retains the complete original pixel dimensions, with sampling and density scaling disabled; the transmitted PNG bytes are never recompressed. The display view fits the image to the requested size. Results are checked again against the current generation and actual overlay permission before installation. Rotation and configuration changes refresh real display bounds and clamp the window and close control to them.

Replacing a displayed image detaches its drawable and recycles its old bitmap. Stale decoded results, queued results, permission revocation and service destruction release their bitmaps. Destruction cancels decoding, clears the result queue, removes the overlay window and notification, and shuts down the worker.

## Build and verification

Sources are Java 8 compatible and use only Android framework APIs plus Java standard APIs available from API 26. No Gradle or external library is required. Compile production sources with a JDK and the API 35 `android.jar`:

```sh
javac --release 8 -classpath "$ANDROID_JAR" -d classes src/com/zyn/lightengine/overlay/*.java
```

The repository companion build tool performs D8 conversion with minimum API 26, AAPT2 manifest linking, ZIP alignment and APK signing. Using `android.jar` alone as javac's boot classpath fails Java lambda compilation because its `LambdaMetafactory` is an Android runtime stub; use the classpath command above and D8 desugaring.

Pure JVM policy tests do not need Android or simulated permission grants:

```sh
javac --release 8 -d policy-classes src/com/zyn/lightengine/overlay/OverlayRequest.java src/com/zyn/lightengine/overlay/OverlaySession.java src/com/zyn/lightengine/overlay/OverlayGeometry.java tests/OverlayPolicyTest.java
java -cp policy-classes com.zyn.lightengine.overlay.OverlayPolicyTest
```

Tests cover PNG byte preservation, invalid/oversized payloads, bounds, field/token validation, explicit consent, denied/granted permission state, pending and active hide, incorrect tokens, replacement generations and revocation. Production Java compiles against Android API 35. Real Android permission screens, bitmap decoding, foreground service restrictions, dragging, notifications and other-app display require device or emulator verification; no such runtime is available in this workspace.
