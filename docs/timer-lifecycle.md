# Timer and tween callback lifecycle

`TimerManager:update(dt)` and a Tween manager's `update(dt)` process the
instances present at the start of that tick in reverse insertion order.
Each remaining instance receives at most one update. A callback may cancel
another instance, clear the manager, or create replacements without changing
the current iteration into duplicate callbacks or an access to a removed entry.

Use manager methods and the instance's `cancel()`/`destroy()` methods to change
membership. Instances removed during a tick are skipped, even if reinserted
during that tick. Newly added instances first advance on the next manager
update. Recursive calls to the same manager's `update()` while a callback is
running return immediately; their elapsed time is not applied a second time.

Tween callbacks may cancel or destroy the current tween during `onStart` or
`onUpdate`. Cancellation during `onStart` prevents property changes. Disposal
during `onUpdate` prevents the completion callback. Normal completion still
invokes `onComplete`; it may clear or dispose the rest of its manager safely.
`Tween:clear()` continues to retain entries with `persist = true`.

Callback failures propagate with their traceback. The manager clears its
iteration guard before raising the error, so a caller that catches the error
can use the manager again. The remaining entries do not advance until the
caller explicitly invokes the next update. Zero elapsed time and `timeScale`
retain their existing behavior.

The change does not make canceled native Timer handles reusable through
`start()`: create a new Timer when replacing a canceled handle. Direct mutation
of a manager's public `instances` array bypasses its membership methods.

## Regression fixture

Use `tests/engine/timer-lifecycle.lua` as `main.lua` in a disposable LÖVE 11.5
runner containing this checkout's modules and assets. The setup described in
`docs/audio-lifecycle.md` also works for this fixture. It exercises real native
Timer and Tween classes, including callback disposal, sibling cancellation,
deferred additions, recursive updates, callback errors, and normal timing.

Validation was run under Linux with LÖVE 11.5. No physical Android, Windows or
macOS runtime test is implied.
