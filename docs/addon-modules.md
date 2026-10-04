# Reusable addon modules

Native Lua mods can import utilities from an enabled addon. Put shared code under that addon's `modules/` directory, return its public API, and import it by the addon's directory name:

```lua
local Timing = requireAddon('library-addon', 'timing')
-- Equivalent explicit namespace:
local Scene = require('addon:library-addon/scene')

function create()
  print('One bar lasts '..Timing.barMillis(120)..' milliseconds')
end
```

Copy `examples/library-addon` into the engine's addon content directory as `library-addon`, enable it in the Addons menu, and copy `examples/addon-consumer-mod` into the mod content directory. The consumer combines imported timing and scene utilities with [the opt-in scene controls](modding-compatibility.md). The library imports without creating text, cameras, timers, listeners, or global scripts; its functions perform work only when called.

## Layout and lookup

```text
addons/library-addon/
  meta.json
  modules/
    timing.lua
    scene.lua
    effects/
      init.lua
      captions.lua
```

`requireAddon(id, 'effects.captions')` loads `modules/effects/captions.lua`. `requireAddon(id, 'effects')` tries `modules/effects.lua` first, then `modules/effects/init.lua`. The addon must be installed and active in `Addons.all`. Resolution uses exactly that addon's root: another addon or a mod with the same module filename cannot override it.

The addon ID is its exact directory name, including spaces, dots or Unicode, with case preserved. For example, `require('addon:Library Tools.v1/timing')` is valid when that registry entry is active. Empty IDs, standalone `.`/`..`, separators, colons and control bytes are rejected. Module names use dot-separated Lua identifier segments: letters or `_` first, then letters, digits or `_`. Empty segments, traversal, absolute paths, slashes and backslashes are rejected. Match filename case on all systems; Linux enforces case-sensitive file lookup.

Only the `addon:` prefix changes native `require` behavior. Existing calls such as `require('pibbyruntime')` retain the engine's existing class loader. Addon modules can use either import form for dependencies:

```lua
-- modules/scene.lua
local Timing = requireAddon('library-addon', 'timing')
local Scene = {}
function Scene.duration(bpm)
  return Timing.seconds(Timing.barMillis(bpm))
end
return Scene
```

## Optional imports and dependency checks

`tryRequireAddon(id, module)` uses the same validated loader and cache, returning `export, nil` on success or `nil, errorMessage` on failure. It catches missing/disabled addons, invalid paths, cycles and module execution errors; failed modules can still retry. A successful `false` export remains `false`, so check the error value rather than treating a falsy export as failure:

```lua
local Optional, importError = tryRequireAddon('optional-library', 'effects')
if importError == nil then
  -- Use the library's documented export, which may legally be false.
else
  -- Leave this optional feature disabled. No substitute export is created.
end
```

Optional failures do not disable callbacks or automatically notify the player. If the failure deserves a notification, call `reportRecoverableError('Optional effects unavailable', importError)` explicitly.

`checkAddonDependencies(requirements)` returns `ready, issues`. Pass an array of addon ID strings to check installed/active status, or `{id = '...', module = '...'}` records to also check module file availability. Checks do not execute module code or inspect its own runtime dependencies. Each issue is a fresh `{id, module, message}` record. An empty array succeeds. A non-table argument is a programmer error.

Unavailable dependencies are reported through the engine's recoverable error service: diagnostics preserve the messages and caller traceback, while existing notifications and clipboard handling remain bounded and initialization-safe. The check does not enable addons, stop gameplay, or invent exports. The caller decides which feature to omit:

```lua
local ready, issues = checkAddonDependencies({
  {id = 'library-addon', module = 'scene'},
})
if not ready then return end -- End this script chunk before installing scene callbacks.
local Scene = requireAddon('library-addon', 'scene')
```

Strict `requireAddon` and `require('addon:...')` still raise clear errors. A native Script chunk failure closes that affected Script; a callback failure uses existing callback isolation. Other scripts and the engine continue. A dependency file can exist but fail when executed, so availability checks do not replace the strict import boundary.

`getAddonImports()` returns a fresh, path-sorted array of `{id, module, path}` records for successful imports in the calling Script, including imported dependencies. It exposes neither exports nor mutable cache entries. File/init aliases appear once under the first successful import name. Failed and availability-only checks are absent. Cached imports remain in this usage snapshot if their addon is later disabled. Closing the Script clears its usage; saved `tryRequireAddon` bindings return a closed-owner error, and the dependency/usage bindings reject closed owners.

## Scope and lifetime

Each parent native `Script` has its own module cache. A module executes once after a successful import; repeated imports return the same export. Separate scripts and separate addon paths have separate exports. File and `init.lua` aliases that resolve to the same file share one cache entry. No exports enter global `package.loaded`. A `false` export remains `false`; no returned value becomes `true`, following Lua require convention.

Modules use the native script sandbox, with the caller's `state`, `script`, engine APIs and scoped helpers available. Their global assignments stay in their own module environment. They can call [namespaced addon asset helpers](addon-assets.md) directly. Scene helpers such as `makeLuaText` require the parent script to create its compatibility context before calling those helpers; imports can occur earlier if module initialization does not use them.

Importing does not launch addon global scripts or enable addons. Disabling an addon blocks subsequent imports, including cache hits, but does not undo resources or behavior already created by its functions.

Cyclic imports fail with the dependency chain. Load or execution failures clear that module's loading guard and cache entry so a later import can retry. Successfully loaded dependencies remain cached, and explicit state changes made before an error remain the caller's responsibility. Errors escaping a native script chunk or callback use the engine's persistent diagnostics, with the module filename and original nested traceback; normal callback isolation still applies.

`Script:close()` clears its addon cache and module environments. Saved import functions reject calls after close, and modules do not add message listeners. Exported functions that access their closed module environment also raise a clear error. Values or local references explicitly retained by a caller remain ordinary Lua values: scripts must dispose resources they create through the normal native lifecycle or compatibility context. The loader does not infer arbitrary module destructors.

## Registry helpers

| Native helper | Result |
| --- | --- |
| `Addons.has(id)` | Whether the exact addon ID is installed, including disabled addons |
| `Addons.has(id, true)` | Whether it is installed and active |
| `Addons.list(activeOnly)` | Fresh ordered `{path, active}` records; changing them does not alter the registry |
| `Addons.getMetadata(id)` | Metadata for an installed ID; the existing addon-record form also works |
| `Addons.hasModule(id, name)` | `true, resolvedPath` for an available active module; otherwise `false, nil`; does not execute it |

An optional library can be checked before import:

```lua
if Addons.hasModule('library-addon', 'timing') then
  local Timing = requireAddon('library-addon', 'timing')
  -- Use its documented API here.
end
```

## Verification

`tests/engine/addon-modules.lua` uses real addon directories, registry reload and native Script execution. It covers active/disabled IDs, spaced and Unicode names, scoped caches, collisions, nested/init imports, false/nil exports, cyclic and failed-import retry, original error traces, invalid paths, closed imports, safe optional failures/false exports, dependency diagnostics without module execution, fresh usage snapshots and the complete consumer scene with and without its library. It passed with official Linux LÖVE 11.5. The API uses LÖVE virtual paths and avoids platform-specific separators; execution on physical Windows and Android remains unverified.
