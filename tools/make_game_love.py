#!/usr/bin/env python3
"""Build game.love, the zipped game source shared by every platform build.

The archive must contain the whole runtime (Lua sources, lib/, assets/, art/)
so the packaged binaries actually boot. Only VCS/CI/build-only files are left
out. Run it from anywhere:

    python3 tools/make_game_love.py [output.love]
"""

from __future__ import annotations

import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Directories that never belong inside the shipped game.
SKIP_DIRS = {
    ".git",
    ".github",
    ".vscode",
    "android",
    "tools",
    "release",
    "mods",
    "addons",
}

# Files that only exist for development/CI.
SKIP_FILES = {
    ".editorconfig",
    ".gitignore",
    ".luarc.json",
    "actionlint",
    "game.love",
    "Boon.toml",
}

# Archives and other build outputs.
SKIP_SUFFIXES = (".love", ".zip", ".tar.gz", ".apk", ".lnk", ".fla")

REQUIRED_ENTRIES = (
    "main.lua",
    "conf.lua",
    "project.lua",
    "lib/baton.lua",
    "lib/https.lua",
    "art/logo.png",
    "funkin/ui/mods/modcard.lua",
    "funkin/ui/mods/searchbox.lua",
    "funkin/ui/mods/selectionlist.lua",
)


def is_excluded(rel: str) -> bool:
    """`rel` is a POSIX style path relative to the repository root."""
    parts = rel.split("/")
    # These names are root-level build/content directories. Matching every
    # path component would also remove runtime modules such as funkin/ui/mods.
    if parts and parts[0] in SKIP_DIRS:
        return True

    name = parts[-1]
    if name in SKIP_FILES:
        return True
    if name.endswith(SKIP_SUFFIXES):
        return True
    # Documentation ships through LICENSE.md only (see its terms); the rest is
    # development material that has no business inside the game archive.
    if name.endswith(".md") and not name.upper().startswith("LICENSE"):
        return True
    return False


def collect_files() -> list[str]:
    entries: list[str] = []
    for current, dirs, files in os.walk(ROOT):
        rel_dir = os.path.relpath(current, ROOT).replace(os.sep, "/")
        if rel_dir == ".":
            rel_dir = ""
        if not rel_dir:
            dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
        else:
            dirs[:] = sorted(dirs)
        for name in sorted(files):
            rel = f"{rel_dir}/{name}".lstrip("/") if rel_dir else name
            if not is_excluded(rel):
                entries.append(rel)
    return sorted(entries)


def build(output: str) -> int:
    files = collect_files()
    if not files:
        print("No files found to pack.", file=sys.stderr)
        return 1

    tmp = output + ".tmp"
    try:
        with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for rel in files:
                archive.write(os.path.join(ROOT, *rel.split("/")), rel)
        os.replace(tmp, output)
    finally:
        if os.path.exists(tmp):
            os.remove(tmp)

    with zipfile.ZipFile(output) as archive:
        names = set(archive.namelist())
    missing = [entry for entry in REQUIRED_ENTRIES if entry not in names]
    if missing:
        print(f"game.love is incomplete, missing: {', '.join(missing)}", file=sys.stderr)
        return 1

    size = os.path.getsize(output)
    print(f"{output}: {len(names)} files, {size / (1024 * 1024):.1f} MiB")
    return 0


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "game.love")
    sys.exit(build(target))
