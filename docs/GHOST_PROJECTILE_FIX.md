# Swept projectile lifecycle fix — 12 October 2026

## Reproduction and confirmed cause

An instrumented APK with the original projectile mechanics was installed in the separate `com.example.arenadash.review` package on the connected Redmi Note 8 (`13ff9514`). Actual Android `MotionEvent` multi-pointer input exercised stationary firing, movement alone, horizontal/vertical/diagonal movement with firing, and rapidly changing headings. The 24-second recording and individual sampled frames are retained under `qa/ghost-projectile-qa/baseline/`.

The baseline traced 194 impacts. **Two terrain impact callbacks did not overlap their reported target at the bullet's current pose.** The old `Area2D.body_entered` callback had no contact point or activation identity; it used `global_position` when the callback arrived to create an effect. Physics overlap notification and the current manually moved bullet/cover pose can therefore disagree. Logging only valid collision layers and projectile age missed this timing/position mismatch.

The offending baseline projectile IDs are 196 and 254, at trace timestamps 22,062,850 and 25,666,883 microseconds. For example, ID 196 was at `(3820.0444, 1657.5251)` when the callback identified the moving terrain body at `(3914.1267, 1656.3020)`, but a direct shape query at the bullet pose did not find that body. The callback still created an effect at the bullet position. This is measured evidence of a contact-position mismatch; it does not prove that every visual reported as a ghost had that same cause.

Pickup collection also intentionally calls the shared particle-effect factory beside the aircraft, accompanied by `+25`. Enemy destruction has another effect source. These existing effects remain, and the new trace explicitly distinguishes `pickup_collected`, `enemy_destroyed` and `projectile_impact` rather than assuming every nearby burst is a bullet impact.

## Implementation

- `scripts/bullet.gd`: all six weapon patterns use the same swept circular projectile query. Existing overlaps are checked explicitly; the full motion segment is cast; a verified contact at the first unsafe position supplies the target and **world contact point**. The shot is consumed before invoking enemy damage or effects. Expiry/manual cleanup never makes an impact effect. The old overlap signal is disconnected; the compatibility callback rejects non-contact targets. Bullet collision layers/masks still exclude the player. Native Area2D monitoring stays disabled because direct queries now own collision decisions.
- Bullets use a world-level `top_level` transform initialized after parenting. Direction, weapon texture/scale, damage, lifetime, query shape/exclusions and interpolation history are reset on activation. Movement never inherits aircraft velocity or parent rotation/scale.
- `scripts/combat_pool.gd`: deferred returns carry an activation lease; active objects and mismatched leases cannot be returned. Duplicate membership is rejected. A stale recycle can no longer hide or requeue a newly activated bullet/effect.
- `scripts/explosion_particles.gd`: each activation resets its complete world pose and emitter state. Effects have active/lease guards and explicit world-space particles. Normal impact artwork remains. This hardens reuse; the phone baseline did not independently prove an old effect lease caused the original report.
- `scripts/enemy.gd` and `scripts/pickup.gd`: tag existing effect sources for debugging; mechanics and visuals are unchanged.
- `scripts/projectile_trace.gd`: opt-in streaming JSONL in the separate QA package. Unique shot ID, pooled instance, effect lease, weapon/aircraft, timestamps, muzzle/player/projectile coordinates, world direction/velocity, layer/mask, owner, movement, target/contact, destruction reason, effect identity/position/source and render-phase transform/visibility are recorded. Sprite transforms and interpolation fraction are diagnostic state, not a readback of the rendered pixel position; recordings provide the visual evidence.
- `scripts/projectile_debug_overlay.gd`: optional cyan spawn and amber contact markers were recorded for one short QA pass. They are absent in the normal APK's runtime and in the sustained soak. Diagnostics require both a debug build and the isolated QA feature/config.
- `scripts/perf_diagnostics.gd`: the 96-loadout test clears old player shots and resets player/camera interpolation when recentering between cases. Test entitlements/save paths stay in the QA package.
- `scripts/player.gd`: only the separate QA package's long artificial invulnerability suppresses flashing, so the aircraft stays visible during visual verification. Normal damage/invulnerability behavior is unchanged. Previous diagnostics flashed the test aircraft throughout their recordings, making projectile visual assessment less reliable.

No changes to firing patterns, damage, fire intervals, prices, movement speed, controls, UI, theme, mission progression or the player's saved purchases were made for this fix.

## Automated verification

All final suites passed:

- `tests/projectile_lifecycle.tscn`: 29 checks, including a fast projectile crossing a two-unit wall, effect coordinates at its near surface, a stale target callback after actual pooled reuse, stale deferred returns, duplicate pool entries, transformed-parent effects and expiry without explosions.
- `tests/movement_firing.tscn`: 11,014 checks, all 16 aircraft × 6 weapons × 8 headings; ownership, world-space motion, muzzle blocking, terrain hits and fallback parenting.
- Equipment integration, performance safety, campaign combat and three-star progression.

