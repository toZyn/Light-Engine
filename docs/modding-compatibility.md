# Opt-in Lua compatibility

Light Engine keeps its native Lua script lifecycle. A native script can opt in to a scoped set of Psych-like Lua helpers:

```lua
local compat = Script.createCompatibility(state, script)
function create() compat:forward('create') end
function update(dt) compat:update(dt) end
function postUpdate(dt) compat:forward('postUpdate', dt) end
function step(value) compat:forward('step', value) end
function beat(value) compat:forward('beat', value) end
function leave() compat:dispose() end

function onCreate()
    makeLuaSprite('panel', nil, 40, 40)
    makeGraphic('panel', 200, 12, 'E8793E')
    addLuaSprite('panel', true)
    setObjectCamera('panel', 'hud')
    doTweenX('slide', 'panel', 100, .5, 'quadInOut')
end
```

`script` is the current native Script handle, injected before its chunk runs. Engine code can use `require('funkin.backend.scripts.compat').new(state, script)`. Mod `require` continues to load mod classes; it does not expose arbitrary engine modules. There is one compatibility context per script. Calling the factory does not install global APIs or change other scripts.

Call `compat:update(dt)` once from the native update callback. The context advances its own native Timer and Tween instances and calls `onUpdate(dt)`. Sprites added to the state and sounds registered with SoundManager retain their normal engine updates; the bridge does not update them twice. Use song-scaled `dt` if your script requires playback scaling. Call `dispose()` in `leave`; closing the Script also disposes its context. Dispose is idempotent, cancels pending completions, removes/destroys only owned sprites/sounds, releases generated graphics, and restores prior helper variables when they have not been replaced by the script. Mutations of existing state properties remain in effect.

## Properties and cameras

| Helper | Contract |
| --- | --- |
| `getProperty(path)` | Reads an owned tag or native state field. Missing leaf values return nil; invalid paths/missing intermediate objects raise an error. |
| `setProperty(path, value)` | Writes an existing property; returns true. Does not create arbitrary missing fields. |
| `getPropertyFromGroup(group, index, property)` | Reads a native Group's `members` or a Lua array. |
| `setPropertyFromGroup(group, index, property, value)` | Writes the corresponding existing property. |

Paths accept identifier fields, dot-separated numeric indices and bracket indices: `boyfriend.scale.x`, `notes.members.0.x`, `notes.members[0].x`. Numeric indices are **zero-based** and converted to native Lua's one-based indices; ordinary identifier fields retain their names. Group indices must be nonnegative integers. Quoted keys, function calls and arithmetic expressions are not supported. Native layout is preserved: a Group needs `.members` when addressed through a raw path. Character objects must actually be present in the state; the bridge does not invent character aliases or convert notes/receptors into Psych structures.

`camGame` resolves to `state.camGame` or the engine's current `game.camera`. `camHUD`, `camOther` and `camNotes` resolve to their state fields. Nested camera properties such as `camHUD.alpha`, `camGame.scroll.x` and `camGame.zoom` use the same property helpers. HUD and notes use separate native cameras; changing HUD alpha does not automatically change notes alpha.

## Sprites and animation

