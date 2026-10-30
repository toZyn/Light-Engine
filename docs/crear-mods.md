# Guía Rápida para Crear Mods y Usar los Editores en Light Engine

Light Engine incluye soporte directo para mods sin necesidad de recompilar el motor, detección automática de canciones, una API Lua sencilla (`Mod.*`) y editores integrados para **Charts**, **Personajes** y **Escenarios / Cutscenes**.

---

## 1. Crear un Mod en Segundos

Tienes **tres formas** de generar la estructura completa de un mod nuevo:

1. **Desde el menú de Mods**: Entra a `Mods` y presiona **`N`** para crear una plantilla lista para usar.
2. **Desde el Menú de Editores**: En el Menú Principal presiona **`7`** y elige **`Create New Mod`**.
3. **Desde la terminal**:
   ```bash
   python3 tools/create_mod.py mi-mod --name "Mi Primer Mod" --author "TuNombre"
   ```

Estructura generada dentro de `mods/<tu-mod>/`:
```text
mods/mi-mod/
├── meta.json                  # Nombre, descripción, color e ícono (también soporta pack.json)
├── icon.png                   # Ícono opcional del mod (también soporta pack.png)
├── songs/
│   └── mi-cancion/
│       ├── Inst.ogg           # Instrumental (.ogg, .wav o .mp3)
│       ├── Voices.ogg         # Voces opcionales (o Voices-bf.ogg / Voices-dad.ogg)
│       ├── meta.json          # Metadatos de la canción
│       ├── script.lua         # Script Lua de la canción
│       └── charts/
│           ├── easy.json
│           ├── normal.json
│           └── hard.json
└── data/
    ├── weeks/                 # Semanas para Story Mode (se cargan automáticamente)
    ├── characters/            # JSONs + scripts de personajes (formatos Light, Psych, V-Slice, Codename)
    ├── stages/                # JSONs + scripts Lua de escenarios
    ├── events/                # Eventos personalizados (data/events/<evento>.lua)
    ├── notetypes/             # Tipos de nota personalizados (data/notetypes/<tipo>.lua)
    ├── cutscenes/             # Cutscenes en JSON o Lua
    └── scripts/               # Scripts globales del mod
```

> **Detección automática en Freeplay**: Cualquier carpeta en `mods/<tu-mod>/songs/<cancion>/` que tenga charts aparecerá automáticamente en **Freeplay**, incluso si todavía no has creado un archivo `week.json`.

---

## 2. API `Mod` para Scripts Lua (Fácil y Directa)

Todos los scripts Lua (de canción, etapa, personaje, evento, tipo de nota o globales) tienen disponible el objeto **`Mod`** sin configuración extra:

```lua
function postCreate()
    -- Crear texto en el HUD
    Mod.text("titulo", "Modo Especial", 20, 20, {size = 22, color = "#38BDF8"})

    -- Crear un sprite en el escenario o HUD
    local foco = Mod.sprite("overlay", "menus/menuDesat", 0, 0, {
        camera = "hud",
        alpha = 0.15
    })

    -- Animar propiedades con Tween
    Mod.tween(foco, {alpha = 0}, 1.5, "quadOut")
end

function beat(b)
    if b % 4 == 0 then
        Mod.zoom(0.02, 0.03)                  -- Bop de cámara y HUD
    end
    if b == 32 then
        Mod.flash("#FFFFFF", 0.6, "hud")      -- Destello en pantalla
        Mod.shake(0.01, 0.25, "both")         -- Vibración de cámara
        Mod.swapCharacter("dad", "pico")      -- Cambiar personaje en vivo
    end
end
```

### Funciones principales de `Mod`:
- `Mod.sprite([tag,] imagePath, x, y, opts)` — Crea y registra un `Sprite` (estático o atlas Sparrow automático).
- `Mod.graphic([tag,] x, y, width, height, color, opts)` — Crea un rectángulo/forma vectorial.
- `Mod.text([tag,] text, x, y, [size,] opts)` — Crea un `Text` con borde y fuente automática.
- `Mod.button([tag,] x, y, width, height, label, callback, opts)` — Crea un botón interactivo (`UIButton`, o `SpriteButton` con `opts.image` / `opts.atlas`) compatible con ratón, pantalla táctil y tecla rápida (`opts.key`).
- `Mod.addMenuButton(id, label, callback, opts)` — Añade una opción seleccionable al Menú Principal desde `data/states/mainmenu.lua` (`opts.stay = true` para acciones sin cambiar de pantalla, o `opts.atlas` para usar un atlas Sparrow).
- `Mod.get(tag)` / `Mod.remove(tag)` — Obtiene o destruye un objeto creado con `Mod`.
- `Mod.tween(targetOrTag, props, duration, ease, onComplete)` — Tween seguro sincronizado con pausa/gameplay.
- `Mod.timer(seconds, callback, loops)` — Temporizador sincronizado con el estado.
- `Mod.sound(soundKey, volume, pitch)` — Reproduce un efecto de sonido de `sounds/`.
- `Mod.flash(color, duration, camera)` / `Mod.shake(intensity, duration, camera)` / `Mod.zoom(gameAdd, hudAdd)` — Efectos de cámara instantáneos.
- `Mod.swapCharacter(slot, charName)` — Cambia `"bf"`, `"dad"` o `"gf"` en mitad de la canción actualizando íconos y cámara.
- `Mod.triggerEvent(name, params)` — Dispara cualquier evento de chart desde código.
- `Mod.saveData(key, value)` / `Mod.loadData(key, default)` — Guarda progreso o datos persistentes de tu mod.

