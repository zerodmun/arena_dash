# Rounded flight-console buttons

Implemented 2026-10-09. Existing screen layouts, navigation, gameplay input and fixed landscape orientation remain unchanged.

## Shape and materials

The shared `ArcadeUI` button family replaces the previous 16px native corners with 30px curves on a 64px-high capsule. Nine-slice corners keep the silhouette smooth across wide action buttons and compact icon controls. The face, inner highlight, outer border, lower bevel and focus outline all follow the same curve. Normal, hover, pressed, hover-pressed, disabled and focus states have identical extents, preventing layout shifts.

Primary actions use muted copper/amber gradients with dark navy labels for strong contrast. Secondary controls use lighter steel blue with warm off-white labels; selected controls use muted teal faces and desaturated cyan borders. The warm/cool hierarchy makes action buttons distinct from surrounding navy panels. Disabled controls use a subdued navy face, softer border and readable blue-gray text/icons. The existing joystick artwork retains its geometry and grip rings with desaturated blue/steel colors. Circular planet and fire controls use the same restrained materials; the fire crosshair is retained without the old vivid red/chrome surround.

Source artwork lives in `assets/ui/theme/buttons/`. Regenerate it with `python3 tools/ui/generate_buttons.py`. Existing icons, fonts, ship/planet artwork, panels and layout structures are reused. No raster generation, stock artwork or external font dependency is introduced.

## Alignment and feedback

Text and icons remain vertically centered with equal 12px top/bottom content margins. Text defaults to the existing 20px bold font; screen-specific font sizes remain intact. A 30px icon plus 10px gap receives a mirrored right-side reservation, keeping the label itself horizontally centered instead of shifting it into the remaining space. Icon-only controls center their glyphs. Text clipping is disabled so translated minimum widths can be checked by the layout suites.

`ButtonFeedback` adds a short press/release luminance transition (70ms press, 160ms release) to native button state shading. It never changes control scale, position, hit regions or geometry. Reduced Motion disables transitions. Restyling does not duplicate feedback handlers. The circular fire control uses equivalent state artwork and timing while retaining its original finger ownership. Planet controls animate their circular press inset only while transitioning.

`UIStyler` compatibility helpers delegate to the shared button family, preventing older weapon/sector helpers from reintroducing sharp frames or bright catalog colors.

## Android performance

SVG artwork is imported once to standard textures. StyleBoxTexture resources are cached and shared; variants with balanced icon padding reuse the same textures. All face shading is baked into the artwork. No runtime shader, blur, glow filter or idle button animation is required. Tweens run only during interaction. Planet redraw processing stops after each transition.

## Verification

- `tests/button_design.tscn`: transparent rounded corners for every face/focus texture, continuous gradient face, at least 4.5:1 interactive label contrast at the text band, at least 2:1 normal face contrast against the representative navy panel, equal vertical padding, actual touch press/release, disabled action blocking, unchanged tap bounds, Reduced Motion and repeated restyling. Native capture: `qa/rounded_button_states.png`.
- `tests/landscape_ui.tscn`: screen/button bounds, touch target sizes, shared rounded assets and centered icon reservations, safe-area simulations, normal navigation, pause/results and campaign controls across 16:9, 18:9, 19.5:9 and 20:9 landscape layouts.
- `tests/localization_controls.tscn`: English and Indonesian Home, Hangar, weapon/campaign/settings/control-editor layouts at 1280×720, 1440×720, 1560×720, 1600×720 and 960×540.
- Control input/position and performance safety suites cover unchanged multitouch, joystick customization and gameplay safeguards.

Native visual captures use `godot --path . tests/<suite>.tscn --windowed --resolution 1280x720 --rendering-method gl_compatibility -- --screenshots`. Headless checks use `godot --headless --path . tests/<suite>.tscn`.

Physical Android touch ergonomics and GPU performance still require on-device verification. The tests use injected viewport events and simulated cutout safe areas.

Completed validation: native button-state/touch checks and bilingual rendered layouts, landscape/safe-area checks, control input/position, gameplay smoke, audio and performance safety suites all passed. The Android debug APK exports successfully; v2/v3 signatures and fixed-landscape orientation in its manifest are verified.
