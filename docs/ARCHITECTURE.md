# Arena Dash architecture

Current source reference, updated 2026-10-09. See the [documentation index](README.md) and [localization/control report](LOCALIZATION_CONTROLS.md) for related guides.

## Scenes and navigation

`project.godot` starts `scenes/menu.tscn`. The menu opens the hangar, planet campaign, or settings. `scripts/hangar.gd` builds the aircraft showcase, stats, horizontal roster, weapon selection/live preview, progress planet, and deployment action. `scripts/level_select.gd` builds the eight-node campaign route; locked worlds can be inspected but cannot deploy. Preparing a world selects it and returns to the hangar. Deployment opens `scenes/main.tscn`.

Combat uses `scripts/main.gd` for arena setup, camera tracking/shake, environmental hazards, and mission reset. `scripts/player.gd` handles CharacterBody2D movement, firing, customization, and damage protection. `enemy.gd`, `enemy_spawner.gd`, and `enemy_shot.gd` implement movement roles, formations, guardians, warning telegraphs, and hostile projectiles. Pickups and moving cover retain their existing spawn/physics systems. `hud.gd` manages mission information, pause/settings, touch controls, and results/progression actions.

There is no live weapon-switch button, special-ability button, or upgrade economy. The weapon loadout is chosen in the hangar before deployment.

## Autoloads and shared modules

Autoload order matters: `I18n` initializes before `Game`, allowing saved language restoration during Game startup.

| Module | Responsibility |
|---|---|
| `I18n` / `scripts/i18n.gd` | Load EN/ID JSON catalogs, register Godot translations, format dynamic text, emit language changes |
| `Game` / `scripts/game.gd` | Aircraft/weapon/map catalogs, selections, score/lives, mission and guardian state, campaign progress, saved preferences |
| `InputSetup` / `scripts/input_setup.gd` | Register movement, `fire`, and fullscreen actions; handle F11/Alt+Enter |
| `PerfDiagnostics` / `scripts/perf_diagnostics.gd` | Opt-in debug frame, CPU/GPU, input-to-physics, memory and actor diagnostics; disabled in release |
| `SoundEffects` / `scripts/sound_effects.gd` | Generate and play synthesized weapon, impact, pickup, and alert sounds |
| `Campaign` / `scripts/campaign.gd` | Stable world order, planet art, difficulty labels, drone targets, enemy rosters, guardian presence |
| `ArcadeUI` / `scripts/arcade_ui.gd` | Shared typography, colors, panels, buttons, icons, sliders, focus loops, and dialog creation |
| `FlightDialog` / `scripts/flight_dialog.gd` | Categorized settings/manual, modal input, focus restoration, prior pause-state restoration |

Game broadcasts `score_changed`, `lives_changed`, `game_started`, `game_over`, `mission_completed`, `mission_progress_changed`, `boss_status_changed`, selection signals, `ui_mode_changed`, `preferences_changed`, and `screen_shake_requested`.

## Campaign and completion

| Level | Map ID | Planet | Drone target | Guardian |
|---|---|---|---:|---|
| 1 | `cyber` | Cyber Matrix | 16 | No |
| 2 | `forest` | Primal Jungle | 22 | No |
| 3 | `space` | Void Horizon | 28 | No |
| 4 | `coast` | Coastal Front | 34 | Yes |
| 5 | `desert` | Dune Outpost | 40 | Yes |
| 6 | `volcano` | Magma Caldera | 46 | Yes |
| 7 | `glacier` | Glacial Tundra | 52 | Yes |
| 8 | `toxic` | Toxic Citadel | 58 | Yes |

Targets follow `16 + level_index * 6`. Levels 4–8 require both the drone target and guardian defeat. A surviving completed attempt earns one star, plus one for taking no more than half the selected aircraft’s starting shields (rounded down, minimum one), plus one for meeting the level time limit. Limits for levels 1–8 are **120, 140, 160, 210, 230, 250, 270, 290 seconds**. Both bonus boundaries are inclusive.

Only a saved best rating of exactly three stars clears a world. Every earlier world must have three stars before a later world unlocks. One- and two-star attempts are saved, remain replayable, and cannot advance the campaign. Results show the current attempt and saved best separately; Retry is prominent on partial clears and Next is disabled until the current attempt earns three stars. A weaker replay preserves an existing best clear. All related messages support English and Indonesian.

`select_level`, `select_map`, mission startup, and completion enforce locks independently of the UI. Random map selection samples only unlocked worlds. Legacy saves retain valid 1–3 star ratings, discard malformed/nonfinite/out-of-range ratings, and recompute the contiguous unlock chain; an orphan later-world three-star rating cannot bypass a missing earlier clear. `last_completed_planet` refers to a valid three-star clear, falling back to the highest contiguous clear when necessary. See [Performance and progression](PERFORMANCE_PROGRESSION.md) for criteria and verification, and the [campaign report](CAMPAIGN_REDESIGN.md) for map/planet asset assignments.

