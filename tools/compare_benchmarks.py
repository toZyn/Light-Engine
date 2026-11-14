import argparse
import json
from pathlib import Path

FIELDS = ('device', 'content', 'os', 'renderer', 'driver', 'vendor', 'love', 'width', 'height', 'logical_width', 'logical_height', 'prefs', 'song', 'difficulty', 'cache', 'sample_seconds')

def mismatches(a, b):
    differences = [key for key in FIELDS if a.get('context', {}).get(key) != b.get('context', {}).get(key)]
    if a.get('schema') != b.get('schema'):
        differences.append('schema')
    if not a.get('completed') or not b.get('completed'):
        differences.append('incomplete loading')
    if not a.get('frames', {}).get('count') or not b.get('frames', {}).get('count'):
        differences.append('missing frames')
    return differences

def main():
    parser = argparse.ArgumentParser(description='Compare reports captured with identical content, device and settings.')
    parser.add_argument('before', type=Path)
    parser.add_argument('after', type=Path)
    args = parser.parse_args()
    try:
        a, b = [json.loads(path.read_text()) for path in (args.before, args.after)]
    except (OSError, ValueError) as error:
        parser.error(str(error))
    errors = mismatches(a, b)
    if errors:
        parser.error('Not comparable: ' + ', '.join(errors))
    if a['context'].get('content') in (None, 'unverified'):
        parser.error('Provide a verified content fingerprint when capturing both reports.')
    rows = [('Loading (s)', a['loading_seconds'], b['loading_seconds'])]
    for key in ('mean_ms', 'p50_ms', 'p95_ms', 'p99_ms', 'max_ms'):
        rows.append((key, a['frames'][key], b['frames'][key]))
    for key in ('lua_peak_bytes', 'texture_peak_bytes', 'process_rss_peak_bytes'):
        if key in a['memory'] and key in b['memory']:
            rows.append((key, a['memory'][key], b['memory'][key]))
    print('| Metric | Before | After | Change |\n|---|---:|---:|---:|')
    for name, old, new in rows:
        delta = f'{(new / old - 1) * 100:+.2f}%' if old else 'n/a'
        print(f'| {name} | {old:.3f} | {new:.3f} | {delta} |')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
