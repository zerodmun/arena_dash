# Gameplay control positioning

Implemented 2026-10-09. This guide supersedes the old bottom-only movement placement described in the localization report.

## Player flow

Open Settings → Display → Gameplay → Customize Control Position. Drag the movement preview freely within the highlighted left half. Apply saves position, size, opacity and Fixed Control mode together. Cancel discards draft changes; Reset to Default changes the preview until Apply. The separate Fixed Control option on the Gameplay settings page saves immediately.

The preview uses the selected terrain and aircraft, existing control artwork, rounded dark panels, and English/Indonesian translations. It preserves the landscape aspect ratio. Fire positioning, size and opacity remain available in the editor.

## Gameplay behavior

- Fixed Control enabled: a press within the configured joystick circle activates movement; its base remains anchored regardless of drag distance.
- Fixed Control disabled: movement can begin anywhere in the usable left half. The base starts at the finger (clamped when near an edge), follows a drag beyond its original travel radius, and returns to the selected resting position on release.
- Movement and shooting retain separate finger ownership. Releasing either finger does not release the other control.
- Gameplay gestures never modify saved positions. Opening settings pauses flight and resets active input.

The player's movement code and joystick travel/sensitivity are unchanged. Full knob travel is included in the allowed footprint, so the control remains visible even at maximum deflection. The fire control is confined to the right half, avoiding interference with movement placement.

## Persistence and safe areas

The existing `controls/layout` ConfigFile dictionary stores normalized viewport coordinates and `joystick.fixed`. Existing saves without the flag use fixed mode, preserving their anchored behavior. Invalid fields fall back to sanitized defaults.

Positions resolve against the current viewport and reported Android safe area whenever the viewport or preferences change. Near edges, the center is clamped so the entire control fits inside the left half. Orientation remains fixed landscape in the Godot project and Android manifest; no portrait editor was added.

## Verification

- `tests/control_position.tscn`: arbitrary placement, four aspect ratios (16:9, 18:9, 19.5:9, 20:9), simulated cutout insets, full control footprint, fixed anchoring, dynamic base movement, independent firing, settings navigation, Apply/Cancel/Reset and disk reload.
- `tests/control_position_resume.tscn`: a separate application process restores the saved position and mode and applies both to a live gameplay joystick. Run after the first suite.
- `tests/control_input.tscn`: actual viewport touch routing, multitouch, editor dragging, paused-flight isolation and editor resizing.
- `tests/localization_controls.tscn`: English/Indonesian settings and editor across 1280×720, 1440×720, 1560×720, 1600×720 and 960×540; native screenshots with `-- --screenshots`.
- Landscape UI, performance safety and gameplay smoke suites provide regression coverage.

All listed suites passed. The control-position and separate-process restoration suites also passed with native rendering. The Android debug APK was exported and its v2/v3 signatures and fixed-landscape manifest were verified.

Run each scene with `godot --headless --path . tests/<name>.tscn`. Native screenshots are saved to `qa/l10n_settings_gameplay_<locale>_<resolution>.png` and `qa/l10n_editor_<locale>_<resolution>.png`.

Android device touch and physical cutout behavior still need on-device verification; automated checks use viewport input and simulated safe rectangles. The Redmi Note 8 crash investigation remains documented separately in [Android stability](ANDROID_STABILITY.md).
