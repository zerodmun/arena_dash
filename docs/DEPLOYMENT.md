# Build and distribution

Current local export workflow, updated 2026-10-09. Commands below build or serve locally; no external deployment has been performed.

## Prerequisites

Use Godot **4.7.2** and matching export templates, with `godot` available on PATH. Python 3 generates the Web shell and runs the local server. Android needs JDK 17, Android SDK/command-line tools, and the configured custom APK templates in `templates`.

`build_apk.sh` currently uses Homebrew paths for OpenJDK 17 and Android command-line tools, including build-tools 34.0.0. On another machine, adapt those paths and install matching Godot templates/SDK components. Build logs currently report a target-SDK tool-version fallback to 34.0.0; successful local export does not establish store submission eligibility.

## Web export

From the project root:

```sh
./build_web.sh
python3 serve_web.py
```

`build_web.sh` runs `tools/build_web_shell.py`, then exports the Web preset into `build/web/index.html`. The generator reads EN/ID catalogs and the stock `templates/web_shell_base.html` to update `templates/web_shell.html`. Regenerate through this script whenever translations or loader behavior change. The export includes `localization/*.json` in the game pack.

Open [http://127.0.0.1:8060](http://127.0.0.1:8060). `serve_web.py` binds to localhost, serves `build/web`, disables caching, and adds COOP/COEP headers. If the port is already occupied, use the existing project server or stop that server before starting another.

The Web preset uses **Compatibility rendering and a single-threaded export** (`variant/thread_support=false`). SharedArrayBuffer is not required by this current preset. The supplied local server still sends:

```http
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Keep all generated Web files together when moving a local build. Serve over HTTP rather than opening `index.html` through `file://`; WebAssembly and pack files must load successfully. If threaded export is enabled in a future change, reassess browser isolation requirements and retest hosting.

Use a full `./build_web.sh` export after changes. Updating only `index.pck` can leave HTML pack-size metadata or the generated loader stale, so pack-only export is not the documented release workflow.

The loader reads the saved `arena-dash-language` localStorage mirror before the engine starts. In-game preferences/progress use Godot browser storage. Clearing site data removes local browser saves.

## Android export

```sh
./build_apk.sh --export-release
```

For a debug export:

```sh
./build_apk.sh --export-debug
```

Both commands write `build/arena_dash.apk`. The current preset exports arm64-v8a, uses package ID `com.example.arenadash`, version code 1/name 1.0, and uses the existing **local development signing identity**, including for release-mode export. Release mode here describes the Godot build configuration; it is not a store-ready distribution identity.

Verify the output:

```sh
JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
/opt/homebrew/share/android-commandlinetools/build-tools/34.0.0/apksigner verify --verbose build/arena_dash.apk
```

Latest verification reports `Verifies`, v2 and v3 schemes `true`, and one signer. A connected development device can receive the local APK with:

```sh
adb install -r build/arena_dash.apk
```

Physical device installation/testing has not been completed in this environment. Before public distribution, separately configure the intended package/version/signing identity and validate on target devices. No signing secrets are reproduced in this documentation.

## Export scope and verification

Both presets include the localization JSON catalogs and exclude `build/*`, `tests/*`, `docs/*`, and implementation backup ZIPs. Source artwork is retained. Review `export_presets.cfg` for the actual export settings rather than relying on historical guides.

The latest implementation run successfully exported Web and Android and verified APK v2/v3 signatures. Logs are under `build/web-performance-export.log`, `build/android-performance-export.log`, and `build/apk-performance-signature.log`. Sandbox-only user-log/editor-settings/ADB/certificate diagnostics appeared during some commands; exports completed despite those diagnostics. Script errors or export failures still require investigation.

See [Testing](TESTING.md) for functional suites, browser checks, screenshots, and remaining device validation.

## Debug performance capture

Desktop diagnostics: `godot --path . -- --perf`. Sampling is gated by both a debug build and the user argument. For Android development capture, temporarily set the Android preset’s `command_line/extra_args` to `--perf` and export a debug APK; restore that setting for ordinary exports. Collect Godot `PERF` JSON lines from device logs during light/heavy gameplay and a sustained session. CPU/GPU timing support varies by renderer; a reported zero GPU value may be unavailable timing. Compare percentiles/spikes and physical-device responsiveness, not only average FPS. See [measurement limits](PERFORMANCE_PROGRESSION.md). Release exports do not sample or enable render measurement.
