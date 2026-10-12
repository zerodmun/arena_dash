# Physical Android verification — 2026-10-10

This report supersedes the previous “no authorized device” limitation for this session. Results are populated only from captured phone evidence.

## Device and deployment

An authorized USB device was detected with `adb devices -l`: Redmi Note 8, serial `13ff9514`, Android 13 / API 33, arm64-v8a, Qualcomm Adreno 610. Physical display is 1080 × 2340; game screenshots are 2340 × 1080 landscape. Vulkan 1.1.128 / Forward Mobile and `AUDIO: stage=full driver=Android` were logged on the phone. The package was not installed when discovery began. The corrected normal debug APK installed successfully and launched through its launcher.

## Instrumentation and changes

- `scripts/perf_diagnostics.gd`: opt-in touch test keeps the existing debug-only sustained-combat configuration but disables synthetic fire. Telemetry reports actual joystick output, fire input and player position. Normal play and release behavior remain unchanged.
- `export_presets.cfg`: separate `Android Touch Stability Diagnostic` preset with `--perf --audio-stage=full --stability-auto --stability-touch`. Full audio, normal renderer, fixed landscape, existing package. Diagnostic invulnerability and suppression of mission completion are test accommodations, not changes to production gameplay.
- `tools/android_multitouch/`: standalone, separately installed QA instrumentation injects two pointer IDs through Android UiAutomation, with proper pointer-down/move/pointer-up sequences. Circular directional motion and held firing are generated at coordinates derived from the actual landscape resolution. It declares no permissions and is excluded from game exports.
- `tools/run_phone_multitouch_soak.py`: installs, starts, captures Logcat, records process identity, takes screenshots/memory snapshots, and verifies active gameplay with simultaneous input rather than process survival alone.

