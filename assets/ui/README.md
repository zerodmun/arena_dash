# Unified Game UI Asset Library

This directory contains the unified, production-ready vector SVG UI asset library for the game. Every asset has been crafted to adhere **100% strictly** to the established sci-fi arcade visual language:
- **Consistent Color Palette**: Deep cosmic ink (`#082f49`, `#031d30`), electric cyan/sky blue (`#38bdf8`, `#0284c7`), arcade gold (`#facc15`, `#ca8a04`), tactical crimson (`#ef4444`, `#7f1d1d`), and bio-emerald (`#22c55e`, `#15803d`).
- **Surface & Material Consistency**: Chrome bezels, heavy 3D beveled rims, glossy specular sheen curves, drop shadows, and non-slip tactile grooves.
- **Directional & State Symmetry**: Complete pairs of directional arrows (`back`, `forward`, `up`, `down`), toggles (`on`, `off`), checkboxes (`checked`, `unchecked`), and button interactive states (`normal`, `pressed`, `disabled`).

---

## Directory Organization & Asset Manifest

```text
assets/ui/
├── buttons/      # 29 directional, navigation, action buttons & interactive states
├── controls/     # 6 tactile 3D on-screen gameplay controls (512×512)
├── hud/          # 7 gameplay HUD indicators, bars, radar & boss meter
├── modals/       # 10 dialog cards, frames, tech overlays & title logos
├── badges/       # 11 rating stars, mission ranks (S/A/B/C), and status badges
├── sliders/      # 6 sliders, thumbs, toggle switches & checkboxes
└── icons/        # 7 inline 48×48 HUD counters & resource icons
```

---

### 1. Buttons & Navigation (`assets/ui/buttons/`)
| File | Dimensions | Style / Palette | Description & Purpose |
| :--- | :---: | :--- | :--- |
| `button_back.svg` | 72×72 | Cyan Rounded Square | Left arrow navigation button (original baseline reference). |
| `button_forward.svg` | 72×72 | Cyan Rounded Square | Matching **Right arrow** forward / next navigation button. |
| `button_up.svg` | 72×72 | Cyan Rounded Square | Matching **Up arrow** menu navigation button. |
| `button_down.svg` | 72×72 | Cyan Rounded Square | Matching **Down arrow** menu navigation button. |
| `button_restart.svg` | 72×72 | Cyan Rounded Square | Matching circular reload/restart arrow for game over / restart. |
| `button_info.svg` | 72×72 | Cyan Rounded Square | Matching info `i` manual / help button. |
| `button_pause.svg` | 72×72 | Cyan Rounded Square | Double vertical pause bars button. |
| `button_play.svg` | 72×72 | Cyan Rounded Square | Triangle forward play button. |
| `button_close.svg` | 72×72 | Cyan Rounded Square | `X` close dialog button. |
| `button_home.svg` | 72×72 | Golden Rounded Square | Home menu icon button. |
| `button_menu.svg` | 72×72 | Golden Rounded Square | 3-line hamburger menu button. |
| `button_settings.svg` | 72×72 | Golden Rounded Square | Cogwheel settings button. |
| `button_audio.svg` | 72×72 | Golden Rounded Square | Speaker / sound effects button. |
| `button_audio_off.svg`| 72×72 | Golden Rounded Square | Speaker with mute slash icon button. |
| `button_trophy.svg` | 72×72 | Golden Rounded Square | Trophy cup leaderboard / high scores button. |
| `button_shop.svg` | 72×72 | Golden Rounded Square | Shopping cart / armory store button. |
| `button_stats.svg` | 72×72 | Golden Rounded Square | Bar chart telemetry / statistics button. |
| `button_share.svg` | 72×72 | Golden Rounded Square | Connected node network share button. |
| `button_lock.svg` | 72×72 | Golden Rounded Square | Padlock locked state button. |
| `button_unlock.svg` | 72×72 | Golden Rounded Square | Padlock open / unlocked state button. |
| `button_start_pill.svg` | 280×84 | Golden Pill | Primary glossy golden "START" pill with play chevron. |
| `button_start_pill_pressed.svg` | 280×84 | Golden Pill | Depressed pressed state for START button with tight shadow. |
| `button_start_pill_disabled.svg` | 280×84 | Slate Pill | Inactive/disabled slate graphite state for START button. |
| `button_action_get.svg` | 200×68 | Golden Capsule | Arcade "GET" reward action button. |
| `button_action_next.svg` | 200×68 | Golden Capsule | Arcade "NEXT" stage progression button. |
| `button_action_retry.svg`| 200×68 | Golden Capsule | Arcade "RETRY" mission button. |
| `button_action_claim.svg`| 200×68 | Golden Capsule | Arcade "CLAIM" bounty/achievement button. |
| `button_action_deploy.svg`| 200×68 | Cyan Capsule | Arcade "DEPLOY" hangar vessel launch button. |
| `button_action_upgrade.svg`| 200×68 | Cyan Capsule | Arcade "UPGRADE" weapon & aircraft upgrade button. |

