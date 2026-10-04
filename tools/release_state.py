#!/usr/bin/env python3
"""Decide whether a release can be built without replacing published packages."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess


def should_build(returncode, response):
    headers, separator, body = response.replace('\r\n', '\n').partition('\n\n')
    status = re.match(r'HTTP/\S+\s+(\d{3})\b', headers)
    if not status:
        raise RuntimeError('GitHub did not return an HTTP status; release state is unknown')
    code = int(status.group(1))
    if code == 404:
        return True
    if returncode or code != 200:
        raise RuntimeError('Cannot verify release state: HTTP ' + str(code))
    try:
        release = json.loads(body) if separator else None
    except json.JSONDecodeError as error:
        raise RuntimeError('GitHub returned invalid release metadata') from error
    if not isinstance(release, dict) or type(release.get('draft')) is not bool:
        raise RuntimeError('GitHub did not identify whether the release is a draft')
    return release['draft']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', required=True)
    parser.add_argument('--tag', required=True)
    args = parser.parse_args()
    result = subprocess.run(['gh', 'api', '--include',
                             f'repos/{args.repository}/releases/tags/{args.tag}'],
                            capture_output=True, text=True, timeout=45)
    build = should_build(result.returncode, result.stdout)
    with Path(os.environ['GITHUB_OUTPUT']).open('a', encoding='utf-8') as output:
        output.write('build_release=' + str(build).lower() + '\n')
    print('Release can be built.' if build else 'Release is already published; change project.lua version to publish new binaries.')


if __name__ == '__main__':
    main()
