# Platform and mod controls implementation plan

**Goal:** Shared display adaptation, isolated nonfatal errors, explicit addon imports, offline Zyn credits and a separately distributed overlay addon.

**Architecture:** LÖVE display/window APIs serve all platforms; OS resize must not force another native window size. Recoverable errors are handled only at known isolated boundaries, keep original diagnostics, notify through the existing Toast and copy safely. Fatal errors retain the original error screen. Addons stay separate and optional.

**Tech stack:** LuaJIT / LÖVE 11.5; native test fixtures.

## Constraints
- Preserve existing artwork and original error screen.
- No Android-only changes to common display/error/import code.
- LÖVE supports one native window; simultaneous windows require another native runtime.
- Overlay permissions and wallpaper access require a real platform backend; never invent a grant or silently bypass OS restrictions.
- Zyn remains the existing owner entry with GitHub toZyn; download the public avatar for offline use.

## Work
- [x] Display: trace resize, monitor and fullscreen flow; write failing display fixtures; remove resize feedback loop; expose checked monitor/window helpers; validate input scaling and native modes.
- [x] Recoverable errors: isolated Script failures report original diagnostics, notify and copy; test unavailable storage/clipboard, pre-Toast queues, error floods and continued callbacks. Fatal engine loop is unchanged.
- [x] Imports: add tryRequireAddon, checkAddonDependencies, getAddonImports; test missing/disabled libraries, false exports and fresh snapshots; keep strict imports.
- [x] Credits: embed the original GitHub avatar, reference local asset, verify PNG decodes in the native engine.
- [x] Separate overlay addon: capability and consent API with no automatic activation; clarify overlay purpose, implement supported image-background path and describe native bridge requirements honestly; test denial/unsupported/cleanup.
- [x] Register fixtures, run full native regression suite and actual gameplay smoke where affected; document platform limits.

## Delivered scope

Display sizing, single-window monitor selection, imports, recoverable error reporting and offline credits are implemented. The separate addon supports consent-based image backgrounds and a tested backend interface. Native overlay/window layering and automatic phone wallpaper extraction are **not implemented** in stock LÖVE; the addon reports that capability as unavailable, as its README states. No simultaneous native windows are claimed. Physical Android/Windows validation remains pending.
