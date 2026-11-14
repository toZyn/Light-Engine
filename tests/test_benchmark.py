import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('benchmark_tool', Path(__file__).resolve().parents[1] / 'tools/benchmark.py')
benchmark = importlib.util.module_from_spec(spec)
spec.loader.exec_module(benchmark)


class BenchmarkTest(unittest.TestCase):
    def test_fingerprint_changes_for_content_and_relative_name(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'a').write_bytes(b'123')
            first = benchmark.fingerprint(root)
            self.assertEqual(first, benchmark.fingerprint(root))
            (root / 'a').write_bytes(b'124')
            self.assertNotEqual(first, benchmark.fingerprint(root))
            (root / 'a').write_bytes(b'123')
            (root / 'a').rename(root / 'b')
            self.assertNotEqual(first, benchmark.fingerprint(root))

    def test_comparison_refuses_mismatched_device_content_or_settings(self):
        metadata = dict(device={'gpu': 'fixture'}, width=1280, height=720, preferences={}, contentId='abc', song='fixture', difficulty='normal')
        before = dict(metadata=metadata, frames=60, loadMs=100, p95Ms=20)
        after = dict(metadata=metadata.copy(), frames=60, loadMs=50, p95Ms=18)
        self.assertEqual(benchmark.compare(before, after)['loadMs']['changePercent'], -50)
        for key in ['contentId', 'device', 'preferences', 'width']:
            modified = dict(after, metadata=dict(metadata, **{key: 'different'}))
            with self.assertRaises(ValueError):
                benchmark.compare(before, modified)
        with self.assertRaises(ValueError):
            benchmark.compare(before, dict(after, frames=0))


if __name__ == '__main__':
    unittest.main()
