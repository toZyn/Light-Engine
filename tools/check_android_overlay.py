#!/usr/bin/env python3
"""Exercise the published image-overlay APK through Android's real UI."""
import argparse
import base64
from pathlib import Path
import re
import shlex
import struct
import subprocess
import time
from urllib.parse import urlencode
import xml.etree.ElementTree as ET
import zlib

PACKAGE = 'com.zyn.lightengine.overlay'
ACTIVITY = PACKAGE + '/.OverlayActivity'
TOKEN = 'ab' * 32


def adb(*args, check=True, binary=False):
    return subprocess.run(['adb', *args], capture_output=True, text=not binary,
                          timeout=60, check=check).stdout


def image():
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    pixels = (b'\x00' + b'\x22\xcc\x66\xff' * 16) * 16
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 16, 16, 8, 6, 0, 0, 0)) \
        + chunk(b'IDAT', zlib.compress(pixels)) + chunk(b'IEND', b'')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    adb('install', '-r', str(args.apk))
    adb('shell', 'pm', 'clear', PACKAGE)
    adb('logcat', '-c')

    def screenshot(name):
        (args.output / (name + '.png')).write_bytes(adb('exec-out', 'screencap', '-p', binary=True))

    def nodes():
        adb('shell', 'rm', '-f', '/sdcard/overlay-window.xml')
        adb('shell', 'uiautomator', 'dump', '/sdcard/overlay-window.xml')
        adb('shell', 'test', '-s', '/sdcard/overlay-window.xml')
        text = adb('shell', 'cat', '/sdcard/overlay-window.xml')
        (args.output / 'ui-last.xml').write_text(text)
        return list(ET.fromstring(text).iter('node'))

    def find(text, timeout=30):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            for node in nodes():
                if any(value.casefold() == text.casefold() for value in
                       (node.get('text', ''), node.get('content-desc', ''))):
                    return node
            time.sleep(0.5)
        raise RuntimeError('Android UI did not expose: ' + text)

    def center(node):
        x1, y1, x2, y2 = map(int, re.findall(r'\d+', node.get('bounds')))
        return (x1 + x2) // 2, (y1 + y2) // 2

    def tap(text):
        x, y = center(find(text))
        print('Tap ' + text + ': ' + str((x, y)), flush=True)
        screenshot('before-' + text.lower().replace(' ', '-'))
        adb('shell', 'input', 'tap', str(x), str(y))

    def request(hide=False, token=TOKEN):
        fields = {'token': token}
        if not hide:
            fields.update(image=base64.urlsafe_b64encode(image()).decode().rstrip('='),
                          x=100, y=200, width=300, height=200, label='Runtime PNG check')
        uri = 'lightengine-overlay://' + ('hide' if hide else 'show') + '?' + urlencode(fields)
        adb('shell', 'am start -W -a android.intent.action.VIEW -n ' + ACTIVITY + ' -d ' + shlex.quote(uri))

    def overlay_bounds():
        windows = adb('shell', 'dumpsys', 'window', 'windows')
        for block in re.split(r'\n\s*Window #\d+', windows):
            if ('package=' + PACKAGE) not in block or 'ty=APPLICATION_OVERLAY' not in block:
                continue
            if 'mHasSurface=true' not in block or 'isVisible=true' not in block or 'mDrawState=HAS_DRAWN' not in block:
                continue
            frame = re.search(r'\bframe=\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]', block)
            if frame:
                return tuple(map(int, frame.groups()))

    def wait_visible():
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            bounds = overlay_bounds()
            if bounds:
                return bounds
            time.sleep(0.5)
        raise RuntimeError('Android did not draw the native overlay window')

    def wait_closed():
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            services = adb('shell', 'dumpsys', 'activity', 'services', PACKAGE)
            if not overlay_bounds() and 'ServiceRecord{' not in services:
                return
            time.sleep(0.5)
        raise RuntimeError('Android overlay or foreground service did not stop')

    try:
        adb('shell', 'am', 'start', '-W', '-n', ACTIVITY)
        time.sleep(1)
        if not adb('shell', 'pidof', PACKAGE, check=False).strip():
            raise RuntimeError('Overlay APK did not launch')
        screenshot('launcher')
        request()
        find('Show this image?')
        screenshot('consent')
        tap('Cancel')
        wait_closed()

        adb('shell', 'appops', 'set', '--uid', PACKAGE, 'SYSTEM_ALERT_WINDOW', 'allow')
        request()
        find('Show this image?')
        if overlay_bounds():
            raise RuntimeError('Existing permission bypassed image consent')
        tap('Show image')
        wait_visible()
        adb('shell', 'input', 'keyevent', 'KEYCODE_HOME')
        bounds = wait_visible()
        screenshot('above-home')
        x, y = bounds[0] + 30, (bounds[1] + bounds[3]) // 2
        adb('shell', 'input', 'swipe', str(x), str(y), str(x + 200), str(y + 100), '600')
        moved = wait_visible()
        if moved[:2] == bounds[:2]:
            raise RuntimeError('Dragging did not move the native overlay window')
        screenshot('dragged')
        adb('shell', 'input', 'tap', str(moved[2] - 16), str(moved[1] + 16))
        wait_closed()
        screenshot('closed')

        request()
        tap('Show image')
        wait_visible()
        request(hide=True, token='cd' * 32)
        wait_visible()
        request(hide=True)
        wait_closed()

        request()
        tap('Show image')
        wait_visible()
        adb('shell', 'appops', 'set', '--uid', PACKAGE, 'SYSTEM_ALERT_WINDOW', 'deny')
        wait_closed()
        screenshot('permission-revoked')
        log = adb('logcat', '-d')
        if re.search(r'ANR in com\.zyn\.lightengine\.overlay|(?:Fatal signal|FATAL EXCEPTION)[\s\S]{0,500}com\.zyn\.lightengine\.overlay', log):
            raise RuntimeError('Android reported an overlay crash or ANR')
        print('ANDROID OVERLAY PASSED: signed install, consent/cancel, display above home, dragging, close, token-scoped hide and permission revocation')
    finally:
        screenshot('final')
        (args.output / 'logcat.txt').write_text(adb('logcat', '-d', check=False))
        (args.output / 'window.txt').write_text(adb('shell', 'dumpsys', 'window', 'windows', check=False))
        adb('shell', 'am', 'force-stop', PACKAGE, check=False)
        adb('uninstall', PACKAGE, check=False)


if __name__ == '__main__':
    main()
