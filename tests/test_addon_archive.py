"""Creators can package their own addon without renaming its module to overlay.lua."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]


class AddonArchiveTests(unittest.TestCase):
    def test_custom_addon_packages_its_metadata_and_module(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / 'custom library'
            (source / 'modules').mkdir(parents=True)
            (source / 'meta.json').write_text('{"name":"Custom library"}')
            (source / 'modules/timing.lua').write_text('return {value=42}')
            (source / '.DS_Store').write_bytes(b'junk')
            output = root / 'library.zip'
            result = subprocess.run([sys.executable, str(ROOT / 'tools/make_addon_release.py'),
                                     str(output), '--source', str(source)], text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            with zipfile.ZipFile(output) as archive:
                self.assertEqual(set(archive.namelist()), {
                    'custom library/meta.json', 'custom library/modules/timing.lua'
                })
                self.assertEqual(archive.read('custom library/modules/timing.lua'), b'return {value=42}')

    def test_missing_source_preserves_existing_archive(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = root / 'library.zip'
            output.write_bytes(b'previous archive')
            result = subprocess.run([sys.executable, str(ROOT / 'tools/make_addon_release.py'),
                                     str(output), '--source', str(root / 'missing')], text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Addon directory does not exist', result.stderr)
            self.assertEqual(output.read_bytes(), b'previous archive')


if __name__ == '__main__':
    unittest.main()
