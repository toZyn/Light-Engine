#!/usr/bin/env python3
"""Exercise a packaged desktop game through native keyboard and window events."""
import argparse
import ctypes
import os
from pathlib import Path
import subprocess
import time

from PIL import ImageGrab


class Desktop:
    def __init__(self):
        self.windows = os.name == 'nt'
        self.window = None

    def focus(self):
        if self.windows:
            user = ctypes.windll.user32
            user.GetWindowTextW.argtypes = [ctypes.c_void_p, ctypes.c_wchar_p, ctypes.c_int]
            user.IsWindowVisible.argtypes = [ctypes.c_void_p]
            user.SetForegroundWindow.argtypes = [ctypes.c_void_p]
            user.PostMessageW.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_size_t, ctypes.c_ssize_t]
            found = []
            callback_type = ctypes.WINFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p)
            def visit(window, _):
                title = ctypes.create_unicode_buffer(512)
                user.GetWindowTextW(window, title, len(title))
                if user.IsWindowVisible(window) and title.value.startswith('Light Engine'):
                    found.append(window)
                return True
            user.EnumWindows(callback_type(visit), 0)
            if not found:
                raise RuntimeError('Native game window was not created')
            self.window = found[0]
            user.SetForegroundWindow(self.window)
        else:
            result = subprocess.check_output(['xdotool', 'search', '--onlyvisible', '--name', '^Light Engine'], text=True)
            self.window = result.splitlines()[-1]
            subprocess.run(['xdotool', 'windowfocus', self.window], check=True)

    def key(self, key):
        self.focus()
        if self.windows:
            value = {'Return': 0x0D, 'Down': 0x28, 'BackSpace': 0x08}.get(key, ord(key.upper()[0]))
            user = ctypes.windll.user32
            scan = user.MapVirtualKeyW(value, 0)
            extended = 1 if key == 'Down' else 0
            user.keybd_event(value, scan, extended, 0)
            time.sleep(0.25)
            user.keybd_event(value, scan, extended | 2, 0)
        else:
            subprocess.run(['xdotool', 'keydown', '--clearmodifiers', key], check=True)
            time.sleep(0.25)
            subprocess.run(['xdotool', 'keyup', key], check=True)

    def close(self):
        if self.windows:
            ctypes.windll.user32.PostMessageW(self.window, 0x0010, 0, 0)
        else:
            from Xlib import display, protocol
            connection = display.Display()
            window = connection.create_resource_object('window', int(self.window))
            event = protocol.event.ClientMessage(window=window,
                client_type=connection.intern_atom('WM_PROTOCOLS'),
                data=(32, [connection.intern_atom('WM_DELETE_WINDOW'), 0, 0, 0, 0]))
            window.send_event(event, event_mask=0)
            connection.flush()
            connection.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    if os.name == 'nt':
        saves = Path(os.environ['APPDATA']) / 'com.zyn.lightengine'
    else:
        saves = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share'))) / 'com.zyn.lightengine'
    diagnostic = saves / 'diagnostics' / 'engine.log'
    errors = saves / 'diagnostics' / 'last-error.txt'
    if errors.exists():
        raise SystemExit('Use a clean runner profile for packaged game checks')
    desktop = Desktop()
    with (args.output / 'stdout.log').open('w', encoding='utf-8') as output:
        process = subprocess.Popen(args.command, stdout=output, stderr=subprocess.STDOUT)
        def wait_state(state, timeout=90):
            deadline = time.monotonic() + timeout
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise RuntimeError('Packaged game exited early: ' + str(process.returncode))
                if errors.exists():
                    raise RuntimeError(errors.read_text(errors='replace'))
                if diagnostic.exists() and ('state=' + state) in diagnostic.read_text(errors='replace').splitlines()[-1]:
                    print('NATIVE STATE: ' + state, flush=True)
                    desktop.focus()
                    ImageGrab.grab().save(args.output / (state + '.png'))
                    return
                time.sleep(1)
            raise RuntimeError('Packaged game did not enter ' + state)
        try:
            wait_state('TitleState')
            desktop.key('Return')
            time.sleep(1)
            desktop.key('Return')
            wait_state('MainMenuState')
            desktop.key('Down')
            time.sleep(0.3)
            desktop.key('Return')
            wait_state('FreeplayState')
            desktop.key('Return')
            wait_state('PlayState')
            for _ in range(4):
                for key in ('a', 's', 'w', 'd'):
                    desktop.key(key)
                    time.sleep(0.15)
            desktop.key('p')
            time.sleep(2)
            ImageGrab.grab().save(args.output / 'paused.png')
            desktop.key('Return')
            time.sleep(3)
            ImageGrab.grab().save(args.output / 'resumed.png')
            if errors.exists():
                raise RuntimeError(errors.read_text(errors='replace'))
            desktop.close()
            code = process.wait(timeout=20)
            if code != 0:
                raise RuntimeError('Packaged game quit with exit ' + str(code))
            if (saves / 'diagnostics/session.active').exists():
                raise RuntimeError('Packaged game did not finish diagnostics cleanly')
            print('DESKTOP BINARY PASSED: input-driven menu navigation, song loading and clean shutdown')
            print('MANUAL REVIEW REQUIRED: gameplay input and pause/resume screenshots')
        finally:
            try:
                ImageGrab.grab().save(args.output / 'final.png')
            except OSError as error:
                print('Final screenshot unavailable: ' + str(error))
            if diagnostic.exists():
                (args.output / 'engine.log').write_bytes(diagnostic.read_bytes())
            if errors.exists():
                (args.output / 'last-error.txt').write_bytes(errors.read_bytes())
            if process.poll() is None:
                process.kill()
                process.wait(timeout=10)


if __name__ == '__main__':
    main()
