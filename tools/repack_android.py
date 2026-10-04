#!/usr/bin/env python3
"""Replace assets/game.love in an official Light Engine APK.
This reuses original Java and native libraries. --resizable enables the
existing GameActivity manifest boolean for Android split-screen support.
--direct-assets uses the official assets/main.lua layout instead of a nested
game.love, avoiding the complete private-cache archive copy.
Output is UNSIGNED. Run Android zipalign and apksigner afterwards.
Usage: python3 tools/repack_android.py base.apk game.love unsigned.apk
"""
import argparse
import copy
from pathlib import Path
import shutil
import zipfile
from android_manifest import enable_game_resize
from make_android_assets import game_files, STREAM_MEDIA


def repack(base, game, output, resizable=False, direct_assets=False):
    if output.resolve() in {base.resolve(),game.resolve()}:
        raise ValueError('Output must differ from inputs')
    with zipfile.ZipFile(game) as archive:
        entries=game_files(archive)
    with zipfile.ZipFile(base) as original:
        if not {'assets/game.love','assets/main.lua'} & set(original.namelist()):
            raise ValueError('APK does not embed a Light Engine runtime')
        if not direct_assets and 'assets/game.love' not in original.namelist():
            raise ValueError('Base uses direct assets; pass --direct-assets to replace its runtime')
        with zipfile.ZipFile(output,'w',allowZip64=True) as updated:
            for info in original.infolist():
                # zipfile mutates header offsets while writing; retain the input's
                # metadata so reading the original entry remains valid.
                if direct_assets and info.filename.startswith('assets/') and not info.filename.startswith('assets/dexopt/'):
                    continue
                original_info = info
                info = copy.copy(info)
                upper=info.filename.upper()
                if upper.startswith('META-INF/') and (upper.endswith(('.SF','.RSA','.DSA','.EC')) or upper=='META-INF/MANIFEST.MF'):
                    continue
                # Original alignment and signature blocks are deliberately
                # discarded: the completed APK must be realigned and signed.
                info.extra=b''
                with updated.open(info,'w',force_zip64=info.file_size>=2**31) as dst:
                    if info.filename=='assets/game.love':
                        with game.open('rb') as src: shutil.copyfileobj(src,dst,1024*1024)
                    elif info.filename=='AndroidManifest.xml' and resizable:
                        dst.write(enable_game_resize(original.read(original_info)))
                    else:
                        with original.open(original_info) as src: shutil.copyfileobj(src,dst,1024*1024)
            if direct_assets:
                with zipfile.ZipFile(game) as archive:
                    for entry in entries:
                        info=copy.copy(entry);info.filename='assets/'+entry.filename;info.extra=b''
                        if Path(entry.filename).suffix.lower() in STREAM_MEDIA:
                            info.compress_type=zipfile.ZIP_STORED
                        with archive.open(entry) as source,updated.open(info,'w',force_zip64=entry.file_size>=2**31) as destination:
                            shutil.copyfileobj(source,destination,1024*1024)
    print(f'Unsigned APK: {output} ({output.stat().st_size} bytes)')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('base',type=Path);parser.add_argument('game',type=Path);parser.add_argument('output',type=Path)
    parser.add_argument('--resizable',action='store_true',help='Enable the existing GameActivity OS resize flag')
    parser.add_argument('--direct-assets',action='store_true',help='Use native APK asset loading without duplicating game.love in cache')
    args=parser.parse_args();repack(args.base,args.game,args.output,args.resizable,args.direct_assets)

if __name__=='__main__': main()
