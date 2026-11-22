# Psych Engine 1.0.4 / Light Engine — API inventory

Psych tag `1.0.4`, commit `5c67ced49e5a98535298a6daa3f8f4ec79ac8399`. Light commit `567588a1620a0651eae8822fbddcd17f1d624aa7` (PR #22).

## Interpretation and scope

Static source audit, not a runtime certification. `implementada` requires demonstrated equivalent behavior; `distinta` means an exposed entry has a constrained model or unverified parity; `ausente` means no equivalent exposure was found in the audited installers. An absent entry points to a candidate installer and says so. The original audit made no engine changes. Batch 1 changes are recorded at the end of this document.

Lua registration inventory covers all 223 distinct literal registration names in Psych source/psychlua, including deprecated aliases and optional compile flags. HScript rows cover Psych preset bindings. Property rows cover declarations in PlayState, SwagSong, Note and StrumNote, plus initialized Lua globals and explicit group paths. Inherited framework properties, dynamically created mod variables, and arbitrary imported Haxe classes are not exhaustively enumerated; their full surface cannot be inferred from these engine declarations. This document therefore does not claim complete HaxeFlixel/OpenFL property coverage. Private/class fields are included where found; exposure remains route-dependent.

A definition or name match alone does not demonstrate equivalent semantics. Conservative `distinta` entries make that limitation explicit. Function rows distinguish available exposure from absent exposure in their notes.

Lua registration names: **223**. Total rows: **731**.

## Inventory

| funcion | familia | estado_light | archivo_linea | notas |
|---|---|---|---|---|
| FlxColor | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:19 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:701 |
| addAnimation | Lua/sprites | distinta | funkin/backend/scripts/psych/media.lua:53 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:980 |
| addAnimationByIndices | Lua/sprites | distinta | funkin/backend/scripts/compat.lua:376 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:984 |
| addAnimationByIndicesLoop | Lua/sprites | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/DeprecatedFunctions.hx:14 |
| addAnimationByPrefix | Lua/sprites | distinta | funkin/backend/scripts/compat.lua:371 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:964 |
| addAnimationBySymbol | Lua/sprites | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FlxAnimateFunctions.hx:32 |
| addAnimationBySymbolIndices | Lua/sprites | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FlxAnimateFunctions.hx:47 |
| addCameraFollowPoint | Lua/camara | distinta | funkin/backend/scripts/psych/media.lua:112 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:828 |
| addCameraScroll | Lua/camara | distinta | funkin/backend/scripts/psych/media.lua:105 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:827 |
| addCharacterToList | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:707 |
| addHScript | Lua/scripts | distinta | funkin/backend/scripts/psych/scripts.lua:45 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:311 |
| addHealth | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/gameplay.lua:94 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:697 |
| addHits | Lua/puntuacion | distinta | funkin/backend/scripts/psych/gameplay.lua:95 | Generada por bucle en funkin/backend/scripts/psych/gameplay.lua:95. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:680 |
| addInstance | Lua/reflexion | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ReflectionFunctions.hx:244 |
| addLuaScript | Lua/scripts | distinta | funkin/backend/scripts/psych/scripts.lua:44 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:294 |
| addLuaSprite | Lua/sprites | distinta | funkin/backend/scripts/compat.lua:331 | Expuesta; los personajes comparten Stage y no existen tres grupos intercambiables como en Psych. Psych source/psychlua/FunkinLua.hx:1025 |
| addLuaText | Lua/texto | distinta | funkin/backend/scripts/compat-controls.lua:106 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/TextFunctions.hx:185 |
| addMisses | Lua/puntuacion | distinta | funkin/backend/scripts/psych/gameplay.lua:95 | Generada por bucle en funkin/backend/scripts/psych/gameplay.lua:95. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:676 |
| addOffset | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat.lua:390 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1004 |
| addScore | Lua/puntuacion | distinta | funkin/backend/scripts/psych/gameplay.lua:95 | Generada por bucle en funkin/backend/scripts/psych/gameplay.lua:95. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:672 |
| addToGroup | Lua/reflexion | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ReflectionFunctions.hx:136 |
| anyGamepadJustPressed | Lua/entrada | distinta | funkin/backend/scripts/psych/input.lua:29 | Maps controller IDs as LÖVE getID()-1 and uses fixed digital-stick threshold 0.5; Flixel controller mappings and per-device thresholds are not reproduced. Haxe callback vectors pass against supplied input-state providers. |
| anyGamepadPressed | Lua/entrada | distinta | funkin/backend/scripts/psych/input.lua:29 | Maps controller IDs as LÖVE getID()-1 and uses fixed digital-stick threshold 0.5; Flixel controller mappings and per-device thresholds are not reproduced. Haxe callback vectors pass against supplied input-state providers. |
| anyGamepadReleased | Lua/entrada | distinta | funkin/backend/scripts/psych/input.lua:29 | Maps controller IDs as LÖVE getID()-1 and uses fixed digital-stick threshold 0.5; Flixel controller mappings and per-device thresholds are not reproduced. Haxe callback vectors pass against supplied input-state providers. |
| callMethod | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ReflectionFunctions.hx:200 |
| callMethodFromClass | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ReflectionFunctions.hx:215 |
| callScript | Lua/scripts | distinta | funkin/backend/scripts/psych/scripts.lua:49 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:252 |
| cameraFade | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat-controls.lua:164 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:844 |
| cameraFlash | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat-controls.lua:163 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:841 |
| cameraSetTarget | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:93 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:813 |
| cameraShake | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat-controls.lua:157 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:837 |
| cancelTimer | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat.lua:415 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:669 |
| cancelTween | Lua/tweens | distinta | funkin/backend/scripts/compat.lua:414 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:653 |
| characterDance | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:39 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:929 |
| characterPlayAnim | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat.lua:513 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/DeprecatedFunctions.hx:33 |
| checkFileExists | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/files.lua:38 | Native files.json contract vectors pass (returns/defaults/missing paths/failure). Path lookup uses Light saves/mods/assets resolution, not all Psych shared/global-mod search rules; absolute directory access depends on LÖVE mounting restrictions and host permissions. |
| closeCustomSubstate | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/substate.lua:53 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/CustomSubstate.hx:15 |
| createInstance | Lua/reflexion | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ReflectionFunctions.hx:219 |
| debugPrint | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:161 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1550 |
| deleteFile | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/files.lua:64 | Native files.json contract vectors pass (returns/defaults/missing paths/failure). Path lookup uses Light saves/mods/assets resolution, not all Psych shared/global-mod search rules; absolute directory access depends on LÖVE mounting restrictions and host permissions. |
| directoryFileList | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/files.lua:69 | Native files.json contract vectors pass (returns/defaults/missing paths/failure). Path lookup uses Light saves/mods/assets resolution, not all Psych shared/global-mod search rules; absolute directory access depends on LÖVE mounting restrictions and host permissions. |
| doTweenAlpha | Lua/tweens | distinta | funkin/backend/scripts/compat.lua:408 | Generada por bucle en funkin/backend/scripts/compat.lua:408. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:563 |
| doTweenAngle | Lua/tweens | distinta | funkin/backend/scripts/compat.lua:408 | Generada por bucle en funkin/backend/scripts/compat.lua:408. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:560 |
| doTweenColor | Lua/tweens | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:577 |
| doTweenX | Lua/tweens | distinta | funkin/backend/scripts/compat.lua:408 | Generada por bucle en funkin/backend/scripts/compat.lua:408. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:554 |
| doTweenY | Lua/tweens | distinta | funkin/backend/scripts/compat.lua:408 | Generada por bucle en funkin/backend/scripts/compat.lua:408. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:557 |
| doTweenZoom | Lua/tweens | distinta | funkin/backend/scripts/compat.lua:408 | Generada por bucle en funkin/backend/scripts/compat.lua:408. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:566 |
| endSong | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:736 |
| eraseSaveData | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ExtraFunctions.hx:139 |
| exitSong | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:747 |
| flushSaveData | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ExtraFunctions.hx:108 |
| gamepadAnalogX | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/input.lua:36 | Default left stick and disconnected return 0 match Haxe vectors. LÖVE IDs use getID()-1; dead zone is fixed at 0.15 instead of Flixel per-device configuration. |
| gamepadAnalogY | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/input.lua:36 | Default left stick and disconnected return 0 match Haxe vectors. LÖVE IDs use getID()-1; dead zone is fixed at 0.15 instead of Flixel per-device configuration. |
| gamepadJustPressed | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/input.lua:24 | Maps controller IDs as LÖVE getID()-1 and uses fixed digital-stick threshold 0.5; Flixel controller mappings and per-device thresholds are not reproduced. Haxe callback vectors pass against supplied input-state providers. |
| gamepadPressed | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/input.lua:24 | Maps controller IDs as LÖVE getID()-1 and uses fixed digital-stick threshold 0.5; Flixel controller mappings and per-device thresholds are not reproduced. Haxe callback vectors pass against supplied input-state providers. |
| gamepadReleased | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/input.lua:24 | Maps controller IDs as LÖVE getID()-1 and uses fixed digital-stick threshold 0.5; Flixel controller mappings and per-device thresholds are not reproduced. Haxe callback vectors pass against supplied input-state providers. |
| getCameraFollowX | Lua/camara | distinta | funkin/backend/scripts/psych/media.lua:116 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:834 |
| getCameraFollowY | Lua/camara | distinta | funkin/backend/scripts/psych/media.lua:117 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:835 |
| getCameraScrollX | Lua/camara | distinta | funkin/backend/scripts/psych/media.lua:109 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:832 |
| getCameraScrollY | Lua/camara | distinta | funkin/backend/scripts/psych/media.lua:110 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:833 |
| getCharacterX | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:28 | Generada por bucle en funkin/backend/scripts/psych/media.lua:28. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:773 |
| getCharacterY | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:28 | Generada por bucle en funkin/backend/scripts/psych/media.lua:28. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:793 |
| getColorFromHex | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:20 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:704 |
| getColorFromName | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:20 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:702 |
| getColorFromString | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:20 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:703 |
| getDataFromSave | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ExtraFunctions.hx:117 |
| getGraphicMidpointX | Lua/sprites | distinta | funkin/backend/scripts/psych/media.lua:79 | Generada por bucle en funkin/backend/scripts/psych/media.lua:79. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:889 |
| getGraphicMidpointY | Lua/sprites | distinta | funkin/backend/scripts/psych/media.lua:79 | Generada por bucle en funkin/backend/scripts/psych/media.lua:79. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:899 |
| getHealth | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/gameplay.lua:92 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:698 |
| getMidpointX | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:79 | Generada por bucle en funkin/backend/scripts/psych/media.lua:79. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:869 |
| getMidpointY | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:79 | Generada por bucle en funkin/backend/scripts/psych/media.lua:79. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:879 |
| getMouseX | Lua/entrada | distinta | funkin/backend/scripts/psych/media.lua:118 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:860 |
| getMouseY | Lua/entrada | distinta | funkin/backend/scripts/psych/media.lua:122 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:864 |
| getObjectOrder | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat.lua:343 | Expuesta; los personajes comparten Stage y no existen tres grupos intercambiables como en Psych. Psych source/psychlua/FunkinLua.hx:439 |
| getPixelColor | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/queries.lua:38 | Reads native texture pixels via canvas readback. Psych reads sprite.pixels; Light makeGraphic stores its color as tint, so a tinted generated graphic can yield different pixels. Bounds/missing-sprite and raw RGBA texture are tested; Mali readback is unverified. |
| getProperty | Lua/reflexion | distinta | funkin/backend/scripts/psych/notes.lua:125 | Expuesta con resolucion limitada de rutas, clases y propiedades; no equivale a la reflexion de Psych. Psych source/psychlua/ReflectionFunctions.hx:19 |
| getPropertyFromClass | Lua/reflexion | distinta | funkin/backend/scripts/psych/gameplay.lua:24 | Expuesta con resolucion limitada de rutas, clases y propiedades; no equivale a la reflexion de Psych. Psych source/psychlua/ReflectionFunctions.hx:34 |
| getPropertyFromGroup | Lua/reflexion | distinta | funkin/backend/scripts/psych/notes.lua:114 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ReflectionFunctions.hx:72 |
| getPropertyLuaSprite | Lua/reflexion | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/DeprecatedFunctions.hx:110 |
| getRandomBool | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/utilities.lua:66 | Matches seeded FlxRandom 5.6.1 vectors and defaults. Light owns a Lua random stream rather than sharing FlxG.random. Entirely excluded integer ranges raise an error instead of looping. Invalid exclusion-number parsing is not fully identical. |
| getRandomFloat | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/utilities.lua:65 | Matches seeded FlxRandom 5.6.1 vectors and defaults. Light owns a Lua random stream rather than sharing FlxG.random. Entirely excluded integer ranges raise an error instead of looping. Invalid exclusion-number parsing is not fully identical. |
| getRandomInt | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/utilities.lua:64 | Matches seeded FlxRandom 5.6.1 vectors and defaults. Light owns a Lua random stream rather than sharing FlxG.random. Entirely excluded integer ranges raise an error instead of looping. Invalid exclusion-number parsing is not fully identical. |
| getRunningScripts | Lua/scripts | implementada | funkin/backend/scripts/psych/utilities.lua:67 | Returns open Lua Psych script paths in handler order, excludes HScript, matching game.luaArray enumeration. Integration test verifies installed API and path. |
| getScreenPositionX | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/queries.lua:25 | Exposed. Uses x/y minus camera scroll times scrollFactor. Does not apply Flixel pixelPerfectPosition rounding or all camera aliases; integration tests cover numeric offsets and missing-object return 0. |
| getScreenPositionY | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/queries.lua:25 | Exposed. Uses x/y minus camera scroll times scrollFactor. Does not apply Flixel pixelPerfectPosition rounding or all camera aliases; integration tests cover numeric offsets and missing-object return 0. |
| getShaderBool | Lua/shaders | distinta | funkin/backend/scripts/psych/shaders.lua:184 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ShaderFunctions.hx:65 |
| getShaderBoolArray | Lua/shaders | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ShaderFunctions.hx:79 |
| getShaderFloat | Lua/shaders | distinta | funkin/backend/scripts/psych/shaders.lua:184 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ShaderFunctions.hx:121 |
| getShaderFloatArray | Lua/shaders | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ShaderFunctions.hx:135 |
| getShaderInt | Lua/shaders | distinta | funkin/backend/scripts/psych/shaders.lua:184 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ShaderFunctions.hx:93 |
| getShaderIntArray | Lua/shaders | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ShaderFunctions.hx:107 |
| getSongPosition | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat-controls.lua:165 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:769 |
| getSoundPitch | Lua/audio | distinta | funkin/backend/scripts/psych/media.lua:150 | Generada por bucle en funkin/backend/scripts/psych/media.lua:150. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1482 |
| getSoundTime | Lua/audio | distinta | funkin/backend/scripts/psych/media.lua:150 | Generada por bucle en funkin/backend/scripts/psych/media.lua:150. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1457 |
| getSoundVolume | Lua/audio | distinta | funkin/backend/scripts/compat.lua:441 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1426 |
| getTextFont | Lua/texto | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/TextFunctions.hx:164 |
| getTextFromFile | Lua/texto | distinta | funkin/backend/scripts/psych/files.lua:42 | Native files.json contract vectors pass (returns/defaults/missing paths/failure). Path lookup uses Light saves/mods/assets resolution, not all Psych shared/global-mod search rules; absolute directory access depends on LÖVE mounting restrictions and host permissions. |
| getTextSize | Lua/texto | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/TextFunctions.hx:154 |
| getTextString | Lua/texto | distinta | funkin/backend/scripts/compat.lua:459 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/TextFunctions.hx:144 |
| getTextWidth | Lua/texto | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/TextFunctions.hx:174 |
| getVar | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/init.lua:473 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:290 |
| initSaveData | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ExtraFunctions.hx:96 |
| insertToCustomSubstate | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/substate.lua:62 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/CustomSubstate.hx:16 |
| instanceArg | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ReflectionFunctions.hx:261 |
| isRunning | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/scripts.lua:48 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:265 |
| keyJustPressed | Lua/entrada | implementada | funkin/backend/scripts/psych/input.lua:15 | Matches original callback results/defaults and case sensitivity in input.json. Keyboard events use Light state; key functions use configured gameplay controls. Unknown control returns false. |
| keyPressed | Lua/entrada | implementada | funkin/backend/scripts/psych/input.lua:15 | Matches original callback results/defaults and case sensitivity in input.json. Keyboard events use Light state; key functions use configured gameplay controls. Unknown control returns false. |
| keyReleased | Lua/entrada | implementada | funkin/backend/scripts/psych/input.lua:15 | Matches original callback results/defaults and case sensitivity in input.json. Keyboard events use Light state; key functions use configured gameplay controls. Unknown control returns false. |
| keyboardJustPressed | Lua/entrada | implementada | funkin/backend/scripts/psych/input.lua:10 | Matches original callback results/defaults and case sensitivity in input.json. Keyboard events use Light state; key functions use configured gameplay controls. Unknown control returns false. |
| keyboardPressed | Lua/entrada | implementada | funkin/backend/scripts/psych/input.lua:10 | Matches original callback results/defaults and case sensitivity in input.json. Keyboard events use Light state; key functions use configured gameplay controls. Unknown control returns false. |
| keyboardReleased | Lua/entrada | implementada | funkin/backend/scripts/psych/input.lua:10 | Matches original callback results/defaults and case sensitivity in input.json. Keyboard events use Light state; key functions use configured gameplay controls. Unknown control returns false. |
| loadAnimateAtlas | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FlxAnimateFunctions.hx:27 |
| loadFrames | Lua/sprites | distinta | funkin/backend/scripts/psych/media.lua:50 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:413 |
| loadGraphic | Lua/sprites | distinta | funkin/backend/scripts/psych/media.lua:44 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:399 |
| loadMultipleFrames | Lua/sprites | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:425 |
| loadSong | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:377 |
| luaSoundExists | Lua/audio | distinta | funkin/backend/scripts/psych/media.lua:137 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1127 |
| luaSpriteAddAnimationByIndices | Lua/sprites | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/DeprecatedFunctions.hx:62 |
| luaSpriteAddAnimationByPrefix | Lua/sprites | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/DeprecatedFunctions.hx:52 |
| luaSpriteExists | Lua/sprites | distinta | funkin/backend/scripts/compat.lua:442 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1119 |
| luaSpriteMakeGraphic | Lua/sprites | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/DeprecatedFunctions.hx:47 |
| luaSpritePlayAnimation | Lua/sprites | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/DeprecatedFunctions.hx:77 |
| luaTextExists | Lua/texto | distinta | funkin/backend/scripts/compat.lua:443 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1123 |
| makeAnimatedLuaSprite | Lua/sprites | distinta | funkin/backend/scripts/compat.lua:313 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:948 |
| makeFlxAnimateSprite | Lua/sprites | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FlxAnimateFunctions.hx:11 |
| makeGraphic | Lua/sprites | distinta | funkin/backend/scripts/compat.lua:314 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:960 |
| makeLuaSprite | Lua/sprites | distinta | funkin/backend/scripts/compat.lua:312 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:937 |
| makeLuaText | Lua/texto | distinta | funkin/backend/scripts/compat-controls.lua:94 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/TextFunctions.hx:8 |
| mouseClicked | Lua/entrada | distinta | funkin/backend/scripts/psych/media.lua:126 | Generada por bucle en funkin/backend/scripts/psych/media.lua:126. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:619 |
| mousePressed | Lua/entrada | distinta | funkin/backend/scripts/psych/media.lua:126 | Generada por bucle en funkin/backend/scripts/psych/media.lua:126. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:630 |
| mouseReleased | Lua/entrada | distinta | funkin/backend/scripts/psych/media.lua:126 | Generada por bucle en funkin/backend/scripts/psych/media.lua:126. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:641 |
| musicFadeIn | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/DeprecatedFunctions.hx:143 |
| musicFadeOut | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/DeprecatedFunctions.hx:148 |
| noteTweenAlpha | Lua/tweens | distinta | funkin/backend/scripts/psych/notes.lua:132 | Generada por bucle en funkin/backend/scripts/psych/notes.lua:132. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:613 |
| noteTweenAngle | Lua/tweens | distinta | funkin/backend/scripts/psych/notes.lua:132 | Generada por bucle en funkin/backend/scripts/psych/notes.lua:132. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:610 |
| noteTweenDirection | Lua/tweens | distinta | funkin/backend/scripts/psych/notes.lua:132 | Generada por bucle en funkin/backend/scripts/psych/notes.lua:132. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:616 |
| noteTweenX | Lua/tweens | distinta | funkin/backend/scripts/psych/notes.lua:132 | Generada por bucle en funkin/backend/scripts/psych/notes.lua:132. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:604 |
| noteTweenY | Lua/tweens | distinta | funkin/backend/scripts/psych/notes.lua:132 | Generada por bucle en funkin/backend/scripts/psych/notes.lua:132. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:607 |
| objectPlayAnimation | Lua/sprites | distinta | funkin/backend/scripts/compat.lua:406 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/DeprecatedFunctions.hx:19 |
| objectsOverlap | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/queries.lua:34 | AABB and recursive member queries. Does not reproduce Flixel quadtree world bounds or sprite-group position propagation. Integration tests cover crossing, touching edges, self and missing objects. |
| openCustomSubstate | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/substate.lua:14 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/CustomSubstate.hx:14 |
| pauseSound | Lua/audio | distinta | funkin/backend/scripts/compat.lua:436 | Generada por bucle en funkin/backend/scripts/compat.lua:436. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1358 |
| playAnim | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat.lua:395 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:988 |
| playMusic | Lua/audio | distinta | funkin/backend/scripts/compat.lua:434 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1314 |
| playSound | Lua/audio | distinta | funkin/backend/scripts/compat.lua:433 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1317 |
| precacheImage | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat-controls.lua:175 | Generada por bucle en funkin/backend/scripts/compat-controls.lua:175. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:715 |
| precacheMusic | Lua/audio | distinta | funkin/backend/scripts/compat-controls.lua:175 | Generada por bucle en funkin/backend/scripts/compat-controls.lua:175. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:721 |
| precacheSound | Lua/audio | distinta | funkin/backend/scripts/compat-controls.lua:175 | Generada por bucle en funkin/backend/scripts/compat-controls.lua:175. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:718 |
| removeFromGroup | Lua/reflexion | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ReflectionFunctions.hx:164 |
| removeHScript | Lua/scripts | distinta | funkin/backend/scripts/psych/scripts.lua:47 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:352 |
| removeLuaScript | Lua/scripts | distinta | funkin/backend/scripts/psych/scripts.lua:46 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:332 |
| removeLuaSprite | Lua/sprites | distinta | funkin/backend/scripts/compat.lua:342 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1102 |
| removeLuaText | Lua/texto | distinta | funkin/backend/scripts/compat-controls.lua:107 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/TextFunctions.hx:189 |
| removeSpriteShader | Lua/shaders | distinta | funkin/backend/scripts/psych/shaders.lua:155 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ShaderFunctions.hx:50 |
| restartSong | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:741 |
| resumeSound | Lua/audio | distinta | funkin/backend/scripts/compat.lua:436 | Generada por bucle en funkin/backend/scripts/compat.lua:436. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1371 |
| runTimer | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat.lua:418 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:655 |
| saveFile | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/files.lua:55 | Native files.json contract vectors pass (returns/defaults/missing paths/failure). Path lookup uses Light saves/mods/assets resolution, not all Psych shared/global-mod search rules; absolute directory access depends on LÖVE mounting restrictions and host permissions. |
| scaleLuaSprite | Lua/sprites | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/DeprecatedFunctions.hx:100 |
| scaleObject | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat.lua:363 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1061 |
| screenCenter | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat.lua:370 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1191 |
| setBlendMode | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:67 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1171 |
| setCameraFollowPoint | Lua/camara | distinta | funkin/backend/scripts/psych/media.lua:111 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:826 |
| setCameraScroll | Lua/camara | distinta | funkin/backend/scripts/psych/media.lua:102 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:825 |
| setCharacterX | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:28 | Generada por bucle en funkin/backend/scripts/psych/media.lua:28. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:783 |
| setCharacterY | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:28 | Generada por bucle en funkin/backend/scripts/psych/media.lua:28. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:803 |
| setDataFromSave | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/ExtraFunctions.hx:130 |
| setGraphicSize | Lua/sprites | distinta | funkin/backend/scripts/psych/media.lua:62 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1040 |
| setHealth | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/gameplay.lua:93 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:696 |
| setHealthBarColors | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:74 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1132 |
| setHits | Lua/puntuacion | distinta | funkin/backend/scripts/psych/gameplay.lua:95 | Generada por bucle en funkin/backend/scripts/psych/gameplay.lua:95. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:692 |
| setLuaSpriteCamera | Lua/sprites | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/DeprecatedFunctions.hx:83 |
| setLuaSpriteScrollFactor | Lua/sprites | distinta | funkin/backend/scripts/compat.lua:368 | Alias expuesto para setScrollFactor. Psych source/psychlua/DeprecatedFunctions.hx:92 |
| setMisses | Lua/puntuacion | distinta | funkin/backend/scripts/psych/gameplay.lua:95 | Generada por bucle en funkin/backend/scripts/psych/gameplay.lua:95. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:688 |
| setObjectCamera | Lua/camara | distinta | funkin/backend/scripts/compat-controls.lua:70 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1151 |
| setObjectOrder | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat.lua:348 | Expuesta; los personajes comparten Stage y no existen tres grupos intercambiables como en Psych. Psych source/psychlua/FunkinLua.hx:468 |
| setProperty | Lua/reflexion | distinta | funkin/backend/scripts/compat.lua:299 | Expuesta con resolucion limitada de rutas, clases y propiedades; no equivale a la reflexion de Psych. Psych source/psychlua/ReflectionFunctions.hx:25 |
| setPropertyFromClass | Lua/reflexion | distinta | funkin/backend/scripts/psych/gameplay.lua:57 | Expuesta con resolucion limitada de rutas, clases y propiedades; no equivale a la reflexion de Psych. Psych source/psychlua/ReflectionFunctions.hx:52 |
| setPropertyFromGroup | Lua/reflexion | distinta | funkin/backend/scripts/psych/notes.lua:119 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ReflectionFunctions.hx:105 |
| setPropertyLuaSprite | Lua/reflexion | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/DeprecatedFunctions.hx:125 |
| setRatingFC | Lua/puntuacion | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:855 |
| setRatingName | Lua/puntuacion | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:851 |
| setRatingPercent | Lua/puntuacion | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:847 |
| setScore | Lua/puntuacion | distinta | funkin/backend/scripts/psych/gameplay.lua:95 | Generada por bucle en funkin/backend/scripts/psych/gameplay.lua:95. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:684 |
| setScrollFactor | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat.lua:367 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1014 |
| setShaderBool | Lua/shaders | distinta | funkin/backend/scripts/psych/shaders.lua:165 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ShaderFunctions.hx:151 |
| setShaderBoolArray | Lua/shaders | distinta | funkin/backend/scripts/psych/shaders.lua:175 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ShaderFunctions.hx:166 |
| setShaderFloat | Lua/shaders | distinta | funkin/backend/scripts/psych/shaders.lua:164 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ShaderFunctions.hx:211 |
| setShaderFloatArray | Lua/shaders | distinta | funkin/backend/scripts/psych/shaders.lua:175 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ShaderFunctions.hx:226 |
| setShaderInt | Lua/shaders | distinta | funkin/backend/scripts/psych/shaders.lua:166 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ShaderFunctions.hx:181 |
| setShaderIntArray | Lua/shaders | distinta | funkin/backend/scripts/psych/shaders.lua:175 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ShaderFunctions.hx:196 |
| setShaderSampler2D | Lua/shaders | distinta | funkin/backend/scripts/psych/shaders.lua:176 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/ShaderFunctions.hx:243 |
| setSoundPitch | Lua/audio | distinta | funkin/backend/scripts/psych/media.lua:150 | Generada por bucle en funkin/backend/scripts/psych/media.lua:150. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1492 |
| setSoundTime | Lua/audio | distinta | funkin/backend/scripts/psych/media.lua:150 | Generada por bucle en funkin/backend/scripts/psych/media.lua:150. Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1466 |
| setSoundVolume | Lua/audio | distinta | funkin/backend/scripts/compat.lua:440 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1440 |
| setTextAlignment | Lua/texto | distinta | funkin/backend/scripts/compat-controls.lua:110 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/TextFunctions.hx:123 |
| setTextAutoSize | Lua/texto | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/TextFunctions.hx:64 |
| setTextBorder | Lua/texto | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/TextFunctions.hx:75 |
| setTextColor | Lua/texto | distinta | funkin/backend/scripts/compat-controls.lua:109 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/TextFunctions.hx:90 |
| setTextFont | Lua/texto | distinta | funkin/backend/scripts/compat-controls.lua:127 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/TextFunctions.hx:101 |
| setTextHeight | Lua/texto | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/TextFunctions.hx:53 |
| setTextItalic | Lua/texto | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/TextFunctions.hx:112 |
| setTextSize | Lua/texto | distinta | funkin/backend/scripts/compat-controls.lua:122 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/TextFunctions.hx:31 |
| setTextString | Lua/texto | distinta | funkin/backend/scripts/compat-controls.lua:108 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/TextFunctions.hx:20 |
| setTextWidth | Lua/texto | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/TextFunctions.hx:42 |
| setTimeBarColors | Lua/ciclo_y_utilidades | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:1141 |
| setVar | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/init.lua:466 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:286 |
| soundFadeCancel | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:146 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1412 |
| soundFadeIn | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:138 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1384 |
| soundFadeOut | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/media.lua:142 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1398 |
| startCountdown | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/gameplay.lua:75 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:732 |
| startDialogue | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/cutscene.lua:69 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1242 |
| startTween | Lua/tweens | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:501 |
| startVideo | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/psych/cutscene.lua:27 | Expuesta; solo OGV. MP4 se omite con aviso. Psych source/psychlua/FunkinLua.hx:1282 |
| stopSound | Lua/audio | distinta | funkin/backend/scripts/compat.lua:435 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1340 |
| stringEndsWith | Lua/ciclo_y_utilidades | implementada | funkin/backend/scripts/psych/utilities.lua:48 | Haxe 4.3.7 executes the Psych 1.0.4 callback body; native Lua tests compare case sensitivity, literal delimiters, empty fields, UTF-8, whitespace and a null-string error. Fixture utilities.json. |
| stringSplit | Lua/ciclo_y_utilidades | implementada | funkin/backend/scripts/psych/utilities.lua:49 | Haxe 4.3.7 executes the Psych 1.0.4 callback body; native Lua tests compare case sensitivity, literal delimiters, empty fields, UTF-8, whitespace and a null-string error. Fixture utilities.json. |
| stringStartsWith | Lua/ciclo_y_utilidades | implementada | funkin/backend/scripts/psych/utilities.lua:47 | Haxe 4.3.7 executes the Psych 1.0.4 callback body; native Lua tests compare case sensitivity, literal delimiters, empty fields, UTF-8, whitespace and a null-string error. Fixture utilities.json. |
| stringTrim | Lua/ciclo_y_utilidades | implementada | funkin/backend/scripts/psych/utilities.lua:63 | Haxe 4.3.7 executes the Psych 1.0.4 callback body; native Lua tests compare case sensitivity, literal delimiters, empty fields, UTF-8, whitespace and a null-string error. Fixture utilities.json. |
| triggerEvent | Lua/ciclo_y_utilidades | distinta | funkin/backend/scripts/compat.lua:521 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:726 |
| updateHitbox | Lua/sprites | distinta | funkin/backend/scripts/compat.lua:369 | Expuesta. La equivalencia semantica completa no se certifica en esta auditoria estatica. Psych source/psychlua/FunkinLua.hx:1082 |
| updateHitboxFromGroup | Lua/reflexion | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/DeprecatedFunctions.hx:152 |
| updateScoreText | Lua/texto | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | Sin registro en los instaladores Lua revisados; referencia indica el instalador candidato, no una implementacion. Psych source/psychlua/FunkinLua.hx:859 |
| Achievements | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| Alphabet | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| Character | HScript/preset | ausente | funkin/states/play.lua:224 | Sin binding de preset equivalente en Light. |
| ClientPrefs | HScript/preset | ausente | funkin/backend/scripts/psych/shaders.lua:86 | Sin binding de preset equivalente en Light. |
| Conductor | HScript/preset | distinta | funkin/backend/scripts/psych/primitives.lua:51 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| Countdown | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:423 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| CustomSubstate | HScript/preset | ausente | funkin/backend/scripts/psych/substate.lua:1 | Sin binding de preset equivalente en Light. |
| ErrorHandledRuntimeShader | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| File | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| FileSystem | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| FlxAnimate | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| FlxCamera | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:6 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| FlxColor | HScript/preset | distinta | funkin/backend/scripts/psych/media.lua:19 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| FlxEase | HScript/preset | distinta | funkin/backend/scripts/psych/motion.lua:95 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| FlxG | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:6 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| FlxMath | HScript/preset | distinta | funkin/backend/scripts/psych/primitives.lua:13 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| FlxRuntimeShader | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| FlxSprite | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:6 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| FlxText | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:6 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| FlxTimer | HScript/preset | distinta | funkin/backend/scripts/psych/motion.lua:59 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| FlxTween | HScript/preset | distinta | funkin/backend/scripts/psych/motion.lua:64 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| Function_Continue | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:425 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| Function_Stop | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:426 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| Function_StopAll | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| Function_StopHScript | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| Function_StopLua | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| Note | HScript/preset | ausente | funkin/states/play.lua:270 | Sin binding de preset equivalente en Light. |
| Paths | HScript/preset | distinta | funkin/backend/scripts/compat-controls.lua:129 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| PlayState | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:424 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| PsychCamera | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| ShaderFilter | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:8 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| StringTools | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:379 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| Type | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| addHaxeLibrary | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:496 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| anyGamepadJustPressed | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| anyGamepadPressed | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| anyGamepadReleased | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| buildTarget | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| controls | HScript/preset | ausente | funkin/backend/scripts/compat.lua:529 | Sin binding de preset equivalente en Light. |
| createCallback | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| createGlobalCallback | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| customSubstate | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| customSubstateName | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| debugPrint | HScript/preset | distinta | funkin/backend/scripts/psych/media.lua:161 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| game | HScript/preset | distinta | funkin/backend/scripts/init.lua:19 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| gamepadAnalogX | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| gamepadAnalogY | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| gamepadJustPressed | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| gamepadPressed | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| gamepadReleased | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| getModSetting | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| getVar | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:473 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| keyJustPressed | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| keyPressed | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| keyReleased | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| keyboardJustPressed | HScript/preset | distinta | funkin/backend/scripts/psych/gameplay.lua:84 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| keyboardPressed | HScript/preset | distinta | funkin/backend/scripts/psych/gameplay.lua:84 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| keyboardReleased | HScript/preset | distinta | funkin/backend/scripts/psych/gameplay.lua:84 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| parentLua | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| removeVar | HScript/preset | ausente | funkin/backend/scripts/psych/init.lua:379 | Sin binding de preset equivalente en Light. |
| setVar | HScript/preset | distinta | funkin/backend/scripts/psych/init.lua:466 | Disponible mediante bindings limitados; no incluye todos los metodos heredados de HaxeFlixel/OpenFL. |
| this | HScript/preset | ausente | funkin/backend/scripts/init.lua:21 | Sin binding de preset equivalente en Light. |
| PlayState.BF_X | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:103 |
| PlayState.BF_Y | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:104 |
| PlayState.DAD_X | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:105 |
| PlayState.DAD_Y | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:106 |
| PlayState.GF_X | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:107 |
| PlayState.GF_Y | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:108 |
| PlayState.SONG | propiedad/PlayState | distinta | funkin/backend/scripts/handler.lua:6 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:142 |
| PlayState._lastLoadedModDirectory | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:267 |
| PlayState.allowDebugKeys | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1671 |
| PlayState.autoUpdateRPC | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1630 |
| PlayState.botplaySine | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:202 |
| PlayState.botplayTxt | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:203 |
| PlayState.boyfriend | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:516 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:156 |
| PlayState.boyfriendCameraOffset | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:234 |
| PlayState.boyfriendGroup | propiedad/PlayState | ausente | funkin/gameplay/stage.lua:78 | Los actores viven dentro de Stage; falta grupo independiente con posicion y orden propios. Psych source/states/PlayState.hx:117 |
| PlayState.boyfriendIdleTime | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:247 |
| PlayState.boyfriendIdled | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:248 |
| PlayState.boyfriendMap | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:95 |
| PlayState.camFollow | propiedad/PlayState | distinta | funkin/backend/scripts/psych/media.lua:111 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:162 |
| PlayState.camGame | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:61 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:208 |
| PlayState.camHUD | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:356 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:207 |
| PlayState.camOther | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:356 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:209 |
| PlayState.camZooming | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:170 |
| PlayState.camZoomingDecay | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:172 |
| PlayState.camZoomingMult | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:171 |
| PlayState.cameraSpeed | propiedad/PlayState | distinta | funkin/gameplay/stage.lua:45 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:210 |
| PlayState.cameraTwn | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:2336 |
| PlayState.campaignMisses | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:220 |
| PlayState.campaignScore | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:219 |
| PlayState.canPause | propiedad/PlayState | distinta | funkin/states/play.lua:605 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1669 |
| PlayState.canReset | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1667 |
| PlayState.canResync | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1588 |
| PlayState.changedDifficulty | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:189 |
| PlayState.chartingMode | propiedad/PlayState | distinta | funkin/states/play.lua:37 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:190 |
| PlayState.combo | propiedad/PlayState | distinta | funkin/backend/scripts/init.lua:211 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:177 |
| PlayState.comboGroup | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:2530 |
| PlayState.countdownGo | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:935 |
| PlayState.countdownReady | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:933 |
| PlayState.countdownSet | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:934 |
| PlayState.cpuControlled | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:198 |
| PlayState.curSong | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:173 |
| PlayState.curStage | propiedad/PlayState | distinta | funkin/backend/modding/psych.lua:98 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:120 |
| PlayState.daPixelZoom | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:227 |
| PlayState.dad | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:64 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:154 |
| PlayState.dadGroup | propiedad/PlayState | ausente | funkin/gameplay/stage.lua:78 | Los actores viven dentro de Stage; falta grupo independiente con posicion y orden propios. Psych source/states/PlayState.hx:118 |
| PlayState.dadMap | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:96 |
| PlayState.deathCounter | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:222 |
| PlayState.defaultCamZoom | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:85 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:224 |
| PlayState.detailsPausedText | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:242 |
| PlayState.detailsText | propiedad/PlayState | distinta | funkin/states/play.lua:2110 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:241 |
| PlayState.dialogueCount | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:896 |
| PlayState.endCallback | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:265 |
| PlayState.endingSong | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:186 |
| PlayState.eventNotes | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:160 |
| PlayState.eventsPushed | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1271 |
| PlayState.finishTimer | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:930 |
| PlayState.freezeCamera | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1670 |
| PlayState.gameOverTimer | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1981 |
| PlayState.generatedMusic | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:185 |
| PlayState.gf | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:517 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:155 |
| PlayState.gfGroup | propiedad/PlayState | ausente | funkin/gameplay/stage.lua:78 | Los actores viven dentro de Stage; falta grupo independiente con posicion y orden propios. Psych source/states/PlayState.hx:119 |
| PlayState.gfMap | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:97 |
| PlayState.gfSpeed | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:175 |
| PlayState.girlfriendCameraOffset | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:236 |
| PlayState.grpNoteSplashes | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:168 |
| PlayState.guitarHeroSustains | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:196 |
| PlayState.health | propiedad/PlayState | distinta | funkin/backend/scripts/psych/notes.lua:45 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:176 |
| PlayState.healthBar | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:63 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:179 |
| PlayState.healthGain | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:193 |
| PlayState.healthLoss | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:194 |
| PlayState.hscriptArray | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:100 |
| PlayState.iconP1 | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:63 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:205 |
| PlayState.iconP2 | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:64 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:206 |
| PlayState.iconsAnimations | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1891 |
| PlayState.inCutscene | propiedad/PlayState | distinta | funkin/states/play.lua:283 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:230 |
| PlayState.inst | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:150 |
| PlayState.instakillOnMiss | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:197 |
| PlayState.instance | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:425 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:251 |
| PlayState.introSoundsSuffix | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:257 |
| PlayState.isCameraOnForcedPos | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:93 |
| PlayState.isDead | propiedad/PlayState | distinta | funkin/backend/scripts/handler.lua:28 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1980 |
| PlayState.isPixelStage | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:124 |
| PlayState.isStoryMode | propiedad/PlayState | distinta | funkin/backend/scripts/psych/gameplay.lua:51 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:143 |
| PlayState.keysArray | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:260 |
| PlayState.keysPressed | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:246 |
| PlayState.lastBeatHit | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:3213 |
| PlayState.lastStepHit | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:3199 |
| PlayState.luaDebugGroup | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:255 |
| PlayState.nextReloadAll | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:268 |
| PlayState.noteGroup | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:2534 |
| PlayState.noteKillOffset | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:113 |
| PlayState.noteTypes | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1270 |
| PlayState.notes | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:356 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:158 |
| PlayState.opponentCameraOffset | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:235 |
| PlayState.opponentStrums | propiedad/PlayState | distinta | funkin/backend/scripts/handler.lua:30 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:166 |
| PlayState.opponentVocals | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:152 |
| PlayState.paused | propiedad/PlayState | distinta | funkin/backend/scripts/psych/substate.lua:24 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1666 |
| PlayState.playbackRate | propiedad/PlayState | distinta | funkin/backend/scripts/init.lua:212 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:115 |
| PlayState.playerStrums | propiedad/PlayState | distinta | funkin/backend/scripts/handler.lua:30 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:167 |
| PlayState.practiceMode | propiedad/PlayState | distinta | funkin/states/play.lua:1510 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:199 |
| PlayState.pressMissDamage | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:200 |
| PlayState.prevCamFollow | propiedad/PlayState | distinta | funkin/states/play.lua:34 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:163 |
| PlayState.psychDialogue | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:897 |
| PlayState.ratingFC | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:3487 |
| PlayState.ratingName | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:3485 |
| PlayState.ratingPercent | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:3486 |
| PlayState.ratingStuff | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:79 |
| PlayState.ratingsData | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:183 |
| PlayState.runtimeShaders | propiedad/PlayState | distinta | funkin/backend/scripts/psych/init.lua:28 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:3577 |
| PlayState.scoreTxt | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:215 |
| PlayState.scoreTxtTween | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:217 |
| PlayState.seenCutscene | propiedad/PlayState | distinta | funkin/states/play.lua:32 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:221 |
| PlayState.showCombo | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:2525 |
| PlayState.showComboNum | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:2526 |
| PlayState.showRating | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:2527 |
| PlayState.singAnimations | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:228 |
| PlayState.skipArrowStartTween | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1526 |
| PlayState.skipCountdown | propiedad/PlayState | distinta | funkin/states/play.lua:282 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:231 |
| PlayState.songHits | propiedad/PlayState | distinta | funkin/backend/scripts/handler.lua:23 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:213 |
| PlayState.songLength | propiedad/PlayState | distinta | funkin/backend/scripts/init.lua:208 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:232 |
| PlayState.songMisses | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:75 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:214 |
| PlayState.songName | propiedad/PlayState | distinta | funkin/backend/scripts/psych/gameplay.lua:52 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:261 |
| PlayState.songPercent | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:181 |
| PlayState.songScore | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:75 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:212 |
| PlayState.songSpeed | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:111 |
| PlayState.songSpeedTween | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:110 |
| PlayState.songSpeedType | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:112 |
| PlayState.spawnTime | propiedad/PlayState | distinta | funkin/gameplay/notefield.lua:338 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:148 |
| PlayState.stageUI | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:121 |
| PlayState.startCallback | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:264 |
| PlayState.startOnTime | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:936 |
| PlayState.startTimer | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:929 |
| PlayState.startedCountdown | propiedad/PlayState | distinta | funkin/backend/scripts/init.lua:211 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1668 |
| PlayState.startingSong | propiedad/PlayState | distinta | funkin/backend/scripts/psych/substate.lua:46 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:187 |
| PlayState.storyDifficulty | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:146 |
| PlayState.storyDifficultyText | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:240 |
| PlayState.storyPlaylist | propiedad/PlayState | distinta | funkin/states/play.lua:26 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:145 |
| PlayState.storyWeek | propiedad/PlayState | distinta | funkin/states/play.lua:28 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:144 |
| PlayState.strumLineNotes | propiedad/PlayState | distinta | funkin/backend/scripts/psych/notes.lua:112 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:165 |
| PlayState.strumsBlocked | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:2690 |
| PlayState.timeBar | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:65 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:180 |
| PlayState.timeTxt | propiedad/PlayState | distinta | funkin/backend/scripts/compat.lua:65 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:216 |
| PlayState.totalColumns | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:1272 |
| PlayState.totalNotesHit | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:2523 |
| PlayState.totalPlayed | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:2522 |
| PlayState.uiGroup | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:2532 |
| PlayState.uiPostfix | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:123 |
| PlayState.uiPrefix | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:122 |
| PlayState.unspawnNotes | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:159 |
| PlayState.updateTime | propiedad/PlayState | ausente | funkin/backend/scripts/compat.lua:77 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:188 |
| PlayState.videoCutscene | propiedad/PlayState | distinta | funkin/backend/scripts/psych/cutscene.lua:20 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:829 |
| PlayState.vocals | propiedad/PlayState | distinta | funkin/states/play.lua:494 | La coincidencia de campo no prueba mismo tipo, valor inicial, escritura ni ciclo de vida. Psych source/states/PlayState.hx:151 |
| SONG.arrowSkin | propiedad/SONG | distinta | funkin/backend/scripts/psych/gameplay.lua:49 | Acceso de clase: solo arrowSkin/disableNoteRGB son escribibles; la vista HScript SONG permite lectura de campos seleccionados. Psych source/backend/Song.hx:31 |
| SONG.bpm | propiedad/SONG | distinta | funkin/backend/scripts/psych/gameplay.lua:49 | Acceso de clase: solo arrowSkin/disableNoteRGB son escribibles; la vista HScript SONG permite lectura de campos seleccionados. Psych source/backend/Song.hx:6 |
| SONG.disableNoteRGB | propiedad/SONG | distinta | funkin/backend/scripts/psych/gameplay.lua:49 | Acceso de clase: solo arrowSkin/disableNoteRGB son escribibles; la vista HScript SONG permite lectura de campos seleccionados. Psych source/backend/Song.hx:22 |
| SONG.events | propiedad/SONG | ausente | funkin/backend/scripts/psych/gameplay.lua:49 | Sin acceso de clase SONG equivalente; el parser puede consumir este dato sin exponer la propiedad. Psych source/backend/Song.hx:5 |
| SONG.format | propiedad/SONG | ausente | funkin/backend/scripts/psych/gameplay.lua:49 | Sin acceso de clase SONG equivalente; el parser puede consumir este dato sin exponer la propiedad. Psych source/backend/Song.hx:15 |
| SONG.gameOverChar | propiedad/SONG | ausente | funkin/backend/scripts/psych/gameplay.lua:49 | Sin acceso de clase SONG equivalente; el parser puede consumir este dato sin exponer la propiedad. Psych source/backend/Song.hx:17 |
| SONG.gameOverEnd | propiedad/SONG | ausente | funkin/backend/scripts/psych/gameplay.lua:49 | Sin acceso de clase SONG equivalente; el parser puede consumir este dato sin exponer la propiedad. Psych source/backend/Song.hx:20 |
| SONG.gameOverLoop | propiedad/SONG | ausente | funkin/backend/scripts/psych/gameplay.lua:49 | Sin acceso de clase SONG equivalente; el parser puede consumir este dato sin exponer la propiedad. Psych source/backend/Song.hx:19 |
| SONG.gameOverSound | propiedad/SONG | ausente | funkin/backend/scripts/psych/gameplay.lua:49 | Sin acceso de clase SONG equivalente; el parser puede consumir este dato sin exponer la propiedad. Psych source/backend/Song.hx:18 |
| SONG.gfVersion | propiedad/SONG | distinta | funkin/backend/scripts/psych/gameplay.lua:49 | Acceso de clase: solo arrowSkin/disableNoteRGB son escribibles; la vista HScript SONG permite lectura de campos seleccionados. Psych source/backend/Song.hx:13 |
| SONG.needsVoices | propiedad/SONG | ausente | funkin/backend/scripts/psych/gameplay.lua:49 | Sin acceso de clase SONG equivalente; el parser puede consumir este dato sin exponer la propiedad. Psych source/backend/Song.hx:7 |
| SONG.notes | propiedad/SONG | ausente | funkin/backend/scripts/psych/gameplay.lua:49 | Sin acceso de clase SONG equivalente; el parser puede consumir este dato sin exponer la propiedad. Psych source/backend/Song.hx:4 |
| SONG.offset | propiedad/SONG | ausente | funkin/backend/scripts/psych/gameplay.lua:49 | Sin acceso de clase SONG equivalente; el parser puede consumir este dato sin exponer la propiedad. Psych source/backend/Song.hx:9 |
| SONG.player1 | propiedad/SONG | distinta | funkin/backend/scripts/psych/gameplay.lua:49 | Acceso de clase: solo arrowSkin/disableNoteRGB son escribibles; la vista HScript SONG permite lectura de campos seleccionados. Psych source/backend/Song.hx:11 |
| SONG.player2 | propiedad/SONG | distinta | funkin/backend/scripts/psych/gameplay.lua:49 | Acceso de clase: solo arrowSkin/disableNoteRGB son escribibles; la vista HScript SONG permite lectura de campos seleccionados. Psych source/backend/Song.hx:12 |
| SONG.song | propiedad/SONG | distinta | funkin/backend/scripts/psych/gameplay.lua:49 | Acceso de clase: solo arrowSkin/disableNoteRGB son escribibles; la vista HScript SONG permite lectura de campos seleccionados. Psych source/backend/Song.hx:3 |
| SONG.speed | propiedad/SONG | distinta | funkin/backend/scripts/psych/gameplay.lua:49 | Acceso de clase: solo arrowSkin/disableNoteRGB son escribibles; la vista HScript SONG permite lectura de campos seleccionados. Psych source/backend/Song.hx:8 |
| SONG.splashSkin | propiedad/SONG | ausente | funkin/backend/scripts/psych/gameplay.lua:49 | Sin acceso de clase SONG equivalente; el parser puede consumir este dato sin exponer la propiedad. Psych source/backend/Song.hx:25 |
| SONG.stage | propiedad/SONG | distinta | funkin/backend/scripts/psych/gameplay.lua:49 | Acceso de clase: solo arrowSkin/disableNoteRGB son escribibles; la vista HScript SONG permite lectura de campos seleccionados. Psych source/backend/Song.hx:14 |
| Note.SUSTAIN_SIZE | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:96 |
| Note._lastNoteOffX | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:354 |
| Note._lastValidChecked | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:355 |
| Note.animSuffix | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:90 |
| Note.blockHit | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:75 |
| Note.canBeHit | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:58 |
| Note.colArray | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:98 |
| Note.copyAlpha | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:122 |
| Note.copyAngle | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:121 |
| Note.copyX | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:119 |
| Note.copyY | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:120 |
| Note.correctionOffset | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:357 |
| Note.defaultNoteSkin | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:99 |
| Note.distance | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:135 |
| Note.earlyHitMult | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:92 |
| Note.eventLength | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:82 |
| Note.eventName | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:81 |
| Note.eventVal1 | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:83 |
| Note.eventVal2 | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:84 |
| Note.extraData | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:52 |
| Note.gfNote | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:91 |
| Note.globalRgbShaders | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:87 |
| Note.hitByOpponent | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:65 |
| Note.hitCausesMiss | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:134 |
| Note.hitHealth | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:124 |
| Note.hitsound | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:149 |
| Note.hitsoundChartEditor | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:138 |
| Note.hitsoundDisabled | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:137 |
| Note.hitsoundForce | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:142 |
| Note.hitsoundVolume | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:143 |
| Note.ignoreNote | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:64 |
| Note.inEditor | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:88 |
| Note.isSustainNote | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:78 |
| Note.lateHitMult | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:93 |
| Note.lowPriority | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:94 |
| Note.missHealth | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:125 |
| Note.missed | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:62 |
| Note.multAlpha | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:116 |
| Note.multSpeed | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:117 |
| Note.mustPress | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:57 |
| Note.nextNote | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:68 |
| Note.noAnimation | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:132 |
| Note.noMissAnimation | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:133 |
| Note.noteData | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:55 |
| Note.noteSplashData | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:101 |
| Note.noteType | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:79 |
| Note.noteWasHit | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:66 |
| Note.offsetAngle | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:115 |
| Note.offsetX | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:113 |
| Note.offsetY | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:114 |
| Note.originalHeight | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:356 |
| Note.parent | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:73 |
| Note.prevNote | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:67 |
| Note.rating | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:126 |
| Note.ratingDisabled | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:128 |
| Note.ratingMod | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:127 |
| Note.rgbShader | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:86 |
| Note.spawned | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:70 |
| Note.strumTime | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:54 |
| Note.sustainLength | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:77 |
| Note.swagWidth | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:97 |
| Note.tail | propiedad/Note | ausente | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:72 |
| Note.texture | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:130 |
| Note.tooLate | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:59 |
| Note.wasGoodHit | propiedad/Note | distinta | funkin/backend/scripts/psych/notes.lua:16 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/Note.hx:61 |
| StrumNote.direction | propiedad/StrumNote | distinta | funkin/backend/scripts/psych/notes.lua:52 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/StrumNote.hx:13 |
| StrumNote.downScroll | propiedad/StrumNote | ausente | funkin/backend/scripts/psych/notes.lua:52 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/StrumNote.hx:14 |
| StrumNote.noteData | propiedad/StrumNote | ausente | funkin/backend/scripts/psych/notes.lua:52 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/StrumNote.hx:12 |
| StrumNote.player | propiedad/StrumNote | ausente | funkin/backend/scripts/psych/notes.lua:52 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/StrumNote.hx:16 |
| StrumNote.resetAnim | propiedad/StrumNote | ausente | funkin/backend/scripts/psych/notes.lua:52 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/StrumNote.hx:11 |
| StrumNote.rgbShader | propiedad/StrumNote | ausente | funkin/backend/scripts/psych/notes.lua:52 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/StrumNote.hx:10 |
| StrumNote.sustainReduce | propiedad/StrumNote | ausente | funkin/backend/scripts/psych/notes.lua:52 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/StrumNote.hx:15 |
| StrumNote.texture | propiedad/StrumNote | ausente | funkin/backend/scripts/psych/notes.lua:52 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/StrumNote.hx:18 |
| StrumNote.useRGBShader | propiedad/StrumNote | ausente | funkin/backend/scripts/psych/notes.lua:52 | Propiedad filtrada por proxy; revisar getters/setters de la referencia. isSustainNote devuelve false: una cinta representa la sostenida completa. Psych source/objects/StrumNote.hx:27 |
| Function_Continue | Lua/global | distinta | funkin/backend/modding/psych.lua:103 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| Function_Stop | Lua/global | distinta | funkin/backend/modding/psych.lua:103 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| Function_StopAll | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| Function_StopHScript | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| Function_StopLua | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| altAnim | Lua/global | distinta | funkin/backend/scripts/handler.lua:20 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| botPlay | Lua/global | distinta | funkin/backend/scripts/handler.lua:27 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| boyfriendName | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| bpm | Lua/global | distinta | funkin/backend/scripts/handler.lua:6 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| buildTarget | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| cameraZoomOnBeat | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| chartPath | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| combo | Lua/global | distinta | funkin/backend/scripts/handler.lua:25 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| crochet | Lua/global | distinta | funkin/backend/scripts/handler.lua:10 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| curBeat | Lua/global | distinta | funkin/backend/scripts/handler.lua:15 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| curBpm | Lua/global | distinta | funkin/backend/scripts/handler.lua:7 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| curDecBeat | Lua/global | distinta | funkin/backend/scripts/handler.lua:9 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| curDecStep | Lua/global | distinta | funkin/backend/scripts/handler.lua:8 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| curSection | Lua/global | distinta | funkin/backend/scripts/handler.lua:18 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| curStage | Lua/global | distinta | funkin/backend/modding/psych.lua:98 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| curStep | Lua/global | distinta | funkin/backend/scripts/handler.lua:14 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| currentModDirectory | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| dadName | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| deaths | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| defaultBoyfriendX | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| defaultBoyfriendY | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| defaultGirlfriendX | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| defaultGirlfriendY | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| defaultOpponentStrumX | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| defaultOpponentStrumY | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| defaultOpponentX | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| defaultOpponentY | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| defaultPlayerStrumX | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| defaultPlayerStrumY | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| difficulty | Lua/global | distinta | funkin/backend/modding/psych.lua:145 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| difficultyName | Lua/global | distinta | funkin/backend/modding/psych.lua:94 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| difficultyNameTranslation | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| difficultyPath | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| downscroll | Lua/global | distinta | funkin/backend/modding/psych.lua:101 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| flashingLights | Lua/global | distinta | funkin/backend/modding/psych.lua:102 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| framerate | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| gfName | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| gfSection | Lua/global | distinta | funkin/backend/scripts/handler.lua:21 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| ghostTapping | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| guitarHeroSustains | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| hasVocals | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| healthBarAlpha | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| healthGainMult | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| healthLossMult | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| hideHud | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| hits | Lua/global | distinta | funkin/backend/scripts/handler.lua:23 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| inGameOver | Lua/global | distinta | funkin/backend/scripts/handler.lua:28 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| instakillOnMiss | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| isStoryMode | Lua/global | distinta | funkin/backend/modding/psych.lua:100 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| loadedSongName | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| loadedSongPath | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| lowQuality | Lua/global | distinta | funkin/backend/modding/psych.lua:102 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| luaDebugMode | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| luaDeprecatedWarnings | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| middlescroll | Lua/global | distinta | funkin/backend/modding/psych.lua:101 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| misses | Lua/global | distinta | funkin/backend/scripts/handler.lua:24 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| modFolder | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| mustHitSection | Lua/global | distinta | funkin/backend/scripts/handler.lua:19 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| noResetButton | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| noteOffset | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| noteSkin | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| noteSkinPostfix | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| playbackRate | Lua/global | distinta | funkin/backend/scripts/handler.lua:26 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| practice | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| rating | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| ratingFC | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| ratingName | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| score | Lua/global | distinta | funkin/backend/scripts/handler.lua:22 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| scoreZoom | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| screenHeight | Lua/global | distinta | funkin/backend/modding/psych.lua:100 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| screenWidth | Lua/global | distinta | funkin/backend/modding/psych.lua:100 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| scriptName | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| scrollSpeed | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| seenCutscene | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| shadersEnabled | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| songLength | Lua/global | distinta | funkin/backend/scripts/handler.lua:13 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| songName | Lua/global | distinta | funkin/backend/modding/psych.lua:94 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| songPath | Lua/global | distinta | funkin/backend/modding/psych.lua:94 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| splashAlpha | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| splashSkin | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| splashSkinPostfix | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| startedCountdown | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| stepCrochet | Lua/global | distinta | funkin/backend/scripts/handler.lua:11 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| timeBarType | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| totalNotesHit | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| totalPlayed | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| version | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| week | Lua/global | distinta | funkin/backend/modding/psych.lua:10 | Inicializacion/sincronizacion localizada; valores y frecuencia deben compararse. |
| weekRaw | Lua/global | ausente | funkin/backend/modding/psych.lua:93 | Sin inicializacion de global equivalente localizada. |
| eventEarlyTrigger | callback | distinta | funkin/backend/scripts/handler.lua:158 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| goodNoteHit | callback | distinta | funkin/backend/scripts/handler.lua:93 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| goodNoteHitPre | callback | distinta | funkin/backend/scripts/handler.lua:178 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| noteMiss | callback | distinta | funkin/backend/scripts/handler.lua:92 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| noteMissPress | callback | distinta | funkin/backend/scripts/handler.lua:88 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onBeatHit | callback | distinta | funkin/backend/scripts/compat.lua:154 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onCountdownStarted | callback | distinta | funkin/backend/scripts/handler.lua:61 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onCountdownTick | callback | distinta | funkin/backend/scripts/handler.lua:65 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onCreate | callback | distinta | funkin/backend/scripts/compat.lua:153 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onCreatePost | callback | distinta | funkin/backend/scripts/compat.lua:153 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onCustomSubstateCreate | callback | distinta | funkin/backend/scripts/psych/substate.lua:29 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onCustomSubstateCreatePost | callback | distinta | funkin/backend/scripts/psych/substate.lua:32 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onCustomSubstateDestroy | callback | distinta | funkin/backend/scripts/psych/substate.lua:42 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onCustomSubstateUpdate | callback | distinta | funkin/backend/scripts/psych/substate.lua:36 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onCustomSubstateUpdatePost | callback | distinta | funkin/backend/scripts/psych/substate.lua:38 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onDestroy | callback | distinta | funkin/backend/scripts/handler.lua:58 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onEndSong | callback | distinta | funkin/backend/scripts/compat.lua:155 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onEvent | callback | distinta | funkin/backend/scripts/handler.lua:53 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onEventPushed | callback | distinta | funkin/backend/scripts/handler.lua:156 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onGameOver | callback | distinta | funkin/backend/scripts/handler.lua:174 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onGameOverConfirm | callback | distinta | funkin/backend/scripts/handler.lua:71 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onGameOverStart | callback | distinta | funkin/backend/scripts/handler.lua:73 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onGhostTap | callback | distinta | funkin/backend/scripts/handler.lua:80 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onKeyPress | callback | distinta | funkin/backend/scripts/handler.lua:78 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onKeyPressPre | callback | distinta | funkin/backend/scripts/handler.lua:76 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onKeyRelease | callback | distinta | funkin/backend/scripts/handler.lua:79 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onKeyReleasePre | callback | distinta | funkin/backend/scripts/handler.lua:77 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onMoveCamera | callback | distinta | funkin/backend/scripts/handler.lua:74 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onNextDialogue | callback | distinta | funkin/backend/scripts/handler.lua:54 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onPause | callback | distinta | funkin/backend/scripts/handler.lua:59 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onRecalculateRating | callback | distinta | funkin/backend/scripts/handler.lua:81 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onResume | callback | distinta | funkin/backend/scripts/handler.lua:69 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onSectionHit | callback | distinta | funkin/backend/scripts/handler.lua:52 | Hay dos rutas: section y measure en handler.lua; riesgo de despacho duplicado o por compas. |
| onSkipDialogue | callback | distinta | funkin/backend/scripts/handler.lua:54 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onSongStart | callback | distinta | funkin/backend/scripts/compat.lua:155 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onSoundFinished | callback | distinta | funkin/backend/scripts/compat.lua:276 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onSpawnNote | callback | distinta | funkin/backend/scripts/handler.lua:92 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onStartCountdown | callback | distinta | funkin/backend/scripts/handler.lua:60 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onStepHit | callback | distinta | funkin/backend/scripts/compat.lua:154 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onTimerCompleted | callback | distinta | funkin/backend/scripts/compat.lua:429 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onTweenCompleted | callback | distinta | funkin/backend/scripts/compat.lua:245 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onUpdate | callback | distinta | funkin/backend/scripts/compat.lua:185 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onUpdatePost | callback | distinta | funkin/backend/scripts/compat.lua:153 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| onUpdateScore | callback | distinta | funkin/backend/scripts/handler.lua:81 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| opponentNoteHit | callback | distinta | funkin/backend/scripts/handler.lua:93 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| opponentNoteHitPre | callback | distinta | funkin/backend/scripts/handler.lua:178 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| preUpdateScore | callback | distinta | funkin/backend/scripts/handler.lua:81 | Hay despacho o mapeo. No certifica firma, retornos, orden ni cantidad de llamadas; incluye los eventos sostenidos representados como cinta. |
| gfGroup.members | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| gfGroup.length | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| gfGroup.x | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| gfGroup.y | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| gfGroup.alpha | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| gfGroup.visible | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| dadGroup.members | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| dadGroup.length | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| dadGroup.x | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| dadGroup.y | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| dadGroup.alpha | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| dadGroup.visible | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| boyfriendGroup.members | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| boyfriendGroup.length | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| boyfriendGroup.x | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| boyfriendGroup.y | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| boyfriendGroup.alpha | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| boyfriendGroup.visible | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| strumLineNotes.members | grupo | distinta | funkin/backend/scripts/psych/notes.lua:112 | Proxy concatena campos enemigo/jugador con indices cero; no es FlxTypedGroup. |
| strumLineNotes.length | grupo | distinta | funkin/backend/scripts/psych/notes.lua:112 | Proxy concatena campos enemigo/jugador con indices cero; no es FlxTypedGroup. |
| strumLineNotes.x | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| strumLineNotes.y | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| strumLineNotes.alpha | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| strumLineNotes.visible | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| playerStrums.members | grupo | distinta | funkin/backend/scripts/psych/notes.lua:112 | Proxy concatena campos enemigo/jugador con indices cero; no es FlxTypedGroup. |
| playerStrums.length | grupo | distinta | funkin/backend/scripts/psych/notes.lua:112 | Proxy concatena campos enemigo/jugador con indices cero; no es FlxTypedGroup. |
| playerStrums.x | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| playerStrums.y | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| playerStrums.alpha | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| playerStrums.visible | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| opponentStrums.members | grupo | distinta | funkin/backend/scripts/psych/notes.lua:112 | Proxy concatena campos enemigo/jugador con indices cero; no es FlxTypedGroup. |
| opponentStrums.length | grupo | distinta | funkin/backend/scripts/psych/notes.lua:112 | Proxy concatena campos enemigo/jugador con indices cero; no es FlxTypedGroup. |
| opponentStrums.x | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| opponentStrums.y | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| opponentStrums.alpha | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| opponentStrums.visible | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| notes.members | grupo | distinta | funkin/backend/scripts/psych/notes.lua:112 | Proxy concatena campos enemigo/jugador con indices cero; no es FlxTypedGroup. |
| notes.length | grupo | distinta | funkin/backend/scripts/psych/notes.lua:112 | Proxy concatena campos enemigo/jugador con indices cero; no es FlxTypedGroup. |
| notes.x | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| notes.y | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| notes.alpha | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| notes.visible | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| unspawnNotes.members | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| unspawnNotes.length | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| unspawnNotes.x | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| unspawnNotes.y | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| unspawnNotes.alpha | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| unspawnNotes.visible | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| grpNoteSplashes.members | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| grpNoteSplashes.length | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| grpNoteSplashes.x | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| grpNoteSplashes.y | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| grpNoteSplashes.alpha | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| grpNoteSplashes.visible | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| grpNoteSplashesOpponent.members | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| grpNoteSplashesOpponent.length | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| grpNoteSplashesOpponent.x | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| grpNoteSplashesOpponent.y | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| grpNoteSplashesOpponent.alpha | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |
| grpNoteSplashesOpponent.visible | grupo | ausente | funkin/gameplay/stage.lua:78 | Sin grupo/campo equivalente expuesto por el modelo de grupos Psych de Light. |

## Generated Lua APIs

These are the generation loops in the audited Light revision. Their output names are included individually above.

### funkin/backend/scripts/compat.lua:408

`doTweenX`, `doTweenY`, `doTweenAlpha`, `doTweenAngle`, `doTweenZoom`

```lua
	for _, property in ipairs({"x", "y", "alpha", "angle", "zoom"}) do
		local key = property
		api["doTween" .. key:sub(1, 1):upper() .. key:sub(2)] = function(tag, object, value, duration, ease)
			return self:_tween(tag, object .. "." .. key, value, duration, ease)
		end
	end
	api.cancelTween = function(tag) self:_active(); self:_cancelTween(tag) end
```

### funkin/backend/scripts/compat.lua:436

`pauseSound`, `resumeSound`

```lua
	for name, method in pairs({pauseSound = "pause", resumeSound = "play"}) do
		local action = method
		api[name] = function(tag) self:_active(); if self.sounds[tag] then self.sounds[tag][action](self.sounds[tag]) end end
	end
```

### funkin/backend/scripts/compat-controls.lua:175

`precacheImage`, `precacheSound`, `precacheMusic`

```lua
	for kind, loader in pairs(loaders) do
		local method = loader
		api["precache" .. kind:sub(1, 1):upper() .. kind:sub(2)] = function(key)
			ctx:_active(); assetKey(key)
			local resource = paths[method](key)
			if not resource then fail("missing asset: " .. key) end
			return resource
```

### funkin/backend/scripts/psych/gameplay.lua:84

`keyboardPressed`, `keyboardJustPressed`, `keyboardReleased`

```lua
	for method, source in pairs({keyboardPressed = "pressed", keyboardJustPressed = "justPressed",
		keyboardReleased = "justReleased"}) do
		api[method] = function(key)
			local keys = game.keys[source]
			return keys and keys[tostring(key):upper()] == true or false
		end
```

### funkin/backend/scripts/psych/gameplay.lua:95

`getScore`, `getMisses`, `getHits`, `setScore`, `setMisses`, `setHits`, `addScore`, `addMisses`, `addHits`

```lua
	for label, field in pairs({Score = "score", Misses = "misses", Hits = "songHits"}) do
		local function get() return state[field] or 0 end
		local function set(value)
			state[field] = math.modf(tonumber(value) or 0)
			if state.recalculateRating then state:recalculateRating() end
		end
		api["get" .. label] = get
		api["set" .. label] = set
		api["add" .. label] = function(value) set(get() + (tonumber(value) or 0)) end
	end
```

### funkin/backend/scripts/psych/notes.lua:132

`noteTweenX`, `noteTweenY`, `noteTweenAlpha`, `noteTweenAngle`, `noteTweenDirection`

```lua
	for _, property in ipairs({"x", "y", "alpha", "angle", "direction"}) do
		local name = "noteTween" .. property:sub(1, 1):upper() .. property:sub(2)
		api[name] = function(tag, index, value, duration, ease)
			local object = assert(member("strumLineNotes", index), "Psych receptor index out of range")
			compat:_tweenObject(tag, object, property, value, duration, ease)
		end
	end
```

### funkin/backend/scripts/psych/media.lua:28

`getCharacterX`, `getCharacterY`, `setCharacterX`, `setCharacterY`

```lua
	for _, axis in ipairs({"x", "y"}) do
		local upper = axis:upper()
		api["getCharacter" .. upper] = function(name)
			local actor = character(name)
			return actor and actor[axis] or 0
		end
		api["setCharacter" .. upper] = function(name, value)
			local actor = character(name)
			if actor then actor[axis] = value end
		end
	end
	api.characterDance = function(name)
```

### funkin/backend/scripts/psych/media.lua:79

`getMidpointX`, `getMidpointY`, `getGraphicMidpointX`, `getGraphicMidpointY`

```lua
	for suffix, method in pairs({Midpoint = "getMidpoint", GraphicMidpoint = "getGraphicMidpoint"}) do
		for position, axis in ipairs({"X", "Y"}) do
			api["get" .. suffix .. axis] = function(tag)
				local object = compat:_object(tag)
				local x, y = object[method](object)
				return position == 1 and x or y
			end
		end
```

### funkin/backend/scripts/psych/media.lua:126

`mouseClicked`, `mousePressed`, `mouseReleased`

```lua
	for name, field in pairs({mouseClicked = "justPressed", mousePressed = "pressed", mouseReleased = "justReleased"}) do
		api[name] = function(button)
			local suffix = ({left = "Left", right = "Right", middle = "Middle"})[button or "left"]
			return suffix and game.mouse[field .. suffix] or false
		end
	end

```

### funkin/backend/scripts/psych/media.lua:150

`getSoundTime`, `getSoundPitch`, `setSoundTime`, `setSoundPitch`

```lua
	for _, property in ipairs({"time", "pitch"}) do
		local name = property:sub(1, 1):upper() .. property:sub(2)
		api["getSound" .. name] = function(tag)
			local object = sound(tag)
			if object then return object[property] * (property == "time" and 1000 or 1) end
		end
		api["setSound" .. name] = function(tag, value)
			local object = sound(tag)
			if object then object[property] = value / (property == "time" and 1000 or 1) end
		end
	end
	api.debugPrint = function(...) print(...) end
end
```

## Stage ordering proposal — not applied

| Psych | Light |
|---|---|
| `source/states/PlayState.hx:375` creates `boyfriendGroup`, `dadGroup`, `gfGroup` as separate FlxSpriteGroups. | `funkin/gameplay/stage.lua:84` constructs actors and adds them to Stage. |
| With no stageData.objects: `add(gfGroup); add(dadGroup); add(boyfriendGroup);` at 427–429. | Psych branch assigns GF 100 / Dad 200 / BF 300; Stage:refresh sorts that internal list. |
| With stageData.objects, StageData.addObjectsToState determines interleaving. | PlayState inserts Stage and then Stage.foreground as two top-level units. |

Psych excerpt (PlayState.hx:375):
```haxe
boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
```

Light excerpt (stage.lua):
```lua
self[name] = Character(pos.x, pos.y, char, player)
local character = self[name]
self:add(character)
```

Proposed changes:
1. In stage.lua, create three independently addressable character containers for detected Psych stages. Give each container its authored group position and keep character-local offsets separate. Preserve an ownership list for cleanup.
2. In PlayState, insert the character containers as top-level members in GF, Dad, BF order. Apply stageData.objects interleaving and stage script creation order from Psych. Do not render the same actor both through Stage and through its container.
3. In compatibility object resolution and object-order APIs, resolve those actual containers. addLuaSprite(false) inserts before the earliest character container; true appends. setObjectOrder works on the same state-member sequence.
4. Character swaps replace only the child of the matching container. Update camera midpoint calculations, deferred character preparation, disposal and script lifecycle to preserve local versus world coordinates.
5. Validate a stage with layers behind GF, between GF/Dad, between Dad/BF and in front of BF; test hidden GF, swaps, camera motion, resize, and destruction. Compare rendered frames with Psych.

## Reported errors

- `Glitch.lua:17/33`: addMisses belongs to Score/Misses/Hits setters, adders, counters, rating recalculation and score callbacks. The current revision generates this family in gameplay.lua; the older Android log does not identify its engine commit.
- `Glitch.lua:5`: notes[].texture belongs to note atlas loading, animation state, head/body/tail skin selection and RGB. The current revision has a proxy setter; pixel formats, per-segment scripts and complete shader parity remain outside the demonstrated support.
- `rgbNotes.lua:11`: PlayState.SONG.arrowSkin belongs to chart settings, note/receptor skin initialization, per-note overrides and RGB. The current setter is a selected class-property route, not general class reflection.
- `blubalscript(5resist).lua:344`: file unavailable in the attached ZIPs. The variable and reason for nil are undetermined. Please attach that exact script; no variable is inferred from the traceback.

## Verification limits

The original inventory was static. Batch 1 implementation and checks are recorded below. Previously reported tests are not proof of all entries here. Physical Android touches and Mali-G57 rendering were not tested. No claim of complete Psych compatibility is made.

## Exposure review notes

- The 223 Lua rows include 143 exposed names and 80 names without an equivalent registration in the inspected Light installers. Exposure does not certify parameter, return, ownership, or lifecycle parity.
- API availability is conditional on Psych mod detection, the compatibility option, and successful script initialization.
- `implementada` is deliberately not assigned solely from static registration. Entries marked `distinta` with unverified parity require behavioral review before claiming a semantic difference or equivalence.
- Class and group property rows report their specific access route. A field consumed by a chart parser does not automatically become accessible through getPropertyFromClass.
- No Blueballed source was available. Attach `blubalscript(5resist).lua`, including line 344, to resolve that error.

## Batch 1 — input and Lua utilities

Light base `567588a1620a0651eae8822fbddcd17f1d624aa7`; changed rows refer to batch 1 source. Untouched rows retain the original baseline references.

Scope: ExtraFunctions input, string, random and file utilities; getRunningScripts and absent spatial queries. Save slots belong to batch 4; reflection, tweens, class/PlayState lifecycle and group operations are deferred to their ordered batches.

Contract fixtures execute the original Psych 1.0.4 callback bodies with Haxe 4.3.7. Providers substitute keyboard/controller state and Paths, so this is not a Psych application run. There are 138 reference vectors plus native controller/query tests.

| funcion | before | after |
|---|---|---|
| anyGamepadJustPressed | ausente | distinta |
| anyGamepadPressed | ausente | distinta |
| anyGamepadReleased | ausente | distinta |
| checkFileExists | ausente | distinta |
| deleteFile | ausente | distinta |
| directoryFileList | ausente | distinta |
| gamepadAnalogX | ausente | distinta |
| gamepadAnalogY | ausente | distinta |
| gamepadJustPressed | ausente | distinta |
| gamepadPressed | ausente | distinta |
| gamepadReleased | ausente | distinta |
| getPixelColor | ausente | distinta |
| getRandomBool | ausente | distinta |
| getRandomFloat | ausente | distinta |
| getRandomInt | ausente | distinta |
| getRunningScripts | ausente | implementada |
| getScreenPositionX | ausente | distinta |
| getScreenPositionY | ausente | distinta |
| getTextFromFile | ausente | distinta |
| keyJustPressed | ausente | implementada |
| keyPressed | ausente | implementada |
| keyReleased | ausente | implementada |
| keyboardJustPressed | distinta | implementada |
| keyboardPressed | distinta | implementada |
| keyboardReleased | distinta | implementada |
| objectsOverlap | ausente | distinta |
| saveFile | ausente | distinta |
| stringEndsWith | ausente | implementada |
| stringSplit | ausente | implementada |
| stringStartsWith | ausente | implementada |
| stringTrim | ausente | implementada |

### Attached Blueballed script

At line 319, `messUps = getProperty('songMisses')`; line 344 compares `messUps > 5`. That is the nil operand in the supplied source. Psych exposes PlayState.songMisses initialized to zero. This is a PlayState-property/reflection case, recorded for batch 6 and not changed by batch 1.

The attached script calls `keyJustPressed("space")`. Psych routes unrecognized control names to Controls.justPressed. The contract fixture checks that a missing space control returns false; it does not silently reinterpret space as accept.

Unverified: physical Android touch, USB/Bluetooth gamepad mapping, Mali-G57 readback, Android external-storage permissions, and whole-mod execution on the new batch. Only this batch is authorized; later batches have not been started.

Current batch exposure: 171 of the 223 Lua registration names are exposed; 52 remain absent. Only the 31 changed rows were reviewed for this batch. There are 11 implemented rows in that set, and 20 remain distinct.

## Core menu asset batch — 2026-11-22

| Surface | Light location | Verified behavior | Difference from Psych 1.0.4 |
|---|---|---|---|
| Title intro text | funkin/backend/menuassets.lua:3; funkin/states/title.lua:92 | Base entries then current mod entries, trimmed and deduplicated; literal `--` delimiter; empty mod retains base entries | Only current mod and base, not all global mod directories. Both sources empty returns two empty strings instead of failing selection. |
| Week menu character | funkin/backend/menuassets.lua:31; funkin/ui/storymenu/character.lua:23 | Mod first then base path; Psych `image` uses `menucharacters/`; native `sprite` retains native directory | Missing/invalid fields recover from base BF. Psych MenuCharacter does not validate incomplete JSON and can fail after parsing; this recovery is explicitly requested Light behavior. |

Source comparison: Psych tag `1.0.4`, commit `5c67ced49e5a98535298a6daa3f8f4ec79ac8399`: `TitleState.getIntroTextShit`, `Mods.mergeAllTextsNamed`, `CoolUtil.listFromString`, `MenuCharacter.changeCharacter`.
The uploaded three ZIPs contain neither introText.txt nor menu-character JSON. The exact offending input is not available; empty intro text and missing sprite/image are reproduced fixtures, not an attribution to a specific mod file.
Validation: native LÖVE 11.5 `menu-asset-fallbacks` (2 checks), `menu-regressions`, `syntax` pass. Full compiled Psych differential execution and Android touch/render verification have not been performed.
