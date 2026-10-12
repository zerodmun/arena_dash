# Android stability investigation and UI refinement

> Physical-device follow-up (2026-10-10): the original AudioTrack crash was reproduced on the connected Redmi Note 8. The corrected full-audio build sustained over 16 minutes of verified gameplay. See [physical-phone QA](ANDROID_PHONE_QA.md) for evidence, the instrumentation interruption, and final APK identity. The no-device statements below describe the earlier session.

Updated 2026-10-09. The supplied Redmi Note 8 Logcat now confirms SIGSEGV/SEGV_ACCERR on AudioTrack, Android 13 (`Xiaomi/ginkgo`, userdebug). See [native audio crash diagnosis and fix](ANDROID_AUDIO_CRASH.md) for the new register-level evidence, corrected PCM endpoint, APKs and current test results. Earlier investigation details below are retained as history.

## Current status

**An invalid engine-loop PCM endpoint has been corrected and matches the supplied native fault exactly. On-device elimination of the crash remains unverified.** ADB reports no authorized connected device. The supplied log and diagnosis are retained under `qa/audio-crash-audit/`. Desktop results do not certify the Redmi audio callback. No ten-minute Android session was possible.

The existing game already bounds enemies (14–28 by planet), hostile shots (64), and pickups (32). Scene-owned pools prewarm 96 player shots, 64 hostile shots, and 24 CPU particle bursts. Projectiles expire, inactive shots leave collision/groups, one-shot bursts recycle, score labels expire, and audio has a fixed player pool. No gameplay limits, difficulty, fire rates, or weapons were reduced during this investigation.

## Confirmed defect and fix

A controlled reproduction stopped gameplay during meteor descent. Before the fix, **two `mission_hazards` nodes remained** after the descent: warning and meteor. `main.gd` returned on `not Game.is_running` before freeing these visuals. The fix frees valid, non-queued visuals before the mission-state guard. Generation checks still prevent damage from a preceding mission.

`tests/meteor_lifecycle.tscn` now verifies cancellation before descent, cancellation during descent, and retry cleanup. All pass. This is a confirmed cleanup defect, **not evidence that it caused the Android process shutdown**.

## Validation completed

- Native desktop Mobile renderer (Metal, Apple M1): 12 real seconds of sustained fire per planet, eight planets, active audio decoding/playback at low master volume. No script errors or process termination. Audio nodes stayed at 17. Nodes varied with bounded active combat (833–907); per-map static memory was approximately 66–83 MB and varies with artwork/resources. The runner uses invulnerability and prevents mission completion to sustain combat; this is a stress scenario, not ordinary player progression.
- Headless accelerated soak after the fix: 20 simulated minutes, 0 failures. Nodes ranged 987–1026. Settled static memory was 63.12 MB at the midpoint and 63.14 MB at completion. Audio is disabled for this accelerated run; it is not an Android GPU or audio-driver test.
- Game smoke, campaign combat, localization/control editing, control input, three-star progression, performance safety, audio, meteor lifecycle, and native rendered landscape UI suites passed. Landscape UI verifies 16:9, 18:9, 19.5:9, 20:9, smaller windows, letterboxing, simulated safe areas, consistent rounded styles, symmetric padding, and centered button alignment.
- Standard signed Android debug export and diagnostic exports retain the configured package/signing identity, arm64 target, immersive mode, landscape orientation, and resource filters. APK signatures and manifest orientation are checked after export. No APK was installed on a device here.

Artifacts: `qa/stability-stress.json`, `qa/performance-soak.json`, rendered `qa/landscape_*.png`, and `qa/refinement-*.log`. Some sandboxed headless logs include the host macOS certificate-store access diagnostic; native renderer logs do not have that diagnostic.

## Debug builds for the device investigation

The standard `Android` preset remains on the original Mobile renderer. Two additional debug presets use the same Android configuration:

```sh
godot --headless --path . --export-debug "Android Diagnostic" qa/arena_dash_diagnostic.apk
godot --headless --path . --export-debug "Android Compatibility Diagnostic" qa/arena_dash_compatibility_diagnostic.apk
```

Both include opt-in `--perf` telemetry: device model, engine version, rendering method/driver, node/orphan counts, static/video memory, combat counts, frame timing, and draw calls every five seconds. Ordinary builds do not collect these metrics. The compatibility variant explicitly selects OpenGL for a controlled renderer comparison; it is **not a proven fix** and does not change the standard renderer.

