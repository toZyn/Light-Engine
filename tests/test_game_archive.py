"""Release archives must not ship build caches or replace a valid output on failure."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('game_archive', ROOT / 'tools/make_game_love.py')
packager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packager)


class GameArchiveTests(unittest.TestCase):
    def test_build_caches_are_excluded_but_nested_runtime_mods_remain(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in packager.REQUIRED_ENTRIES:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b'original fixture')
            junk = ['.ci/love/AppRun', '.superpowers/session.json',
                    'funkin/__pycache__/cached.pyc', 'assets/.DS_Store', 'old.apk.idsig']
            for name in junk:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b'build-only')
            output = root / 'game.love'
            with patch.object(packager, 'ROOT', str(root)):
                self.assertEqual(packager.build(str(output)), 0)
            with zipfile.ZipFile(output) as archive:
                for name in junk:
                    self.assertNotIn(name, archive.namelist())
                self.assertEqual(archive.read('funkin/ui/mods/modcard.lua'), b'original fixture')

    def test_incomplete_source_preserves_existing_release(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'main.lua').write_text('-- incomplete source')
            output = root / 'game.love'
            output.write_bytes(b'previous valid release')
            with patch.object(packager, 'ROOT', str(root)):
                self.assertEqual(packager.build(str(output)), 1)
            self.assertEqual(output.read_bytes(), b'previous valid release')
            self.assertFalse((root / 'game.love.tmp').exists())


if __name__ == '__main__':
    unittest.main()
