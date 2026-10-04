#!/usr/bin/env python3
"""Package one reviewed game.love with official LÖVE 11.5 desktop runtimes."""
from __future__ import annotations

import argparse
import gzip
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import struct
import tarfile
import tempfile
import zipfile

CHUNK = 1024 * 1024
ZIP_DATE = (1980, 1, 1, 0, 0, 0)
LAUNCHER = b'''#!/bin/sh
set -eu
package_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export APPDIR="$package_dir/runtime"
unset FUSE_PATH
exec "$APPDIR/AppRun" --fused "$package_dir/game.love" "$@"
'''


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        while data := source.read(CHUNK):
            digest.update(data)
    return digest.hexdigest()


def project_value(project: str, key: str) -> str:
    match = re.search(r"^\s*" + re.escape(key) + r"\s*=\s*(['\"])(.*?)\1\s*,?\s*$", project, re.M)
    if not match:
        raise ValueError(f"project.lua must contain a literal {key}, or supply --{key if key == 'version' else 'name'}")
    return match.group(2)


def game_metadata(game: Path, name: str | None, version: str | None):
    with zipfile.ZipFile(game) as archive:
        for required in ("main.lua", "conf.lua", "project.lua", "art/logo.png"):
            archive.getinfo(required)
        project = archive.read("project.lua").decode("utf-8")
        name = name or project_value(project, "title")
        version = version or project_value(project, "version")
        logo = archive.read("art/logo.png")
    if not name or re.search(r"[\x00-\x1f\x7f]", name):
        raise ValueError("name must be nonempty and contain no control characters")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", version):
        raise ValueError("version must contain only filename-safe letters, numbers, dots, underscores and hyphens")
    slug = re.sub(r"[^A-Za-z0-9._-]+", "-", name).strip("-.")
    if not slug:
        raise ValueError("name must include an ASCII letter or number for the executable filename")
    return name, version, slug, logo


def zip_info(name: str, executable: bool = False):
    entry = zipfile.ZipInfo(name, ZIP_DATE)
    entry.create_system = 3
    entry.external_attr = (stat.S_IFREG | (0o755 if executable else 0o644)) << 16
    entry.compress_type = zipfile.ZIP_DEFLATED
    return entry


def manifest(metadata: dict) -> bytes:
    return (json.dumps(metadata, indent=2, sort_keys=True) + "\n").encode()


def desktop_readme(title: str, platform: str, executable: str) -> bytes:
    opening = (f"Run {executable}. LÖVE is bundled; no separate LÖVE installation is required.\n"
               if platform == "windows-x64" else
               "Extract the whole directory, then run ./launch.sh. LÖVE is bundled.\n"
               "Linux still requires its normal system graphics/audio libraries and a desktop session.\n"
               "For an application-menu entry, copy the .desktop.in template, replace @INSTALL_DIR@\n"
               "with this directory's absolute path, and save it as a .desktop file.\n")
    return (f"{title} — {platform}\n\n" + opening +
            "Keep all bundled runtime files beside the launcher/executable.\n"
            "distribution.json records the exact game/runtime inputs and game SHA-256.\n"
            "Game artwork is logo.png. Runtime licenses are included.\n"
            "The Windows executable retains the official LÖVE icon; the game's window uses its own artwork.\n"
            "Game/mod licenses remain inside the unchanged game archive.\n").encode()


