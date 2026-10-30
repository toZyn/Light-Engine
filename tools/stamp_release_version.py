#!/usr/bin/env python3
"""Resolve and stamp the release version and Android versionCode in project.lua.

If the tag for project.lua's version already exists as a published GitHub
release pointing to an older commit, --resolve automatically derives the next
monotonic SemVer revision (e.g. 0.2.0 -> 0.2.0-r1, androidVersionCode + 1) so
every push/merge to main publishes a brand-new GitHub Release instead of
silently overwriting an older tag.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SEMVER_RE = re.compile(
    r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"
    r"(?:-[0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?"
    r"(?:\+[0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?"
)


def parse_project_lua(source: str) -> tuple[str, int]:
    found = re.search(r'^\s*version\s*=\s*"([^"\n]+)"', source, re.MULTILINE)
    if not found:
        raise ValueError("No version found in project.lua")
    base_version = found.group(1)
    semver = SEMVER_RE.fullmatch(base_version)
    if not semver:
        raise ValueError(f"project.lua version must be a safe semantic version: {base_version!r}")

    override = re.search(r"^\s*androidVersionCode\s*=\s*([^,\n]+)", source, re.MULTILINE)
    if override:
        raw_code = override.group(1).split("--", 1)[0].strip()
        if not re.fullmatch(r"[0-9]+", raw_code):
            raise ValueError("androidVersionCode must be a positive integer")
        code = int(raw_code)
    else:
        major, minor, patch = map(int, semver.group(1, 2, 3))
        if minor > 99 or patch > 99:
            raise ValueError("Set androidVersionCode explicitly when minor or patch exceeds 99")
        code = major * 10000 + minor * 100 + patch

    if not 1 <= code <= 2100000000:
        raise ValueError("Android version code must be between 1 and 2100000000")
    return base_version, code


def stamp_project_lua(project_path: Path, version: str, android_version_code: int) -> None:
    if not SEMVER_RE.fullmatch(version):
        raise ValueError(f"Invalid semantic version: {version!r}")
    if not 1 <= android_version_code <= 2100000000:
        raise ValueError("Android version code must be between 1 and 2100000000")

    source = project_path.read_text(encoding="utf-8")
    updated, v_count = re.subn(
        r'^(\s*version\s*=\s*)"[^"\n]+"',
        rf'\g<1>"{version}"',
        source,
        count=1,
        flags=re.MULTILINE,
    )
    if v_count != 1:
        raise ValueError("Could not update version in project.lua")

    if re.search(r"^\s*androidVersionCode\s*=", updated, re.MULTILINE):
        updated, c_count = re.subn(
            r"^(\s*androidVersionCode\s*=\s*)[0-9]+",
            rf"\g<1>{android_version_code}",
            updated,
            count=1,
            flags=re.MULTILINE,
        )
        if c_count != 1:
            raise ValueError("Could not update androidVersionCode in project.lua")
    else:
        updated, c_count = re.subn(
            r'^(\s*version\s*=\s*"[^"\n]+"\s*,?)',
            rf"\g<1>\n\tandroidVersionCode = {android_version_code},",
            updated,
            count=1,
            flags=re.MULTILINE,
        )
        if c_count != 1:
            raise ValueError("Could not insert androidVersionCode in project.lua")

    tmp = project_path.with_suffix(".lua.tmp")
    tmp.write_text(updated, encoding="utf-8")
    tmp.replace(project_path)


def choose_release_version(
    base_version: str,
    base_code: int,
    sha: str,
    existing_base_target: str | None,
    existing_base_is_draft: bool,
    existing_tags: set[str],
) -> tuple[str, int]:
    """Return (version, androidVersionCode), bumping if v<base> points elsewhere."""
    base_tag = f"v{base_version}"
    if existing_base_target is None or existing_base_is_draft or existing_base_target == sha:
        return base_version, base_code

    sep = ".r" if "-" in base_version else "-r"
    prefix = f"v{base_version}{sep}"
    max_rev = 0
    for tag in existing_tags:
        if tag.startswith(prefix):
            tail = tag[len(prefix):]
            if tail.isdigit():
                max_rev = max(max_rev, int(tail))
    rev = max_rev + 1
    while f"{prefix}{rev}" in existing_tags:
        rev += 1

    new_version = f"{base_version}{sep}{rev}"
    new_code = base_code + rev
    if not 1 <= new_code <= 2100000000:
        raise ValueError("Incremented Android version code exceeded valid range")
    return new_version, new_code


def query_github_tags(repo: str, base_version: str) -> tuple[str | None, bool, set[str]]:
    view = subprocess.run(
        ["gh", "release", "view", f"v{base_version}", "--repo", repo, "--json", "targetCommitish,isDraft"],
        text=True,
        capture_output=True,
    )
    if view.returncode != 0:
        return None, False, set()

    info = json.loads(view.stdout)
    target = info.get("targetCommitish") or ""
    is_draft = bool(info.get("isDraft", False))

    tags: set[str] = {f"v{base_version}"}
    rel_list = subprocess.run(
        ["gh", "api", f"repos/{repo}/releases?per_page=100"],
        text=True,
        capture_output=True,
        check=True,
    )
    for item in json.loads(rel_list.stdout):
        if item.get("tag_name"):
            tags.add(item["tag_name"])

    remote = subprocess.run(
        ["git", "ls-remote", "--tags", "origin"],
        text=True,
        capture_output=True,
    )
    if remote.returncode == 0:
        for line in remote.stdout.splitlines():
            parts = line.split("\t")
            if len(parts) == 2 and parts[1].startswith("refs/tags/"):
                tag = parts[1][len("refs/tags/"):]
                if not tag.endswith("^{}"):
                    tags.add(tag)

    return target, is_draft, tags


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=ROOT / "project.lua")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--resolve", action="store_true", help="Resolve version and write metadata")
    group.add_argument("--apply", type=Path, metavar="META_JSON", help="Stamp project.lua from metadata JSON")
    parser.add_argument("--repo", help="GitHub repository (owner/name) for tag checks")
    parser.add_argument("--sha", default="", help="Target commit SHA")
    parser.add_argument("--output", type=Path, help="Output metadata JSON path for --resolve")
    parser.add_argument("--github-output", type=Path, help="GITHUB_OUTPUT file path for --resolve")
    args = parser.parse_args()

    try:
        if args.apply:
            meta = json.loads(args.apply.read_text(encoding="utf-8"))
            stamp_project_lua(args.project, meta["version"], int(meta["androidVersionCode"]))
            print(f"Stamped project.lua -> {meta['version']} (Android versionCode {meta['androidVersionCode']})")
            return 0

        source = args.project.read_text(encoding="utf-8")
        base_version, base_code = parse_project_lua(source)
        target, is_draft, existing_tags = (None, False, set())
        if args.repo and args.sha:
            target, is_draft, existing_tags = query_github_tags(args.repo, base_version)

        version, code = choose_release_version(
            base_version, base_code, args.sha, target, is_draft, existing_tags
        )
        if version != base_version:
            print(
                f"Tag v{base_version} already points to {target[:7] if target else 'another commit'}; "
                f"auto-incrementing release to {version} (Android versionCode {code})"
            )
            stamp_project_lua(args.project, version, code)

        meta = {
            "version": version,
            "baseVersion": base_version,
            "tag": f"v{version}",
            "releaseName": f"Light Engine {version}",
            "androidVersionCode": code,
        }
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")

        if args.github_output:
            with args.github_output.open("a", encoding="utf-8") as handle:
                handle.write(f"version={version}\n")
                handle.write(f"base_version={base_version}\n")
                handle.write(f"tag=v{version}\n")
                handle.write(f"release_name=Light Engine {version}\n")
                handle.write(f"android_version_code={code}\n")

        print(f"Release {version}; Android versionCode {code}")
        return 0
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as exc:
        print(f"::error::{exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
