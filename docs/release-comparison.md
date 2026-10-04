# Comparación: oficial 0.1.16 → advanced.6

Repositorio original: https://github.com/toZyn/Light-Engine

Base exacta: `9787da0a81c81d0c744647509a116959c2a069da` (`v0.1.16`).
Versión preparada: `0.1.16-advanced.6`, Android versionCode `122`.

| Área | Base oficial | Cambios preparados |
| --- | --- | --- |
| Audio | Rutas que consultaban Sources después de liberarlos | Guardas de vida útil, propiedad de reproducción y limpieza de música de menú |
| Mods complejos | API y controles originales | Ayudantes Lua opt-in para propiedades, sprites, animaciones, capas, temporizadores, sonido, texto y cámaras |
| Addons | Carga original | Importaciones de módulos y recursos con alcance por addon; dependencias ausentes notificadas sin cerrar el juego |
| Ventanas | Comportamiento original de tamaño y coordenadas | Controles compartidos de redimensionado, transformación de entrada, monitores y pantalla dividida Android cuando el SO lo permite |
| Errores | Errores podían llegar al manejador fatal | Avisos para errores recuperables de scripts, portapapeles y diagnóstico protegido; pantalla fatal original conservada |
| Guardados | Fallos de lectura/escritura podían interrumpir el juego | Errores de I/O comprobados, fallback y datos en memoria conservados |
| Recursos Android | `assets/game.love` copiado íntegro a caché privada | Recursos leídos desde el APK mediante AAsset, sin esa copia completa |
| Galería Android | Contenido externo susceptible a indexación | `.nomedia` al crear la carpeta de la app, antes de sus subcarpetas, tanto en Java como en Lua |
| Superposición | Sin compañero externo de esta serie de cambios | Addon separado, compañero Android con permiso y consentimiento, y compañero Windows/Linux X11 |
| Créditos | Créditos originales | Zyn / toZyn y avatar local añadidos |
| Distribución | Workflow original | Checks Linux/Windows, paquetes de escritorio portables, APKs por ABI y universal, y checksums antes de publicar |

## Calidad y límites

La comparación de Git muestra que ningún recurso existente de `assets/` o
`art/` fue modificado ni eliminado. La única adición allí es
`assets/images/menus/credits/icons/tozyn.png`. Las mejoras no reducen resolución,
fotogramas ni calidad de audio. No se garantiza ausencia de lag en todo hardware.

Las pruebas nativas locales se ejecutan con LÖVE 11.5 en Linux. Las pruebas de
política Android simulan decisiones del motor; no equivalen a ejecutar en un
Redmi. El workflow incluye ejecución real en Windows y compilación Android,
pero sus resultados solo pueden afirmarse después de ejecutarlo en GitHub.
Errores nativos, falta de memoria o fallos de drivers pueden cerrar el proceso
antes de que Lua tenga posibilidad de informar. Wayland y macOS no están
soportados por el compañero de superposición de escritorio.

## Publicación

Esta versión se publica mediante `.github/workflows/release.yml` después de
integrar los cambios en `main`. Primero crea un draft y solo lo hace público
cuando terminan los checks y las compilaciones Windows/Linux/Android, y se
verifica la presencia de los archivos requeridos y SHA256SUMS.

La integración y publicación remotas no se han completado desde este entorno:
las llamadas GitHub usan la identidad conectada `muleff`, incluso enviando otra
clave, y GitHub denegó la creación del fork con HTTP 403. Esa observación no
demuestra que la clave proporcionada por el usuario carezca de permisos.
