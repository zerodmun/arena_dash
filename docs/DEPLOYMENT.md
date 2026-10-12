# Build and distribution

Current local export workflow, updated 2026-10-10. Commands below build or serve locally; no store publication has been performed.

## Prerequisites

Use Godot **4.7.2** and matching export templates, with `godot` available on PATH. Python 3 generates the Web shell and runs the local server. Android needs JDK 17, Android SDK/command-line tools, and the officially distributed export templates installed for the exact engine version. Android presets use Godot’s standard template lookup, with no custom Android override.

`build_apk.sh` detects JDK 17 and prefers the local Android SDK installation. Godot also has its own editor SDK path: configure Editor Settings → Export → Android to the intended SDK/JDK. This host now uses `/Users/tentendigitalindonesia/Library/Android/sdk`; the audited debug export used build-tools 36.0.0 with no target-SDK fallback. Standard templates supply min SDK 24 / target SDK 36; these preset SDK override fields remain blank because overrides require a Gradle build. Successful export does not establish store eligibility or Play Protect acceptance.

## Web export

From the project root:

```sh
./build_web.sh
python3 serve_web.py
```

`build_web.sh` runs `tools/build_web_shell.py`, then exports the Web preset into `dist/web/index.html`. The generator reads EN/ID catalogs and the stock `templates/web_shell_base.html` to update `templates/web_shell.html`. Regenerate through this script whenever translations or loader behavior change. The export includes `localization/*.json` in the game pack.

