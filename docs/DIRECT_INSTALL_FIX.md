# Confirmed direct-install cause and resolution

Verified on 2026-10-12, Asia/Jakarta, using the USB-connected Redmi Note 8 (`13ff9514`). **Normal Android installation now succeeds. The exact APK was installed through Android Files twice, and the game opened to Home. Play Protect remained enabled. No APK/code/signing changes were needed.**

## Exact artifact

`build/arena_dash_debug.apk`, 57,812,783 bytes.

SHA-256: `d41aa34cef3b0965c8ad598eacea7c22a9cba3c7418f298ad107ce5f693a7d69`.

The local build, the user's existing `/sdcard/Documents/arena_dash_debug.apk`, the newly transferred `/sdcard/Download/arena_dash_debug.apk`, and the final installed `base.apk` all have this exact checksum. This proves the investigation and successful normal installs used the same bytes; transfer corruption was ruled out.

Package `com.example.arenadash`; version 1.0/code 1; minimum SDK 24/target SDK 36; arm64-v8a. Phone: Android 13/API 33 with arm64 support. The MIUI version property is empty; fingerprint is `Xiaomi/ginkgo/ginkgo:13/TQ3A.230901.001.B1/2308:userdebug/release-keys`.

`apksigner verify --verbose --print-certs` passed with v2/v3 signatures. Debug certificate SHA-256 remains `0e477ff5a93c87091b58bb83639a949b9df3b474e19da515fabb611645e69dc0`. `zipalign -c -P 16 4` and ZIP CRC verification passed. The existing decoded manifest and native/DEX inventory establish a complete standalone APK, without split requirements. This is a development APK; it was not re-signed or represented as a production release.

## Actual rejection and confirmed cause

The user supplied a screen reading “App blocked to protect your device”, with the explanation that Play Protect had not seen an app from this developer before.

In the live reproduction, Android Files launched `com.google.android.packageinstaller`; its APK parsing and normal update confirmation succeeded. The update then reached Google Play Protect and stopped at **“App scan recommended”**, explaining that Google had not seen this app before and requesting a security scan. It offered **Scan app** and **Don't install app**.

This was an unfamiliar-app security scan requiring user consent, not an APK parse/signature/ABI/downgrade rejection. The same APK subsequently passed Google's scan and installed twice without an APK modification. No harmful-app verdict was observed during this reproduction.

The precise logged value before consent was **Google Play Protect/Finsky `overallScanResult = 9`**. This is a Play Protect internal verdict, **not an Android PackageInstaller error-code mapping**. No standard `INSTALL_FAILED_*` rejection was returned in the completed flow; installation was awaiting the security scan and user action. It would be inaccurate to invent an `INSTALL_FAILED_VERIFICATION_FAILURE` code.

## Relevant Logcat evidence

Times below are the phone's Asia/Jakarta clock. Relevant excerpts are retained in `qa/direct-install-20261012/installer-evidence.txt`; the full local capture is `logcat-live.txt`.

```text
08:46:01.614 VerificationCheck: Verifying com.example.arenadash
08:46:01.688 VerificationCheck: Verification finished ... Result: Pass(reason=UNSPECIFIED, message=null)
08:46:01.918 Finsky: APK Analysis scan finished ... Verdict: 0
08:46:02.824 Finsky: Verification package=com.example.arenadash, id=80, response=9, upload_requested=false
08:46:02.830 Finsky: overallScanResult for package=com.example.arenadash: 9
08:46:02.866 ActivityTaskManager: ... PlayProtectDialogsActivity
08:53:23.035 Finsky: Stripped APK Bundle upload starting
08:53:38.059 Finsky: JIT scan response: {"verdict":"SAFE"}
08:54:27.029 Finsky: app installation complete for com.example.arenadash
08:58:29.743 Finsky: Verification package=com.example.arenadash, id=81, response=15, upload_requested=false
08:58:29.860 Finsky: Install-time verification complete ... package_name=com.example.arenadash
08:58:31.072 Finsky: app installation complete for com.example.arenadash
```

Both completed normal installations showed **“App installed.”** The final installed-package record names `installerPackageName=com.google.android.packageinstaller`, rather than ADB. First normal update: approximately 08:54:24. Second update from Download: approximately 08:58:29. The second install completed without another scan approval/upload prompt. The internal value 15 is recorded as observed, without claiming an undocumented universal meaning.

