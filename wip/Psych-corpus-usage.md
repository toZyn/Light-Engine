# Psych mod corpus — static usage inventory

Analysis A. No engine code changes. Corpus is restricted to the attached bytes listed below. Counts include each uploaded script once; possible duplicate filenames across archives remain separate entries. Cross-reference: Psych-1.0.4-Light-API-audit.md version 1, including the local batch-1 commit b3b68ac. The input/utilities batch was published as 44241ec; the current backup includes subsequent core/global commits. The corpus orders regression testing and does not limit the API scope.

All active Lua calls and API route arguments were scanned after excluding comments and string contents. Call counts are syntactic occurrences, not runtime frequency. Callback declarations are separated from helper definitions. Dynamic expressions and loop indexes remain explicit; no claim of 100% runtime coverage is made.

Cross-reference uses the batch-1 Markdown inventory, whose exposure/behavior distinctions remain in force. `sin fila` is an audit gap, not a conclusion that the engine lacks the value. Rows marked implementada in that inventory retain its test limits.

Files: 18; Lua: 18; HScript files: 0; embedded Haxe calls: 0.

## Corpus manifest

| archive | script | lines | SHA-256 |
|---|---|---|---|
| (BenSKR) Deathmatch Proyect mods folder port Optimizado (1).zip | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua | 20 | 8ae46d49459004cf17667f48cda9e6f60c0f2926c4a065fd2a7fef63073d0f7c |
| (BenSKR) Deathmatch Proyect mods folder port Optimizado (1).zip | (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/deathmatch/script.lua | 6 | e784b9b33db5867e870247e59637f7d2c751c4596c4fc1d1436fd938b342d627 |
| (BenSKR) Deathmatch Proyect mods folder port Optimizado (1).zip | (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/the-deathmatch/script.lua | 6 | e784b9b33db5867e870247e59637f7d2c751c4596c4fc1d1436fd938b342d627 |
| (BenSKR) Deathmatch Proyect mods folder port Optimizado (1).zip | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua | 107 | 82302c51208258cd0d29e6554d3c56b9865a18b99f21ece768ba40725cbed729 |
| (BenSKR) Deathmatch Proyect mods folder port Optimizado (1).zip | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua | 71 | 5124f756676f7f3e2f5dfc11dd35459e1aae46a439fa3aec1d2c5552c1b4936b |
| Phonophobia Android Port.zip | Phonophobia Android Port/data/Phonophobia/script.lua | 271 | 19c901f398f36ddc109d4d1e7b08bd6f1afda4ccd353ed5a665b10a1c6d178c2 |
| Phonophobia Android Port.zip | Phonophobia Android Port/scripts/Heath_Display.lua | 12 | 900626462ff7935decebf0d5e395b9a8c792692ad8596487e407c44190e7c41a |
| Phonophobia Android Port.zip | Phonophobia Android Port/scripts/floating.lua | 8 | 8b046d685822de052638271b9762aeeed6a64110dbc0292ee5458a14aac116ac |
| Phonophobia Android Port.zip | Phonophobia Android Port/scripts/health_drain.lua | 6 | 5c1a553d3946104823dcbf181b3986f3f2f4a9e4567929a1fb937143cc6dfd27 |
| Phonophobia Android Port.zip | Phonophobia Android Port/scripts/shake.lua | 3 | ce73117b55f5074c1b5d5c1936db9128f7505f0a79bcec3c9e441212057183a0 |
| Phonophobia Android Port.zip | Phonophobia Android Port/stages/White.lua | 11 | 2158fe91d6dc56639d6dce55162bd2e1f376d28f0ef7fa585dc91cb0d8e28df1 |
| VS Abrahaham Funky Fonks Port Psych Engine 1.0.4 Optimizado (Juni07).zip | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Camera Flash.lua | 7 | 3d93c3b24e9da876ca68b810d730371cf41be7af86a625acc0df3f107d87eab8 |
| VS Abrahaham Funky Fonks Port Psych Engine 1.0.4 Optimizado (Juni07).zip | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Goodbye Hud.lua | 6 | 5f8e5c0b5fbdd3abd6de7aa61fa27fbd9c621522e0cd25576f25fdbf1964b3cc |
| VS Abrahaham Funky Fonks Port Psych Engine 1.0.4 Optimizado (Juni07).zip | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua | 20 | b1b0e390e64ff93009c37fd1a7ba527c4f840f4408d55cb85040c4224f097e02 |
| VS Abrahaham Funky Fonks Port Psych Engine 1.0.4 Optimizado (Juni07).zip | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Stage Changer.lua | 8 | b763f0cd6b3445cde5e59fd94c6386255c57d7ad92057bcca829857891e6966f |
| VS Abrahaham Funky Fonks Port Psych Engine 1.0.4 Optimizado (Juni07).zip | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua | 7 | 7f87b648846ecfda6dac891fc5353f9eafdcde48ec0d635b1ea84fff5bd935c1 |
| VS Abrahaham Funky Fonks Port Psych Engine 1.0.4 Optimizado (Juni07).zip | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/reaction.lua | 8 | 5562947f45bc51589c1c736d2a6aac79545be1fa871b6b02b74a8cf207e7850a |
| attached script | blubalscript(5resist).lua | 748 | 01aa31a363c117d869d2bac2828ba698558ebcfbd43555736051fd8169e162de |

Blueballed is represented only by the attached blubalscript(5resist).lua. Its Glitch.lua and rgbNotes.lua and the complete mod are not attached. Their log examples are not included as scanned source.

## Calls — every function name

| function | occurrences | classification | inventory status | Light reference | source sites |
|---|---|---|---|---|---|
| setProperty | 96 | engine/external | distinta | funkin/backend/scripts/compat.lua:299 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:10; (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:11; (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:12; (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:13; (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/deathmatch/script.lua:4; (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/the-deathmatch/script.lua:4; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:21; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:25; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:29; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:34; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:39; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:44; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:50; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:56; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:70; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:71; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:72; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:79; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:80; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:81; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:82; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:83; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:84; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:85; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:86; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:87; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:88; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:92; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:93; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:94; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:95; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:99; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:100; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:104; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:105; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:23; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:29; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:35; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:49; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:50; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:51; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:58; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:59; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:63; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:64; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:68; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:69; Phonophobia Android Port/data/Phonophobia/script.lua:36; Phonophobia Android Port/data/Phonophobia/script.lua:38; Phonophobia Android Port/data/Phonophobia/script.lua:244; Phonophobia Android Port/data/Phonophobia/script.lua:253; Phonophobia Android Port/data/Phonophobia/script.lua:264; Phonophobia Android Port/data/Phonophobia/script.lua:267; Phonophobia Android Port/scripts/health_drain.lua:4; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/reaction.lua:2; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/reaction.lua:7; blubalscript(5resist).lua:8; blubalscript(5resist).lua:46; blubalscript(5resist).lua:47; blubalscript(5resist).lua:49; blubalscript(5resist).lua:50; blubalscript(5resist).lua:51; blubalscript(5resist).lua:88; blubalscript(5resist).lua:159; blubalscript(5resist).lua:169; blubalscript(5resist).lua:176; blubalscript(5resist).lua:179; blubalscript(5resist).lua:186; blubalscript(5resist).lua:187; blubalscript(5resist).lua:201; blubalscript(5resist).lua:204; blubalscript(5resist).lua:258; blubalscript(5resist).lua:259; blubalscript(5resist).lua:311; blubalscript(5resist).lua:312; blubalscript(5resist).lua:314; blubalscript(5resist).lua:315; blubalscript(5resist).lua:392; blubalscript(5resist).lua:396; blubalscript(5resist).lua:400; blubalscript(5resist).lua:403; blubalscript(5resist).lua:428; blubalscript(5resist).lua:463; blubalscript(5resist).lua:572; blubalscript(5resist).lua:576; blubalscript(5resist).lua:577; blubalscript(5resist).lua:580; blubalscript(5resist).lua:586; blubalscript(5resist).lua:587; blubalscript(5resist).lua:705; blubalscript(5resist).lua:706; blubalscript(5resist).lua:710; blubalscript(5resist).lua:711; blubalscript(5resist).lua:720; blubalscript(5resist).lua:727; blubalscript(5resist).lua:729 |
| getProperty | 34 | engine/external | distinta | funkin/backend/scripts/psych/notes.lua:125 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/deathmatch/script.lua:2; (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/deathmatch/script.lua:3; (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/the-deathmatch/script.lua:2; (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/the-deathmatch/script.lua:3; Phonophobia Android Port/data/Phonophobia/script.lua:264; Phonophobia Android Port/data/Phonophobia/script.lua:267; Phonophobia Android Port/scripts/Heath_Display.lua:4; Phonophobia Android Port/scripts/Heath_Display.lua:10; Phonophobia Android Port/scripts/health_drain.lua:2; blubalscript(5resist).lua:10; blubalscript(5resist).lua:20; blubalscript(5resist).lua:176; blubalscript(5resist).lua:179; blubalscript(5resist).lua:199; blubalscript(5resist).lua:200; blubalscript(5resist).lua:203; blubalscript(5resist).lua:311; blubalscript(5resist).lua:312; blubalscript(5resist).lua:314; blubalscript(5resist).lua:315; blubalscript(5resist).lua:319; blubalscript(5resist).lua:381; blubalscript(5resist).lua:382; blubalscript(5resist).lua:407; blubalscript(5resist).lua:413; blubalscript(5resist).lua:413; blubalscript(5resist).lua:419; blubalscript(5resist).lua:627; blubalscript(5resist).lua:658; blubalscript(5resist).lua:664; blubalscript(5resist).lua:674; blubalscript(5resist).lua:679; blubalscript(5resist).lua:685; blubalscript(5resist).lua:690 |
| noteTweenX | 29 | engine/external | distinta | funkin/backend/scripts/psych/notes.lua:132 | Phonophobia Android Port/data/Phonophobia/script.lua:91; Phonophobia Android Port/data/Phonophobia/script.lua:92; Phonophobia Android Port/data/Phonophobia/script.lua:93; Phonophobia Android Port/data/Phonophobia/script.lua:94; Phonophobia Android Port/data/Phonophobia/script.lua:100; Phonophobia Android Port/data/Phonophobia/script.lua:101; Phonophobia Android Port/data/Phonophobia/script.lua:102; Phonophobia Android Port/data/Phonophobia/script.lua:103; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:5; blubalscript(5resist).lua:282; blubalscript(5resist).lua:283; blubalscript(5resist).lua:284; blubalscript(5resist).lua:285; blubalscript(5resist).lua:286; blubalscript(5resist).lua:287; blubalscript(5resist).lua:288; blubalscript(5resist).lua:289; blubalscript(5resist).lua:497; blubalscript(5resist).lua:500; blubalscript(5resist).lua:503; blubalscript(5resist).lua:506; blubalscript(5resist).lua:513; blubalscript(5resist).lua:517; blubalscript(5resist).lua:521; blubalscript(5resist).lua:525; blubalscript(5resist).lua:529; blubalscript(5resist).lua:533; blubalscript(5resist).lua:537; blubalscript(5resist).lua:541 |
| addLuaSprite | 24 | engine/external | distinta | funkin/backend/scripts/compat.lua:331 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:8; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:14; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:15; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:16; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:58; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:59; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:60; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:61; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:62; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:63; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:64; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:65; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:37; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:38; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:39; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:40; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:41; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:42; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:43; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:44; Phonophobia Android Port/stages/White.lua:4; Phonophobia Android Port/stages/White.lua:8; blubalscript(5resist).lua:213; blubalscript(5resist).lua:570 |
| scaleObject | 21 | engine/external | distinta | funkin/backend/scripts/compat.lua:363 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:6; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:9; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:12; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:20; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:24; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:28; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:33; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:38; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:43; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:49; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:55; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:4; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:7; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:10; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:14; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:18; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:22; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:28; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:34; Phonophobia Android Port/stages/White.lua:3; Phonophobia Android Port/stages/White.lua:7 |
| swapTurn | 19 | helper | sin fila | — | blubalscript(5resist).lua:549; blubalscript(5resist).lua:552; blubalscript(5resist).lua:555; blubalscript(5resist).lua:558; blubalscript(5resist).lua:561; blubalscript(5resist).lua:564; blubalscript(5resist).lua:588; blubalscript(5resist).lua:591; blubalscript(5resist).lua:594; blubalscript(5resist).lua:597; blubalscript(5resist).lua:600; blubalscript(5resist).lua:603; blubalscript(5resist).lua:606; blubalscript(5resist).lua:609; blubalscript(5resist).lua:612; blubalscript(5resist).lua:615; blubalscript(5resist).lua:618; blubalscript(5resist).lua:621; blubalscript(5resist).lua:624 |
| tonumber | 18 | Lua builtin | sin fila | — | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Goodbye Hud.lua:3; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Goodbye Hud.lua:3; blubalscript(5resist).lua:46; blubalscript(5resist).lua:47; blubalscript(5resist).lua:49; blubalscript(5resist).lua:51; blubalscript(5resist).lua:88; blubalscript(5resist).lua:159; blubalscript(5resist).lua:169; blubalscript(5resist).lua:572; blubalscript(5resist).lua:576; blubalscript(5resist).lua:577; blubalscript(5resist).lua:587; blubalscript(5resist).lua:705; blubalscript(5resist).lua:706; blubalscript(5resist).lua:710; blubalscript(5resist).lua:711; blubalscript(5resist).lua:720 |
| doTweenAlpha | 16 | engine/external | distinta | funkin/backend/scripts/compat.lua:408 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:15; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Goodbye Hud.lua:3; blubalscript(5resist).lua:236; blubalscript(5resist).lua:239; blubalscript(5resist).lua:243; blubalscript(5resist).lua:246; blubalscript(5resist).lua:409; blubalscript(5resist).lua:415; blubalscript(5resist).lua:421; blubalscript(5resist).lua:464; blubalscript(5resist).lua:721; blubalscript(5resist).lua:724; blubalscript(5resist).lua:725; blubalscript(5resist).lua:731; blubalscript(5resist).lua:732; blubalscript(5resist).lua:734 |
| noteTweenAlpha | 16 | engine/external | distinta | funkin/backend/scripts/psych/notes.lua:132 | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:3; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:4; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:5; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:6; blubalscript(5resist).lua:499; blubalscript(5resist).lua:502; blubalscript(5resist).lua:505; blubalscript(5resist).lua:508; blubalscript(5resist).lua:515; blubalscript(5resist).lua:519; blubalscript(5resist).lua:523; blubalscript(5resist).lua:527; blubalscript(5resist).lua:531; blubalscript(5resist).lua:535; blubalscript(5resist).lua:539; blubalscript(5resist).lua:543 |
| triggerEvent | 16 | engine/external | distinta | funkin/backend/scripts/compat.lua:521 | Phonophobia Android Port/data/Phonophobia/script.lua:44; Phonophobia Android Port/data/Phonophobia/script.lua:217; Phonophobia Android Port/scripts/shake.lua:2; blubalscript(5resist).lua:44; blubalscript(5resist).lua:45; blubalscript(5resist).lua:449; blubalscript(5resist).lua:452; blubalscript(5resist).lua:455; blubalscript(5resist).lua:571; blubalscript(5resist).lua:574; blubalscript(5resist).lua:703; blubalscript(5resist).lua:704; blubalscript(5resist).lua:708; blubalscript(5resist).lua:709; blubalscript(5resist).lua:718; blubalscript(5resist).lua:719 |
| getPropertyFromClass | 15 | engine/external | distinta | funkin/backend/scripts/psych/gameplay.lua:24 | Phonophobia Android Port/data/Phonophobia/script.lua:24; Phonophobia Android Port/data/Phonophobia/script.lua:25; Phonophobia Android Port/data/Phonophobia/script.lua:26; Phonophobia Android Port/data/Phonophobia/script.lua:27; Phonophobia Android Port/data/Phonophobia/script.lua:65; Phonophobia Android Port/data/Phonophobia/script.lua:76; Phonophobia Android Port/data/Phonophobia/script.lua:145; Phonophobia Android Port/data/Phonophobia/script.lua:167; Phonophobia Android Port/data/Phonophobia/script.lua:171; Phonophobia Android Port/data/Phonophobia/script.lua:209; Phonophobia Android Port/data/Phonophobia/script.lua:210; Phonophobia Android Port/data/Phonophobia/script.lua:220; blubalscript(5resist).lua:114; blubalscript(5resist).lua:495; blubalscript(5resist).lua:510 |
| makeLuaSprite | 15 | engine/external | distinta | funkin/backend/scripts/compat.lua:312 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:6; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:5; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:8; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:11; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:19; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:23; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:27; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:31; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:3; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:6; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:9; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:12; Phonophobia Android Port/stages/White.lua:2; Phonophobia Android Port/stages/White.lua:6; blubalscript(5resist).lua:569 |
| setTextColor | 14 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:109 | blubalscript(5resist).lua:70; blubalscript(5resist).lua:83; blubalscript(5resist).lua:97; blubalscript(5resist).lua:107; blubalscript(5resist).lua:156; blubalscript(5resist).lua:166; blubalscript(5resist).lua:265; blubalscript(5resist).lua:341; blubalscript(5resist).lua:361; blubalscript(5resist).lua:367; blubalscript(5resist).lua:434; blubalscript(5resist).lua:436; blubalscript(5resist).lua:441; blubalscript(5resist).lua:443 |
| characterPlayAnim | 13 | engine/external | distinta | funkin/backend/scripts/compat.lua:513 | blubalscript(5resist).lua:462; blubalscript(5resist).lua:631; blubalscript(5resist).lua:634; blubalscript(5resist).lua:637; blubalscript(5resist).lua:640; blubalscript(5resist).lua:644; blubalscript(5resist).lua:647; blubalscript(5resist).lua:650; blubalscript(5resist).lua:653; blubalscript(5resist).lua:686; blubalscript(5resist).lua:691; blubalscript(5resist).lua:726; blubalscript(5resist).lua:733 |
| makeLuaText | 13 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:94 | Phonophobia Android Port/scripts/Heath_Display.lua:4; blubalscript(5resist).lua:57; blubalscript(5resist).lua:59; blubalscript(5resist).lua:63; blubalscript(5resist).lua:65; blubalscript(5resist).lua:78; blubalscript(5resist).lua:80; blubalscript(5resist).lua:92; blubalscript(5resist).lua:94; blubalscript(5resist).lua:102; blubalscript(5resist).lua:104; blubalscript(5resist).lua:154; blubalscript(5resist).lua:164 |
| math.sin | 12 | Lua builtin | sin fila | — | Phonophobia Android Port/data/Phonophobia/script.lua:84; Phonophobia Android Port/data/Phonophobia/script.lua:85; Phonophobia Android Port/data/Phonophobia/script.lua:91; Phonophobia Android Port/data/Phonophobia/script.lua:92; Phonophobia Android Port/data/Phonophobia/script.lua:93; Phonophobia Android Port/data/Phonophobia/script.lua:94; Phonophobia Android Port/data/Phonophobia/script.lua:100; Phonophobia Android Port/data/Phonophobia/script.lua:101; Phonophobia Android Port/data/Phonophobia/script.lua:102; Phonophobia Android Port/data/Phonophobia/script.lua:103; Phonophobia Android Port/data/Phonophobia/script.lua:154; Phonophobia Android Port/scripts/floating.lua:6 |
| noteTweenAngle | 12 | engine/external | distinta | funkin/backend/scripts/psych/notes.lua:132 | blubalscript(5resist).lua:498; blubalscript(5resist).lua:501; blubalscript(5resist).lua:504; blubalscript(5resist).lua:507; blubalscript(5resist).lua:514; blubalscript(5resist).lua:518; blubalscript(5resist).lua:522; blubalscript(5resist).lua:526; blubalscript(5resist).lua:530; blubalscript(5resist).lua:534; blubalscript(5resist).lua:538; blubalscript(5resist).lua:542 |
| doTweenY | 11 | engine/external | distinta | funkin/backend/scripts/compat.lua:408 | Phonophobia Android Port/data/Phonophobia/script.lua:154; Phonophobia Android Port/scripts/floating.lua:6; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:9; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:10; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:11; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:12; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:14; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:15; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:16; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:17; blubalscript(5resist).lua:112 |
| setTextString | 10 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:108 | Phonophobia Android Port/scripts/Heath_Display.lua:10; blubalscript(5resist).lua:372; blubalscript(5resist).lua:373; blubalscript(5resist).lua:376; blubalscript(5resist).lua:377; blubalscript(5resist).lua:385; blubalscript(5resist).lua:387; blubalscript(5resist).lua:489; blubalscript(5resist).lua:490; blubalscript(5resist).lua:670 |
| addAnimationByPrefix | 9 | engine/external | distinta | funkin/backend/scripts/compat.lua:371 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:37; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:42; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:47; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:53; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:17; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:21; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:26; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:32; blubalscript(5resist).lua:211 |
| makeAnimatedLuaSprite | 9 | engine/external | distinta | funkin/backend/scripts/compat.lua:313 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:36; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:41; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:46; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:52; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:16; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:20; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:25; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:31; blubalscript(5resist).lua:210 |
| math.cos | 8 | Lua builtin | sin fila | — | Phonophobia Android Port/data/Phonophobia/script.lua:95; Phonophobia Android Port/data/Phonophobia/script.lua:96; Phonophobia Android Port/data/Phonophobia/script.lua:97; Phonophobia Android Port/data/Phonophobia/script.lua:98; Phonophobia Android Port/data/Phonophobia/script.lua:104; Phonophobia Android Port/data/Phonophobia/script.lua:105; Phonophobia Android Port/data/Phonophobia/script.lua:106; Phonophobia Android Port/data/Phonophobia/script.lua:107 |
| noteTweenY | 8 | engine/external | distinta | funkin/backend/scripts/psych/notes.lua:132 | Phonophobia Android Port/data/Phonophobia/script.lua:95; Phonophobia Android Port/data/Phonophobia/script.lua:96; Phonophobia Android Port/data/Phonophobia/script.lua:97; Phonophobia Android Port/data/Phonophobia/script.lua:98; Phonophobia Android Port/data/Phonophobia/script.lua:104; Phonophobia Android Port/data/Phonophobia/script.lua:105; Phonophobia Android Port/data/Phonophobia/script.lua:106; Phonophobia Android Port/data/Phonophobia/script.lua:107 |
| removeLuaText | 8 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:107 | blubalscript(5resist).lua:660; blubalscript(5resist).lua:661; blubalscript(5resist).lua:667; blubalscript(5resist).lua:668; blubalscript(5resist).lua:676; blubalscript(5resist).lua:677; blubalscript(5resist).lua:681; blubalscript(5resist).lua:682 |
| runTimer | 8 | engine/external | distinta | funkin/backend/scripts/compat.lua:418 | blubalscript(5resist).lua:11; blubalscript(5resist).lua:13; blubalscript(5resist).lua:188; blubalscript(5resist).lua:214; blubalscript(5resist).lua:473; blubalscript(5resist).lua:475; blubalscript(5resist).lua:478; blubalscript(5resist).lua:480 |
| addLuaText | 7 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:106 | Phonophobia Android Port/scripts/Heath_Display.lua:5; blubalscript(5resist).lua:72; blubalscript(5resist).lua:85; blubalscript(5resist).lua:109; blubalscript(5resist).lua:158; blubalscript(5resist).lua:168; blubalscript(5resist).lua:666 |
| setLuaSpriteScrollFactor | 7 | engine/external | distinta | funkin/backend/scripts/compat.lua:368 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:9; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:32; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:48; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:54; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:13; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:27; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:33 |
| setObjectCamera | 7 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:70 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:14; blubalscript(5resist).lua:69; blubalscript(5resist).lua:82; blubalscript(5resist).lua:96; blubalscript(5resist).lua:106; blubalscript(5resist).lua:155; blubalscript(5resist).lua:165 |
| setTextSize | 7 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:122 | Phonophobia Android Port/scripts/Heath_Display.lua:6; blubalscript(5resist).lua:71; blubalscript(5resist).lua:84; blubalscript(5resist).lua:98; blubalscript(5resist).lua:108; blubalscript(5resist).lua:157; blubalscript(5resist).lua:167 |
| addCharacterToList | 6 | engine/external | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | blubalscript(5resist).lua:30; blubalscript(5resist).lua:31; blubalscript(5resist).lua:32; blubalscript(5resist).lua:33; blubalscript(5resist).lua:34; blubalscript(5resist).lua:35 |
| removeLuaSprite | 6 | engine/external | distinta | funkin/backend/scripts/compat.lua:342 | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Stage Changer.lua:6; blubalscript(5resist).lua:222; blubalscript(5resist).lua:225; blubalscript(5resist).lua:228; blubalscript(5resist).lua:231; blubalscript(5resist).lua:585 |
| setPropertyFromClass | 6 | engine/external | distinta | funkin/backend/scripts/psych/gameplay.lua:57 | Phonophobia Android Port/data/Phonophobia/script.lua:168; Phonophobia Android Port/data/Phonophobia/script.lua:172; Phonophobia Android Port/data/Phonophobia/script.lua:211; Phonophobia Android Port/data/Phonophobia/script.lua:212; blubalscript(5resist).lua:342; blubalscript(5resist).lua:362 |
| setTextAlignment | 6 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:110 | blubalscript(5resist).lua:74; blubalscript(5resist).lua:87; blubalscript(5resist).lua:100; blubalscript(5resist).lua:111; blubalscript(5resist).lua:161; blubalscript(5resist).lua:171 |
| setTextFont | 6 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:127 | blubalscript(5resist).lua:73; blubalscript(5resist).lua:86; blubalscript(5resist).lua:99; blubalscript(5resist).lua:110; blubalscript(5resist).lua:160; blubalscript(5resist).lua:170 |
| math.random | 5 | Lua builtin | sin fila | — | Phonophobia Android Port/data/Phonophobia/script.lua:211; Phonophobia Android Port/data/Phonophobia/script.lua:212; blubalscript(5resist).lua:486; blubalscript(5resist).lua:487; blubalscript(5resist).lua:488 |
| precacheImage | 5 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:175 | blubalscript(5resist).lua:36; blubalscript(5resist).lua:39; blubalscript(5resist).lua:40; blubalscript(5resist).lua:41; blubalscript(5resist).lua:42 |
| cameraFlash | 4 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:163 | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Camera Flash.lua:4; blubalscript(5resist).lua:575; blubalscript(5resist).lua:701; blubalscript(5resist).lua:722 |
| doTweenZoom | 4 | engine/external | distinta | funkin/backend/scripts/compat.lua:408 | Phonophobia Android Port/data/Phonophobia/script.lua:37; Phonophobia Android Port/data/Phonophobia/script.lua:39; Phonophobia Android Port/data/Phonophobia/script.lua:113; Phonophobia Android Port/data/Phonophobia/script.lua:114 |
| getColorFromHex | 4 | engine/external | distinta | funkin/backend/scripts/psych/media.lua:20 | blubalscript(5resist).lua:392; blubalscript(5resist).lua:396; blubalscript(5resist).lua:400; blubalscript(5resist).lua:403 |
| playSound | 4 | engine/external | distinta | funkin/backend/scripts/compat.lua:433 | blubalscript(5resist).lua:300; blubalscript(5resist).lua:687; blubalscript(5resist).lua:692; blubalscript(5resist).lua:730 |
| close | 3 | engine/external | sin fila | — | Phonophobia Android Port/stages/White.lua:10; blubalscript(5resist).lua:22; blubalscript(5resist).lua:301 |
| endin | 3 | helper | sin fila | — | blubalscript(5resist).lua:659; blubalscript(5resist).lua:665; blubalscript(5resist).lua:680 |
| doTweenColor | 2 | engine/external | ausente | funkin/backend/scripts/psych/gameplay.lua:22 | blubalscript(5resist).lua:324; blubalscript(5resist).lua:355 |
| getPropertyFromGroup | 2 | engine/external | distinta | funkin/backend/scripts/psych/notes.lua:114 | Phonophobia Android Port/data/Phonophobia/script.lua:51; Phonophobia Android Port/data/Phonophobia/script.lua:53 |
| getSongPosition | 2 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:165 | Phonophobia Android Port/data/Phonophobia/script.lua:152; Phonophobia Android Port/scripts/floating.lua:4 |
| math.floor | 2 | Lua builtin | sin fila | — | Phonophobia Android Port/scripts/Heath_Display.lua:4; Phonophobia Android Port/scripts/Heath_Display.lua:10 |
| setPropertyFromGroup | 2 | engine/external | distinta | funkin/backend/scripts/psych/notes.lua:119 | Phonophobia Android Port/data/Phonophobia/script.lua:84; Phonophobia Android Port/data/Phonophobia/script.lua:85 |
| startDialogue | 2 | engine/external | distinta | funkin/backend/scripts/psych/cutscene.lua:69 | blubalscript(5resist).lua:249; blubalscript(5resist).lua:252 |
| addLuaScript | 1 | engine/external | distinta | funkin/backend/scripts/psych/scripts.lua:44 | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Stage Changer.lua:3 |
| doTweenAngle | 1 | engine/external | distinta | funkin/backend/scripts/compat.lua:408 | Phonophobia Android Port/data/Phonophobia/script.lua:255 |
| doTweenX | 1 | engine/external | distinta | funkin/backend/scripts/compat.lua:408 | Phonophobia Android Port/data/Phonophobia/script.lua:256 |
| ending | 1 | engine/external | sin fila | — | blubalscript(5resist).lua:675 |
| keyJustPressed | 1 | engine/external | implementada | funkin/backend/scripts/psych/input.lua:15 | blubalscript(5resist).lua:281 |
| loadScript | 1 | engine/external | sin fila | — | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Stage Changer.lua:4 |
| makeGraphic | 1 | engine/external | distinta | funkin/backend/scripts/compat.lua:314 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:7 |
| objectPlayAnimation | 1 | engine/external | distinta | funkin/backend/scripts/compat.lua:406 | blubalscript(5resist).lua:212 |
| precacheSound | 1 | engine/external | distinta | funkin/backend/scripts/compat-controls.lua:175 | blubalscript(5resist).lua:43 |
| removeLuaScript | 1 | engine/external | distinta | funkin/backend/scripts/psych/scripts.lua:46 | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Stage Changer.lua:5 |
| resizeWindow | 1 | engine/external | sin fila | — | Phonophobia Android Port/data/Phonophobia/script.lua:205 |
| setSplashSets | 1 | helper | sin fila | — | blubalscript(5resist).lua:116 |
| startVideo | 1 | engine/external | distinta | funkin/backend/scripts/psych/cutscene.lua:27 | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/reaction.lua:6 |
| table.insert | 1 | Lua builtin | sin fila | — | Phonophobia Android Port/data/Phonophobia/script.lua:55 |
| victoryCheck | 1 | helper | sin fila | — | blubalscript(5resist).lua:627 |
| windowShake | 1 | helper | sin fila | — | Phonophobia Android Port/data/Phonophobia/script.lua:221 |

## Property and object routes

| route/expression | occurrences | inventory status | Light reference | route context | access and source sites |
|---|---|---|---|---|---|
| <'splash' .. direction>.animation | 1 | sin fila | — | engine/class/group route | addAnimationByPrefix implicit target field @ blubalscript(5resist).lua:211 |
| <'splash'.. direction>.animation | 1 | sin fila | — | engine/class/group route | objectPlayAnimation implicit target field @ blubalscript(5resist).lua:212 |
| ClientPrefs.noteSplashes | 1 | sin fila | — | engine/class/group route | getPropertyFromClass @ blubalscript(5resist).lua:114 |
| ClientPrefs.windowMove | 3 | sin fila | — | engine/class/group route | getPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:76; getPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:145; getPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:220 |
| Conductor.songPosition | 1 | sin fila | — | engine/class/group route | getPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:65 |
| Lost.alignment | 1 | sin fila | — | created by a corpus script | setTextAlignment implicit target field @ blubalscript(5resist).lua:100 |
| Lost.cameras | 1 | sin fila | — | created by a corpus script | setObjectCamera implicit target field @ blubalscript(5resist).lua:96 |
| Lost.color | 1 | sin fila | — | created by a corpus script | setTextColor implicit target field @ blubalscript(5resist).lua:97 |
| Lost.font | 1 | sin fila | — | created by a corpus script | setTextFont implicit target field @ blubalscript(5resist).lua:99 |
| Lost.size | 1 | sin fila | — | created by a corpus script | setTextSize implicit target field @ blubalscript(5resist).lua:98 |
| Lost.text | 1 | sin fila | — | created by a corpus script | setTextString implicit target field @ blubalscript(5resist).lua:670 |
| backend.ClientPrefs.data.middleScroll | 2 | sin fila | — | engine/class/group route | getPropertyFromClass @ blubalscript(5resist).lua:495; getPropertyFromClass @ blubalscript(5resist).lua:510 |
| behind.animation | 2 | sin fila | — | created by a corpus script | addAnimationByPrefix implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:37; addAnimationByPrefix implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:17 |
| behind.scale.x | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:38; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:18 |
| behind.scale.y | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:38; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:18 |
| behind.visible | 2 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:39; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:93 |
| bgshit.scale.x | 1 | sin fila | — | created by a corpus script | scaleObject implicit target field @ Phonophobia Android Port/stages/White.lua:3 |
| bgshit.scale.y | 1 | sin fila | — | created by a corpus script | scaleObject implicit target field @ Phonophobia Android Port/stages/White.lua:3 |
| botplayTxt.y | 1 | ausente | funkin/backend/scripts/compat.lua:77 | engine/class/group route | doTweenY @ blubalscript(5resist).lua:112 |
| boyfriend.alpha | 5 | distinta | funkin/backend/scripts/compat.lua:516 | engine/class/group route | setProperty @ blubalscript(5resist).lua:576; setProperty @ blubalscript(5resist).lua:705; setProperty @ blubalscript(5resist).lua:710; setProperty @ blubalscript(5resist).lua:720; doTweenAlpha @ blubalscript(5resist).lua:734 |
| boyfriend.animation | 11 | distinta | funkin/backend/scripts/compat.lua:516 | engine/class/group route | characterPlayAnim implicit target field @ blubalscript(5resist).lua:462; characterPlayAnim implicit target field @ blubalscript(5resist).lua:631; characterPlayAnim implicit target field @ blubalscript(5resist).lua:634; characterPlayAnim implicit target field @ blubalscript(5resist).lua:637; characterPlayAnim implicit target field @ blubalscript(5resist).lua:640; characterPlayAnim implicit target field @ blubalscript(5resist).lua:644; characterPlayAnim implicit target field @ blubalscript(5resist).lua:647; characterPlayAnim implicit target field @ blubalscript(5resist).lua:650; characterPlayAnim implicit target field @ blubalscript(5resist).lua:653; characterPlayAnim implicit target field @ blubalscript(5resist).lua:726; characterPlayAnim implicit target field @ blubalscript(5resist).lua:733 |
| boyfriend.curCharacter | 2 | distinta | funkin/backend/scripts/compat.lua:516 | engine/class/group route | getProperty @ blubalscript(5resist).lua:10; getProperty @ blubalscript(5resist).lua:20 |
| camGame.zoom | 3 | distinta | funkin/backend/scripts/compat.lua:61 | engine/class/group route | setProperty @ Phonophobia Android Port/data/Phonophobia/script.lua:36; doTweenZoom @ Phonophobia Android Port/data/Phonophobia/script.lua:37; doTweenZoom @ Phonophobia Android Port/data/Phonophobia/script.lua:113 |
| camHUD.alpha | 1 | distinta | funkin/backend/scripts/compat.lua:356 | engine/class/group route | doTweenAlpha @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Goodbye Hud.lua:3 |
| camHUD.angle | 3 | distinta | funkin/backend/scripts/compat.lua:356 | engine/class/group route | setProperty @ Phonophobia Android Port/data/Phonophobia/script.lua:244; setProperty @ Phonophobia Android Port/data/Phonophobia/script.lua:253; doTweenAngle @ Phonophobia Android Port/data/Phonophobia/script.lua:255 |
| camHUD.x | 1 | distinta | funkin/backend/scripts/compat.lua:356 | engine/class/group route | doTweenX @ Phonophobia Android Port/data/Phonophobia/script.lua:256 |
| camHUD.zoom | 3 | distinta | funkin/backend/scripts/compat.lua:356 | engine/class/group route | setProperty @ Phonophobia Android Port/data/Phonophobia/script.lua:38; doTweenZoom @ Phonophobia Android Port/data/Phonophobia/script.lua:39; doTweenZoom @ Phonophobia Android Port/data/Phonophobia/script.lua:114 |
| control.alignment | 1 | sin fila | — | created by a corpus script | setTextAlignment implicit target field @ blubalscript(5resist).lua:87 |
| control.alpha | 4 | sin fila | — | created by a corpus script | setProperty @ blubalscript(5resist).lua:88; doTweenAlpha @ blubalscript(5resist).lua:464; doTweenAlpha @ blubalscript(5resist).lua:725; doTweenAlpha @ blubalscript(5resist).lua:732 |
| control.cameras | 1 | sin fila | — | created by a corpus script | setObjectCamera implicit target field @ blubalscript(5resist).lua:82 |
| control.color | 1 | sin fila | — | created by a corpus script | setTextColor implicit target field @ blubalscript(5resist).lua:83 |
| control.font | 1 | sin fila | — | created by a corpus script | setTextFont implicit target field @ blubalscript(5resist).lua:86 |
| control.scale.x | 1 | sin fila | — | created by a corpus script | setProperty @ blubalscript(5resist).lua:314 |
| control.scale.y | 1 | sin fila | — | created by a corpus script | setProperty @ blubalscript(5resist).lua:315 |
| control.size | 1 | sin fila | — | created by a corpus script | setTextSize implicit target field @ blubalscript(5resist).lua:84 |
| control.text | 3 | sin fila | — | created by a corpus script | setTextString implicit target field @ blubalscript(5resist).lua:373; setTextString implicit target field @ blubalscript(5resist).lua:377; setTextString implicit target field @ blubalscript(5resist).lua:490 |
| curt.scale.x | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:33; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:14 |
| curt.scale.y | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:33; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:14 |
| curt.scrollFactor.x | 2 | sin fila | — | created by a corpus script | setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:32; setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:13 |
| curt.scrollFactor.y | 2 | sin fila | — | created by a corpus script | setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:32; setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:13 |
| curt.visible | 2 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:34; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:87 |
| curtpast.scale.x | 1 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:12 |
| curtpast.scale.y | 1 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:12 |
| curtpast.visible | 1 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:84 |
| dad.alpha | 5 | distinta | funkin/backend/scripts/compat.lua:64 | engine/class/group route | setProperty @ blubalscript(5resist).lua:47; setProperty @ blubalscript(5resist).lua:577; setProperty @ blubalscript(5resist).lua:706; setProperty @ blubalscript(5resist).lua:711; doTweenAlpha @ blubalscript(5resist).lua:721 |
| dad.animation | 2 | distinta | funkin/backend/scripts/compat.lua:64 | engine/class/group route | characterPlayAnim implicit target field @ blubalscript(5resist).lua:686; characterPlayAnim implicit target field @ blubalscript(5resist).lua:691 |
| dad.y | 2 | distinta | funkin/backend/scripts/compat.lua:64 | engine/class/group route | doTweenY @ Phonophobia Android Port/data/Phonophobia/script.lua:154; doTweenY @ Phonophobia Android Port/scripts/floating.lua:6 |
| dancer.animation | 2 | sin fila | — | created by a corpus script | addAnimationByPrefix implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:53; addAnimationByPrefix implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:32 |
| dancer.scale.x | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:55; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:34 |
| dancer.scale.y | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:55; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:34 |
| dancer.scrollFactor.x | 2 | sin fila | — | created by a corpus script | setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:54; setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:33 |
| dancer.scrollFactor.y | 2 | sin fila | — | created by a corpus script | setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:54; setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:33 |
| dancer.visible | 6 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:56; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:100; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:105; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:35; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:64; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:69 |
| defaultCamZoom | 1 | distinta | funkin/backend/scripts/compat.lua:85 | engine/class/group route | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:92 |
| fakeScore.alignment | 1 | sin fila | — | created by a corpus script | setTextAlignment implicit target field @ blubalscript(5resist).lua:111 |
| fakeScore.cameras | 1 | sin fila | — | created by a corpus script | setObjectCamera implicit target field @ blubalscript(5resist).lua:106 |
| fakeScore.color | 5 | sin fila | — | created by a corpus script | setTextColor implicit target field @ blubalscript(5resist).lua:107; setProperty @ blubalscript(5resist).lua:392; setProperty @ blubalscript(5resist).lua:396; setProperty @ blubalscript(5resist).lua:400; setProperty @ blubalscript(5resist).lua:403 |
| fakeScore.font | 1 | sin fila | — | created by a corpus script | setTextFont implicit target field @ blubalscript(5resist).lua:110 |
| fakeScore.scale.x | 2 | sin fila | — | created by a corpus script | setProperty @ blubalscript(5resist).lua:186; setProperty @ blubalscript(5resist).lua:258 |
| fakeScore.scale.y | 2 | sin fila | — | created by a corpus script | setProperty @ blubalscript(5resist).lua:187; setProperty @ blubalscript(5resist).lua:259 |
| fakeScore.size | 1 | sin fila | — | created by a corpus script | setTextSize implicit target field @ blubalscript(5resist).lua:108 |
| fakeScore.text | 2 | sin fila | — | created by a corpus script | setTextString implicit target field @ blubalscript(5resist).lua:385; setTextString implicit target field @ blubalscript(5resist).lua:387 |
| fgshit.scale.x | 1 | sin fila | — | created by a corpus script | scaleObject implicit target field @ Phonophobia Android Port/stages/White.lua:7 |
| fgshit.scale.y | 1 | sin fila | — | created by a corpus script | scaleObject implicit target field @ Phonophobia Android Port/stages/White.lua:7 |
| flash.alpha | 3 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:12; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:13; doTweenAlpha @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:15 |
| flash.cameras | 1 | sin fila | — | created by a corpus script | setObjectCamera implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:14 |
| flash.color | 1 | sin fila | — | created by a corpus script | makeGraphic implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:7 |
| flash.pixels | 1 | sin fila | — | created by a corpus script | makeGraphic implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:7 |
| flash.scale.x | 1 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:10 |
| flash.scale.y | 1 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:11 |
| flash.scrollFactor.x | 1 | sin fila | — | created by a corpus script | setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:9 |
| flash.scrollFactor.y | 1 | sin fila | — | created by a corpus script | setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:9 |
| floor.scale.x | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:24; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:7 |
| floor.scale.y | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:24; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:7 |
| floor.visible | 2 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:25; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:86 |
| floorpast.scale.x | 1 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:9 |
| floorpast.scale.y | 1 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:9 |
| floorpast.visible | 1 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:83 |
| gf.alpha | 3 | distinta | funkin/backend/scripts/compat.lua:517 | engine/class/group route | setProperty @ blubalscript(5resist).lua:46; setProperty @ blubalscript(5resist).lua:572; setProperty @ blubalscript(5resist).lua:587 |
| gf.visible | 1 | distinta | funkin/backend/scripts/compat.lua:517 | engine/class/group route | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:88 |
| health | 33 | distinta | funkin/backend/scripts/psych/notes.lua:45 | engine/class/group route | getProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/deathmatch/script.lua:2; getProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/deathmatch/script.lua:3; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/deathmatch/script.lua:4; getProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/the-deathmatch/script.lua:2; getProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/the-deathmatch/script.lua:3; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/the-deathmatch/script.lua:4; setProperty @ Phonophobia Android Port/data/Phonophobia/script.lua:264; getProperty @ Phonophobia Android Port/data/Phonophobia/script.lua:264; setProperty @ Phonophobia Android Port/data/Phonophobia/script.lua:267; getProperty @ Phonophobia Android Port/data/Phonophobia/script.lua:267; getProperty @ Phonophobia Android Port/scripts/Heath_Display.lua:4; getProperty @ Phonophobia Android Port/scripts/Heath_Display.lua:10; getProperty @ Phonophobia Android Port/scripts/health_drain.lua:2; setProperty @ Phonophobia Android Port/scripts/health_drain.lua:4; setProperty @ blubalscript(5resist).lua:50; setProperty @ blubalscript(5resist).lua:176; getProperty @ blubalscript(5resist).lua:176; setProperty @ blubalscript(5resist).lua:179; getProperty @ blubalscript(5resist).lua:179; getProperty @ blubalscript(5resist).lua:199; getProperty @ blubalscript(5resist).lua:200; setProperty @ blubalscript(5resist).lua:201; getProperty @ blubalscript(5resist).lua:203; setProperty @ blubalscript(5resist).lua:204; getProperty @ blubalscript(5resist).lua:407; getProperty @ blubalscript(5resist).lua:413; getProperty @ blubalscript(5resist).lua:413; getProperty @ blubalscript(5resist).lua:419; setProperty @ blubalscript(5resist).lua:463; setProperty @ blubalscript(5resist).lua:580; setProperty @ blubalscript(5resist).lua:586; setProperty @ blubalscript(5resist).lua:727; setProperty @ blubalscript(5resist).lua:729 |
| healthBar.visible | 1 | distinta | funkin/backend/scripts/compat.lua:63 | engine/class/group route | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:81 |
| healthLabel.y | 2 | sin fila | — | engine/class/group route | doTweenY @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:9; doTweenY @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:14 |
| healthLabelShadow.y | 2 | sin fila | — | engine/class/group route | doTweenY @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:11; doTweenY @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:16 |
| healthText.size | 1 | sin fila | — | created by a corpus script | setTextSize implicit target field @ Phonophobia Android Port/scripts/Heath_Display.lua:6 |
| healthText.text | 1 | sin fila | — | created by a corpus script | setTextString implicit target field @ Phonophobia Android Port/scripts/Heath_Display.lua:10 |
| healthValue.y | 2 | sin fila | — | engine/class/group route | doTweenY @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:10; doTweenY @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:15 |
| healthValueShadow.y | 2 | sin fila | — | engine/class/group route | doTweenY @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:12; doTweenY @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:17 |
| icon-bf.visible | 1 | sin fila | — | engine/class/group route | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:79 |
| icon-dad.visible | 1 | sin fila | — | engine/class/group route | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:80 |
| iconP1.alpha | 4 | distinta | funkin/backend/scripts/compat.lua:63 | engine/class/group route | doTweenAlpha @ blubalscript(5resist).lua:409; doTweenAlpha @ blubalscript(5resist).lua:415; doTweenAlpha @ blubalscript(5resist).lua:421; setProperty @ blubalscript(5resist).lua:428 |
| iconP1.scale.x | 2 | distinta | funkin/backend/scripts/compat.lua:63 | engine/class/group route | getProperty @ blubalscript(5resist).lua:311; getProperty @ blubalscript(5resist).lua:314 |
| iconP1.scale.y | 2 | distinta | funkin/backend/scripts/compat.lua:63 | engine/class/group route | getProperty @ blubalscript(5resist).lua:312; getProperty @ blubalscript(5resist).lua:315 |
| iconP2.alpha | 1 | distinta | funkin/backend/scripts/compat.lua:64 | engine/class/group route | setProperty @ blubalscript(5resist).lua:49 |
| inCutscene | 2 | distinta | funkin/states/play.lua:283 | engine/class/group route | setProperty @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/reaction.lua:7; setProperty @ blubalscript(5resist).lua:8 |
| mic.scale.x | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:28; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:10 |
| mic.scale.y | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:28; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:10 |
| mic.visible | 1 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:29 |
| mid.animation | 2 | sin fila | — | created by a corpus script | addAnimationByPrefix implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:47; addAnimationByPrefix implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:26 |
| mid.scale.x | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:49; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:28 |
| mid.scale.y | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:49; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:28 |
| mid.scrollFactor.x | 2 | sin fila | — | created by a corpus script | setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:48; setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:27 |
| mid.scrollFactor.y | 2 | sin fila | — | created by a corpus script | setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:48; setLuaSpriteScrollFactor implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:27 |
| mid.visible | 4 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:50; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:95; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:29; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:59 |
| openfl.Lib.application.window.title | 2 | sin fila | — | engine/class/group route | setPropertyFromClass @ blubalscript(5resist).lua:342; setPropertyFromClass @ blubalscript(5resist).lua:362 |
| openfl.Lib.application.window.x | 8 | sin fila | — | engine/class/group route | getPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:24; getPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:26; getPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:167; setPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:168; getPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:171; setPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:172; getPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:209; setPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:211 |
| openfl.Lib.application.window.y | 4 | sin fila | — | engine/class/group route | getPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:25; getPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:27; getPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:210; setPropertyFromClass @ Phonophobia Android Port/data/Phonophobia/script.lua:212 |
| people.animation | 2 | sin fila | — | created by a corpus script | addAnimationByPrefix implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:42; addAnimationByPrefix implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:21 |
| people.scale.x | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:43; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:22 |
| people.scale.y | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:43; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:22 |
| people.visible | 8 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:44; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:94; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:99; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:104; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:23; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:58; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:63; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:68 |
| ratingFC | 1 | ausente | funkin/backend/modding/psych.lua:93 | engine/class/group route | getProperty @ blubalscript(5resist).lua:382 |
| resist.alignment | 1 | sin fila | — | created by a corpus script | setTextAlignment implicit target field @ blubalscript(5resist).lua:74 |
| resist.alpha | 2 | sin fila | — | created by a corpus script | doTweenAlpha @ blubalscript(5resist).lua:724; doTweenAlpha @ blubalscript(5resist).lua:731 |
| resist.cameras | 1 | sin fila | — | created by a corpus script | setObjectCamera implicit target field @ blubalscript(5resist).lua:69 |
| resist.color | 11 | sin fila | — | created by a corpus script | setTextColor implicit target field @ blubalscript(5resist).lua:70; setTextColor implicit target field @ blubalscript(5resist).lua:265; doTweenColor @ blubalscript(5resist).lua:324; setTextColor implicit target field @ blubalscript(5resist).lua:341; doTweenColor @ blubalscript(5resist).lua:355; setTextColor implicit target field @ blubalscript(5resist).lua:361; setTextColor implicit target field @ blubalscript(5resist).lua:367; setTextColor implicit target field @ blubalscript(5resist).lua:434; setTextColor implicit target field @ blubalscript(5resist).lua:436; setTextColor implicit target field @ blubalscript(5resist).lua:441; setTextColor implicit target field @ blubalscript(5resist).lua:443 |
| resist.font | 1 | sin fila | — | created by a corpus script | setTextFont implicit target field @ blubalscript(5resist).lua:73 |
| resist.scale.x | 1 | sin fila | — | created by a corpus script | setProperty @ blubalscript(5resist).lua:311 |
| resist.scale.y | 1 | sin fila | — | created by a corpus script | setProperty @ blubalscript(5resist).lua:312 |
| resist.size | 1 | sin fila | — | created by a corpus script | setTextSize implicit target field @ blubalscript(5resist).lua:71 |
| resist.text | 3 | sin fila | — | created by a corpus script | setTextString implicit target field @ blubalscript(5resist).lua:372; setTextString implicit target field @ blubalscript(5resist).lua:376; setTextString implicit target field @ blubalscript(5resist).lua:489 |
| scoreTxt.alpha | 1 | ausente | funkin/backend/scripts/compat.lua:77 | engine/class/group route | setProperty @ blubalscript(5resist).lua:51 |
| skipCountdown | 1 | distinta | funkin/states/play.lua:282 | engine/class/group route | setProperty @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/reaction.lua:2 |
| songMisses | 8 | distinta | funkin/backend/scripts/compat.lua:75 | engine/class/group route | getProperty @ blubalscript(5resist).lua:319; getProperty @ blubalscript(5resist).lua:627; getProperty @ blubalscript(5resist).lua:658; getProperty @ blubalscript(5resist).lua:664; getProperty @ blubalscript(5resist).lua:674; getProperty @ blubalscript(5resist).lua:679; getProperty @ blubalscript(5resist).lua:685; getProperty @ blubalscript(5resist).lua:690 |
| songScore | 1 | distinta | funkin/backend/scripts/compat.lua:75 | engine/class/group route | getProperty @ blubalscript(5resist).lua:381 |
| strumLineNotes[ 0 ].alpha | 3 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAlpha implicit receptor field @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:4; noteTweenAlpha implicit receptor field @ blubalscript(5resist).lua:499; noteTweenAlpha implicit receptor field @ blubalscript(5resist).lua:515 |
| strumLineNotes[ 0 ].angle | 2 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAngle implicit receptor field @ blubalscript(5resist).lua:498; noteTweenAngle implicit receptor field @ blubalscript(5resist).lua:514 |
| strumLineNotes[ 0 ].x | 4 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenX implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:100; noteTweenX implicit receptor field @ blubalscript(5resist).lua:286; noteTweenX implicit receptor field @ blubalscript(5resist).lua:497; noteTweenX implicit receptor field @ blubalscript(5resist).lua:513 |
| strumLineNotes[ 0 ].y | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenY implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:104 |
| strumLineNotes[ 1 ].alpha | 3 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAlpha implicit receptor field @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:5; noteTweenAlpha implicit receptor field @ blubalscript(5resist).lua:502; noteTweenAlpha implicit receptor field @ blubalscript(5resist).lua:519 |
| strumLineNotes[ 1 ].angle | 2 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAngle implicit receptor field @ blubalscript(5resist).lua:501; noteTweenAngle implicit receptor field @ blubalscript(5resist).lua:518 |
| strumLineNotes[ 1 ].x | 4 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenX implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:101; noteTweenX implicit receptor field @ blubalscript(5resist).lua:287; noteTweenX implicit receptor field @ blubalscript(5resist).lua:500; noteTweenX implicit receptor field @ blubalscript(5resist).lua:517 |
| strumLineNotes[ 1 ].y | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenY implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:105 |
| strumLineNotes[ 2 ].alpha | 3 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAlpha implicit receptor field @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:3; noteTweenAlpha implicit receptor field @ blubalscript(5resist).lua:505; noteTweenAlpha implicit receptor field @ blubalscript(5resist).lua:523 |
| strumLineNotes[ 2 ].angle | 2 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAngle implicit receptor field @ blubalscript(5resist).lua:504; noteTweenAngle implicit receptor field @ blubalscript(5resist).lua:522 |
| strumLineNotes[ 2 ].x | 4 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenX implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:102; noteTweenX implicit receptor field @ blubalscript(5resist).lua:288; noteTweenX implicit receptor field @ blubalscript(5resist).lua:503; noteTweenX implicit receptor field @ blubalscript(5resist).lua:521 |
| strumLineNotes[ 2 ].y | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenY implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:106 |
| strumLineNotes[ 3 ].alpha | 3 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAlpha implicit receptor field @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:6; noteTweenAlpha implicit receptor field @ blubalscript(5resist).lua:508; noteTweenAlpha implicit receptor field @ blubalscript(5resist).lua:527 |
| strumLineNotes[ 3 ].angle | 2 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAngle implicit receptor field @ blubalscript(5resist).lua:507; noteTweenAngle implicit receptor field @ blubalscript(5resist).lua:526 |
| strumLineNotes[ 3 ].x | 4 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenX implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:103; noteTweenX implicit receptor field @ blubalscript(5resist).lua:289; noteTweenX implicit receptor field @ blubalscript(5resist).lua:506; noteTweenX implicit receptor field @ blubalscript(5resist).lua:525 |
| strumLineNotes[ 3 ].y | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenY implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:107 |
| strumLineNotes[ 4 ].alpha | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAlpha implicit receptor field @ blubalscript(5resist).lua:531 |
| strumLineNotes[ 4 ].angle | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAngle implicit receptor field @ blubalscript(5resist).lua:530 |
| strumLineNotes[ 4 ].x | 3 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenX implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:91; noteTweenX implicit receptor field @ blubalscript(5resist).lua:282; noteTweenX implicit receptor field @ blubalscript(5resist).lua:529 |
| strumLineNotes[ 4 ].y | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenY implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:95 |
| strumLineNotes[ 5 ].alpha | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAlpha implicit receptor field @ blubalscript(5resist).lua:535 |
| strumLineNotes[ 5 ].angle | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAngle implicit receptor field @ blubalscript(5resist).lua:534 |
| strumLineNotes[ 5 ].x | 3 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenX implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:92; noteTweenX implicit receptor field @ blubalscript(5resist).lua:283; noteTweenX implicit receptor field @ blubalscript(5resist).lua:533 |
| strumLineNotes[ 5 ].y | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenY implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:96 |
| strumLineNotes[ 6 ].alpha | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAlpha implicit receptor field @ blubalscript(5resist).lua:539 |
| strumLineNotes[ 6 ].angle | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAngle implicit receptor field @ blubalscript(5resist).lua:538 |
| strumLineNotes[ 6 ].x | 3 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenX implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:93; noteTweenX implicit receptor field @ blubalscript(5resist).lua:284; noteTweenX implicit receptor field @ blubalscript(5resist).lua:537 |
| strumLineNotes[ 6 ].y | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenY implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:97 |
| strumLineNotes[ 7 ].alpha | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAlpha implicit receptor field @ blubalscript(5resist).lua:543 |
| strumLineNotes[ 7 ].angle | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenAngle implicit receptor field @ blubalscript(5resist).lua:542 |
| strumLineNotes[ 7 ].x | 3 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenX implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:94; noteTweenX implicit receptor field @ blubalscript(5resist).lua:285; noteTweenX implicit receptor field @ blubalscript(5resist).lua:541 |
| strumLineNotes[ 7 ].y | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenY implicit receptor field @ Phonophobia Android Port/data/Phonophobia/script.lua:98 |
| strumLineNotes[ i ].x | 2 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | getPropertyFromGroup @ Phonophobia Android Port/data/Phonophobia/script.lua:51; setPropertyFromGroup @ Phonophobia Android Port/data/Phonophobia/script.lua:84 |
| strumLineNotes[ i ].y | 2 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | getPropertyFromGroup @ Phonophobia Android Port/data/Phonophobia/script.lua:53; setPropertyFromGroup @ Phonophobia Android Port/data/Phonophobia/script.lua:85 |
| strumLineNotes[ i+4 ].x | 1 | distinta | funkin/backend/scripts/psych/notes.lua:112 | engine/class/group route | noteTweenX implicit receptor field @ VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:5 |
| timeBar.visible | 2 | distinta | funkin/backend/scripts/compat.lua:65 | engine/class/group route | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:70; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:49 |
| timeBarBG.visible | 2 | sin fila | — | engine/class/group route | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:72; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:51 |
| timeTxt.visible | 2 | distinta | funkin/backend/scripts/compat.lua:65 | engine/class/group route | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:71; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:50 |
| wall.scale.x | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:20; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:4 |
| wall.scale.y | 2 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:20; scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:4 |
| wall.visible | 2 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:21; setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:85 |
| wallpast.scale.x | 1 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:6 |
| wallpast.scale.y | 1 | sin fila | — | created by a corpus script | scaleObject implicit target field @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:6 |
| wallpast.visible | 1 | sin fila | — | created by a corpus script | setProperty @ (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:82 |
| warning1.alignment | 1 | sin fila | — | created by a corpus script | setTextAlignment implicit target field @ blubalscript(5resist).lua:161 |
| warning1.alpha | 3 | sin fila | — | created by a corpus script | setProperty @ blubalscript(5resist).lua:159; doTweenAlpha @ blubalscript(5resist).lua:236; doTweenAlpha @ blubalscript(5resist).lua:239 |
| warning1.cameras | 1 | sin fila | — | created by a corpus script | setObjectCamera implicit target field @ blubalscript(5resist).lua:155 |
| warning1.color | 1 | sin fila | — | created by a corpus script | setTextColor implicit target field @ blubalscript(5resist).lua:156 |
| warning1.font | 1 | sin fila | — | created by a corpus script | setTextFont implicit target field @ blubalscript(5resist).lua:160 |
| warning1.size | 1 | sin fila | — | created by a corpus script | setTextSize implicit target field @ blubalscript(5resist).lua:157 |
| warning2.alignment | 1 | sin fila | — | created by a corpus script | setTextAlignment implicit target field @ blubalscript(5resist).lua:171 |
| warning2.alpha | 3 | sin fila | — | created by a corpus script | setProperty @ blubalscript(5resist).lua:169; doTweenAlpha @ blubalscript(5resist).lua:243; doTweenAlpha @ blubalscript(5resist).lua:246 |
| warning2.cameras | 1 | sin fila | — | created by a corpus script | setObjectCamera implicit target field @ blubalscript(5resist).lua:165 |
| warning2.color | 1 | sin fila | — | created by a corpus script | setTextColor implicit target field @ blubalscript(5resist).lua:166 |
| warning2.font | 1 | sin fila | — | created by a corpus script | setTextFont implicit target field @ blubalscript(5resist).lua:170 |
| warning2.size | 1 | sin fila | — | created by a corpus script | setTextSize implicit target field @ blubalscript(5resist).lua:167 |

## Referenced classes

Class-state values below are inventory lookups, not proof of availability through getPropertyFromClass. A missing HScript preset and a supported Lua class-property getter are different access routes.

| class | occurrences | inventory cross-reference / actual route | sites |
|---|---|---|---|
| ClientPrefs | 4 | HScript preset absent in inventory; Lua class getter exists at psych/gameplay.lua:24 with selected preference aliases | Phonophobia Android Port/data/Phonophobia/script.lua:76; Phonophobia Android Port/data/Phonophobia/script.lua:145; Phonophobia Android Port/data/Phonophobia/script.lua:220; blubalscript(5resist).lua:114 |
| Conductor | 1 | distinta; Lua songPosition getter at psych/gameplay.lua:42 | Phonophobia Android Port/data/Phonophobia/script.lua:65 |
| backend.ClientPrefs | 2 | class alias missing from inventory; selected data fields resolved at psych/gameplay.lua:24 | blubalscript(5resist).lua:495; blubalscript(5resist).lua:510 |
| openfl.Lib | 14 | no class row; x/y getter exists, title writes have no equivalent setter in psych/gameplay.lua:57 | Phonophobia Android Port/data/Phonophobia/script.lua:24; Phonophobia Android Port/data/Phonophobia/script.lua:25; Phonophobia Android Port/data/Phonophobia/script.lua:26; Phonophobia Android Port/data/Phonophobia/script.lua:27; Phonophobia Android Port/data/Phonophobia/script.lua:167; Phonophobia Android Port/data/Phonophobia/script.lua:168; Phonophobia Android Port/data/Phonophobia/script.lua:171; Phonophobia Android Port/data/Phonophobia/script.lua:172; Phonophobia Android Port/data/Phonophobia/script.lua:209; Phonophobia Android Port/data/Phonophobia/script.lua:210; Phonophobia Android Port/data/Phonophobia/script.lua:211; Phonophobia Android Port/data/Phonophobia/script.lua:212; blubalscript(5resist).lua:342; blubalscript(5resist).lua:362 |

## Declared callbacks and helpers

| name | kind | inventory status | sites |
|---|---|---|---|
| endin | helper | sin fila | blubalscript(5resist).lua:715 |
| goodNoteHit | callback | distinta | blubalscript(5resist).lua:174 |
| noteMiss | callback | distinta | Phonophobia Android Port/data/Phonophobia/script.lua:263 |
| noteMissPress | callback | distinta | Phonophobia Android Port/data/Phonophobia/script.lua:266 |
| onBeatHit | callback | distinta | Phonophobia Android Port/data/Phonophobia/script.lua:229; blubalscript(5resist).lua:459 |
| onCreate | callback | distinta | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:1; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:1; Phonophobia Android Port/data/Phonophobia/script.lua:23; Phonophobia Android Port/scripts/Heath_Display.lua:3; Phonophobia Android Port/stages/White.lua:1; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/reaction.lua:1; blubalscript(5resist).lua:29 |
| onCreatePost | callback | distinta | blubalscript(5resist).lua:136 |
| onDestroy | callback | distinta | Phonophobia Android Port/data/Phonophobia/script.lua:227 |
| onEndSong | callback | distinta | blubalscript(5resist).lua:6 |
| onEvent | callback | distinta | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:1; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Camera Flash.lua:1; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Goodbye Hud.lua:1; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:1; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Stage Changer.lua:1 |
| onSongStart | callback | distinta | Phonophobia Android Port/data/Phonophobia/script.lua:47; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/reaction.lua:5 |
| onStepHit | callback | distinta | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:76; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:55; blubalscript(5resist).lua:469 |
| onTimerCompleted | callback | distinta | blubalscript(5resist).lua:219 |
| onTweenCompleted | callback | distinta | blubalscript(5resist).lua:263 |
| onUpdate | callback | distinta | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:69; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:48; Phonophobia Android Port/data/Phonophobia/script.lua:64; Phonophobia Android Port/scripts/Heath_Display.lua:8; Phonophobia Android Port/scripts/floating.lua:2; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:2; blubalscript(5resist).lua:277 |
| opponentNoteHit | callback | distinta | (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/deathmatch/script.lua:1; (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/the-deathmatch/script.lua:1; Phonophobia Android Port/data/Phonophobia/script.lua:43; Phonophobia Android Port/data/Phonophobia/script.lua:215; Phonophobia Android Port/scripts/health_drain.lua:1; Phonophobia Android Port/scripts/shake.lua:1; blubalscript(5resist).lua:197 |
| setSplashSets | helper | sin fila | blubalscript(5resist).lua:122 |
| swapTurn | helper | sin fila | blubalscript(5resist).lua:699 |
| victoryCheck | helper | sin fila | blubalscript(5resist).lua:738 |
| windowMove | helper | sin fila | Phonophobia Android Port/data/Phonophobia/script.lua:159 |
| windowShake | helper | sin fila | Phonophobia Android Port/data/Phonophobia/script.lua:208 |
| windowZooming | helper | sin fila | Phonophobia Android Port/data/Phonophobia/script.lua:177 |

## Global/external read candidates

These identifiers were not declared/assigned elsewhere in the same file according to the lexical scan. Resolve against Psych globals, script variables, and callbacks at runtime. Dynamic globals created by Lua can make this set conservative.

| identifier | occurrences | inventory status | sites |
|---|---|---|---|
| Function_Continue | 1 | distinta | blubalscript(5resist).lua:24 |
| Function_Stop | 1 | distinta | blubalscript(5resist).lua:18 |
| botPlay | 1 | distinta | blubalscript(5resist).lua:183 |
| bpm | 3 | distinta | Phonophobia Android Port/data/Phonophobia/script.lua:67; Phonophobia Android Port/data/Phonophobia/script.lua:153; Phonophobia Android Port/scripts/floating.lua:5 |
| camOther | 1 | distinta | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Camera Flash.lua:4 |
| crochet | 4 | distinta | Phonophobia Android Port/data/Phonophobia/script.lua:256; blubalscript(5resist).lua:409; blubalscript(5resist).lua:415; blubalscript(5resist).lua:421 |
| curBeat | 16 | distinta | Phonophobia Android Port/data/Phonophobia/script.lua:111; Phonophobia Android Port/data/Phonophobia/script.lua:128; Phonophobia Android Port/data/Phonophobia/script.lua:134; Phonophobia Android Port/data/Phonophobia/script.lua:231; Phonophobia Android Port/data/Phonophobia/script.lua:240; Phonophobia Android Port/data/Phonophobia/script.lua:242; blubalscript(5resist).lua:175; blubalscript(5resist).lua:178; blubalscript(5resist).lua:200; blubalscript(5resist).lua:203; blubalscript(5resist).lua:407; blubalscript(5resist).lua:413; blubalscript(5resist).lua:419; blubalscript(5resist).lua:427; blubalscript(5resist).lua:433; blubalscript(5resist).lua:461 |
| curStep | 56 | distinta | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:78; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:91; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:98; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:103; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:57; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:62; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:67; Phonophobia Android Port/data/Phonophobia/script.lua:140; Phonophobia Android Port/data/Phonophobia/script.lua:144; Phonophobia Android Port/data/Phonophobia/script.lua:151; Phonophobia Android Port/scripts/floating.lua:3; blubalscript(5resist).lua:280; blubalscript(5resist).lua:440; blubalscript(5resist).lua:448; blubalscript(5resist).lua:451; blubalscript(5resist).lua:454; blubalscript(5resist).lua:472; blubalscript(5resist).lua:474; blubalscript(5resist).lua:477; blubalscript(5resist).lua:479; blubalscript(5resist).lua:484; blubalscript(5resist).lua:493; blubalscript(5resist).lua:548; blubalscript(5resist).lua:551; blubalscript(5resist).lua:554; blubalscript(5resist).lua:557; blubalscript(5resist).lua:560; blubalscript(5resist).lua:563; blubalscript(5resist).lua:568; blubalscript(5resist).lua:579; blubalscript(5resist).lua:579; blubalscript(5resist).lua:584; blubalscript(5resist).lua:590; blubalscript(5resist).lua:593; blubalscript(5resist).lua:596; blubalscript(5resist).lua:599; blubalscript(5resist).lua:602; blubalscript(5resist).lua:605; blubalscript(5resist).lua:608; blubalscript(5resist).lua:611; blubalscript(5resist).lua:614; blubalscript(5resist).lua:617; blubalscript(5resist).lua:620; blubalscript(5resist).lua:623; blubalscript(5resist).lua:630; blubalscript(5resist).lua:633; blubalscript(5resist).lua:636; blubalscript(5resist).lua:639; blubalscript(5resist).lua:643; blubalscript(5resist).lua:646; blubalscript(5resist).lua:649; blubalscript(5resist).lua:652; blubalscript(5resist).lua:656; blubalscript(5resist).lua:685; blubalscript(5resist).lua:685; blubalscript(5resist).lua:690 |
| dadTweenY | 2 | sin fila | Phonophobia Android Port/data/Phonophobia/script.lua:154; Phonophobia Android Port/scripts/floating.lua:6 |
| defaultOpponentStrumX0 | 1 | sin fila | blubalscript(5resist).lua:286 |
| defaultOpponentStrumX1 | 1 | sin fila | blubalscript(5resist).lua:287 |
| defaultOpponentStrumX2 | 1 | sin fila | blubalscript(5resist).lua:288 |
| defaultOpponentStrumX3 | 1 | sin fila | blubalscript(5resist).lua:289 |
| defaultPlayerStrumX0 | 2 | sin fila | Phonophobia Android Port/data/Phonophobia/script.lua:91; blubalscript(5resist).lua:282 |
| defaultPlayerStrumX1 | 2 | sin fila | Phonophobia Android Port/data/Phonophobia/script.lua:92; blubalscript(5resist).lua:283 |
| defaultPlayerStrumX2 | 2 | sin fila | Phonophobia Android Port/data/Phonophobia/script.lua:93; blubalscript(5resist).lua:284 |
| defaultPlayerStrumX3 | 2 | sin fila | Phonophobia Android Port/data/Phonophobia/script.lua:94; blubalscript(5resist).lua:285 |
| difficulty | 28 | distinta | blubalscript(5resist).lua:55; blubalscript(5resist).lua:91; blubalscript(5resist).lua:140; blubalscript(5resist).lua:141; blubalscript(5resist).lua:321; blubalscript(5resist).lua:326; blubalscript(5resist).lua:330; blubalscript(5resist).lua:334; blubalscript(5resist).lua:338; blubalscript(5resist).lua:344; blubalscript(5resist).lua:352; blubalscript(5resist).lua:358; blubalscript(5resist).lua:364; blubalscript(5resist).lua:371; blubalscript(5resist).lua:375; blubalscript(5resist).lua:448; blubalscript(5resist).lua:451; blubalscript(5resist).lua:454; blubalscript(5resist).lua:484; blubalscript(5resist).lua:658; blubalscript(5resist).lua:664; blubalscript(5resist).lua:669; blubalscript(5resist).lua:674; blubalscript(5resist).lua:679; blubalscript(5resist).lua:685; blubalscript(5resist).lua:690; blubalscript(5resist).lua:739; blubalscript(5resist).lua:740 |
| downscroll | 6 | distinta | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:8; blubalscript(5resist).lua:56; blubalscript(5resist).lua:62; blubalscript(5resist).lua:77; blubalscript(5resist).lua:101; blubalscript(5resist).lua:123 |
| flashingLights | 1 | distinta | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Camera Flash.lua:2 |
| inGameOver | 1 | distinta | blubalscript(5resist).lua:299 |
| isStoryMode | 1 | distinta | blubalscript(5resist).lua:7 |
| mustHitSection | 4 | distinta | blubalscript(5resist).lua:208; blubalscript(5resist).lua:310; blubalscript(5resist).lua:313; blubalscript(5resist).lua:579 |
| screenHeight | 13 | distinta | Phonophobia Android Port/data/Phonophobia/script.lua:95; Phonophobia Android Port/data/Phonophobia/script.lua:96; Phonophobia Android Port/data/Phonophobia/script.lua:97; Phonophobia Android Port/data/Phonophobia/script.lua:98; Phonophobia Android Port/data/Phonophobia/script.lua:104; Phonophobia Android Port/data/Phonophobia/script.lua:105; Phonophobia Android Port/data/Phonophobia/script.lua:106; Phonophobia Android Port/data/Phonophobia/script.lua:107; Phonophobia Android Port/scripts/Heath_Display.lua:4; blubalscript(5resist).lua:92; blubalscript(5resist).lua:94; blubalscript(5resist).lua:154; blubalscript(5resist).lua:164 |
| screenWidth | 14 | distinta | Phonophobia Android Port/data/Phonophobia/script.lua:91; Phonophobia Android Port/data/Phonophobia/script.lua:92; Phonophobia Android Port/data/Phonophobia/script.lua:93; Phonophobia Android Port/data/Phonophobia/script.lua:94; Phonophobia Android Port/data/Phonophobia/script.lua:100; Phonophobia Android Port/data/Phonophobia/script.lua:101; Phonophobia Android Port/data/Phonophobia/script.lua:102; Phonophobia Android Port/data/Phonophobia/script.lua:103; Phonophobia Android Port/scripts/Heath_Display.lua:4; VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:5; blubalscript(5resist).lua:92; blubalscript(5resist).lua:94; blubalscript(5resist).lua:154; blubalscript(5resist).lua:164 |
| stepCrochet | 1 | distinta | Phonophobia Android Port/data/Phonophobia/script.lua:255 |

## Objects created by scripts

| tag/expression | occurrences | sites |
|---|---|---|
| <dynamic: 'splash'.. direction> | 1 | blubalscript(5resist).lua:210 |
| Lost | 2 | blubalscript(5resist).lua:92; blubalscript(5resist).lua:94 |
| ballOver | 1 | blubalscript(5resist).lua:569 |
| behind | 2 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:36; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:16 |
| bgshit | 1 | Phonophobia Android Port/stages/White.lua:2 |
| control | 2 | blubalscript(5resist).lua:78; blubalscript(5resist).lua:80 |
| curt | 2 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:31; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:12 |
| curtpast | 1 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:11 |
| dancer | 2 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:52; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:31 |
| fakeScore | 2 | blubalscript(5resist).lua:102; blubalscript(5resist).lua:104 |
| fgshit | 1 | Phonophobia Android Port/stages/White.lua:6 |
| flash | 1 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:6 |
| floor | 2 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:23; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:6 |
| floorpast | 1 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:8 |
| healthText | 1 | Phonophobia Android Port/scripts/Heath_Display.lua:4 |
| mic | 2 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:27; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:9 |
| mid | 2 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:46; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:25 |
| people | 2 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:41; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:20 |
| resist | 4 | blubalscript(5resist).lua:57; blubalscript(5resist).lua:59; blubalscript(5resist).lua:63; blubalscript(5resist).lua:65 |
| wall | 2 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:19; (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:3 |
| wallpast | 1 | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:5 |
| warning1 | 1 | blubalscript(5resist).lua:154 |
| warning2 | 1 | blubalscript(5resist).lua:164 |

## Triggered events

| event/expression | occurrences | arguments and sites |
|---|---|---|
| Camera Follow Pos | 1 | 625, 600 @ blubalscript(5resist).lua:44 |
| Change Character | 9 | '2', 'bfYOUgf' @ blubalscript(5resist).lua:45; '0', 'bfYOUGHOST' @ blubalscript(5resist).lua:571; '1', 'bf@NOTYOUGHOST' @ blubalscript(5resist).lua:574; '0', 'bfYOU' @ blubalscript(5resist).lua:703; '1', 'bf@NOTYOUGHOST' @ blubalscript(5resist).lua:704; '0', 'bfYOUGHOST' @ blubalscript(5resist).lua:708; '1', 'bf@NOTYOU' @ blubalscript(5resist).lua:709; '0', 'bf' @ blubalscript(5resist).lua:718; '1', 'bf@NOTYOUGHOST' @ blubalscript(5resist).lua:719 |
| Change Scroll Speed | 3 | '1.2', '0' @ blubalscript(5resist).lua:449; '1.1', '0' @ blubalscript(5resist).lua:452; '1', '0' @ blubalscript(5resist).lua:455 |
| Screen Shake | 3 | '0.1, 0.01', '0.1, 0.01' @ Phonophobia Android Port/data/Phonophobia/script.lua:44; '0.1, 0.02', '0.1, 0.03' @ Phonophobia Android Port/data/Phonophobia/script.lua:217; '0.1, 0.01', '0.1, 0.01' @ Phonophobia Android Port/scripts/shake.lua:2 |

## Dynamic routes and embedded-code entry points

| script | line | API | expression |
|---|---|---|---|
| Phonophobia Android Port/data/Phonophobia/script.lua | 51 | getPropertyFromGroup | strumLineNotes[ i ].x |
| Phonophobia Android Port/data/Phonophobia/script.lua | 53 | getPropertyFromGroup | strumLineNotes[ i ].y |
| Phonophobia Android Port/data/Phonophobia/script.lua | 84 | setPropertyFromGroup | strumLineNotes[ i ].x |
| Phonophobia Android Port/data/Phonophobia/script.lua | 85 | setPropertyFromGroup | strumLineNotes[ i ].y |
| VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua | 5 | noteTweenX | strumLineNotes[ i+4 ].x |

## All call sites and argument expressions

| function | source | kind and arguments |
|---|---|---|
| addAnimationByPrefix | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:37 | engine/external; 'behind', 'idle', 'Eyes', 24, true |
| addAnimationByPrefix | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:42 | engine/external; 'people', 'idle', 'people stage', 24, true |
| addAnimationByPrefix | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:47 | engine/external; 'mid', 'idle', 'people front', 24, true |
| addAnimationByPrefix | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:53 | engine/external; 'dancer', 'idle', 'Dancers', 24, true |
| addAnimationByPrefix | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:17 | engine/external; 'behind', 'idle', 'Eyes', 24, true |
| addAnimationByPrefix | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:21 | engine/external; 'people', 'idle', 'people stage', 24, true |
| addAnimationByPrefix | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:26 | engine/external; 'mid', 'idle', 'people front', 24, true |
| addAnimationByPrefix | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:32 | engine/external; 'dancer', 'idle', 'Dancers', 24, true |
| addAnimationByPrefix | blubalscript(5resist).lua:211 | engine/external; 'splash' .. direction, 'toThe' .. direction, 'noteSplashes 000', 24, false |
| addCharacterToList | blubalscript(5resist).lua:30 | engine/external; 'bf@NOTYOU', 'dad' |
| addCharacterToList | blubalscript(5resist).lua:31 | engine/external; 'bf@NOTYOUghost', 'dad' |
| addCharacterToList | blubalscript(5resist).lua:32 | engine/external; 'bfYOUgf', 'gf' |
| addCharacterToList | blubalscript(5resist).lua:33 | engine/external; 'bfYOUghost', 'boyfriend' |
| addCharacterToList | blubalscript(5resist).lua:34 | engine/external; 'bfYOUghost-scared', 'boyfriend' |
| addCharacterToList | blubalscript(5resist).lua:35 | engine/external; 'bfYOU-scared', 'boyfriend' |
| addLuaScript | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Stage Changer.lua:3 | engine/external; 'stages/'..value1 |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:8 | engine/external; 'flash', true |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:14 | engine/external; 'wallpast', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:15 | engine/external; 'floorpast', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:16 | engine/external; 'curtpast', true |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:58 | engine/external; 'curt', true |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:59 | engine/external; 'behind', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:60 | engine/external; 'wall', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:61 | engine/external; 'people', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:62 | engine/external; 'floor', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:63 | engine/external; 'mic', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:64 | engine/external; 'dancer', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:65 | engine/external; 'mid', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:37 | engine/external; 'curt', true |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:38 | engine/external; 'behind', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:39 | engine/external; 'wall', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:40 | engine/external; 'people', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:41 | engine/external; 'floor', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:42 | engine/external; 'mic', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:43 | engine/external; 'dancer', false |
| addLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:44 | engine/external; 'mid', false |
| addLuaSprite | Phonophobia Android Port/stages/White.lua:4 | engine/external; 'bgshit', false |
| addLuaSprite | Phonophobia Android Port/stages/White.lua:8 | engine/external; 'fgshit', false |
| addLuaSprite | blubalscript(5resist).lua:213 | engine/external; 'splash' .. direction, true |
| addLuaSprite | blubalscript(5resist).lua:570 | engine/external; 'ballOver', true |
| addLuaText | Phonophobia Android Port/scripts/Heath_Display.lua:5 | engine/external; 'healthText' |
| addLuaText | blubalscript(5resist).lua:72 | engine/external; "resist" |
| addLuaText | blubalscript(5resist).lua:85 | engine/external; "control" |
| addLuaText | blubalscript(5resist).lua:109 | engine/external; "fakeScore" |
| addLuaText | blubalscript(5resist).lua:158 | engine/external; "warning1" |
| addLuaText | blubalscript(5resist).lua:168 | engine/external; "warning2" |
| addLuaText | blubalscript(5resist).lua:666 | engine/external; "Lost" |
| cameraFlash | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Camera Flash.lua:4 | engine/external; camOther, v1, v2 |
| cameraFlash | blubalscript(5resist).lua:575 | engine/external; 'game', '0xFFFFFF', 0.5, true |
| cameraFlash | blubalscript(5resist).lua:701 | engine/external; 'game', '0xFFFFFF', 0.5, true |
| cameraFlash | blubalscript(5resist).lua:722 | engine/external; 'game', '0xFFFFFF', 0.5, true |
| characterPlayAnim | blubalscript(5resist).lua:462 | engine/external; 'boyfriend', 'hurt' |
| characterPlayAnim | blubalscript(5resist).lua:631 | engine/external; 'boyfriend', 'singRIGHT', true |
| characterPlayAnim | blubalscript(5resist).lua:634 | engine/external; 'boyfriend', 'singUP', true |
| characterPlayAnim | blubalscript(5resist).lua:637 | engine/external; 'boyfriend', 'pre-attack', true |
| characterPlayAnim | blubalscript(5resist).lua:640 | engine/external; 'boyfriend', 'attack', true |
| characterPlayAnim | blubalscript(5resist).lua:644 | engine/external; 'boyfriend', 'singRIGHTmiss', true |
| characterPlayAnim | blubalscript(5resist).lua:647 | engine/external; 'boyfriend', 'singUPmiss', true |
| characterPlayAnim | blubalscript(5resist).lua:650 | engine/external; 'boyfriend', 'singLEFTmiss', true |
| characterPlayAnim | blubalscript(5resist).lua:653 | engine/external; 'boyfriend', 'singDOWNmiss', true |
| characterPlayAnim | blubalscript(5resist).lua:686 | engine/external; 'dad', 'singRIGHT', true |
| characterPlayAnim | blubalscript(5resist).lua:691 | engine/external; 'dad', 'singRIGHT', true |
| characterPlayAnim | blubalscript(5resist).lua:726 | engine/external; 'boyfriend', 'hey', true |
| characterPlayAnim | blubalscript(5resist).lua:733 | engine/external; 'boyfriend', 'hurt', true |
| close | Phonophobia Android Port/stages/White.lua:10 | engine/external; true |
| close | blubalscript(5resist).lua:22 | engine/external;  |
| close | blubalscript(5resist).lua:301 | engine/external; true |
| doTweenAlpha | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:15 | engine/external; 'flTw', 'flash', 0, v1, 'linear' |
| doTweenAlpha | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Goodbye Hud.lua:3 | engine/external; 'hudalpha', 'camHUD', tonumber(value1), tonumber(value2), 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:236 | engine/external; 'comeOn1', 'warning1', 1, 1.3, 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:239 | engine/external; 'goOff1', 'warning1', 0, 1.8, 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:243 | engine/external; 'comeOn2', 'warning2', 1, 1.6, 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:246 | engine/external; 'goOff2', 'warning2', 0, 2.3, 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:409 | engine/external; 'nahWeGooTween', 'iconP1', 1, (crochet/5000), 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:415 | engine/external; 'youFadingTween', 'iconP1', 0.75, (crochet/5000), 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:421 | engine/external; 'ohShitTween', 'iconP1', 0.43, (crochet/5000), 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:464 | engine/external; 'itsHere', 'control', 1, 0.5, 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:721 | engine/external; 'youWon', 'dad', 0, 0.9, 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:724 | engine/external; 'noNeedForThis', 'resist', 0, 0.9, 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:725 | engine/external; 'controlNoMo', 'control', 0, 0.9, 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:731 | engine/external; 'noNeedForThis', 'resist', 0, 0.9, 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:732 | engine/external; 'controlNoMo', 'control', 0, 0.9, 'linear' |
| doTweenAlpha | blubalscript(5resist).lua:734 | engine/external; 'boyfriendlostTween', 'boyfriend', 0, 0.5, 'linear' |
| doTweenAngle | Phonophobia Android Port/data/Phonophobia/script.lua:255 | engine/external; 'turn', 'camHUD', 1, stepCrochet*0.002, 'quadinOut' |
| doTweenColor | blubalscript(5resist).lua:324 | engine/external; 'noPerfect:(', 'resist', 'ffffff', 0.1, 'linear' |
| doTweenColor | blubalscript(5resist).lua:355 | engine/external; 'noPerfect:(', 'resist', 'ffffff', 0.2, 'linear' |
| doTweenX | Phonophobia Android Port/data/Phonophobia/script.lua:256 | engine/external; 'tuin', 'camHUD', -1*8, crochet*0.001, 'quadinOut' |
| doTweenY | Phonophobia Android Port/data/Phonophobia/script.lua:154 | engine/external; dadTweenY, 'dad', 290-130*math.sin((currentBeat*0.25)*math.pi), 0.001 |
| doTweenY | Phonophobia Android Port/scripts/floating.lua:6 | engine/external; dadTweenY, 'dad', 100-150*math.sin((currentBeat*0.25)*math.pi), 0.001 |
| doTweenY | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:9 | engine/external; "healthLabelY", "healthLabel", 650, 0.5, "sineInOut" |
| doTweenY | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:10 | engine/external; "healthValueY", "healthValue", 650, 0.5, "sineInOut" |
| doTweenY | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:11 | engine/external; "healthLabelShadowY", "healthLabelShadow", 650+5, 0.5, "sineInOut" |
| doTweenY | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:12 | engine/external; "healthValueShadowY", "healthValueShadow", 650+5, 0.5, "sineInOut" |
| doTweenY | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:14 | engine/external; "healthLabelY", "healthLabel", 30, 0.5, "sineInOut" |
| doTweenY | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:15 | engine/external; "healthValueY", "healthValue", 30, 0.5, "sineInOut" |
| doTweenY | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:16 | engine/external; "healthLabelShadowY", "healthLabelShadow", 30+5, 0.5, "sineInOut" |
| doTweenY | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:17 | engine/external; "healthValueShadowY", "healthValueShadow", 30+5, 0.5, "sineInOut" |
| doTweenY | blubalscript(5resist).lua:112 | engine/external; 'botplytxtDownABit', 'botplayTxt', 160, 0.6, 'quartInOut' |
| doTweenZoom | Phonophobia Android Port/data/Phonophobia/script.lua:37 | engine/external; 'BEGIN', 'camGame', '0.7', 3, 'quadOut' |
| doTweenZoom | Phonophobia Android Port/data/Phonophobia/script.lua:39 | engine/external; 'BEGIN2', 'camHUD', '1', 7, 'quadOut' |
| doTweenZoom | Phonophobia Android Port/data/Phonophobia/script.lua:113 | engine/external; 'BEGIN', 'camGame', '0.7', 0.1, 'quadOut' |
| doTweenZoom | Phonophobia Android Port/data/Phonophobia/script.lua:114 | engine/external; 'BEGIN2', 'camHUD', '1', 0.3, 'quadOut' |
| endin | blubalscript(5resist).lua:659 | helper; 'good' |
| endin | blubalscript(5resist).lua:665 | helper; 'bad' |
| endin | blubalscript(5resist).lua:680 | helper; 'bad' |
| ending | blubalscript(5resist).lua:675 | engine/external; 'good' |
| getColorFromHex | blubalscript(5resist).lua:392 | engine/external; '36eaf7' |
| getColorFromHex | blubalscript(5resist).lua:396 | engine/external; '90ee90' |
| getColorFromHex | blubalscript(5resist).lua:400 | engine/external; 'fffecb' |
| getColorFromHex | blubalscript(5resist).lua:403 | engine/external; 'ffffff' |
| getProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/deathmatch/script.lua:2 | engine/external; 'health' |
| getProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/deathmatch/script.lua:3 | engine/external; 'health' |
| getProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/the-deathmatch/script.lua:2 | engine/external; 'health' |
| getProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/the-deathmatch/script.lua:3 | engine/external; 'health' |
| getProperty | Phonophobia Android Port/data/Phonophobia/script.lua:264 | engine/external; 'health' |
| getProperty | Phonophobia Android Port/data/Phonophobia/script.lua:267 | engine/external; 'health' |
| getProperty | Phonophobia Android Port/scripts/Heath_Display.lua:4 | engine/external; "health" |
| getProperty | Phonophobia Android Port/scripts/Heath_Display.lua:10 | engine/external; "health" |
| getProperty | Phonophobia Android Port/scripts/health_drain.lua:2 | engine/external; 'health' |
| getProperty | blubalscript(5resist).lua:10 | engine/external; 'boyfriend.curCharacter' |
| getProperty | blubalscript(5resist).lua:20 | engine/external; 'boyfriend.curCharacter' |
| getProperty | blubalscript(5resist).lua:176 | engine/external; 'health' |
| getProperty | blubalscript(5resist).lua:179 | engine/external; 'health' |
| getProperty | blubalscript(5resist).lua:199 | engine/external; 'health' |
| getProperty | blubalscript(5resist).lua:200 | engine/external; 'health' |
| getProperty | blubalscript(5resist).lua:203 | engine/external; 'health' |
| getProperty | blubalscript(5resist).lua:311 | engine/external; 'iconP1.scale.x' |
| getProperty | blubalscript(5resist).lua:312 | engine/external; 'iconP1.scale.y' |
| getProperty | blubalscript(5resist).lua:314 | engine/external; 'iconP1.scale.x' |
| getProperty | blubalscript(5resist).lua:315 | engine/external; 'iconP1.scale.y' |
| getProperty | blubalscript(5resist).lua:319 | engine/external; 'songMisses' |
| getProperty | blubalscript(5resist).lua:381 | engine/external; 'songScore' |
| getProperty | blubalscript(5resist).lua:382 | engine/external; 'ratingFC' |
| getProperty | blubalscript(5resist).lua:407 | engine/external; 'health' |
| getProperty | blubalscript(5resist).lua:413 | engine/external; 'health' |
| getProperty | blubalscript(5resist).lua:413 | engine/external; 'health' |
| getProperty | blubalscript(5resist).lua:419 | engine/external; 'health' |
| getProperty | blubalscript(5resist).lua:627 | engine/external; 'songMisses' |
| getProperty | blubalscript(5resist).lua:658 | engine/external; 'songMisses' |
| getProperty | blubalscript(5resist).lua:664 | engine/external; 'songMisses' |
| getProperty | blubalscript(5resist).lua:674 | engine/external; 'songMisses' |
| getProperty | blubalscript(5resist).lua:679 | engine/external; 'songMisses' |
| getProperty | blubalscript(5resist).lua:685 | engine/external; 'songMisses' |
| getProperty | blubalscript(5resist).lua:690 | engine/external; 'songMisses' |
| getPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:24 | engine/external; 'openfl.Lib', 'application.window.x' |
| getPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:25 | engine/external; 'openfl.Lib', 'application.window.y' |
| getPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:26 | engine/external; 'openfl.Lib', 'application.window.x' |
| getPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:27 | engine/external; 'openfl.Lib', 'application.window.y' |
| getPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:65 | engine/external; 'Conductor', 'songPosition' |
| getPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:76 | engine/external; 'ClientPrefs', 'windowMove' |
| getPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:145 | engine/external; 'ClientPrefs', 'windowMove' |
| getPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:167 | engine/external; 'openfl.Lib', 'application.window.x' |
| getPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:171 | engine/external; 'openfl.Lib', 'application.window.x' |
| getPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:209 | engine/external; 'openfl.Lib', 'application.window.x' |
| getPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:210 | engine/external; 'openfl.Lib', 'application.window.y' |
| getPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:220 | engine/external; 'ClientPrefs', 'windowMove' |
| getPropertyFromClass | blubalscript(5resist).lua:114 | engine/external; 'ClientPrefs', 'noteSplashes' |
| getPropertyFromClass | blubalscript(5resist).lua:495 | engine/external; 'backend.ClientPrefs', 'data.middleScroll' |
| getPropertyFromClass | blubalscript(5resist).lua:510 | engine/external; 'backend.ClientPrefs', 'data.middleScroll' |
| getPropertyFromGroup | Phonophobia Android Port/data/Phonophobia/script.lua:51 | engine/external; 'strumLineNotes', i, 'x' |
| getPropertyFromGroup | Phonophobia Android Port/data/Phonophobia/script.lua:53 | engine/external; 'strumLineNotes', i, 'y' |
| getSongPosition | Phonophobia Android Port/data/Phonophobia/script.lua:152 | engine/external;  |
| getSongPosition | Phonophobia Android Port/scripts/floating.lua:4 | engine/external;  |
| keyJustPressed | blubalscript(5resist).lua:281 | engine/external; "space" |
| loadScript | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Stage Changer.lua:4 | engine/external; value1, true |
| makeAnimatedLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:36 | engine/external; 'behind', 'Corruption/TheWorldKids', -420, -230 |
| makeAnimatedLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:41 | engine/external; 'people', 'Corruption/stagepeople', -500, 170 |
| makeAnimatedLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:46 | engine/external; 'mid', 'Corruption/frontpeople', -1000, 500 |
| makeAnimatedLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:52 | engine/external; 'dancer', 'Corruption/stagepeople', -600, 45 |
| makeAnimatedLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:16 | engine/external; 'behind', 'Corruption/TheWorldKids', -420, -230 |
| makeAnimatedLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:20 | engine/external; 'people', 'Corruption/stagepeople', -500, 170 |
| makeAnimatedLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:25 | engine/external; 'mid', 'Corruption/frontpeople', -1000, 500 |
| makeAnimatedLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:31 | engine/external; 'dancer', 'Corruption/stagepeople', -600, 45 |
| makeAnimatedLuaSprite | blubalscript(5resist).lua:210 | engine/external; 'splash'.. direction, 'notesplashes/'.. splahes[direction + 1], splaXnY[direction + 1].x, splaXnY[direction + 1].y |
| makeGraphic | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:7 | engine/external; 'flash', 1280, 720, 'ffffff' |
| makeLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:6 | engine/external; 'flash', '', 0, 0 |
| makeLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:5 | engine/external; 'wallpast', 'Corruption/past/stagebackpast', -900, -600 |
| makeLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:8 | engine/external; 'floorpast', 'Corruption/past/stagefrontpast', -900, 689 |
| makeLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:11 | engine/external; 'curtpast', 'Corruption/past/stagecurtainspast', -900, -600 |
| makeLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:19 | engine/external; 'wall', 'Corruption/stagewall', -1100, -600 |
| makeLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:23 | engine/external; 'floor', 'Corruption/stage', -1100, 689 |
| makeLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:27 | engine/external; 'mic', 'Corruption/mics', 100, 630 |
| makeLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:31 | engine/external; 'curt', 'Corruption/curtains', -1400, -600 |
| makeLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:3 | engine/external; 'wall', 'Corruption/stagewall', -1100, -600 |
| makeLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:6 | engine/external; 'floor', 'Corruption/stage', -1100, 689 |
| makeLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:9 | engine/external; 'mic', 'Corruption/mics', 100, 630 |
| makeLuaSprite | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:12 | engine/external; 'curt', 'Corruption/curtains', -1400, -600 |
| makeLuaSprite | Phonophobia Android Port/stages/White.lua:2 | engine/external; 'bgshit', 'White/FutileBG', -1350, -750 |
| makeLuaSprite | Phonophobia Android Port/stages/White.lua:6 | engine/external; 'fgshit', 'White/ThanosGround', 720, 550 |
| makeLuaSprite | blubalscript(5resist).lua:569 | engine/external; 'ballOver', 'balls_overlay', -15, 200 |
| makeLuaText | Phonophobia Android Port/scripts/Heath_Display.lua:4 | engine/external; 'healthText', 'Health: ' .. math.floor(getProperty("health") * 50), 300, screenWidth / 2 - 300 / 2, screenHeight / 2 - 300 / 1.5 |
| makeLuaText | blubalscript(5resist).lua:57 | engine/external; "resist", 'Resistance: 0', 200, 940, 77 |
| makeLuaText | blubalscript(5resist).lua:59 | engine/external; "resist", 'Resistance: 0', 200, 940, 639 |
| makeLuaText | blubalscript(5resist).lua:63 | engine/external; "resist", 'Resistance? : 0', 200, 940, 77 |
| makeLuaText | blubalscript(5resist).lua:65 | engine/external; "resist", 'Resistance? : 0', 200, 940, 639 |
| makeLuaText | blubalscript(5resist).lua:78 | engine/external; "control", 'Control: 0', 200, 155, 77 |
| makeLuaText | blubalscript(5resist).lua:80 | engine/external; "control", 'Control: 0', 200, 155, 639 |
| makeLuaText | blubalscript(5resist).lua:92 | engine/external; "Lost", 'LOSER', 1000, screenWidth / 2 - 500, screenHeight / 2 - 50 |
| makeLuaText | blubalscript(5resist).lua:94 | engine/external; "Lost", 'LOSER', 1000, screenWidth / 2 - 100, screenHeight / 2 |
| makeLuaText | blubalscript(5resist).lua:102 | engine/external; "fakeScore", 'Score: 0', 300, 650, 36 |
| makeLuaText | blubalscript(5resist).lua:104 | engine/external; "fakeScore", 'Score: 0', 300, 650, 670 |
| makeLuaText | blubalscript(5resist).lua:154 | engine/external; 'warning1', "" .. choseText1, 500, screenWidth / 2 - 250, screenHeight / 2 - 50 |
| makeLuaText | blubalscript(5resist).lua:164 | engine/external; 'warning2', "" .. choseText2, 500, screenWidth / 2 - 250, screenHeight / 2 |
| math.cos | Phonophobia Android Port/data/Phonophobia/script.lua:95 | Lua builtin; (currentBeat) + 0 |
| math.cos | Phonophobia Android Port/data/Phonophobia/script.lua:96 | Lua builtin; (currentBeat) + 1 |
| math.cos | Phonophobia Android Port/data/Phonophobia/script.lua:97 | Lua builtin; (currentBeat) + 2 |
| math.cos | Phonophobia Android Port/data/Phonophobia/script.lua:98 | Lua builtin; (currentBeat) + 3 |
| math.cos | Phonophobia Android Port/data/Phonophobia/script.lua:104 | Lua builtin; (songPos/500) + (4) * 2 |
| math.cos | Phonophobia Android Port/data/Phonophobia/script.lua:105 | Lua builtin; (songPos/500) + (5) * 2 |
| math.cos | Phonophobia Android Port/data/Phonophobia/script.lua:106 | Lua builtin; (songPos/500) + (6) * 2 |
| math.cos | Phonophobia Android Port/data/Phonophobia/script.lua:107 | Lua builtin; (songPos/500) + (7) * 2 |
| math.floor | Phonophobia Android Port/scripts/Heath_Display.lua:4 | Lua builtin; getProperty("health") * 50 |
| math.floor | Phonophobia Android Port/scripts/Heath_Display.lua:10 | Lua builtin; getProperty("health") * 50 |
| math.random | Phonophobia Android Port/data/Phonophobia/script.lua:211 | Lua builtin; -5, 5 |
| math.random | Phonophobia Android Port/data/Phonophobia/script.lua:212 | Lua builtin; -5, 5 |
| math.random | blubalscript(5resist).lua:486 | Lua builtin; 1, 9 |
| math.random | blubalscript(5resist).lua:487 | Lua builtin; 1, 9 |
| math.random | blubalscript(5resist).lua:488 | Lua builtin; 1, 9 |
| math.sin | Phonophobia Android Port/data/Phonophobia/script.lua:84 | Lua builtin; (currentBeat + i*0.25) * math.pi |
| math.sin | Phonophobia Android Port/data/Phonophobia/script.lua:85 | Lua builtin; (currentBeat + i*0.25) * math.pi |
| math.sin | Phonophobia Android Port/data/Phonophobia/script.lua:91 | Lua builtin; (currentBeat) + 0 |
| math.sin | Phonophobia Android Port/data/Phonophobia/script.lua:92 | Lua builtin; (currentBeat) + 1 |
| math.sin | Phonophobia Android Port/data/Phonophobia/script.lua:93 | Lua builtin; (currentBeat) + 2 |
| math.sin | Phonophobia Android Port/data/Phonophobia/script.lua:94 | Lua builtin; (currentBeat) + 3 |
| math.sin | Phonophobia Android Port/data/Phonophobia/script.lua:100 | Lua builtin; (songPos/500) + (4) * 2 |
| math.sin | Phonophobia Android Port/data/Phonophobia/script.lua:101 | Lua builtin; (songPos/500) + (5) * 2 |
| math.sin | Phonophobia Android Port/data/Phonophobia/script.lua:102 | Lua builtin; (songPos/500) + (6) * 2 |
| math.sin | Phonophobia Android Port/data/Phonophobia/script.lua:103 | Lua builtin; (songPos/500) + (7) * 2 |
| math.sin | Phonophobia Android Port/data/Phonophobia/script.lua:154 | Lua builtin; (currentBeat*0.25)*math.pi |
| math.sin | Phonophobia Android Port/scripts/floating.lua:6 | Lua builtin; (currentBeat*0.25)*math.pi |
| noteTweenAlpha | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:3 | engine/external; "Note2", 2, 0, 1, ".cubeInOut" |
| noteTweenAlpha | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:4 | engine/external; "Note0", 0, 0, 1, ".cubeInOut" |
| noteTweenAlpha | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:5 | engine/external; "Note1", 1, 0, 1, ".cubeInOut" |
| noteTweenAlpha | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/Opponentarrowshide.lua:6 | engine/external; "Note3", 3, 0, 1, ".cubeInOut" |
| noteTweenAlpha | blubalscript(5resist).lua:499 | engine/external; "Mdo5", 0, 0.5, 0.4, "quartInOut" |
| noteTweenAlpha | blubalscript(5resist).lua:502 | engine/external; "Mdo6", 1, 0.5, 0.4, "quartInOut" |
| noteTweenAlpha | blubalscript(5resist).lua:505 | engine/external; "Mdo7", 2, 0.5, 0.4, "quartInOut" |
| noteTweenAlpha | blubalscript(5resist).lua:508 | engine/external; "Mdo8", 3, 0.5, 0.4, "quartInOut" |
| noteTweenAlpha | blubalscript(5resist).lua:515 | engine/external; "o5", 0, 0.5, 0.4, "quartInOut" |
| noteTweenAlpha | blubalscript(5resist).lua:519 | engine/external; "o6", 1, 0.5, 0.4, "quartInOut" |
| noteTweenAlpha | blubalscript(5resist).lua:523 | engine/external; "o7", 2, 0.5, 0.4, "quartInOut" |
| noteTweenAlpha | blubalscript(5resist).lua:527 | engine/external; "o8", 3, 0.5, 0.4, "quartInOut" |
| noteTweenAlpha | blubalscript(5resist).lua:531 | engine/external; "Mo5", 4, 1, 16, "quartInOut" |
| noteTweenAlpha | blubalscript(5resist).lua:535 | engine/external; "Mo6", 5, 1, 16, "quartInOut" |
| noteTweenAlpha | blubalscript(5resist).lua:539 | engine/external; "Mo7", 6, 1, 16, "quartInOut" |
| noteTweenAlpha | blubalscript(5resist).lua:543 | engine/external; "Mo8", 7, 1, 16, "quartInOut" |
| noteTweenAngle | blubalscript(5resist).lua:498 | engine/external; "Mdr5", 0, 360, 16, "quartInOut" |
| noteTweenAngle | blubalscript(5resist).lua:501 | engine/external; "Mdr6", 1, 360, 16, "quartInOut" |
| noteTweenAngle | blubalscript(5resist).lua:504 | engine/external; "Mdr7", 2, -360, 16, "quartInOut" |
| noteTweenAngle | blubalscript(5resist).lua:507 | engine/external; "Mdr8", 3, -360, 16, "quartInOut" |
| noteTweenAngle | blubalscript(5resist).lua:514 | engine/external; "r5", 0, 360, 16, "quartInOut" |
| noteTweenAngle | blubalscript(5resist).lua:518 | engine/external; "r6", 1, 360, 16, "quartInOut" |
| noteTweenAngle | blubalscript(5resist).lua:522 | engine/external; "r7", 2, 360, 16, "quartInOut" |
| noteTweenAngle | blubalscript(5resist).lua:526 | engine/external; "r8", 3, 360, 16, "quartInOut" |
| noteTweenAngle | blubalscript(5resist).lua:530 | engine/external; "Mr5", 4, 360, 16, "quartInOut" |
| noteTweenAngle | blubalscript(5resist).lua:534 | engine/external; "Mr6", 5, 360, 16, "quartInOut" |
| noteTweenAngle | blubalscript(5resist).lua:538 | engine/external; "Mr7", 6, 360, 16, "quartInOut" |
| noteTweenAngle | blubalscript(5resist).lua:542 | engine/external; "Mr8", 7, 360, 16, "quartInOut" |
| noteTweenX | Phonophobia Android Port/data/Phonophobia/script.lua:91 | engine/external; defaultPlayerStrumX0, 4, ((screenWidth / 2) - (157 / 2)) + (math.sin((currentBeat) + 0) * 300), 0.001 |
| noteTweenX | Phonophobia Android Port/data/Phonophobia/script.lua:92 | engine/external; defaultPlayerStrumX1, 5, ((screenWidth / 2) - (157 / 2)) + (math.sin((currentBeat) + 1) * 300), 0.001 |
| noteTweenX | Phonophobia Android Port/data/Phonophobia/script.lua:93 | engine/external; defaultPlayerStrumX2, 6, ((screenWidth / 2) - (157 / 2)) + (math.sin((currentBeat) + 2) * 300), 0.001 |
| noteTweenX | Phonophobia Android Port/data/Phonophobia/script.lua:94 | engine/external; defaultPlayerStrumX3, 7, ((screenWidth / 2) - (157 / 2)) + (math.sin((currentBeat) + 3) * 300), 0.001 |
| noteTweenX | Phonophobia Android Port/data/Phonophobia/script.lua:100 | engine/external; 'fake1', 0, ((screenWidth / 2) - (157 / 2)) + (math.sin((songPos/500) + (4) * 2) * 300), 0.0000001 |
| noteTweenX | Phonophobia Android Port/data/Phonophobia/script.lua:101 | engine/external; 'fake2', 1, ((screenWidth / 2) - (157 / 2)) + (math.sin((songPos/500) + (5) * 2) * 300), 0.0000001 |
| noteTweenX | Phonophobia Android Port/data/Phonophobia/script.lua:102 | engine/external; 'fake3', 2, ((screenWidth / 2) - (157 / 2)) + (math.sin((songPos/500) + (6) * 2) * 300), 0.0000001 |
| noteTweenX | Phonophobia Android Port/data/Phonophobia/script.lua:103 | engine/external; 'fake4', 3, ((screenWidth / 2) - (157 / 2)) + (math.sin((songPos/500) + (7) * 2) * 300), 0.0000001 |
| noteTweenX | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Midscroll.lua:5 | engine/external; i..'mid', i+4, screenWidth/2+(110*(i-2)), 0.5, 'sineInOut' |
| noteTweenX | blubalscript(5resist).lua:282 | engine/external; "UMx4", 4, defaultPlayerStrumX0, 1, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:283 | engine/external; "UMx5", 5, defaultPlayerStrumX1, 1, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:284 | engine/external; "UMx6", 6, defaultPlayerStrumX2, 1, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:285 | engine/external; "UMx7", 7, defaultPlayerStrumX3, 1, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:286 | engine/external; "UOMx0", 0, defaultOpponentStrumX0, 1, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:287 | engine/external; "UOMx1", 1, defaultOpponentStrumX1, 1, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:288 | engine/external; "UOMx2", 2, defaultOpponentStrumX2, 1, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:289 | engine/external; "UOMx3", 3, defaultOpponentStrumX3, 1, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:497 | engine/external; "Mdx5", 0, 410, 16, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:500 | engine/external; "Mdx6", 1, 522, 16, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:503 | engine/external; "Mdx7", 2, 633, 16, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:506 | engine/external; "Mdx8", 3, 745, 16, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:513 | engine/external; "x5", 0, 410, 16, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:517 | engine/external; "x6", 1, 522, 16, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:521 | engine/external; "x7", 2, 633, 16, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:525 | engine/external; "x8", 3, 745, 16, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:529 | engine/external; "Mx5", 4, 410, 16, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:533 | engine/external; "Mx6", 5, 522, 16, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:537 | engine/external; "Mx7", 6, 633, 16, "quartInOut" |
| noteTweenX | blubalscript(5resist).lua:541 | engine/external; "Mx8", 7, 745, 16, "quartInOut" |
| noteTweenY | Phonophobia Android Port/data/Phonophobia/script.lua:95 | engine/external; 'defaultPlayerStrumY0', 4, ((screenHeight / 2) - (157 / 2)) + (math.cos((currentBeat) + 0) * 300), 0.001 |
| noteTweenY | Phonophobia Android Port/data/Phonophobia/script.lua:96 | engine/external; 'defaultPlayerStrumY1', 5, ((screenHeight / 2) - (157 / 2)) + (math.cos((currentBeat) + 1) * 300), 0.001 |
| noteTweenY | Phonophobia Android Port/data/Phonophobia/script.lua:97 | engine/external; 'defaultPlayerStrumY2', 6, ((screenHeight / 2) - (157 / 2)) + (math.cos((currentBeat) + 2) * 300), 0.001 |
| noteTweenY | Phonophobia Android Port/data/Phonophobia/script.lua:98 | engine/external; 'defaultPlayerStrumY3', 7, ((screenHeight / 2) - (157 / 2)) + (math.cos((currentBeat) + 3) * 300), 0.001 |
| noteTweenY | Phonophobia Android Port/data/Phonophobia/script.lua:104 | engine/external; 'defaultFPlayerStrumY0', 0, ((screenHeight / 2) - (157 / 2)) + (math.cos((songPos/500) + (4) * 2) * 300), 0.0000001 |
| noteTweenY | Phonophobia Android Port/data/Phonophobia/script.lua:105 | engine/external; 'defaultFPlayerStrumY1', 1, ((screenHeight / 2) - (157 / 2)) + (math.cos((songPos/500) + (5) * 2) * 300), 0.0000001 |
| noteTweenY | Phonophobia Android Port/data/Phonophobia/script.lua:106 | engine/external; 'defaultFPlayerStrumY2', 2, ((screenHeight / 2) - (157 / 2)) + (math.cos((songPos/500) + (6) * 2) * 300), 0.0000001 |
| noteTweenY | Phonophobia Android Port/data/Phonophobia/script.lua:107 | engine/external; 'defaultFPlayerStrumY3', 3, ((screenHeight / 2) - (157 / 2)) + (math.cos((songPos/500) + (7) * 2) * 300), 0.0000001 |
| objectPlayAnimation | blubalscript(5resist).lua:212 | engine/external; 'splash'.. direction, 'toThe'.. direction |
| playSound | blubalscript(5resist).lua:300 | engine/external; 'HA_HA' |
| playSound | blubalscript(5resist).lua:687 | engine/external; 'HA_HA' |
| playSound | blubalscript(5resist).lua:692 | engine/external; 'HA_HA' |
| playSound | blubalscript(5resist).lua:730 | engine/external; 'deathGrunt' |
| precacheImage | blubalscript(5resist).lua:36 | engine/external; 'balls_overlay' |
| precacheImage | blubalscript(5resist).lua:39 | engine/external; 'notesplashes/noteSplashesRIGHT' |
| precacheImage | blubalscript(5resist).lua:40 | engine/external; 'notesplashes/noteSplashesLEFT' |
| precacheImage | blubalscript(5resist).lua:41 | engine/external; 'notesplashes/noteSplashesDOWN' |
| precacheImage | blubalscript(5resist).lua:42 | engine/external; 'notesplashes/noteSplashesUP' |
| precacheSound | blubalscript(5resist).lua:43 | engine/external; 'HA_HA' |
| removeLuaScript | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Stage Changer.lua:5 | engine/external; 'stages/'..value2 |
| removeLuaSprite | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Stage Changer.lua:6 | engine/external; 'stages/'..value2 |
| removeLuaSprite | blubalscript(5resist).lua:222 | engine/external; 'splash0', false |
| removeLuaSprite | blubalscript(5resist).lua:225 | engine/external; 'splash1', false |
| removeLuaSprite | blubalscript(5resist).lua:228 | engine/external; 'splash2', false |
| removeLuaSprite | blubalscript(5resist).lua:231 | engine/external; 'splash3', false |
| removeLuaSprite | blubalscript(5resist).lua:585 | engine/external; 'ballOver', true |
| removeLuaText | blubalscript(5resist).lua:660 | engine/external; 'warning1', true |
| removeLuaText | blubalscript(5resist).lua:661 | engine/external; 'warning2', true |
| removeLuaText | blubalscript(5resist).lua:667 | engine/external; 'warning1', true |
| removeLuaText | blubalscript(5resist).lua:668 | engine/external; 'warning2', true |
| removeLuaText | blubalscript(5resist).lua:676 | engine/external; 'warning1', true |
| removeLuaText | blubalscript(5resist).lua:677 | engine/external; 'warning2', true |
| removeLuaText | blubalscript(5resist).lua:681 | engine/external; 'warning1', true |
| removeLuaText | blubalscript(5resist).lua:682 | engine/external; 'warning2', true |
| resizeWindow | Phonophobia Android Port/data/Phonophobia/script.lua:205 | engine/external; windowXscale, windowYscale |
| runTimer | blubalscript(5resist).lua:11 | engine/external; 'startDialogueBadEnd', 0.8 |
| runTimer | blubalscript(5resist).lua:13 | engine/external; 'startDialogueEnd', 0.8 |
| runTimer | blubalscript(5resist).lua:188 | engine/external; 'hited', 0.1, 1 |
| runTimer | blubalscript(5resist).lua:214 | engine/external; 'splashGone' .. direction, 0.2, 1 |
| runTimer | blubalscript(5resist).lua:473 | engine/external; 'come1', 1, 1 |
| runTimer | blubalscript(5resist).lua:475 | engine/external; 'go1', 1, 1 |
| runTimer | blubalscript(5resist).lua:478 | engine/external; 'come2', 1, 1 |
| runTimer | blubalscript(5resist).lua:480 | engine/external; 'go2', 1, 1 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:6 | engine/external; 'wallpast', 3, 3 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:9 | engine/external; 'floorpast', 3, 3 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:12 | engine/external; 'curtpast', 3, 3 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:20 | engine/external; 'wall', 2.5, 2.5 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:24 | engine/external; 'floor', 2.5, 2.5 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:28 | engine/external; 'mic', 1, 1 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:33 | engine/external; 'curt', 2.75, 2.75 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:38 | engine/external; 'behind', 4, 4 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:43 | engine/external; 'people', 4.25, 4.25 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:49 | engine/external; 'mid', 4.25, 4.25 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:55 | engine/external; 'dancer', 4.25, 4.25 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:4 | engine/external; 'wall', 2.5, 2.5 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:7 | engine/external; 'floor', 2.5, 2.5 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:10 | engine/external; 'mic', 1, 1 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:14 | engine/external; 'curt', 2.75, 2.75 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:18 | engine/external; 'behind', 4, 4 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:22 | engine/external; 'people', 4.25, 4.25 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:28 | engine/external; 'mid', 4.25, 4.25 |
| scaleObject | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:34 | engine/external; 'dancer', 4.25, 4.25 |
| scaleObject | Phonophobia Android Port/stages/White.lua:3 | engine/external; 'bgshit', 2.0, 2.0 |
| scaleObject | Phonophobia Android Port/stages/White.lua:7 | engine/external; 'fgshit', 0.55, 0.55 |
| setLuaSpriteScrollFactor | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:9 | engine/external; 'flash', 0, 0 |
| setLuaSpriteScrollFactor | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:32 | engine/external; 'curt', 0.9, 0.9 |
| setLuaSpriteScrollFactor | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:48 | engine/external; 'mid', 0.9, 0.9 |
| setLuaSpriteScrollFactor | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:54 | engine/external; 'dancer', 0.9, 0.9 |
| setLuaSpriteScrollFactor | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:13 | engine/external; 'curt', 0.9, 0.9 |
| setLuaSpriteScrollFactor | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:27 | engine/external; 'mid', 0.9, 0.9 |
| setLuaSpriteScrollFactor | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:33 | engine/external; 'dancer', 0.9, 0.9 |
| setObjectCamera | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:14 | engine/external; "flash", 'hud' |
| setObjectCamera | blubalscript(5resist).lua:69 | engine/external; "resist", 'hud' |
| setObjectCamera | blubalscript(5resist).lua:82 | engine/external; "control", 'hud' |
| setObjectCamera | blubalscript(5resist).lua:96 | engine/external; "Lost", 'hud' |
| setObjectCamera | blubalscript(5resist).lua:106 | engine/external; "fakeScore", 'hud' |
| setObjectCamera | blubalscript(5resist).lua:155 | engine/external; "warning1", 'other' |
| setObjectCamera | blubalscript(5resist).lua:165 | engine/external; "warning2", 'other' |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:10 | engine/external; 'flash.scale.x', 2 |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:11 | engine/external; 'flash.scale.y', 2 |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:12 | engine/external; 'flash.alpha', 0 |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/custom_events/Flash Camera.lua:13 | engine/external; 'flash.alpha', 1 |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/deathmatch/script.lua:4 | engine/external; 'health', health- 0.02 |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/data/the-deathmatch/script.lua:4 | engine/external; 'health', health- 0.02 |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:21 | engine/external; 'wall.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:25 | engine/external; 'floor.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:29 | engine/external; 'mic.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:34 | engine/external; 'curt.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:39 | engine/external; 'behind.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:44 | engine/external; 'people.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:50 | engine/external; 'mid.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:56 | engine/external; 'dancer.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:70 | engine/external; 'timeBar.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:71 | engine/external; 'timeTxt.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:72 | engine/external; 'timeBarBG.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:79 | engine/external; 'icon-bf.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:80 | engine/external; 'icon-dad.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:81 | engine/external; 'healthBar.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:82 | engine/external; 'wallpast.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:83 | engine/external; 'floorpast.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:84 | engine/external; 'curtpast.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:85 | engine/external; 'wall.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:86 | engine/external; 'floor.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:87 | engine/external; 'curt.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:88 | engine/external; 'gf.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:92 | engine/external; 'defaultCamZoom', 0.5 |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:93 | engine/external; 'behind.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:94 | engine/external; 'people.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:95 | engine/external; 'mid.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:99 | engine/external; 'people.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:100 | engine/external; 'dancer.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:104 | engine/external; 'people.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death-remix.lua:105 | engine/external; 'dancer.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:23 | engine/external; 'people.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:29 | engine/external; 'mid.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:35 | engine/external; 'dancer.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:49 | engine/external; 'timeBar.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:50 | engine/external; 'timeTxt.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:51 | engine/external; 'timeBarBG.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:58 | engine/external; 'people.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:59 | engine/external; 'mid.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:63 | engine/external; 'people.visible', false |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:64 | engine/external; 'dancer.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:68 | engine/external; 'people.visible', true |
| setProperty | (BenSKR) Deathmatch Proyect mods folder port Optimizado/stages/death.lua:69 | engine/external; 'dancer.visible', false |
| setProperty | Phonophobia Android Port/data/Phonophobia/script.lua:36 | engine/external; 'camGame.zoom', 2 |
| setProperty | Phonophobia Android Port/data/Phonophobia/script.lua:38 | engine/external; 'camHUD.zoom', 3 |
| setProperty | Phonophobia Android Port/data/Phonophobia/script.lua:244 | engine/external; 'camHUD.angle', 1*-5 |
| setProperty | Phonophobia Android Port/data/Phonophobia/script.lua:253 | engine/external; 'camHUD.angle', 1*5 |
| setProperty | Phonophobia Android Port/data/Phonophobia/script.lua:264 | engine/external; 'health', getProperty('health') + 0.0025 |
| setProperty | Phonophobia Android Port/data/Phonophobia/script.lua:267 | engine/external; 'health', getProperty('health') + 0.0025 |
| setProperty | Phonophobia Android Port/scripts/health_drain.lua:4 | engine/external; 'health', health - 0.01 |
| setProperty | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/reaction.lua:2 | engine/external; 'skipCountdown', true |
| setProperty | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/reaction.lua:7 | engine/external; 'inCutscene', false |
| setProperty | blubalscript(5resist).lua:8 | engine/external; 'inCutscene', true |
| setProperty | blubalscript(5resist).lua:46 | engine/external; 'gf.alpha', tonumber(0) |
| setProperty | blubalscript(5resist).lua:47 | engine/external; 'dad.alpha', tonumber(0) |
| setProperty | blubalscript(5resist).lua:49 | engine/external; 'iconP2.alpha', tonumber(0) |
| setProperty | blubalscript(5resist).lua:50 | engine/external; 'health', 2 |
| setProperty | blubalscript(5resist).lua:51 | engine/external; 'scoreTxt.alpha', tonumber(0) |
| setProperty | blubalscript(5resist).lua:88 | engine/external; 'control.alpha', tonumber(0) |
| setProperty | blubalscript(5resist).lua:159 | engine/external; 'warning1.alpha', tonumber(0) |
| setProperty | blubalscript(5resist).lua:169 | engine/external; 'warning2.alpha', tonumber(0) |
| setProperty | blubalscript(5resist).lua:176 | engine/external; 'health', getProperty('health')+ 0.0112 |
| setProperty | blubalscript(5resist).lua:179 | engine/external; 'health', getProperty('health')+ 0.0689 |
| setProperty | blubalscript(5resist).lua:186 | engine/external; 'fakeScore.scale.x', 1.1 |
| setProperty | blubalscript(5resist).lua:187 | engine/external; 'fakeScore.scale.y', 1.1 |
| setProperty | blubalscript(5resist).lua:201 | engine/external; 'health', health- 0.0312 |
| setProperty | blubalscript(5resist).lua:204 | engine/external; 'health', health- 0.0824 |
| setProperty | blubalscript(5resist).lua:258 | engine/external; 'fakeScore.scale.x', 1 |
| setProperty | blubalscript(5resist).lua:259 | engine/external; 'fakeScore.scale.y', 1 |
| setProperty | blubalscript(5resist).lua:311 | engine/external; 'resist.scale.x', getProperty('iconP1.scale.x') |
| setProperty | blubalscript(5resist).lua:312 | engine/external; 'resist.scale.y', getProperty('iconP1.scale.y') |
| setProperty | blubalscript(5resist).lua:314 | engine/external; 'control.scale.x', getProperty('iconP1.scale.x') |
| setProperty | blubalscript(5resist).lua:315 | engine/external; 'control.scale.y', getProperty('iconP1.scale.y') |
| setProperty | blubalscript(5resist).lua:392 | engine/external; 'fakeScore.color', getColorFromHex('36eaf7') |
| setProperty | blubalscript(5resist).lua:396 | engine/external; 'fakeScore.color', getColorFromHex('90ee90') |
| setProperty | blubalscript(5resist).lua:400 | engine/external; 'fakeScore.color', getColorFromHex('fffecb') |
| setProperty | blubalscript(5resist).lua:403 | engine/external; 'fakeScore.color', getColorFromHex('ffffff') |
| setProperty | blubalscript(5resist).lua:428 | engine/external; 'iconP1.alpha', 1 |
| setProperty | blubalscript(5resist).lua:463 | engine/external; 'health', 1 |
| setProperty | blubalscript(5resist).lua:572 | engine/external; 'gf.alpha', tonumber(1) |
| setProperty | blubalscript(5resist).lua:576 | engine/external; 'boyfriend.alpha', tonumber(0.6) |
| setProperty | blubalscript(5resist).lua:577 | engine/external; 'dad.alpha', tonumber(0.6) |
| setProperty | blubalscript(5resist).lua:580 | engine/external; 'health', 0.15 |
| setProperty | blubalscript(5resist).lua:586 | engine/external; 'health', 1 |
| setProperty | blubalscript(5resist).lua:587 | engine/external; 'gf.alpha', tonumber(0) |
| setProperty | blubalscript(5resist).lua:705 | engine/external; 'boyfriend.alpha', tonumber(1) |
| setProperty | blubalscript(5resist).lua:706 | engine/external; 'dad.alpha', tonumber(0.5) |
| setProperty | blubalscript(5resist).lua:710 | engine/external; 'boyfriend.alpha', tonumber(0.5) |
| setProperty | blubalscript(5resist).lua:711 | engine/external; 'dad.alpha', tonumber(1) |
| setProperty | blubalscript(5resist).lua:720 | engine/external; 'boyfriend.alpha', tonumber(1) |
| setProperty | blubalscript(5resist).lua:727 | engine/external; 'health', 2 |
| setProperty | blubalscript(5resist).lua:729 | engine/external; 'health', 0.01 |
| setPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:168 | engine/external; 'openfl.Lib', 'application.window.x', windowX - 4 |
| setPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:172 | engine/external; 'openfl.Lib', 'application.window.x', windowX + 4 |
| setPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:211 | engine/external; 'openfl.Lib', 'application.window.x', windowX + math.random(-5,5) |
| setPropertyFromClass | Phonophobia Android Port/data/Phonophobia/script.lua:212 | engine/external; 'openfl.Lib', 'application.window.y', windowY + math.random(-5,5) |
| setPropertyFromClass | blubalscript(5resist).lua:342 | engine/external; "openfl.Lib", "application.window.title", "HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHA" |
| setPropertyFromClass | blubalscript(5resist).lua:362 | engine/external; "openfl.Lib", "application.window.title", "HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHA" |
| setPropertyFromGroup | Phonophobia Android Port/data/Phonophobia/script.lua:84 | engine/external; 'strumLineNotes', i, 'x', defaultNotePos[i + 1][1] + modchartX * math.sin((currentBeat + i*0.25) * math.pi) |
| setPropertyFromGroup | Phonophobia Android Port/data/Phonophobia/script.lua:85 | engine/external; 'strumLineNotes', i, 'y', defaultNotePos[i + 1][2] + modchartY * math.sin((currentBeat + i*0.25) * math.pi) |
| setSplashSets | blubalscript(5resist).lua:116 | helper;  |
| setTextAlignment | blubalscript(5resist).lua:74 | engine/external; 'resist', 'center' |
| setTextAlignment | blubalscript(5resist).lua:87 | engine/external; 'control', 'center' |
| setTextAlignment | blubalscript(5resist).lua:100 | engine/external; 'Lost', 'center' |
| setTextAlignment | blubalscript(5resist).lua:111 | engine/external; 'fakeScore', 'center' |
| setTextAlignment | blubalscript(5resist).lua:161 | engine/external; 'warning1', 'center' |
| setTextAlignment | blubalscript(5resist).lua:171 | engine/external; 'warning2', 'center' |
| setTextColor | blubalscript(5resist).lua:70 | engine/external; 'resist', '0x36eaf7' |
| setTextColor | blubalscript(5resist).lua:83 | engine/external; 'control', '0xff0000' |
| setTextColor | blubalscript(5resist).lua:97 | engine/external; 'Lost', '0xff0000' |
| setTextColor | blubalscript(5resist).lua:107 | engine/external; 'fakeScore', '0xffffff' |
| setTextColor | blubalscript(5resist).lua:156 | engine/external; 'warning1', '0xff0000' |
| setTextColor | blubalscript(5resist).lua:166 | engine/external; 'warning2', '0xffffff' |
| setTextColor | blubalscript(5resist).lua:265 | engine/external; 'resist', '0xffffff' |
| setTextColor | blubalscript(5resist).lua:341 | engine/external; 'resist', 'ff0000' |
| setTextColor | blubalscript(5resist).lua:361 | engine/external; 'resist', 'ff0000' |
| setTextColor | blubalscript(5resist).lua:367 | engine/external; 'resist', 'ff0000' |
| setTextColor | blubalscript(5resist).lua:434 | engine/external; 'resist', 'ff0000' |
| setTextColor | blubalscript(5resist).lua:436 | engine/external; 'resist', '0xffffff' |
| setTextColor | blubalscript(5resist).lua:441 | engine/external; 'resist', 'ff0000' |
| setTextColor | blubalscript(5resist).lua:443 | engine/external; 'resist', '0xffffff' |
| setTextFont | blubalscript(5resist).lua:73 | engine/external; 'resist', "vcr.ttf" |
| setTextFont | blubalscript(5resist).lua:86 | engine/external; 'control', "vcr.ttf" |
| setTextFont | blubalscript(5resist).lua:99 | engine/external; 'Lost', "vcr.ttf" |
| setTextFont | blubalscript(5resist).lua:110 | engine/external; 'fakeScore', "vcr.ttf" |
| setTextFont | blubalscript(5resist).lua:160 | engine/external; 'warning1', "vcr.ttf" |
| setTextFont | blubalscript(5resist).lua:170 | engine/external; 'warning2', "vcr.ttf" |
| setTextSize | Phonophobia Android Port/scripts/Heath_Display.lua:6 | engine/external; 'healthText', 30 |
| setTextSize | blubalscript(5resist).lua:71 | engine/external; 'resist', 20 |
| setTextSize | blubalscript(5resist).lua:84 | engine/external; 'control', 20 |
| setTextSize | blubalscript(5resist).lua:98 | engine/external; 'Lost', 100 |
| setTextSize | blubalscript(5resist).lua:108 | engine/external; 'fakeScore', 19 |
| setTextSize | blubalscript(5resist).lua:157 | engine/external; 'warning1', 20 |
| setTextSize | blubalscript(5resist).lua:167 | engine/external; 'warning2', 20 |
| setTextString | Phonophobia Android Port/scripts/Heath_Display.lua:10 | engine/external; 'healthText', 'Health: ' .. math.floor(getProperty("health") * 50) |
| setTextString | blubalscript(5resist).lua:372 | engine/external; 'resist', 'Resistance: ' .. oopsH |
| setTextString | blubalscript(5resist).lua:373 | engine/external; 'control', 'Control: ' .. hoopsH |
| setTextString | blubalscript(5resist).lua:376 | engine/external; 'resist', 'Resistance: ' .. oopsN |
| setTextString | blubalscript(5resist).lua:377 | engine/external; 'control', 'Control: ' .. hoopsN |
| setTextString | blubalscript(5resist).lua:385 | engine/external; 'fakeScore', 'Score: ' .. scorin .. ' - ?' |
| setTextString | blubalscript(5resist).lua:387 | engine/external; 'fakeScore', 'Score: ' .. scorin .. ' - ' .. ratin |
| setTextString | blubalscript(5resist).lua:489 | engine/external; 'resist', '*%&Y^@@$: '.. ran1 .. ran2 .. ran3 |
| setTextString | blubalscript(5resist).lua:490 | engine/external; 'control', 'Control: HAHA' |
| setTextString | blubalscript(5resist).lua:670 | engine/external; 'Lost', "YOU DIDN'T EVEN TRY" |
| startDialogue | blubalscript(5resist).lua:249 | engine/external; 'dialogueEnd', '' |
| startDialogue | blubalscript(5resist).lua:252 | engine/external; 'dialogueBadEnd', '' |
| startVideo | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/data/funky-fonks/reaction.lua:6 | engine/external; 'abrahaham_funkyfonks' |
| swapTurn | blubalscript(5resist).lua:549 | helper; false |
| swapTurn | blubalscript(5resist).lua:552 | helper; true |
| swapTurn | blubalscript(5resist).lua:555 | helper; false |
| swapTurn | blubalscript(5resist).lua:558 | helper; true |
| swapTurn | blubalscript(5resist).lua:561 | helper; false |
| swapTurn | blubalscript(5resist).lua:564 | helper; true |
| swapTurn | blubalscript(5resist).lua:588 | helper; false |
| swapTurn | blubalscript(5resist).lua:591 | helper; true |
| swapTurn | blubalscript(5resist).lua:594 | helper; false |
| swapTurn | blubalscript(5resist).lua:597 | helper; true |
| swapTurn | blubalscript(5resist).lua:600 | helper; false |
| swapTurn | blubalscript(5resist).lua:603 | helper; true |
| swapTurn | blubalscript(5resist).lua:606 | helper; false |
| swapTurn | blubalscript(5resist).lua:609 | helper; true |
| swapTurn | blubalscript(5resist).lua:612 | helper; false |
| swapTurn | blubalscript(5resist).lua:615 | helper; true |
| swapTurn | blubalscript(5resist).lua:618 | helper; false |
| swapTurn | blubalscript(5resist).lua:621 | helper; true |
| swapTurn | blubalscript(5resist).lua:624 | helper; false |
| table.insert | Phonophobia Android Port/data/Phonophobia/script.lua:55 | Lua builtin; defaultNotePos, {x, y} |
| tonumber | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Goodbye Hud.lua:3 | Lua builtin; value1 |
| tonumber | VS Abrahaham - Funky Fonks 1.0.4 Optimizado/custom_events/Goodbye Hud.lua:3 | Lua builtin; value2 |
| tonumber | blubalscript(5resist).lua:46 | Lua builtin; 0 |
| tonumber | blubalscript(5resist).lua:47 | Lua builtin; 0 |
| tonumber | blubalscript(5resist).lua:49 | Lua builtin; 0 |
| tonumber | blubalscript(5resist).lua:51 | Lua builtin; 0 |
| tonumber | blubalscript(5resist).lua:88 | Lua builtin; 0 |
| tonumber | blubalscript(5resist).lua:159 | Lua builtin; 0 |
| tonumber | blubalscript(5resist).lua:169 | Lua builtin; 0 |
| tonumber | blubalscript(5resist).lua:572 | Lua builtin; 1 |
| tonumber | blubalscript(5resist).lua:576 | Lua builtin; 0.6 |
| tonumber | blubalscript(5resist).lua:577 | Lua builtin; 0.6 |
| tonumber | blubalscript(5resist).lua:587 | Lua builtin; 0 |
| tonumber | blubalscript(5resist).lua:705 | Lua builtin; 1 |
| tonumber | blubalscript(5resist).lua:706 | Lua builtin; 0.5 |
| tonumber | blubalscript(5resist).lua:710 | Lua builtin; 0.5 |
| tonumber | blubalscript(5resist).lua:711 | Lua builtin; 1 |
| tonumber | blubalscript(5resist).lua:720 | Lua builtin; 1 |
| triggerEvent | Phonophobia Android Port/data/Phonophobia/script.lua:44 | engine/external; 'Screen Shake', '0.1, 0.01', '0.1, 0.01' |
| triggerEvent | Phonophobia Android Port/data/Phonophobia/script.lua:217 | engine/external; 'Screen Shake', '0.1, 0.02', '0.1, 0.03' |
| triggerEvent | Phonophobia Android Port/scripts/shake.lua:2 | engine/external; 'Screen Shake', '0.1, 0.01', '0.1, 0.01' |
| triggerEvent | blubalscript(5resist).lua:44 | engine/external; 'Camera Follow Pos', 625, 600 |
| triggerEvent | blubalscript(5resist).lua:45 | engine/external; 'Change Character', '2', 'bfYOUgf' |
| triggerEvent | blubalscript(5resist).lua:449 | engine/external; 'Change Scroll Speed', '1.2', '0' |
| triggerEvent | blubalscript(5resist).lua:452 | engine/external; 'Change Scroll Speed', '1.1', '0' |
| triggerEvent | blubalscript(5resist).lua:455 | engine/external; 'Change Scroll Speed', '1', '0' |
| triggerEvent | blubalscript(5resist).lua:571 | engine/external; 'Change Character', '0', 'bfYOUGHOST' |
| triggerEvent | blubalscript(5resist).lua:574 | engine/external; 'Change Character', '1', 'bf@NOTYOUGHOST' |
| triggerEvent | blubalscript(5resist).lua:703 | engine/external; 'Change Character', '0', 'bfYOU' |
| triggerEvent | blubalscript(5resist).lua:704 | engine/external; 'Change Character', '1', 'bf@NOTYOUGHOST' |
| triggerEvent | blubalscript(5resist).lua:708 | engine/external; 'Change Character', '0', 'bfYOUGHOST' |
| triggerEvent | blubalscript(5resist).lua:709 | engine/external; 'Change Character', '1', 'bf@NOTYOU' |
| triggerEvent | blubalscript(5resist).lua:718 | engine/external; 'Change Character', '0', 'bf' |
| triggerEvent | blubalscript(5resist).lua:719 | engine/external; 'Change Character', '1', 'bf@NOTYOUGHOST' |
| victoryCheck | blubalscript(5resist).lua:627 | helper; getProperty('songMisses') |
| windowShake | Phonophobia Android Port/data/Phonophobia/script.lua:221 | helper;  |

## Coverage boundary and family ordering

Unique external call names: 53. Inventory states: ausente=2, distinta=46, implementada=1, sin fila=4.

The corpus contains no HScript source and no runHaxeCode/runHaxeFunction/addHaxeLibrary calls. HScript compatibility cannot be inferred from this corpus.

Proposed family order from observed triggers: (1) PlayState counters and initialized globals, (2) HUD objects and UI groups, (3) property/class/group resolution, (4) notes and receptor groups, (5) text, (6) sprites/cameras/stage ordering, (7) tweens/timers, (8) events/script lifecycle and shader contracts when a shader corpus exists. Frequency tables above provide per-symbol counts; the order also accounts for creation dependencies.

The current corpus cannot certify whole-mod execution for Blueballed or expose unexecuted branches. Missing assets and resources are outside a static call inventory. Dynamic route rows require traced argument values in later differential runs.

## Blueballed line 344

`messUps = getProperty('songMisses')` is assigned at line 319 and compared with 5 at line 344. The comparison operand is messUps. The script also reads difficulty, mustHitSection and other engine globals. These values require initialization contracts, not inferred substitutes.

## Gate before implementation

This report inventories source usage and cross-references earlier audit rows. It does not certify that all used APIs behave equivalently. No Psych reference application was compiled or run for Analysis A; prior callback-body tests are not framebuffer or whole-engine differential runs. Physical Android/Mali behavior remains unverified.

## Additional source findings

- Syntax check: all 18 Lua files compile with loadstring in LÖVE 11.5 / LuaJIT, with zero syntax errors. Script callbacks were not executed by this check.
- `loadScript(value1, true)` occurs in Funky Fonks custom_events/Stage Changer.lua:4. Psych 1.0.4 source/psychlua contains no registration under that name; addLuaScript is a separate API. The contract cannot be inferred by substituting it.
- `resizeWindow(windowXscale, windowYscale)` occurs in Phonophobia data/Phonophobia/script.lua:205. No definition is in that file, and no Psych 1.0.4 psychlua registration has that name. Window API behavior needs a version/fork contract.
- `ClientPrefs.windowMove` occurs at Phonophobia lines 76, 145 and 220. The property is not declared in Psych 1.0.4 backend/ClientPrefs.hx. Treating it as an original Psych field would be unsupported.
- Blueballed calls `ending('good')` at line 675, while its declared helper is named `endin` at line 715. No definition of ending appears in the attached corpus. This is a distinct unresolved call, not an alias established by the scan.
- `close(true)` is outside the previous 223 literal-registration inventory; Light exposes close through funkin/backend/scripts/init.lua:160. It requires its own lifecycle contract and an inventory row.
- `dadTweenY` is read as a tween tag without a local assignment in the Phonophobia files. The call-argument table preserves that expression so anonymous-tag behavior can be checked.
- `camOther` is passed as an identifier, rather than the string 'camOther', in the Funky Fonks flash script. Its actual argument value must be recorded during execution.
- No corpus source calls addMisses, writes notes.texture or writes SONG.arrowSkin in rgbNotes.lua, because Glitch.lua and rgbNotes.lua are not included in the available uploads. These reported failures remain regression requirements from the logs, not evidence of scanned-source coverage.
