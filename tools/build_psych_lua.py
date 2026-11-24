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

def check_haxe(haxe: str) -> str:
    version = subprocess.check_output([haxe, "--version"], text=True).strip()
    if version != EXPECTED_HAXE:
        raise SystemExit(f"expected Haxe {EXPECTED_HAXE}, found {version}")
    return version


# Imports that resolve against Haxe's stdlib or the externs, not the engine.
ENGINE_FREE_IMPORT = re.compile(r"\s*import\s+(haxe\.|Type\.|Std\.)")


def stage(source: Path, work: Path) -> None:
    """Copy the psychlua sources, dropping the imports that point into the engine.

    Psych's files `import` engine packages (`flixel.util.FlxSave`,
    `objects.Character`, `backend.WeekData`, ...). Stripping those instead of
    faking them is deliberate: the compile then *names* every engine type this
    layer still needs, which is the measurement this job exists to produce.
    """
    package = work / "psychlua"
    package.mkdir(parents=True)
    missing = []
    for name in MODULES:
        origin = source / "source" / "psychlua" / f"{name}.hx"
        if not origin.exists():
            missing.append(str(origin))
            continue
        body = origin.read_text(encoding="utf-8")
        lines = body.splitlines()
        # `package` has to stay first; imports go right after it.
        decl = next((l for l in lines if re.match(r"\s*package\s", l)), "package psychlua;")
        # Keep the imports that belong to Haxe's own standard library: those
        # types exist, and dropping them only invents errors. Everything that
        # points into the engine is still stripped, so the compiler keeps
        # naming the engine surface instead of stopping at the import.
        body_lines = [l for l in lines
                      if not re.match(r"\s*package\s", l)
                      and not (re.match(r"\s*import\s", l)
                               and not ENGINE_FREE_IMPORT.match(l))]
        # No imports are added. Haxe resolves a bare type name first in the
        # file's own package, then at the root of the class path, which is
        # exactly where the externs live -- so `Paths` and `FlxSprite` in
        # `package psychlua` reach them without a declaration. Adding
        # `import Paths;` here made the compiler resolve psychlua.Paths instead
        # and report the root type as redefined.
        # Two things HaxeFlixel gave Psych for free and Haxe 4 needs spelled out:
        # `.trim()`/`.replace()` on strings (StringTools as a `using`), and the
        # bare `LEFT`/`CENTER` text alignment constructors (wildcard import).
        # Everything else resolves by falling back to the root of the class
        # path, which is where the externs live.
        header = [decl, "using StringTools;",
                  "import TextAlign.*;", "import AssetType.*;",
                  "import FlxGamepadInputID.*;", "import FlxTweenType.*;", "import BlendMode.*;"]
        package.joinpath(f"{name}.hx").write_text(
            "\n".join(header + body_lines), encoding="utf-8")
    if missing:
        raise SystemExit("missing Psych sources:\n  " + "\n  ".join(missing))


# Psych wraps whole files in these flags, so without them the shim silently omits
# features: FlxAnimateFunctions, for instance, is entirely inside `#if flxanimate`.
# The set matches what a normal Psych build defines.
PSYCH_DEFINES = [
    "LUA_ALLOWED",
    "MODS_ALLOWED",
    "HSCRIPT_ALLOWED",
    "flxanimate",
    "FLX_PITCH",
    "VIDEOS_ALLOWED",
]


def build(haxe: str, work: Path, target: Path) -> tuple[bool, str]:
    command = [
        haxe,
        "-cp", str(ROOT / "tools" / "psych-externs"),
        "-cp", str(work),
        "-D", "lua_vanilla",
        "-D", "lua-jit",
        *[arg for d in PSYCH_DEFINES for arg in ("-D", d)],
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


def annotate(title: str, message: str) -> None:
    """Surface a failure where CI will keep it.

    Run logs are not readable from every client and the uploaded log can be out
    of reach, so the builder reports its own failure as an annotation. A single
    line per call, which is all GitHub keeps anyway.
    """
    import os
    if not os.environ.get("GITHUB_ACTIONS"):
        return
    flat = " / ".join(line.strip() for line in message.splitlines() if line.strip())
    print(f"::error title={title}::{flat[:1200]}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path, help="FNF-PsychEngine checkout")
    parser.add_argument("--out", type=Path, default=ROOT / "build/psych-lua")
    parser.add_argument("--haxe", default="haxe")
    parser.add_argument("--no-clean", action="store_true")
    args = parser.parse_args()

    try:
        return run(args)
    except SystemExit as exc:
        if exc.code not in (0, None):
            annotate("builder", str(exc.code))
        raise
    except Exception as exc:
        # A crash in the builder is not a compile result, and it must not look
        # like one: say what broke instead of leaving an empty error list.
        annotate(type(exc).__name__, str(exc))
        raise


def run(args) -> int:
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
        print("\ncompile FAILED:", file=sys.stderr)
        print(output, file=sys.stderr)
        first = [l for l in output.splitlines() if re.search(r"\.hx:\d+:", l)]
        annotate(f"compile failed ({len(first)} errors)", first[0] if first else output)
        return 1

    try:
        shown = target.resolve().relative_to(ROOT)
    except ValueError:
        shown = target
    print(f"\ncompiled -> {shown} ({target.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