Connect the Redmi through USB, enable USB debugging, authorize the computer, and capture a ten-minute session:

```sh
python3 tools/capture_android_stability.py --apk qa/arena_dash_diagnostic.apk --output qa/android-mobile-capture
```

Play continuously while the script captures filtered Logcat, process presence, device/Android details, app memory, and available Android exit-reason records. If the process exits early, it retains partial evidence and reports failure to complete the duration. A surviving process alone does not establish responsive or correct gameplay; inspect the session manually. Android exit-info support depends on OS version. Multiple devices require `--serial`. The tool does not clear global logs, uninstall the app, or erase saved progress. An incompatible signing identity causes installation to fail rather than deleting data.

Repeat with the compatibility diagnostic APK in a separate output folder if the Mobile variant crashes. Compare logs before deciding whether renderer/GPU behavior, OOM, audio, or another subsystem is responsible. Native backtraces can be symbolized using matching debug symbols following the [Godot Android crash guide](https://docs.godotengine.org/en/stable/tutorials/platform/android/resolving_crashes_on_android.html).

## Recurring crash follow-up: 2026-10-09

The user reports that the Android app still closes around ten seconds. The prior meteor cleanup fix did not resolve that report. **No further crash fix is claimed.**

ADB was checked outside the host sandbox: the device list is empty. The installed emulator reports no configured AVDs, and no Android system images are installed. Therefore actual Logcat, tombstones, Android memory/exit records and a ten-minute Android gameplay session could not be collected. Android version remains unknown. The missing evidence prevents distinguishing a native engine/GPU failure, Java exception, low-memory kill or another termination cause.

The code investigation covered mission start/stop and scene changes, spawning cadence, pooled projectiles/CPU particles, collision callbacks, meteor timers, asynchronous music/audio pools and signal/lifetime handling. No timed `SceneTree.quit`/process-kill path was found in game scripts. No additional engine, renderer, memory-limit, weapon, enemy-count or audio-disable change was made without a reproduced cause.

The current build was exercised on the desktop Mobile/Metal renderer with audio enabled: eight planets, twelve real seconds each. All passed beyond the reported ten-second window with no script/native termination. This is desktop regression evidence only, not Android crash verification. Raw evidence is `qa/stability-stress.json` and `qa/recurring-crash-desktop.log`. Static/video memory counters are engine measurements, not Android PSS or device GPU-driver allocations.

Diagnostic builds now emit mission start/failure/completion and application lifecycle events, plus active gameplay state, mission elapsed time, map/ship/weapon, audio node count and uptime. This helps distinguish a game-over screen from process death and identifies the event before a fatal trace.

The capture tool now includes main/system/crash/events buffers, native fatal/debug records, AndroidRuntime errors, ActivityManager and process-kill/death events, and unknown-tag errors. It saves before/after exit records, APK SHA-256, device ABI/graphics properties, memory and PID samples. Connection loss, Logcat failure and PID replacement terminate verification with distinct reasons. `gameplay_verified` stays false: reaching the duration only proves process survival until logs and actual gameplay are reviewed. Five mocked capture-tool tests cover these failure modes; they are not device evidence.

Run `python3 tests/test_android_capture.py` for the tooling tests. For a real device, run the ten-minute capture command above, play continuously, and supply the resulting directory. Native traces require symbols matching the exported Godot template/build; see the linked Godot crash guide.

## Current button contrast

Buttons retain 30px capsule curves and shared layered state artwork. Primary controls now use muted warm amber/copper with dark navy labels; secondary controls use lighter steel blue with warm off-white labels; selected controls use muted teal. Disabled controls use neutral gray-blue. Cached artwork, centering, existing layouts and landscape-only presentation are retained. Native button tests verify at least 4.5:1 label contrast at the text band in normal/hover/pressed states and at least 2:1 normal face contrast against the representative dark panel. See [Button design](BUTTON_DESIGN.md) for styling and validation.

Current exports: standard, Mobile diagnostic and OpenGL comparison diagnostic APKs were rebuilt successfully with the new button palette. Signatures are verified and the manifest remains fixed landscape. These APKs are not certified crash fixes. UI contrast/state, landscape, bilingual layout, control positioning/input and performance safety checks pass.

The latest audio correction passed a 600-second real CoreAudio/Metal combat soak with repeated PCM endpoint seeks; see [native audio diagnosis](ANDROID_AUDIO_CRASH.md) for both runs and exact metrics. No Android runtime pass is claimed.
