# Arena Dash

A Godot 4.7 aircraft combat game with twelve aircraft, four weapons, eight campaign worlds, English/Bahasa Indonesia localization, and customizable touch controls.

## Run locally

Use Godot 4.7.2 with matching export templates. Open `project.godot` in the editor or run from the project directory:

```sh
godot --path .
```

The main menu opens the Hangar, Planet Campaign, and Settings. Choose an aircraft and weapon in the hangar, inspect or prepare an unlocked planet, then deploy. Complete the drone objective and, on levels 4–8, defeat the guardian. Earn **three stars** to unlock the next world: complete the mission, meet the aircraft damage budget, and beat the planet time limit. One- and two-star attempts save your best rating but require a retry.

## Controls and preferences

| Context | Controls |
|---|---|
| Flight | WASD/arrows to move; Space/J to fire; Esc/P to pause |
| Hangar | A/D or arrows to select aircraft; swipe on touch; Enter to deploy |
| Campaign | Arrows to inspect planets; Enter to prepare an unlocked mission; Escape to return |
| Display | F11 or Alt+Enter to toggle fullscreen |
| Touch flight | Movement joystick and hold-to-fire button |

Settings offers General, Language, Audio, Graphics, and Controls categories. English is the default; English/Bahasa Indonesia switching applies immediately and persists. Sound effects and reduced motion save automatically.

In **Customize Controls**, drag Fire or Movement in the selected planet/aircraft preview. Adjust each control's size (80–140%) and opacity (35–100%). **Save Layout** applies and persists the draft; **Cancel/Escape** discards it; **Reset to Default** resets the preview and requires Save to apply. Controls remain within the reserved gameplay area and use normalized positions across resolutions.

The interface uses a 1280×720 logical landscape canvas. Wider landscapes expand horizontally; portrait windows letterbox the landscape layout. Native mobile orientation is landscape.

## Build and preview

```sh
./build_web.sh
python3 serve_web.py
./build_apk.sh --export-release
```

The server serves `build/web` at [http://127.0.0.1:8060](http://127.0.0.1:8060). The Web build script regenerates the localized loading shell before export. Android output is `build/arena_dash.apk`; the existing signing identity is for local testing. See [build and distribution instructions](docs/DEPLOYMENT.md) for prerequisites and signature verification.

## Verification

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

All nine suites passed in the latest implementation validation. Web and Android exports and APK v2/v3 signature checks passed. The exported browser game was checked for language switching, control editing, and reload persistence with no warning/error console logs. Desktop frame-pacing benchmarks and a 20-minute accelerated simulation soak passed; physical Android ergonomics, multitouch, cutouts, thermals and GPU performance remain unverified. Details and rendered capture commands are in the [testing guide](docs/TESTING.md).

## Documentation and assets

Start with the [documentation index](docs/README.md) for architecture, save data, campaign assignments, localization maintenance, and build guidance. The latest [recursive asset inventory](docs/localization-asset-inventory.json) contains 215 source resources; all 208 graphical resources present before the localization/control refinement remained unchanged. No artwork was created or downloaded during that refinement, and no required artwork is missing.

See [performance measurements and strict campaign progression](docs/PERFORMANCE_PROGRESSION.md) for the latest changes, criteria and validation limits. All 215 source assets were verified byte-identical during this phase.

Earlier implementation reports and backup ZIPs are retained as historical records. Tests use project-local saves; reports, tests, backups, and build output are excluded from game exports. No external deployment has been performed.
