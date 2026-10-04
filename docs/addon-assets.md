# Namespaced addon assets

Native scripts and their reusable addon modules can request assets from one explicitly named, active addon. These helpers resolve only that addon's directory. A mod override or another addon with the same filename does not change the result.

The ID is the directory name recorded in `Addons.all[].path`, including existing names with spaces, dots or Unicode. It must match an active registry entry exactly, preserving case. Empty IDs, standalone `.`/`..`, separators, colons and control bytes are rejected. Unknown and disabled IDs raise contextual errors, including when the resource was cached before the addon was disabled. Disabling an addon does not release assets still used by a state.

The native script aliases are:

| Helper | Location under the named addon | Result |
| --- | --- | --- |
| `getAddonPath(id, relative)` | Normalized relative path | LÖVE filesystem path; existence is not required |
| `readAddonText(id, relative)` | Exact relative filename | File contents |
| `readAddonJSON(id, relative)` | Exact relative filename | Parsed JSON value |
| `getAddonImage(id, key)` | `images/<key>.png` | Cached LÖVE Image |
| `getAddonSound(id, key)` | `sounds/<key>.ogg` | Cached SoundData |
| `getAddonMusic(id, key)` | `music/<key>.ogg` | Cached streaming Source |
| `getAddonFont(id, filename, size)` | `fonts/<filename>` | Cached Font; default size 12 |

Image, sound and music keys omit the file extension. Font filenames include it, and sizes must be positive finite integers. This initial image helper supports PNG. Native compressed-image selection remains available through the existing engine paths APIs.

Example addon layout:

```text
addons/weather-pack/
  images/rain.png
  sounds/drop.ogg
  music/storm.ogg
  fonts/labels.ttf
  data/weather.json
```

A native callback can use:

```lua
function create()
  local settings = readAddonJSON('weather-pack', 'data/weather.json')
  local texture = getAddonImage('weather-pack', 'rain')
  local font = getAddonFont('weather-pack', 'labels.ttf', 20)
  local effect = Sound()
  effect:load(getAddonSound('weather-pack', 'drop'))
  effect:play(0.6)
  -- Add these objects to the state's normal ownership/lifecycle as needed.
end
```

Each relative path is confined syntactically to the addon namespace: absolute paths, backslashes, colons, control bytes and `..` segments are rejected. Harmless `.` segments and repeated `/` separators normalize to a single cache path. File, decoder and JSON errors include the addon ID and resolved filename; native `Script:call` records their full traceback and applies its existing callback isolation behavior.

Images, audio and fonts use the existing `paths.images`, `paths.audio` and `paths.fonts` caches. Cache keys include the actual addon filesystem path; fonts additionally include size. Returned GPU/audio/font objects are **borrowed cache assets**. Do not release them yourself. A `Sound` loaded from SoundData or Source owns independent playback; normal sound cleanup does not release the cached asset, and cache eviction does not stop the Sound's owned Source. Shared font changes affect every consumer of that cached font.

Bindings hold a weak reference to their native Script and reject calls after it closes. Saving an alias does not keep a closed Script alive. Engine code can also require `funkin.backend.modding.addonassets` and call `getPath`, `readText`, `readJSON`, `image`, `sound`, `music`, or `font` directly. These helpers do not start global scripts or automatically enable an addon.

## Verification

`tests/engine/addon-assets.lua` exercises addons with simple, spaced/dotted and Unicode IDs plus a mod sharing the same image name, real image/audio/font caches, normalization and invalid paths, unknown/disabled IDs, native Script JSON diagnostics, closed/collected bindings, independent Sound playback, and real cache eviction. It passed with native and official AppImage LÖVE 11.5 on Linux. Physical Android and other OS validation remains outstanding.
