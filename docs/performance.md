# Large charts and low-resource devices

Light Engine 0.4.0 keeps the original image/audio files, shaders, note rendering,
input preferences and gameplay effects. The changes reduce CPU work rather than
reduce asset quality. The editor UI changes are confined to editing tools.

## What changed

- Gameplay and editor entry check whether chart records are already sorted before
  sorting. Ordered charts take a linear validation pass instead of another sort.
- Gameplay seeks use a binary search of raw chart times. Sprite creation remains
  limited to the existing spawn window; the full chart is not turned into sprites.
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

## Reproduce

Use LÖVE 11.5 with a working graphics backend:

```sh
python3 tools/run_engine_tests.py dense-charts
python3 tools/run_engine_tests.py
python3 -m unittest discover -s tests -p 'test_*.py'
```

For Linux without a display, SDL's offscreen backend can be used if supported:

```sh
ALSOFT_DRIVERS=null SDL_VIDEODRIVER=offscreen python3 tools/run_engine_tests.py dense-charts
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

Raw JSON decoding, initial chart storage, index construction and editor undo
snapshots still scale with chart size. Undo snapshots clone the chart; repeated
edits of multi-million-note charts can require substantial additional memory.
Extremely many overlapping sustains also require processing their actual visible
results. Large charts can therefore exceed the memory or CPU of low-end phones.
This update does not claim zero latency, constant memory, or verified Android FPS.
Test on the target device using real charts, scripts and shaders. The scene
benchmark tooling remains available for end-to-end frame/load/memory comparison.
