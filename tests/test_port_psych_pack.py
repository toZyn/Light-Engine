import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('port_psych_pack', ROOT / 'tools/port_psych_pack.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class PsychPortTests(unittest.TestCase):
    def test_slugs_and_difficulties(self):
        self.assertEqual(module.slug('My Song!'), 'my-song')
        self.assertEqual(module.chart_difficulty('my-song.json', 'My Song!'), 'normal')
        self.assertEqual(module.chart_difficulty('my-song-hard.json', 'My Song!'), 'hard')
        self.assertEqual(module.chart_difficulty('my-song-erect.json', 'My Song!'), 'erect')

    def test_structural_port_preserves_original_and_is_non_destructive(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            src = base / 'original'
            (src / 'data' / 'My Song').mkdir(parents=True)
            (src / 'songs' / 'My Song').mkdir(parents=True)
            (src / 'characters').mkdir()
            (src / 'stages').mkdir()
            (src / 'weeks').mkdir()
            (src / 'scripts').mkdir()
            chart = {'song': {'song': 'My Song', 'bpm': 125, 'notes': [{'mustHitSection': True, 'sectionNotes': [[200, 4, 0]]}]}}
            for name in ('My Song.json', 'My Song-hard.json'):
                (src / 'data' / 'My Song' / name).write_text(json.dumps(chart))
            (src / 'songs' / 'My Song' / 'Inst.ogg').write_bytes(b'audio')
            (src / 'characters' / 'z.json').write_text('{}')
            (src / 'stages' / 'test.json').write_text('{}')
            (src / 'weeks' / 'week1.json').write_text('{"songs": [["My Song", "z", [3, 2, 1]]]}')
            (src / 'scripts' / 'custom.lua').write_text('function onCreate() runHaxeCode("unused") end')
            target = base / 'port'
            stats = module.convert(src, target)
            self.assertEqual(stats['songs'], 1)
            self.assertEqual(stats['charts'], 2)
            self.assertEqual(stats['lua_scripts'], 1)
            self.assertEqual(stats['features']['runHaxeCode'], 1)
            self.assertTrue((target / 'songs/my-song/charts/normal.json').is_file())
            self.assertTrue((target / 'songs/my-song/charts/hard.json').is_file())
            self.assertEqual((target / 'songs/my-song/Inst.ogg').read_bytes(), b'audio')
            self.assertTrue((target / 'data/characters/z.json').exists())
            self.assertTrue((target / 'data/stages/test.json').exists())
            self.assertTrue((target / 'data/weeks/weeks/week1.json').exists())
            self.assertTrue((target / 'psych-legacy/scripts/custom.lua').exists())
            self.assertFalse((target / 'data/scripts/custom.lua').exists())
            self.assertEqual(json.loads((target / 'meta.json').read_text())['name'], 'original')
            with self.assertRaises(FileExistsError):
                module.convert(src, target)
            self.assertTrue((src / 'scripts/custom.lua').exists())

if __name__ == '__main__':
    unittest.main()
