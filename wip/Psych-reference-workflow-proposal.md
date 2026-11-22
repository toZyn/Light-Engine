# Proposed compiled Psych reference workflow

Status: proposal only. No workflow has been installed in .github/workflows, dispatched or executed. Scope is wip/psych-compat. Activation needs the user's OK. The reference instrumentation described below must be implemented and reviewed before activation; this draft is not advertised as a runnable reference capture yet.

## Trigger and isolation

- workflow_dispatch only; no push, pull_request, schedule or workflow_run trigger.
- Reject every ref except refs/heads/wip/psych-compat in the job condition.
- Read-only contents permission; checkout with persist-credentials false; no repository writes, deployments, secrets or remote mod downloads.
- Checkout Light at the manually selected WIP ref and Psych at 5c67ced49e5a98535298a6daa3f8f4ec79ac8399 (tag 1.0.4).
- Ubuntu 22.04, Haxe 4.3.7, native Linux C++ target, Neko runtime and hxcpp. Preserve the complete compiler/dependency manifest in artifacts.

## Proposed workflow

```yaml
name: Psych 1.0.4 reference capture
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  reference:
    if: github.ref == 'refs/heads/wip/psych-compat'
    runs-on: ubuntu-22.04
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4
        with:
          persist-credentials: false
          path: light
      - uses: actions/checkout@v4
        with:
          repository: ShadowMario/FNF-PsychEngine
          ref: 5c67ced49e5a98535298a6daa3f8f4ec79ac8399
          persist-credentials: false
          path: reference
      - uses: krdlab/setup-haxe@v1
        with:
          haxe-version: 4.3.7
      - run: |
          sudo apt-get update
          sudo apt-get install -y neko libneko2 g++ pkg-config xvfb ffmpeg libvlc-dev libvlccore-dev libgtk-3-dev libasound2-dev libpulse-dev libgl1-mesa-dev libglu1-mesa-dev libx11-dev libxrandr-dev libxi-dev libxinerama-dev
      - working-directory: reference/setup
        run: bash unix.sh
      - working-directory: reference
        run: |
          haxelib install hxcpp 4.3.2 --quiet
          haxe --version
          haxelib list
      - run: python3 light/wip/reference/instrument_psych.py --source reference --output reference-output
      - working-directory: reference
        run: haxelib run lime build linux -debug -D officialBuild -D PSYCH_REFERENCE_CAPTURE
      - working-directory: reference/export/debug/linux/bin
        env:
          ALSOFT_DRIVERS: null
        run: xvfb-run -a timeout 90s ./PsychEngine
      - run: python3 light/wip/reference/validate_capture.py --input reference-output --required-phase defaults --required-phase onCreate --required-phase onCountdownStarted --required-phase onCreatePost --required-phase rating
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: psych-1.0.4-linux-reference
          path: |
            reference-output/
            reference/export/debug/linux/haxe/
          if-no-files-found: error
```

Before activation, pin Actions to reviewed immutable SHAs and verify the native export path against the generated Lime configuration. Dependency setup is copied from the pinned upstream setup/unix.sh: Flixel 5.6.1, flixel-addons 3.2.2, flixel-tools 1.5.1, hscript-iris 1.1.3, tjson 1.4.0, hxdiscord_rpc 1.2.4, hxvlc 2.0.1, Lime 8.1.2, OpenFL 9.3.3; the script also pins flxanimate/linc_luajit/funkin.vis/grig.audio Git revisions. Any mismatch or unavailable package must fail the build rather than substitute versions.

## Instrumentation contract to implement before activation

instrument_psych.py must assert the exact pinned source hash and instrument a temporary checkout only. Keep original calculations and Lua callback bodies unchanged. Add a compile-guarded reference boot state and source hooks; do not replace PlayState with a synthetic class.

1. Construct the real PlayState and capture declared instance/static field names, scalar values, type names and null status before create; record errors separately.
2. Use a synthetic no-note chart, generated silent audio and base engine assets. Use two stage-data fixtures: default positions and explicit BF/GF/Dad coordinates; no user mods.
3. Run the real FunkinLua constructor and capture all literal set registrations plus expanded strum names at script source execution, onCreate, onCountdownStarted and onCreatePost. Capture nil distinctly from false and zero.
4. Capture selected PlayState, SONG, Note, StrumNote and group property reads/writes and errors. Record class/type and object identity where values are not scalar; do not silently stringify object references into values.
5. Run rating threshold, miss-count, ratingDisabled, botplay and stopped-hook cases through the real state and callbacks. Dump values and ordered callback events.
6. Flush JSONL plus source/dependency/build manifests, exit with a defined success code, and validate all required phases. Timeout, missing phases, skipped scripts or capture exceptions fail validation.
7. Store full build/capture logs and reference artifacts; do not update fixtures automatically. Review generated reference changes before committing them.

Linux compilation validates native C++ behavior, not Android touch or Mali rendering. A separate approved Android job/device run is required for those targets. The instrumentation helpers named in the draft are not implemented in this proposal; activation remains pending.
