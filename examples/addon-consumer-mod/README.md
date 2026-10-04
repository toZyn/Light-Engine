# Addon library consumer

Copy this directory into your engine's mod content directory as `addon-consumer-mod`. Install `examples/library-addon` as the `library-addon` addon and enable it before selecting this mod.

The native script first checks its required scene module. If the addon is missing or disabled, the engine reports the dependency and the script omits its scene callbacks without affecting other scripts. It then imports a scene module through `require('addon:library-addon/scene')`, explicitly creates a compatibility context, adds a HUD caption, reveals the camera, animates the caption and displays music position. Native `update` and `beat` callbacks forward into the context; `leave` disposes its owned objects and effects. Closing the Script also disposes the context and releases its import cache.

The example needs no image, font or sound assets of its own. The caption uses its owned default font, and song position comes from the existing native music player. Camera fade uses the native one-shot effect described in [scene controls](../../docs/modding-compatibility.md).
