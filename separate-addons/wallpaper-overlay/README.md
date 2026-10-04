# Wallpaper & Overlay Toolkit (separate addon)

Copy `wallpaper-overlay/` to the engine content `addons/` directory, enable it in Addons, then import it explicitly. This addon is excluded from game.love and the APK; it never starts on its own.

```lua
local ready = checkAddonDependencies({{id='wallpaper-overlay', module='overlay'}})
if not ready then return end
local Background = requireAddon('wallpaper-overlay', 'overlay').new()
function create()
  -- Supply an image the user chose. It can live at images/wallpaper.png
  -- inside this addon. No reading/uploading of the phone's wallpaper occurs.
  local image = getAddonImage('wallpaper-overlay', 'wallpaper')
  local sprite, error = Background.createBackground(image, state)
  if not sprite then return end -- denied permission leaves gameplay intact
end
function leave() Background.close() end
```

The existing native message box asks Allow/Deny before displaying an image. The original Image is rendered directly; the addon does not resize, recompress or rewrite the asset. Cover-fit rendering may crop the edges to fit the viewport. Cleanup removes only its own layer and never releases a borrowed image. Script close also cleans up automatically.

## Real operating-system overlays

**Stock LÖVE 11.5 has no native overlay or wallpaper-reading API. This addon cannot draw the game over other apps on the current stock Android APK.** A Lua addon cannot add Android manifest permissions or create a native overlay service. Changing this requires a native host extension and a newly built APK; it cannot be achieved by just installing a Lua addon. iOS does not offer Android-style SYSTEM_ALERT_WINDOW access.

An optional native backend can be passed to `.new(backend)`. It must provide:

- `capabilities() -> {overlay=boolean, wallpaper=boolean}` for the actual current OS/session.
- `hasPermission('overlay') -> boolean`, querying the OS, not a cached dialog answer.
- `requestPermission('overlay') -> true | nil, error`, opening the real OS permission flow. Opening Settings is not a grant.
- `beginOverlay(options) -> true | nil, error`, activating the native window only after permission is granted.
- `endOverlay() -> true | nil, error`, restoring/disposing the native window safely.
- `getWallpaper() -> Image | nil, error`, returning an accessible user-approved wallpaper as a **borrowed Image**. The bridge owns this Image and must cache/dispose it only after all users remove their background layers; the toolkit never releases it. Live/lock-screen wallpaper and Android privacy restrictions may deny this.

`requestOverlay(options)` first checks capability, asks consent, checks OS permission on every call (including an active overlay), stops an overlay when permission has been revoked, requests it when absent, checks it again, and starts only after a real grant. Pending permission returns `nil, message`; retry explicitly after returning from Settings. `stopOverlay()`/`close()` restore the native window. `getWallpaper()` asks separate consent, never requests broad storage permission and never uploads the image.

No native backend is bundled or claimed to be working. Android needs a WindowManager/SYSTEM_ALERT_WINDOW bridge and lifecycle-aware restoration of the renderer; Windows requires native window layering and click behavior; X11/Wayland depend on compositor capabilities. Unsupported systems return a recoverable error. A module offering fictitious permission grants would not provide OS support.

The native test uses a simulated backend solely to verify permission denial/pending/granted transitions and cleanup, plus a real LÖVE image and scene for the supported background path. It does not prove Android native overlay operation.