The read-only setting `verifier_verify_adb_installs` was **0 before the scan and remained 0 afterward**. This explains why the successful ADB route did not exercise the same required Play Protect scan as the file-manager route. No verifier setting was changed. Global verifier consent was already 1; the verifier-enable setting was unset/default, and active Play Protect scanning was observed directly. Files by Google's existing `REQUEST_INSTALL_PACKAGES` app-op was already `allow`; no unknown-source permission was enabled by this investigation.

Unrelated AppsFilter “BLOCKED” messages concern application visibility; fs-verity probe errors also occurred during successful installs. Neither was treated as the direct-install rejection.

## Resolution performed

1. Verified the exact existing APK and matching phone Documents copy.
2. Executed `adb -s 13ff9514 install -r build/arena_dash_debug.apk`: **Success**. No uninstall, downgrade flag, or data clear was used.
3. Transferred identical bytes to Download and verified SHA-256.
4. Opened the APK through Android Files and the normal package installer; captured the live Play Protect prompt and Logcat.
5. Asked the user to authorize sending this exact APK to Google. The user explicitly approved the security scan.
6. Pressed **Scan app**. Google returned **SAFE**, and the phone displayed **“This app looks safe — You can continue to install it.”**
7. Pressed **Install** through that approved normal UI. The installer reported **App installed**.
8. Opened the installed game; observed the rendered Arena Dash Home screen and running Godot activity.
9. Repeated the normal update from the transferred Download copy. It again reported **App installed**, without another scan approval/upload prompt. Final installed APK bytes still match the original checksum.

No “install anyway” exception, Play Protect disablement, security-setting modification, package-name change, new key, re-signing, or gameplay/UI/source/export change was used. No rebuild was performed: rebuilding would change the exact artifact under investigation despite no confirmed export defect. The already generated standalone APK was validated and retained unchanged. Only investigation evidence and documentation were added/updated in this request. Root `build/` still contains only this validated APK.

For the same security prompt, the applicable action is the normal **Scan app → wait for Google's verdict → Install if marked safe** flow. If Google instead blocks/classifies an APK as harmful, preserve its exact bytes and warning for review rather than disabling protection or changing its identity. [Google's developer guidance for Play Protect warnings](https://developers.google.com/android/play-protect/warning-dev-guidance).

## Launch and data preservation

Home rendered successfully after normal installation; the process remained alive and logs reached `STARTUP: menu ready`. Screenshot: `qa/direct-install-20261012/home.png`. The startup capture includes nonfatal Adreno/graphics format-probe diagnostics; no current launch-process Godot script error or fatal crash was observed in the captured launch window. This was a launch check, not a long gameplay soak.

**At the start of this investigation, Android reported that `com.example.arenadash` was not installed**, and `pm list packages -u arenadash` listed only the separate `com.arenadash.qa`. The first ADB install created the main package at 08:40:03. Therefore historical main-game coin balances/purchases/progress could not be compared with a pre-existing installed game; Home showed the fresh-install balance of 0. No progress-reset operation was performed. The separate QA package was not updated or uninstalled. Normal updates retained the main package's UID 10263 and original first-install timestamp.

Early attempted save-hash commands produced directory listings rather than valid hashes; those files are retained as raw evidence and are not represented as a successful save-integrity test. The main app had no `files/` directory before first launch, and afterward only runtime cache directories were observed. No historical player save preservation claim is made beyond not performing any uninstall/data-clear/reset operation.

## Results and limits

| Check | Result |
|---|---|
| Exact APK identity, transferred copies, installed bytes | All SHA-256 values match |
| Signature / alignment / ZIP integrity | Passed |
| ADB installation | Success |
| Original direct-install blocker | Play Protect unfamiliar-app scan approval |
| User-approved Google security scan | SAFE |
| Normal installer, original Documents APK | App installed |
| Normal installer, transferred Download APK | App installed; no repeated scan approval |
| Launch after normal install | Rendered Home, running game |
| Application/signing/gameplay changes | None |
| Current artifact on this connected phone | No remaining installation blocker |
| Historical player progress comparison | Not possible: main package absent at the start |

A fresh installation with this APK was not reproduced after ADB installation, because uninstalling is forbidden. Verified normal installs were data-preserving updates. Scan/reputation decisions are controlled by Google: a changed APK, another phone, or a future policy decision may require another scan. The result does not promise permanent approval for arbitrary future builds or constitute production/store release validation.
