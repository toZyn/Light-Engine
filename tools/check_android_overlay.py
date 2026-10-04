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
        adb('shell', 'uiautomator', 'dump', '/sdcard/overlay-window.xml', check=False)
        text = adb('shell', 'cat', '/sdcard/overlay-window.xml', check=False)
        try:
            return list(ET.fromstring(text).iter('node'))
        except ET.ParseError:
            return []

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
        adb('shell', 'input', 'tap', str(x), str(y))

    def request(hide=False, token=TOKEN):
        fields = {'token': token}
        if not hide:
            fields.update(image=base64.urlsafe_b64encode(image()).decode().rstrip('='),
                          x=100, y=200, width=300, height=200, label='Runtime PNG check')
        uri = 'lightengine-overlay://' + ('hide' if hide else 'show') + '?' + urlencode(fields)
        adb('shell', 'am start -W -a android.intent.action.VIEW -n ' + ACTIVITY + ' -d ' + shlex.quote(uri))

    def active():
        return any(n.get('content-desc') == 'Close image overlay' for n in nodes())

    def wait_closed():
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            services = adb('shell', 'dumpsys', 'activity', 'services', PACKAGE)
            if not active() and 'ServiceRecord{' not in services:
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
        if active():
            raise RuntimeError('Existing permission bypassed image consent')
        tap('Show image')
        find('Close image overlay')
        adb('shell', 'input', 'keyevent', 'KEYCODE_HOME')
        close = find('Close image overlay')
        screenshot('above-home')
        x, y = center(close)
        adb('shell', 'input', 'swipe', str(x - 100), str(y + 80), str(x + 100), str(y + 180), '600')
        moved = center(find('Close image overlay'))
        if moved == (x, y):
            raise RuntimeError('Dragging did not move the native overlay window')
        screenshot('dragged')
        tap('Close image overlay')
        wait_closed()
        screenshot('closed')

        request()
        tap('Show image')
        find('Close image overlay')
        request(hide=True, token='cd' * 32)
        find('Close image overlay')
        request(hide=True)
        wait_closed()

        request()
        tap('Show image')
        find('Close image overlay')
        adb('shell', 'appops', 'set', '--uid', PACKAGE, 'SYSTEM_ALERT_WINDOW', 'deny')
        wait_closed()
        screenshot('permission-revoked')
        log = adb('logcat', '-d')
        if re.search(r'ANR in com\.zyn\.lightengine\.overlay|(?:Fatal signal|FATAL EXCEPTION)[\s\S]{0,500}com\.zyn\.lightengine\.overlay', log):
            raise RuntimeError('Android reported an overlay crash or ANR')
        print('ANDROID OVERLAY PASSED: signed install, consent/cancel, display above home, dragging, close, token-scoped hide and permission revocation')
    finally:
        (args.output / 'logcat.txt').write_text(adb('logcat', '-d', check=False))
        (args.output / 'window.txt').write_text(adb('shell', 'dumpsys', 'window', 'windows', check=False))
        adb('shell', 'am', 'force-stop', PACKAGE, check=False)
        adb('uninstall', PACKAGE, check=False)


if __name__ == '__main__':
    main()
