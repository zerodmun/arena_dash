# Android security and Play Protect audit

Audit date: 2026-10-09. Package: `com.example.arenadash`, version code 1/name 1.0. Engine: `4.7.2.stable.official.ed1daf0bf`. This is a static project/APK audit with limited public advisory checks, not malware certification or a reproduced Play Protect result. The exact warning text and exact APK flagged on the phone have not been supplied. The original APK examined here is a candidate, not a confirmed copy of the flagged installation.

## Findings and changes

| Finding | Evidence | Action/status |
|---|---|---|
| Release presets used the development debug key | All three Android presets selected `debug.keystore` / `androiddebugkey` for release | Cleared production key fields. Release script requires production credentials and rejects the debug key/certificate. No production-signed release was generated. |
| Development MCP configuration was shipped | Original APK contained `assets/opencode.json`; diagnostic APKs also contained it | Excluded developer config, tools, signing material and archives across all presets. Both new APKs and their sparse resource indexes contain no inspected developer/signing identifiers. No credential-named fields were found in that configuration; its contents are not reproduced. |
| SDK tools did not match target SDK | Original Godot editor SDK path selected build-tools 34 fallback for target 36 | Pointed Godot at the already installed SDK with Android 36 tools; final debug export used 36.0.0 without fallback. Build script prefers this local SDK. |
| Custom template overrides and unsafe cross-version fallback | APK paths were custom symlinks; shell script could select any installed engine version | Removed Android custom overrides and arbitrary-version fallback. Godot now resolves its exact-version installed templates. |
| Known native dependency version match | Engine source declares libpng 1.6.58; release `libgodot_android.so` contains that version string | **Remaining risk:** CVE-2026-46675 is fixed in libpng 1.6.59. No newer official Godot release was available in the checked release API. Needs a vendor-patched engine/template or a reviewed custom engine rebuild plus Android validation before production. No claim of vulnerability-free native code. |
| Older APKs remain on disk | Diagnostic/compatibility APKs retain developer config and debug signing | Audited and retained as historical evidence; do not distribute them as hardened release builds. Re-export any diagnostic APK needed for development from the updated presets. |

No gameplay scripts, visual assets, UI layout, movement logic, renderer, orientation, package identity, or save format were changed during this audit. The only source/tool changes are export configuration, the build guard, a read-only APK inspection utility, and documentation. Package identity remains unchanged so existing local data/update paths are preserved.

## Actual APK evidence

| Property | Original development APK | Rebuilt development APK | Unsigned release audit candidate |
|---|---|---|---|
| File | `qa/security-audit/original-debug.apk` | `qa/arena_dash_audited_debug.apk` (security-audit snapshot; normal APK rebuilt later for audio correction) | `qa/arena_dash_release_unsigned.apk` |
| SHA-256 | `fc9fc179a4856ec03aaee884d0db91775ac6197ca1f5a9f65c23807643a5d535` | `f006ea36f860da4460e12f1daf7bda23e42527b73bcade006f8f555e6ae979a0` | `753897f1ff0bd10db99a888a8483ed406025025e051225e1b39280e532c0cbe4` |
| Requested permissions | None | None | None |
| Debuggable | true | true, development only | absent, Android default false |
| Backup / legacy storage | false / false | false / false | false / false |
| Main orientation | landscape (0) | landscape (0) | landscape (0) |
| SDK | min 24 / target 36 / compile 36 | min 24 / target 36 / compile 36 | min 24 / target 36 / compile 36 |
| ABI | arm64-v8a | arm64-v8a | arm64-v8a |
| Signature | Development certificate, v2/v3 verified | Same development certificate, v2/v3 verified | Unsigned by design; signature verification fails as expected |
| Executable provenance | All 13 DEX files and both native libraries match installed debug template | All 13 DEX files and both native libraries match installed debug template | Every DEX/native entry matches installed release template |
| Developer config | opencode.json present | absent | absent |

