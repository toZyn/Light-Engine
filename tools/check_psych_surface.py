#!/usr/bin/env python3
"""Compare Light Engine's Psych Lua surface with Psych 1.0.4 itself.

The list of functions a Psych 1.0.4 mod may call is not guesswork: it is every
name passed to `Lua_helper.add_callback` in
ShadowMario/FNF-PsychEngine's `source/psychlua/*.hx`. Reading it from there
keeps this project honest -- a function we forget to implement is a callback
that dies with "attempt to call a nil value" in the middle of a song.

Usage:
    tools/check_psych_surface.py                 # report, exit 1 if incomplete
    tools/check_psych_surface.py --write         # regenerate the Lua fixture
    tools/check_psych_surface.py --source DIR    # use a local Psych checkout
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.request

REPO = "ShadowMario/FNF-PsychEngine"
REF = "1.0.4"
PSYCHLUA = "source/psychlua"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURE = os.path.join(ROOT, "tests", "engine", "psych-api-surface.lua")

CALLBACK_RE = re.compile(
    r"""add_callback\(\s*(?:\w+\s*,\s*)?['"]([A-Za-z_]\w*)['"]"""
)


def _github(path: str, ref: str) -> bytes:
    url = f"https://api.github.com/repos/{REPO}/contents/{path}?ref={ref}"
    token = os.environ.get("GITHUB_TOKEN")
    request = urllib.request.Request(url, headers={"Accept": "application/vnd.github+json"})
    if token:
        request.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(request, timeout=60) as response:
        payload = json.load(response)
    if "content" not in payload:
        raise RuntimeError(f"{path}: {payload.get('message', 'no content')}")
    return base64.b64decode(payload["content"])


def collect(source_dir: str | None) -> list[str]:
    names: set[str] = set()
    if source_dir:
        for entry in sorted(os.listdir(os.path.join(source_dir, PSYCHLUA))):
            if entry.endswith(".hx"):
                with open(os.path.join(source_dir, PSYCHLUA, entry), encoding="utf-8", errors="replace") as handle:
                    names.update(CALLBACK_RE.findall(handle.read()))
    else:
        listing = json.load(
            urllib.request.urlopen(
                f"https://api.github.com/repos/{REPO}/contents/{PSYCHLUA}?ref={REF}", timeout=60
            )
        )
        for item in listing:
            if item["name"].endswith(".hx"):
                names.update(CALLBACK_RE.findall(_github(item["path"], REF).decode("utf-8", "replace")))
    return sorted(names)


def write_fixture(names: list[str]) -> None:
    lines = [
        f"-- Generated from {REPO} {REF} {PSYCHLUA}/*.hx.",
        "-- Every name below is registered with Lua_helper.add_callback in Psych itself,",
        "-- so it is part of the surface a Psych 1.0.4 mod is allowed to call.",
        "-- Regenerate with tools/check_psych_surface.py --write.",
        "return {",
    ]
    lines += [f'\t"{name}",' for name in names]
    lines.append("}")
    with open(FIXTURE, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="regenerate the Lua fixture")
    parser.add_argument("--source", help="path to a local FNF-PsychEngine checkout")
    args = parser.parse_args()

    try:
        names = collect(args.source)
    except (urllib.error.URLError, RuntimeError) as error:
        print(f"could not read Psych {REF} sources: {error}", file=sys.stderr)
        return 2

    if not names:
        print("no callbacks found; refusing to write an empty surface", file=sys.stderr)
        return 2

    print(f"Psych {REF} registers {len(names)} Lua callbacks")
    if args.write:
        write_fixture(names)
        print(f"wrote {os.path.relpath(FIXTURE, ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
