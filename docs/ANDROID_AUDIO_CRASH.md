# Android native audio crash: diagnosis and correction

> Physical-device follow-up (2026-10-10): the original AudioTrack crash was reproduced on the connected Redmi Note 8. The corrected full-audio build sustained over 16 minutes of verified gameplay. See [physical-phone QA](ANDROID_PHONE_QA.md) for evidence, the instrumentation interruption, and final APK identity. The no-device statements below describe the earlier session.

Completed 2026-10-10 (Asia/Jakarta); supplied crash log dated 2026-10-09. The supplied `arena_dash_full.log` confirms SIGSEGV/SEGV_ACCERR on `AudioTrack` through OpenSL ES (`libwilhelm.so`) into Godot's mixer. The phone identifies as Xiaomi/ginkgo, Android 13, userdebug. The crash is not a Java exception or an app low-memory-kill record. No renderer change was made: a Vulkan GPU log is not evidence that Vulkan caused this fault.

## Evidence and root-cause correlation

The exact installed debug library matches the log's Build ID `379cc52e73d31af89517a529d3bbc6108b808986`. Its faulting instruction at PC `0x2f8f814` is `ldrsh w8, [x22, x8, lsl #1]`, reading a signed 16-bit sample. Register x22 is `0x7a7eed2580`; x8 is `0x1cd40` (118080). Therefore:

```
0x7a7eed2580 + 118080 * 2 = 0x7a7ef0c000
```

That is exactly the reported fault address. The sole looping PCM WAV is `engine_loop.wav`, mono 16-bit at 24000 Hz, with 236160 bytes / 118080 frames. Its original imported `loop_end` was 118080, one past the last valid frame. The 4.7.2 WAV mixer includes loop_end in the decode limit. Its importer only resolves negative endpoint values to a bounded frame; the positive configured frame count remained unchanged. The unique looping resource's extent, invalid endpoint, fault index, decoded load instruction, and computed fault address all agree.

**Confirmed defect:** the engine-loop resource supplied an out-of-bounds loop endpoint. The native log is strongly correlated to the resulting one-past-end PCM read, not an assumed general audio-driver failure. Full symbol names are unavailable in the stripped debug template; symbolizer returned `??`. Objdump's nearest exported `WebPPictureRescale` label is unrelated and must not be interpreted as a WebP crash. No original process memory dump was supplied, so PCM buffer ownership was correlated from its unique size/configuration rather than dereferenced live.