---

### 2. Tactile On-Screen Gameplay Controls (`assets/ui/controls/`)
All controls share the exact 512×512 heavy 3D beveled chrome bezel, tactile non-slip grooves, and specular curves from `fire_button.svg`:
| File | Dimensions | Theme Color | Description & Purpose |
| :--- | :---: | :--- | :--- |
| `control_fire.svg` | 512×512 | Crimson | Heavy 3D primary blaster trigger with crosshairs reticle. |
| `control_boost.svg` | 512×512 | Amber / Gold | Heavy 3D afterburner boost trigger with aerodynamic flame glyph. |
| `control_shield.svg`| 512×512 | Cyan / Sky Blue | Heavy 3D aegis energy shield trigger with defensive crest glyph. |
| `control_bomb.svg` | 512×512 | Amethyst Violet| Heavy 3D quantum bomb / missile trigger with hazard nova reticle. |
| `control_joystick_base.svg` | 512×512 | Cyan Hologram | High-tech glass disc base with chrome rim and cardinal notches. |
| `control_joystick_knob.svg` | 512×512 | Gunmetal Chrome | Heavy 3D thumbstick knob with grip rings and cyber core jewel. |

---

### 3. Gameplay HUD Indicators & Gauges (`assets/ui/hud/`)
| File | Dimensions | Style / Socket | Description & Purpose |
| :--- | :---: | :--- | :--- |
| `gauge_boost_bar.svg` | 360×80 | Candy Stripes / "GO!" | Dynamic boost propulsion capsule gauge. |
| `hud_health_bar.svg` | 360×80 | Emerald / 3D Heart | Segmented player hull health bar with heart socket. |
| `hud_shield_bar.svg` | 360×80 | Cyan / 3D Aegis | Segmented player plasma shield bar with shield socket. |
| `hud_currency_bar.svg` | 220×56 | Cyan Pill / Gold Coin | Currency HUD capsule with gold coin socket and counter text. |
| `hud_score_pill.svg` | 240×56 | Gold Pill / Star Crest | Mission score HUD capsule with multiplier badge. |
| `hud_boss_health_bar.svg`| 540×72 | Crimson / Hazard Strip | Widescreen boss battle warning health bar with skull crest. |
| `hud_radar_minimap.svg`| 180×180 | Cyan Scanner Grid | Circular tactical radar scanner with range rings & sweep beam. |

---

