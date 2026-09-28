# Android build assets

This directory contains the project-specific launcher, manifest, Gradle values,
and the PhysFS patch needed to build the embed APK with `love-android` 11.5a.

Use `tools/build-android.sh` with `LOVE_ANDROID_DIR` and `ANDROID_SDK_ROOT` set.
The script applies the storage mount patch, copies the launcher and manifest,
creates the Boon `.love`, runs the Android release build and signs the APK with
`android/keystore.jks`.

## Launcher icon

`res/drawable-*/icon.png` are generated from `art/logo.png`, never from
`art/icon.png` (that one is a 16x16 placeholder). Regenerate them with:

```sh
for spec in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  dir=${spec%%:*}
  size=${spec##*:}
  magick art/logo.png -resize "${size}x${size}" "android/res/drawable-$dir/icon.png"
done
```

`.github/workflows/release.yml` builds the same icons on every release, so the
committed copies only matter for local builds.

## Signing

`keystore.jks` holds the release key and `keystore.properties` holds its alias
and password. Both are read by `tools/build-android.sh` and by the release
workflow. Its job is to give every build the same signature, so updates install
over older versions instead of failing with "app not installed". This
repository is public, so the keystore and its password are public too: anyone
can sign the same package. Rotating the key means installed copies have to be
uninstalled first.
