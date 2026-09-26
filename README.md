<h1 align="center">FNF LÖVE</h1>

![](art/funkin_logo.png)

<p align="center">A port of <a href="https://funkin.me">Friday Night Funkin'</a> to the <a href="https://love2d.org">LÖVE</a> game engine.</p>

## Android data

On Android, the game uses the following shared-storage layout:

```text
Android/media/fr.stilic.fnflove/
├── mods/
├── addons/
└── saves/
```

`mods` and `addons` are loaded directly from that folder. Preferences, high scores,
selected mods, add-on state and the rest of the persistent game data are stored in
`saves/funkin.lox`. The directory and its three subdirectories are created
automatically on first launch. Changes to external mods, add-ons and the save file
are detected by a low-overhead metadata watcher and applied while the game is
running, without restarting it. The Android package requests access on first
launch because Android 11 and newer require explicit user approval to write to
shared storage. If access is denied, the game falls back to its private app
storage instead of losing the save.

The **Virtual controls** option under **Options > Gameplay** is enabled by default.
Turning it off immediately hides and disables all on-screen/touch controls while
leaving keyboard and gamepad input available.

## Discord Server

[![Discord Banner](https://invidget.switchblade.xyz/eFFgHz7X8N)](https://discord.gg/eFFgHz7X8N)

## Contributing

Please follow our [contributing guidelines](CONTRIBUTING.md) while contributing to this project.

## Dev Team

- [Stilic (owner)](https://github.com/Stilic)
- [Victor Kaoy](https://github.com/ViKaoy)
- [TehPuertoRicanSpartan](https://github.com/TehPuertoRicanSpartan)
- [Shirobuu](https://github.com/Shirobuuh)
- [Dawn Fowler](https://github.com/fowluhhdevbcfunny)
- [Carrot](https://github.com/n64carrot)

## Former Dev Team members

- [Raltyro](https://github.com/Raltyro) (huge thanks to them for the 3d and modchart code)
- [Ikawa](https://github.com/ikawaluvyu)
