import importlib.util
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('android_manifest',ROOT/'tools/android_manifest.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class ManifestTests(unittest.TestCase):
 def setUp(self):self.original=(ROOT/'tests/fixtures/android-manifest.axml').read_bytes()
 def test_only_game_activity_resize_boolean_changes(self):
  updated=m.enable_game_resize(self.original)
  diffs=[i for i,(a,b) in enumerate(zip(self.original,updated)) if a!=b]
  self.assertEqual(len(updated),len(self.original));self.assertEqual(len(diffs),4)
  self.assertEqual(updated[diffs[0]:diffs[-1]+1],b'\xff'*4)
  self.assertEqual(m.enable_game_resize(updated),updated)
 def test_invalid_manifest_rejected(self):
  for b in [b'',self.original[:100],b'HTML download page']:
   with self.assertRaises(ValueError):m.enable_game_resize(b)
 def test_other_activity_is_not_selected(self):
  # Alter only the UTF-16 activity name, preserving stringpool byte lengths.
  b=self.original.replace('org.love2d.android.GameActivity'.encode('utf-16le'),'org.love2d.android.FakeActivity'.encode('utf-16le'))
  self.assertNotEqual(b,self.original)
  with self.assertRaises(ValueError):m.enable_game_resize(b)
if __name__=='__main__':unittest.main()
