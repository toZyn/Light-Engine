# Compatibility examples

Copy this directory into your engine's mods directory, activate it through the native mod menu, then play an available base song. An orange HUD bar slides into place, pulses using a scoped timer/tween and changes angle on beats. A text caption shows native song timing, reveals through a camera fade and responds to beats. Leaving gameplay disposes each script's owned resources.

Alternatively, copy either `data/scripts/compat-demo.lua` or `data/scripts/compat-scene.lua` into an existing native mod. No new assets or chart conversion are needed. See `docs/modding-compatibility.md` in the engine source for the exact supported API and limits.
