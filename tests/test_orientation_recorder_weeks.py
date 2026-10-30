"""Regression tests for Android landscape orientation, screen recording settings, and week script/shader fixes."""
from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"


class OrientationRecorderAndWeekFixesTests(unittest.TestCase):
    def test_android_manifest_and_launcher_enforce_sensor_landscape(self):
        tree = ET.parse(ROOT / "android/AndroidManifest.xml")
        activities = {
            el.attrib[f"{ANDROID_NS}name"]: el
            for el in tree.findall(".//activity")
        }
        for name in (
            "org.love2d.android.StoragePermissionActivity",
            "org.love2d.android.GameActivity",
        ):
            self.assertIn(name, activities)
            act = activities[name]
            self.assertEqual(act.attrib.get(f"{ANDROID_NS}screenOrientation"), "${ORIENTATION}")
            cfg = act.attrib.get(f"{ANDROID_NS}configChanges", "")
            self.assertIn("orientation", cfg)
            self.assertIn("screenSize", cfg)

        gradle_props = (ROOT / "android/gradle.properties.example").read_text(encoding="utf-8")
        self.assertIn("app.orientation=sensorLandscape", gradle_props)

        java_src = (ROOT / "android/StoragePermissionActivity.java").read_text(encoding="utf-8")
        self.assertIn("SCREEN_ORIENTATION_SENSOR_LANDSCAPE", java_src)

    def test_mobile_window_mode_locks_landscape_and_polls_surface_resize(self):
        funkin_init = (ROOT / "funkin/init.lua").read_text(encoding="utf-8")
        self.assertIn("fullscreen = isMobile or ClientPrefs.data.fullscreen", funkin_init)
        self.assertIn("resizable = not isMobile", funkin_init)
        self.assertIn("game.resize(sw, sh)", funkin_init)

    def test_shaders_avoid_gles3_s0023_precision_conflicts(self):
        for frag_name in ("rain.frag", "wiggle.frag"):
            src = (ROOT / "assets/shaders" / frag_name).read_text(encoding="utf-8")
            self.assertNotRegex(src, r"#pragma\s+language\s+glsl3\s*;")
            self.assertNotRegex(src, r"(?m)^\s*precision\s+highp\s+float\s*;")
            self.assertRegex(src, r"vec4\s+effect\s*\(\s*vec4\s+\w+\s*,\s*Image\s+\w+\s*,\s*vec2\s+\w+\s*,\s*vec2\s+\w+\s*\)")

    def test_weekend1_and_cutscene_bugs_are_fixed(self):
        play_src = (ROOT / "funkin/states/play.lua").read_text(encoding="utf-8")
        self.assertIn('"images/" .. data.sprite .. "/Animation.json"', play_src)
        self.assertNotIn("select(7, anim)", play_src)

        for char_script in ("darnell-blazin.lua", "pico-blazin.lua"):
            src = (ROOT / "assets/data/characters" / char_script).read_text(encoding="utf-8")
            self.assertNotIn("game.camera.shake(", src)
            self.assertIn("game.camera:shake(", src)
            self.assertNotIn("not type:sub(1, 10) ==", src)

        philly = (ROOT / "assets/data/stages/phillyStreets.lua").read_text(encoding="utf-8")
        self.assertNotIn("not setting == \"shader\"", philly)
        self.assertIn('"puddle"', philly)

        puddle = (ROOT / "assets/data/classes/puddlething.lua").read_text(encoding="utf-8")
        self.assertIn("self.copyFrom.simple = false", puddle)

        abot = (ROOT / "assets/data/classes/abot.lua").read_text(encoding="utf-8")
        self.assertNotIn('self.abot.animation.curAnim.name ~= "pupilRight"', abot)

        guns = (ROOT / "assets/data/cutscenes/guns.lua").read_text(encoding="utf-8")
        self.assertIn("state.camFollow:set(dadX + 380, dadY + 170)", guns)

    def test_recording_options_are_english_and_conditional(self):
        rec_ui = (ROOT / "funkin/ui/options/recording.lua").read_text(encoding="utf-8")
        self.assertIn('"Gameplay only (No UI)"', rec_ui)
        self.assertIn('"Entire game"', rec_ui)
        self.assertIn('"Capture mode"', rec_ui)
        self.assertIn('"Resolution scale"', rec_ui)
        self.assertIn('"Frame rate"', rec_ui)

        opts_ui = (ROOT / "funkin/ui/options/init.lua").read_text(encoding="utf-8")
        self.assertIn("function Options:syncRecordingTab()", opts_ui)


if __name__ == "__main__":
    unittest.main()
