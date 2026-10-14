# Release APK security and Play Protect audit — 13 October 2026

The supplied APK and two new default builds are genuine, consistently signed Godot Release APKs. No current APK permission/debugging/injected-library misconfiguration was found. Build validation was strengthened to prevent certificate and manifest drift. This is a static audit, not a malware certification, complete dependency-vulnerability assessment, or confirmation that the phone warning disappeared. An upstream libpng advisory remains relevant to the installed engine template.

## Build and signing

`./build_apk.sh` defaults to `--export-release Android`; Debug requires an explicit argument. Missing/invalid release credentials cause failure. There is no automatic Debug fallback, new-key generation or cross-version template fallback. Export uses a fresh temporary output, validates it, then atomically publishes it to `build/arena_dash_release.apk`.

The production PKCS12 key is persistent outside the repository in the existing local signing directory. The helper retrieves its password from the existing macOS Keychain record and passes it through the child environment. The build verifies a private-key entry, rejects the debug keystore/alias and certificate, and checks the configured fingerprint. Neither the keystore nor its password was changed or disclosed. `init-new` is a separate maintenance command; the build never invokes it. Export presets contain no production password/key and exclude signing material, tests, QA, developer configuration and tools.

The existing application ID remains **com.example.arenadash**, version **1.1 / code 2**. The production certificate SHA-256 is:

`317b9baedaf187bd9e4cf17096fbca1119dac169f063e3090bd9b5bc8e3523af`

This public fingerprint matches the input APK and both new builds. It is not a password or private key.

## Exact changes

| File | Change and purpose |
|---|---|
| `tools/android_release_policy.py` (new) | Pins the existing public production fingerprint and application ID. Defines the offline-app manifest contract: zero requested permissions, min SDK 24, target SDK at least 36, no debuggable/test-only/backup/legacy-storage flags, and the audited component exposure/launcher/DUMP guard. |
| `build_apk.sh` | Checks the selected certificate against the pinned identity before export. Previously, a CI keystore override without an expected fingerprint could use another production key. Local Keychain builds were already tied to the existing key. |
| `tools/validate_android_build.py` | Enforces the same identity/manifest policy on the signed artifact before publication and records its results. Replaces Python `assert` gates with explicit failure checks; previously `PYTHONOPTIMIZE=1` could remove those checks. Existing signature, executable-template, icon, ABI, standalone and ZIP checks remain. |
| `tests/test_android_release_policy.py` (new) | Nine tests exercising the actual decoded manifest and rejection of changed certificates, permissions, debugging/backup flags, exposed providers, unprotected receivers, injected services and changed package/SDK. Runs under normal and optimized Python. |
| `tests/android_release_manifest.xml` (new) | Decoded original release manifest fixture. Excluded from exports with the existing test exclusion. |
| This report | Current evidence and remaining limitations. Historical October 9/12 reports identify different artifacts and do not prove the current warning is cleared. |

These are build-tool safeguards, not evidence the input APK was malicious or wrongly signed. No gameplay/visual/save/locale code, artwork, renderer, physics setting, package ID, production key or export preset was changed by this security task. Earlier performance changes were preserved and their source hashes checked. A pre-change checkpoint is in `.maintenance/recovery/pre-release-security-20261013.tar`; the input APK is retained in `qa/release-security-20261013/input.apk`.

The first new validator run was too strict about the stock launcher categories: the template includes both DEFAULT and LAUNCHER. It correctly blocked publication; the policy was corrected to preserve the audited categories, then both final builds and all tests passed.

## Final APK inspection

| Property | Result |
|---|---|
| Export mode | Release; executable matches exact installed 4.7.2 release template |
| Package / version | com.example.arenadash / 1.1 / 2 |
| Minimum / target / compile SDK | 24 / 36 / 36 |
| Debuggable / testOnly | Absent: false by Android default |
| Requested Android permissions | **None**, including no INTERNET, storage, camera, microphone, contacts, location or SMS |
| Backup / legacy external storage | Explicitly false / false |
| ABI / packaging | arm64-v8a; standalone APK |
| Signature | apksigner verifies v2 and v3; one unchanged production signer |
| Other signature schemes | v1, v3.1, v3.2 and v4 absent; v2 is supported from the declared Android 7/API 24 minimum; later optional schemes are not required for this standalone APK |
| Alignment | zipalign -c -P 16 4 passes |
| Integrity | ZIP CRC validation passes; manifest and required native libraries present |
| Executable provenance | classes.dex, libc++_shared.so and libgodot_android.so byte-match installed release template; no extra/missing executable entries |
| Native hardening inspected | Both .so files have non-executable stack, GNU RELRO and immediate binding |
| Bundled private/developer material | No detected keystore/key files, export presets, opencode.json or inspected development identifiers in sparse packs |

Template release SHA-256: `6d1bb2cfa126a1b1c87e064a35b3cbd181bef0ec784dec1efd1d64dffa8be6cb`. This matches the template fingerprint recorded in the earlier official-template provenance audit. The current task compared executable bytes against this installed template; it did not freshly download or hash the full upstream template archive.

DEX package inventory contains stock Godot, AndroidX, Kotlin and coroutine classes. No project Android plugins, custom runtime AAR/JAR/GDExtension, advertising or analytics additions were identified. Executable equality proves absence of added executable entries relative to that template, not that every upstream dependency is vulnerability-free. Release dependency-version metadata is stripped; a complete transitive software bill of materials cannot be inferred from APK `.version` files.

