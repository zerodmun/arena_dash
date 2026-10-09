# Testing and validation

Guide updated 2026-10-09. The latest performance/progression implementation reran the suites and both exports.

## Automated suites

Run from the project root with Godot 4.7.2 and imported resources. For a fresh checkout, import first:

```sh
godot --headless --path . --editor --import --quit
```

| Suite | Coverage | Latest result |
|---|---|---|
| `tests/game_smoke.tscn` | Eight maps, twelve aircraft, four weapons, movement, damage, mission progression/save/load, defeat/retry | PASS, zero failures |
| `tests/hangar_review.tscn` | Aircraft/weapon previews, campaign navigation/locks, UI geometry, results, touch firing/pause | PASS, zero failures |
| `tests/campaign_combat.tscn` | Enemy roles, telegraphs, safe spawns, projectile collision, guardian patterns/completion gate, legacy campaign saves | PASS, zero failures |
| `tests/landscape_ui.tscn` | Navigation/dialog bounds, settings, keyboard focus, pause/resume, landscape scaling and portrait letterbox | PASS, zero failures |
| `tests/localization_controls.tscn` | EN/ID key parity, instant switching, persistence, editor actions, size/opacity, overlap/bounds, results text | PASS, zero failures |
| `tests/control_input.tscn` | Actual viewport GUI routing for independent touch fingers, outside releases, editor drag/isolation, resizing open preview | PASS, zero failures |

| `tests/three_star_progression.tscn` | All eight worlds, star boundaries for every ship, save migration, bypass guards, EN/ID results and campaign | PASS, zero failures |
| `tests/performance_safety.tscn` | Deferred saves, 30/60/120 Hz movement/fire cadence, 7,200 pooled shots, reset/collision safety, pickup cap | PASS, zero failures |
| `tests/performance_soak.tscn` | 20 accelerated simulation minutes, actor caps, memory/node samples, muted headless audio | PASS, zero failures |

```sh
godot --headless --path . tests/game_smoke.tscn
godot --headless --path . tests/hangar_review.tscn
godot --headless --path . tests/campaign_combat.tscn
godot --headless --path . tests/landscape_ui.tscn
godot --headless --path . tests/localization_controls.tscn
godot --headless --path . tests/control_input.tscn
godot --headless --path . tests/three_star_progression.tscn
godot --headless --path . tests/performance_safety.tscn
godot --headless --path . --fixed-fps 60 tests/performance_soak.tscn
```

Each suite reports PASS/FAIL and an exit code. Test saves live under `build` through an overridden `Game.save_path`; they do not overwrite normal `user://` player saves. Headless checks verify state/input/geometry; rendered checks are also needed for text fit and visual appearance.

## Rendered UI checks

```sh
godot --path . --windowed --resolution 1280x720 --rendering-method gl_compatibility tests/localization_controls.tscn -- --screenshots
godot --path . --windowed --resolution 1280x720 --rendering-method gl_compatibility tests/landscape_ui.tscn -- --screenshots
```

Native rendered localization/control checks passed in both languages at 1280×720, 1600×720 (20:9), and 960×540. Captures cover menus, settings categories, editor, hangar, weapons, campaign, gameplay, pause, victory, and defeat. The landscape suite additionally covers 1920×1080 and 720×1280 portrait letterboxing. Inspect `build/l10n_*.png` and `build/landscape_*.png` for clipping, alignment, readability, selected/focus states, and control bounds.

Harnesses explicitly draw capture frames and wait for queued dialog deletion before asserting disappearance. A background/minimized native window can affect capture timing; keep the rendered test window available when investigating capture failures.

## Browser and persistence checks

Build and serve with `./build_web.sh` and `python3 serve_web.py`. Check:

1. Open menu, hangar, weapon preview, campaign, and gameplay; confirm navigation and pause/resume.
2. Switch EN/ID in settings; verify current labels/tooltips/formatted content update immediately.
3. Drag Fire and Movement; adjust their size/opacity independently; try overlapping or offscreen positions.
4. Cancel a draft, then reopen; verify the previous saved layout remains. Reset and Save; verify defaults apply.
5. Save a customized layout and language, reload, and reopen the editor; verify both persist. Check localized loader text during startup.
6. Check browser console warnings/errors and confirm gameplay input is inactive while editing.

The exported browser game passed real mouse drag/slider/Save checks and language/layout reload persistence with empty warning/error logs. The final browser editor capture is `build/web-control-editor.jpg`.

## Build and asset evidence

Web and Android exports completed successfully, and APK signature verification passed v2/v3. See [Deployment](DEPLOYMENT.md) for commands. Existing logs:

- `build/game_smoke-localization.log`, `build/hangar_review-localization.log`, `build/campaign_combat-localization.log`, `build/landscape_ui-localization.log`.
- `build/localization-controls-headless.log`, `build/localization-controls-final.log`, `build/control-input.log`.
- `build/web-localization-export.log`, `build/android-localization-export.log`, `build/apk-localization-signature.log`.
- `build/localization-integrity-result.json`: 208 graphical resources unchanged; 189 translation keys.

The latest recursive [asset inventory](localization-asset-inventory.json) records 215 source resources. Integrity compares against `build/localization-assets-before.json`; historical asset counts refer to earlier phases.

## Remaining validation

Viewport-dispatched touch tests exercise input routing but do not replace physical-device testing. Android touch ergonomics, real multitouch, display cutouts, interruptions, and GPU performance require a device. No physical Android/iOS or store submission validation has been completed. Human difficulty tuning also remains unverified. Native mobile is intended for landscape; portrait browser/desktop windows retain letterboxing.

## Latest performance/progression evidence

See [Performance and progression](PERFORMANCE_PROGRESSION.md) for baseline/after frame statistics and interpretation. Current suite logs use `build/*-performance.log`, with `build/performance-soak.log` for the soak and `build/three-star-rendered.log` for rendered EN/ID results. `build/progression_*.png` captures actual/current versus best stars and disabled Next states.

```sh
godot --path . --windowed --resolution 1280x720 --rendering-method gl_compatibility tests/three_star_progression.tscn -- --screenshots
godot --path . --windowed --resolution 1280x720 --rendering-method gl_compatibility tests/performance_bench.tscn
godot --path . --windowed --resolution 1280x720 --rendering-method gl_compatibility tests/performance_bench.tscn -- --perf
```

The benchmark records JSON under `build`. `--baseline` chooses the baseline output filename; a valid before/after comparison also requires the pre-change source snapshot. The ordinary benchmark excludes each phase’s first second; diagnostics intentionally include startup. The soak is accelerated rather than twenty wall-clock minutes and excludes audio-driver scheduling.

Latest export/signature logs: `build/web-performance-export.log`, `build/android-performance-export.log`, `build/apk-performance-signature.log`. All 215 source assets match `build/performance-assets-before.json`; catalogs contain 199 identical keys. Sandbox user-log/OS diagnostics occurred in headless runs; suites returned PASS without script errors. Android sustained thermal, GPU and physical input-to-display measurements remain outstanding.
