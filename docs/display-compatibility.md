# Displays, window resizing, and split-screen

Light Engine uses LÖVE's single native window. Desktop users can move that
window between monitors through **Display → Monitor**, then toggle
**Fullscreen** on the selected monitor. Fullscreen defaults to the desktop
mode, which uses the monitor's current resolution. This does not create
multiple simultaneous native windows.

Monitor selection is saved with the other preferences. Indices are the
operating system's current enumeration, starting at 1; they are not permanent
hardware IDs. If a saved monitor is missing at startup, the current monitor
is retained. Recheck the selector after connecting or disconnecting displays.
The engine verifies the native window's resulting monitor before reporting a
successful switch. If the OS refuses the move, it restores the previous mode
and reports the rejection through the display options error notification.

Desktop window resizing and fullscreen keep the selected camera resolution,
antialiasing, artwork, and gameplay coordinates. Fixed-aspect projects scale
uniformly and center the scene with letterboxing. OS resizing does not change
the graphics quality preference or recreate fixed-size camera canvases.

Projects with `Project.adaptableWidth = true` retain their adaptive viewport:
the logical height stays fixed and the logical width follows the window's
aspect ratio. This is the existing mobile default. The original
`Project.width` configuration remains intact. Origin cameras that cover the
previous full logical screen follow this viewport at their existing render
resolution; custom camera sizes and positions are retained. State and object
`resize(width, height)` callbacks receive the native window dimensions and can
adapt their own layout. Layout code should use `game.width` and `game.height`
for the current logical viewport.

On Android and iOS, the OS controls window bounds, including split-screen and
orientation changes. Startup does not force fullscreen or a nonresizable
window. Resize notifications update the logical viewport without requesting
another native size. Zero, nonfinite, or temporary invalid dimensions are
ignored. Desktop-only Monitor and Fullscreen settings are hidden on mobile;
the Resolution setting adjusts camera quality without requesting mobile
window bounds. The Android source manifest marks both the permission entry
activity and game activity `android:resizeableActivity="true"`; a distributed
APK must also contain that flag on `GameActivity` in its compiled manifest.
The APK repack tool's `--resizable` option patches the existing GameActivity
flag when building from a runtime APK; it does not add a new flag to the
transient permission activity in that compiled APK.
Platform support for actual split-screen still depends on OS/device support.

## Engine API

Use `game.display` after requiring the engine. Changes return `true` on success
or `false, message` when invalid, unsupported, or rejected by the OS.

```lua
local displays = game.display.getMonitors()
-- Entries: {index=1, name="...", width=1920, height=1080}
local current = game.display.getMonitor()
local ok, reason = game.display.selectMonitor(2)

game.display.setFullscreen(true) -- desktop fullscreen
game.display.setFullscreen(false) -- restores the prior windowed dimensions
game.display.resizeWindow(960, 540) -- explicit desktop window sizing
```

`setFullscreen` also accepts `"desktop"` or `"exclusive"` as its second
argument. Existing `love.window.setFullscreen` callers use the same safe
engine path. Successful state changes notify `love.fullscreen` through the
engine fullscreen handler. Redundant requests do not emit another callback.
An OS rejection returns a reason; platform errors are not reported as a
successful change.

`resizeWindow` requires windowed desktop mode and positive finite dimensions.
It uniformly fits oversized requests inside the current monitor's desktop
dimensions. It does not change logical dimensions or camera quality. Mobile
fullscreen, monitor selection, and explicit sizing return an unsupported
reason without changing the native window.

`refresh()` updates `game.display.width`, `height`, `monitor`, and `fullscreen`
from the native window. These reflect the most recent refresh; getters and
coordinate helpers query the current native dimensions directly. Engine
startup and resize notifications refresh these fields automatically.

```lua
local viewport = game.display.getViewport()
-- {x, y, width, height, scale} in window coordinates, or nil before a valid viewport.
local gx, gy = game.display.windowToGame(windowX, windowY)
local wx, wy = game.display.gameToWindow(gameX, gameY)
```

These conversions use the same centered uniform scaling as mouse, touch, and
virtual pads. Points in letterboxing can map outside the logical viewport;
they are not clamped into interactive content. Engine windows use
`usedpiscale=false`, preserving the existing input/render coordinate convention.

## Verification and limits

`tests/engine/display.lua` is the standalone native `display` suite. It checks
real native resize/fullscreen operations, adaptive viewport behavior, camera
canvas ownership/quality, rendered pixel positions and letterboxing, monitor
selection, and mouse/touch/virtual-pad coordinate agreement. Invalid requests
must leave the native window intact. Native positioning-error fault injection
checks that change and restoration exceptions return a reason instead of
escaping; it does not establish physical hotplug behavior. A mobile device-policy substitution
checks unsupported-operation handling; it is not Android or iOS execution.

Linux tests use official LÖVE 11.5 under Xvfb. The normal display reports one
monitor. Xvfb with two independent X11 screens reports two native displays;
this topology rejects moving the LÖVE window to the other screen, so the
fixture checks accurate rejection and restoration in both windowed and
fullscreen modes. Xinerama merges those overlapping screens into one display
in the tested SDL backend. These are not successful physical monitor migration
tests. Physical monitor hotplug and movement, Windows/macOS execution,
and actual Android/iOS split-screen require testing on those platforms; do not
infer those results from the Linux fixture.
