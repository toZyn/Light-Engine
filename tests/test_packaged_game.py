"""Check shipped bytes for ZIP, fused executable and direct APK asset layouts."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

TOOLS = Path(__file__).resolve().parents[1] / 'tools'
sys.path.insert(0, str(TOOLS))
spec = importlib.util.spec_from_file_location('check_packaged_game', TOOLS / 'check_packaged_game.py')
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class PackagedGameTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / 'main.lua').write_bytes(b'function love.load() end\n')
        (self.root / 'assets').mkdir()
        (self.root / 'assets/pixel.png').write_bytes(b'original\x00bytes')

    def tearDown(self):
        self.temp.cleanup()

    def verify(self, package, android=False):
        with patch.object(checker, 'ROOT', str(self.root)), \
                patch.object(checker, 'collect_files', return_value=['main.lua', 'assets/pixel.png']):
            checker.verify(package, android)

    def package(self, name, prefix='', changed=False, junk=False):
        path = self.root / name
        with zipfile.ZipFile(path, 'w') as archive:
            archive.writestr(prefix + 'main.lua', (self.root / 'main.lua').read_bytes())
            archive.writestr(prefix + 'assets/pixel.png', b'changed' if changed else (self.root / 'assets/pixel.png').read_bytes())
            if junk:
                archive.writestr(prefix + '__pycache__/cached.pyc', b'cache')
        return path

    def test_zip_fused_executable_and_apk_preserve_runtime_bytes(self):
        archive = self.package('game.love')
        self.verify(archive)
        fused = self.root / 'game.exe'
        fused.write_bytes(b'MZ' + b'\x00' * 126 + archive.read_bytes())
        self.verify(fused)
        self.verify(self.package('game.apk', prefix='assets/'), android=True)

    def test_changed_assets_are_rejected(self):
        with self.assertRaisesRegex(ValueError, 'different bytes for assets/pixel.png'):
            self.verify(self.package('changed.love', changed=True))

    def test_development_cache_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'development files'):
            self.verify(self.package('dirty.love', junk=True))


if __name__ == '__main__':
    unittest.main()
