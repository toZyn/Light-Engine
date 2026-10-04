# Audio ownership and playback lifecycle

`Sound:load(source)` clones a LÖVE Source. `Sound:load(soundData)` creates a
static Source. Each Sound owns its playback, so volume, pitch, seek, looping,
pause and destruction do not affect other Sounds using the same cached asset.
`paths` continues to own its originals; clearing its cache does not invalidate
active Sounds. Reloading or destroying a Sound stops and releases its owned
Source. Mods should use Sound methods instead of releasing `sound._source`.

An externally released Source makes its Sound inactive. Reads return safe
defaults (`duration = -1`, `time = 0`, `looped = false`) and cleanup remains
safe. Invalid loads and genuine Source argument errors still raise errors.

Focus gain resumes only playback paused by focus loss. An explicit pause or
stop cancels pending automatic resume. A Video starts through `Video:play()`;
dormant and manually paused Videos stay inactive during focus changes and
updates. Video completion fires once per playback. Destroying a Video pauses
its drawable and stops its audio before discarding the references, including
when the containing state exits without a mod-specific disposal callback.

The Pibby `pibbyaudio` cache hook remains compatible: engine-owned clones are
absent from the cache, so its borrowed-Source transfer branch does not clone
them again or leave duplicate menu music in the audio pool.

## Regression test

`tests/engine/audio.lua` is a standalone LÖVE fixture. Use it as `main.lua` in a
disposable runner containing this checkout's `loxel`, `funkin`, `lib`, `assets`,
`mods`, `art` and `project.lua`. Enable the window in the runner's `conf.lua`;
the fixture uses a real `.ogv` and audio Sources. The checkout's normal startup
`main.lua` is not loaded. A minimal runner configuration is:

```lua
function love.conf(t)
 t.identity = 'engine-audio-tests'
 t.window.width, t.window.height = 64, 64
 t.modules.physics = false
end
```

Run `love <runner>` with LÖVE 11.5. It prints each assertion and returns a
nonzero exit status on failure. The focused suite tests engine ownership,
cache eviction, independent streams, external release handling, explicit loop
disable, focus behavior, video destruction/completion and the original Pibby
cache hook. Full native menu/song tests belong to the integration suite.

The recorded runs use Linux with a null OpenAL output driver. They validate
native playback state and resource ownership; they do not establish physical
Android/iOS device behavior or listening quality.
