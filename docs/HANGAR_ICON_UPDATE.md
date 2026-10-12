# Hangar and application icon update — 2026-10-10

Implemented directly in the Godot project and installed on the connected Redmi Note 8 (Android 13).

## Changes

- `assets/logo.png` is the application icon in `project.godot`. The final provided source is a 1024 × 1024 RGBA PNG. Its artwork, proportions and alpha are preserved; the source was not edited by this implementation. The source changed during testing, so icons were regenerated and the APK rebuilt from the latest version.
- `tools/generate_android_icons.gd` generates legacy launcher sizes 48, 72, 96, 144 and 192 pixels, plus 432-pixel adaptive foreground/background resources. The complete square artwork is centered at 184 pixels inside the adaptive foreground to avoid mask clipping. Transparent source pixels remain transparent; a separate navy adaptive background is used.
- All Android presets reference the custom launcher and adaptive resources. Exported adaptive XML uses those foreground/background layers. The installed launcher displays the provided spaceship logo instead of Godot's icon.
- `scripts/hangar.gd` removes the instruction Label entirely. Aircraft selection callbacks and arrows remain intact.
- The header is now a bare navigation row and standalone HANGAR title. Its surrounding card, emblem and command branding were removed. No literal BASE label existed in the inspected source; its associated decorative header area is gone. Home, Settings, Help and the best-score display remain functional.
- Deploy Mission increased from 272 × 76 to 352 × 108 logical pixels, with 28-point text and 24-pixel horizontal / 20-pixel vertical padding. All button states retain the existing rounded texture and feedback system.
- Bottom layout uses a 24-pixel margin inside the usable safe rectangle. The mission label sits above Deploy with a 24-pixel gap. Wrapped label geometry is finalized after layout to prevent the label's actual bounds from overlapping the button. Preview, weapon controls and aircraft arrows retain their existing roles.

## Verification

- Hangar review: PASS, 0 failures, including all 12 aircraft and weapon previews, gameplay/navigation checks and new instruction/header/button geometry assertions.
- Landscape UI: PASS, 0 failures. Checked 16:9, 18:9, 19.5:9, 20:9, smaller landscape windows, portrait-window landscape letterboxing and simulated safe areas.
- English and Indonesian Hangar text-fit / safe-area checks: PASS across those aspect ratios.
- Host headless tests emitted macOS certificate warnings; the temporary localization harness also emitted resource cleanup warnings at exit. These were not assertion failures. The final phone log contains no captured script error or fatal crash.
- Actual device screenshots are 2340 × 1080. Inspected the uncropped Titan preview, centered Deploy label, preserved weapon loadout and clear button/label separation.
- Device interaction verified aircraft next/previous, weapon dialog, Deploy starting a mission, pause/return and launcher icon. Final rebuild repeated mission deployment and launcher verification using the latest logo.
- The APK signature verified using v2/v3 and passed alignment verification. This is a signed **development/debug APK**, not a production release.
- Pulled the installed APK back from the phone and confirmed it exactly matches the delivered build.

## Deliverable and evidence

APK: `build/arena_dash_debug.apk` (48,259,085 bytes).

SHA-256: `92c57fa504260b88190196d141c7dcad0177cf8247fd7518a745a598ca5ea91a`

Source logo SHA-256: `1f3affd7bdb54a6cabb94c9c9a40edaae84e89382ee5f216ece289957e664ef5`

Evidence under `qa/hangar-icon-qa/`:

- `phone-hangar-final.png`: final installed Hangar.
- `phone-gameplay-final.png`: mission started by tapping Deploy.
- `phone-hangar-returned.png`: return navigation.
- `phone-launcher-final.png`: latest custom installed icon.
- `phone-aircraft-next.png`, `phone-aircraft-restored.png`, `phone-weapons.png`: aircraft and weapon interaction evidence from the same Hangar implementation before the final icon-only rebuild.
- `verification.json`, `phone-logcat.txt`, `build-final.log`, `hangar-test-final.log`, `landscape-test-final.log`, `localized-test.log`: checksums, build and QA records.

Physical verification covers the connected Redmi Note 8; other landscape sizes and cutouts were checked by automated layout tests. This update does not establish a Play Protect false-positive resolution or repeat the earlier long-duration stability audit.
