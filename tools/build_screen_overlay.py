#!/usr/bin/env python3
"""Build/sign the separate Java-only Android image-overlay companion.

Requires Android platform/build-tools 35 and a JDK. No Gradle, JNI rebuild or
changes to the Light Engine APK. Credentials never appear in command arguments.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'separate-addons/screen-overlay/android'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jdk', type=Path, required=True)
    parser.add_argument('--android-jar', type=Path, required=True)
    parser.add_argument('--build-tools', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--keystore', type=Path, default=ROOT / 'android/keystore.jks')
    parser.add_argument('--properties', type=Path, default=ROOT / 'android/keystore.properties')
    args = parser.parse_args()
    args.output = args.output.resolve()
    if args.output in {args.keystore.resolve(), args.properties.resolve(), args.android_jar.resolve()}:
        parser.error('Output must differ from inputs')
    java, javac = args.jdk / 'bin/java', args.jdk / 'bin/javac'
    tools = args.build_tools
    inputs = [java, javac, args.android_jar, tools / 'aapt2', tools / 'zipalign',
              tools / 'lib/d8.jar', tools / 'lib/apksigner.jar', args.keystore, args.properties]
    for file in inputs:
        if not file.is_file(): parser.error(f'Missing build input: {file}')
    properties = {}
    for line in args.properties.read_text().splitlines():
        if '=' in line and not line.lstrip().startswith('#'):
            name, value = line.split('=', 1)
            properties[name.strip()] = value.strip()
    environment = os.environ.copy()
    environment['LE_OVERLAY_STORE_PASS'] = properties.get('KEYSTORE_PASSWORD', properties['KEY_PASSWORD'])
    environment['LE_OVERLAY_KEY_PASS'] = properties['KEY_PASSWORD']
    def run(command, **kwargs):
        return subprocess.run([str(x) for x in command], env=environment, check=True, **kwargs)
    source_files = sorted((SOURCE / 'src').rglob('*.java'))
    if not source_files: parser.error('No companion Java sources')
    source_snapshot = {file: file.read_bytes() for file in [SOURCE / 'AndroidManifest.xml', *source_files]}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='light-engine-overlay-build-') as directory:
        work = Path(directory)
        snapshot = work / 'source'
        for original, contents in source_snapshot.items():
            copy = snapshot / original.relative_to(SOURCE)
            copy.parent.mkdir(parents=True, exist_ok=True)
            copy.write_bytes(contents)
        frozen_sources = [snapshot / file.relative_to(SOURCE) for file in source_files]
        classes, dex = work / 'classes', work / 'dex'
        classes.mkdir(); dex.mkdir()
        run([javac, '--release', '8', '-classpath', args.android_jar, '-d', classes, *frozen_sources])
        run([java, '-cp', tools / 'lib/d8.jar', 'com.android.tools.r8.D8', '--min-api', '26',
             '--lib', args.android_jar, '--output', dex, *sorted(classes.rglob('*.class'))])
        package = work / 'unsigned.apk'
        run([tools / 'aapt2', 'link', '-o', package, '-I', args.android_jar,
             '--manifest', snapshot / 'AndroidManifest.xml', '--min-sdk-version', '26', '--target-sdk-version', '35'])
        with zipfile.ZipFile(package, 'a', zipfile.ZIP_DEFLATED) as archive:
            for file in sorted(dex.glob('*.dex')): archive.write(file, file.name)
        aligned = work / 'aligned.apk'
        run([tools / 'zipalign', '-P', '16', '-f', '4', package, aligned])
        signer = [java, '-jar', tools / 'lib/apksigner.jar']
        run([*signer, 'sign', '--ks', args.keystore, '--ks-key-alias', properties['KEY_ALIAS'],
             '--ks-pass', 'env:LE_OVERLAY_STORE_PASS', '--key-pass', 'env:LE_OVERLAY_KEY_PASS',
             '--out', args.output, aligned])
        run([tools / 'zipalign', '-c', '-P', '16', '4', args.output])
        verified = run([*signer, 'verify', '--verbose', '--print-certs', args.output], capture_output=True, text=True)
        print(verified.stdout)
    with zipfile.ZipFile(args.output) as archive:
        if archive.testzip() is not None: raise ValueError('Companion ZIP integrity failed')
        if 'classes.dex' not in archive.namelist(): raise ValueError('Companion DEX missing')
        if any(name.startswith(('lib/', 'assets/game.love')) for name in archive.namelist()):
            raise ValueError('Companion must stay separate from the engine/native runtime')
    report = {
        'package': 'com.zyn.lightengine.overlay', 'minSdk': 26, 'targetSdk': 35,
        'bytes': args.output.stat().st_size,
        'sha256': hashlib.sha256(args.output.read_bytes()).hexdigest(),
        'sources': {file.relative_to(ROOT).as_posix(): hashlib.sha256(contents).hexdigest()
                    for file, contents in source_snapshot.items()},
    }
    args.output.with_suffix('.build.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f"Signed separate companion: {args.output} ({report['bytes']} bytes), SHA256 {report['sha256']}")


if __name__ == '__main__': main()
