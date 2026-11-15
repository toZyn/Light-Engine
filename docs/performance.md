# Large charts and low-resource devices

Light Engine 0.4.2 keeps the original image/audio files, shaders, note rendering,
input preferences and gameplay effects. The changes reduce CPU work rather than
reduce asset quality. The editor UI changes are confined to editing tools.

## What changed

- Gameplay and editor entry check whether chart records are already sorted before
  sorting. Ordered charts take a linear validation pass instead of another sort.
- Gameplay seeks use a binary search of raw chart times. Sprite creation remains
  limited to the visible-lane and hit-window horizon; the full chart is not turned into sprites.
- Consumed active notes are compacted in one stable pass. Lane membership and the
  last-sustain pointer are cleared through the same detach operation as manual
  removal. Surviving notes keep their order and identity.
- The editor stores maximum sustain end times in a tree over 128-record blocks.
  Queries skip blocks that cannot overlap the viewport. A hold starting long
  before the viewport remains visible until its end. Only the blocks containing
  relevant records are inspected; no per-note Sprite is created for the timeline.
- Editor note/event picking and playback hitsounds start at a binary-searched
  timestamp. Chart edits, sustain dragging, undo/redo and event rebuilding
  invalidate cached indexes; list replacement/length changes also rebuild them.
- Editor typography and widget colors are shared locally by the editing tools.
  The tool menu has its own overlay camera, released when it closes or is destroyed.

## Loading and dense gameplay in 0.4.1

Standard menu entry points now defer chart ingestion until the loading view has
been drawn. JSON decoding, normalization, large sorts and note-type scans yield
to the scene job. The legacy direct `PlayState(..., song, difficulty)` constructor
remains synchronous for compatibility; use `PlayState.deferred(...)` when routing
through `LoadState`.

The decoder releases completed documents. Parser-owned raw note arrays are
consumed during normalization, avoiding a deep clone of the input. Difficulty
scans retain chart structure and names without allocating all note arrays.
Normalizing unowned data through a chart parser does not mutate the caller's notes.

Spawning uses visible lane bounds and the timing window, rather than expanding
with scroll speed. `noteSpawn` therefore runs closer to the time the note is
needed, particularly at extreme speeds; scripts should not depend on the old
speed-dependent, hundreds-of-seconds-ahead callback. Actual visible stationary
notes still spawn. Removed active notes are ignored immediately by queries and
rendering; internal active arrays compact on the next field update or explicit
`flushRemovedNotes()`.

An isolated Linux x86_64 / LÖVE 11.5 software-rendered comparison used the same
synthetic Vanilla chart (2,000,000 notes, 2 ms spacing, eight alternating lanes,
zero-length sustains, speed 640), base stage/characters and base instrumental.
Both paths entered through `LoadState` and updated/drew until the scene finished
preparing. The previous version parsed synchronously before that state.

| Measurement | 0.4.0 | 0.4.1 observed run |
| --- | ---: | ---: |
| First loading frame after request | 10.131 s | 0.074 s |
| Complete scene preparation | 12.901 s | 10.223 s |
| Peak process RSS (`VmHWM`) | 1,764,880 KiB | 1,329,300 KiB |
| Peak Lua heap sampled per loading frame | 971.31 MiB | 492.91 MiB |
| Lua heap after full collection | 508.90 MiB | 326.22 MiB |

These are individual observations, not device guarantees. Preparation still had
an 857 ms update/draw spike in this run; repeated instrumented runs varied and
showed longer pauses. Lua allocation/collection, file reads, audio, GPU work and
mod script callbacks are not all preemptible. Showing loading promptly does not
mean all subsequent frames are smooth. Do not infer Android FPS from this table.

## Reproduce

Use LÖVE 11.5 with a working graphics backend:

```sh
python3 tools/run_engine_tests.py dense-charts dense-gameplay loading-ingestion menu-regressions
python3 tools/run_engine_tests.py
python3 -m unittest discover -s tests -p 'test_*.py'
```

For Linux without a display, SDL's offscreen backend can be used if supported:

```sh
ALSOFT_DRIVERS=null SDL_VIDEODRIVER=offscreen python3 tools/run_engine_tests.py dense-charts dense-gameplay loading-ingestion menu-regressions
```

