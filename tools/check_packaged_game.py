#!/usr/bin/env python3
"""Compare a distributed game archive or APK with the checked-out runtime."""
import argparse
import hashlib
from pathlib import Path
import zipfile

from make_game_love import ROOT, collect_files


def verify(package, android=False):
    prefix = 'assets/' if android else ''
    with zipfile.ZipFile(package) as archive:
        expected = collect_files()
        if android:
            # Android's default AAPT asset policy excludes hidden paths and
            # directories beginning with an underscore from the APK.
            expected = [name for name in expected if not any(part.startswith('.') for part in Path(name).parts)
                        and not any(part.startswith('_') for part in Path(name).parts[:-1])
                        and not name.endswith('~')]
        for name in expected:
            source = Path(ROOT, name).read_bytes()
            try:
                shipped = archive.read(prefix + name)
            except KeyError:
                raise ValueError('Package is missing ' + name) from None
            if hashlib.sha256(source).digest() != hashlib.sha256(shipped).digest():
                raise ValueError('Package has different bytes for ' + name)
        junk = [name for name in archive.namelist() if '__pycache__' in name.split('/') or name.endswith(('.pyc', '.idsig'))]
        if junk:
            raise ValueError('Package contains development files: ' + ', '.join(junk))
    print(f'PACKAGED GAME VERIFIED: {len(expected)} runtime files match the source checkout')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', type=Path)
    parser.add_argument('--android', action='store_true')
    args = parser.parse_args()
    verify(args.package, args.android)


if __name__ == '__main__':
    main()
