# Arena Dash

A Godot 4.7 aircraft combat game with sixteen aircraft, six weapons, fifteen campaign worlds, English/Bahasa Indonesia localization, and customizable touch controls.

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

Settings offers General, Language, Audio, Graphics, and Controls categories. English is the default; English/Bahasa Indonesia switching applies immediately and persists. Master, Music, Sound Effects and UI volumes, Mute All Audio, and reduced motion save automatically. The [audio implementation report](docs/AUDIO.md) records the licensed assets, music assignments, event coverage, and verification limits.

In **Customize Controls**, drag Fire or Movement in the selected planet/aircraft preview. Adjust each control's size (80–140%) and opacity (35–100%). **Save Layout** applies and persists the draft; **Cancel/Escape** discards it; **Reset to Default** resets the preview and requires Save to apply. Controls remain within the reserved gameplay area and use normalized positions across resolutions.

The interface uses a 1280×720 logical landscape canvas. Wider landscapes expand horizontally; portrait windows letterbox the landscape layout. Native mobile orientation is locked to landscape at startup and resume. Home, Hangar, campaign, settings, loadout dialogs, control editor, and gameplay share a muted navy/steel and gold theme with rounded buttons; menu controls and dialogs respect reported device safe areas. Hangar ship selection uses arrows, A–D, or swipe around one enlarged aircraft display.

## Build and preview

```sh
./build_web.sh
python3 serve_web.py
./build_apk.sh debug
```

The server serves `dist/web` at [http://127.0.0.1:8060](http://127.0.0.1:8060). The Web build script regenerates the localized loading shell before export. `./build_apk.sh` defaults to a production signed release at `build/arena_dash_release.apk`; an optional second argument selects the output path. The script verifies signature and alignment before replacing the previous APK, then writes signature and checksum reports under `qa/build-verification/`. Use `./build_apk.sh debug` explicitly for development builds. Release builds require an explicitly supplied production keystore and reject the existing debug key. Set `GODOT_BIN` or `ANDROID_SDK_ROOT` to override automatic tool discovery. See [build and distribution instructions](docs/DEPLOYMENT.md) for prerequisites and signature verification.

## Verification

```sh
godot --headless --path . tests/audio_system.tscn
godot --headless --path . tests/audio_system.tscn -- --reload
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

The supplied Redmi Note 8 Logcat identified a one-past-end PCM read matching the engine-loop resource; its endpoint is corrected. Android retesting remains blocked by the absence of a connected device. See [audio crash diagnosis and fix](docs/ANDROID_AUDIO_CRASH.md). See [Android stability investigation](docs/ANDROID_STABILITY.md) for the confirmed meteor cleanup fix, signed diagnostic APKs, and a ten-minute capture workflow.

See [Android security audit](docs/ANDROID_SECURITY_AUDIT.md) and [Play Protect review evidence](docs/PLAY_PROTECT_REVIEW.md) for the current findings, known libpng risk, signing requirements, and verification limits.

Physical Redmi Note 8 crash reproduction and corrected-build verification: [Android phone QA](docs/ANDROID_PHONE_QA.md).

Dynamic selected-aircraft Home, subtle menu animation, larger Hangar weapon labels and premium four-/five-shot weapons: [implementation and physical Android verification](docs/HOME_PREMIUM_WEAPONS.md).

Centralized projectile rebuild, removed legacy firing/pooling logic, and Android test evidence: [implementation and verification](docs/PROJECTILE_REBUILD.md). Earlier investigation: [historical report](docs/GHOST_PROJECTILE_FIX.md).

Normal Android installation of the previous debug APK was verified on the connected Redmi Note 8 after a user-approved Google Play Protect scan returned SAFE. Both Documents and Download installation paths succeeded. See [the exact cause, evidence, and limits](docs/DIRECT_INSTALL_FIX.md).

The advanced update appends Levels 9–15 using the existing future-update maps and planets. See [implementation and verification](docs/ADVANCED_RELEASE.md).

Production signing now retrieves the local macOS Keychain identity automatically. See [signing and device update results](docs/ANDROID_RELEASE_SIGNING.md); the installed development app rejects the new production certificate without any data being removed.