Android API references: [UiAutomation injection](https://developer.android.com/reference/android/app/UiAutomation), [MotionEvent pointers](https://developer.android.com/reference/android/view/MotionEvent). These document the injection mechanism; successful game input is established independently by phone telemetry and screenshots.

The previous PCM endpoint fix remains in place: engine loop frame count 118080, valid final index 118079. See [native audio investigation](ANDROID_AUDIO_CRASH.md) for register/address correlation, importer change and loading-time bounds validation. No audio was removed or disabled for the full-audio soak.

## Evidence integrity and unsuccessful attempts

Evidence is under `qa/phone-qa/`, excluded from game exports. The first synchronous helper attempt accepted input then reported rejection at event 194; it is not a completed input test. The helper was changed to asynchronous injection. The first monitored soak stopped because Logcat ended after approximately 15 seconds. Its result explicitly records `passed: false`; there was no captured native fault in that interval. A normal APK export was running concurrently; disruption of ADB is a possibility, not a proven cause. The repeat runs without concurrent export.

Final duration and outcome will be added after the physical test finishes. No crash-free claim follows merely from installation, process survival, or the prior desktop test.

## Verified physical-phone results

The corrected full-audio diagnostic sustained continuous unpaused gameplay for **1006.367 seconds (16 minutes 46 seconds)** across 202 telemetry samples, all belonging to Arena Dash PID 6136. Mission time advanced from 4.867 to 1011.233 seconds. Recovered on-device logs bridge the ADB interruption; the largest telemetry interval is 5.037 seconds. Reconnected `pidof` still returned 6136. Historical exit information contains only preceding force-stops/installations, not a crash of that running process.

Every sample records both joystick and fire pressed. Before interruption, the helper logged 10540 events / 532.474 seconds of completed directional touch cycles; event 10577 was rejected when its UiAutomation connection died. The QA helper, **com.arenadash.qa PID 24313**, subsequently raised `DeadObjectException` during instrumentation disconnect. This is separate from Arena Dash, which continued moving/firing with the final input held. A resumed directional helper run then completed **90.011 seconds, 1777 accepted events, instrumentation success code -1**. Therefore the evidence verifies over ten minutes of continuous actual gameplay and over ten minutes total of directional multitouch automation, but **does not represent a single uninterrupted ten-minute helper execution**. The original monitor's failed result is preserved.

No Arena Dash SIGSEGV, Java fatal exception, ANR, or script error is present in the recovered full-audio session. Audio node count stays 17. Static memory after 120 seconds is 68,296,340–68,584,688 bytes. FPS ranges 36–60 across the extended session; most central-arena samples are around 40–45. These are stability results, not a 60 FPS performance certification. Device thermal-service errors about unavailable CPU frequency limits were observed; they are not the application's crash trace.

Evidence: `qa/phone-qa/soak-repeat/recovered-verification.json`, `combined-perf.json`, original and recovered Logcat files, `resumed-multitouch.txt`, screenshots, memory snapshots, and recovered process-exit information.

## Original crash reproduced on the same phone

The preserved pre-fix APK (`arena_dash_audited_debug.apk`, SHA-256 `f006ea36f860da4460e12f1daf7bda23e42527b73bcade006f8f555e6ae979a0`) was reinstalled only for comparison. In its first mission it terminated with **SIGSEGV / SEGV_ACCERR on AudioTrack at 2026-10-10 09:45:55**, PID 6134. This is an actual native crash, not a normal game defeat, forced stop, ANR, or disconnection. The captured native stack repeats the original faulting PC `0x2f8f814` and exact official engine Build ID.

The new crash has sample index x8 = `0x1cd40` = 118080, tagged x22 = `0xb400007a5b5c4580`. Removing the pointer's top-byte tag gives PCM base `0x7a5b5c4580`; adding `118080 × 2` produces **`0x7a5b5fe000`, exactly the reported fault address**. Direct inspection of resources extracted from both APKs confirms equal 236160-byte mono16 / 24 kHz buffers: old endpoint 118080, corrected endpoint 118079. This independently reproduces and corroborates the one-past-end PCM loop diagnosis.

Evidence: `qa/phone-qa/pre-fix-comparison/logcat.txt`, `exit-info.txt`, `crash-correlation.json`, screenshots, and `qa/phone-qa/pcm-comparison.txt`. No permanent audio removal or renderer change was used to obtain the corrected result.

## Normal build and remaining scope

The normal APK was rebuilt and verified with v2/v3 development signing. SHA-256: `ffa26bd2d3e9b2c34c8d62d93c494696ef3e73ac7eab81ed86a85bae11bb846c`. Static inspection confirms fixed landscape, no requested permissions, no packaged signing/developer files, and all executable entries match the installed official debug template. It has no automatic-gameplay or isolation flags. Production signing credentials remain unavailable.

The phone test covers Cyber Matrix, Valkyrie, and Plasma Bolt. It does not establish every possible phone, ship, weapon, planet, or long-duration combination. Prior desktop regression coverage remains separate. Play Protect clearance and previously reported dependency risks are not resolved by a successful gameplay test.

The corrected normal APK was restored and tested; final transition results are recorded below.

## Final normal-build and transition results

The corrected normal APK installed successfully and completed three ordinary launcher → Home → Hangar → mission starts, each monitored for at least 25 seconds after deployment. All 15 sampled process checks retained their expected PID within each run; process changes between runs were intentional force-stops. Each 20-second real multitouch run completed successfully (398 accepted events each). Total comparison capture was 130.29 seconds, with no native crash, ANR, Java fatal exception, or script error. Normal in-game mission defeats were observed and distinguished from process termination.

In-game Retry Mission, Pause, Resume Flight, Return to Hangar, and redeployment were subsequently exercised and visually checked from screenshots, retaining PID 20831 throughout. The final state is the Hangar. The standalone QA helper was uninstalled successfully. The installed game APK was pulled back from the phone and its SHA-256 matched the rebuilt normal APK exactly; see `qa/phone-qa/installed-final-verification.json`.

Evidence: `qa/phone-qa/corrected-normal/` (installation, Logcat, screenshots, three input results, process/exit checks) and `qa/phone-qa/transitions/` (retry/pause/resume/Hangar/redeploy screenshots, final PID, logs, helper removal).

Project/audio/control regression checks passed: Audio System 0 failures, Control Position 0 failures, and capture-tool tests 5 passing. Sandboxed desktop checks logged host log-directory/CA-access warnings; those are distinct from phone runtime results. Final APK signature and manifest/native-content checks are saved in `qa/phone-qa/normal-apk-audit.json` and its manifest XML.

No human gameplay or manual log collection was required. No connected-device blocker remains. The USB/UiAutomation interruption limits the clean-run automation claim, and one device/configuration cannot guarantee universal stability. Full game audio, movement mechanics, UI design and landscape orientation are preserved.
