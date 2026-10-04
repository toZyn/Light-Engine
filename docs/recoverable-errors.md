# Recoverable error reports

The engine reports failures at boundaries that already define a safe outcome: a failed native Script chunk closes that Script, a failed Script callback disables that callback, an unavailable addon dependency lets its caller omit a feature, and a failed `Save.bind` write returns `false, message` while retaining live save data. Corrupt saved data retains live defaults. Other callbacks can continue under the existing Script rules. Fatal engine errors still use the original error screen.

Each new report preserves its complete message and traceback in the engine diagnostics and prints it to the console. The latest saved report is `<LÖVE save directory>/diagnostics/last-error.txt`; `diagnostics/engine.log` also records reports with the normal log rotation. Invalid UTF-8 bytes are escaped rather than discarded. Reports use engine-owned paths, independent of mod assets.

## Native mods and addon modules

Native Script environments and their reusable addon modules expose `reportRecoverableError(message, trace)`. Call it after choosing an explicit safe fallback:

```lua
local Effects, importError = tryRequireAddon('optional-effects', 'scene')
if importError ~= nil then
  reportRecoverableError('Optional scene effects unavailable', importError)
  -- Omit the optional scene. Other setup can continue.
else
  Effects.install()
end
```

The helper reports the supplied error; it does not catch code, create substitute values, restart gameplay, or undo state changes. Supply the original error or traceback as `trace`. If omitted, the helper captures the caller traceback. A saved helper rejects calls after its Script has closed, and its binding does not retain the Script.

Strict addon imports retain their normal Script failure behavior. `tryRequireAddon` returns an error for the caller to handle without automatically notifying. `checkAddonDependencies` reports unavailable dependencies together with the caller traceback. See [addon modules](addon-modules.md) for their exact return values and scope.

## Engine API and output limits

Engine code can use the same reporting service at a known safe boundary:

```lua
local Errors = require('funkin.backend.recoverable-errors')
local record = Errors.report(message, originalTrace, {source = 'optional-feature'})
```

`source` identifies the reporter for deduplication and returned metadata. `report` returns a record containing `message`, `trace`, `source`, `duplicate`, `count`, `reported`, `persisted`, `copied`, and `queued`. New reports also contain the complete `report` text and, when saved, `reportPath`. `reported` means diagnostics produced a report; `persisted` means the file was saved. `copied` describes the immediate clipboard attempt, and `queued` means a notification was accepted, even if it was displayed during that call. These are snapshots; later output retries do not mutate the record.

The service uses the existing error Toast with its normal style. Before Toast initialization, notifications wait in a bounded queue. `Errors.update()` runs from the normal engine update loop and flushes at most one notification every two seconds. At most eight notifications wait; additional notifications are dropped without discarding their original diagnostic report.

Clipboard copying is automatic and protected against an unavailable or rejecting provider. Writes occur at most once every two seconds. While throttled or unavailable, only the latest complete report is retained for a later attempt from `update()`. A provider returning `false` is a failure; LÖVE's normal nil return is success. A Toast or clipboard failure cannot replace the original error or escape the reporting call.

Exact repetitions of the same source, message and traceback within ten seconds are deduplicated: they do not rewrite diagnostics, notify again or overwrite the clipboard. Deduplication retains at most 32 keys, each limited to 16 KiB. Larger reports and distinct errors still preserve complete diagnostics; notification and clipboard queues remain bounded. `Errors.getStats()` returns a fresh snapshot of report, duplicate, dropped notification, clipboard and notification failure counters, queue sizes and configured limits.

`Save.bind` reports its write-failure result, including the target filename and original error. External storage verifies both write and close results before returning success and updating the save watcher; a failure reports the external filename and uses the existing internal writer fallback, preserving that fallback's return values. Callers must still inspect the result. Serialization errors remain errors.

Native save initialization protects hex decoding and JSON parsing, rejects non-table JSON, and closes desktop readers before decoding. Failed reads, failed closes and corrupt contents report the filename and preserve live defaults; valid tables still replace defaults. Arbitrary engine update errors are not converted into recoverable outcomes.

## Verification

`tests/engine/recoverable-errors.lua` covers full saved traces and malformed bytes, automatic clipboard writes and delayed latest-report copying, explicit clipboard rejection and provider exceptions, real pre-initialization Toast queuing, duplicate floods and bounded distinct notification floods, optional UI failure, missing addon callback isolation, healthy callbacks, closed helper bindings, and native save-write failure without losing live data. `tests/engine/save-storage.lua` also covers external write/close return failures and exceptions, fallback results, successful hex-JSON persistence, preserved encoding exceptions, corrupt initialization on desktop/mobile policies, reader closure, live defaults and valid saved tables.

The recoverable error, Script error, save-storage and addon-module suites passed with official Linux LÖVE 11.5 under Xvfb. The implementation uses the same native LÖVE APIs across platforms; physical Windows and Android clipboard, Toast and storage behavior remains unverified.
