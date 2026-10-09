# UI refinement, localization and flight controls

Updated 2026-10-09. See the [documentation index](README.md), [architecture](ARCHITECTURE.md), [build guide](DEPLOYMENT.md), and [testing guide](TESTING.md).

The current implementation supersedes the settings/control details in the previous landscape report. Gameplay, campaign progression, aircraft statistics, weapons, objectives and map assignments are retained.

## Unified interface

`ArcadeUI` supplies shared navy surfaces, violet borders, cyan selected/hover states, gold primary actions, muted descriptions, consistent 64-unit buttons, and keyboard focus rings. Labels, buttons, hangar typography and HUD helpers explicitly share the engine's fallback font; no supplied font files were present. Titles use 28–48 units according to hierarchy, body text 18–20, supporting labels at least 16 except compact campaign markers with responsive sizing. Hangar aircraft classification, loadout headings and roster names were made more readable; heavy HUD text outlines were reduced. Existing landscape layouts and proportional image fitting remain in place.

The menu, hangar, aircraft roster, weapon preview, planet route/briefing, HUD, pause, flight manual, settings, editor, victory and defeat share this system. A 1280×720 logical canvas scales to smaller windows; wide landscapes expand horizontally. Portrait windows letterbox the landscape interface.

## English and Bahasa Indonesia

`localization/en.json` and `localization/id.json` contain 199 matching English source keys. `I18n` registers Godot Translation resources at startup so static controls/tooltips translate automatically. Formatted text translates before interpolation through `I18n.t(key, arguments)`; language signals refresh current HUD messages, statistics, mission summaries, aircraft descriptions and open selection panels immediately.

Coverage includes navigation, settings/categories, editor instructions/status, aircraft classes/descriptions, weapon descriptions, biome descriptions/hazards, campaign lock requirements/challenges/difficulty, objectives/guardian messages, pause, results, notices and tooltips. Aircraft, weapon and planet proper names remain unchanged. Numeric counters and symbols are language-neutral. Existing weapon selection is retained; there is no upgrade economy, weapon-switch button or special-ability button to invent or translate.

Language defaults to English for new saves. The existing local ConfigFile stores `settings.language`; it restores on reopening. Web builds also mirror the locale into localStorage for the pre-engine loader. `tools/build_web_shell.py` generates the stock Godot loading shell from the same catalogs. Loader progress, browser canvas fallback and friendly load errors use the saved language, while technical error details remain in the developer console. Regenerate/export with `./build_web.sh` after catalog changes. Add future content to both catalogs; the automated suite checks key parity and nonempty Indonesian values.

## Settings and editor

Landscape settings have General, Language, Audio, Graphics and Controls categories. The General page offers the key preferences together; dedicated categories provide descriptions. Audio enables/disables all sound effects; reduced motion governs existing animation/shake behavior. Changes save immediately. Customize Controls opens a separate editor; close/Escape and tab navigation preserve focus and the prior flight pause state.

Supported draggable controls are **Fire** and **Movement joystick**, the two existing gameplay touch controls. The preview uses the selected planet's existing map image, the current aircraft and actual supplied control textures. It reserves the HUD zone and never runs movement/firing logic. Each handle supports mouse and touch dragging. Selection highlights and a localized blocked-position message explain overlap rejection.

Size ranges from 80–140% and opacity from 35–100%, independently for each control. The supplied slider rail/thumb artwork is reused, with a dynamic cyan fill and shared focus styling. Circular hit regions and joystick travel scale with the saved dimensions. Keyboard navigation includes selection, both sliders, Reset, Cancel and Save.

Editor changes are a draft: **Save Layout** applies/persists both controls; **Cancel/Escape** preserves the previous live settings; **Reset to Default** restores the draft and requires Save to apply. This matches the explicit Save/Cancel architecture while other settings save immediately.

## Persistence, bounds and input

The existing ConfigFile stores `controls.layout` with normalized center coordinates, size multiplier and opacity. Older saves receive defaults. Invalid types/nonfinite positions are sanitized and numeric settings clamped. Layout resolution fits the controls inside the lower gameplay area, keeps a 2.5% horizontal and 3% bottom screen margin, reserves the top 28% for HUD/alerts, and prevents controls from overlapping. Android/iOS reported display safe areas further constrain placement; hardware cutout behavior still requires device validation. Resizing resolves the same normalized layout without stretching control artwork. Invalid overlap after an aspect-ratio change falls back to separated safe positions.