| Helper | Contract |
| --- | --- |
| `makeLuaSprite(tag, image, x, y)` | Creates/replaces an owned native Sprite; image is a Paths image key without extension. Nil/empty image creates a sprite ready for `makeGraphic`. Coordinates default to zero. |
| `makeAnimatedLuaSprite(tag, image, x, y)` | Loads a native Sparrow/Packer atlas through `paths.getAtlas`. |
| `makeGraphic(tag, width, height, rgb)` | Creates an owned solid texture; dimensions are positive integers; color is six RGB hex digits, optionally prefixed by `#` or `0x`. |
| `addLuaSprite(tag, front)` | Adds/reorders an owned sprite in the state. True appends; false/nil inserts at the back (index zero). |
| `removeLuaSprite(tag, destroy)` | Removes an owned sprite; destroys by default. False retains it for reuse/re-addition. |
| `getObjectOrder(tag)` / `setObjectOrder(tag, index)` | State member order is zero-based. Get returns -1 if absent; set requires an added, owned sprite and an existing slot. |
| `setObjectCamera(tag, name)` | Accepts `game`, `hud`, `other`, `notes`, or their `camGame`/`camHUD`/`camOther`/`camNotes` names. Unavailable cameras raise an error. |
| `scaleObject(tag, x, y, updateHitbox)` | Absolute scale; y defaults to x. Updates native hitbox unless last argument is false. |
| `setScrollFactor(tag, x, y)` / `updateHitbox(tag)` / `screenCenter(tag, axes)` | Native Sprite operations; axes is `x`, `y`, `xy`, or nil. |
| `addAnimationByPrefix(tag, name, prefix, fps, looped)` | Native atlas prefix selection; fps defaults to 24, looping defaults to false. Missing frames raise an error. |
| `addAnimationByIndices(tag, name, prefix, indices, fps, looped)` | Indices are zero-based, provided as a native array or comma-separated string, e.g. `'0,2,3'`. |
| `addOffset(tag, animation, x, y)` | Sets native per-animation offset; requires the animation to exist. |
| `playAnim(tag, name, force, reversed, frame)` | Plays a native animation, optionally starting at a zero-based frame. `objectPlayAnimation` is an alias. |

Owned sprite tags must be Lua identifiers. Resource removal/layer changes operate only on this context's sprites. Property, camera, scale and animation helpers may address existing native objects; scripts own those mutations. Cached Paths images/atlases stay cache-owned and are not released by context cleanup.

## Timers, tweens and audio

| Helper | Contract |
| --- | --- |
| `runTimer(tag, seconds, loops)` | Positive interval; loops defaults to 1, zero loops forever. Reusing a tag cancels its prior timer. Calls `onTimerCompleted(tag, elapsedLoops, loopsLeft)`; infinite timers report zero loopsLeft. |
| `cancelTimer(tag)` | Cancels only this context's tag, without callback. |
| `doTweenProperty(tag, path, target, seconds, ease)` | Tweens an existing numeric native property. Positive duration, native Ease name (default `linear`). Calls `onTweenCompleted(tag)` once. |
| `doTweenX`, `doTweenY`, `doTweenAlpha`, `doTweenAngle`, `doTweenZoom` | Same signature, but second argument names the object instead of a full property path. |
| `cancelTween(tag)` | Cancels only this context's tag, without callback. |
| `playSound(key, volume, tag)` | Paths sound key; volume defaults to 1. Returns the tag, generating one if omitted. Completion calls `onSoundFinished(tag)` and disposes the owned Sound. |
| `playMusic(key, volume, looped)` | Paths music key; defaults to volume 1, looping true. Owns the reserved `__music` sound tag and leaves the native song/menu music reference intact. |
| `stopSound`, `pauseSound`, `resumeSound` | Operate on this context's sound tag. Unknown tags do nothing. |
| `setSoundVolume(tag, value)` / `getSoundVolume(tag)` | Native Sound volume; unknown get returns nil. |

Timer/Tween namespaces are per context. Timers retain native cadence: at most one completion per timer per update; a long frame does not replay every missed interval. Tween elapsed time clamps at its target before evaluating easing to avoid overshoot/invalid circular easing. Timer and tween callbacks may replace tags, cancel peers or dispose the context. Streaming Sources are independent native Sound-owned clones of cached Paths Sources; disposal preserves cached Sources and other scripts' playback. Global SoundManager owns focus handling and normal sound updates.

## Callback forwarding

The bridge never replaces native callbacks. Call these methods explicitly from your native entry points:

| Native callback passed to `compat:forward(name, ...)` | Default target |
| --- | --- |
| `create`, `postCreate` | `onCreate`, `onCreatePost` |
| `postUpdate` | `onUpdatePost` |
| `step`, `postStep` | `onStepHit`, `onStepHitPost` |
| `beat`, `postBeat` | `onBeatHit`, `onBeatHitPost` |
| `songStart`, `endSong` | `onSongStart`, `onEndSong` |
| `event` | `onEvent(name, value1, value2)` |

