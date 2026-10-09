# Landscape UI conversion and unified theme

The [localization/control report](LOCALIZATION_CONTROLS.md) extends this conversion with bilingual content, categorized settings, unified typography, and saved touch layouts. Asset counts and validation results in the phase-specific sections below refer to the landscape conversion; see the [latest inventory](localization-asset-inventory.json) and [testing guide](TESTING.md) for current coverage.

## Completed screens

- Main menu: replace the narrow centered portrait card with an aircraft hero on the left and navigation/actions on the right. Reuse the existing landscape campaign sky.
- Hangar and aircraft selection: left column for aircraft identity, speed/shields/fire rate and weapon loadout; central aircraft and docking pedestal; right column for circular progress planet, selected mission destination and deployment; horizontal aircraft roster along the bottom. Remove the compact portrait stacking branch.
- Planet campaign/level selection: retain the eight-world winding landscape route, numbered planet circles and star ratings. Remove the portrait staggered vertical route. Use shared navigation buttons and briefing surfaces.
- Weapon popup: aircraft/firing preview on the left; two-column weapon selection, description and confirmation on the right. Fix transient container minimum-size inflation so the modal stays within the viewport.
- Settings and flight manual: replace native AcceptDialog windows and generic CheckButtons with in-canvas landscape overlays. Settings now groups General, Language, Audio, Graphics, and Controls, with a dedicated control editor. The manual shows the current aircraft beside the control guide.
- Pause menu: aircraft/title on the left; resume/settings/hangar actions on the right; blocking dim overlay.
- Victory, final campaign completion and defeat: mission information on the left; stars and next-world/replay/retry/hangar actions on the right.
- Combat HUD/notifications: shared panels/buttons, consistent score/shield/objective typography, saved size/opacity/position for touch Fire and Movement controls. Pause overlays dim all underlying HUD content.
- Startup/loading: retain supplied landscape splash artwork; match its surrounding navy color and style the Web progress/error notice with shared colors and borders. Display artwork without distortion; Web loader text restores the saved EN/ID preference.

## Shared components and behavior

`ArcadeUI` owns navy/violet surfaces, cyan highlights, gold primary actions, text colors, spacing, rounded borders, shadows, control sizes and hover/pressed/disabled/focus/selected states. Hangar progress bars use matching cyan fills. PlanetButton retains its circular hit region and actual planet texture; idle buttons no longer redraw continuously. Reduced motion stops animated campaign route highlights and UI entrance/selection fades.

`FlightDialog` provides modal settings/help, Escape close, keyboard focus loops, focus restoration, saved settings and pause restoration. Opening it during flight releases firing and resets the joystick. Closing settings opened from pause keeps flight paused. Loadout supports a focus loop, Escape/cancel and confirmation; selecting a weapon updates its live preview. Pause/results actions use the shared focus styling.

One 1280×720 logical canvas serves every screen. Wider landscape windows expand horizontally for 20:9. Native mobile orientation remains locked to landscape. Portrait desktop/browser windows letterbox this same landscape interface rather than switching to a portrait design. At 960×540, 64-unit main buttons render 48 pixels tall. Checks cover 1920×1080, 1280×720, 1600×720 and 960×540, plus the 720×1280 letterbox fallback.

## Recursive asset reuse and integrity

All graphical resources under `assets` and nested folders were recursively inspected. The 82 graphical files present at the start were hashed and remain byte-identical. No artwork was created, generated, downloaded, overwritten or deleted by this implementation. An organized `assets/ui` kit appeared during the run; its supplied files were preserved and audited separately, including dedicated forward/restart/up/down icons. Shared buttons use the organized kit when available, with existing nested UI assets as fallback. Forward/restart icons now identify aircraft navigation and mission actions.

Reused assets include the already-existing `assets/generated/campaign_horizon.svg` from the prior redesign; original splash; booster and all twelve selectable aircraft; eight planet previews; star badges; home/back/forward/play/restart/pause/settings/audio/close/menu icons; portrait starry hangar background fitted proportionally; docking pedestal; weapon/projectile art; joystick/fire textures. Existing maps, obstacles, pickups and gameplay systems are retained. Portrait modal-card artwork was inspected but not stretched to fabricate landscape imagery: reusable code styles supply panel containers.

`landscape-ui-backup.zip` preserves source/scenes/tests/configuration before this conversion. Backups, documentation, tests and build output are excluded from exports. Changes are confined to the project.

## Validation

`tests/landscape_ui.tscn` exercises main UI and campaign layouts, all popup bounds, settings persistence, help Escape close, every weapon choice/live preview, touch firing/pause reset, settings during pause, resume/retry, victory progression, focus/touch geometry and landscape canvas policy at five window shapes. Screenshots are saved as `build/landscape_*.png`.

Existing smoke, hangar-review and campaign-combat suites guard all eight environments, twelve aircraft, four weapon patterns, armor/projectile physics, movement, pause, campaign save/load, latest completion order and mandatory guardian encounters. Test saves are project-local.

## Limitations and missing assets

No physical Android device or human playtesting session was available. Portrait/tiny browser windows letterbox rather than provide a portrait redesign; landscape is the intended viewing orientation. Android retains the existing local test signing identity and is not a store release. No external deployment occurred.

**Missing graphical assets: none required.** The supplied resources and reusable UI code support every requested interface. There are no placeholder substitutions or pending artwork requests, so no filename/dimension/format request is needed.

Final results: GAME SMOKE PASS, HANGAR REVIEW PASS, CAMPAIGN COMBAT PASS, and LANDSCAPE UI PASS (both headless and native rendered), all with zero failures. Web and Android release exports exited successfully. The rebuilt Web game was checked through menu, settings/Escape close, hangar, loadout confirmation, deployment, pause and settings-close-to-pause, without browser warning/error logs. APK signature verification passes schemes v2 and v3. The rendered harness explicitly draws capture frames to avoid background-window focus stalls and waits for queued dialog deletion before assertions. Sandbox editor-settings/log/ADB diagnostics do not prevent builds or game checks.
