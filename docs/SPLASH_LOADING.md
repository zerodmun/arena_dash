# Fullscreen startup and measured loading

Implemented and tested on 2026-10-10 with Godot 4.7.2 official templates and a physical Redmi Note 8 (Android 13, Adreno 610, 2340×1080 landscape).

## Implementation

`scenes/loading.tscn` is the project's entry scene. `scripts/loading_screen.gd` renders the existing `assets/ui/theme/space_landscape.svg` with `KEEP_ASPECT_COVERED` and a small overscan for slow background motion. It fills the viewport while preserving the artwork's aspect ratio. Foreground coordinates use the existing Android safe-area mapping, independently of the full-bleed background.

The original `assets/logo.png` remains unchanged. It fades in above the title, with a gently floating existing `assets/player.svg`, 24 inexpensive drawn stars, a rounded progress bar and a cross-fade into the existing menu. Reduced motion disables floating, parallax and star animation. There are no new bitmap assets, expensive shaders, particle nodes, timed loading holds or changes to gameplay mechanics.

Godot threaded resource loading warms the menu, Hangar, planet selection, gameplay scene, selected equipment/map artwork, menu ship artwork and button textures. Export-safe resource enumeration and deduplication produce 24 jobs for the configuration tested on the phone. Progress is the equal-weight mean of completed resource jobs plus Godot's reported progress for the active job; it describes this resource queue, not a prediction of total startup time. `load_threaded_get` is called only after the job reports loaded. Warm resources remain referenced by `Game.startup_resources` for subsequent scene reuse.

Autoload/engine initialization happens before the loading scene and cannot supply a resource percentage. Menu instantiation uses “Preparing navigation…” without a percentage. No fabricated percentage is assigned to either phase. Failed resource requests expose a translated Retry button, and a retry restarts the queue using cached successful resources. English and Indonesian catalog entries cover new loading/error/retry text.

Existing audio initialization and the menu's audio hooks remain intact. Cold-launch logs show the Android audio driver initializing without script exceptions or native crashes during these tests. Silent screen recordings do not constitute audible verification of sound quality.

## Native Android and Godot boot stages

Android retains its system launch splash with the existing custom ship icon. Export presets configure the splash icon, immersive launch and a deep navy engine background (`#020617`), and disable the old Godot boot image. The original static splash artwork is preserved in assets but is no longer displayed. APK/native logs confirm `--fullscreen`, `--background_color #020617` and `--disable_godot_splash`.

The standard non-Gradle template's Android 12+ theme uses the adaptive icon background resource for its system splash backdrop; the preset background color is not a guarantee of a rewritten native theme color. The actual phone recording shows a dark backdrop with the custom ship icon, followed by the full-bleed cinematic scene. The native system stage briefly shows system bars and a rotation transition from the portrait launcher before immersive Godot presentation starts. Those system-owned frames are not the Godot loading layout. Custom full-screen artwork and animation begin when the engine can render them, as permitted by [Android's splash-screen model](https://developer.android.com/develop/ui/views/launch/splash-screen). Engine and autoload startup take approximately three seconds on this phone; they are not concealed by fake loading progress.

## Verification

- Godot import/script validation completed without parse errors.
- `tests/loading_screen.tscn`: PASS, zero assertion failures. Checks actual resource completion, monotonic/bounded progress, background coverage, preserved aspect ratio, foreground safe-area containment, reduced motion, missing-resource error presentation and retry recovery.
- Automated viewport checks: 1280×720, 1440×720, 1560×720 and 1600×720 (16:9 through 20:9), with simulated 32-unit safe insets. These are geometry checks; physical verification was performed on one phone/aspect ratio.
- Three force-stop/cold launches created distinct processes and reached the menu. Screen recordings visibly show logo fade, measured bar advancement, spaceship motion, the transition and the main menu. No black frame or letterboxing was observed between the Godot loading scene and menu.
- Full physical screenshots and Android window diagnostics confirm 2340×1080 landscape presentation, full background coverage, a left cutout inset of 80 physical pixels and foreground kept away from that cutout.
- Automatic touch navigation after the transition opened Hangar, confirming menu input was restored.
- No script errors, AndroidRuntime fatal exceptions or native fatal signals appear in the captured startup and post-startup logs. This is a short startup regression test, not a long gameplay/security certification.
- Headless test shutdown reports three ObjectDB cleanup warnings; these were not present in the Android startup captures.

| Cold launch | Resource queue ready | Menu ready | Android activity launch TotalTime |
|---|---:|---:|---:|
| 1 | 1303 ms | 1570 ms | 3479 ms |
| 2 | 1255 ms | 1521 ms | 3292 ms |
| 3 | 1250 ms | 1539 ms | 3275 ms |

The first two timing columns are measured from loading-scene initialization. Android's activity TotalTime is a separate system measurement and does not include the entire later loading transition; do not interpret 1.52–1.57 seconds as total tap-to-menu time.

## Delivered build and evidence

`build/arena_dash_debug.apk` was built sequentially, signature/alignment verified, installed with `adb install --no-incremental -r`, and used for all three recordings. Existing app data was retained. This is the project's development-signed APK, not a production release signed with a supplied release keystore.

SHA-256: `f6a8322d27ab39dcd310089b379867c6259bb389037a8831c0915458615b663f`

Evidence is in `qa/splash-qa/`: `build-final.log`, `import.log`, `loading-test.log`, `manifest.txt`, `apk-resources.txt`, `cold-launches.json`, `cold-1.mp4` through `cold-3.mp4`, individual launch logs/screenshots, `frame-049.png` (loading at 45%), `post-startup-hangar.png`, `post-startup.log` and `window.txt`. The manifest enforces landscape; the native APK splash theme/icon and engine startup parameters were inspected directly.

Relevant API: [Godot ResourceLoader](https://docs.godotengine.org/en/stable/classes/class_resourceloader.html).
