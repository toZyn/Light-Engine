# Reproducible performance captures

Enable **Options → Display → Capture performance** before selecting a song. A desktop alternative is `LIGHT_BENCHMARK=1`. The next native `PlayState:preload` starts a capture; gameplay-ready marks loading completion. Leaving the song writes `benchmarks/*.json` under LÖVE's save directory. The option is off by default. Paused/loading updates are excluded from gameplay frame statistics.

Reports contain load milliseconds; frame count, mean, p50/p95/p99 and maximum milliseconds; sampled peak Lua memory; sampled peak texture memory; and sampled peak process RSS when `/proc/self/status` is readable (Linux/Android). Memory samples occur every 250 ms during gameplay; they can miss shorter peaks and are not a measurement of total GPU allocation. Frame percentiles use a bounded 0.1 ms histogram through 1000 ms; slower frames saturate that percentile bucket, while `maxMs` retains the observed maximum. Lua/texture/RSS measures overlap and must not be added together. Unsupported RSS is absent, never fabricated as zero.

Frame intervals are wall-clock intervals between update callbacks, including frame pacing and draw/present time, not GPU execution timestamps. A software-rendered test is a functional test, not a phone benchmark. Compare performance only on the same physical device and content.

## Protocol

1. Fix device, OS/GPU driver, resolution, refresh/FPS cap, renderer and graphics settings. Record battery/thermal conditions and power mode separately.
2. Use identical media/chart content and difficulty. Generate its fingerprint outside the content directory:
   `python3 tools/benchmark.py fingerprint /path/to/content`.
3. On desktop set `LIGHT_BENCHMARK_CONTENT` to that SHA-256 value. On mobile put the value in the song's scene manifest as `contentId`. A fingerprint is a declared content identifier; regenerate it after any content change. Do not fingerprint generated captures together with the content.
4. Warm the device consistently, then capture the same full-song run and gameplay/input mode at least three times for each build. Keep both cold-load and warm-load runs separately. Exit at the same point; do not compare a cancelled song to a full run.
5. Run `python3 tools/benchmark.py compare before.json after.json`. The tool rejects missing/different content IDs, devices, resolutions, preferences, song or difficulty, and empty frame samples. Smaller values mean less loading time, shorter frames or less observed memory; negative change percentages are reductions.

Keep the individual reports and report variability, not just the best run. Different engines can export this schema to use the same comparison tool, but their loading boundaries and sampled windows must agree. The tool does not prove that an externally supplied fingerprint is truthful or that the phone was at the same temperature. Do not use comparisons on different devices to claim that one engine is faster.