def windows_release(game: Path, runtime: Path, output: Path, title: str, version: str,
                    slug: str, logo: bytes, game_hash: str):
    bundle = f"{slug}-{version}-win64"
    executable = slug + ".exe"
    with zipfile.ZipFile(runtime) as original:
        candidates = [p for p in original.namelist() if PurePosixPath(p).name == "love.exe"]
        if len(candidates) != 1:
            raise ValueError("Windows runtime must contain exactly one love.exe")
        prefix = candidates[0][:-len("love.exe")]
        entries = {}
        for info in original.infolist():
            if info.is_dir():
                continue
            if not info.filename.startswith(prefix):
                raise ValueError("Windows runtime has files outside its love.exe directory")
            relative = info.filename[len(prefix):]
            path = PurePosixPath(relative)
            if not relative or path.is_absolute() or ".." in path.parts or "\\" in relative:
                raise ValueError("Windows runtime contains an unsafe member path")
            if stat.S_ISLNK(info.external_attr >> 16):
                raise ValueError("Windows runtime must not contain symlinks")
            if relative in entries:
                raise ValueError("Windows runtime has duplicate entries")
            entries[relative] = info
        for required in ("love.dll", "lua51.dll", "SDL2.dll", "OpenAL32.dll", "license.txt"):
            if required not in entries:
                raise ValueError(f"Windows runtime is missing {required}")
        if "changes.txt" not in entries or not original.read(entries["changes.txt"]).startswith(b"LOVE 11.5 "):
            raise ValueError("Windows runtime must be the official LÖVE 11.5 release")
        exe = original.read(candidates[0])
        if len(exe) < 64 or exe[:2] != b"MZ":
            raise ValueError("love.exe is not a PE executable")
        pe = struct.unpack_from("<I", exe, 0x3C)[0]
        if pe + 26 > len(exe) or exe[pe:pe+4] != b"PE\0\0" or struct.unpack_from("<H", exe, pe+4)[0] != 0x8664:
            raise ValueError("love.exe must be an x64 PE executable")
        if struct.unpack_from("<H", exe, pe+24)[0] != 0x20B:
            raise ValueError("love.exe must use a PE32+ optional header")
        generated = {
            "logo.png": logo,
            "README-desktop.txt": desktop_readme(title, "windows-x64", executable),
            "distribution.json": manifest({"format": 1, "title": title, "version": version,
                "platform": "windows-x64", "loveVersion": "11.5", "runtimeSha256": sha256(runtime),
                "gameSha256": game_hash, "gameBytes": game.stat().st_size,
                "fusedGameOffset": len(exe), "executable": executable}),
        }
        if set(generated) & set(entries):
            raise ValueError("Windows runtime collides with generated package metadata")
        target = output / (bundle + ".zip")
        with tempfile.NamedTemporaryFile(dir=output, prefix=".desktop-win-", delete=False) as pending:
            temporary = Path(pending.name)
        try:
            with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
                for name in sorted(set(entries) | set(generated) | {executable}):
                    with archive.open(zip_info(bundle + "/" + name, name.endswith(".exe")), "w", force_zip64=True) as destination:
                        if name == executable:
                            destination.write(exe)
                            with game.open("rb") as source:
                                shutil.copyfileobj(source, destination, CHUNK)
                        elif name in generated:
                            destination.write(generated[name])
                        else:
                            with original.open(entries[name]) as source:
                                shutil.copyfileobj(source, destination, CHUNK)
            os.replace(temporary, target)
        finally:
            temporary.unlink(missing_ok=True)
    return target


def runtime_members(runtime: Path):
    members = sorted(runtime.rglob("*"), key=lambda p: p.relative_to(runtime).as_posix())
    for path in members:
        if path.is_symlink():
            if not path.resolve().is_relative_to(runtime.resolve()):
                raise ValueError(f"Linux runtime symlink escapes its directory: {path}")
        elif not path.is_dir() and not path.is_file():
            raise ValueError(f"Linux runtime contains a special file: {path}")
    return members


