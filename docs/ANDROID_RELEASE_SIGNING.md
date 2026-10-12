# Arena Dash production signing — 2026-10-12

The default `./build_apk.sh` now builds and validates a genuine production-signed release without manual keystore, alias, password, or environment setup on this Mac. Two actual default builds succeeded using the same identity. The connected phone rejected both ADB and normal updates because its existing game is signed with the older development certificate. Installation is not reported as successful.

## Discovery and identity

The recorded local search covered Documents, Desktop, Downloads, Android SDK/debug directories, Gradle, local configuration, Godot, and Codex. It found three Android development keystores and an unrelated CMake Windows test certificate. No Arena Dash production keystore, configured release secret, or matching Keychain record was found. All 29 inspected Arena Dash APKs used the original debug certificate. Historical Git export presets also used `debug.keystore` / `androiddebugkey` for release. The existing phone APK uses certificate `0e477ff5a93c87091b58bb83639a949b9df3b474e19da515fabb611645e69dc0`. This is a local evidence audit, not proof about keys or distributions on unavailable machines/accounts.

Under the user's explicit conditional authorization, the first production identity was created locally. No existing key was overwritten or reclassified as production.

- Keystore: `/Users/tentendigitalindonesia/Library/Application Support/Arena Dash/signing/arena_dash_release.p12`
- Alias: `arena-dash-release`
- Public certificate SHA-256: `317b9baedaf187bd9e4cf17096fbca1119dac169f063e3090bd9b5bc8e3523af`
- RSA 3072-bit, SHA256withRSA, validity 10,000 days.
- Password: 384 bits of cryptographically random entropy, stored and retrieval-verified in the macOS login Keychain. No password is printed or stored in the repository.
- Keychain service: `Arena Dash Android production signing`; account: `com.example.arenadash.release`.
- Directory permissions: 0700. Keystore, metadata and recovery instructions: 0600.

## Build configuration and guards

`tools/android_signing.py` reads external, nonsecret `release.json` metadata and retrieves the Keychain password into memory. Its credential creation uses an input pipe to `security -i`; retrieval output is captured. The helper passes signing credentials to the build environment, never displaying them. CI environment overrides remain supported. `export_presets.cfg` retains empty release credential fields and the original package ID.

Initialization is an explicit audited maintenance action; regular builds never generate a replacement key. A second initialization was exercised and refused to overwrite the new identity; the encrypted keystore checksum remained unchanged. Partial environment configuration was exercised and rejected. Missing keystore, unavailable Keychain credential, changed recorded certificate, debug key selection, and invalid validation results block release publication.

After signing and validation, publication is atomic. Other APKs are moved into private `.maintenance/recovery/previous-apks/`, preserving recovery while leaving `build/` with only `arena_dash_release.apk`. The former development APK was archived there. Signing material stays outside the repository and remains covered by Git/export exclusions. Checks found no production password in examined source/configuration/logs or APK content, and no private signing material packaged in the APK.

## Final artifact validation

- File: `build/arena_dash_release.apk` (53 MiB).
- APK SHA-256: `7848ea95715cdbd8cd3ff99bb53ec4fae14113e69bb282f3b5337da886a986b1`.
- Package: `com.example.arenadash`; version code 2, version name 1.1.
- Manifest: release, debuggable=false, testOnly=false; standalone arm64-v8a.
- Signature: apksigner verifies v2/v3 with the recorded production certificate.
- ZIP integrity and 16 KB native-library alignment: pass.
- DEX/native executable bytes match the installed exact-version Godot 4.7.2 release template.
- Adaptive/density icon resources are present; decoded xxxhdpi launcher/foreground/background pixels match regenerated sources.
- Stock template shell profiling metadata remains; debuggable=false does not claim every platform profiling facility is disabled.

Full validator/signature/checksum reports are in `qa/build-verification/`. Signing discovery and device evidence are in `qa/release-signing/`. The earlier 29 desktop/five Python/seven-world debug QA checks remain documented in `ADVANCED_RELEASE.md`; these do not certify a release-mode phone launch.

## Connected Redmi Note 8 installation

The exact validated APK was installed with `adb install --no-incremental -r`, then transferred to `/sdcard/Download/arena_dash_release.apk`. Its phone checksum matches the local APK. ADB returned:

```text
INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package com.example.arenadash signatures do not match newer version; ignoring!
```

The phone's file manager opened that same APK through the normal system Package Installer. Google requested its scan; after explicit approval for this artifact, Google returned **SAFE** at 10:08:29.424. Selecting Install then displayed:

```text
App not installed as package conflicts with an existing package.
```

Actual installation Logcat:

```text
10-12 10:04:05.686  1344  1877 W PackageManager: Existing package com.example.arenadash signatures do not match newer version; ignoring!
10-12 10:04:05.722  1344  1877 D PackageInstallerSession: Marking session 2046778339 as failed: INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package com.example.arenadash signatures do not match newer version; ignoring!
10-12 10:06:03.901 11517 21186 I Finsky  : [11171] VerifyApps: overallScanResult for package=com.example.arenadash: 9
10-12 10:08:29.424 11517 21413 I Finsky  : [11190] VerifyApps: JIT scan response: {"verdict":"SAFE"}
10-12 10:09:56.048  1344  1877 W PackageManager: Existing package com.example.arenadash signatures do not match newer version; ignoring!
10-12 10:09:56.071  1344  1877 D PackageInstallerSession: Marking session 239840581 as failed: INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package com.example.arenadash signatures do not match newer version; ignoring!
```

Confirmed remaining blocker: the existing development installation and new production APK have different signing certificates. The result is not a malformed APK, downgrade, split dependency, unknown-source permission failure, or Play Protect rejection. Play Protect stays enabled. No package-ID change, uninstall, data clearing, or debug-signing fallback was performed. The production APK could not launch because neither update was accepted. The original installed APK's checksum remained unchanged; its player save remained byte-identical (`595eb10a3cc8426228c925e395a40a325ea5936a5cec872dbfde7f96d42cfe68`). The existing game still launches (PID 18160), with screenshot `existing-app-after.png`.

## Secure recovery

The private signing directory contains `RECOVERY.md`. Keep the PKCS12 file and metadata in encrypted offline storage, and preserve its separate Keychain credential through an encrypted Mac backup or an authenticated export into an encrypted password manager. Recovery requires both the private key and password; copying the signing directory alone does not back up the password. Never regenerate this production identity after a loss. Neither its password nor an unencrypted recovery-secret file was written into the project.

Apple documents authenticated Keychain password retrieval in [Keychain Services](https://developer.apple.com/documentation/security/seckeychainfindgenericpassword(_:_:_:_:_:_:_:_:)).