## Save data

Game writes `user://arena_dash_save.cfg` using `ConfigFile`; tests override `Game.save_path` with project-local files under `build`. Exported Web saves use Godot's browser storage; native saves use the platform-specific user-data directory.

| Section | Keys |
|---|---|
| `stats` | `high_score` |
| `settings` | `ship`, `weapon`, `map`, `audio`, `reduced_motion`, `language` |
| `campaign` | `completed` (world ID → best star count), `last_completed` |
| `controls` | `layout` (joystick/fire dictionaries) |

Invalid selection IDs fall back to valid defaults; a saved locked map falls back to `cyber`. Control layouts sanitize invalid types/nonfinite positions and clamp size/opacity. Older saves receive default controls and English when no language preference exists. High-score increments mark a dirty flag instead of writing on every kill. Pause/settings, results, defeat, focus loss/backgrounding, hangar return and orderly exit flush dirty scores. Campaign results persist immediately. Other settings save immediately; the editor commits only through Save Layout.

## Localization

`localization/en.json` and `localization/id.json` currently contain 199 matching keys. English source strings are stable keys; static controls use Godot automatic translation. Dynamic content calls `I18n.t(key, arguments)` before formatting, then refreshes on `I18n.changed`. Proper aircraft/weapon/planet names remain unchanged.

Web locale is also mirrored to localStorage under `arena-dash-language` for the pre-engine loader. `tools/build_web_shell.py` generates `templates/web_shell.html` from the stock shell and the same catalogs. The gameplay save remains the source of truth for in-game preferences. Translation maintenance is described in the [localization report](LOCALIZATION_CONTROLS.md).

## Touch layout and modal input

`TouchLayout` stores normalized centers, size multipliers, and opacity for `joystick` and `fire`. Default centers are `(0.12, 0.82)` and `(0.91, 0.82)`. Base diameters are 28% and 19% of viewport height; size ranges 0.8–1.4, opacity 0.35–1.0. Resolved geometry reserves the top 28%, 2.5% horizontal margins, and 3% bottom margin, further intersecting reported Android/iOS display safe areas. Overlap is rejected while dragging; aspect-ratio overlap falls back to separated safe positions.

`ControlLayoutEditor` edits a sanitized copy using separate `LayoutHandle` input scripts. Its selected map/aircraft preview does not run flight logic. Save applies/persists the draft, Cancel preserves live settings, and Reset changes the draft until Save. Preview aspect ratio follows viewport changes.

`TouchFire` and `GameJoystick` own separate finger indices and release held input even when a finger releases outside the hit region. Circular hit regions and joystick travel scale with the layout. Focus loss resets both. Settings opened during flight pause simulation and release/reset input; closing restores the preceding pause state. HUD listens for preference/viewport changes to resolve saved controls. Touch UI appears on native/touchscreen platforms or windows at most 1120 pixels wide; desktop keyboard controls remain available.

## Rendering and assets

Project startup configuration lists a 1920×1080 viewport, but `Game._update_device_detection()` sets the runtime logical canvas to **1280×720**. Landscape windows expand horizontally; portrait windows use aspect-preserving letterboxing. Stretch mode is `canvas_items`; native handheld orientation is landscape. HiDPI and MSAA/screen-space antialiasing are disabled in the current configuration. Native rendering uses Godot's Mobile method; Web uses Compatibility with threading disabled.

Every arena is 6800×4400 units. Sixteen 1700×1100 deterministic `LandscapeChunk` nodes supply biome terrain; offscreen chunks are culled. Existing map images remain proportion-preserved landmarks. Portrait hangar backgrounds fit uniformly and extend with surrounding color/stars rather than stretching. UI artwork is reused from nested supplied assets, with shared code styles for surfaces and interaction states.

The latest [recursive inventory](localization-asset-inventory.json) records 215 source resources. All 208 graphical resources audited before the localization/control refinement remained unchanged. Historical counts in earlier reports refer to their respective implementation phases.

## Simulation and allocation

Simulation runs at 60 fixed physics ticks with interpolation and up to eight catch-up steps. Mission time, pickup bobbing and camera tracking run in physics; the camera follows after actors with one exponential smoothing stage. Movement remains delta-based and firing/spawn timers preserve fractional overshoot. No combat population or visual resolution was reduced.

Scene-owned `CombatPool` prewarms 96 player bullets, 64 hostile shots and 24 particle bursts. Returned instances disable processing/collision and leave active groups; activation resets lifetime, weapon, transform and interpolation. Pool growth preserves effects during bursts, with bounded retained free instances. Weapon/meteor textures and enemy volley angles are cached; HUD objective and boss strings update only when their values change. Pickup spawning pauses at 32 live pickups. Debug diagnostics require `--perf` and allocate no sampling buffers in ordinary runs. See the [measurement report](PERFORMANCE_PROGRESSION.md).