Old speed/damage fixtures were corrected: speed is measured outside arena cover, and enemy damage is tested with a real swept contact rather than a synthetic non-contact callback. Existing test-process resource cleanup warnings are retained in the logs; assertions pass and physical runtime logs are checked separately.

## Physical Android matrices

All six weapons completed the eight-case real multitouch matrix, each with 308 injected events and instrumentation success. Actual recordings, stationary/movement screenshots and individual sampled rapid-turn frames were inspected. The selected aircraft and projectiles remain visible; shots follow the ship's world heading. Valid cover/enemy impacts remain at their contact points.

| Weapon | Traced shots | Verified impacts | Projectile effects |
|---|---:|---:|---:|
| Ion | 101 | 69 | 69 |
| Plasma | 89 | 42 | 42 |
| Twin Lasers | 172 | 112 | 112 |
| Quantum Spread | 288 | 178 | 178 |
| Plasma Lance | 190 | 167 | 167 |
| Nova Burst | 235 | 173 | 173 |

The trace analyzer passed all six: no duplicate impacts/despawns, off-trajectory movement, player impacts, invalid targets, effect-without-impact events or contact/effect coordinate mismatches. Every one of the 741 projectile effects matches its verified contact point. No Godot script errors, fatal signals or Java fatal exceptions appeared in these recordings. Sampled FPS ranges were 37–43 during debug tracing/screen recording; this is not a 60 FPS claim.

## Evidence and reproduction

`qa/ghost-projectile-qa/` contains the baseline/fixed QA APKs, original script snapshots, regressions, per-weapon videos/screenshots/JSONL/analyzer output, marker footage and sustained-soak evidence. `tools/analyze_projectile_trace.py <trace.jsonl>` checks trajectory and lifecycle/impact causality. `tools/run_phone_projectile_soak.py` uses the existing standalone `com.arenadash.qa` instrumentation helper to inject real simultaneous touches for 310 seconds while cycling all equipment and capturing two video segments. It never targets the player's normal package.

Swept query semantics follow [Godot's PhysicsDirectSpaceState2D API](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html): motion casting ignores initial overlaps, which are therefore checked separately, and rest information supplies the intersection point.

The in-game equipment-cycle HUD badge stays on its initial aircraft name because this diagnostic switches loadouts directly; the actual sprite and trace aircraft ID change for every case. Normal Hangar selection is unchanged.

## Completed five-minute phone verification

The completed repeat used a phone-local detached instrumentation process, which returned `elapsed_ms=310052`, `injected_events=6124`, and `INSTRUMENTATION_CODE: -1`. This is injected Android multi-pointer touchscreen input on the connected device, not manual finger testing. The same game PID (`26830`) remained alive at every 30-second checkpoint. All 96 aircraft/weapon combinations appear in shot traces. Sixty-two telemetry samples show joystick and fire held together; sampled FPS during those active samples was 35–41, with zero orphan nodes and no script errors, Java fatal exceptions or fatal signals.

The retained trace (including the gameplay settling period after input release) contains 4,458 shots, 33,417 movement samples, and 1,936 verified impacts. All 1,936 projectile effects use exactly their recorded contact points; lifecycle and trajectory analysis passed. Nine contact sheets sampled every three seconds across both video segments were inspected, in addition to the denser per-weapon rapid-turn frames. Aircraft/projectiles remained visible and no unexplained projectile explosions or ghost shots appeared in the inspected frames. Full videos remain available for review; sampled inspection does not claim to inspect every recorded frame.

One analyzer warning required investigation: shot 781 began inside an enemy before its first movement step. Godot's overlap query returned that collider's contact point 18.67 units from the bullet center. A new deep-overlap regression reproduced that an intersection contact point can exceed the projectile perimeter. The analyzer now separately records verified, unadvanced initial penetrations; the footprint bound still applies to swept contacts. No gameplay change was needed for this warning. All 29 lifecycle checks passed.

The QA profile requested Coast, but its locked campaign progression correctly selected Cyber instead. The six phone matrices and 96-loadout soak therefore test Cyber; they do not establish phone coverage of every map. Shared projectile behavior and campaign regressions were tested separately.

The earlier host-attached instrumentation stream interrupted at about 176 seconds. Its evidence is retained under `soak-interrupted/` and is not counted as completion of the required five-minute input test. The repeat's on-device completion result is in `soak/multitouch.txt`, with `run.json`, `verification.json`, both videos and the JSONL analysis beside it.

## Final normal build and save

The normal package was updated from `build/arena_dash_debug.apk` and launched successfully without diagnostic overlays. Its APK SHA-256 is `8c30bd3e3ad87942699709d8031523921f5096cd825dc70e201e16dbef4e8091`. The existing player save was checked before and after installation/launch and remained byte-identical; purchases, coins and progression were preserved. Evidence: `qa/ghost-projectile-qa/real-save-preservation.json` and `normal-home.png`.
