# Project restructuring and Android installation investigation

**Later device verification:** direct installation succeeded after a user-approved Google security scan. The earlier installation blocker/untested status below describes the initial cleanup phase. See [the confirmed cause and live installation report](DIRECT_INSTALL_FIX.md).

Date: 2026-10-12. **Project cleanup and debug APK validation completed. Direct phone installation remains unverified because ADB reports no connected devices. The installation issue is not claimed fixed.**

## Recovery and preservation

The checkout already contained substantial modified, deleted, and untracked user work. No Git reset, checkout, staging, commit, or uninstall was performed. Before restructuring, a full local archive captured the working project, Git repository, ignored build output, cache, assets, signing configuration, and keystore. The archive was read to completion and SHA-256 recorded.

Recovery files are under `.maintenance/recovery/`:

- `original-project.tar.gz`: full original project; mode 0600 because it includes signing material.
- `original-files.json` and `archive-members.txt`: original structure and archive inventory.
- `git-status.txt` and `uncommitted.patch`: original Git state and tracked binary diff.
- `archive.sha256`: archive integrity fingerprint.
- `cleanup-manifest.json`: exact moved/deleted paths, byte counts, and deletion reasons.

For recovery, extract the archive into a separate empty directory, inspect it, and copy back only the affected files. Do not extract over a live checkout with newer work. External installed Godot templates remain external; their original project symlinks were preserved.

437 original asset, scene, gameplay script/UID, and debug-keystore files were compared against the archive: **zero byte mismatches**. All 383 checked UID-bearing source/import descriptors retain their original UIDs. Evidence: `qa/restructuring/source-preservation.json` and `uid-preservation.json`. No gameplay source, save schema, package identifier, version code, or signing credentials changed.

## Original problems and current organization

The existing assets/scenes/scripts/tests/tools/docs separation was appropriate. Moving gameplay resources would add risk without a demonstrated benefit, so those paths remain intact. Flat assets, future-update directories, root resource files, historical source backup ZIPs, and uncertain orphan UID files were preserved.

The original `build/` occupied approximately 4.2 GiB and mixed 13 root APKs with nested QA APKs, screenshots, videos, logs, test saves, captured scripts, import descriptors, native audit files, helper intermediates, and web output. Tests, phone tools, web scripts, and export presets continued generating non-APK content there.

Current output organization:

```text
assets/                 original assets and future-update material
scenes/                 existing scenes, unchanged
scripts/                existing gameplay code, unchanged
tests/                  active tests and their original UIDs
tools/                  build, diagnostic, and test utilities
docs/                   documentation
build/                  arena_dash_debug.apk only
qa/                     retained diagnostics, reports, screenshots, videos, test saves
qa/build-verification/  APK signature, checksum, and export reports
qa/checks/              repeatable headless suite results and logs
dist/web/               future web exports
.maintenance/recovery/  private local recovery archive and manifests
```

341 original root build entries were moved or renamed, including entire QA trees. Historical signed diagnostic APKs are retained under `qa/` as evidence; they are not current deliverables. Log contents may refer to their original `build/` paths. Source tools/tests and documentation paths were updated to the new output locations. `.gdignore` files protect QA, distribution, and recovery trees from registering historical captured scripts or importing captures. These output trees are ignored by Git and excluded from every export preset.

## Removed and retained files; storage

Removed from working folders only after archiving:

- 526 generated QA `.import` descriptors.
- 19 generated APK `.idsig` signing sidecars.
- 3 generated `.sha256` sidecars; current checksums now live outside `build/`.
- 3 historical unsigned APKs: `qa/arena_dash_release_unsigned.apk`, `qa/arena_dash_ui_unsigned.apk`, and `qa/phone-qa/helper/unsigned.apk`.
- The old `build/.gdignore`, since `build/` must contain APKs only.

Total removed: **552 files / 99,150,388 bytes (94.56 MiB)**. Original copies remain inside the recovery archive. Useful and uncertain `.stdout` logs, diagnostic configurations, test saves, source snapshots, screenshots, videos, and signed helper/diagnostic APKs were retained outside `build/`. No original assets, active tests, production dependencies, player saves, or signing keys were deleted. The active `.godot/` cache was retained to avoid unnecessary cache churn.

**This is not a net disk-space reduction:** the full recovery archive adds 4,229,862,233 bytes (3.94 GiB). QA evidence was moved, not erased. Retaining a full recovery point takes precedence over discarding uncertain evidence.

## Build changes

`./build_apk.sh debug` now publishes `build/arena_dash_debug.apk`. Release output remains `build/arena_dash_release.apk`, conditional on existing production credentials.

Exports run in a fresh system temporary directory. Signature verification, 16 KiB native-library/ZIP alignment verification, ZIP CRC checks, and presence of the manifest/arm64 libraries run before atomic publication. Failed builds retain the previous deliverable. Temporary APKs, signing sidecars, and engine logs stay outside `build/`; signature, checksum, and export evidence is written under `qa/build-verification/`. Nested custom outputs under `build/` are rejected; diagnostic outputs can use `qa/`.

