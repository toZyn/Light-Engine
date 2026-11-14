import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'tools' / (name + '.py'))
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded

class SceneTools(unittest.TestCase):
    def test_manifest_reports_missing_files_and_bad_shapes(self):
        tool = module('scene_manifest')
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.assertEqual(tool.validate({'assets': [['image', 'missing']]}, [root]), ['assets[0]: missing image missing'])
            errors = tool.validate({'assets': {'x': 'y'}, 'shaders': [False]}, [root])
            self.assertEqual(len(errors), 2)
            (root / 'images').mkdir()
            (root / 'images' / 'tile.png').write_bytes(b'fixture')
            self.assertEqual(tool.validate({'assets': [['image', 'tile']]}, [root]), [])

    def test_comparison_rejects_mismatched_device_or_content(self):
        tool = module('compare_benchmarks')
        a = {'schema': 1, 'completed': True, 'context': {'device': 'one', 'content': 'same', 'cache': 'cold'}, 'frames': {'count': 10}}
        b = json.loads(json.dumps(a))
        self.assertEqual(tool.mismatches(a, b), [])
        b['context']['device'] = 'other'
        self.assertIn('device', tool.mismatches(a, b))
        b['context']['content'] = 'different'
        self.assertIn('content', tool.mismatches(a, b))

if __name__ == '__main__':
    unittest.main()
