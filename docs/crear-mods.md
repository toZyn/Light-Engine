### Quick Guide to Creating Mods and Using the Editors in Light Engine

Light Engine includes built-in mod support without requiring the engine to be recompiled, automatic song detection, a simple Lua API (`Mod.*`), and integrated editors for Charts, Characters, and Stages / Cutscenes.

### 1\. Create a Mod in Seconds

There are three ways to generate the complete structure of a new mod:

* From the Mods Menu: Open `Mods` and press `N` to create a ready-to-use template.

* From the Editors Menu: Press `7` in the Main Menu and select `Create New Mod`.

* From the terminal:

    ```bash
    python3 tools/create_mod.py my-mod --name "My First Mod" --author "YourName"
    ```

Generated structure inside `mods/<your-mod>/`:

```text
mods/my-mod/
├── meta.json                  # Name, description, color, and icon (pack.json is also supported)
├── icon.png                   # Optional mod icon (pack.png is also supported)
├── songs/
│   └── my-song/
│       ├── Inst.ogg           # Instrumental (.ogg, .wav, or .mp3)
│       ├── Voices.ogg         # Optional vocals (or Voices-bf.ogg / Voices-dad.ogg)
│       ├── meta.json          # Song metadata
│       ├── script.lua         # Song Lua script
│       └── charts/
│           ├── easy.json
│           ├── normal.json
│           └── hard.json
└── data/
    ├── weeks/                 # Story Mode weeks (loaded automatically)
    ├── characters/            # Character JSON files + scripts (Light, Psych, V-Slice, Codename formats)
    ├── stages/                # Stage JSON files + Lua scripts
    ├── events/                # Custom events (data/events/<event>.lua)
    ├── notetypes/             # Custom note types (data/notetypes/<type>.lua)
    ├── cutscenes/             # JSON or Lua cutscenes
    └── scripts/               # Global mod scripts
```

> Automatic Freeplay Detection: Any folder inside `mods/<your-mod>/songs/<song>/` containing charts will automatically appear in Freeplay, even if you haven't created a `week.json` file yet.

### 2\. The `Mod` API for Lua Scripts (Simple and Straightforward)

All Lua scripts (song, stage, character, event, note type, or global scripts) have access to the `Mod` object without requiring any additional configuration:

```lua
function postCreate()
    -- Create text on the HUD
    Mod.text("title", "Special Mode", 20, 20, {size = 22, color = "#38BDF8"})

    -- Create a sprite on the stage or HUD
    local spotlight = Mod.sprite("overlay", "menus/menuDesat", 0, 0, {
        camera = "hud",
        alpha = 0.15
    })

    -- Animate properties using tweens
    Mod.tween(spotlight, {alpha = 0}, 1.5, "quadOut")
end

function beat(b)
    if b % 4 == 0 then
        Mod.zoom(0.02, 0.03)                  -- Camera and HUD bop
    end
    if b == 32 then
        Mod.flash("#FFFFFF", 0.6, "hud")      -- Screen flash
        Mod.shake(0.01, 0.25, "both")         -- Camera shake
        Mod.swapCharacter("dad", "pico")      -- Swap characters during gameplay
    end
end
```

### Main `Mod` Functions

* `Mod.sprite([tag,] imagePath, x, y, opts)` — Creates and registers a `Sprite` (static image or automatically detected Sparrow atlas).

* `Mod.graphic([tag,] x, y, width, height, color, opts)` — Creates a rectangle or vector shape.

* `Mod.text([tag,] text, x, y, [size,] opts)` — Creates a `Text` object with automatic font and outline handling.

* `Mod.button([tag,] x, y, width, height, label, callback, opts)` — Creates an interactive button (`UIButton`, or `SpriteButton` when using `opts.image` / `opts.atlas`) with mouse, touchscreen, and keyboard shortcut (`opts.key`) support.

