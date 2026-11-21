# Mega Modpack V3 Optimizado: informe de port preliminar

## Estado verificado

- Mods independientes preparados: 154.
- Canciones detectadas y copiadas: 595.
- Charts Psych enlazados a `songs/<nombre>/charts/<dificultad>.json`: 1265.
- Scripts Lua conservados para adaptación manual: 2065.
- Advertencias de conversión: 36.
- Recursos globales originales instalados en `addons/psych-megamodpack-shared`; requieren activación manual.
- Directorios globales `images`, `characters` y `music` del origen no se presentan como mods independientes.
- Las rutas de imágenes con mayúsculas tienen alias para resolverse en sistemas de archivos sensibles a mayúsculas.

**Importante:** conversión estructural solamente. No se ha demostrado paridad funcional con Psych Engine y no se debe distribuir como port final.

## Origen y comprobación

- Fuente: https://www.mediafire.com/file/zuandla3m3y05ez/Mega_Modpack_V3_Optimizado.zip/file
- ZIP: 1 330 654 437 bytes.
- SHA-256: `36044528004a554c8877ef821313267bab24a68b1664c3f3c5e1b2370d060007`.
- ZIP comprobado con `unzip -tq`, sin errores.
- El original permanece sin modificar en el directorio vecino `../megamodpack-source/original.zip`.
- Los archivos de mods están en `mods/` (excluidos del control de versiones por `.gitignore`).

## Prueba nativa

- Ambiente: LÖVE 11.5 sobre Linux con Xvfb y audio nulo.
- Probado el chart `31minutos / Ajena / Normal`: 221 notas del jugador, 291 del oponente.
- Se comprobó la lectura del escenario `studio` y la imagen de fondo (2560×1400).
- Tras adaptar individualmente `studio.lua` a la API nativa, el estado de juego inicializó personajes y el fondo sin fallos del script de escenario.
- El origen de `Ajena` no incluye `Voices.ogg`. El motor emitió avisos por voces ausentes; no deben confundirse con éxito de audio completo.
- Resto de canciones, cámaras, diálogos y eventos: no verificados en tiempo de juego.

## Obstáculos para la paridad

El puente optativo de Psych implementado en Light Engine es parcial. No ejecuta Haxe y no sustituye las estructuras internas de Psych. No se han activado automáticamente scripts incompatibles. Entre las llamadas registradas en el ZIP:

- `onCreate`: 1028 archivos.
- `onEvent`: 564 archivos.
- `onUpdate`: 515 archivos.
- `onTimerCompleted`: 466 archivos.
- `onBeatHit`: 365 archivos.
- `getPropertyFromGroup`: 228 archivos.
- `onStepHit`: 225 archivos.
- `opponentNoteHit`: 216 archivos.
- `setPropertyFromGroup`: 208 archivos.
- `setPropertyFromClass`: 174 archivos.
- `goodNoteHit`: 153 archivos.
- `getPropertyFromClass`: 127 archivos.
- `startVideo`: 72 archivos.
- `runHaxeCode`: 25 archivos.
- `addHaxeLibrary`: 9 archivos.
- `initLuaShader`: 4 archivos.
- `playVideo`: 4 archivos.
- `setShaderFloat`: 2 archivos.
- `setSpriteShader`: 2 archivos.

Además, el ZIP contiene 47 vídeos `.mp4` que requieren adaptación y validación de su secuencia de reproducción. Los shaders originales deben evaluarse para LÖVE/Android y las notas personalizadas deben probarse con sus efectos.

## Ejecutar la conversión de nuevo

```sh
python3 tools/port_psych_pack.py /ruta/original/mods mods --shared-addon addons/psych-megamodpack-shared --report /tmp/psych-port-report.json
```

El comando exige un directorio de salida nuevo; no sobreescribe un port existente. Se pueden seleccionar mods específicos con `--only "31minutos"`. Activar el addon compartido desde el menú de addons.

## Pruebas realizadas

- `python3 -m unittest discover -s tests -p test_*.py -q`: conjunto preexistente OK antes del port.
- `ALSOFT_DRIVERS=null xvfb-run -a python3 tools/run_engine_tests.py --love /usr/bin/love`: conjunto nativo existente OK antes del port.
- `python3 -m unittest tests/test_port_psych_pack.py -q`: conversiones y no sobrescritura OK.
- Prueba manual LÖVE de `31minutos/Ajena`: carga del chart y escena verificada.

## Pendientes críticos

1. Crear una matriz por canción, evento, note type y script que indique comportamiento esperado/implementado/probado.
2. Adaptar las 2065 unidades de scripts Lua con APIs nativas específicas y sin introducir funciones falsas o silenciosas.
3. Portar los eventos, filtros, cambios de ventanas/cámara y reproducción de vídeo según corresponda a cada mod.
4. Comparar cada canción con Psych Engine, incluidos ritmo, vida, HUD, capas, voces, animaciones y transiciones.
5. Ejecutar regresiones en Android físico y otros sistemas, incluyendo rendimiento.

No se ha hecho commit ni push de recursos originales del ZIP.
