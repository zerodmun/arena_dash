# Centralized player projectile rebuild — 12 October 2026

## Scope and audit

The user's continued visual reports supersede the earlier claim of resolution. Previous contact-position evidence identified one bug but did not establish the cause of every reported artifact. This rebuild removes the pooled player-shot architecture rather than treating those earlier phone samples as proof of a permanent fix.

The audited runtime routes were:
- HUD / TouchFire keyboard or multitouch controls set the `fire` action. They do not instantiate shots.
- Player's physics step moved/rotated the aircraft, maintained `_fire_cd`, expanded `EquipmentCatalog.firing_pattern`, then used either `CombatPool.bullet` or a fallback `bullet.tscn` instance.
- `Bullet` was an Area2D with manually moved world pose, a compatibility body callback, activation state and deferred pooled recycling. Earlier fixes had disabled native overlap monitoring, but retained those competing lifecycle concepts.
- `ExplosionParticles.spawn` used the shared world-effect pool for player hits, enemy destruction and pickup collection.
- Enemy's `_fire_volley` / EnemyShot handle separate, intentional hostile attacks; these remain mechanically unchanged. Enemy-volley creation now has a development trace tag so incoming red laser artwork can be distinguished from player shots.
- HangarPreview draws local decorative samples from shared pattern math; it does not create gameplay Projectile nodes.
- Main's meteor warning/fireball/ground blast is a Space mission hazard, with generation checks on its delayed timers. Atmosphere renders biome foreground particles. Neither is a player firing route.
- There are no animation-track projectile spawn events or shot Timer nodes in the player scenes. Enemy attack clocks, spawners and meteor timers have separate responsibilities and are preserved.

## New runtime pipeline

`Player input after movement → WeaponController → ProjectileManager → fresh Projectile → verified contact → ImpactEffectManager`

WeaponController owns the only player firing cooldown. Selection is read synchronously for each immediate request; no deferred firing timer or saved weapon callback exists. Repeated input edges affect a single held-action state. The explicit `_shoot` regression entry point delegates to that same controller and contains no spawn logic.

WeaponData snapshots the existing catalog's texture, speed, damage, radius, lifetime, scale, color and mathematically generated pattern. Catalog prices, entitlements and save code remain in Game. Single, twin, three-shot, four-shot and five-shot configurations are preserved.

ProjectileManager accepts only the actual controller attached to its scene's Player. It rejects replayed owner/sequence requests, invalid configurations and non-finite transforms. It assigns global runtime event/shot IDs, expands each volley once, records each pattern index, validates owner clearance and checks initial/crossed/end terrain in the muzzle corridor. Blocked launches are recorded and do not create projectiles or effects. Every accepted shot is registered before parenting into the scene-owned manager, then initialized in world coordinates with scale one. No fallback route exists.

Projectile is a new Node2D with a fresh Sprite2D and query shape, not an Area2D or a pooled object. It has no activation/recycling API, collision signals, stale timers or old particle state. It uses its fixed normalized world direction and catalog speed. Initial overlaps and full motion segments are queried directly; verified contact points report through the manager. Physics interpolation is disabled for this fresh visual so rendered pose and the query pose use the same current world transform. The existing textures and local luminous wake remain. Lifetime limits the final simulated travel step. Owner exclusion and collision mask 5 preserve terrain/enemy targets while excluding the player.

Consumption removes the registry entry, group membership, visibility and processing before damage/effects. ImpactEffectManager accepts a single-use shot ID, creates a fresh one-shot emitter at the verified world contact, and deduplicates repeat receipts. It never runs on expiry, invalid spawn or normal cleanup. Restart cleanup removes active shots and impact effects immediately; scene destruction emits the exit reason and releases authority. Hostile shots and legitimate enemy/pickup world effects retain their existing separate pool.

## Files

New runtime scripts: `weapon_controller.gd`, `weapon_data.gd`, `projectile_manager.gd`, `projectile.gd`, `impact_effect_manager.gd` (plus Godot UIDs).

Migrated runtime scripts: `player.gd`, `main.gd`, `combat_pool.gd`, `projectile_trace.gd`. `enemy.gd` adds only opt-in hostile spawn metadata. `scenes/player.tscn` removes the exported legacy projectile-scene dependency.

Removed: `scripts/bullet.gd`, its UID and `scenes/bullet.tscn`. A dependency search found no remaining Bullet / bullet.tscn / CombatPool.bullet references in runtime scripts, scenes or tests. WeaponController now owns cooldown state; the old `_fire_cd` field is removed.

Verification files: `tests/projectile_lifecycle.gd` rebuilt for fresh objects and event authority; new `tests/projectile_transitions.gd/.tscn`; migrated `movement_firing.gd`, `equipment_integration.gd`, `performance_safety.gd`, `game_smoke.gd`; corrected the older `home_premium.gd` fixture to respect the preceding user-requested image-first Hangar card. No UI implementation changed in this task.

Tools: enhanced `analyze_projectile_trace.py`, new `run_phone_projectile_matrix.py`, and updated `run_phone_projectile_soak.py` output argument/default map. Diagnostics remain opt-in in the isolated debug QA package; no automation or overlay ships enabled in the normal APK.

## Verification status

The completed physical phone tests and final installation are recorded below. Headless cleanup warnings, where present, are retained separately from assertion results. The initial host-connected phone matrix lost its ADB result stream during the simultaneous build and was not counted as a completed test. The replacement runner detaches instrumentation and video capture on the device and reads the actual completion result from its local file.

## Completed automated checks

