#!/usr/bin/env python3
"""Explicit per-user URI registration. Importing this module changes nothing."""
import argparse
import importlib.util
import os
import subprocess
import sys
from pathlib import Path

SCHEME='lightengine-overlay'
ENTRY='lightengine-screen-overlay.desktop'

def safe_path(value):
    value=str(value)
    if any(ord(c)<32 or ord(c)==127 for c in value) or '"' in value:
        raise ValueError('Handler paths cannot contain quotes or control characters.')
    return value

def windows_command(python,script):
    return f'"{safe_path(python)}" "{safe_path(script)}" --uri "%1"'

def desktop_quote(value):
    value=safe_path(value).replace('%','%%').replace('\\','\\\\\\\\')
    for character in ('"','`','$'):value=value.replace(character,'\\\\'+character)
    return '"'+value+'"'

def linux_entry(python,script):
    return '[Desktop Entry]\nType=Application\nName=Light Engine PNG overlay\nNoDisplay=true\nTerminal=false\n' + \
           f'Exec={desktop_quote(python)} {desktop_quote(script)} --uri %u\nMimeType=x-scheme-handler/{SCHEME};\n'

def data_directory(data_home=None):
    return Path(data_home) if data_home is not None else Path(os.environ.get('XDG_DATA_HOME',Path.home()/'.local/share'))

def install_linux(script,data_home=None,run=subprocess.run):
    script=Path(script).resolve()
    path=data_directory(data_home)/'applications'/ENTRY
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(linux_entry(sys.executable,script),encoding='utf-8');path.chmod(0o644)
    try:run(['xdg-mime','default',ENTRY,'x-scheme-handler/'+SCHEME],check=True,timeout=10)
    except (OSError,subprocess.SubprocessError):
        path.unlink(missing_ok=True)
        raise
    return path

def uninstall_linux(data_home=None):
    path=data_directory(data_home)/'applications'/ENTRY
    path.unlink(missing_ok=True)
    return path

def install_windows(script):
    import winreg
    python=Path(sys.executable)
    if python.with_name('pythonw.exe').exists():python=python.with_name('pythonw.exe')
    root='Software\\Classes\\'+SCHEME
    with winreg.CreateKey(winreg.HKEY_CURRENT_USER,root) as key:
        winreg.SetValueEx(key,'',0,winreg.REG_SZ,'URL:Light Engine PNG overlay')
        winreg.SetValueEx(key,'URL Protocol',0,winreg.REG_SZ,'')
    with winreg.CreateKey(winreg.HKEY_CURRENT_USER,root+'\\shell\\open\\command') as key:
        winreg.SetValueEx(key,'',0,winreg.REG_SZ,windows_command(python,Path(script).resolve()))
    return 'HKCU\\'+root

def uninstall_windows(script):
    import winreg
    root='Software\\Classes\\'+SCHEME
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER,root+'\\shell\\open\\command') as key:
            command=winreg.QueryValueEx(key,'')[0]
        if '"'+str(Path(script).resolve())+'"' not in command:
            raise ValueError('Another handler owns this URI scheme; it was left unchanged.')
        for suffix in ('\\shell\\open\\command','\\shell\\open','\\shell',''):
            winreg.DeleteKey(winreg.HKEY_CURRENT_USER,root+suffix)
    except FileNotFoundError:pass
    return 'HKCU\\'+root

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--install',action='store_true');group.add_argument('--uninstall',action='store_true')
    args=parser.parse_args();script=Path(__file__).resolve().with_name('companion.py')
    if args.install and importlib.util.find_spec('PySide6') is None:
        parser.error('Install requirements.txt into this Python interpreter first.')
    if sys.platform=='win32':operation=install_windows if args.install else uninstall_windows
    elif sys.platform=='linux':operation=install_linux if args.install else uninstall_linux
    else:parser.error('Protocol registration supports Windows and Linux only.')
    try:print(('Registered: ' if args.install else 'Removed: ')+str(operation(script) if sys.platform=='win32' or args.install else operation()))
    except (OSError,ValueError,subprocess.SubprocessError) as error:parser.error(str(error))

if __name__=='__main__':main()