Fire and joystick own independent finger indices; global release handling clears a held control even when its finger releases outside the hit region. Mouse/keyboard flight controls remain available. Pausing, settings/editor opening and focus loss release firing/reset movement. Editor handles use a separate script and cannot trigger flight inputs. Saving updates the HUD immediately on returning to gameplay.

## Asset discovery and integrity

The entire nested `assets` tree was reviewed, including `future_updates/aircraft`, maps, `future_updates/ui`, hangar resources and the organized `ui/buttons`, `ui/controls`, `ui/sliders`, `ui/badges`, icons/panels folders. [The latest asset inventory](localization-asset-inventory.json) records 215 source resources with hashes and available dimensions. The starting SHA-256 inventory covers **208 graphical resources**; every file remains byte-identical. No artwork was generated, downloaded, overwritten or removed in this refinement.

Reused resources include existing map and planet artwork, twelve aircraft, weapon/projectile art, original splash, hangar background and docking elements, campaign sky, home/back/forward/play/restart/pause/settings/audio/close icons, star badges, joystick base/knob, Fire control, slider track and thumb. Alternative supplied panel/toggle assets were inspected; shared code styles and state buttons provide consistent functional surfaces. All eight campaign map assignments and portrait-to-landscape adaptation remain documented in `CAMPAIGN_REDESIGN.md` and `LANDSCAPE_UI.md`.

`localization-controls-backup.zip` preserves source/scenes/tests/configuration before these changes. Tests use project-local save files. Builds exclude tests, reports, backups and build output. No changes were made outside the project.

## Validation and local outputs

- **GAME SMOKE, HANGAR REVIEW, CAMPAIGN COMBAT, LANDSCAPE UI:** pass with zero failures. These cover the existing aircraft/weapons/maps, campaign/boss requirements, navigation, dialogs, settings persistence and landscape/portrait-letterbox geometry.
- **LOCALIZATION + CONTROLS:** headless and rendered native pass with zero failures. Both languages at 1280×720, 1600×720 and 960×540; captures cover menu, every settings category, editor, hangar, weapon dialog, campaign, flight, pause, defeat and victory. Checks include instant translations, CFG reload, Fire drag, independent size/opacity, overlap rejection, safe bounds, Cancel, Save, Reset and malformed preferences.
- **CONTROL INPUT:** pass with zero failures. Events go through the actual viewport GUI dispatch: independent simultaneous movement/firing fingers, releases outside bounds, touch drag in the editor and isolation from paused flight, and changing the preview aspect ratio while the editor is open.
- **Web browser:** real mouse dragging, resizing, opacity, Save, instant Indonesian switching and reload persistence verified. The pre-engine loader also restores Indonesian. Console warning/error logs were empty.
- **Web release export:** successful; includes both JSON catalogs and localized loader.
- **Android release export:** successful; APK signature verified with v2/v3 schemes using the existing local test signing identity.

Useful commands:

```sh
godot --headless --path . tests/localization_controls.tscn
godot --headless --path . tests/control_input.tscn
godot --path . --windowed --resolution 1280x720 --rendering-method gl_compatibility tests/localization_controls.tscn -- --screenshots
./build_web.sh
./build_apk.sh --export-release
python3 serve_web.py
```

Rendered captures are in `build/l10n_*.png`; exported game is in `build/web`, APK in `build/arena_dash.apk`. Local preview uses port 8060. Environment-only sandbox log/editor-settings/ADB/certificate diagnostics did not block tests or exports.

## Remaining limits

No physical Android device was available for ergonomics, real multitouch, cutout or GPU validation. The APK uses the existing development signing identity rather than a store release identity. Very small/portrait windows retain landscape letterboxing. No external deployment occurred. **Missing graphical assets: none.**

## Campaign feedback update

The latest ten catalog additions cover three-star clear/retry status, damage/time criteria, current versus best ratings, and unlock feedback in both languages. [Performance and progression](PERFORMANCE_PROGRESSION.md) supersedes earlier completion rules and documents the latest validation.
