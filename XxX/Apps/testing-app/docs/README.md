# Documentation index

Documentation updated against the project source and export configuration on 2026-10-09.

## Current guides

| Guide | Contents |
|---|---|
| [Project README](../README.md) | Running, controls, settings, builds, and verification overview |
| [Performance and progression](PERFORMANCE_PROGRESSION.md) | Three-star criteria, save migration, pooling, frame statistics, soak results and device limitations |
| [Architecture](ARCHITECTURE.md) | Scenes, autoloads, campaign rules, persistence, rendering, and input |
| [Build and distribution](DEPLOYMENT.md) | Local Web/Android exports, loader generation, serving, and APK verification |
| [Testing](TESTING.md) | Nine automated suites, rendered captures, manual checks, evidence, and limitations |
| [Localization and controls](LOCALIZATION_CONTROLS.md) | UI theme, translation coverage, categorized settings, saved control editor, asset audit |
| [Campaign report](CAMPAIGN_REDESIGN.md) | Planet/map assignments and combat behavior; historical layout sections are superseded |
| [Landscape report](LANDSCAPE_UI.md) | Landscape geometry, shared surfaces, image adaptation, and screen organization |
| [Latest asset inventory](localization-asset-inventory.json) | 215 source resources with hashes, sizes, and available dimensions |

For current settings and controls, use the localization report. For current code/build behavior, use Architecture and Deployment. The performance/progression report contains the latest implementation validation.

## Historical records

[Initial overhaul](OVERHAUL.md), the original [asset inventory](asset-inventory.json), and implementation-stage validation counts describe earlier project states. The campaign report supersedes the initial gameplay progression/balance; the landscape report supersedes portrait screen layouts; the localization report supersedes the earlier settings and touch controls.

Project-local backup ZIPs preserve the source/configuration before each implementation phase: `overhaul-backup.zip`, `campaign-redesign-backup.zip`, `landscape-ui-backup.zip`, `localization-controls-backup.zip`, and `performance-progression-backup.zip`. They are excluded from exported game packs.