The fixture generates 2,000,000 chart records, including a hold spanning the
entire chart. It checks 200 visible-range queries, exact seek positions, interval
results against a full scan, duplicate timestamps, sustain edits, undo/redo and
consumed-note cleanup. It prints record generation time, index construction time,
query p50/p95, a single full-scan reference time and Lua heap usage. The full scan
and indexed queries check equivalent time-interval predicates. Timings are
microbenchmarks, not complete frame times or end-to-end chart loading times.

An observed Linux x86_64 / LÖVE 11.5 software-rendered run during development:

| Operation | Observed time |
| --- | ---: |
| Generate two million Lua records | 1,018.88 ms |
| Build the block index | 24.98 ms |
| Indexed query p50 | 0.0111 ms |
| Indexed query p95 | 0.0288 ms |
| Full-scan reference query | 23.35 ms |

The fixture's Lua heap was about 324 MiB, including chart records and the running
engine. This is not total process memory, GPU memory or a device memory budget.
Values vary with CPU, runtime and other work on the machine; repeat on the same
content/device and compare medians across runs before making device claims.

## Limits

Millions of records distributed across a song are different from millions of
simultaneously visible/hittable notes. Dense spawn windows still create and
process every applicable note and invoke mod callbacks. There is no note cap,
intentional note dropping or automatic disabling of effects.

Initial chart storage, index construction and editor undo
snapshots still scale with chart size. Undo snapshots clone the chart; repeated
edits of multi-million-note charts can require substantial additional memory.
Extremely many overlapping sustains also require processing their actual visible
results. Large charts can therefore exceed the memory or CPU of low-end phones.
This update does not claim zero latency, constant memory, or verified Android FPS.
Test on the target device using real charts, scripts and shaders. The scene
benchmark tooling remains available for end-to-end frame/load/memory comparison.

`dense-gameplay` separately exercises actual note creation, hit removal and canvas
rendering for 60 frames at 2,000 notes/second, and a 12,000-active-note removal
batch. `loading-ingestion` checks deferred loading, decoder ownership, metadata
projection, parser source ownership and a cooperative 30,000-note reverse sort.
These fixtures supplement the index microbenchmark; none replaces testing an
actual mod on the target device. No per-song benchmark files are generated by
normal gameplay.

## Loading transitions and rendering preparation in 0.4.2

The loading view fades in over 220 ms, survives the scene handoff and reveals the
prepared scene over 300 ms. Gameplay update/countdown timing stays paused through
the exit fade; the view is released after its transparent final frame is drawn.
Early song-start requests are queued until that point, keeping audio from
advancing under the loading artwork when a cutscene skips the countdown.
Standard menu exits use a short fade unless they define their own transition.

During loading, each field exercises note/sustain rendering in a small temporary
canvas, preparing the shared meshes, atlas prefixes and color shaders for every
lane. This does not instantiate chart records or fire `noteSpawn`/hit callbacks.
RGB palette conversions are reused across note instances; palette edits and
shader-cache invalidation are observed. This warm-up cannot predict arbitrary
shaders, skins or objects created later by mod scripts.

When many notes leave a lane viewport together, rendered-note and member arrays
now compact in stable linear passes. A Linux LÖVE 11.5 comparison using the same
12,000 Note objects measured 56.794 ms for 0.4.1's per-note removals and 6.025 ms
for compaction. This measures CPU lane preparation, not a complete GPU frame.
Run `dense-gameplay` to reproduce the departure fixture; `loading-regressions`
checks intermediate fade opacity, final-frame presentation, warm-up ownership
and palette reuse. Measurements vary by device and content.

All chart notes remain available and all applicable visible notes still render.
There is no maximum visible-note count, note dropping or automatic reduction of
shaders/effects. Visibility checks avoid drawing outside the lane/camera viewport;
they do not limit the number of visible results. Simultaneously visible note
counts still carry actual CPU/GPU and memory costs; no finite device can process
an unlimited number within a fixed frame time. Preparing shared graphics reduces
first-use work, but does not establish freeze-free behavior on every chart/device.