### Ejemplo: Añadir Botones en Menús y en Partida
Consulta el mod de ejemplo completo en [`examples/custom-button-mod/`](../examples/custom-button-mod/):

```lua
-- data/states/mainmenu.lua
function postCreate()
    Mod.addMenuButton("bonus", "Bonus Mode", function(menu, id, item)
        local enabled = not Mod.loadData("bonusMode", false)
        Mod.saveData("bonusMode", enabled)
        return true -- permanece en MainMenuState sin bloquear la lista
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

---

## 3. Tipos de Nota y Eventos Personalizados

### Tipos de Nota (`data/notetypes/<nombre>.lua`)
Si colocas una nota con tipo `"Hurt Note"` en el Chart Editor y creas `data/notetypes/hurt-note.lua`:
```lua
function onNoteHit(event)
    if event.note.type == "Hurt Note" then
        state.health = state.health - 0.35
        Mod.shake(0.015, 0.2, "both")
    end
end
```

### Eventos Integrados Listos para Usar
- `FocusCamera` — Enfoca cámara en `0` (BF), `1` (Dad) o `2` (GF).
- `Add Camera Zoom` — Impulso instantáneo de zoom en cámara y HUD.
- `ZoomCamera` — Cambia el zoom base con interpolación opcional.
- `ScrollSpeed` — Modifica la velocidad de las notas instantáneamente o con tween.
- `PlayAnimation` — Reproduce una animación en `bf`, `dad` o `gf`.
- `Change Character` — Reemplaza `bf`, `dad` o `gf` durante la canción.
- `Camera Flash` — Destello de color en `hud` o `game`.
- `Screen Shake` — Sacude la cámara del juego y/o HUD.
- `Hey!` — Reproduce la animación `hey` / `cheer` en BF y GF.

---

## 4. Atajos de los Editores Integrados

- **Menú Principal**:
  - **`7`** — Abre el menú de Editores (`Chart Editor`, `Character Editor`, `Stage & Cutscene Editor`, `Create New Mod`).
  - **`8`** — Abre directamente el `Character Editor`.
- **Freeplay / En Partida (`PlayState`)**:
  - **`7`** — Abre la canción actual en el `Chart Editor`.
  - **`8`** (en partida) — Abre el personaje actual en el `Character Editor`.
- **Chart Editor**:
  - `Clic Izquierdo` en pistas: Añadir / borrar nota (`Arrastrar` hacia abajo = crear cola sustain).
  - `Clic Izquierdo` en columna `EV`: Añadir o editar evento en ese tiempo.
  - `Q` / `E`: Acortar / alargar sustain de la nota seleccionada.
  - `IZQUIERDA` / `DERECHA`: Cambiar cuantización (`1/4` .. `1/64`).
  - `ESPACIO`: Reproducir / Pausar audio con hitsounds y metrónomo opcional.
  - `W` / `S` o `Rueda del ratón`: Desplazar línea de tiempo (`A` / `D` salta por secciones).
  - `CTRL+C` / `CTRL+V`: Copiar y pegar sección; `CTRL+Z` / `CTRL+Y`: Deshacer y rehacer.
  - `CTRL+S`: Guardar chart directamente en el mod activo (multiplataforma).
  - `ENTER` / `SHIFT+ENTER`: Probar canción desde el inicio o desde el punto actual.
- **Character Editor**:
  - Pestañas **`Character`** y **`Animations`** completas con **Ghost (Onion-Skin)** (`G`).
  - `Q` / `E`: Cambiar animación; `ESPACIO`: Repetir animación.
  - `Flechas`: Ajustar offsets (`1px`, o `10px` manteniendo `SHIFT`).
  - `WASD` / Arrastrar ratón: Mover cámara; `Rueda` / `CTRL + / -`: Zoom.
  - `CTRL+S`: Guardar JSON del personaje directamente.
