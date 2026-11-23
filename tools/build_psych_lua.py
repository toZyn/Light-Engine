#!/usr/bin/env python3
"""Compile Psych Engine's own Lua layer to Lua, with Haxe.

This is the alternative to reimplementing Psych's 223 Lua functions by hand.
Psych's `source/psychlua/*.hx` is the authority on what those functions do; the
only thing missing to run it on Light Engine is the outside world it calls into.
`tools/psych-externs/` declares that world as `extern` classes, so Haxe
type-checks Psych against it and emits Lua that calls the engine's own objects.

Why this beats a hand-written port:
  - the behaviour IS Psych's code, so argument coercion, callback ordering and
    edge cases cannot drift;
  - when Psych changes, recompile instead of re-reading a diff.

Proven in this repository already: `funkin/backend/scripts/psych/runtime.lua` is
Haxe 4.3.7 output (Iris) running on LuaJIT, produced by
`tools/build_psych_hscript.py`.

Usage
    tools/build_psych_lua.py --source /path/to/FNF-PsychEngine [--out DIR]

Requires Haxe 4.3.7 and a Psych 1.0.4 checkout (`--source`). Nothing is written
when the compile fails; the failure text is the deliverable in that case.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PSYCH_REF = "1.0.4"
EXPECTED_HAXE = "4.3.7"

# psychlua files that only contain Lua callbacks. FunkinLua.hx itself is the
# host class (it owns the lua_State) and is not part of the shim.
MODULES = [
    "ExtraFunctions",
    "ReflectionFunctions",
    "ShaderFunctions",
    "TextFunctions",
    "DeprecatedFunctions",
    "LuaUtils",
    "FlxAnimateFunctions",
]

# Globals Psych uses without an explicit import. The externs provide the types;
# this list is what the compile has to be allowed to see.
IMPLICIT = [
    "Paths", "FlxG", "FlxCamera", "FlxObject", "FlxBasic", "FlxSprite", "FlxText",
    "FlxSound", "FlxTimer", "FlxTween", "FlxEase", "FlxColor", "FlxSave",
    "FlxRuntimeShader", "BlendMode", "Assets", "Conductor", "ClientPrefs", "Mods",
    "MusicBeatState", "PlayState", "Song", "Note", "FlxTransitionableState",
    "Lua_helper", "Std", "Math", "StringTools", "Reflect", "Type", "StdTypes",
]


def check_haxe(haxe: str) -> str:
    version = subprocess.check_output([haxe, "--version"], text=True).strip()
    if version != EXPECTED_HAXE:
        raise SystemExit(f"expected Haxe {EXPECTED_HAXE}, found {version}")
    return version


def stage(source: Path, work: Path) -> None:
    """Copy the psychlua sources next to the externs and add the implicit imports."""
    package = work / "psychlua"
    package.mkdir(parents=True)
    missing = []
    for name in MODULES:
        origin = source / "source" / "psychlua" / f"{name}.hx"
        if not origin.exists():
            missing.append(str(origin))
            continue
        # Psych calls these classes without importing them (HaxeFlixel resolves
        # them through the class path). Haxe 4 refuses that, so the imports are
        # added here instead of editing the declaration.
        body = origin.read_text(encoding="utf-8")
        imports = "\n".join(f"import {name};" for name in IMPLICIT if name not in body)
        package.joinpath(f"{name}.hx").write_text(imports + "\n" + body, encoding="utf-8")
    if missing:
        raise SystemExit("missing Psych sources:\n  " + "\n  ".join(missing))


def build(haxe: str, work: Path, target: Path) -> tuple[bool, str]:
    command = [
        haxe,
        "-cp", str(ROOT / "tools" / "psych-externs"),
        "-cp", str(work),
        "-D", "lua_vanilla",
        "-D", "lua-jit",
        "-dce", "full",
        "-main", "PsychBridge",
        "-lua", str(target),
    ]
    result = subprocess.run(command, text=True, capture_output=True)
    output = (result.stdout + result.stderr).strip()
    return result.returncode == 0, output


def report(source: Path) -> None:
    psychlua = source / "source" / "psychlua"
    total = 0
    for name in MODULES:
        path = psychlua / f"{name}.hx"
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        callbacks = len(re.findall(r"add_callback\(\s*(?:\w+\s*,\s*)?['\"]", text))
        total += callbacks
        print(f"  {name:24} {callbacks:3} callbacks  {len(text.splitlines()):5} lines")
    print(f"  {'total':24} {total:3} callbacks")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path, help="FNF-PsychEngine checkout")
    parser.add_argument("--out", type=Path, default=ROOT / "build/psych-lua")
    parser.add_argument("--haxe", default="haxe")
    parser.add_argument("--no-clean", action="store_true")
    args = parser.parse_args()

    version = check_haxe(args.haxe)
    print(f"Haxe {version}; Psych {PSYCH_REF}")
    print("callbacks to cover:")
    report(args.source)

    work = args.out / "src"
    if work.exists() and not args.no_clean:
        shutil.rmtree(work)
    work.mkdir(parents=True, exist_ok=True)
    stage(args.source, work)

    target = args.out / "psych-lua.lua"
    ok, output = build(args.haxe, work, target)
    if not ok:
        print("\ncompile FAILED (this is the useful result):", file=sys.stderr)
        print(output, file=sys.stderr)
        return 1

    print(f"\ncompiled -> {target.relative_to(ROOT)} ({target.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
