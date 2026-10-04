# Engine diagnostics

The engine writes diagnostics in LÖVE's save directory, independently of mod assets and the asset cache:

- `diagnostics/last-error.txt`: complete latest Lua or worker error and traceback.
- `diagnostics/engine.log`: startup, checkpoint, error and shutdown history; rotates to `engine.previous.log` at 256 KiB before the next append. A single complete error may exceed that limit.
- `diagnostics/session.active`: latest checkpoint of the active run. Normal shutdown removes it. If it remains on the next startup, the log labels the previous session **interrupted**. Force quit, power loss, and OS process termination can leave the same marker; it is not proof of a crash.

Checkpoints include OS, LÖVE version, renderer, active mod, active state, Lua memory and texture memory. Repeated running checkpoints are limited to once every five seconds. Before a graphics context exists, renderer fields are unavailable and no native renderer queries run. Invalid UTF-8 bytes in an error are represented as `\xNN`, retaining the byte information while making the report safe to display.

Write failures (including denied permissions and an invalid diagnostics directory) do not replace the original error or block the error handler. A saved-report path is included only after a successful write; otherwise the original message/trace remains available to display and copy, with a storage warning. Diagnostics use the engine's LÖVE save directory, independently of external mod-folder permissions.

The normal error screen retains the original Light Engine background, logo, fonts, music and controls. Press **Ctrl+C** to copy the displayed error, **Ctrl+R** to restart, or **Esc** to quit; touching the screen opens the original native quit/restart/copy dialog. Diagnostics are saved in the background before stopping loaders or preparing that screen; a report path is not inserted into the normal display. Failed loader shutdown does not replace the original error. Only an unavailable original screen (missing base assets, startup or graphics failure) uses the asset-independent emergency screen. That fallback supports C/R/Esc and bottom touch regions while preserving the report.

The low-memory callback records the notification and collects Lua garbage. It does not clear the asset cache, release textures, or reduce graphics quality. Lua cannot catch native segmentation faults or an Android process killed by the OS; the retained marker helps identify the last recorded activity, while a native trace or Android logcat is still needed to establish cause.

On desktop, the save location is typically `%APPDATA%\LOVE\<identity>` on Windows, `~/Library/Application Support/LOVE/<identity>` on macOS, and `~/.local/share/love/<identity>` on Linux. The identity is configured by `Project.package`. Android save location and direct access depend on the runner and Android version; use the report path printed to the console or the emergency screen when available. External mods/storage paths are separate from this engine diagnostic directory.

## Regression test

Run the test in an isolated LÖVE directory, using the engine's window-disabled configuration:

```sh
engine_test_dir=$(mktemp -d)
cp tests/engine/diagnostics.lua "$engine_test_dir/main.lua"
cat > "$engine_test_dir/conf.lua" <<'LUA'
function love.conf(t)
  t.modules.window = false
end
LUA
ENGINE_ROOT="$PWD" love "$engine_test_dir"
```

The test exercises the real filesystem, native window/context creation, malformed UTF-8, full saved traces, interrupted/clean sessions, repeated startup and checkpoint throttling, missing mod assets, failed loader shutdown, missing graphics, keyboard/touch copy/restart/quit, a real failed worker thread, and a live image surviving low-memory collection. Linux LÖVE 11.5 is the verified runtime; physical Android, Windows and macOS validation is still required.

The `error-screen` suite checks the real original images/fonts and keyboard/native touch actions, with the report saved independently. The emergency-screen tests deliberately use missing assets/graphics.
