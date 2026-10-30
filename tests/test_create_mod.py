"""Tests for tools/create_mod.py mod scaffolding utility."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("create_mod", ROOT / "tools/create_mod.py")
mod_tool = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod_tool)


class CreateModTests(unittest.TestCase):
    def test_scaffolds_complete_mod_structure(self):
        with tempfile.TemporaryDirectory() as tmp:
            mods_root = Path(tmp) / "mods"
            created = mod_tool.create_mod(
                mods_root,
                "Mi Mod Genial!",
                "Mi Mod Genial",
                author="Tester",
                song_name="Mi Cancion",
            )
            self.assertEqual(created.name, "mi-mod-genial")
            meta = json.loads((created / "meta.json").read_text(encoding="utf-8"))
            self.assertEqual(meta["name"], "Mi Mod Genial")
            self.assertTrue((created / "data/weeks/week1.json").is_file())
            self.assertTrue((created / "songs/mi-cancion/meta.json").is_file())
            self.assertTrue((created / "songs/mi-cancion/charts/normal.json").is_file())
            self.assertTrue((created / "songs/mi-cancion/script.lua").is_file())
            self.assertTrue((created / "data/scripts/global.lua").is_file())

    def test_refuses_to_overwrite_existing_mod(self):
        with tempfile.TemporaryDirectory() as tmp:
            mods_root = Path(tmp) / "mods"
            mod_tool.create_mod(mods_root, "dup-mod", "Dup Mod")
            with self.assertRaises(FileExistsError):
                mod_tool.create_mod(mods_root, "dup-mod", "Dup Mod")


if __name__ == "__main__":
    unittest.main()
