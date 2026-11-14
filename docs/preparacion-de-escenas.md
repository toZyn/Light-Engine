# Preparación de escenas y rendimiento

Light Engine 0.3.0 prepara escenas nativas en el hilo principal mediante puntos
cooperativos, mientras los workers existentes decodifican archivos. Los workers
no ejecutan scripts ni realizan llamadas gráficas.

## Pantalla de carga

La pantalla usa las ilustraciones, fuentes y atlas de `funkinloading.zip`
proporcionado para esta actualización. El código de presentación se adaptó a
Lua/LÖVE; no se incorpora el módulo Haxe original. Alterna BF/GF, incluye la
variante secreta y anima las letras de LOADING.

El progreso representa **fases**, no una predicción del tiempo restante:

| Intervalo | Trabajo |
|---|---|
| 0–25 % | Recopilar recursos, preparar shaders y ejecutar la precarga |
| 25–50 % | Decodificar archivos y subir texturas; se muestra el número completado |
| 50–100 % | Construir scripts, escenario, personajes, notas, HUD y controles; liberar recursos anteriores |

100 % aparece únicamente al retornar la preparación completa. No existe un
porcentaje que avance por tiempo ni un temporizador para fingir finalización.
Los reinicios desde pausa, Game Over y F5 comparten la misma preparación.
La entrada directa desde editores conserva su ruta síncrona compatible.

Los puntos de trabajo nativos se reparten entre actualizaciones. Una llamada
individual al driver, un atlas enorme o un script heredado que haga todo en
`create` puede ocupar un fotograma largo: Lua no puede interrumpir con seguridad
esas operaciones. Esto no promete un límite absoluto de milisegundos. Divide
contenido grande y declara sus recursos antes de usarlos.

## Manifiesto por canción

Crea `songs/<cancion>/scene.json` dentro de tu mod. Es opcional:

```json
{
  "assets": [["image", "stages/stage/stageback"]],
  "shaders": ["wave"],
  "characters": [{"slot": "dad", "character": "pico"}]
}
```

`assets` usa las mismas entradas que `preload`: `image`, `sound`, `audio`,
`inst`, `voices` y `animate`. Las rutas no llevan extensión. `animate` apunta
al directorio que contiene `Animation.json`. Los recursos resuelven con la
precedencia nativa de saves/mod/addons/assets.

`shaders` contiene nombres relativos a `shaders/`, sin `.frag` ni `.vert`.
Los nombres literales `Shader("nombre")` del script del escenario también se
preparan automáticamente; para nombres dinámicos o shaders de scripts de canción,
usa el manifiesto. Las construcciones directas con `love.graphics.newShader`
pertenecen al script y deben anticiparse en su propia precarga.

`characters` declara reemplazos por `bf`, `dad` o `gf`. Los eventos del chart
`Change Character` y `changecharacter` se descubren automáticamente, tanto con
valores `[slot, character]` como con `{slot, character}`. Los recursos y las
animaciones se preparan antes de jugar. Los scripts de personajes de reemplazo
se cargan y reciben `create` al activarse, y `postCreate` después de insertarse;
por tanto, un script arbitrariamente costoso todavía puede causar una pausa.
Los personajes retirados conservan su instancia visual para reutilización durante
esa canción. La posición base y los offsets de cámara se restablecen al volver.
Al abandonar la escena se destruyen esas instancias.

No se puede anticipar un nombre inventado por un script en mitad de la canción.
Decláralo en `characters` cuando sepas que será necesario.

## Recursos por escena

Al comenzar una carga se toma una instantánea de los caches. Durante la precarga
y la construcción se marcan las entradas reutilizadas. Después del cambio de
estado y de construir la escena, se liberan las entradas anteriores sin uso.
Las texturas y los fotogramas compartidos por atlas conservados permanecen
válidos. Las entradas de `paths.addPersistant` siguen conservándose. La cancelación durante
el juego no espera a las peticiones en curso; el cierre definitivo sí espera a
que terminen los workers retirados antes de cerrar las bibliotecas nativas. Los recursos
nuevos declarados para cambios futuros pertenecen a la escena hasta su salida.

Usa `paths.getImage/getAtlas/getAnimateAtlas` y las APIs nativas. Guardar userdata
gráfico de una escena destruida en variables globales no otorga propiedad ni
persistencia. Para recursos globales explícitos existe `paths.addPersistant`.
La gestión nativa no puede seguir referencias creadas fuera de estas APIs.

## Preferencias

El motor vuelve a aplicar downscroll, centrado, ancho/separación y splashes
al terminar `postCreate`; los nuevos Notefields heredan downscroll. Los cambios
de opciones durante pausa siguen actualizando el diseño. La separación se aplica
también fuera del modo centrado. Los controles continúan pasando por el registro
nativo de bindings y los controles virtuales respetan su preferencia global.

