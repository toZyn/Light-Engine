"""The native runner must report setup errors before starting a game."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("engine_runner", ROOT / "tools/run_engine_tests.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class EngineRunnerTests(unittest.TestCase):
    def test_missing_fixture_is_reported_before_launch(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.object(runner, "ROOT", root), patch.object(sys, "argv", [
                "run_engine_tests.py", "--love", sys.executable,
                "--logs", str(root / "logs"), "audio"
            ]), patch.object(runner.subprocess, "run") as launch:
                with self.assertRaises(SystemExit) as failure:
                    runner.main()
                self.assertEqual(failure.exception.code, 2)
                launch.assert_not_called()

    def test_missing_runtime_has_an_actionable_error(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixture = root / "tests/engine/audio.lua"
            fixture.parent.mkdir(parents=True)
            fixture.write_text("-- fixture\n")
            with patch.object(runner, "ROOT", root), patch.object(sys, "argv", [
                "run_engine_tests.py", "--love", str(root / "missing-love"),
                "--logs", str(root / "logs"), "audio"
            ]):
                with self.assertRaises(SystemExit) as failure:
                    runner.main()
                self.assertEqual(failure.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
