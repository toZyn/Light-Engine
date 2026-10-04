# Build and release validation

`.github/workflows/engine-checks.yml` is a reusable check workflow. Pull requests changing engine code, native assets, regression tests, tools, examples or workflows run it automatically. It can also be started from the GitHub Actions page. `.github/workflows/release.yml` calls the same checks before its `prepare` job: a failed check prevents draft creation and every Windows, Linux and Android build.

The Linux job downloads the official **LÖVE 11.5** AppImage, extracts it without FUSE, and runs the complete native regression suite under Xvfb with null audio. It then runs the async suite with `ASYNC_MOBILE=1` to exercise the two-worker/one-upload mobile policy. This second run is a Linux configuration test, not an Android device test.

The Windows job downloads official **LÖVE 11.5 win64**, installs a pinned Mesa 25.0.7 software OpenGL renderer beside the test executable, and runs the same complete suite. The test runner's `--copy` mode avoids Windows symlink privileges. Mesa is used only by this check job; the release packages continue to use the native official LÖVE runtimes. Actual Windows runner execution must be checked in GitHub Actions; adding the job does not establish that a Windows run passed.

Both check jobs upload their test logs with `if: always()`. Artifacts are named `engine-checks-linux` and `engine-checks-windows`, retained for fourteen days. Linux logs include the separate mobile-policy directory and runtime extraction log. Inspect these artifacts when a check fails rather than relying solely on the Actions step summary.

The release keeps the existing native packaging:

- Windows x64/x86 fused executables from the official runtime archives.
- Linux AppImage and portable packages containing `game.love`.
- Android native `love-android` **11.5a**, Java **17**, SDK/build tools **34**, and NDK **25.2.9519653**, with the existing storage patch, launcher and signing key. It builds arm64, ARMv7 and universal embed APKs.

`tools/make_game_love.py` remains the game payload builder for every platform. Release pushes additionally include changes to tests, documentation, examples, tools and workflows so changes affecting these deliverables cannot bypass the gate.

## Android update codes

The Android package name and signing key are retained. Android also requires a version code at least as high as the installed package; increment the code for each new release intended to replace it.

Set an explicit positive integer `androidVersionCode` in `project.lua` when a release name alone does not determine the update order. The advanced release uses **118**, above the previous official `0.1.16` code **116**. Future releases must keep this field monotonic; a later stable `0.1.17` should use a code above 118 when replacing this advanced build. A rebuilt payload inside an existing APK preserves that APK's original manifest code; it does not receive the workflow's new native-build code automatically.

The prepare job validates the release name and override before publishing outputs. If the override is absent, it uses the numeric semantic-version base `major * 10000 + minor * 100 + patch`, stripping prerelease/build labels. It rejects overlapping minor/patch fields above 99, zero/negative/oversized codes and malformed overrides. A version such as `0.1.16-advanced.1` never silently falls back to code 1. The accepted range is 1–2,100,000,000.

## Local checks and evidence

With a working LÖVE 11.5 graphics backend:

```sh
ALSOFT_DRIVERS=null xvfb-run -a python3 tools/run_engine_tests.py --love /path/to/love
ALSOFT_DRIVERS=null ASYNC_MOBILE=1 xvfb-run -a python3 tools/run_engine_tests.py --love /path/to/love --logs test-results/mobile-policy async
```

Validate workflow syntax with:

```sh
actionlint .github/workflows/engine-checks.yml .github/workflows/release.yml
```

The Linux check job also runs `tests/desktop-packaging.py` against the official Windows x64 runtime.

Locally verified on Linux: the complete default suite using the downloaded official 11.5 AppImage runtime; the mobile async policy variant; actionlint 1.7.7 on both workflows; and version-reader fixtures for accepted stable/advanced values and rejected malformed/out-of-range values. This is local evidence, not a GitHub-hosted run. Physical Android, Windows and macOS validation remains outstanding, as does the first execution of the modified repository workflow.
