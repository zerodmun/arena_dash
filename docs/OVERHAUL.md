# Arena Dash implementation report

> Historical report of the initial overhaul. Counts, portrait behavior, and balance below describe that phase. Use the [documentation index](README.md), [current architecture](ARCHITECTURE.md), and [testing guide](TESTING.md) for the current implementation. The [localization/control report](LOCALIZATION_CONTROLS.md) covers the latest settings and input changes.

The later [landscape UI report](LANDSCAPE_UI.md) supersedes the layout and portrait-adaptation details below.

The later [campaign redesign report](CAMPAIGN_REDESIGN.md) supersedes the campaign layout, enemy balance and mission completion sections below. This file documents the initial overhaul.

The existing Godot 4.7 game engine, scenes, flight physics, four weapon patterns, touch joystick, sound synthesizer, and original seven aircraft are retained. A project-local `overhaul-backup.zip` preserves the pre-change scripts, scenes, tests, documentation, README, and engine configuration. Original artwork has not been overwritten or deleted.

## Recursive asset audit

`asset-inventory.json` records every source resource under `assets`, recursively, with file size, SVG dimensions, viewBox and element count. There are 83 resources: 81 images and two documentation files. Four rendered contact sheets in `build/assets_*.png` cover all images. Orphan `.import` entries for the previously removed hangar PNGs are metadata rather than usable artwork; the replacement uses existing nested SVGs.

Integrated resources include all seven original aircraft and five nested expansion craft (Saucer, Rocket, Wedge, Speeder, Booster); all eight original environment maps; all eight matching `planet_*.svg` previews; the galaxy progression backdrop; both portrait hangar backgrounds and the docking pedestal; home, settings, back, close, play, pause, action and star UI assets; nested crystal pickups and asteroid boulders; original biome obstacles, bullets, joystick and fire button. Decorative SVG logos contain text that Godot's SVG renderer omits, so the menu uses an existing aircraft hero and native editable labels. Unused reward/chest art remains available without inventing an unrelated economy.

## Screens and gameplay

- New entry menu routes to the hangar, planet campaign and settings.
- Hangar: 12 selectable aircraft, swipe/keyboard carousel, scrolling roster, large aspect-preserved preview, docking pedestal, live weapon preview, stats and selected planet.
- Planet campaign: eight cards, difficulty, kill objective, planet art, saved star ratings, and locked/ready/completed states. Selecting an available world returns to the hangar for loadout/deployment.
- Combat HUD: score, shields, planet difficulty, objective count, elapsed mission time, pause/settings, desktop fullscreen and mobile controls.
- Mission completion: kill objective ends the mission, saves its rating and unlocks the next world. Results offer replay, hangar or next planet. Final planet shows campaign completion.
- Defeat and retry reset mission counters, shields, enemies, projectiles, moving cover and camera. Pause stops simulation and releases touch/fire input.
- Settings persist sound and reduced camera shake. Existing saved loadouts are validated. Test saves use project-local paths and do not overwrite player progress.

## Planet assignments

| Level | Existing environment | Planet asset | Difficulty | Drone objective | Enemy HP |
|---|---|---|---|---:|---:|
| 1 | Cyber Matrix / `map_cyber.svg` | `planet_cyber_matrix.svg` | Cadet | 16 | 1 |
| 2 | Primal Jungle / `map_forest.svg` | `planet_primal_jungle.svg` | Patrol | 22 | 1 |
| 3 | Void Horizon / `map_space.svg` | `planet_void_horizon.svg` | Hostile | 28 | 1 |
| 4 | Coastal Front / `map_coast.svg` | `planet_coastal_front.svg` | Veteran | 34 | 2 |
| 5 | Dune Outpost / `map_desert.svg` | `planet_dune_outpost.svg` | Elite | 40 | 2 |
| 6 | Magma Caldera / `map_volcano.svg` | `planet_magma_caldera.svg` | Inferno | 46 | 2 |
| 7 | Glacial Tundra / `map_glacier.svg` | `planet_glacial_tundra.svg` | Extreme | 52 | 3 |
| 8 | Toxic Citadel / `map_toxic.svg` | `planet_toxic_citadel.svg` | Commander | 58 | 3 |

Enemy base speed increases from 85 to 176, initial spawn interval decreases from 1.9 to 0.85 seconds, and active population increases from 14 to 35. Armor absorbs successive projectile hits. Stars reward clearing a mission, retaining two shields, and completing within 150 seconds; the best rating is kept.

## Expanded landscape worlds

Every physical arena is 6,800 × 4,400 units, four times the original playable area, with matching walls, camera bounds, spawn regions, pickups and moving-cover bounds. Sixteen deterministic 1,700 × 1,100 chunks extend each biome with distinct terrain variation. World-coordinate river paths remain continuous across chunk boundaries. Static draw commands are cached and offscreen chunks are culled. Original map illustrations are uniformly scaled, edge-feathered landmarks; original obstacle proportions are retained. Additional cover populates the enlarged environment, with a safe launch zone.

Actual map SVGs are 512 × 512, rather than portrait. The two nested progression maps are 1,920 × 1,080. Portrait hangar backdrops are 1,080 × 1,920: fit their full height uniformly and extend the surrounding cosmic color/star field horizontally. The hangar fades artwork edges into its surroundings. No original asset is stretched into a landscape rectangle. Camera tracking, bounded scrolling, biome particles and world-relative parallax support 16:9 and 20:9 layouts. Phone controls also remain usable in portrait.

## Verification and practical limits

Integration tests exercise all maps, all aircraft previews, all four firing patterns, moving cover, pause, locked-level rejection, increasing difficulty, mission completion, defeat, replay and campaign save/load. Rendered checks cover 1,920 × 1,080, 1,280 × 720, 1,600 × 720 (20:9), and 720 × 1,280. Web and Android exports are generated locally. Physical Android hardware and iOS are not available for device performance validation. Android export retains the project's existing signing configuration and package identity; this is a local test build, not a store release. Only the master-prompt text was attached, so separate reference-image accuracy could not be checked. The supplied SVG artwork and its reference descriptions guide the visual theme.

Build output, tests, backup and documentation are excluded from exported game packs. No deployment was performed.

Final results: `GAME SMOKE: PASS — 0 failures`; `HANGAR REVIEW: PASS / 0 failures`. Real physics checks verify two projectile hits destroy a two-HP drone and keyboard input moves the player. Every aircraft is instantiated in combat, and mobile fire press/release and pause reset are checked. Rendered screenshots cover all eight biomes and both success/failure screens. The compiled Web game was opened locally and exercised through menu, campaign, hangar, movement, firing and pause. Android APK verification passes signature schemes v2 and v3. Sandbox-only editor-settings/log/ADB diagnostics do not prevent exports; no game script errors remain. Audio shutdown checks finish without leaked-object warnings.
