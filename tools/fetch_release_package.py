#!/usr/bin/env python3
"""Download a release asset and verify its recorded digest and source commit."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time


def api(path):
    result = subprocess.run(['gh', 'api', path], capture_output=True, text=True, timeout=40)
    if result.returncode:
        return None
    return json.loads(result.stdout)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('asset')
    parser.add_argument('output', type=Path)
    parser.add_argument('--commit', required=True)
    parser.add_argument('--timeout', type=int, default=1800)
    args = parser.parse_args()
    repository = os.environ['GITHUB_REPOSITORY']
    source = (Path(__file__).resolve().parents[1] / 'project.lua').read_text()
    import re
    version = re.search(r'^\s*version\s*=\s*"([^"\n]+)"', source, re.MULTILINE).group(1)
    name = args.asset.replace('{version}', version)
    deadline = time.monotonic() + args.timeout
    asset = None
    while time.monotonic() < deadline:
        releases = api(f'repos/{repository}/releases?per_page=30') or []
        release = next((r for r in releases if r['tag_name'] == 'v' + version), None)
        if release:
            if release['target_commitish'] != args.commit:
                raise SystemExit('Release does not belong to the expected source commit: ' + release['target_commitish'])
            asset = next((a for a in release['assets'] if a['name'] == name and a['state'] == 'uploaded'), None)
            if asset:
                break
        print('Waiting for release asset: ' + name, flush=True)
        time.sleep(20)
    if not asset:
        raise SystemExit('Release asset was not produced: ' + name)
    digest = asset.get('digest', '')
    if not digest.startswith('sha256:'):
        raise SystemExit('Release asset has no SHA-256 digest')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open('wb') as handle:
        subprocess.run(['gh', 'api', '-H', 'Accept: application/octet-stream',
                        f'repos/{repository}/releases/assets/{asset["id"]}'], stdout=handle, check=True, timeout=600)
    with args.output.open('rb') as handle:
        actual = hashlib.file_digest(handle, 'sha256').hexdigest()
    if actual != digest.split(':', 1)[1]:
        args.output.unlink()
        raise SystemExit('Downloaded asset failed its SHA-256 check')
    print(json.dumps({'asset': name, 'sourceCommit': args.commit, 'sha256': actual, 'bytes': args.output.stat().st_size}), flush=True)


if __name__ == '__main__':
    main()