`Shader` respeta `ClientPrefs.data.shader`. `Camera:flash` respeta
`flashingLights`, incluso si un mod llama a la cámara directamente. Las cámaras
conservan sus fades normales y los shaders internos de representación de notas
siguen perteneciendo al renderizador. Un mod que sustituya deliberadamente el
renderizado o las posiciones en cada update debe consultar las preferencias;
el motor no desactiva sus callbacks ni prohíbe modcharts.

## Shaders y Android

La preparación valida y compila en el hilo gráfico antes de construir la escena.
En Android/iOS la validación usa el objetivo GLES. El sanitizador existente
conserva su tratamiento de precisión. Cada instancia preparada tiene su propio
programa y uniformes; no se comparte el estado mutable entre efectos. Para
varias instancias conocidas puede usarse `Shader.prepare("nombre", cantidad)`.

Un shader no compatible se omite: `Shader:get()` devuelve nil. El diagnóstico
incluye el recurso, sistema, renderer, driver y error del compilador; el fallo se
recuerda durante la escena para no repetir compilaciones fallidas. Los errores se
escriben en el registro de diagnósticos nativo. Los scripts deben admitir ese
resultado nulo y mantener la escena jugable. La validación y la compilación no
se trasladan a un servidor ni garantizan compatibilidad con todas las GPU.

## Editor, ejemplo y diagnóstico

- Abre `tools/scene_editor.html` en un navegador. Importa, edita, valida la
  estructura y descarga `scene.json`; funciona sin servidor ni dependencias.
- Valida los archivos antes de ejecutar:

```sh
python3 tools/scene_manifest.py ruta/al/mod/songs/bopeebo/scene.json --root ruta/al/mod --root assets
```

- `examples/scene-preparation-mod` es un ejemplo mínimo que reutiliza contenido
  base. Copia su manifiesto a una canción existente de tu mod.
- Los editores nativos de chart, personaje y escenario continúan disponibles
  desde el menú de editores. Consulta [Crear mods](crear-mods.md).
- Un manifiesto inválido informa su ruta y entrada; un error de preparación
  informa la fase y conserva el traceback. La pantalla muestra recursos fallidos
  y el registro mantiene el error original del worker.

## Medir y comparar

En **Options → Display → Capture performance report**, activa la captura para
la siguiente canción. Al salir se escribe un JSON en `benchmarks/` dentro de la
carpeta de guardado de LÖVE. El registro imprime su ruta. Esos informes manuales
marcan el contenido como `unverified`: no se presentan como comparación validada.

Para una comparación automática entre dos checkouts, usa la misma versión de la
herramienta y el mismo runtime:

```sh
python3 tools/benchmark_scene.py --engine ../version-anterior --love love --song bopeebo --difficulty normal --seconds 30 --device mi-telefono-o-pc --run antes --output antes.json
python3 tools/benchmark_scene.py --engine . --love love --song bopeebo --difficulty normal --seconds 30 --device mi-telefono-o-pc --run despues --output despues.json
python3 tools/compare_benchmarks.py antes.json despues.json
```

La herramienta ejecuta contenido base con botplay en un proceso nuevo por prueba,
con identidad y preferencias aisladas de la partida habitual.
Calcula SHA-256 de `assets`, excluyendo únicamente los gráficos y fuentes de la
pantalla de carga cambiados por esta versión. No carga mods o addons. Esta prueba
compara el motor con el mismo contenido jugable. Para un mod, prepara el mismo
paquete en ambos dispositivos y usa una captura instrumentada con un identificador
de contenido verificado; no mezcles sus resultados con la prueba base.

Se registran tiempo total de carga, muestras de duración entre fotogramas
renderizados, media/p50/p95/p99/máximo y picos separados de memoria Lua, memoria
de texturas reportada por LÖVE y RSS del proceso cuando `/proc/self/status` está
disponible. **No se suman** esas cifras: sus dominios se solapan y RSS no equivale
a toda la memoria GPU. El muestreo no puede capturar picos que ocurran enteramente
dentro de una llamada indivisible. La captura guarda renderer/driver, resolución,
versión, preferencias, canción, dificultad e identidad del dispositivo declarada.

La comparación rechaza diferencias de contenido, dispositivo, ajustes, resolución,
runtime, política de cache o duración solicitada. No interpreta `fresh-process`
como cache fría del sistema operativo. Realiza un calentamiento, cinco pruebas
alternadas por versión y compara las medianas; conserva todos los JSON. Usa el
mismo modo de energía, temperatura inicial y aplicaciones en segundo plano.

La comprobación de desarrollo en Linux/offscreen solo valida que la captura y
la comparación funcionan. No demuestra una mejora de velocidad ni sustituye una
medición física en Android. La pantalla nueva añade ilustraciones y la preparación
anticipa trabajo que antes podía ocurrir durante la canción: una carga total
mayor puede acompañar una transición más continua.
