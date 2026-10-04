# Native mod and addon examples

Copy the addon directory into `addons/` and the mod directory into `mods/`.
On Android these live under `Android/media/com.zyn.lightengine/`.
Enable the addon in the Mods menu, select the mod, then play any existing song.

| Mod | Addon | What it does |
| --- | --- | --- |
| `beat-meter-mod` | `tempo-tools-addon` | Shows beat position and BPM, including tempo changes. |
| `timing-trainer-mod` | `judgement-tools-addon` | Shows signed timing bias, mean absolute error, and miss counts. |

The examples keep the game's chart, scoring and saved preferences. Each removes
its HUD objects and subscriptions in `leave()`. A disabled or absent addon omits
the optional HUD and lets the song run normally. Botplay samples are automatic;
turn botplay off to measure your own input.

`Beat.phase(conductor, milliseconds)` returns fractional phase and a zero-based
beat number. `Beat.subscribe(conductor, callback)` returns an idempotent detach
function. Call it before the conductor is destroyed.

`Statistics.new()` creates a separate sample set. `add(milliseconds)` accepts
finite signed errors. `snapshot()` returns count, signed mean, mean absolute
error, and peak absolute error without exposing the live counters.

Package your addon with:

```sh
python3 tools/make_addon_release.py /tmp/tempo-tools.zip --source examples/tempo-tools-addon
```

The other example directories demonstrate compatibility callbacks, optional
dependencies and shared scene modules. See [addon modules](../docs/addon-modules.md)
for their lifecycle rules.
