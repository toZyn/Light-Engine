# Custom Button Mod

Demonstrates how to add interactive buttons in a Light Engine mod across both menus and gameplay:

- `data/states/mainmenu.lua` adds a selectable **Bonus Bop** option to `MainMenuState` via `Mod.addMenuButton(...)` and persists its toggle state with `Mod.saveData` / `Mod.loadData`.
- `data/scripts/hud-button.lua` adds a clickable, touch-friendly, and keyboard-bound (`B`) button on the gameplay HUD via `Mod.button(...)`, updates a status label via `Mod.text(...)`, and cleans up all objects in `leave()` via `Mod.remove(...)`.