## Components and profiling

- GodotApp activity: private. GodotAppLauncher alias: exported for MAIN/DEFAULT/LAUNCHER, targeting that activity.
- ProcessPhoenix restart activity: private, in the stock `:phoenix` process.
- FileProvider and AndroidX InitializationProvider: private. No service components are present.
- ProfileInstallReceiver: exported, guarded by privileged `android.permission.DUMP`. This protects inbound operations; the game does not request DUMP.

The stock template retains `<profileable enabled="true" shell="true">`. It is a deliberate release-profiling facility, distinct from debuggable. Android documents minimal exposure (stack traces rather than process memory) and supports it in production builds. It was reviewed and retained; the APK is not described as having every diagnostic facility disabled. [Android profileable documentation](https://developer.android.com/guide/topics/manifest/profileable-element).

Stock FileProvider paths permit internal files and broad external roots, but the provider is private and no URI-grant/sharing flow was found in game code. Both stock providers have the same rewritten `.fileprovider` authority. These are upstream configuration concerns to revisit before adding sharing functionality; this audit did not prove an externally reachable disclosure or alter engine provider behavior without Android validation.

## Repeated-build verification

Commands completed:

1. `./build_apk.sh` — passed.
2. `PYTHONOPTIMIZE=1 ./build_apk.sh` — passed with security gates active.
3. `python3 -B tests/test_android_release_policy.py` — nine passed.
4. Optimized-Python repeat of the policy suite — nine passed.
5. Wrong-certificate CLI check — rejected with exit failure.
6. Final `apksigner`, `zipalign`, `apkanalyzer`, `aapt`, ZIP integrity, executable equality and manifest-policy checks — passed.
7. Shell syntax, Python compilation and `git diff --check` — passed.

| Artifact | APK SHA-256 |
|---|---|
| Input | `4056f5a078861855541d44793b65654aa946adfea6e9d28b86997ec9a82728b3` |
| Build 1 | `ca4a0633bf8cba12231eb73ce4b109212e8ca63fe20c40866cbd8cfe32750f7a` |
| Final build 2 | `3604956a276f50a86eafd39eb5382bc407980f0319f3d90e391a2716f39c3c7d` |

Both new APKs have identical ZIP member names and uncompressed contents. Their 1,112 differing ZIP timestamps explain why archive bytes and signatures/hashes can differ. Thus content and identity are consistent, but the build is **not claimed bit-for-bit reproducible**. Evidence is in `qa/release-security-20261013/`, including the final manifest, audit JSON, package inventory, provider paths, signatures, tests, build logs and repeated-build comparison. Normal publication checks are in `qa/build-verification/`.

Final artifact: **build/arena_dash_release.apk**, approximately 53 MiB. The same application ID and certificate preserve Android update identity. No phone was connected, installed or tested. Godot's headless exporter attempted its automatic device discovery and logged a refused connection; no manual ADB or connected-device operation was performed.

## Remaining upstream dependency concern

The native engine contains the version string **1.6.58**, consistent with the official 4.7.2 libpng source. The libpng maintainer identifies **CVE-2026-46675**, a use-after-free involving incomplete compressed ancillary PNG chunks, fixed in **1.6.59**. This confirms a version-level dependency concern, not a demonstrated exploit against this game or a proven cause of the Play Protect warning. No downloaded/untrusted PNG ingestion path was found in game runtime code; that reduces observed exposure but does not patch the library. [Godot 4.7.2 source](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/thirdparty/libpng/png.h), [libpng 1.6.59 announcement](https://github.com/pnggroup/libpng/blob/v1.6.59/ANNOUNCE).

The checked official stable download remains 4.7.2. No newer installed patched release template was available. Resolving this concern requires a reviewed vendor-patched engine/template or compatible engine update and renewed gameplay/Android verification. Altering a native version string, switching to an unreviewed development engine or changing signing flags does not fix it. This APK is properly packaged and signed, but is not certified free of upstream vulnerabilities. [Official Godot release](https://godotengine.org/download/archive/4.7.2-stable/).

## Meaning of the Play Protect warning

The quoted unfamiliar-developer text is consistent with Google not yet recognizing this app/developer, rather than a specific harmful-code or sensitive-permission finding. That classification is an inference from the text; no current on-device scan result or Google backend reputation verdict was obtained. Correct signing establishes update identity, not Google's reputation history. Rebuilding, replacing certificates or changing the package cannot legitimately guarantee the warning's removal. [Google's warning guidance](https://developers.google.com/android/play-protect/warning-dev-guidance).

Use the legitimate Play Console internal testing track, then applicable closed testing and normal production review. Distribute the test through its Play opt-in link rather than only a sideloaded file. When enrolling in Play App Signing, preserve the existing app signing key so Play-delivered and existing sideloaded installations retain the same signing identity; distinguish an upload key from the app signing key. This is a recommended next distribution process, not a claim of completed publication or guaranteed warning removal. [Play testing guidance](https://support.google.com/googleplay/android-developer/answer/9845334), [Android signing guidance](https://developer.android.com/studio/publish/app-signing).

Keep Play Protect enabled. If a later scan explicitly classifies the app as harmful in error, use Google's corresponding review/appeal process with the exact APK hash and warning. An unfamiliar-app prompt alone does not establish malware. No upload, appeal, Play Console publication, bypass or on-phone warning-removal claim was made in this task.
