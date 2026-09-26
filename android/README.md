# Android launcher

`StoragePermissionActivity.java` is the launcher used by the exported APK. It:

- requests shared-storage access on Android 11 and newer;
- requests legacy storage access on Android 6-10;
- creates `Android/media/<applicationId>/mods`, `addons`, and `saves` automatically;
- starts the embedded LÖVE game after the permission flow returns.

The exported application ID is `fr.stilic.fnflove`, so its data directory is
`Android/media/fr.stilic.fnflove`.

When rebuilding with `love-android` 11.5a:

1. copy `StoragePermissionActivity.java` to
   `love/src/main/java/org/love2d/android/`;
2. apply `allow-android-media-mount.patch` from
   `love/src/jni/love/`;
3. use this directory's `AndroidManifest.xml` as the app manifest;
4. merge `gradle.properties.example` into the template's `gradle.properties`;
5. put the Boon build at `app/src/embed/assets/game.love`;
6. run `./gradlew :app:assembleEmbedNoRecordRelease`.

The PhysFS patch is required because stock LÖVE intentionally rejects mounting
an absolute `Android/media` directory. It only enables paths below
`/sdcard/Android/media/` or `/storage/.../Android/media/` and rejects `..`.

The APK was built with the LÖVE 11.5a Android template (`11.5a`), Android SDK 34,
NDK 25.2.9519653, and JDK 17.
