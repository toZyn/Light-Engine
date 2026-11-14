# Scene loading and native authoring

Light Engine 0.3.0 accepts an optional `songs/<song-id>/scenes.json`. Existing songs need no manifest. Open `tools/scene_editor.html` in a browser to import, edit, validate and export one. The editor runs locally and makes no network requests. Its input and output are ordinary JSON; saving exports a file, which you place in the song directory.

```json
{
  "shaders": ["stage-glow"],
  "scenes": [
    {
      "name": "intro",
      "start": 0,
      "finish": 16,
      "lead": 3,
      "assets": [["image", "stage/intro"], ["atlas", "characters/guest"]],
      "characters": ["guest"]
    }
  ]
}
```

Times are **song seconds**, independent of rendering FPS and playback speed. Names must be unique; finish must follow start. Omit finish for assets needed until the song exits. Image, atlas and Animate assets use paths relative to `images/`, without extension. Character entries expand the native character descriptor's sprite, alternate animation atlases and icon. A custom character script can load additional assets: declare those explicitly in `assets`. Assets for scenes within their lead window are queued at startup; future scenes are queued as the conductor advances. Large scenes need a longer lead. This reduces synchronous asset misses; it cannot promise that arbitrary third-party synchronous scripts or oversized GPU uploads take no time.

## Ownership and retirement

`Mod.prepareScene(name)` queues a scene early and returns its current status. `state.sceneAssets.scenes[name].status` is `idle`, `loading`, `ready`, `failed` or `released`. Failed assets retain an error and generate a diagnostic. Preparation does not automatically instantiate characters or change their visibility.

Use `Mod.sceneTrack(name, object)` for objects exclusively owned by a scene. At finish the controller destroys tracked objects, removes its ownership of their assets and evicts cache entries it introduced. Already-cached engine resources are borrowed. Overlapping scenes retain their shared resources until the final owner retires. Eviction drops references rather than forcibly releasing GPU images that another live sprite may still hold. LÖVE/GC can reclaim images once all live references disappear. A bounded GC step assists retirement; it does not force a full collection in the gameplay loop.

Do not track the player's character, the shared stage, a globally reused HUD object, or another scene's object. Retired scenes do not reconstruct themselves on a backward seek: restart the song for a fresh lifetime. Exiting disposes all scene ownership. Late async callbacks cannot reactivate a disposed scene or cancel unrelated loader requests.

Copy `examples/scene-assets-mod` into `mods` for a small example based solely on bundled engine content. The second scene prepares a character; it deliberately does not invent a character-change event.

## User preferences

Native scripts receive a read-only `ClientPrefs` view. Reads, indexed control binds and script-level `pairs(ClientPrefs.data)` follow the user's current options. Writes are ignored and reported once per preference path. Calling its `saveData` returns false; engine-owned options remain responsible for saving. Keep per-song behavior in script/state variables. This is a supported API boundary, not isolation against code deliberately accessing engine internals through other globals.

`Mod.layoutNotes()` reapplies the native layout, including Downscroll, middle scroll, split width and lane spacing. The native player layout now applies custom spacing outside middle scroll too. Listen to `onSettingChange(category, setting)` when positioning custom HUD elements. Do not overwrite notefield orientation or replace the input dispatcher. Use the native controls API rather than rebinding saved controls. Existing keyboard, gamepad and touch handling stays engine-owned.

`Mod.flash` respects flashing-light preferences. `Shader:get()` respects the current shader option, including changes during pause. Direct custom drawing must observe the same preferences; the engine cannot infer which arbitrary graphics operations are flashes or effects. The chart and character editors remain available through the existing debug controls. Scene editing supplements these editors; it does not replace them.

## Shader preparation and Android

Put native shader names in the manifest `shaders` list. The engine validates OpenGL ES code and compiles programs during loading, yielding between shaders. The next `Shader(name)` consumes that prepared program without compiling again. Repeat a shader name in the list to prepare additional simultaneous instances; mutable uniforms are never shared between separate shader instances. `Shader.prepare({name})` also provides an explicit preparation API.

Invalid or unsupported programs disable that effect and produce a contextual recoverable error. Source names, validation/compiler messages and existing diagnostic reports identify the failure. Validation does not rewrite ambiguous integer/float expressions: write `amount <= 0.0`, `1.0 / size`, or explicit conversions such as `float(samples)`. Fix errors at their source. Program validity and driver support are checked at runtime on the actual device; desktop GLES validation does not certify all Android GPUs.

The initial loading UI uses the supplied Funkin' Loading artwork, BF/GF run animation, microphone and hopping text. Options → Display → Loading artwork selects Default, Custom or Disable. Custom uses the three supplied placeholders under `images/loading/custom_artwork/`; replace them with your own 1280×720 art. Original package metadata is preserved at `assets/images/loading/SOURCE-METADATA.json`; its resources are not relicensed as engine code.

## Loading lifecycle

The loading screen runs actual preload work and displays current phase/asset counts. Once decoded assets arrive, normal menu-to-song entry continues through a main-thread coroutine: scripts, stage props, individual characters, note fields and gameplay finalization yield at explicit checkpoints. The renderer can draw the loading artwork between checkpoints. No artificial percentage, fixed three-second wait, or fake 99% completion is used. Countdown updates wait until construction finishes. Back/Escape cancels normal loading and returns to the menu. Direct programmatic `PlayState` entry retains synchronous behavior for existing callers; normal `LoadState` entry enables staged construction.

LÖVE requires GPU uploads and shader compilation on the graphics thread. A single upload, atlas parser, shader compile or user callback can still exceed the 4 ms cooperative budget. The budget bounds work between checkpoints, not the runtime of an indivisible operation. Keep textures reasonable and preload custom-script dependencies. The supplied V-Slice Haxe module is not executed; the native loading screen uses its visual resources and animation timing while readiness is controlled by real engine work.

Run `python3 tools/run_engine_tests.py --love /path/to/love scene-runtime streamed-loading` for ownership, late callbacks, preferences, GLES preparation, measured reports and real menu-to-gameplay loading regressions.

## Validation for 0.3.0

The complete 29-suite native runner passed on Linux with LÖVE 11.5, SDL offscreen graphics and null audio. The Python tool suite passed 22 tests. Additional async/mobile-policy, staged-loading and scene-runtime runs passed with `ASYNC_MOBILE=1`; this emulates loader limits on Linux, not Android hardware. The scene editor JavaScript passed syntax and invalid-manifest checks. A rendered loading checkpoint was inspected against the supplied visual resource layout. Release CI independently runs Linux and Windows checks. Physical Android performance, every GPU driver and arbitrary custom script stalls remain unverified.
