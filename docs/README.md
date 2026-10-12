# Documentation index

Documentation updated against the project source and export configuration on 2026-10-09.

## Current guides

[Equipment purchases and gameplay integration](EQUIPMENT_PURCHASES.md) documents the central equipment catalog, current Hangar purchase flow, save compatibility, functional gameplay tests and remaining Android device verification.

[Hangar layout refinement](HANGAR_LAYOUT_REFINEMENT.md) documents the current Hangar-only alignment changes, rendered verification and pending physical-device checks.

[Fullscreen splash and measured loading](SPLASH_LOADING.md) documents the animated entry scene, native startup boundaries, real resource progress and repeated physical-phone verification.

[Adaptive icon and coin economy](ADAPTIVE_ICON_ECONOMY.md) documents the latest full-bleed launcher artwork, Hangar alignment, persistent purchases, save migration and physical Android verification.

| Guide | Contents |
|---|---|
| [Audio implementation](AUDIO.md) | CC0 asset manifest, screen music, event hooks, buses, settings, optimization, and validation |
| [Project README](../README.md) | Running, controls, settings, builds, and verification overview |
| [Performance and progression](PERFORMANCE_PROGRESSION.md) | Three-star criteria, save migration, pooling, frame statistics, soak results and device limitations |
| [Architecture](ARCHITECTURE.md) | Scenes, autoloads, campaign rules, persistence, rendering, and input |
| [Build and distribution](DEPLOYMENT.md) | Local Web/Android exports, loader generation, serving, and APK verification |
| [Testing](TESTING.md) | Nine automated suites, rendered captures, manual checks, evidence, and limitations |
| [Button design system](BUTTON_DESIGN.md) | Capsule geometry, materials, state artwork, centered labels, feedback and validation |
| [Control positioning](CONTROL_POSITION.md) | Settings → Display → Gameplay, fixed/dynamic joystick, safe-area bounds and persistence validation |
| [Localization and controls](LOCALIZATION_CONTROLS.md) | UI theme, translation coverage, categorized settings, saved control editor, asset audit |
| [Campaign report](CAMPAIGN_REDESIGN.md) | Planet/map assignments and combat behavior; historical layout sections are superseded |
| [Landscape report](LANDSCAPE_UI.md) | Landscape geometry, shared surfaces, image adaptation, and screen organization |
| [Latest asset inventory](localization-asset-inventory.json) | 215 source resources with hashes, sizes, and available dimensions |

For current settings and controls, use the localization report. For current code/build behavior, use Architecture and Deployment. The performance/progression report contains the latest implementation validation.

## Historical records

[Initial overhaul](OVERHAUL.md), the original [asset inventory](asset-inventory.json), and implementation-stage validation counts describe earlier project states. The campaign report supersedes the initial gameplay progression/balance; the landscape report supersedes portrait screen layouts; the localization report supersedes the earlier settings and touch controls.

Project-local backup ZIPs preserve the source/configuration before each implementation phase: `overhaul-backup.zip`, `campaign-redesign-backup.zip`, `landscape-ui-backup.zip`, `localization-controls-backup.zip`, and `performance-progression-backup.zip`. They are excluded from exported game packs.

- [Landscape UI theme](UI_THEME.md) — reference adaptation, reused artwork, safe areas, and validation.

- [Android stability investigation](ANDROID_STABILITY.md) — confirmed cleanup fix, device verification limits, debug builds, and Logcat capture.

- [Android security audit](ANDROID_SECURITY_AUDIT.md) — APK inspection, export hardening, dependencies, signing, and remaining risks.
- [Play Protect review evidence](PLAY_PROTECT_REVIEW.md) — accurate review packet and missing warning/device information.

- [Android audio crash diagnosis](ANDROID_AUDIO_CRASH.md) — native instruction/register correlation, PCM loop correction, signed builds and real-time test evidence.

- [Physical Android phone QA and reproduced native audio crash](ANDROID_PHONE_QA.md)

- [Project restructuring and Android installation investigation (2026-10-12)](PROJECT_RESTRUCTURING.md)

- [Confirmed APK direct-install cause and successful phone verification](DIRECT_INSTALL_FIX.md)

- [Advanced campaign and production release pipeline](ADVANCED_RELEASE.md) — Levels 9–15, latest icon, release default, actual test evidence and signing blocker.

- [Android production signing and device installation](ANDROID_RELEASE_SIGNING.md)
