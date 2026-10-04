#!/usr/bin/env python3
"""Package an optional addon separately from the engine runtime."""
from pathlib import Path
import argparse
import zipfile
ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    parser.add_argument('--addon', choices=('screen-overlay', 'wallpaper-overlay'), default='screen-overlay')
    args = parser.parse_args()
    addon = ROOT / 'separate-addons' / args.addon
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for file in sorted(addon.rglob('*')):
            if (file.is_file() and '__pycache__' not in file.parts
                    and file.suffix not in {'.pyc', '.class', '.apk', '.jks', '.log'}):
                archive.write(file, args.addon + '/' + file.relative_to(addon).as_posix())
    with zipfile.ZipFile(args.output) as archive:
        assert archive.testzip() is None
        assert args.addon + '/modules/overlay.lua' in archive.namelist()
    print(f'Separate addon: {args.output} ({args.output.stat().st_size} bytes)')

if __name__ == '__main__': main()