Step/beat forwarding sets script-local `curStep`/`curBeat` and passes the native value as an extra callback argument. `update` uses `compat:update(dt)`, not `forward`. Return values from forwarded callbacks are returned unchanged; native script code decides whether to return them to the engine. There is no automatic conversion of Psych cancellation constants, countdowns, note-hit callback signatures or native event names.

Event forwarding accepts the native `{e=..., v=...}` chart event. An array `v` provides its first two entries; a scalar or named-value table passes unchanged as value1, with nil value2. Native song scripts already have an `onEvent(event)` callback, so give the forwarded target a distinct name:

```lua
compat.callbackNames.event = 'onCompatEvent'
function onEvent(event) return compat:forward('event', event) end
function onCompatEvent(name, value1, value2) -- your event logic here
end
```

An event-specific native script can instead forward from `event(event)` to default `onEvent`. Any documented forward mapping may be renamed through that context's `callbackNames` table. Recursive callback forwarding raises a diagnostic rather than overflowing the Lua stack. Callback errors use native Script error reporting and failed-callback isolation.

## Supported boundary and example

This is an opt-in Lua bridge, not a complete Psych runtime. It does not execute Haxe, translate arbitrary foreign scripts, create a Haxe class registry, reproduce Psych note/UI fields, load videos, or wrap shaders. `runHaxeCode` and `runHaxeFunction` raise explicit unsupported-operation diagnostics. Use native Lua APIs for features outside the documented table. Unknown foreign functions remain unavailable rather than pretending to succeed.

Copy `examples/compat-mod/data/scripts/compat-demo.lua` into your native mod's `data/scripts/` directory to see a HUD graphic, beat callbacks, a looping timer and scoped tween cleanup during normal gameplay. The example uses generated graphics and requires no new image/audio assets.

`tests/engine/compat.lua` is a real LÖVE 11.5 runner fixture. It exercises native Script isolation/factory/example execution, zero-based array paths, native Sprite/atlas animation, scoped Timer/Tween completion/cancellation, disposal inside callbacks, independent static/streaming Source cleanup, retained cached Sources and same-tag ownership across scripts. Run it as `main.lua` in a temporary checkout runner with the remaining source/assets available. Tests require a working graphics/audio backend; Linux can use Xvfb and `ALSOFT_DRIVERS=null`. These tests do not establish Windows, macOS or physical Android validation.

## Native text, camera effects and scene timing

These controls are installed by the same opt-in factory. They share the context's object tags, property paths, layer ordering, camera assignment and tween helpers.

| Helper | Contract |
| --- | --- |
| `makeLuaText(tag, text, width, x, y)` | Creates/replaces an owned native Text. Width defaults to zero (no wrap limit), coordinates to zero, font size to 16. Text accepts valid UTF-8 strings or numbers. |
| `addLuaText(tag)` / `removeLuaText(tag, destroy)` | Adds an owned Text to the front of the state; removes/destroys by default, or retains it when destroy is false. |
| `setTextString(tag, text)` | Updates content and native dimensions immediately. |
| `setTextSize(tag, size)` | Positive integer pixel size; preserves the selected font filename. |
| `setTextColor(tag, rgb)` | Six RGB hex digits, optionally prefixed by `#` or `0x`. |
| `setTextAlignment(tag, alignment)` | `left`, `center`, `right`, or `justify`. |
| `setTextFont(tag, filename)` | Uses `paths.getFont(filename, currentSize)`, e.g. `vcr.ttf`. Missing fonts raise an error. |
| `cameraShake(camera, intensity, seconds, forced, axes, tag)` | Native shake; intensity is a nonnegative fraction of camera dimensions; axes defaults to `xy` and accepts `x`/`y`/`xy`. Duration defaults to one positive second. |
| `cameraFlash(camera, rgb, seconds, forced, tag)` | Native flash; defaults to white and one positive second. |
| `cameraFade(camera, rgb, seconds, forced, fadeIn, tag)` | Native fade; defaults to black and one positive second. `fadeIn=true` reveals the scene from the overlay; false/nil fades toward it. |
| `getSongPosition()` | Native engine music position in **milliseconds**, zero when no playback Source is available. |
| `getSongBpm()` / `getSongBeat()` | Current state conductor BPM/fractional beat, or nil when the state has no conductor. |

