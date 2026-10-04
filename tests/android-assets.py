"""Regression: Android reads the unchanged runtime directly inside its APK."""
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

class AndroidAssetsTests(unittest.TestCase):
 def game(self, path, extra=None):
  contents={'main.lua':b'-- startup\n','conf.lua':b'-- configuration\n','project.lua':b'return {}\n',
            'assets/images/example.png':(ROOT/'android/res/drawable-mdpi/icon.png').read_bytes(),
            'assets/music/example.ogg':b'OggS'+bytes(range(256))*16,'assets/data/example.json':b'{"value":42}'}
  contents.update(extra or {})
  with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
   for name,data in contents.items():z.writestr(name,data)
  return contents
 def test_direct_apk_preserves_resources_native_code_and_has_no_cache_archive(self):
  with tempfile.TemporaryDirectory() as d:
   d=Path(d);game=d/'game.love';expected=self.game(game);base=d/'base.apk';output=d/'result.apk'
   with zipfile.ZipFile(base,'w') as z:
    for name,data in {'assets/game.love':b'old archive','assets/dexopt/baseline.prof':b'profile',
                      'classes.dex':b'original dex','lib/arm64-v8a/liblove.so':b'original JNI',
                      'AndroidManifest.xml':b'original manifest','META-INF/OLD.SF':b'old signature'}.items():z.writestr(name,data)
   result=subprocess.run([sys.executable,str(ROOT/'tools/repack_android.py'),str(base),str(game),str(output),'--direct-assets'],capture_output=True,text=True)
   self.assertEqual(result.returncode,0,result.stderr)
   with zipfile.ZipFile(output) as z:
    self.assertNotIn('assets/game.love',z.namelist(),'game archive triggers a complete private-cache copy')
    for name,data in expected.items():self.assertEqual(z.read('assets/'+name),data)
    for name in ['classes.dex','lib/arm64-v8a/liblove.so','AndroidManifest.xml','assets/dexopt/baseline.prof']:
     with zipfile.ZipFile(base) as old:self.assertEqual(z.read(name),old.read(name))
    self.assertNotIn('META-INF/OLD.SF',z.namelist());self.assertIsNone(z.testzip())
    for name in ['assets/assets/images/example.png','assets/assets/music/example.ogg']:
     self.assertEqual(z.getinfo(name).compress_type,zipfile.ZIP_STORED,'media must permit direct seek without ZIP decompression')
 def test_native_build_stages_same_files_without_nested_archive(self):
  with tempfile.TemporaryDirectory() as d:
   d=Path(d);game=d/'game.love';expected=self.game(game);output=d/'assets'
   result=subprocess.run([sys.executable,str(ROOT/'tools/make_android_assets.py'),str(game),str(output)],capture_output=True,text=True)
   self.assertEqual(result.returncode,0,result.stderr)
   self.assertFalse((output/'game.love').exists())
   self.assertEqual({p.relative_to(output).as_posix():p.read_bytes() for p in output.rglob('*') if p.is_file()},expected)
 def test_unsafe_archive_is_rejected_before_staging_any_file(self):
  for name in ['../escape.png','/escape.png','folder\\escape.png','assets/game.love']:
   with self.subTest(name=name),tempfile.TemporaryDirectory() as d:
    d=Path(d);game=d/'game.love';self.game(game,{name:b'unsafe'});output=d/'assets'
    result=subprocess.run([sys.executable,str(ROOT/'tools/make_android_assets.py'),str(game),str(output)],capture_output=True,text=True)
    self.assertNotEqual(result.returncode,0)
    self.assertFalse(output.exists(),'validation must precede writes')

if __name__=='__main__':unittest.main()
