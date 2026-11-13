# Story difficulties and gameplay information

Implement inline in the existing Lua/LÖVE engine. Discover chart difficulties when loading a week and offer only variants playable by every song. Preserve explicit labels and mod difficulty images. Generate missing labels using a configurable difficulty font, with deterministic colors and per-week opt-out. The supplied FNFont TTF is bundled as `assets/fonts/difficulty.ttf`.

Add a saved Gameplay information setting: Simple (score), Informative (score, misses, weighted judgement accuracy), Full (judgement breakdown, hits, misses, combo/peak combo, real-time inputs per second/peak, notes per second, health, playback, timing error and chart-derived turn countdowns). Build merged activity intervals from chart note heads and sustain lengths once, query them by binary search, and account for playback rate. Keep all UI text English and all HUD objects on camHUD.

Verify difficulty discovery for metadata, split charts and multi-difficulty charts; missing names; image priority; color opt-out; score/accuracy including misses; rolling inputs; player/opponent/both/break/end turn states; sustained notes; seek and speed changes. Run available Lua and repository regressions. Update changelog and release 0.2.7 / Android 209 after verification.