Text helpers require this context's owned Text tags and reject sprite tags. Default fonts are created explicitly per Text; creating/changing text never changes LÖVE's global font. Replacing an owned default font releases it. Paths fonts stay cache-owned: replacing/removing Text or disposing its context does not release them. Text also supports `setProperty('caption.alpha', ...)`, `doTweenX(...)`, `setObjectCamera(...)` and the other documented object controls. Existing native Text/Sprite classes retain their behavior.

Camera names use the same `game`/`hud`/`other`/`notes` aliases and must resolve to a live native Camera. Effects return true when started and false when an existing effect prevents an unforced replacement. An optional nonempty completion tag calls `onCameraEffectCompleted(tag, cameraName, effect)`; cameraName is the canonical field name such as `camHUD`, and effect is `shake`, `flash`, or `fade`. Completion notifications are delivered at the next `compat:update(dt)`, so callbacks can safely start another effect after native Camera update finishes. Native fade is a one-shot effect: the overlay is cleared when its duration finishes, including fade-out. It does not retain a persistent Psych-style black overlay. Context disposal cancels an effect only when its camera callback still belongs to that context; effects subsequently replaced by native code or other scripts remain intact. Cameras themselves stay state/engine-owned.

```lua
local scene = Script.createCompatibility(state, script)
function onCreate()
    makeLuaText('caption', 'Ready', 400, 40, 60)
    setTextSize('caption', 24)
    addLuaText('caption')
    setObjectCamera('caption', 'hud')
    cameraFade('hud', '000000', .3, true, true, 'reveal')
    doTweenX('captionSlide', 'caption', 80, .6, 'quadInOut')
end
function onUpdate(dt)
    setTextString('caption', ('Song %.1fs'):format(getSongPosition() / 1000))
end
function create() scene:forward('create') end
function update(dt) scene:update(dt) end
function leave() scene:dispose() end
```

`examples/compat-mod/data/scripts/compat-scene.lua` contains a complete native scene script with text, camera reveal/flash, song timing and beat-driven tweens. It creates its text and uses the engine's font support, without changing or replacing any mod assets.

## Cached and asynchronous asset requests

| Helper | Contract |
| --- | --- |
| `precacheImage(key)` / `precacheSound(key)` / `precacheMusic(key)` | Synchronous native Paths loading; returns the cached resource, raising an error for a missing asset. Keys omit the image/audio extension and category prefix. |
| `requestAsset(kind, key, tag, callbackName)` | Requests `image`, `sound`, or `music` through native bounded async loading. Returns a generated or supplied nonempty tag. Callback defaults to `onAssetLoaded`. |
| `cancelAssetRequest(tag)` | Suppresses this context's request callback. It leaves shared loading/cache work available to other callers. |

A completion calls `onAssetLoaded(tag, kind, key, resource, errorMessage)`. Success provides the cache-owned resource and nil error; failure provides nil resource and a diagnostic string. Cached resources and missing local paths may complete synchronously inside `requestAsset`; worker-backed requests complete when the engine advances Paths async loading. Asynchronous keys use their corresponding native loader's format. Remote image requests depend on a working native HTTPS transport; this API does not add a transport or bypass the engine's supported boundaries.

Request tags belong to one context. Reusing a tag suppresses its older callback. The wrapper checks the request token, context disposal and native async generation **before accessing returned userdata**. Leaving a scene, closing its Script, cancelling a tag or clearing the cache prevents obsolete callbacks from reaching that scene. It does not stop other scripts' requests or release cache-owned returned resources. Scripts retaining returned resources must continue to respect native cache lifetime.

`tests/engine/compat-controls.lua` verifies real Text drawing and font cleanup, shared font preservation, native Camera completion/replacement/disposal, milliseconds/BPM/beat queries, synchronous caches, real worker decoding, missing-resource callbacks, request cancellation/generation/disposal and the native scene example. It uses the same real LÖVE runner as the base compatibility tests.
