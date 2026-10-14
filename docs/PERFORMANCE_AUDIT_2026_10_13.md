# Arena Dash performance audit — 13 October 2026

Implemented focused performance fixes and built a signed production Release APK. Desktop measurements show substantial reductions in repeated level initialization and Galaxy Map CPU work. Android frame pacing, thermal behavior, GPU cost and touch-to-display latency still require a phone; this report does not claim complete Android optimization.

## Scope and recovery

Inspected runtime scripts, all 10 game scenes, autoloads, input, campaign/progression, equipment, enemy spawning/AI, projectiles, physics layers, UI, saves, audio, procedural terrain, particles, texture imports, shaders, project settings and Android export/signing. The final script inventory contains 46 scripts, including the new mission cache and debug-only tools. An asset scan covers 409 SVG/PNG textures. Raw inventories and logs are in [qa/performance-audit](/Users/tentendigitalindonesia/Downloads/XxX/Apps/arena_dash/qa/performance-audit).

The working tree was clean initially. The original tracked project is recoverable from `.maintenance/recovery/pre-performance-audit-20261013.tar`, at Git commit `063eaf9237cf0574e4fab97f939b472c7cc8bf0b`. Changes remain in the working tree for review; no commit, renderer switch, physics-rate change or signing-identity replacement was made.

## Bottlenecks and implemented fixes

1. **Galaxy zoom:** every interpolation step reapplied 16 font theme overrides and rebuilt route draw commands, including hundreds of static dots. Theme invalidation can cause text/layout work even when the integer font size remains unchanged. Font overrides now change only when the actual font size changes. Route dots occupy a separate cached canvas and redraw only when overview touch-target diameter or layout changes; moving badge geometry remains updated at every zoom. All scale-dependent label positions, readable sizes and hit targets retain their original formulas.
2. **Galaxy pan:** every input/inertia update reassigned visibility on five controls per planet and reevaluated unlock status. Visibility updates now occur only at viewport-boundary crossings, with unlock flags cached for this map instance. The map stops its process callback when zoom and inertia settle, then wakes for new zoom/drag input. Planet selection avoids an unnecessary redraw when the selected flag is unchanged. Nodes and textures are never rebuilt during gestures. Four-direction pan, moving-midpoint pinch, cursor anchor, clamping, FIT, focus animation, wheel and fixed controls are preserved.
3. **Level transition stalls:** `_build_floor()` created the same inline Shader on every arena entry and a material per landmark. The identical shader is now a preloaded `.gdshader`; both landmarks share a scene-owned material. On this Mac, repeated arena construction dropped from around 1.1 seconds to around 20 ms. The result is consistent with avoiding repeated shader creation/driver compilation; there is no Android driver trace to prove the same magnitude there. The shader's fragment calculations are unchanged.
4. **Dynamic mission assets:** map icons, advanced floors/overlays, advanced enemy artwork and relevant obstacles were loaded synchronously during arena construction or spawning. A persistent `MissionAssets` node requests only the selected mission's textures while the hangar is visible. Deployment polls to completion across frames and retrieves resources only after LOADED. It retains at most one mission's texture set, retires superseded requests, deduplicates paths and permits failed-request retries. No scene-tree work occurs on worker threads. The asynchronous deployment path is tested for all 15 planets. This reduces expected deployment/spawn I/O stalls; no separate end-to-end Android loading-time gain is claimed.
5. **Repeated weapon work:** every volley rebuilt `WeaponData`, its pattern dictionaries and texture lookup. Validated catalog snapshots now reuse a bounded cache of the six existing weapons. Pattern arrays and dictionaries are read-only. This removes repeat pattern allocation and texture reload work without changing damage, speed, angles, offsets, lifetime, counts or firing clocks. Muzzle collision radius/node lookup is performed once per volley; the original three physics checks still run for each projectile.
6. **Impact memory growth:** the effect manager retained a receipt for every hit until scene exit. Receipts now leave the dictionary when their fresh effect node exits. Duplicate live receipts are still rejected, and the projectile authority already prevents impacts from consumed shots. Memory therefore scales with live effects instead of mission hit count.

Player projectiles remain fresh single-use nodes. Existing hostile-shot/effect pools, collision masks, swept queries and generation/lease safeguards are preserved. Introducing a second pooling lifecycle was not justified after the game's prior phantom-projectile repairs. Enemy health, roster, count limits, spawn intervals, bosses, movement and attack patterns are unchanged.