The build script prefers the existing local SDK and refuses to silently create a new debug signing identity if the original key is missing. It retains the existing exact-version custom template links; final native and DEX entries match the installed template. Production key generation/replacement was not performed. Existing guards reject absent production credentials and debug signing for production.

Web exports and the local server now use `dist/web/`. Diagnostic export presets, phone tools, helper builds, and desktop test outputs now use `qa/`. Desktop tests formerly using `user://` review saves now use workspace QA saves; their Android review-save locations are unchanged.

Two stale tests were repaired without changing application behavior: equipment UI purchase funding now accommodates the existing 1,680-coin Nova Burst price, and landscape navigation checks preview selection separately from equipping. `tools/run_project_checks.py` runs the existing scene suites and records exits/timeouts under `qa/checks/`.

## Validation

Godot 4.7.2 headless import completed without script parse or missing-resource errors. Literal dependency audit found no missing production dependency; dynamic fire-icon prefixes and deliberately missing test resources were distinguished from actual missing resources. Full suites cover Home/Hangar state, all catalog equipment textures, firing, movement, controls, purchases, saved ownership/loadout, localization, loading, progression, and soak behavior. Headless checks do not establish visual rendering quality or physical Android behavior.

All **28 scene suites passed** after the two documented stale-test corrections. This includes 20 accelerated simulated minutes of performance soak and approximately 98 seconds of desktop headless stability stress. See `qa/restructuring/final-results.json` for consolidated latest results. The five Python capture-tool unit tests passed; they use synthetic ADB/time and are **not phone evidence**. Shell syntax validation passed. `git diff --check` reports existing trailing whitespace in the user's original `icon.svg` modifications; that original asset was preserved unchanged.

Some test exits retain ObjectDB/resource teardown warnings. Sandbox runs also emit macOS certificate-access diagnostics, and editor/export runs report inability to save global editor settings. These are disclosed in retained logs; they did not prevent APK export or the reported passing suite assertions. No phone runtime Logcat was collected.

## Final APK and installation investigation

Artifact: `build/arena_dash_debug.apk` (development signing, not a production release).

- SHA-256: `d41aa34cef3b0965c8ad598eacea7c22a9cba3c7418f298ad107ce5f693a7d69`.
- Package: `com.example.arenadash`; version name 1.0 / code 1, unchanged.
- Minimum SDK 24; target/compile SDK 36; arm64-v8a.
- Full standalone APK: no manifest split requirement; DEX/native template entries are complete.
- No requested permissions or packaged inspected developer/signing files. No QA/test/tool/recovery folders were found in the APK.
- APK signature v2/v3 verified; ZIP integrity and `zipalign -c -P 16 4` passed.
- Debug certificate SHA-256: `0e477ff5a93c87091b58bb83639a949b9df3b474e19da515fabb611645e69dc0`, identical to the original artifact. Certificate validity: 2026-10-09 to 2054-02-24. Details retained in `qa/restructuring/debug-certificate.txt`.
- All inspected executable entries match the installed debug template; no missing template binaries.

Audit evidence: `qa/restructuring/apk-audit.json`, its decoded manifest, and `qa/build-verification/arena_dash_debug.apk.*`.

The absence of v1 signing is not evidence of the reported failure: Android supports v2 from Android 7/API 24, matching this APK's minimum SDK. [Android APK v2 specification](https://source.android.com/docs/security/features/apksigning/v2). Normal installer restrictions and pending user approval differ from privileged installation flows, but no such restriction was established on this phone. [Android PackageInstaller status documentation](https://developer.android.com/reference/android/content/pm/PackageInstaller).

**Confirmed direct-install root cause: unknown.** With ADB access enabled outside the sandbox, repeated `adb devices -l` calls returned only an empty device list. A reconnect/unlock/USB-debugging authorization request was sent during the work. No accessible physical device appeared.

Consequently, ADB installation of this exact APK, file transfer/hash comparison, installed-app certificate/version comparison, device SDK/ABI check, installer permission/policy inspection, direct installer launch/error capture, phone Home/Hangar/gameplay launch, real player-balance/ownership persistence, and device Logcat were **not performed**. No uninstall, data clear, security-setting bypass, package rename, key replacement, or downgrade was attempted. Device player data was not touched, but preservation on an installed update remains unverified.

Production credential variables and release preset key fields are absent. The release guard was exercised and correctly rejected the build; no release APK or placeholder was produced.

To finish the installation investigation, reconnect and authorize the phone, then first record its installed package/version/certificate and safely preserve accessible data. Compare that identity with the final APK before any update; verify ADB installation of the exact bytes, transfer those same bytes and compare hashes, open them through the actual phone file manager, and retain installer/logcat evidence. Any required phone permission interaction must be handled through the normal Android UI. Choose an export/configuration correction only after the actual error is identified.
