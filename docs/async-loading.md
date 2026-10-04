# Asynchronous asset loading

The public `paths.async` loader and callback signatures are unchanged. Image decoding, sound decoding, streamed Source creation and URL requests run in workers. Images are uploaded to the GPU on the main thread.

The loader uses at most **four workers on desktop** and **two on mobile**, counting workers retiring after cancellation. Only that many tasks are dispatched at once; further paths remain in the Lua queue. Each `update` handles at most **two results on desktop** or **one on mobile**, including failed results. This limits decoded buffers waiting in channels and main-thread upload bursts without reducing image resolution, animation frames or audio quality. Duplicate pending requests share a task and retain all callbacks, including when the original request had no callback.

Workers load HTTPS support only for URL requests. A module must provide a callable `request` function; absent or malformed modules produce a reported task failure. Local assets require no HTTPS support. HTTP failures, decoder failures and main-thread processor failures invoke the callback with `nil` and a contextual error string, count as completed progress, and retain structured failure information in `getStats().lastError`. If diagnostics are already available, they also persist the error. Successful URL callbacks retain the existing second argument containing the URL. Streamed URL audio returns a usable LÖVE Source directly.

An exception thrown by a callback propagates with its asset path and full traceback. It reaches the engine's error handler; it is not converted into a successful load. Completion bookkeeping occurs before callback invocation.

`stop()` cancels pending callbacks, clears queued tasks, resets progress, and starts a new channel generation. Late results cannot repopulate the cache or run cancelled callbacks. `paths.clearCache()` calls `stop()` before releasing cached resources. Workers release their userdata references after channel transfer or cancellation; the channel owns its transferred reference until the main thread consumes or discards it. An existing cache object is reused if a direct queued request finishes for the same path, avoiding a second object replacing a live cached resource.

A transport already inside a blocking request cannot be forcibly interrupted through LÖVE's thread API. `stop()` returns without waiting for that request. The worker checks cancellation before publishing, releases its result, then exits. Until it finishes it still occupies a worker slot; new work waits when all slots are occupied. Idle workers are cancelled after ten seconds without queued or active work. Each loader lifetime uses distinct channel names, including across module reloads.

## Inspection

`paths.async.getStats()` returns a snapshot:

| Field | Meaning |
| --- | --- |
| `queued`, `completed`, `failed` | Submitted, completed and failed tasks in the current batch |
| `pending`, `inFlight`, `ready` | Lua backlog, dispatched tasks and queued current-generation results |
| `workers`, `retiringWorkers` | Current and cancelled workers still running |
| `maxWorkers`, `maxUploads` | Platform concurrency and per-update result limits |
| `generation` | Current cancellation generation |
| `lastError` | Latest failure with `kind`, `path`, `message`, `traceback`, and `generation` |

`getProgress()` remains a number from zero to one; no outstanding tasks, failed tasks which completed, and cancelled batches all reach one.

## Regression test

Run from the checkout with LÖVE 11.5:

```sh
engine_test_dir=$(mktemp -d)
cp tests/engine/async.lua "$engine_test_dir/main.lua"
ENGINE_ROOT="$PWD" love "$engine_test_dir"
ENGINE_ROOT="$PWD" ASYNC_MOBILE=1 love "$engine_test_dir"
```

The test uses real worker threads, image buffers, GPU images, Sources, channels and the real cache-clear/AnimateLibrary implementations. Controlled HTTP modules reproduce malformed transports, successful streamed audio, and delayed requests without external network dependence. It covers upload/worker limits, failures and progress, callback exceptions, pending deduplication, cache reuse, cancellation, delayed retirement, restart, cache clearing, and a JSON-backed AnimateLibrary texture callback. The mobile flag exercises the mobile limits on Linux; it is not a physical Android test. Physical Android and other desktop operating systems remain unverified.