* `Mod.addMenuButton(id, label, callback, opts)` — Adds a selectable option to the Main Menu from `data/states/mainmenu.lua` (`opts.stay = true` for actions that don't change screens, or `opts.atlas` to use a Sparrow atlas).

* `Mod.get(tag)` / `Mod.remove(tag)` — Retrieves or destroys an object created through `Mod`.

* `Mod.tween(targetOrTag, props, duration, ease, onComplete)` — Creates a safe tween synchronized with the pause and gameplay states.

* `Mod.timer(seconds, callback, loops)` — Creates a timer synchronized with the current state.

* `Mod.sound(soundKey, volume, pitch)` — Plays a sound effect from `sounds/`.

* `Mod.flash(color, duration, camera)` / `Mod.shake(intensity, duration, camera)` / `Mod.zoom(gameAdd, hudAdd)` — Applies instant camera effects.

* `Mod.swapCharacter(slot, charName)` — Replaces `"bf"`, `"dad"`, or `"gf"` during a song while updating character icons and camera behavior.

* `Mod.triggerEvent(name, params)` — Triggers any chart event programmatically.

* `Mod.saveData(key, value)` / `Mod.loadData(key, default)` — Saves progress or persistent data for your mod.

### Example: Adding Buttons to Menus and Gameplay

See the complete example mod in `examples/custom-button-mod/`:

```lua
-- data/states/mainmenu.lua
function postCreate()
    Mod.addMenuButton("bonus", "Bonus Mode", function(menu, id, item)
        local enabled = not Mod.loadData("bonusMode", false)
        Mod.saveData("bonusMode", enabled)
        return true -- Stay in MainMenuState without blocking the menu list
    end, {stay = true})
end
```

```lua
-- data/scripts/hud-button.lua
function postCreate()
    Mod.button("boost_btn", 20, 96, 170, 38, "Camera Bop [B]", function(btn)
        Mod.zoom(0.025, 0.04)
    end, {key = "b", camera = "hud"})
end

function leave()
    Mod.remove("boost_btn")
end
```

### 3\. Custom Note Types and Events

### Custom Note Types (`data/notetypes/<name>.lua`)

If you place a note with the type `"Hurt Note"` in the Chart Editor and create `data/notetypes/hurt-note.lua`:

```lua
function onNoteHit(event)
    if event.note.type == "Hurt Note" then
        state.health = state.health - 0.35
        Mod.shake(0.015, 0.2, "both")
    end
end
```

### Built-in Events Ready to Use

* `FocusCamera` — Focuses the camera on `0` (BF), `1` (Dad), or `2` (GF).

* `Add Camera Zoom` — Instantly increases the game camera and HUD zoom.

* `ZoomCamera` — Changes the base camera zoom with optional interpolation.

* `ScrollSpeed` — Changes note scroll speed instantly or through a tween.

* `PlayAnimation` — Plays an animation on `bf`, `dad`, or `gf`.

* `Change Character` — Replaces `bf`, `dad`, or `gf` during a song.

* `Camera Flash` — Triggers a color flash on the `hud` or `game` camera.

* `Screen Shake` — Shakes the game camera and/or HUD.

* `Hey!` — Plays the `hey` / `cheer` animation for BF and GF.

### 4\. Built-in Editor Shortcuts

### Main Menu

* `7` — Opens the Editors Menu (`Chart Editor`, `Character Editor`, `Stage & Cutscene Editor`, `Create New Mod`).

* `8` — Opens the `Character Editor` directly.

### Freeplay / Gameplay (`PlayState`)

* `7` — Opens the current song in the `Chart Editor`.

* `8` (during gameplay) — Opens the current character in the `Character Editor`.

### Chart Editor

* Left Click on note lanes — Adds or removes a note (drag downward to create a sustain tail).

* Left Click on the `EV` column — Adds or edits an event at the selected timestamp.

* `Q` / `E` — Shortens or extends the selected note's sustain.

* `LEFT` / `RIGHT` — Changes note quantization (`1/4` through `1/64`).

* `SPACE` — Plays or pauses audio with hitsounds and an optional metronome.

* `W` / `S` or Mouse Wheel — Scrolls through the timeline (`A` / `D` jumps between sections).

* `CTRL+C` / `CTRL+V` — Copies and pastes a section.

* `CTRL+Z` / `CTRL+Y` — Undo and redo.

* `CTRL+S` — Saves the chart directly to the active mod (cross-platform).

* `ENTER` / `SHIFT+ENTER` — Tests the song from the beginning or from the current position.

### Character Editor

* Fully featured `Character` and `Animations` tabs with Ghost (Onion-Skin) support (`G`).

* `Q` / `E` — Switches between animations.

* `SPACE` — Replays the current animation.

* Arrow Keys — Adjusts offsets (`1px`, or `10px` while holding `SHIFT`).

* `WASD` / Mouse Drag — Moves the camera.

* Mouse Wheel / `CTRL + / -` — Adjusts zoom.

* `CTRL+S` — Saves the character JSON directly.
