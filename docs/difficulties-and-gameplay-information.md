# Story difficulties and gameplay information

Story Mode scans the charts once when loading weeks. It recognizes `charts/<difficulty>.json`,
`chart-<difficulty>.json`, `<song>-chart-<difficulty>.json`, `<difficulty>.json`,
and difficulty keys in V-Slice `chart.json` files. Generic native/vanilla charts
use declared week difficulties and song metadata. Only common variants across
all songs are selectable, preventing a week from failing halfway through.
An explicit week `difficulties` list preserves its order; newly discovered shared
variants are appended. Comparisons and duplicate checks ignore case.

## Labels and mod overrides

A difficulty image at `images/menus/storymenu/difficulties/<song-path-name>.png`
takes priority, including existing built-in images. Compressed image formats
supported by the engine are also recognized. The image is not recolored.
Without an image, the engine generates a fitted uppercase label with the bundled
FNFont in `fonts/difficulty.ttf`. Font bytes are preserved from the supplied TTF.

Optional fields in a week JSON:

```json
{
  "difficulties": ["Normal", "Expert"],
  "autoDifficultyColor": false,
  "difficultyFont": "my-difficulty.ttf",
  "difficultyColors": {
    "expert": [255, 100, 30]
  }
}
```

`autoDifficultyColor` defaults to true. False leaves generated text white.
When enabled, `difficultyColors` overrides the defaults; RGB values can be 0–255
or 0–1. Easy, Normal, Hard, Erect and Nightmare have predefined colors; custom
names receive a stable color derived from their name. Font paths are relative to
`fonts/` and follow the engine's existing mod/addon resolution rules.

## Gameplay information

Options -> Gameplay -> Gameplay information is saved and can be changed while paused.
The default is Simple, preserving the score-only layout.

| Mode | Information |
| --- | --- |
| Simple | Score |
| Informative | Score, misses, accuracy |
| Full | Informative plus hits, Sick/Good/Bad/Shit counts, combo/max combo, IPS/peak IPS, NPS/peak NPS, health, playback speed, botplay-used flag, timing offsets/errors and turn countdowns |

Accuracy uses the existing judgement weights (Sick 1, Good 0.7, Bad 0.4, Shit 0),
divided by judged hits plus misses. Before the first judgement it is 100%.
IPS counts non-repeated player direction presses, including ghost taps. NPS counts
successful note heads, so sustain ticks do not inflate it. Both use a rolling
second of unpaused real time, independently of playback speed. Automated hits are
not counted as physical inputs or human timing samples; they are included in NPS,
score and accuracy, with botplay usage shown in Full.

Turn activity includes a note's whole sustain duration, or 0.2 chart seconds for
a tap. Adjacent intervals separated by no more than 0.35 chart seconds merge into
a phrase. The Full HUD distinguishes player, opponent, simultaneous activity,
breaks and exhausted tracks. Countdown values are real seconds at the current
playback rate, not camera-focus or vocal-volume guesses. The timeline is built
once and queried by binary search, including after seeking. Turn countdowns refresh
ten times per second; score and judgement updates remain immediate.

All information objects use the HUD camera and respect gameplay-only recording.
The compact score line remains near the health bar; Full details move away from
the receptor edge when downscroll changes and fit the viewport's screen margins.

## Optional credit avatars

If this runtime has no usable HTTPS module, credit avatars show a static neutral
placeholder and do not queue downloads. This does not add an HTTPS binary to
Android or pretend that unsupported devices can download avatars. When a native
module is available, the loader executes its initializer and normal downloads run.
Other asset/network errors continue to use the engine's diagnostic handling.
