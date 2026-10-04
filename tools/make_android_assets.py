#!/usr/bin/env python3
"""Stage the unchanged game as APK assets for LÖVE's native AAsset loader.

This is the official embed/main.lua layout, avoiding the full game.love cache
copy. It changes packaging, not game content or shared desktop packaging.
"""
import argparse
from pathlib import Path, PurePosixPath
import shutil
import stat
import zipfile

STREAM_MEDIA={'.png','.jpg','.jpeg','.ogg','.mp3','.ogv','.mp4','.webm'}

def game_files(archive):
    files=[];names=set()
    for entry in archive.infolist():
        name=entry.filename
        clean=name[:-1] if entry.is_dir() else name
        path=PurePosixPath(clean)
        if (not clean or path.is_absolute() or path.as_posix()!=clean or '..' in path.parts
                or '\\' in clean or ':' in clean or any(ord(c)<32 for c in clean)
                or path.name=='game.love' or stat.S_ISLNK(entry.external_attr>>16)):
            raise ValueError(f'Unsafe or nested Android runtime asset: {name!r}')
        if entry.is_dir():continue
        if name in names:raise ValueError(f'Duplicate runtime asset: {name}')
        files.append(entry);names.add(name)
    missing={'main.lua','conf.lua','project.lua'}-names
    if missing:raise ValueError(f'Incomplete game archive: {missing}')
    return files

def stage(game,output):
    with zipfile.ZipFile(game) as archive:
        files=game_files(archive)  # Validate all paths before touching output.
        if output.exists() and any(output.iterdir()):
            raise ValueError('Android asset staging directory must be empty')
        output.mkdir(parents=True,exist_ok=True)
        for entry in files:
            target=output/entry.filename
            target.parent.mkdir(parents=True,exist_ok=True)
            with archive.open(entry) as source,target.open('wb') as destination:
                shutil.copyfileobj(source,destination,1024*1024)
    print(f'Direct APK assets: {len(files)} unchanged files, no game.love cache archive')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('game',type=Path);parser.add_argument('output',type=Path)
    args=parser.parse_args();stage(args.game,args.output)
if __name__=='__main__':main()