Primary source: [Godot 4.7.2 WAV mixer/importer](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/resources/audio_stream_wav.cpp). A related upstream [WAV loop-boundary issue](https://github.com/godotengine/godot/issues/119778) describes the inclusive/exclusive mismatch; the diagnosis here is based on this application's actual log and binary, not merely that issue. The remaining one-frame loop convention quirk in the engine is not fixed by this project-level correction, but the invalid read endpoint is removed.

## Changes

- `assets/audio/ambient/engine_loop.wav.import`: changed endpoint to `-1`. Import resolves it to 118079, the final valid frame. Audio source bytes, sample rate, mono format, engine pitch modulation and continuous looping remain intact.
- `scripts/sound_effects.gd`: validates looping 8/16-bit PCM bounds before first playback. Zero/one-frame loops are rejected; valid streams are untouched. Validation occurs while loading, not inside a mixer callback or while mutating an active stream. Added debug-only `--audio-stage=off|ui|music|sfx|full` gates for staged diagnostics. Normal builds default to full audio.
- `scripts/perf_diagnostics.gd`: debug-only `--stability-auto` starts gameplay after the scene-change completion signal, sustains fire/combat, and writes any diagnostic progress to a separate save. It enables invulnerability only in that diagnostic mode. Normal gameplay and production builds do not enter this mode.
- `export_presets.cfg`: added five non-runnable debug diagnostic presets. The Off preset selects Dummy audio plus disables all playback. Others isolate UI, music/results, gameplay SFX/engine, or full audio. Standard Android keeps full audio and the existing renderer/layout/landscape/package identity.
- `tests/audio_loop_stability.*` and `tests/audio_isolation.*`: endpoint/guard regression, staged audio checks, and continuous real-time combat/mixer soak with repeated seeks near the loop boundary.
- `tools/capture_android_stability.py`: detects the current SDK path and records automated diagnostic runs without instructing the player to debug manually. Existing device/process failure guards remain intact.

Pre-fix checkpoint: `qa/audio-crash-audit/pre-fix-checkpoint.zip`. The existing dirty project was preserved; no reset/commit or important asset deletion was performed.

## Audio and broader stability review

The audio director remains persistent with 17 children: eight SFX voices, three UI voices, two crossfade music players, engine/warning/sting voices and one debounce timer. Effect cooldowns bound traffic; all resources load before reuse, music uses bounded asynchronous requests, and stale result timers check generation. Background and pause handling, crossfade cleanup, music-loop endpoints, settings persistence, all weapon cues, warnings, explosions, victory/defeat/unlock cues and bus mixing passed the existing audio test. No audio feature was permanently disabled.

Non-looping `charge`/`critical_warning` imports contain stale endpoint fields, but their loop mode is disabled and the mixer ignores those fields. They were not classified as active loop defects or changed unnecessarily.

Combat allocations remain bounded by existing spawner limits and pools. Gameplay smoke covers all maps/ships/weapons, progression, victory/defeat, pause and scene changes. Joystick-position and performance-safety tests passed. No new demonstrated leak, bad signal connection or renderer fault was found that justified unrelated gameplay changes. CPU/GPU/thermal behavior on Android remains unmeasured.

## Verification

Audio functionality and fresh-process settings persistence: PASS. All five isolation-stage tests: PASS. Automated diagnostic startup: PASS (`AUTO_GAMEPLAY_STARTED`). Gameplay smoke, control position, performance safety: PASS. Capture-tool failure-mode tests: five tests PASS, with mocked ADB; not device evidence.

The continuous real-audio desktop soak is recorded in `qa/audio-loop-stability.json` and `qa/audio-crash-audit/native-soak-console.log`. Final duration, endpoint crossing count, memory/node bounds and outcome are appended below only after completion. CoreAudio/Metal on Apple M1 is desktop evidence, not Android OpenSL ES verification.

Six Android debug APKs were built and independently checked: `build/arena_dash_debug.apk` plus `arena_dash_audio_off.apk`, `arena_dash_audio_ui.apk`, `arena_dash_audio_music.apk`, `arena_dash_audio_sfx.apk`, and `arena_dash_audio_full.apk`. All verify v2/v3 development signing, fixed landscape, no requested permissions, and contain the corrected imported engine resource byte-for-byte. The standard build contains no isolation/automated-gameplay flags. Hashes and embedded argument lists are in `qa/audio-crash-audit/apk-verification.json`.

ADB was started with the required host access and reported **zero connected devices**. The automatic Off-build install/capture workflow was attempted and stopped at device discovery. No APK installation, Android crash reproduction, incremental Android playback trial, or ten-minute Android session occurred. No configured emulator/system image was available. On-device elimination of the crash remains unverified; the actual resource defect is corrected with native fault correlation and desktop evidence.

Production signing credentials remain unavailable; these are development APKs. The prior libpng security advisory and Play Protect uncertainty are separate outstanding issues, not explained or resolved by this audio correction. See [security audit](ANDROID_SECURITY_AUDIT.md).

## Evidence files

Original log, native library, fault disassembly, resource inspection, register/address correlation, checkpoint, APK hashes/signatures/arguments, per-stage test/export logs and device-attempt result are retained under `qa/audio-crash-audit/`. This build evidence directory is excluded from game exports. Full audio remains enabled in `build/arena_dash_debug.apk`.

## Completed desktop soak result

The corrected repeat run completed **600.017 real seconds** on macOS/Apple M1, CoreAudio and Metal Mobile, with **zero failures, native crashes or script errors**. It issued 2390 near-end seek requests to exercise repeated PCM loop boundaries during sustained combat. Audio players remained at 17; nodes ranged 868–1006. After 120 seconds of warm-up, monitored static memory ranged 68.96–69.05 MiB. These engine counters are not Android PSS, GPU-driver memory or a proof of absence of all leaks.

The first run also survived 600.001 seconds without native termination, but recorded two assertion failures during intentional background audio suspension. A separate check reproduced `playing=false` with `stream_paused=true`, followed by successful resume. The test was corrected to respect that lifecycle state and the full ten-minute run was repeated. Both original and repeat evidence remain available; the initial run is not labeled a passing test.

Standard debug APK: `build/arena_dash_debug.apk`, SHA-256 `3c57fde3321423b6ce139fc6b4ab13c0ce59a69c9726c76e2430c4eb8397f467`. It keeps all normal audio enabled and has no automation/isolation flags. Device retest still unavailable: authorized ADB discovery returned an empty device list, no emulator/system image is installed, and the capture attempt stopped before installation.
