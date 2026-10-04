"""Portable release tests: official Win64 PE/runtime and a deterministic fixture."""
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import tarfile
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
WIN_RUNTIME = Path(os.environ.get("LOVE_WIN64_RUNTIME", "/workspace/runtime/love-win64.zip"))


class DesktopPackaging(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="desktop packaging ")
        self.work = Path(self.temp.name)
        self.game = self.work / "reviewed game.love"
        with zipfile.ZipFile(self.game, "w") as z:
            z.writestr("main.lua", "function love.load() end\n")
            z.writestr("conf.lua", "function love.conf(t) end\n")
            z.writestr("project.lua", 'return {\n title = "Light Engine",\n version = "1.2.3",\n}\n')
            z.writestr("art/logo.png", (ROOT / "art/logo.png").read_bytes())
        self.runtime = self.work / "Linux runtime"
        (self.runtime / "bin").mkdir(parents=True)
        (self.runtime / "AppRun").write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
        (self.runtime / "AppRun").chmod(0o755)
        elf = bytearray(64); elf[:6] = b"\x7fELF\x02\x01"; struct.pack_into("<H", elf, 18, 62)
        (self.runtime / "bin/love").write_bytes(elf)
        (self.runtime / "bin/love").chmod(0o755)
        (self.runtime / "lib").mkdir()
        (self.runtime / "lib/liblove-11.5.so").write_text("Fixture version marker\n")
        (self.runtime / "license.txt").write_text("Runtime license\n")
        (self.runtime / ".DirIcon").symlink_to("license.txt")

    def tearDown(self):
        self.temp.cleanup()

    def build(self, destination, windows_runtime=WIN_RUNTIME):
        return subprocess.run([
            "python3", str(ROOT / "tools/make_desktop_release.py"),
            "--game", str(self.game), "--windows-runtime", str(windows_runtime),
            "--linux-runtime", str(self.runtime), "--output-dir", str(destination),
        ], text=True, capture_output=True)

    def test_structure_preserves_official_PE_and_appended_game_bytes(self):
        result = self.build(self.work / "output")
        self.assertEqual(result.returncode, 0, result.stderr)
        with zipfile.ZipFile(self.work / "output/Light-Engine-1.2.3-win64.zip") as package, \
                zipfile.ZipFile(WIN_RUNTIME) as runtime:
            prefix = "Light-Engine-1.2.3-win64/"
            exe = package.read(prefix + "Light-Engine.exe")
            original = runtime.read("love-11.5-win64/love.exe")
            self.assertEqual(exe[:len(original)], original)
            self.assertEqual(exe[len(original):], self.game.read_bytes())
            pe = struct.unpack_from("<I", exe, 0x3C)[0]
            self.assertEqual(exe[pe:pe+4], b"PE\x00\x00")
            self.assertEqual(struct.unpack_from("<H", exe, pe+4)[0], 0x8664)
            for member in runtime.namelist():
                if member.endswith(".dll"):
                    self.assertEqual(package.read(prefix + Path(member).name), runtime.read(member))
            manifest = json.loads(package.read(prefix + "distribution.json"))
            self.assertEqual(manifest["gameSha256"], hashlib.sha256(self.game.read_bytes()).hexdigest())
            self.assertEqual(manifest["fusedGameOffset"], len(original))
            self.assertEqual(package.read(prefix + "logo.png"), (ROOT / "art/logo.png").read_bytes())

    def test_reproducibility_and_launcher_arguments_with_spaces(self):
        first, second = self.work / "first output", self.work / "second output"
        for destination in [first, second]:
            result = self.build(destination)
            self.assertEqual(result.returncode, 0, result.stderr)
        for name in ["Light-Engine-1.2.3-win64.zip", "Light-Engine-1.2.3-linux-x64.tar.gz"]:
            self.assertEqual((first / name).read_bytes(), (second / name).read_bytes())
        archive = first / "Light-Engine-1.2.3-linux-x64.tar.gz"
        with tarfile.open(archive) as package:
            options = {"filter": "data"} if hasattr(tarfile, "data_filter") else {}
            package.extractall(self.work / "extracted path with spaces", **options)
        bundle = self.work / "extracted path with spaces/Light-Engine-1.2.3-linux-x64"
        self.assertEqual((bundle / "game.love").read_bytes(), self.game.read_bytes())
        self.assertTrue((bundle / "runtime/.DirIcon").is_symlink())
        result = subprocess.run([str(bundle / "launch.sh"), "argument with spaces", "$(literal)"],
                                text=True, capture_output=True, check=True,
                                env={"PATH": "/usr/bin:/bin", "APPDIR": "/wrong app", "FUSE_PATH": "/wrong game"})
        self.assertEqual(result.stdout.splitlines(), ["--fused", str(bundle / "game.love"),
                                                     "argument with spaces", "$(literal)"])

    def test_invalid_game_fails_without_output(self):
        self.game.write_bytes(b"not a zip")
        result = self.build(self.work / "invalid output")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(list((self.work / "invalid output").glob("*.zip")))

    def test_x86_runtime_is_rejected_without_output(self):
        invalid = self.work / "wrong architecture.zip"
        with zipfile.ZipFile(WIN_RUNTIME) as original, zipfile.ZipFile(invalid, "w") as modified:
            for name in original.namelist():
                data = original.read(name)
                if name.endswith("/love.exe"):
                    data = bytearray(data)
                    pe = struct.unpack_from("<I", data, 0x3C)[0]
                    struct.pack_into("<H", data, pe + 4, 0x14C)
                modified.writestr(name, data)
        result = self.build(self.work / "invalid architecture", invalid)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("x64 PE", result.stderr)
        self.assertFalse(list((self.work / "invalid architecture").glob("*.zip")))


if __name__ == "__main__":
    unittest.main()
