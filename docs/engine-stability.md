# Light Engine 0.1.16-advanced.2

Esta edición parte de `toZyn/Light-Engine` commit `9787da0a81c81d0c744647509a116959c2a069da`.
Es una rama experimental con correcciones concretas y una API Lua opcional para mods complejos.

## Cambios

- Audio con Sources independientes: limpiar la caché no invalida los sonidos activos, ni comparte volumen, posición o pausa entre sonidos.
- Reanudación al recuperar el foco que respeta las pausas manuales; vídeos con finalización única y audio detenido al destruirse.
- Propiedades heredadas que conservan correctamente el valor `false`.
- Cancelación de movimientos de cámara, descarte de sprites destruidos en colas pendientes y fotogramas rotados de ActorSprite, incluida su textura individual.
- La caída de FPS ya no rebobina la música ni impide avanzar los temporizadores de gameplay.
- Temporizadores/tweens toleran cancelaciones y limpieza desde callbacks, con altas nuevas pendientes para el siguiente tick.
- Carga asíncrona limitada y cancelable, con errores y propiedad de recursos definidos.
- Informes persistentes de errores Lua, scripts e hilos y pantalla de emergencia independiente de recursos del mod.
- Compatibilidad Lua opcional: propiedades, sprites, animaciones, cámaras, capas, temporizadores, tweens, audio con etiquetas, texto, efectos de cámara y precarga de recursos.
- Add-ons reutilizables: importación explícita de módulos, caché por script, dependencias anidadas, diagnóstico de ciclos y recursos con namespace propio.
- Paquetes independientes para Linux x64 y Windows x64, además de Android; verificaciones nativas de Linux y Windows en el workflow antes de publicar.

Los archivos de imágenes, audio y vídeo del juego permanecen idénticos. No se redujo resolución, tasa de fotogramas ni calidad de recursos.

Consulta [la API de mods](modding-compatibility.md), [audio](audio-lifecycle.md), [diagnósticos](engine-diagnostics.md), [carga asíncrona](async-loading.md) y [temporizadores](timer-lifecycle.md).

Consulta también [el workflow de compilación](build-validation.md).

La documentación de [módulos de add-ons](addon-modules.md), [recursos de add-ons](addon-assets.md) y [distribución de escritorio](desktop-distribution.md) incluye ejemplos completos.

## Android

El APK arm64 sirve para dispositivos como el Redmi Note 12. Usa el APK oficial 0.1.16 como base y reemplaza solamente el juego Lua embebido; conserva el lanzador Android, el manifiesto y las bibliotecas nativas oficiales. Su versión de paquete Android sigue siendo 0.1.16 y la versión interna del motor es `0.1.16-advanced.2`.

La firma usa la clave de distribución incluida en el repositorio original. La instalación como actualización depende de que el APK instalado tenga esa misma firma. Conserva una copia de tus mods y partidas antes de sustituir instalaciones.

Esta edición no recompila LÖVE/JNI/SDL/OpenAL ni demuestra que un controlador o una biblioteca nativa no pueda fallar. Android puede finalizar un proceso por presión de memoria sin dar una excepción Lua; el marcador de sesión conserva contexto, pero no demuestra la causa. Un `SIGSEGV` nativo tampoco puede recuperarse con `pcall`.

## Verificación

Se usan LÖVE 11.5 real, renderizado OpenGL por software en Linux y un dispositivo de audio nulo. Las pruebas comprueban estado de reproducción, recursos y callbacks; no son una medida de FPS del teléfono ni una prueba auditiva. Android físico, Windows, macOS e iOS requieren validación en sus dispositivos.

```sh
python3 tools/run_engine_tests.py --love /ruta/a/love
```

En Linux sin pantalla:

```sh
DISPLAY=:99 XDG_RUNTIME_DIR=/tmp ALSOFT_DRIVERS=null python3 tools/run_engine_tests.py
```

Hace falta Xvfb ya iniciado. Cada prueba usa una carpeta temporal e identidad separada. El test de integración del hook Pibby se omite si el mod no está instalado; las demás pruebas usan recursos nativos. Los resultados quedan en `test-results/`.

Para generar el juego portable:

```sh
python3 tools/make_game_love.py /ruta/salida/Light-Engine-advanced.2.love
```

La edición Android puede reconstruirse a partir del APK oficial arm64 y ese archivo:

```sh
python3 tools/repack_android.py base.apk Light-Engine-advanced.2.love unsigned.apk
zipalign -P 16 -f 4 unsigned.apk aligned.apk
# Firma aligned.apk con apksigner y verifica la firma del APK resultante.
```

Este puente no ejecuta Haxe ni convierte automáticamente cualquier mod de Psych Engine. Las funciones soportadas y sus límites están documentados; se mantienen los callbacks nativos.

## Correcciones de advanced.2

Se restaura la pantalla de error original; los informes se guardan en segundo plano. Una escritura fallida ya no anuncia un archivo inexistente. El guardado de partidas devuelve errores de E/S sin provocar una excepción por intentar usar un archivo que no se pudo abrir. Los datos permanecen en memoria si no se pueden persistir; esta corrección no concede permisos ni garantiza que se pueda guardar en un almacenamiento bloqueado. El formato de partidas hex-JSON no cambia.