- Projectile lifecycle: 493 checks covering legitimate events, replay rejection, unauthorized controllers, all patterns/indices/directions/assets, deterministic travel, expiry without effects, owner filtering, thin-wall contact coordinates, duplicate impact rejection, blocked/end/initial-overlap muzzle corridors, 100 equipment/input-edge cycles and authority removal.
- Movement/firing: 11,014 checks for all 16 aircraft × six weapons × eight headings, under a transformed parent, including obstructed muzzle paths and actual terrain impacts.
- Real scene restarts/transitions: 118 checks over 14 rounds, with unique IDs across scenes, immediate registry cleanup, destroyed shot nodes, reset firing clock and retained-controller rejection after scene removal.
- Equipment integration, performance safety (including released allocations after 2,400 repeated volleys), game smoke across map/weapon content, campaign combat, three-star progression, coin economy, audio system, Home and Hangar layout passed.

## Completed six-weapon Android matrix

Each weapon completed the device-local multi-pointer matrix (308 injected MotionEvents, about 19.3 seconds of input within a 24-second recording). It includes stationary fire, move-only, horizontal/vertical/diagonal movement with firing and rapid heading changes. This is actual injected touchscreen input on the connected Redmi Note 8, not manual finger testing. JSONL analysis links every player shot to its owner/event/index, matches origin/direction/speed to that event's mathematical pattern, and checks lifecycle/trajectory/contact/effect causality. Runtime logs have no Godot script errors or fatal exceptions.

| Weapon | Accepted firing events | Spawned shots | Verified impacts/effects |
|---|---:|---:|---:|
| ion | 105 | 82 | 78 |
| plasma | 106 | 99 | 71 |
| twin_laser | 105 | 194 | 170 |
| quantum_spread | 105 | 297 | 195 |
| plasma_lance | 63 | 239 | 193 |
| nova_burst | 60 | 292 | 187 |

All six analyses passed. Accepted events can have fewer shots where terrain blocks one or more muzzle corridors; every omitted pattern index has a `spawn_blocked` record, rather than an unexplained projectile or explosion. Total: 1,203 shots and 894 verified projectile effects. Full recordings and screenshots are in `qa/projectile-rebuild-qa/matrix/`. Dense individual frames from movement/rapid-turn sections were inspected for every weapon; no unexplained player shots or misplaced projectile effects appeared in the inspected frames. Valid nearby enemy hits and gold pickup effects remain.


## Completed sustained Android test

Device-local instrumentation completed 310,063 ms of actual gameplay input, injecting 6,120 MotionEvents. The same game PID (4000) remained alive in all eleven snapshots from startup through 300 seconds. All 96 aircraft/weapon pairs appeared in spawn records. The complete-record analysis passed: 1,868 authorized firing events, 4,552 shots, 34,143 movement samples, 4,552 destruction records and 2,028 verified projectile impacts/effects. Two impacts began with a verified overlap from moving colliders; these are explicitly recorded as initial-overlap contacts, not treated as swept surface contacts.

The raw live-file capture ends with one incomplete `hostile_spawn` JSON record. It is retained unchanged as `soak/projectile-trace.jsonl`; only that final partial record is excluded in `projectile-trace-complete.jsonl`. All preceding records parse, and every player firing event, shot and effect is accounted for. This is a capture boundary, not a skipped player lifecycle failure.

The tested game PID has no Godot errors, script errors or fatal exceptions. The full unfiltered log also retains Android video encoder capability warnings and a surface-lost error from the prior stopped game PID 1733; these are separated in `coverage.json`. Sampled FPS ranged from 35 to 42 while recording with diagnostics, and sampled orphan-node counts remained zero. This does not establish sustained 60 FPS. Both recordings were sampled every three seconds and all nine resulting contact sheets were inspected; no unexplained player shots or misplaced projectile effects appeared in these inspected frames. The earlier six-weapon matrix provides denser rapid-turn samples.

The QA equipment cycler changes actual ship/weapon data and sprites every three seconds, with repositioning and extended invulnerability to cover all combinations. Its HUD shield label retains the initially selected Tempest name; loadout coverage uses spawn metadata and actual aircraft art. These diagnostic adjustments require the isolated `arena_review` build and opt-in QA configuration. Normal gameplay retains its existing controls, damage and equipment flow.

Evidence: `qa/projectile-rebuild-qa/soak/{run.json,multitouch.txt,coverage.json,analysis.json,logcat.txt,gameplay-1.mp4,gameplay-2.mp4,inspection-*.png}`. Restart/scene-exit correctness is covered by the separate 118-check real-scene automated suite, rather than claimed as part of this continuous phone session.

## Final normal APK and save preservation

Built and installed `build/arena_dash_debug.apk` into the normal `com.example.arenadash` package, then launched Home and opened Hangar on the connected Redmi Note 8. The existing player save was byte-identical before installation, after startup and after opening Hangar. SHA-256 before/after: `6ce4458f34a9732f481f82052bbd0b9a157f72e3f512460f50ad237ad9007a11`. See `qa/projectile-rebuild-qa/real-save-preservation.json`. Existing aircraft/weapon artwork, prices, entitlements, progression, localization and the preceding image-first Hangar improvement remain preserved.

APK SHA-256: `05ac5601682c4f5e5792f9a577b8e25872993b52df9817e7d87c35e7a9b4e871`. Build output: `qa/projectile-rebuild-qa/normal-build.log`. Final phone screenshots: `normal-home.png`, `normal-hangar.png`. Tests establish the recorded scenarios and lifecycle invariants; finite sampled visuals cannot prove the absence of every possible future rendering artifact.
