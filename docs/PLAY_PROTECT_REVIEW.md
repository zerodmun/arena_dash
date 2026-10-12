# Play Protect review preparation

Prepared 2026-10-09. **Draft evidence only; no appeal or APK upload has been submitted.** We do not yet know whether the reported screen was an unrecognized/unscanned-app prompt or a potentially harmful app classification. Obtain the exact wording before selecting the review path. [Google warning categories](https://support.google.com/work/android/answer/15162069?hl=en-GB).

## Missing evidence to collect

- Exact warning text/category and a screenshot retained locally; installation date/time and install source.
- Exact flagged APK file, SHA-256, package/version, signing certificate SHA-256. Do not assume it is one of the candidates examined here.
- Redmi Note 8 Android/MIUI version, security patch date, Google Play services / Play Store versions, and Play Protect scan/detection details, including any app identifier/threat name.
- Whether the warning occurs on installation, a later scan, or while launching; other devices affected and their Android versions.
- Final production-signed artifact and intended distribution channel, after native-dependency remediation and device testing. Keystore passwords and private keys must not accompany the submission.

## Examined artifact identities

Application: Arena Dash, offline 2D landscape combat game built with Godot 4.7.2. Package `com.example.arenadash`, version 1.0/code 1, min SDK 24/target 36, arm64-v8a.

| Artifact | SHA-256 | Signing / role |
|---|---|---|
| Original candidate, retained at `qa/security-audit/original-debug.apk` | `fc9fc179a4856ec03aaee884d0db91775ac6197ca1f5a9f65c23807643a5d535` | Android Debug certificate; not confirmed as the user's flagged APK |
| Security-audit snapshot `qa/arena_dash_audited_debug.apk` | `f006ea36f860da4460e12f1daf7bda23e42527b73bcade006f8f555e6ae979a0` | Development-only, verified v2/v3; no claim of Play Protect clearance |
| `qa/arena_dash_release_unsigned.apk` | `753897f1ff0bd10db99a888a8483ed406025025e051225e1b39280e532c0cbe4` | Unsigned inspection candidate, not installable/distributable |

Development certificate SHA-256: `0e477ff5a93c87091b58bb83639a949b9df3b474e19da515fabb611645e69dc0`. No production signing identity was available, so production certificate details are pending.

## Supporting evidence

- Decoded manifests and APK JSON inventories in `qa/security-audit/`: original, audited-debug, unsigned-release and historical diagnostic APKs.
- Both complete Android debug/release template files match bytes downloaded from the official Godot HTTPS release. Recorded hashes and scope: `template-provenance.json`. Every examined DEX and native-library entry matches the corresponding installed template; no added executable library/DEX was found.
- No requested permissions, services, boot receivers or application-added network/dynamic-code/download/unauthorized-data access paths found by static project/manifest inspection.
- Launcher alias and protected AndroidX profiling receiver are exported; main activity and providers are private. Release candidate is non-debuggable but remains shell-profileable as the stock template specifies.
- Original APK included development `opencode.json`; newly built APKs and resource indexes exclude it and inspected signing/developer files. Original configuration was not executed by the game in the reviewed runtime paths.
- Release presets formerly used a debug key; that setting has been removed. Build guards prevent accidental debug-signed production releases. Package identity was preserved.
- Dependency check: zero advisory matches across 19 provisional Maven package/version queries. Some metadata is unresolved; no complete native SBOM or vulnerability-free claim.
- Disclose remaining native version match: libpng 1.6.58 versus CVE-2026-46675 fixed in 1.6.59. No external PNG-loading path found in the game; remediation/compiled-code reachability is pending. This must not be omitted to portray the application as fully audited and safe.
- Physical Android runtime behavior and the Play Protect warning have not been reproduced. The previously reported Redmi Note 8 shutdown is also unresolved.

## Neutral review message draft

> We request clarification and review of the Play Protect classification for Arena Dash, package com.example.arenadash. The submitted artifact's SHA-256, version, signing certificate fingerprint, exact warning text, affected device/software versions and installation source are attached [fill in confirmed details]. Our static audit found no requested Android permissions or app-added services/network/downloading-code paths, and the DEX/native entries match official Godot templates. We removed mistakenly bundled development configuration and corrected production signing configuration. The supporting audit states its limits and any outstanding native dependency findings. Please advise on the specific detected category and whether the submitted artifact requires further remediation or a false-positive correction.

Replace all placeholders with the exact artifact submitted for review. Do not attach the unsigned candidate as though it were an installable release, describe the debug certificate as production, claim Google acceptance, or assert the libpng advisory caused the warning.

For confirmed potentially harmful app classification, use Google's [Play Protect appeal form](https://support.google.com/googleplay/android-developer/contact/protectappeals) and [classification/review guidance](https://support.google.com/transparencyreport/answer/9150182?hl=en-GB). Preparing the packet does not submit it. Do not disable Play Protect, obfuscate suspicious behavior, randomize package/signing identity, or encourage users to bypass the warning.

The normal `build/arena_dash_debug.apk` was subsequently rebuilt for the [native audio correction](ANDROID_AUDIO_CRASH.md). Use `qa/audio-crash-audit/apk-verification.json` for its current hash; do not submit it under the historical security snapshot identity above.

October 12 maintenance note: QA evidence moved from `build/` to `qa/`. Historical unsigned APKs and generated sidecars were removed from working folders; their original `build/` paths are retained inside `.maintenance/recovery/original-project.tar.gz`. Historical hashes above do not identify the newly rebuilt deliverable. See [the current report](PROJECT_RESTRUCTURING.md).

October 12 later device verification: the user supplied the unfamiliar-developer block screenshot. Live reproduction requested an unfamiliar-app scan. With explicit user authorization, the exact APK was uploaded by Play Protect for scanning; Google returned SAFE and two normal installer updates succeeded. No appeal was submitted. Historical draft status above applies to the earlier audit. See [current evidence](DIRECT_INSTALL_FIX.md).
