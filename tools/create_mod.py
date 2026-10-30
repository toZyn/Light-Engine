#!/usr/bin/env python3
"""Scaffold a ready-to-use Light Engine mod folder."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9\-_]+", "-", value.strip().lower()).strip("-")
    return slug or "my-mod"


def create_mod(
    dest_root: Path,
    mod_id: str,
    name: str,
    author: str = "Modder",
    description: str = "Un mod creado con Light Engine.",
    song_name: str = "demo-song",
) -> Path:
    slug = slugify(mod_id)
    song_slug = slugify(song_name)
    mod_dir = dest_root / slug
    if mod_dir.exists():
        raise FileExistsError(f"Mod folder already exists: {mod_dir}")

    for sub in (
        f"songs/{song_slug}/charts",
        "data/weeks",
        "data/characters",
        "data/stages",
        "data/events",
        "data/notetypes",
        "data/cutscenes",
        "data/scripts",
        "images/characters",
        "images/icons",
        "images/menus/storymenu/weeks",
        "sounds",
        "music",
        "fonts",
    ):
        (mod_dir / sub).mkdir(parents=True, exist_ok=True)

    (mod_dir / "meta.json").write_text(
        json.dumps(
            {
                "name": name,
                "description": description,
                "author": author,
                "version": "1.0.0",
                "color": "#38BDF8",
            },
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )

    (mod_dir / "data/weeks/week1.json").write_text(
        json.dumps(
            {
                "name": name.upper(),
                "sprite": "week1",
                "chars": ["dad", "bf", "gf"],
                "songs": [[song_slug, "dad", [146, 113, 253]]],
                "difficulties": ["Easy", "Normal", "Hard"],
            },
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )

    (mod_dir / f"songs/{song_slug}/meta.json").write_text(
        json.dumps(
            {
                "songName": song_name,
                "difficulties": ["easy", "normal", "hard"],
                "stage": "stage",
                "skin": "default",
                "characters": {
                    "player": "bf",
                    "opponent": "dad",
                    "girlfriend": "gf",
                },
            },
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )

    normal_chart = {
        "song": {
            "song": song_slug,
            "bpm": 120,
            "speed": 2.2,
            "needsVoices": False,
            "player1": "bf",
            "player2": "dad",
            "gfVersion": "gf",
            "stage": "stage",
            "skin": "default",
            "format": "psych_v1",
            "notes": [
                {
                    "sectionBeats": 4,
                    "mustHitSection": False,
                    "sectionNotes": [
                        [0, 4, 0],
                        [500, 5, 0],
                        [1000, 6, 0],
                        [1500, 7, 0],
                    ],
                },
                {
                    "sectionBeats": 4,
                    "mustHitSection": True,
                    "sectionNotes": [
                        [2000, 0, 0],
                        [2500, 1, 0],
                        [3000, 2, 0],
                        [3500, 3, 250],
                    ],
                },
            ],
            "events": [],
        }
    }
    for diff in ("easy", "normal", "hard"):
        (mod_dir / f"songs/{song_slug}/charts/{diff}.json").write_text(
            json.dumps(normal_chart, indent=2) + "\n", encoding="utf-8"
        )

    (mod_dir / f"songs/{song_slug}/script.lua").write_text(
        "-- Script de canción para Light Engine\n"
        "function postCreate()\n"
        f'\tMod.text("watermark", "{name} - Light Engine", 16, game.height - 30, {{size = 16}})\n'
        "end\n\n"
        "function beat(b)\n"
        "\tif b % 4 == 0 then\n"
        "\t\tMod.zoom(0.015, 0.02)\n"
        "\tend\n"
        "end\n",
        encoding="utf-8",
    )

    (mod_dir / "data/scripts/global.lua").write_text(
        "-- Script global del mod (se ejecuta en todos los estados cuando el mod está activo)\n"
        "function create()\n"
        "end\n",
        encoding="utf-8",
    )

    return mod_dir


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mod_id", help="Folder ID of the mod (e.g. mi-mod)")
    parser.add_argument("--name", default=None, help="Display name of the mod")
    parser.add_argument("--author", default="Modder", help="Author name")
    parser.add_argument(
        "--description",
        default="Un mod creado con Light Engine.",
        help="Short description shown in the Mods menu",
    )
    parser.add_argument("--song", default="bopeebo", help="Starter song folder name")
    parser.add_argument(
        "--mods-dir",
        type=Path,
        default=ROOT / "mods",
        help="Target mods root directory (defaults to ./mods)",
    )
    args = parser.parse_args()
    display = args.name or args.mod_id.replace("-", " ").title()
    created = create_mod(
        args.mods_dir,
        args.mod_id,
        display,
        author=args.author,
        description=args.description,
        song_name=args.song,
    )
    print(f"Created mod template at: {created}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