## Before and after measurements

Godot **4.7.2 stable**, macOS, Apple M1, **Mobile/Metal**, 1280×720 window. The baseline ran from the saved original project. Each map benchmark sampled 1,200 identical zoom/pan calls with a frame between samples. These are **handler CPU durations**, not touch latency or total frame durations. One run per configuration; background scheduling, cache state and driver behavior can affect results.

| Rendered desktop measurement | Before | After |
|---|---:|---:|
| Zoom CPU average | 0.421 ms | 0.221 ms |
| Zoom CPU p95 | 0.519 ms | 0.428 ms |
| Zoom CPU worst | 1.357 ms | 1.025 ms |
| Pan CPU average | 0.024 ms | 0.021 ms |
| Pan CPU p95 | 0.034 ms | 0.042 ms |
| 15-level initialization median | 1109.532 ms | 19.880 ms |
| 10,000 repeated weapon lookups | 9828.397 ms | 5.814 ms |

Zoom CPU average decreased **47.5%**; pan average decreased **14.4%**, while pan p95 increased. Headless zoom average was 0.705 → 0.487 ms; pan average 0.061 → 0.042 ms. The weapon microbenchmark repeatedly releases baseline snapshots and exaggerates texture-reload savings compared with continuous firing that retains live bullets. It is not an FPS multiplier.

Level timings below include `instantiate()` plus adding the scene and synchronous `_ready()` work. They exclude initial PackedScene loading, waiting for threaded assets, and the first complete rendered frame. Shared shader loading can move initial cost into startup, where the existing loader already loads the main scene; repeated per-level construction is avoided. About 20 ms of scene construction remains, which can still exceed a 60 Hz frame budget.

| Planet | Before initialization ms | After initialization ms |
|---|---:|---:|
| advanced_desert | 1195.436 | 19.941 |
| advanced_toxic | 1114.653 | 20.414 |
| coast | 1110.896 | 19.672 |
| crystal | 20.114 | 19.524 |
| cyber | 1272.361 | 30.004 |
| dark_void | 19.928 | 19.410 |
| desert | 1108.739 | 19.609 |
| forest | 1181.632 | 20.493 |
| glacier | 1109.532 | 19.437 |
| ice | 1106.988 | 19.597 |
| lava | 1107.815 | 20.852 |
| space | 1111.195 | 20.201 |
| storm | 880.427 | 19.713 |
| toxic | 1115.497 | 19.949 |
| volcano | 1108.028 | 19.880 |

Headless seeded gameplay benchmark, original light/heavy workload:

| Phase/measurement | Before | After |
|---|---:|---:|
| Light average frame interval | 6.902 ms | 6.925 ms |
| Light p95 | 8.140 ms | 8.625 ms |
| Heavy average frame interval | 6.924 ms | 6.900 ms |
| Heavy p99 | 10.168 ms | 8.911 ms |
| Heavy worst | 55.670 ms | 9.298 ms |
| Heavy static memory | 66.72 MB | 66.79 MB |

These gameplay samples do not demonstrate a universal frame-time gain: light p95 worsened, averages remained close to the headless scheduler limit, and live populations differed slightly. Rendered gameplay logs also include CPU rendering, physics, process time, object/node counts, draw calls and video memory. Window scheduling changed between runs, so their FPS/frame-interval difference is not used as a reliable improvement claim. Snapshot physics times are instantaneous, not phase averages. Render GPU time returned zero and input-latency sample count was zero; neither is treated as a valid measurement. Cached textures trade bounded retained memory for lower allocation/loading cost; overall GPU-memory reduction is not claimed.

## Assets, audio and Android configuration

Retained current Mobile renderer, VSync, 60 Hz physics, interpolation, texture resolution/filtering and import compression. Artwork, animations and particle counts remain intact. The live landscape background is 1920×1080 (roughly 8.3 MB at RGBA8); other large contact sheets and PNG/SVG alternatives exist, but source size is not evidence that they are live GPU bottlenecks. Blanket mipmap/compression changes or asset removal would risk readability/quality without phone measurements. No original asset was deleted.

