# Android build assets

This directory contains the project-specific launcher, manifest, Gradle values,
and the PhysFS patch needed to build the embed APK with `love-android` 11.5a.

Use `tools/build-android.sh` with `LOVE_ANDROID_DIR` and `ANDROID_SDK_ROOT` set.
The script applies the storage mount patch, copies the launcher and manifest,
creates the Boon `.love`, and runs the Android release build.