def linux_release(game: Path, runtime: Path, output: Path, title: str, version: str,
                  slug: str, logo: bytes, game_hash: str):
    for required in ("AppRun", "bin/love", "lib/liblove-11.5.so", "license.txt"):
        if not (runtime / required).is_file():
            raise ValueError(f"Extracted Linux runtime is missing {required}")
    if not os.access(runtime / "AppRun", os.X_OK) or not os.access(runtime / "bin/love", os.X_OK):
        raise ValueError("Linux AppRun and bin/love must be executable")
    with (runtime / "bin/love").open("rb") as binary:
        elf = binary.read(64)
    if len(elf) < 64 or elf[:6] != b"\x7fELF\x02\x01" or struct.unpack_from("<H", elf, 18)[0] != 62:
        raise ValueError("Linux bin/love must be an x64 ELF executable")
    members = runtime_members(runtime)
    runtime_digest = hashlib.sha256()
    for path in members:
        runtime_digest.update(path.relative_to(runtime).as_posix().encode() + b"\0")
        runtime_digest.update((os.readlink(path) if path.is_symlink() else sha256(path) if path.is_file() else "directory").encode() + b"\0")
    bundle = f"{slug}-{version}-linux-x64"
    desktop = (f"[Desktop Entry]\nType=Application\nName={title}\n"
               "Exec=\"@INSTALL_DIR@/launch.sh\"\nIcon=@INSTALL_DIR@/logo.png\n"
               "Terminal=false\nCategories=Game;\n").encode()
    generated = {"launch.sh": LAUNCHER, "logo.png": logo, slug + ".desktop.in": desktop,
        "README-desktop.txt": desktop_readme(title, "linux-x64", "launch.sh"),
        "distribution.json": manifest({"format": 1, "title": title, "version": version,
            "platform": "linux-x64", "loveVersion": "11.5", "runtimeTreeSha256": runtime_digest.hexdigest(),
            "gameSha256": game_hash, "gameBytes": game.stat().st_size, "launcher": "launch.sh"})}
    target = output / (bundle + ".tar.gz")
    with tempfile.NamedTemporaryFile(dir=output, prefix=".desktop-linux-", delete=False) as pending:
        temporary = Path(pending.name)
    try:
        with temporary.open("wb") as raw, gzip.GzipFile(fileobj=raw, filename="", mode="wb", mtime=0, compresslevel=6) as compressed, tarfile.open(fileobj=compressed, mode="w|", format=tarfile.PAX_FORMAT) as archive:
            for name in (bundle, bundle + "/runtime"):
                info = tarfile.TarInfo(name); info.type = tarfile.DIRTYPE; info.mode = 0o755; archive.addfile(info)
            for name, data in sorted(generated.items()):
                info = tarfile.TarInfo(bundle + "/" + name); info.mode = 0o755 if name == "launch.sh" else 0o644
                info.size = len(data); archive.addfile(info, io.BytesIO(data))
            info = tarfile.TarInfo(bundle + "/game.love"); info.mode = 0o644; info.size = game.stat().st_size
            with game.open("rb") as source:
                archive.addfile(info, source)
            for path in members:
                info = tarfile.TarInfo(bundle + "/runtime/" + path.relative_to(runtime).as_posix())
                if path.is_symlink():
                    info.type = tarfile.SYMTYPE; info.linkname = os.readlink(path); info.mode = 0o777; archive.addfile(info)
                elif path.is_dir():
                    info.type = tarfile.DIRTYPE; info.mode = 0o755; archive.addfile(info)
                else:
                    info.mode = 0o755 if path.stat().st_mode & 0o111 else 0o644; info.size = path.stat().st_size
                    with path.open("rb") as source:
                        archive.addfile(info, source)
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)
    return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game", type=Path, required=True)
    parser.add_argument("--windows-runtime", type=Path, help="official love-11.5-win64.zip")
    parser.add_argument("--linux-runtime", type=Path, help="official extracted AppImage squashfs-root")
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--name", help="display title; defaults to project.lua in the game archive")
    parser.add_argument("--version", help="defaults to project.lua in the game archive")
    args = parser.parse_args()
    if not args.windows_runtime and not args.linux_runtime:
        parser.error("provide --windows-runtime and/or --linux-runtime")
    try:
        title, version, slug, logo = game_metadata(args.game, args.name, args.version)
        args.output_dir.mkdir(parents=True, exist_ok=True)
        game_hash = sha256(args.game)
        for runtime, builder in ((args.windows_runtime, windows_release), (args.linux_runtime, linux_release)):
            if runtime:
                target = builder(args.game, runtime, args.output_dir, title, version, slug, logo, game_hash)
                print(f"{target}\n  bytes={target.stat().st_size} sha256={sha256(target)}")
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        parser.exit(1, f"Desktop packaging failed: {error}\n")


if __name__ == "__main__":
    main()
