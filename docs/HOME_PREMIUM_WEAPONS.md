# Dynamic Home and premium weapons — 11 October 2026

Home reads `Game.get_current_ship()` and listens to `ship_selected`, using the same catalog and persisted equipment IDs as Hangar and gameplay. Artwork keeps its aspect ratio, with a bounded scale derived from the aircraft's existing visual scale. The original space artwork drifts within a small overscan; the aircraft floats smoothly. No particles, shaders, new textures or background actors are added. Hidden, backgrounded and reduced-motion menus stop or suppress movement.

The Hangar's existing 352×108 rounded weapon card now uses a centered 26 px weapon name and 20 px heading, preserving its icon, padding and footer layout. English and Indonesian labels were checked on the phone and at logical landscape widths from 1280 to 1600.

## Equipment and economy

| Existing weapon | Shots | Total spread | Damage per shot | Speed | Minimum interval | Price |
|---|---:|---:|---:|---:|---:|---:|
| Plasma Lance | 4 | 30° | 2 | 960 | 0.24 s | 1,050 Coins |
| Nova Burst | 5 | 48° | 2 | 720 | 0.26 s | 1,680 Coins |

Four-shot angles are −15°, −5°, +5°, +15°. Five-shot angles are −24°, −12°, 0°, +12°, +24°. Lateral muzzle spacing separates the projectiles at launch. Live combat and Hangar preview share one configurable pattern helper. Ship firing intervals still apply, subject to premium minimum intervals; maximum rates are about 16.7 and 19.2 projectiles/second. Their theoretical on-axis aggregate damage is strong, but the spread means targets normally intercept only part of each volley.

The existing reward is `120 + 30 × stars + 10 × world_index`, plus 250 for a first clear. A repeat three-star first-world clear pays 210 Coins. Premium prices therefore represent five and eight repeat clears, compared with 200/300 Coins for the intermediate weapons. No save schema, balance migration, existing entitlements, mission rewards or three-star gate was changed.

Launch-corridor sweeps, world-space muzzle alignment, shooter exclusion, collision masks, valid-impact filtering and pooled bullets remain intact. Muzzles are 68 units ahead of the ship center, beyond its collision radius plus projectile radius. Advanced lateral positions remain outside that footprint.

## Verified results

Godot 4.7.2: Home/premium, equipment integration and fresh-process purchase persistence, Coin economy, Hangar layout, three-star progression, performance safety and movement/firing suites passed. The firing suite exercised 96 equipment combinations across eight headings, totaling 11,014 checks. Some existing integration suites emit resource-cleanup warnings on exit; they report no assertion failures. `qa/.gdignore` prevents historical `.gd` capture backups from registering duplicate classes; the APK build script creates this guard.

Physical Redmi Note 8 (`13ff9514`), 2340×1080, Android Vulkan/Adreno 610:

- Inspected actual screenshots of Valkyrie and Falcon Home/Hangar selection, Falcon after process restart, enlarged English/Indonesian weapon cards, locked prices, and premium purchase/equip states.
- Inspected sampled frames from the actual eight-second Home recording: subtle artwork drift and aircraft float with stationary UI.
- Inspected stationary captures and six sampled frames from each 24-second premium gameplay recording. Four green lances and five orange Nova orbs are distinct and follow the aircraft's heading.
- Real Android instrumentation injected 308 multi-pointer events per weapon. Each matrix covers stationary fire, movement only, left/right/up/down with fire, diagonal with fire and rapid direction changes with fire. Both return instrumentation success.
- Final logs: 195 Lance impacts and 178 Nova impacts, all enemy/terrain; zero player impacts, invalid layers or age-zero terrain impacts. One immediate Lance impact was against an enemy at the muzzle, a valid contact. Both have three sampled simultaneous joystick/fire states, no Godot errors/crashes and zero sampled orphan nodes.
- Sampled Home FPS settled at 60. Recorded combat FPS: Lance 38–43, Nova 37–42. These are short debug runs with screen recording and verbose diagnostics, not a sustained 60 FPS or thermal soak claim. Sampled projectile maxima were 26 and 35.
- Tests used separate package `com.example.arenadash.review`, a separate save and 5,000 QA Coins. Purchases ended at 2,270 Coins (5,000 − 1,050 − 1,680). Temporary combat entitlements exist only in the debug QA feature. No premium unlocks were added to the player's actual profile.

ADB briefly interrupted one log stream; its incomplete Nova attempt was discarded. The repeat runner retrieves PID-filtered logs and the final Nova evidence confirms the correct equipped weapon.

Normal signed APK: `build/arena_dash_debug.apk`. QA APK: `qa/arena_dash_home_premium_qa.apk`. Evidence, recordings, test logs and JSON summaries: `qa/home-premium-qa/`. Reproduce device combat using `python3 tools/run_phone_home_premium.py` after exporting/installing the `Android Home Premium QA` preset and the existing `com.arenadash.qa` touch helper.

The normal APK was installed with `adb install -r` and launched. The real `arena_dash_save.cfg` SHA-256 was identical before and after: `50d911e854430747f009881d2e400e7e378d144bc6513e3b0b027a23c3d405ec`. Its selected Tempest and 2,300 Coins were inspected on the actual Home capture.