Developer certificate SHA-256: `0e477ff5a93c87091b58bb83639a949b9df3b474e19da515fabb611645e69dc0`, DN `CN=Android Debug, O=Android, C=US`. This is not a production signing identity. Signing alone neither explains nor resolves a Play Protect warning. The unsigned release candidate is solely for inspection, is not installable as-is, and must not be distributed.

Godot standard release manifest still enables `profileable` with shell access. This differs from `debuggable`: Android documents it as local release profiling with stack traces, not full process-memory access. It was retained from the stock template; there is no profileable export option in the checked standard exporter. See [Android profileable documentation](https://developer.android.com/guide/topics/manifest/profileable-element). The release candidate does not contain the debuggable flag, but it is **not described as disabling every diagnostic facility**.

## Permissions, components, and access

There are no requested permissions to remove in the examined APKs. In particular: no INTERNET, external storage, camera, microphone, contacts, location, SMS, install-packages, boot-completed, notification, overlay, accessibility, or device-administration permissions. Permission switches default false and no custom permissions are configured. Final manifests, not preset assumptions, were used for verification.

- Main `GodotApp` activity is private; its MAIN/LAUNCHER alias is exported, as required to launch the game.
- `ProcessPhoenix` is a private engine restart activity in `:phoenix`; it is not an unexpected background service.
- No services are declared. No app-created scheduled workers or boot receiver were found in project runtime code.
- FileProvider and AndroidX InitializationProvider are private. Stock FileProvider paths include internal files and broad external roots; no application sharing code or grant flow was found. Broad paths would require review if file sharing is added later.
- Both providers have the same `.fileprovider` authority in the standard exported manifest. This follows the checked Godot exporter’s authority rewriting logic; it is a stock configuration oddity, not evidence of injected malware. Provider behavior on the phone remains untested.
- AndroidX ProfileInstallReceiver is exported but protected by `android.permission.DUMP`. That attribute protects incoming calls; the game does **not** request DUMP. Its actions are profile installation/benchmark maintenance from AndroidX, not app data exfiltration.
- No shared UID, custom accessibility/VPN/device-admin components, app-added native libraries, or injected DEX entries were found.

The runtime source index covers networking classes, process execution, shell opening, singleton/native bridges, file I/O, loaders and evaluation. No app HTTP/WebSocket/TCP/UDP requests, shell/process execution, downloaded script/resource-pack loading, Android plugin bridges, or permission requests were found. Loads use packaged `res://` game assets and scenes. Engine code naturally contains filesystem/network/dynamic-library APIs; their presence alone is not proof the game invokes them. This was not instruction-by-instruction reverse engineering of the whole engine.

Persisted `user://arena_dash_save.cfg` contains game progress and preferences, including normalized touch layout, language and audio/display settings. No personal-data collection fields were found. The sole JavaScript evaluation is Web-only, with language restricted to `en`/`id`, updating localStorage and the HTML language; it is not Android-downloaded executable code. Source review does not replace runtime observation on a physical Android device.

## Plugins, Gradle and dependency review

The project uses the standard APK export path with Gradle disabled. No project Android Gradle tree, custom manifests, `.gdap`, `.aar`, `.jar`, `.so`, GDExtension or enabled editor plugin was found outside generated/installed template material. The included Android template source archive and Gradle configuration were inspected as upstream build evidence, not as an active custom project build.

The debug DEX inventory contains 3,887 class definitions, primarily Godot, AndroidX, Kotlin/coroutines, support interfaces and annotations. Class listing and package counts are retained. No added advertising, analytics, billing or custom app SDK was found in the executable comparison.

Nineteen Maven package/version queries to GitHub’s public advisory API returned zero advisory matches on the audit date. Coordinates and responses are saved in `dependency-inventory.json` and `dependency-github-advisories.json`. These query versions come from the installed template’s `.version` metadata and declared Kotlin configuration. Six AndroidX arch/lifecycle version files contain literal Gradle task placeholders, and other class families have no usable version metadata; the resulting inventory is **provisional and incomplete**, not a resolved lockfile/SBOM. No definitive conclusion is made for those versions. OSV POST requests timed out twice. Godot’s public repository advisory endpoint returned an empty list, which does not prove absence of CVEs.

The tag’s third-party inventory records 64 libraries, including optional/editor/non-Android components. It is saved with upstream URLs and vendor-patch notes; not every listed library is established as compiled into this APK. Source versions include FreeType 2.14.3, libpng 1.6.58, libwebp 1.6.0, Mbed TLS 3.6.7, libjpeg-turbo 3.1.3, libvorbis 1.3.7, zlib 1.3.2 and zstd 1.5.7. This is not a complete native CVE scan or reachability assessment.

**CVE-2026-46675:** libpng’s maintainer reports a read-after-free when malformed compressed ancillary PNG chunks are handled; 1.6.59 fixes it. The source/version match warrants a dependency upgrade recommendation. No external PNG import/download path was found in this game, reducing the observed exposure but not fixing the engine. The app’s splash PNG is packaged input. No exploit test or confirmation of the vulnerable binary code path was performed, and this advisory is not attributed to Play Protect. [Primary libpng advisory](https://www.libpng.org/pub/png/libpng.html).

Both packaged shared libraries have a non-executable GNU stack, GNU RELRO, and bind-now dynamic flags. These are inspected ELF properties, not proof of complete hardening, absence of vulnerabilities, or malicious behavior.

## Template provenance

Installed templates were initially project-local symlinks into Godot’s exact-version template directory. Public release metadata and both complete Android APK template members were verified against the official HTTPS Godot release. See `qa/security-audit/template-provenance.json` for completed member results and scope; a member is considered verified only when its full bytes match. The debug member matched SHA-256 `59e0073f0fa59f552684a861d8f4266b0b34b488a140d6657eac7dd70d1a0a0d`; the release member matched `6d1bb2cfa126a1b1c87e064a35b3cbd181bef0ec784dec1efd1d64dffa8be6cb`. The local Android source ZIP was inspected but its entire archive was not remotely compared.

The publisher reports the entire template archive digest `sha256:f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`. The whole 1.28 GB archive was not downloaded and hashed: verification uses precise HTTPS ranges, decompresses full Android members, checks ZIP CRC/size, and compares SHA-256 with the installed files. Do not represent the publisher’s archive digest as independently verified. [Official release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable).

## Verification and remaining work

Completed: actual manifests and package entries inspected; executable comparisons; permission/component inspection; ELF flags; public advisory queries with stated limits; reqa/signature verification; rejection of missing release credentials, unsupported mode, and debug-key release; gameplay smoke, joystick-position and landscape UI suites (zero failures). Sandbox user-log/CA-certificate diagnostics occurred in desktop test logs; they are separate from the passing functional assertions. The final debug export completed using the matching SDK without export errors.

No Android device/emulator was available. Installation, OEM behavior, multitouch on the Redmi Note 8, runtime traffic/filesystem activity, the previously reported shutdown, Play Protect scanning, and final release-certificate signing remain unverified. No production credentials were supplied; the unsigned release candidate does not substitute for a correctly signed release.

Before production: resolve the native libpng advisory with an appropriate engine/template, supply the established production key, rebuild and rerun the APK audit, inspect the final signed manifest/certificate, and validate the actual package on target Android devices. Obtain the exact Play Protect warning and flagged file hash before choosing the proper Google review route. Never disable Play Protect or change package/key identity to evade detection. See [review evidence](PLAY_PROTECT_REVIEW.md) and [build instructions](DEPLOYMENT.md).

Subsequent work: the supplied native audio crash was analyzed and a PCM loop endpoint corrected; see [audio crash report](ANDROID_AUDIO_CRASH.md). The normal `build/arena_dash_debug.apk` now has a different hash recorded in that report’s evidence. Earlier security snapshot hashes above remain historical identities.

October 12 maintenance note: QA evidence moved from `build/` to `qa/`. Historical unsigned APKs and generated sidecars were removed from working folders; their original `build/` paths are retained inside `.maintenance/recovery/original-project.tar.gz`. Historical hashes above do not identify the newly rebuilt deliverable. See [the current report](PROJECT_RESTRUCTURING.md).
