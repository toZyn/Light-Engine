#!/usr/bin/env python3
"""Package an optional addon separately from the engine runtime."""
from pathlib import Path
import argparse
import json
import os
import tempfile
import zipfile
ROOT = Path(__file__).resolve().parents[1]

def build(addon, output):
    addon, output = addon.resolve(), output.resolve()
    if not addon.is_dir():
        raise ValueError('Addon directory does not exist: ' + str(addon))
    if output.is_relative_to(addon):
        raise ValueError('Write the archive outside the addon directory')
    metadata = addon / 'meta.json'
    if not metadata.is_file() or not isinstance(json.loads(metadata.read_text(encoding='utf-8')), dict):
        raise ValueError('Addon must contain a JSON object in meta.json')
    if not any((addon / 'modules').rglob('*.lua')):
        raise ValueError('Addon must contain at least one Lua module under modules/')
    files = [file for file in sorted(addon.rglob('*'))
             if file.is_file() and not {'.git', '__pycache__', '.venv'} & set(file.relative_to(addon).parts)
             and file.name not in {'.DS_Store', 'Thumbs.db'}
             and file.suffix not in {'.pyc', '.class', '.apk', '.jks', '.log', '.zip', '.idsig'}]
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=output.parent, prefix=output.name + '.', suffix='.tmp', delete=False) as handle:
        temporary = Path(handle.name)
    try:
        with zipfile.ZipFile(temporary, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for file in files:
                archive.write(file, addon.name + '/' + file.relative_to(addon).as_posix())
        with zipfile.ZipFile(temporary) as archive:
            if archive.testzip() is not None:
                raise ValueError('Addon archive failed its CRC check')
        os.replace(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)
    print(f'Separate addon: {output} ({output.stat().st_size} bytes)')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    source = parser.add_mutually_exclusive_group()
    source.add_argument('--addon', choices=('screen-overlay', 'wallpaper-overlay'), default='screen-overlay')
    source.add_argument('--source', type=Path, help='Package your own addon directory')
    args = parser.parse_args()
    addon = args.source or ROOT / 'separate-addons' / args.addon
    try:
        build(addon, args.output)
    except (ValueError, OSError) as error:
        parser.error(str(error))

if __name__ == '__main__': main()
