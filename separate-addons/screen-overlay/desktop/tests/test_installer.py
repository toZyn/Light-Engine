import sys
import ctypes
import ctypes.util
import json
import os
import time
import tempfile
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from install_protocol import linux_entry, windows_command, install_linux, uninstall_linux

class InstallerTests(unittest.TestCase):
    def test_windows_handler_quotes_python_script_and_uri_separately(self):
        result=windows_command(r'C:\Python Space\pythonw.exe',r'C:\Mods Space\companion.py')
        self.assertEqual(result,r'"C:\Python Space\pythonw.exe" "C:\Mods Space\companion.py" --uri "%1"')
        with self.assertRaises(ValueError):windows_command('python"injection','script')
    def test_linux_desktop_entry_escapes_spaces_field_codes_and_shell_characters(self):
        entry=linux_entry('/space python/py%thon','/folder $literal`/companion.py')
        self.assertIn(r'Exec="/space python/py%%thon" "/folder \\$literal\\`/companion.py" --uri %u',entry)
        self.assertIn('MimeType=x-scheme-handler/lightengine-overlay;',entry)
        self.assertNotIn('/bin/sh',entry)
    def test_explicit_install_and_uninstall_touch_only_owned_entry(self):
        with tempfile.TemporaryDirectory() as directory:
            calls=[];root=Path(directory);script=root/'my folder'/'companion.py'
            script.parent.mkdir();script.write_text('# fixture')
            path=install_linux(script,data_home=root,run=lambda args,**kwargs:calls.append(args))
            self.assertTrue(path.exists());self.assertEqual(calls[0][0:2],['xdg-mime','default'])
            unrelated=path.parent/'unrelated.desktop';unrelated.write_text('keep')
            uninstall_linux(data_home=root)
            self.assertFalse(path.exists());self.assertTrue(unrelated.exists())
    @unittest.skipUnless(sys.platform=='linux' and ctypes.util.find_library('gio-2.0'),'Native GIO launcher is Linux-specific')
    def test_native_linux_desktop_launcher_preserves_uri_and_literal_path_characters(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)/'space $literal` % name';root.mkdir()
            script=root/'record.py';record=root/'argv.json'
            script.write_text('import json,sys\nfrom pathlib import Path\nPath(__file__).with_name("argv.json").write_text(json.dumps(sys.argv[1:]))\n')
            entry=root/'handler.desktop';entry.write_text(linux_entry(sys.executable,script))
            gio=ctypes.CDLL(ctypes.util.find_library('gio-2.0'));glib=ctypes.CDLL(ctypes.util.find_library('glib-2.0'))
            gio.g_desktop_app_info_new_from_filename.argtypes=[ctypes.c_char_p];gio.g_desktop_app_info_new_from_filename.restype=ctypes.c_void_p
            gio.g_app_info_launch_uris.argtypes=[ctypes.c_void_p,ctypes.c_void_p,ctypes.c_void_p,ctypes.POINTER(ctypes.c_void_p)]
            gio.g_app_info_launch_uris.restype=ctypes.c_int
            glib.g_list_append.argtypes=[ctypes.c_void_p,ctypes.c_void_p];glib.g_list_append.restype=ctypes.c_void_p
            glib.g_list_free.argtypes=[ctypes.c_void_p];gio.g_object_unref.argtypes=[ctypes.c_void_p]
            app=gio.g_desktop_app_info_new_from_filename(os.fsencode(entry));self.assertTrue(app,'Native desktop parser rejected entry')
            uri='lightengine-overlay://connect?token='+'a'*64+'&label=Space%20%26%20literal'
            buffer=ctypes.create_string_buffer(uri.encode());items=glib.g_list_append(None,ctypes.cast(buffer,ctypes.c_void_p))
            error=ctypes.c_void_p()
            try:self.assertTrue(gio.g_app_info_launch_uris(app,items,None,ctypes.byref(error)),'Native desktop launch failed')
            finally:glib.g_list_free(items);gio.g_object_unref(app)
            deadline=time.monotonic()+3
            while not record.exists() and time.monotonic()<deadline:time.sleep(.02)
            self.assertTrue(record.exists());self.assertEqual(json.loads(record.read_text()),['--uri',uri])

if __name__=='__main__':unittest.main()
