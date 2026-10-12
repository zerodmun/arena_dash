# Arena Dash architecture

Current source reference, updated 2026-10-09. See the [documentation index](README.md) and [localization/control report](LOCALIZATION_CONTROLS.md) for related guides.

## Scenes and navigation

`project.godot` starts `scenes/menu.tscn`. The menu opens the hangar, planet campaign, or settings. `scripts/hangar.gd` builds the aircraft showcase, stats, horizontal roster, weapon selection/live preview, progress planet, and deployment action. `scripts/level_select.gd` builds the campaign route across two pages (eight original nodes, seven advanced nodes); locked worlds can be inspected but cannot deploy. Preparing a world selects it and returns to the hangar. Deployment opens `scenes/main.tscn`.

Combat uses `scripts/main.gd` for arena setup, camera tracking/shake, environmental hazards, and mission reset. `scripts/player.gd` handles CharacterBody2D movement, customization and damage protection, and delegates firing input to `WeaponController`. `enemy.gd`, `enemy_spawner.gd`, and `enemy_shot.gd` implement movement roles, formations, guardians, warning telegraphs, and hostile projectiles. Pickups and moving cover retain their existing spawn/physics systems. `hud.gd` manages mission information, pause/settings, touch controls, and results/progression actions.

There is no live weapon-switch button, special-ability button, or upgrade economy. The weapon loadout is chosen in the hangar before deployment.

## Autoloads and shared modules

Autoload order matters: `I18n` initializes before `Game`, allowing saved language restoration during Game startup.

| Module | Responsibility |
|---|---|
| `I18n` / `scripts/i18n.gd` | Load EN/ID JSON catalogs, register Godot translations, format dynamic text, emit language changes |
| `Game` / `scripts/game.gd` | Aircraft/weapon/map catalogs, selections, score/lives, mission and guardian state, campaign progress, saved preferences |
| `InputSetup` / `scripts/input_setup.gd` | Register movement, `fire`, and fullscreen actions; handle F11/Alt+Enter |
| `PerfDiagnostics` / `scripts/perf_diagnostics.gd` | Opt-in debug frame, CPU/GPU, input-to-physics, memory and actor diagnostics; disabled in release |
| `SoundEffects` / `scripts/sound_effects.gd` | Direct licensed music/UI/combat audio, pooled voices, crossfades, pause handling, and bus volumes |
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
| `audio` | `Master`, `Music`, `UI`, `SFX` normalized volumes |
| `settings` | `ship`, `weapon`, `map`, `audio`, `reduced_motion`, `language` |
| `campaign` | `completed` (world ID → best star count), `last_completed` |
| `controls` | `layout` (joystick/fire dictionaries) |

Invalid selection IDs fall back to valid defaults; a saved locked map falls back to `cyber`. Control layouts sanitize invalid types/nonfinite positions and clamp size/opacity. Older saves receive default controls and English when no language preference exists. High-score increments mark a dirty flag instead of writing on every kill. Pause/settings, results, defeat, focus loss/backgrounding, hangar return and orderly exit flush dirty scores. Campaign results persist immediately. Other settings save immediately; the editor commits only through Save Layout.

## Localization

`localization/en.json` and `localization/id.json` currently contain 199 matching keys. English source strings are stable keys; static controls use Godot automatic translation. Dynamic content calls `I18n.t(key, arguments)` before formatting, then refreshes on `I18n.changed`. Proper aircraft/weapon/planet names remain unchanged.

Web locale is also mirrored to localStorage under `arena-dash-language` for the pre-engine loader. `tools/build_web_shell.py` generates `templates/web_shell.html` from the stock shell and the same catalogs. The gameplay save remains the source of truth for in-game preferences. Translation maintenance is described in the [localization report](LOCALIZATION_CONTROLS.md).

## Touch layout and modal input

