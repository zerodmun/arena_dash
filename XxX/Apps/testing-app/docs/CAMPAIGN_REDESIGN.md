# Planet campaign implementation

> Implementation-stage campaign report. Map assignments and campaign systems remain relevant; asset counts and validation below describe that phase. The portrait route has been replaced by landscape letterboxing. See the [documentation index](README.md) and [current architecture](ARCHITECTURE.md) for the active implementation.

The later [landscape UI report](LANDSCAPE_UI.md) supersedes the layout and portrait-adaptation details below.

The supplied image guides the blue/purple cosmic sky, lower mountain silhouettes, winding dotted route, circular glowing planets, numbered badges and three-star ratings. The original card grid is replaced with this composition. Selecting a node shows its difficulty, objective, combat identity and lock state in the bottom briefing. Locked worlds can be inspected but cannot deploy. Landscape layouts were rendered at 1920×1080, 1280×720 and 1600×720; the original portrait route at 720×1280 used a staggered vertical layout, which the later landscape conversion replaced with letterboxing. Keyboard arrows inspect worlds, Enter prepares an unlocked mission, and Escape returns to the hangar. Hover/press effects and a short entrance fade respect reduced motion.

## Assets and integrity

All 83 original source resources were recursively inventoried, including 81 images and two asset documents. Existing planet previews, numbered labels, star badges, back/play/settings controls, the expansion rocket and the horizon sky are integrated into the new page. Wedge and saucer aircraft distinguish flankers/chargers and orbiters; the booster becomes the guardian craft. Existing laser art supplies hostile plasma. Original aircraft, hangar elements, maps, biome obstacles, pickups and weapon art remain integrated from the initial overhaul.

`assets/generated/campaign_horizon.svg` is a supporting landscape adaptation of `assets/future_updates/maps/map_starfield_horizon.svg`: preserve its sky, stars, meteor trails and mountains; remove its baked navigation circles, dashed route and rocket so live controls do not duplicate decorations; enrich the blue/purple atmosphere with light ribbons. The original SVG is intact. The inventory now records 84 resources including this one derived asset. `campaign-redesign-backup.zip` preserves the scripts/scenes/configuration before this change. No original assets were deleted or overwritten in this redesign.

The map illustrations are actually square 512×512. Existing 6800×4400 biome arenas extend them through sixteen deterministic chunks and proportion-preserved, feathered landmarks. The portrait 1080×1920 hangar backgrounds retain their aspect ratio, fit to height, and extend with matching cosmic color and stars horizontally. No portrait artwork is stretched to fill landscape.

## Progression and the hangar

The shared PlanetButton draws actual planet artwork, glow rings, hover feedback and press animation, with a circular hit test. It opens the campaign from the hangar. The first game shows Cyber Matrix. Each successful mission records `campaign.last_completed` alongside best star ratings, including replays of earlier planets. Reopening restores that exact last completion independently of the selected launch destination. Defeat never updates it. Completing a world unlocks the next; later missions require both the drone objective and guardian defeat. Legacy saves missing this new field migrate to their highest completed planet, since historical completion order was never stored.

## Level assignments and combat

| Level | Planet / environment asset | Target | Challenge | Guardian pattern |
|---|---|---:|---|---|
| 1 | Cyber Matrix / map_cyber.svg / planet_cyber_matrix.svg | 16 | First three waves teach pursuit; later aimed gunner fire | None |
| 2 | Primal Jungle / map_forest.svg / planet_primal_jungle.svg | 22 | Predictive flanks and paired wings around tree cover | None |
| 3 | Void Horizon / map_space.svg / planet_void_horizon.svg | 28 | Tangential orbiters, two-shot crossfire, drifting asteroid cover | None |
| 4 | Coastal Front / map_coast.svg / planet_coastal_front.svg | 34 | Gunner pressure and V-wing formations | Three-shot fan |
| 5 | Dune Outpost / map_desert.svg / planet_dune_outpost.svg | 40 | Committed charge runs and escort V formations | Narrow three-shot volley |
| 6 | Magma Caldera / map_volcano.svg / planet_magma_caldera.svg | 46 | Mixed orbiters, gunners and chargers around basalt cover | Eight-direction thermal ring |
| 7 | Glacial Tundra / map_glacier.svg / planet_glacial_tundra.svg | 52 | Flanks, orbiters and chargers converge around cryo cover | Four-shot crossfire |
| 8 | Toxic Citadel / map_toxic.svg / planet_toxic_citadel.svg | 58 | All four attack roles in mixed three-craft squadrons | Five-shot command spread |

Base speed increases 85→176, initial wave interval decreases 1.90→0.99 seconds, active population grows 14→28, and firing intervals decrease 4.40→2.51 seconds. Every third later wave uses paired/triple formations. Ordinary pursuers/flankers/chargers retain one hit point, gunners/orbiters have two; difficulty comes from positioning and attacks. Guardians have 26→34 hit points, slower movement and faster firing. They arrive halfway through the drone objective, once per mission.

Gunners maintain distance; orbiters circle tangentially; flankers lead player movement; chargers warn for 0.85 seconds then commit to a 0.6-second dash. Projectile attacks warn for 0.7 seconds with visible aim lines for each volley direction. Spawns stay at least 500 units from the player and clear of moving cover. Projectiles travel at 220–290 units/second, expire after four seconds, stop on cover and cap at 64 active shots. Normal hits cost one shield, guardian projectiles two, with 1.2 seconds of player invulnerability to prevent stacked damage. Pause and results stop attacks. There are no invisible damaging terrain zones: environmental challenges use visible physical moving cover.

## Validation

- `tests/game_smoke.tscn`: all eight maps, twelve ships, four weapons, movement, armor hits, objectives, save/load, defeat/retry and boss completion gate.
- `tests/hangar_review.tscn`: rendered menu/hangar/campaign layouts at four resolutions, all ship/weapon previews, node lock/deploy behavior, circular hit geometry, pause, results, mobile fire and touch reset.
- `tests/campaign_combat.tscn`: every planet's movement roles and gradual difficulty, safe spawns, warning timing, real projectile collisions, invulnerability, bounded guardian damage, unique guardian volleys, one boss per mission, boss health tracking, mandatory boss defeat, next-world progression, older-world replay completion order, reopened hangar artwork and legacy-save migration.

Test saves are project-local and do not alter player saves. Build artifacts and documentation are excluded from exported packs. Physical Android performance and human difficulty tuning remain unverified. Android uses the existing local debug signing identity; the APK is for testing, not a store release. No deployment occurred.

Final results: GAME SMOKE PASS, HANGAR REVIEW PASS, CAMPAIGN COMBAT PASS, all with zero failures and no script errors. Web and Android release exports exited successfully. The rebuilt Web game was opened locally and checked through menu → campaign → locked-world inspection → preparation → hangar → circular planet-button navigation, with no browser warning/error logs. APK signature verification passes v2 and v3. Sandbox restrictions produce editor-settings/log/ADB diagnostics, but do not prevent the builds or game tests.
