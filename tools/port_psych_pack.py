#!/usr/bin/env python3
import argparse
import json
import os
import re
import shutil
from collections import Counter
from pathlib import Path

AUDIO = {'.ogg', '.wav', '.mp3', '.flac'}
ASSETS = ('images', 'sounds', 'music', 'fonts', 'videos', 'shaders')
GLOBAL_ROOTS = {'images', 'characters', 'music', 'sounds', 'fonts', 'data', 'stages', 'weeks', 'videos', 'shaders'}
FEATURES = (
    'runHaxeCode', 'runHaxeFunction', 'addHaxeLibrary', 'setPropertyFromClass',
    'getPropertyFromClass', 'setPropertyFromGroup', 'getPropertyFromGroup',
    'startVideo', 'playVideo', 'initLuaShader', 'setSpriteShader',
    'setShaderFloat', 'onCreate', 'onUpdate', 'onBeatHit', 'onStepHit',
    'goodNoteHit', 'opponentNoteHit', 'onEvent', 'onTimerCompleted',
)

def slug(name):
    name = name.lower().replace(' ', '-')
    name = re.sub(r'[~&\\;:<>#]', '-', name)
    return re.sub(r'[.,\'"%?!]', '', name)

def link_file(source, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        return False
    try:
        os.link(source, dest)
    except OSError:
        shutil.copy2(source, dest)
    return True

def link_tree(source, dest, allow=None):
    count = 0
    if not source.is_dir():
        return count
    for path in source.rglob('*'):
        if not path.is_file() or path.is_symlink():
            continue
        if allow is not None and path.suffix.lower() not in allow:
            continue
        count += bool(link_file(path, dest / path.relative_to(source)))
    return count

def alias_casefolded_images(dest):
    source = dest / 'images'
    if not source.is_dir():
        return 0
    count = 0
    for image in list(source.rglob('*')):
        if not image.is_file() or image.suffix.lower() not in {'.png', '.xml', '.jpg', '.jpeg', '.json'}:
            continue
        relative = image.relative_to(source)
        normalized = Path(*(part.lower() for part in relative.parts))
        if normalized != relative:
            count += bool(link_file(image, source / normalized))
    return count

def write_json(dest, data):
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        raise FileExistsError(dest)
    dest.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def chart_difficulty(filename, directory):
    base = filename[:-5] if filename.lower().endswith('.json') else filename
    low = base.lower()
    for root in (directory.lower(), slug(directory), 'chart'):
        if low == root:
            return 'normal'
        if low.startswith(root + '-'):
            return low[len(root) + 1:]
    if low in ('normal', 'easy', 'hard', 'erect', 'nightmare'):
        return low
    return None

def audit_script(path, stats):
    try:
        data = path.read_text(encoding='utf-8', errors='replace')
    except OSError:
        return
    stats['lua_scripts'] += 1
    for feature in FEATURES:
        if re.search(r'\b' + feature + r'\s*\(', data):
            stats['features'][feature] += 1

def convert(src, dest):
    if dest.exists():
        raise FileExistsError(f'Refusing to overwrite {dest}')
    dest.mkdir(parents=True)
    stats = {'source': src.name, 'assets': 0, 'charts': 0,
             'songs': 0, 'image_aliases': 0, 'characters': 0, 'stages': 0,
             'weeks': 0, 'lua_scripts': 0, 'features': Counter(),
             'warnings': [], 'status': 'structural-only'}
    for folder in ASSETS:
        stats['assets'] += link_tree(src / folder, dest / folder)
    stats['image_aliases'] = alias_casefolded_images(dest)
    for root, target, label in (
        ('characters', 'data/characters', 'characters'),
        ('stages', 'data/stages', 'stages'),
        ('weeks', 'data/weeks/weeks', 'weeks'),
    ):
        source = src / root
        if source.exists():
            stats[label] += link_tree(source, dest / target, {'.json'})
    for path in src.rglob('*.lua'):
        if path.is_file():
            audit_script(path, stats)
            link_file(path, dest / 'psych-legacy' / path.relative_to(src))
    charts = {}
    chart_data = src / 'data'
    if chart_data.is_dir():
        for chart_dir in chart_data.iterdir():
            if not chart_dir.is_dir():
                continue
            name = slug(chart_dir.name)
            if not name:
                continue
            for path in chart_dir.glob('*.json'):
                if path.name.lower() == 'events.json':
                    link_file(path, dest / 'songs' / name / 'events.json')
                    continue
                try:
                    data = json.loads(path.read_text(encoding='utf-8-sig'))
                except (OSError, UnicodeError, ValueError) as exc:
                    stats['warnings'].append(f'{path.relative_to(src)}: invalid JSON ({exc})')
                    continue
                song = data.get('song') if isinstance(data, dict) else None
                if not isinstance(song, dict) or not isinstance(song.get('notes'), list):
                    continue
                diff = chart_difficulty(path.name, chart_dir.name)
                if diff is None:
                    stats['warnings'].append(f'{path.relative_to(src)}: unknown difficulty')
                    continue
                target = dest / 'songs' / name / 'charts' / (diff + '.json')
                if not link_file(path, target):
                    stats['warnings'].append(f'{path.relative_to(src)}: chart collision: {diff}')
                    continue
                stats['charts'] += 1
                charts.setdefault(name, {})[diff] = song
    for song_dir in (src / 'songs').iterdir() if (src / 'songs').is_dir() else []:
        if not song_dir.is_dir():
            continue
        name = slug(song_dir.name)
        if not name:
            continue
        target = dest / 'songs' / name
        for asset in song_dir.iterdir():
            if asset.is_file() and asset.suffix.lower() in AUDIO:
                link_file(asset, target / asset.name)
        if not (target / 'charts').exists():
            stats['warnings'].append(f'songs/{song_dir.name}: audio without converted charts')
    for name, variants in charts.items():
        target = dest / 'songs' / name
        selected = variants.get('normal') or next(iter(variants.values()))
        if not (target / 'meta.json').exists():
            write_json(target / 'meta.json', {
                'songName': selected.get('song') or name,
                'difficulties': sorted(variants, key=lambda d: (['easy', 'normal', 'hard'].index(d) if d in ('easy', 'normal', 'hard') else 3, d)),
                'stage': selected.get('stage') or 'stage',
                'characters': {
                    'player': selected.get('player1') or 'bf',
                    'opponent': selected.get('player2') or 'dad',
                    'girlfriend': selected.get('gfVersion') or 'gf'
                }
            })
        stats['songs'] += 1
    original_meta = src / 'pack.json'
    meta = {'name': src.name, 'version': '3.0-port-preview',
            'description': 'Structural Psych Engine port. Advanced scripts and effects are not yet compatible.'}
    if original_meta.is_file():
        try:
            raw = json.loads(original_meta.read_text(encoding='utf-8-sig'))
            if isinstance(raw, dict):
                for key in ('name', 'author', 'description'):
                    if isinstance(raw.get(key), str):
                        meta[key] = raw[key]
        except (UnicodeError, ValueError):
            pass
    write_json(dest / 'meta.json', meta)
    stats['features'] = dict(stats['features'])
    write_json(dest / 'port-report.json', stats)
    return stats

def convert_globals(source, dest):
    if dest.exists():
        raise FileExistsError(f'Refusing to overwrite {dest}')
    dest.mkdir(parents=True)
    total = 0
    for folder in ASSETS:
        total += link_tree(source / folder, dest / folder)
    total += link_tree(source / 'characters', dest / 'data/characters', {'.json'})
    total += link_tree(source / 'stages', dest / 'data/stages', {'.json'})
    total += link_tree(source / 'weeks', dest / 'data/weeks/weeks', {'.json'})
    aliases = alias_casefolded_images(dest)
    write_json(dest / 'meta.json', {
        'name': 'Mega Modpack V3 Shared Assets',
        'description': 'Psych Engine global assets; manually activate this addon for imported mods.',
        'version': '0.1.0'
    })
    return {'assets': total, 'aliases': aliases}

def main():
    p = argparse.ArgumentParser(description='Create a safe structural port of Psych Engine mod folders for Light Engine.')
    p.add_argument('source', type=Path)
    p.add_argument('destination', type=Path)
    p.add_argument('--only', action='append', help='Original mod folder name; repeat as necessary')
    p.add_argument('--report', type=Path)
    p.add_argument('--shared-addon', type=Path, help='Install global Psych assets as a selectable Light Engine addon')
    args = p.parse_args()
    if not args.source.is_dir():
        p.error('Source mods folder not found')
    selected = args.only if args.only else sorted(p.name for p in args.source.iterdir() if p.is_dir() and p.name not in GLOBAL_ROOTS)
    report = {'mods': [], 'failures': [], 'status': 'structural-port-only'}
    if args.shared_addon:
        report['shared_addon'] = convert_globals(args.source, args.shared_addon)
    for name in selected:
        if Path(name).name != name or name in {'.', '..'}:
            report['failures'].append(f'{name}: invalid mod folder name')
            continue
        if name in GLOBAL_ROOTS:
            report['failures'].append(f'{name}: global asset folder, not a standalone mod')
            continue
        src = args.source / name
        if not src.is_dir() or src.parent != args.source:
            report['failures'].append(f'{name}: invalid source')
            continue
        try:
            result = convert(src, args.destination / name)
            report['mods'].append(result)
            print(f'{name}: {result["songs"]} songs / {result["charts"]} charts / {result["lua_scripts"]} scripts require review', flush=True)
        except (OSError, ValueError) as exc:
            report['failures'].append(f'{name}: {exc}')
            print(f'FAILED {name}: {exc}', flush=True)
    if args.report:
        write_json(args.report, report)
    print(f'PORT SUMMARY: {len(report["mods"])} staged, {len(report["failures"])} failures', flush=True)
    return 1 if report['failures'] else 0

if __name__ == '__main__':
    raise SystemExit(main())
