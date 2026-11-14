import argparse
import hashlib
import json
from pathlib import Path


def fingerprint(root):
    digest = hashlib.sha256()
    count = 0
    for file in sorted(root.rglob('*')):
        if not file.is_file() or '.git' in file.parts:
            continue
        name = file.relative_to(root).as_posix().encode()
        digest.update(len(name).to_bytes(8, 'big'))
        digest.update(name)
        digest.update(file.stat().st_size.to_bytes(8, 'big'))
        with file.open('rb') as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b''):
                digest.update(block)
        count += 1
    return {'contentId': digest.hexdigest(), 'files': count}


def compare(a, b):
    for key in ['device', 'width', 'height', 'preferences', 'contentId', 'song', 'difficulty']:
        left, right = a['metadata'].get(key), b['metadata'].get(key)
        if left is None or right is None or left != right:
            raise ValueError('Runs are not comparable: ' + key)
    if not a.get('frames') or not b.get('frames'):
        raise ValueError('Runs contain no gameplay frames')
    fields = ['loadMs', 'meanFrameMs', 'p50Ms', 'p95Ms', 'p99Ms', 'maxMs', 'peakLuaBytes', 'peakTextureBytes', 'sampledPeakRssBytes']
    result = {}
    for key in fields:
        old, new = a.get(key), b.get(key)
        result[key] = {'before': old, 'after': new, 'changePercent': (new / old - 1) * 100 if old and new is not None else None}
    return result


def main():
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest='command', required=True)
    hash_command = commands.add_parser('fingerprint')
    hash_command.add_argument('root', type=Path)
    diff = commands.add_parser('compare')
    diff.add_argument('before', type=Path)
    diff.add_argument('after', type=Path)
    args = parser.parse_args()
    try:
        if args.command == 'fingerprint':
            if not args.root.is_dir():
                raise ValueError('Content directory does not exist')
            result = fingerprint(args.root)
        else:
            result = compare(json.loads(args.before.read_text()), json.loads(args.after.read_text()))
        print(json.dumps(result, indent=2))
    except (ValueError, KeyError, OSError) as error:
        parser.exit(1, str(error) + '\n')


if __name__ == '__main__':
    main()
