#!/usr/bin/env python3
"""Install and exercise the signed release APK on a running Android emulator."""
import argparse
from pathlib import Path
import re
import subprocess
import time

PACKAGE = 'com.zyn.lightengine'
LAUNCHER = PACKAGE + '/org.love2d.android.StoragePermissionActivity'


def adb(*args, check=True, timeout=60, binary=False):
    result = subprocess.run(['adb', *args], capture_output=True, text=not binary,
                            timeout=timeout, check=check)
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--abi', required=True, choices=('arm64-v8a', 'armeabi-v7a'))
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    properties = adb('shell', 'getprop')
    (args.output / 'device-properties.txt').write_text(properties)
    if args.abi not in adb('shell', 'getprop', 'ro.product.cpu.abilist').strip().split(','):
        raise SystemExit('Emulator does not advertise the requested ARM ABI: ' + args.abi)
    adb('root')
    adb('wait-for-device')
    adb('install', '-r', '--abi', args.abi, str(args.apk), timeout=300)
    adb('shell', 'pm', 'clear', PACKAGE)
    adb('logcat', '-c')
    diagnostic = None

    def screenshot(name):
        (args.output / (name + '.png')).write_bytes(adb('exec-out', 'screencap', '-p', binary=True))

    def key(value):
        adb('shell', 'input', 'keyevent', value)

    def wait_state(state, timeout=150, previous_log=None):
        nonlocal diagnostic
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if not adb('shell', 'pidof', PACKAGE, check=False).strip():
                raise RuntimeError('Release APK process exited while waiting for ' + state)
            if not diagnostic:
                found = adb('shell', 'find /data/data/' + PACKAGE + ' /sdcard/Android/data/' + PACKAGE
                            + ' -name engine.log 2>/dev/null', check=False)
                diagnostic = next((p for p in found.splitlines() if p.endswith('/diagnostics/engine.log')), None)
            if diagnostic:
                text = adb('shell', 'cat', diagnostic, check=False)
                (args.output / 'engine.log').write_text(text)
                error = adb('shell', 'cat', diagnostic.replace('engine.log', 'last-error.txt'), check=False)
                if error.strip():
                    raise RuntimeError(error)
                if text != previous_log and text.splitlines() and ('state=' + state) in text.splitlines()[-1]:
                    print('ANDROID STATE: ' + state, flush=True)
                    screenshot(state)
                    return
            time.sleep(2)
        raise RuntimeError('Release APK did not enter ' + state)

    try:
        adb('shell', 'am', 'start', '-W', '-n', LAUNCHER)
        time.sleep(3)
        screenshot('storage-permission')
        adb('shell', 'appops', 'set', PACKAGE, 'MANAGE_EXTERNAL_STORAGE', 'allow')
        adb('shell', 'am', 'force-stop', PACKAGE)
        adb('shell', 'am', 'start', '-W', '-n', LAUNCHER)
        wait_state('TitleState')
        key('KEYCODE_ENTER')
        time.sleep(1)
        key('KEYCODE_ENTER')
        wait_state('MainMenuState')
        key('KEYCODE_DPAD_DOWN')
        time.sleep(0.3)
        key('KEYCODE_ENTER')
        wait_state('FreeplayState')
        key('KEYCODE_ENTER')
        wait_state('PlayState')
        for _ in range(3):
            for value in ('KEYCODE_A', 'KEYCODE_S', 'KEYCODE_W', 'KEYCODE_D'):
                key(value)
                time.sleep(0.2)
        key('KEYCODE_P')
        time.sleep(2)
        screenshot('paused')
        key('KEYCODE_ENTER')
        time.sleep(3)
        screenshot('resumed')
        original_pid = adb('shell', 'pidof', PACKAGE).strip()
        previous_log = adb('shell', 'cat', diagnostic)
        key('KEYCODE_HOME')
        time.sleep(2)
        if adb('shell', 'pidof', PACKAGE, check=False).strip() != original_pid:
            raise RuntimeError('Android killed the game while backgrounded')
        adb('shell', 'am', 'start', '-W', '-n', PACKAGE + '/org.love2d.android.GameActivity')
        if adb('shell', 'pidof', PACKAGE, check=False).strip() != original_pid:
            raise RuntimeError('Foregrounding restarted the game process')
        wait_state('PlayState', previous_log=previous_log)
        screenshot('foreground-restored')
        if not adb('shell', 'pidof', PACKAGE).strip():
            raise RuntimeError('Release APK did not survive background/foreground')
        log = adb('logcat', '-d')
        if re.search(r'ANR in com\.zyn\.lightengine|(?:Fatal signal|FATAL EXCEPTION)[\s\S]{0,500}com\.zyn\.lightengine', log):
            raise RuntimeError('Android reported an application crash or ANR')
        if diagnostic:
            error = adb('shell', 'cat', diagnostic.replace('engine.log', 'last-error.txt'), check=False)
            if error.strip():
                raise RuntimeError(error)
        print('App-private storage: ' + adb('shell', 'du', '-sk', '/data/data/' + PACKAGE + '/files', check=False).strip())
        print('ANDROID APK PASSED: ' + args.abi + ', signed install, storage, input-driven menus, song loading and process/state continuity')
        print('MANUAL REVIEW REQUIRED: gameplay input and pause/resume screenshots')
    finally:
        (args.output / 'logcat.txt').write_text(adb('logcat', '-d', check=False))
        screenshot('final')
        adb('shell', 'am', 'force-stop', PACKAGE, check=False)
        adb('uninstall', PACKAGE, check=False)


if __name__ == '__main__':
    main()
