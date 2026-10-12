# Landscape space UI refresh

The supplied reference images inform the navy/purple atmosphere, cyan highlights, blue glass panels, gold actions, and bold typography. The existing landscape structures, navigation, campaign progression, weapons, audio, and gameplay remain intact.

## Artwork and shared theme

`ArcadeUI` centralizes muted navy/steel colors, typography, focus/hover/pressed/disabled states, dark glass panels, muted amber primary actions, steel-blue secondary controls and restrained reward highlights, and rounded utility controls. Interactive buttons now use purpose-built capsule artwork with 30px curves, restrained vertical gradients and shared rounded bevel/focus states. Older pointed frames are unused by buttons. Vertical padding is symmetric; labeled icons reserve equal space on both sides of the text so labels remain at the actual button center. See [Button design system](BUTTON_DESIGN.md). `assets/ui/theme/space_landscape.svg` recomposes the existing `future_updates/hangar/hangar_space_background.svg` into landscape without stretching planets. Text-free buttons derive from `future_updates/ui/button_start_pill.svg`; compact frames and glyphs derive from `assets/ui/buttons`. Panels use matching vector glass gradients. Ship, planet, pedestal, weapon, and slider art is reused. No reference image pixels, stock watermarks, or external fonts are bundled.

Home retains its left title/ship and right action panel. Hangar retains header navigation, left flight systems/loadout, central ship with arrows, and right campaign/deploy controls. The bottom thumbnail roster is removed; all 12 aircraft still use the original catalog, selection persistence, arrow wraparound, keyboard controls, and swipe gestures. The central stage is taller, with a visible selection hint.

## Landscape and device safe areas

Startup and runtime use a 1280×720 minimum landscape canvas with `canvas_items` stretch. Wide landscape windows expand horizontally; portrait-shaped desktop windows letterbox the landscape canvas. Android uses `display/window/handheld/orientation=0` (landscape). `Game` reapplies `SCREEN_LANDSCAPE` at startup and application resume. Orientation is shared by every scene.

`ArcadeUI.safe_rect()` maps the device's interactive display area into logical coordinates. Home, Hangar, campaign, settings, weapon dialogs, control editor, gameplay top bar, pause, result dialogs, and touch controls respect this area. Screen layout methods accept an available rectangle for deterministic cutout checks. Backgrounds cover with preserved aspect ratio; ship previews contain with preserved aspect ratio. Compact utility controls use 64-pixel logical touch targets.

## Validation

`tests/landscape_ui.tscn` verifies 16:9, 18:9, 19.5:9, 20:9, smaller landscape windows, and letterboxed portrait windows. It checks simulated cutouts, dialog bounds and touch targets, removal of the visual roster, all-ship arrow navigation, keyboard/swipe selection, weapon preview selection, locked campaign nodes, settings persistence, gameplay input, pause/resume, defeat/retry, and victory progression. Run with `--screenshots` using a native renderer for visual captures in `qa/landscape_*.png`.

A local unsigned Android validation APK is exported separately using installed Godot templates and a temporary validation key, preserving the project's configured signing identity. Its extracted manifest is saved to `qa/ui-android-manifest.txt`. Physical Android notch behavior, rotation, and touch ergonomics still require device verification; no connected Android device was available.

Completed validation on 2026-10-09: native rendered landscape suite (0 failures), plus game smoke, Hangar review, campaign combat, localization/control editing, control input, three-star progression, performance safety, and audio suites (all pass). The APK manifest contains `android:screenOrientation=0` (landscape); export completed with no script errors. This refresh did not repeat the earlier long performance soak.

See [Android stability and subsequent UI refinement](ANDROID_STABILITY.md) for current crash verification status, palette changes, and diagnostic builds.