`TouchLayout` stores normalized centers, size multipliers and opacity for `joystick` and `fire`, plus `joystick.fixed`. Legacy saves default to fixed mode, preserving the previous anchored control. Default centers remain `(0.12, 0.82)` and `(0.91, 0.82)`. Movement may occupy the entire usable left half, including above the former HUD reservation. Resolution clamps the full knob-at-maximum-travel footprint inside the reported display safe area. Shooting stays in the right half below the HUD, preventing overlap. Positions persist in the existing `controls/layout` save dictionary.

`ControlLayoutEditor` edits a sanitized draft using separate `LayoutHandle` scripts and a terrain/selected-aircraft preview. Settings → Display → Gameplay exposes Customize Control Position and an immediately saved Fixed Control toggle. Apply commits and persists the editor draft, Cancel preserves live settings, and Reset changes only the draft until Apply. Preview aspect ratio follows the landscape viewport.

`TouchFire` and `GameJoystick` own separate finger indices. Fixed movement begins inside the selected base circle and never relocates it. Dynamic movement begins anywhere in the usable left half, moves its base toward a finger beyond the original travel radius, and returns to the selected center on release. Neither mode changes the saved position during gameplay. Both modes retain the existing normalized movement output and independent simultaneous shooting. Focus loss resets input; settings pause flight. HUD re-resolves saved geometry after preference or viewport changes. See [Control positioning](CONTROL_POSITION.md) for validation and limitations.

## Rendering and assets

Project startup and `Game._update_device_detection()` use the same **1280×720** logical canvas. Landscape windows expand horizontally; portrait windows use aspect-preserving letterboxing. Stretch mode is `canvas_items`; native handheld orientation is landscape. HiDPI and MSAA/screen-space antialiasing are disabled in the current configuration. Native rendering uses Godot's Mobile method; Web uses Compatibility with threading disabled.

Every arena is 6800×4400 units. Sixteen 1700×1100 deterministic `LandscapeChunk` nodes supply biome terrain; offscreen chunks are culled. Existing map images remain proportion-preserved landmarks. Home, Hangar, and campaign use a landscape starfield recomposed from supplied vector artwork, displayed with aspect-preserving cover. Ships and planet art retain their proportions. `ArcadeUI` shares muted glass panels, rounded capsule buttons with cached gradient artwork and input-driven feedback, bold headings, and device safe-area mapping across menus and gameplay overlays. See [UI theme](UI_THEME.md) and [Button design system](BUTTON_DESIGN.md) for asset derivation and validation.

The latest [recursive inventory](localization-asset-inventory.json) records 215 source resources. All 208 graphical resources audited before the localization/control refinement remained unchanged. Historical counts in earlier reports refer to their respective implementation phases.

## Simulation and allocation

Simulation runs at 60 fixed physics ticks with interpolation and up to eight catch-up steps. Mission time, pickup bobbing and camera tracking run in physics; the camera follows after actors with one exponential smoothing stage. Movement remains delta-based and firing/spawn timers preserve fractional overshoot. No combat population or visual resolution was reduced.

Player firing uses one `WeaponController` clock and catalog-backed `WeaponData` snapshots. A scene-owned `ProjectileManager` validates each owner/event/sequence and muzzle corridor, assigns unique IDs, and instantiates fresh world-space `Projectile` nodes. Projectiles disable interpolation to render their current collision pose, sweep their configured circle along a fixed trajectory, and are consumed before applying damage. `ImpactEffectManager` creates one fresh effect at each verified contact; expiry and cleanup create none. Scene restarts clear the registry and all impact effects. Player shots and their impact effects are not pooled. `CombatPool` retains only the unrelated 64 hostile shots and 24 world particle bursts. See [Projectile rebuild](PROJECTILE_REBUILD.md) for authority, lifecycle and phone evidence. Weapon/meteor textures and enemy volley angles are cached; HUD objective and boss strings update only when their values change. Pickup spawning pauses at 32 live pickups. Debug diagnostics require `--perf` and allocate no sampling buffers in ordinary runs. See the [measurement report](PERFORMANCE_PROGRESSION.md).
