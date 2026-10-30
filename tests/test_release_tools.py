import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import stamp_release_version as srv  # noqa: E402


class ReleaseToolsTests(unittest.TestCase):
    def test_current_project_lua_has_valid_release_version(self):
        source = (ROOT / "project.lua").read_text(encoding="utf-8")
        version, code = srv.parse_project_lua(source)
        self.assertEqual(version, "0.2.0")
        self.assertGreaterEqual(code, 200)

    def test_choose_release_version_keeps_base_when_new_or_same_sha(self):
        self.assertEqual(
            srv.choose_release_version("0.2.0", 200, "abc123", None, False, set()),
            ("0.2.0", 200),
        )
        self.assertEqual(
            srv.choose_release_version("0.2.0", 200, "abc123", "abc123", False, {"v0.2.0"}),
            ("0.2.0", 200),
        )
        self.assertEqual(
            srv.choose_release_version("0.2.0", 200, "abc123", "old999", True, {"v0.2.0"}),
            ("0.2.0", 200),
        )

    def test_choose_release_version_auto_increments_when_tag_points_elsewhere(self):
        self.assertEqual(
            srv.choose_release_version("0.2.0", 200, "newsha", "oldsha", False, {"v0.2.0"}),
            ("0.2.0-r1", 201),
        )
        self.assertEqual(
            srv.choose_release_version(
                "0.2.0",
                200,
                "newsha",
                "oldsha",
                False,
                {"v0.2.0", "v0.2.0-r1", "v0.2.0-r2"},
            ),
            ("0.2.0-r3", 203),
        )
        self.assertEqual(
            srv.choose_release_version(
                "0.1.16-advanced.8",
                124,
                "newsha",
                "oldsha",
                False,
                {"v0.1.16-advanced.8"},
            ),
            ("0.1.16-advanced.8.r1", 125),
        )

    def test_resolve_and_apply_cli(self):
        with tempfile.TemporaryDirectory() as tmp:
            work = Path(tmp)
            proj = work / "project.lua"
            proj.write_text(
                'return {\n\ttitle = "Light Engine",\n\tversion = "0.2.0",\n\tandroidVersionCode = 200,\n}\n',
                encoding="utf-8",
            )
            meta = work / "release-meta.json"
            gh_out = work / "github_output.txt"

            res = subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "tools/stamp_release_version.py"),
                    "--project",
                    str(proj),
                    "--resolve",
                    "--output",
                    str(meta),
                    "--github-output",
                    str(gh_out),
                ],
                text=True,
                capture_output=True,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            payload = json.loads(meta.read_text(encoding="utf-8"))
            self.assertEqual(payload["version"], "0.2.0")
            self.assertEqual(payload["tag"], "v0.2.0")
            self.assertEqual(payload["androidVersionCode"], 200)
            self.assertIn("tag=v0.2.0\n", gh_out.read_text(encoding="utf-8"))

            payload["version"] = "0.2.0-r4"
            payload["androidVersionCode"] = 204
            meta.write_text(json.dumps(payload), encoding="utf-8")

            apply_res = subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "tools/stamp_release_version.py"),
                    "--project",
                    str(proj),
                    "--apply",
                    str(meta),
                ],
                text=True,
                capture_output=True,
            )
            self.assertEqual(apply_res.returncode, 0, apply_res.stderr)
            stamped_ver, stamped_code = srv.parse_project_lua(proj.read_text(encoding="utf-8"))
            self.assertEqual(stamped_ver, "0.2.0-r4")
            self.assertEqual(stamped_code, 204)

    def test_make_modding_kit_archive_and_bundle_population(self):
        with tempfile.TemporaryDirectory() as tmp:
            work = Path(tmp)
            archive_path = work / "Light-Engine-0.2.0-modding-kit.zip"
            bundle_dir = work / "Light Engine"
            bundle_dir.mkdir()
            (bundle_dir / "Light Engine.exe").write_bytes(b"MZfake")

            res = subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "tools/make_modding_kit.py"),
                    "--archive",
                    str(archive_path),
                    "--populate-bundle",
                    str(bundle_dir),
                ],
                text=True,
                capture_output=True,
            )
            self.assertEqual(res.returncode, 0, res.stderr)
            self.assertTrue(archive_path.is_file())

            with zipfile.ZipFile(archive_path) as zf:
                names = set(zf.namelist())
            self.assertTrue(all("\\" not in n for n in names))
            self.assertIn("Light-Engine-Modding-Kit/tools/create_mod.py", names)
            self.assertIn("Light-Engine-Modding-Kit/docs/crear-mods.md", names)
            self.assertIn("Light-Engine-Modding-Kit/docs/modding-compatibility.md", names)
            self.assertIn("Light-Engine-Modding-Kit/CHANGELOG.md", names)
            self.assertTrue(any(n.startswith("Light-Engine-Modding-Kit/examples/") for n in names))

            self.assertEqual((bundle_dir / "Light Engine.exe").read_bytes(), b"MZfake")
            self.assertTrue((bundle_dir / "tools/create_mod.py").is_file())
            self.assertTrue((bundle_dir / "docs/crear-mods.md").is_file())
            self.assertTrue((bundle_dir / "examples/compat-mod/meta.json").is_file())


if __name__ == "__main__":
    unittest.main()
