# Windows and Linux desktop distributions

One reviewed `game.love` supplies both desktop packages. The packager copies
its bytes without rewriting game sources, artwork or assets. Project title and
version come from the archive's `project.lua`, so packages cannot silently pick
up a newer version from a different checkout.

The Windows x64 ZIP includes the official LÖVE 11.5 runtime files and a fused
`Light-Engine.exe`: the original `love.exe` followed by the exact `game.love`
bytes. Extract the whole ZIP and launch `Light-Engine.exe`. Keep the DLLs beside
it. The official unmodified `love.exe` and `lovec.exe` also remain in the folder;
they are runtime utilities, while `Light-Engine.exe` launches this game.

The Linux x64 tarball includes the extracted official LÖVE 11.5 AppImage runtime,
the exact `game.love`, and `launch.sh`. Extract it and run `./launch.sh`. The
launcher resolves its own directory, chooses its bundled runtime, and passes
`--fused`, the game path, and any supplied arguments separately. Spaces in paths
and arguments are supported. AppImage FUSE mounting is not needed. Linux still
needs its normal desktop graphics/audio libraries and a graphical session.

Both packages include the unchanged `art/logo.png` as `logo.png`. The Linux
`.desktop.in` template uses that artwork; replace `@INSTALL_DIR@` with the
bundle's absolute directory and save it as a `.desktop` file for menu
installation. The Windows executable retains the official LÖVE icon because
this build does not edit PE resources. The running game's window continues to
use its existing Project icon. Runtime licenses are retained, and game/mod
licenses remain inside the unchanged game archive.

## Reproduce the packages

Use Python 3.10 or newer. Download the official runtimes from the LÖVE project:

```sh
curl --fail --location --output love-win64.zip \
  https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.zip
curl --fail --location --output love-linux.AppImage \
  https://github.com/love2d/love/releases/download/11.5/love-11.5-x86_64.AppImage
chmod +x love-linux.AppImage
./love-linux.AppImage --appimage-extract
```

After the reviewed game archive has been built, pass all inputs explicitly:

```sh
python3 tools/make_desktop_release.py \
  --game /absolute/path/game.love \
  --windows-runtime /absolute/path/love-win64.zip \
  --linux-runtime /absolute/path/squashfs-root \
  --output-dir /absolute/path/release
```

Either runtime option may be omitted to build one platform. Optional `--name`
and `--version` override the archive's literal Project values. The default
outputs are `Light-Engine-<version>-win64.zip` and
`Light-Engine-<version>-linux-x64.tar.gz`, each containing one matching top-level
directory. The tool verifies Windows x64 PE and Linux x64 ELF headers and checks
for LÖVE 11.5 runtime files. Only obtain runtimes from the official source; these
structural checks are not signature authentication.

`distribution.json` records platform, title/version, LÖVE version, game size and
SHA-256, runtime fingerprint, and the fused executable's game offset when
applicable. ZIP/tar ordering, timestamps, ownership and modes are normalized;
gzip omits the input filename and creation time. Identical input bytes and
runtime trees reproduce identical package bytes with the same Python/zlib
toolchain. Compression-library changes may alter compressed bytes without
altering their contents.

## Validation and platform limits

```sh
LOVE_WIN64_RUNTIME=/absolute/path/love-win64.zip \
  python3 tests/desktop-packaging.py
```

The tests compare the PE prefix and appended game bounds, verify DLL/artwork
byte preservation, reject a wrong architecture, compare independent builds,
and execute the launcher with paths/arguments containing spaces. They use the
real official Windows runtime for structural validation and a small Linux
launcher fixture for argument checks. Release validation also boots the actual
Linux bundle using the actual game archive.

Windows bundles can be produced and structurally checked from Linux. A Windows
execution result requires running the delivered executable on Windows; PE/ZIP
checks alone do not establish native Windows boot or gameplay. Linux software
rendering/cold-boot tests likewise do not establish every GPU's performance.