Existing audio uses bounded persistent players, cached effects, threaded music loading, cross-fades and a PCM loop-end guard. Existing score persistence batches disk writes and atomically saves progression/economy. Those safeguards remain unchanged. Saves keep the same path/schema, level IDs, ownership, coins, three-star rules, localization and control settings.

## Validation and limitations

All 33 test scenes have been exercised through the regression runner or direct benchmark execution; consolidated results are in `qa/performance-audit/test-results.json`. Tests cover all original/advanced maps, 96 equipment combinations and eight headings each, firing cadence at 30/60/120 Hz, projectile cleanup/obstructions/transitions, coins/purchases, three-star progression, legacy saves, English/Indonesian UI, controls/pause/resume, loading, audio and meteors. Leaving/freeing the hangar while a deployment request is pending was also exercised in a temporary scene harness without script errors. The performance soak passed **20 simulated minutes**. The cache suite validates actual asynchronous deployment through all 15 planets, superseded requests, immutable weapon patterns, idle-map processing and completed impact cleanup.

Rendered Galaxy Map tests passed on recheck. One earlier rendered run failed two zoom-limit checks; the untouched baseline passed, headless tests passed, and a rendered rerun passed. Since window-focus/scheduling interference was not conclusively traced, that intermittent run is recorded rather than erased. FIT/maximum/preferred-zoom screenshots were captured; baseline and optimized FIT layouts were visually inspected.

The first stability runner used a 180-second timeout for a suite requiring 15 × 12 seconds plus setup; it reached 14 maps before the harness killed it. It was rerun with 240 seconds. Final status is recorded below after completion.

No physical Android tests were performed, and no device connection was required. Godot's initial editor import automatically attempted Android device discovery and was blocked by the sandbox; no manual ADB command or phone test was used. Subsequent validation relied on desktop/headless execution and APK inspection. Sandbox runs emitted macOS certificate-access errors. Abrupt shutdown in several audio tests emitted ObjectDB/audio-resource warnings; these were reproduced in the original baseline and are not treated as evidence of a new persistent gameplay leak. Other retained limitations include cold startup/first-driver-shader costs, remaining main-thread node construction, hundreds of procedural draw commands, sustained on-phone GPU/thermal cost, and real pinch/input latency.

## Files changed

- `scripts/level_select.gd`, `scripts/planet_button.gd`: map invalidation, visibility and idle processing.
- `scripts/main.gd`, new `assets/shaders/landmark.gdshader`: shared identical landmark shader/material.
- `scripts/game.gd`, `scripts/hangar.gd`, new `scripts/mission_assets.gd`: bounded threaded mission texture warming and deployment wait.
- `scripts/weapon_data.gd`, `scripts/projectile_manager.gd`: cached catalog snapshots and per-volley owner lookup.
- `scripts/impact_effect_manager.gd`: live-effect receipt lifetime.
- New `tests/performance_audit.gd/.tscn`, `tests/performance_cache_safety.gd/.tscn`: repeatable measurements and integration regressions.
- `tests/galaxy_zoom.gd`: exact state values on zoom-limit assertion failures.
- Godot-generated UID files for new resources and this report. `project.godot`, export presets, game balance, save serialization and signing configuration are unchanged.

## Release artifact

[build/arena_dash_release.apk](/Users/tentendigitalindonesia/Downloads/XxX/Apps/arena_dash/build/arena_dash_release.apk) — genuine **Release**, approximately 53 MiB, arm64-v8a standalone, package `com.example.arenadash`, version code 2. Built using existing `build_apk.sh release` and the existing production Keychain identity. No debug fallback or credential disclosure.

APK SHA-256: `2ea0339e9120838753409ca6bc4783f0406bf8345599af4d26ec9d78a722de71`.

Signer certificate SHA-256: `317b9baedaf187bd9e4cf17096fbca1119dac169f063e3090bd9b5bc8e3523af` (public certificate fingerprint). Verification confirms production certificate match, non-debuggable manifest, exact 4.7.2 release executable template, cryptographic signature, ZIP integrity, 16 KiB alignment and packaged icons. Reports are in `qa/build-verification/`. The final artifact is kept in `build/`.

## Final stability result

PASS — all 15 planets, 182.4 seconds, zero stability assertions failed. All 31 regression suites passed in their final runs; both additional performance benchmark scenes completed successfully. The initial timeout was a harness limit, not a gameplay failure.