### 4. Dialog Cards, Frames & Overlays (`assets/ui/modals/`)
| File | Dimensions | Style / Structure | Description & Purpose |
| :--- | :---: | :--- | :--- |
| `modal_reward_dialog.svg`| 420×520 | Cyan Card / Sunburst | Reward presentation window with loot pedestal chamber. |
| `modal_level_complete.svg`| 420×540 | Cyan Card / 3-Star | Level complete victory window with trophy pedestal & coin pill. |
| `modal_ship_card.svg` | 540×640 | Cyan HUD / Nav Chevrons | Ship hangar inspection card with `< >` navigation buttons. |
| `panel_dialog_base.svg` | 480×560 | Cosmic Blue Frame | Universal dialog frame for settings, briefings, and confirmations. |
| `panel_pause_menu.svg` | 400×480 | Compact Beveled Card | Dedicated pause menu panel with header plaque and rivet accents. |
| `panel_card_slot.svg` | 140×160 | Recessed Cyber Well | Item / equipment / weapon chip socket card with rarity pips. |
| `panel_header_banner.svg`| 360×64 | Angled Ribbon Plaque | Sci-fi metallic header ribbon banner for window titles. |
| `panel_tech_frame.svg` | 512×320 | 90° Bracket Frame | Cybernetic HUD overlay frame with reticle guides. |
| `logo_space_racing.svg` | 480×160 | Chrome & Fire Text | Title logo text with speed flairs. |
| `logo_space_adventure.svg`| 512×160 | Winged Crest & Gold | Title logo with winged crest and golden embossed banner. |

---

### 5. Badges, Stars & Ranks (`assets/ui/badges/`)
| File | Dimensions | Tier / Accent | Description & Purpose |
| :--- | :---: | :--- | :--- |
| `badge_star_active.svg` | 64×64 | 3D Gold | Earned 3-star rating star with specular sheen. |
| `badge_star_inactive.svg`| 64×64 | Recessed Slate | Unearned rating star placeholder. |
| `badge_star_silver.svg` | 64×64 | 3D Chrome Silver | Silver tier achievement star. |
| `badge_star_bronze.svg` | 64×64 | 3D Copper Bronze | Bronze tier achievement star. |
| `badge_rank_s.svg` | 96×96 | Gold Winged Crest | Arcade S-rank mission performance emblem. |
| `badge_rank_a.svg` | 96×96 | Gold Shield Crest | Arcade A-rank mission performance emblem. |
| `badge_rank_b.svg` | 96×96 | Emerald Shield Crest | Arcade B-rank mission performance emblem. |
| `badge_rank_c.svg` | 96×96 | Cyan Shield Crest | Arcade C-rank mission performance emblem. |
| `badge_checkmark.svg` | 64×64 | Emerald Green | Completed mission / objective checkmark badge. |
| `badge_cross_failed.svg`| 64×64 | Crimson Red | Failed attempt / danger warning badge. |
| `badge_lock.svg` | 64×64 | Dark Slate & Gold | Locked aircraft / locked sector badge. |

---

### 6. Sliders, Toggles & Checkboxes (`assets/ui/sliders/`)
| File | Dimensions | Interaction State | Description & Purpose |
| :--- | :---: | :--- | :--- |
| `slider_track.svg` | 280×24 | Recessed Cyber Rail | Horizontal slider track with neon cyan energy fill and tick marks. |
| `slider_thumb.svg` | 48×48 | Tactile 3D Knob | Circular slider thumb knob with grip groove and cyber core jewel. |
| `toggle_switch_on.svg` | 80×40 | Active ON | Pill toggle in active ON state with emerald/cyan gradient. |
| `toggle_switch_off.svg`| 80×40 | Inactive OFF | Pill toggle in inactive OFF state with dark slate track. |
| `checkbox_checked.svg` | 48×48 | Checked State | Rounded square cyber checkbox with glowing white/cyan tick. |
| `checkbox_unchecked.svg`| 48×48 | Unchecked State | Rounded square cyber checkbox with empty recessed well. |

---

### 7. Inline HUD Icons (`assets/ui/icons/`)
Crisp, high-contrast 48×48 icons for inline labels, tooltips, and weapon cards:
- `icon_coin.svg`: Gold coin with star insignia.
- `icon_gem.svg`: Cyan power crystal gem.
- `icon_heart.svg`: Glossy 3D red heart.
- `icon_shield.svg`: Defensive cyan aegis shield.
- `icon_energy.svg`: Amber lightning bolt power icon.
- `icon_speed.svg`: Aerodynamic velocity chevrons.
- `icon_damage.svg`: Crossed blaster lasers with impact spark.
