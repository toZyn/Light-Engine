# Screen Overlay: imagen sobre el inicio y otras aplicaciones

Add-on opcional para Light Engine advanced.3. Un mod puede enviar un PNG original a un componente separado que crea una ventana transparente sobre otras aplicaciones. No captura el juego, no lee el fondo de pantalla y no cambia los recursos del mod. Importar el módulo no muestra ninguna imagen ni pide permisos.

## Android

1. Instala `Light-Engine-screen-overlay-android.apk` **además del juego**. Es una aplicación pequeña independiente, compatible desde Android 8.
2. Extrae este ZIP y coloca la carpeta `screen-overlay` dentro de la carpeta `addons` del motor. Actívala desde el menú de add-ons. Usa la carpeta de contenido que utiliza tu instalación para sus mods.
3. Cuando el mod envíe una imagen, confirma la solicitud del componente. Si falta el permiso Android **Mostrar sobre otras aplicaciones**, se abrirán sus ajustes; concédelo y vuelve al componente.
4. Quita la imagen con **×**, el control **Stop** de la notificación o `overlay.hide()`. No ocupa toda la pantalla ni toma el teclado. Cancelar no da permiso.

Cada imagen necesita aprobación. La entrega mediante enlace Android tiene un límite de **256 KiB por PNG original**; no se recomprime ni reduce su resolución para cumplirlo. Las dimensiones originales máximas son 4096 por eje y 16 millones de píxeles. El tamaño de la ventana se adapta al espacio disponible sin deformar la imagen. Android o una aplicación protegida pueden restringir las superposiciones.

## Windows y Linux X11

El componente está en `desktop/`, con sus instrucciones de instalación y registro explícito del protocolo. Requiere Python y PySide6. Confirma la solicitud de emparejamiento y usa × o Stop para quitar la imagen. El límite de PNG original es **8 MiB**. Wayland y macOS no están soportados por este componente.

## Uso desde un script del mod

```lua
local overlay

function create()
    local Toolkit, err = tryRequireAddon('screen-overlay', 'overlay')
    if not Toolkit then
        reportRecoverableError(err)
        return
    end
    overlay = Toolkit.new({label = 'Mi mod'})
    if overlay then
        -- Demostración opcional: este PNG es una copia exacta del icono del motor.
        -- Solo se solicita cuando el mod llama esta función.
        local pending, message = overlay.showAddonImage(
            'screen-overlay', 'images/example.png', {x = 32, y = 100, width = 128})
        -- pending indica solicitud enviada/pendiente, no visibilidad confirmada.
    end
end

function destroy()
    if overlay then overlay.close() end
end
```

Para la imagen de tu mod usa `overlay.showModImage('images/mi-imagen.png', geometria)`. Para bytes PNG originales usa `overlay.showPng(bytes, geometria)`. Las etiquetas admiten hasta 80 bytes UTF-8, sin caracteres de control. La geometría opcional admite x/y entre −100000 y 100000 y width/height entre 1 y 4096, todos enteros; si omites tamaños se conservan los originales y si solo das un eje se conserva la proporción. La posición se ajusta para mantener accesible el cierre. No debes enviar una imagen cada frame: úsalo al cambiar de escena o ante una acción concreta.

`overlay.getStatus()` devuelve una copia del estado. `accepted` en escritorio confirma que el componente aceptó la entrega en su cola, no que el gestor de ventanas la haya mostrado. En Android queda `pending`: abrir el enlace no permite comprobar desde Lua el permiso ni la aceptación. `hide()` solicita quitarla; `close()` libera la sesión y solicita su retirada. Los fallos de entrega se notifican como errores recuperables. El cierre del script también libera la sesión.

El ZIP incluye el código de ambos componentes, pruebas y un PNG de ejemplo. El APK nativo se distribuye aparte. Las pruebas verifican el transporte sin cambiar bytes, consentimiento, cancelación y ventanas Qt reales en Linux X11 virtual; no sustituyen una prueba en un Redmi Note 12 o un escritorio Windows físico.
