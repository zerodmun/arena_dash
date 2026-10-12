# Movement and firing collision fix — 2026-10-11

Scope: projectile spawning, heading, ownership, pool activation and collision verification. No UI, aircraft artwork, weapon artwork, economy, movement speed, firing interval, weapon damage, spread pattern, or camera redesign.

## Reproduced cause

Connected Redmi Note 8 (`13ff9514`, Android 13, 2340×1080 landscape) was tested with actual `MotionEvent` multi-pointer input using standalone Android instrumentation. This helper is not included in the game APK.

The unchanged-mechanics diagnostic baseline completed all eight requested scenarios. It logged 255 impacts, including **114 terrain contacts at projectile age zero** (and three age-zero enemy contacts). Player self-contact count was zero. The muzzle extends beyond the aircraft collision circle, so movement against cover can put a muzzle inside terrain even though the aircraft body is stopped. A new bullet was then created inside the cover and immediately generated an impact burst. During steering, another mismatch made the projectile use the requested movement heading while its muzzle followed the still-rotating aircraft.

The first recording of the originally installed APK was interrupted by a normal mission defeat; it is retained but is not counted as a complete eight-case verification. A diagnostic baseline with unchanged projectile mechanics and invulnerability provided the complete comparison. The diagnostic startup race discovered during verification was fixed in the opt-in diagnostic path; an invalid menu-only recording is also excluded from the results.

## Changes

- `player.gd`: derives world firing direction from the current muzzle basis after movement and smooth rotation. Twin/spread/burst offsets keep their existing distances and angles.
- Before creating a projectile, sweeps its circular footprint from the aircraft center through the muzzle corridor against terrain, then checks the destination footprint. An obstructed barrel cannot create a bullet inside or beyond cover. Existing airborne bullets still generate normal impacts; impact visuals have not been hidden or redesigned.
- Pooled and fallback bullets both receive the shooter. Fallback bullets are added to their actual parent before setting the global spawn transform.
- `bullet.gd`: sets global rotation and fully resets weapon, position, owner and physics interpolation before enabling collision participation. Rejects player/owner and unrelated collision-layer callbacks.
- Layer 0 / mask 5 still means player projectiles detect terrain and enemies, excluding player layer 2. Default monitorability is retained: the regression fixture showed disabled monitorability missing static-body contacts in this installed engine. Layer 0 continues to exclude bullets from other areas' detection. See [Godot Area2D properties](https://docs.godotengine.org/en/stable/classes/class_area2d.html#class-area2d-property-monitorable).
- Opt-in debug diagnostics can select a test loadout and sweep all equipment using a separate save path. Production exports without diagnostic arguments do not sample, auto-start, grant invulnerability, or cycle equipment.

## Verification

Headless `tests/movement_firing.tscn`: **7,174 checks passed**, 16 aircraft × 6 weapons × 8 headings. Covers mismatched requested/actual heading, transformed parents, pooled reuse, owner callbacks, world velocity, blocked muzzle, blocked launch corridor, normal terrain impact and fallback spawning.

Phone eight-case post-fix matrix: all eight cases completed; 728 injected events; 636 new projectiles, 156 obstructed launches rejected, 335 valid impacts, **zero age-zero terrain impacts**, zero player impacts and zero Godot errors. Periodic input telemetry independently confirms stationary firing, movement without firing, and simultaneous joystick/firing in the movement cases.

Phone equipment sweep: **all 96 combinations completed**, each producing new projectiles and ending with movement and firing active. 3,122 real touch events over 158 seconds; 1,777 projectiles; 1,071 valid impacts; zero age-zero terrain impacts, self-hits, unrelated-layer impacts or Godot errors. Test-only invulnerability and recentering between combinations keep the comparison running; they are not normal-gameplay behavior.

Recorded videos were inspected through extracted frames, including the new aircraft and weapon visuals. Real cover/enemy impacts, thruster particles and weapon wakes remain visible as intended. The recording encoder emitted vendor OMX unsupported-option messages; these are not Godot application failures.

## Retained artifacts

`qa/movement-fire-qa/` contains baseline/post-fix APKs, videos, screenshots/contact sheets, input results, Logcat, regression/build logs and `results.json`. `tools/run_phone_movement_firing.py` runs the two diagnostic recording modes; `tools/analyze_movement_firing.py` summarizes logs. Full equipment footage is a stress verification, not a separate game feature.

Normal APK smoke verification: all eight short cases completed with 238 injected events over 15.1 seconds, without diagnostic invulnerability or equipment cycling. The recorded normal mission showed visible projectiles during movement and valid enemy eliminations. No Godot/Java fatal errors appeared in that capture. A temporary beginner-planet profile was used for this smoke test; the exact original save was restored afterward and verified byte-for-byte (2,300 coins, Tempest, Quantum Spread, Coastal Front and original progression/settings). The installed APK SHA-256 matches the local deliverable.

Normal deliverable: `build/arena_dash_debug.apk`, signed with the existing development key, verified APK Signature Scheme v2/v3 and zip alignment. SHA-256: `23fca220b01dfcbac6975b663073c41ef49b2b4b0d45f2fc4cdaeb4d6209152b`.
