# Reusable scene library

Copy this directory into your engine's addon content directory as `library-addon`, then enable it in the Addons menu. It contains no global scripts and performs no work merely by being enabled or imported.

`requireAddon('library-addon', 'timing')` returns helpers for beat/bar durations and milliseconds-to-seconds conversion. `require('addon:library-addon/scene')` returns text caption and camera reveal helpers; create the native Script compatibility context before calling those scene functions.

Install `examples/addon-consumer-mod` to see a native mod import both modules, animate a caption, and read the music position. See [module contracts](../../docs/addon-modules.md) and [scene controls](../../docs/modding-compatibility.md).
