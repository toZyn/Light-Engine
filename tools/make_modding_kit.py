#!/usr/bin/env python3
"""Package modding tools, docs, and examples for GitHub Releases and bundles."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]

KIT_FILES = (
    "CHANGELOG.md",
    "LICENSE.md",
    "docs/crear-mods.md",
    "docs/modding-compatibility.md",
    "tools/create_mod.py",
)

SKIP_NAMES = {".DS_Store", "Thumbs.db", "__pycache__"}


def collect_kit_entries(root: Path = ROOT) -> list[tuple[Path, str]]:
    entries: list[tuple[Path, str]] = []
    for rel in KIT_FILES:
        src = root / rel
        if not src.is_file():
            raise FileNotFoundError(f"Missing required modding-kit file: {rel}")
        entries.append((src, rel))

    examples_root = root / "examples"
    if not examples_root.is_dir():
        raise FileNotFoundError("Missing examples/ directory")

    for dirpath, dirnames, filenames in os.walk(examples_root):
        dirnames[:] = sorted(d for d in dirnames if d not in SKIP_NAMES)
        for fname in sorted(filenames):
            if fname in SKIP_NAMES or fname.endswith(".pyc"):
                continue
            src = Path(dirpath) / fname
            rel = src.relative_to(root).as_posix()
            entries.append((src, rel))

    return sorted(entries, key=lambda item: item[1])


def build_archive(output: Path, prefix: str = "Light-Engine-Modding-Kit", root: Path = ROOT) -> None:
    entries = collect_kit_entries(root)
    output.parent.mkdir(parents=True, exist_ok=True)
    tmp = output.with_suffix(output.suffix + ".tmp")
    try:
        with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for src, rel in entries:
                arcname = f"{prefix}/{rel}" if prefix else rel
                archive.write(src, arcname)
        tmp.replace(output)
    finally:
        tmp.unlink(missing_ok=True)
    print(f"{output}: {len(entries)} files, {output.stat().st_size / 1024:.1f} KiB")


def populate_bundle(bundle_dir: Path, root: Path = ROOT) -> None:
    entries = collect_kit_entries(root)
    bundle_dir.mkdir(parents=True, exist_ok=True)
    for src, rel in entries:
        dest = bundle_dir / Path(*rel.split("/"))
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
    print(f"Populated {bundle_dir} with {len(entries)} modding/docs/example files")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--archive", type=Path, help="Build modding-kit zip archive at this path")
    parser.add_argument("--prefix", default="Light-Engine-Modding-Kit", help="Top-level folder inside --archive")
    parser.add_argument("--populate-bundle", type=Path, help="Copy docs, mod generator, and examples into bundle directory")
    args = parser.parse_args()

    if not args.archive and not args.populate_bundle:
        parser.error("Specify --archive and/or --populate-bundle")

    try:
        if args.archive:
            build_archive(args.archive, prefix=args.prefix, root=args.root)
        if args.populate_bundle:
            populate_bundle(args.populate_bundle, root=args.root)
        return 0
    except OSError as exc:
        print(f"::error::{exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