Open [http://127.0.0.1:8060](http://127.0.0.1:8060). `serve_web.py` binds to localhost, serves `dist/web`, disables caching, and adds COOP/COEP headers. If the port is already occupied, use the existing project server or stop that server before starting another.

The Web preset uses **Compatibility rendering and a single-threaded export** (`variant/thread_support=false`). SharedArrayBuffer is not required by this current preset. The supplied local server still sends:

```http
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Keep all generated Web files together when moving a local build. Serve over HTTP rather than opening `index.html` through `file://`; WebAssembly and pack files must load successfully. If threaded export is enabled in a future change, reassess browser isolation requirements and retest hosting.

Use a full `./build_web.sh` export after changes. Updating only `index.pck` can leave HTML pack-size metadata or the generated loader stale, so pack-only export is not the documented release workflow.

The loader reads the saved `arena-dash-language` localStorage mirror before the engine starts. In-game preferences/progress use Godot browser storage. Clearing site data removes local browser saves.

## Android export

With no arguments, the script retrieves the configured macOS Keychain credential and builds a production signed release APK. No manual environment setup is needed on this Mac. Missing or denied credentials stop publication:

```sh
./build_apk.sh
./build_apk.sh debug build/arena_dash_debug.apk
./build_apk.sh --help
```

It checks required tools, exports to a fresh temporary directory, verifies signature and ZIP alignment, then replaces the destination, archives other build APKs privately under `.maintenance/recovery/previous-apks/`, and writes reports beneath `qa/build-verification/`. A failed export cannot silently reuse the previous APK. Relative output paths resolve from the project root; absolute paths are also supported. `GODOT_BIN` and `ANDROID_SDK_ROOT` can override executable/SDK discovery.

For a production release with signing credentials configured:

```sh
./build_apk.sh --export-release
```

For a debug export:

```sh
./build_apk.sh --export-debug
```

Debug builds write `build/arena_dash_debug.apk`; releases write `build/arena_dash_release.apk`. Both retain arm64-v8a, `com.example.arenadash`, and fixed landscape. The primary preset now uses version code 2/name 1.1. Do not change the package or signing key to evade a warning. Before publishing an update, use the application's established production signing identity and a higher version code.

The production keystore fields in `export_presets.cfg` intentionally remain empty. Local signing metadata and the encrypted PKCS12 key live outside the project in `~/Library/Application Support/Arena Dash/signing/`. `tools/android_signing.py` retrieves the password from the login Keychain and passes credentials to the build in its environment. For CI, the documented Godot overrides remain supported:

- `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`: absolute production keystore path, preferably outside the project.
- `GODOT_ANDROID_KEYSTORE_RELEASE_USER`: production alias.
- `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`: password, never committed or printed.

The build script rejects missing credentials, the local debug key/alias, Android Debug certificates, and aliases without a private key. It validates the alias using `keytool -storepass:env`, then verifies the exported APK signature. Use an existing production key for an existing application; do not generate or replace its identity casually. The October 12 signing follow-up created the first production identity after the local audit found only debug keys. Two default builds reused that identity and validated successfully. See [signing configuration and device results](ANDROID_RELEASE_SIGNING.md). The historical unsigned release audit binary is retained only in the recovery archive; it is not a distribution build.

With Android build-tools on PATH, verify a signed output:

```sh
apksigner verify --verbose --print-certs build/arena_dash_release.apk
```

The development APK verifies v2/v3 signing with the development certificate. Physical Redmi Note 8 installation and gameplay were verified in the [phone QA follow-up](ANDROID_PHONE_QA.md); its results describe the tested APK identity and automation limits. Play Protect clearance remains unverified. See [security findings](ANDROID_SECURITY_AUDIT.md), including a remaining libpng advisory that must be assessed before public release.

## Export scope and verification

All presets include the game localization/audio data and exclude build output, tests, documentation, developer tools/configuration, signing material, and backup archives. The actual rebuilt APK contains neither `opencode.json` nor keystore files. Source artwork is retained. Review `export_presets.cfg` for the actual export settings rather than relying on historical guides.

The latest implementation run successfully exported Web and Android and verified APK v2/v3 signatures. Logs are under `qa/web-performance-export.log`, `qa/android-performance-export.log`, and `qa/apk-performance-signature.log`. Sandbox-only user-log/editor-settings/ADB/certificate diagnostics appeared during some commands; exports completed despite those diagnostics. Script errors or export failures still require investigation.

See [Testing](TESTING.md) for functional suites, browser checks, screenshots, and remaining device validation.

## Debug performance capture

Desktop diagnostics: `godot --path . -- --perf`. Sampling is gated by both a debug build and the user argument. For Android development capture, temporarily set the Android preset’s `command_line/extra_args` to `--perf` and export a debug APK; restore that setting for ordinary exports. Collect Godot `PERF` JSON lines from device logs during light/heavy gameplay and a sustained session. CPU/GPU timing support varies by renderer; a reported zero GPU value may be unavailable timing. Compare percentiles/spikes and physical-device responsiveness, not only average FPS. See [measurement limits](PERFORMANCE_PROGRESSION.md). Release exports do not sample or enable render measurement.

## Direct APK installation verified on October 12

The exact debug APK was accepted through the normal Android installer after the user approved Play Protect’s **Scan app** action and Google returned **SAFE**. A second normal update from Download succeeded without another scan approval. This was a required security scan, not an export/signing defect; do not change package or key identity or disable protection. See [the device evidence and limitations](DIRECT_INSTALL_FIX.md). Changed APKs or other phones may require their own security scan.


The launcher source is the updated root `icon.svg`. `tools/generate_android_icons.gd` splits the supplied artwork into adaptive layers; `tools/render_android_icons.cjs` renders its original SVG filters with sharp/librsvg and validates the safe zone. The build requires Node.js and sharp. It uses the installed bundled runtime on this host, or `node` with a resolvable sharp package. Override `ARENA_ICON_NODE_BIN` and `ARENA_ICON_SHARP_PATH` on another host. No artwork is generated by AI.

Before atomic publication, `tools/validate_android_build.py` checks the actual decoded manifest, expected package/version/ABIs, standalone layout, signing certificate, alignment, and executable identity against the exact-version debug or release template. Release validation rejects `debuggable` and `testOnly`. The primary preset is package `com.example.arenadash`, version code 2 / name 1.1. The stock release template supplies optimized native code; opt-in diagnostics and review automation are disabled by `OS.is_debug_build()` guards.

The three `GODOT_ANDROID_KEYSTORE_RELEASE_*` variables correspond to Godot's documented Android export options: [Godot 4.7 Android export variables](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html#android-export-environment-variables). Keep the production key outside this repository. A different production certificate cannot normally update an app signed with the development key. Inspect the installed certificate before deployment; never uninstall or clear data to bypass that conflict.
